USE SOITOSAP
Go

-- Find last error message for records in PIC and PMPS. Used in other queries later.
WITH ErrorMessages AS (
    SELECT 
        pica.PostedInventoryConsumptionsKey As RecordKey,
        pica.SAPMessage,
        ROW_NUMBER() OVER (PARTITION BY pica.PostedInventoryConsumptionsKey ORDER BY pica.AuditDate DESC) AS RowNum
    FROM PostedInventoryConsumptionsAudit pica (NOLOCK)
    WHERE pica.StatusCode = 'E'
    UNION ALL
    SELECT 
        pmpsa.PostedManufacturedProductStockKey As RecordKey,
        pmpsa.SAPMessage,
        ROW_NUMBER() OVER (PARTITION BY pmpsa.PostedManufacturedProductStockKey ORDER BY pmpsa.AuditDate DESC) AS RowNum
    FROM PostedManufacturedProductStockAudit pmpsa (NOLOCK)
    WHERE pmpsa.StatusCode = 'E'
),

--Find the quantity difference between all 601 and 602 records that are marked completed.  
MBP_601_602_Sum AS (
    SELECT 
        Batch,
        Plant,
        SUM(CASE WHEN Movtype = '602' THEN (Quantity * -1) ELSE Quantity END) As QuantitySum
    FROM MMMovsbyPlant m WITH (NOLOCK)
    WHERE m.MovType IN ('601','602') 
        AND m.ProcessStatus IN ('F', 'T')
    GROUP BY Batch, Plant
),
  
-- Load X and W records from PIC and PMPS. Get their error message from ErrorMessages. 
-- Attempts to guess if inventory exists in SAP still by only loading X and W records that have had a 601 occur. This is done by inner joining to MBP_601_602_Sum. 
-- Also filter out where the sum of the 601's and 602's quantity is 0. When 0 it's still in inventory and hasn't been shipped.
X_and_W AS (
  SELECT pic.PostedInventoryConsumptionsKey As RecordKey, StatusCode, pic.MovType, CreateDateTime, e.SAPMessage, InterfaceDate, pic.Batch, pic.Plant, LineAmount As ReceivingPlant, '' As StatusInd, Quantity, UOM,  MaterialNumber, StorageLoc, '' As VendorBatch, DocHeader, 'PIC' As TableName
  FROM PostedInventoryConsumptions pic WITH (NOLOCK)
    JOIN MBP_601_602_Sum s WITH (NOLOCK) ON
      s.Batch = pic.Batch AND
      s.QuantitySum <> 0
    LEFT JOIN ErrorMessages e WITH (NOLOCK) ON 
      e.RecordKey = pic.PostedInventoryConsumptionsKey AND 
      e.RowNum = 1
  WHERE StatusCode In ('X', 'W')
  UNION ALL
  SELECT pmps.PostedManufacturedProductStockKey As RecordKey, StatusCode, pmps.MovType, CreateDateTime, e.SAPMessage, InterfaceDate, pmps.Batch, pmps.Plant, '' As ReceivingPlant, StatusInd, Quantity, UOM,  MaterialNumber, StorageLoc, VendorBatch, DocHeader, 'PMPS' As TableName
  FROM PostedManufacturedProductStock pmps WITH (NOLOCK)
    JOIN MBP_601_602_Sum s WITH (NOLOCK) ON
      s.Batch = pmps.Batch AND
      s.QuantitySum <> 0
    LEFT JOIN ErrorMessages e WITH (NOLOCK) ON 
      e.RecordKey = pmps.PostedManufacturedProductStockKey AND 
      e.RowNum = 1
  WHERE StatusCode In ('X', 'W')
),

-- Get SOI inventory where balance is not 0. 
BatchInInventoryStill AS (
  SELECT 
    SUM(i.Units) As QuantitySum, 
    xw.Batch, 
    xw.Plant
  FROM X_and_W xw
    INNER JOIN OK..LotNo ln WITH (NOLOCK) ON 
      CAST(ln.LotNoKey As varchar) = xw.Batch
    INNER JOIN OK..Inventory i WITH (NOLOCK) ON
        i.LotNo = ln.LotNo AND 
        i.DateProduced = ln.DateProduced AND 
        i.ProductCode = ln.ProductCode   
  GROUP BY
    xw.Batch, 
    xw.Plant
  Having SUM(i.Units) <> 0
),

-- Filter out what is still in inventory found by the previous query.
ResultsCTE AS (
  Select xw.*
  From X_and_W xw
  Left Join BatchInInventoryStill b ON
    b.Batch = xw.Batch 
  Where b.Batch IS NULL
  
)

Select * From ResultsCTE ORDER BY CreateDateTime desc

