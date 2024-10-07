USE SOITOSAP
GO

/**********************************************************************************************************************************************
SP Version
Find SAP Errors and Related Record History V6.2 SP Version

  Finds failed or waiting records in the PIC and PMPS tables. Then it finds their related records for that batch 
    so the history/lifecycle can be viewed. 
  This also shows the last error message that each record had. This is done by partitioning the audit tables by batch and pulling the last 
    time the record was status code 'E'. This is because when records change to 'X' the error message gets updated to a generic useless message.
  Records are grouped together by batch and then in ascending order for each chunk of records for that batch.

Exec [RPT_SAPIntegrationErrorReport_SP] '2000-08-01 00:00:00', '2024-09-06 00:00:00', 1  
**********************************************************************************************************************************************/

CREATE OR ALTER PROC [dbo].[RPT_SAPIntegrationErrorReport_SP]

  @StartSearchDateTime DATETIME, -- Searching for 'X' and 'W' records. 
  @EndSearchDateTime DATETIME,
  @ReportType SmallInt
  
AS
BEGIN

  DECLARE 
    @BeforeReleaseDateTime DATETIME = '2024-06-21 12:02:00', -- DO NOT CHANGE!!! Time of process order fix release
    @WaitingTooLong INT = 60  -- minutes

  -- Create a temporary table for MovType descriptions
  Drop Table If Exists #MovTypeDescriptions;
  Create Table #MovTypeDescriptions (MovType VarChar(3), [Description] VarChar(40), TableNameAbbreviation VarChar(5), TableName VarChar(50));

  -- Insert MovType descriptions into the temporary table
  Insert Into #MovTypeDescriptions (MovType, [Description], TableNameAbbreviation, TableName)
  Values
    ('201', 'Consumption'               ,'PIC',  'PostedInventoryConsumptions'),
    ('202', 'Consumption Reversal'      ,'PIC',  'PostedInventoryConsumptions'),
    ('303', 'Transfer Out'              ,'PIC',  'PostedInventoryConsumptions'),
    ('304', 'Transfer Reversal'         ,'PIC',  'PostedInventoryConsumptions'),
    ('305', 'Transfer Receive In'       ,'PIC',  'PostedInventoryConsumptions'),
    ('501', 'Production'                ,'PMPS', 'PostedManufacturedProductStock'),
    ('502', 'Production Reversal'       ,'PMPS', 'PostedManufacturedProductStock'),
    ('321', 'Quality --> UnRestricted'  ,'PMPS', 'PostedManufacturedProductStock'),
    ('322', 'UnRestricted --> Quality'  ,'PMPS', 'PostedManufacturedProductStock'),
    ('343', 'Blocked --> UnRestricted'  ,'PMPS', 'PostedManufacturedProductStock'),
    ('344', 'UnRestricted --> Blocked'  ,'PMPS', 'PostedManufacturedProductStock'),
    ('349', 'Blocked --> Quality'       ,'PMPS', 'PostedManufacturedProductStock'),
    ('350', 'Quality --> Blocked'       ,'PMPS', 'PostedManufacturedProductStock'),
    ('601', 'Sales Order GI'            ,'MBP',  'MMMovsByPlant'),
    ('602', 'Reversal Sales Order GI'   ,'MBP',  'MMMovsByPlant'),
    ('641', 'STO GI'                    ,'MBP',  'MMMovsByPlant'),
    ('642', 'Reversal STO GI'           ,'MBP',  'MMMovsByPlant'),
    ('101', 'Received STO GI'           ,'MBP',  'MMMovsByPlant'),
    ('102', 'Reversal Received STO GI'  ,'MBP',  'MMMovsByPlant'),
    ('653', 'GD Return Unrestr'         ,'MBP',  'MMMovsByPlant'),  --Returned from customer. This is being used when a product is returned and the credit memo is processed on the sales order delivery document. 
    ('551', 'GI Scrapping'              ,'MBP',  'MMMovsByPlant'),  --Example damaged or non-usable inventory being thrown away. I believe K007 is the only one at this time using it but that could change. 
    ('711', 'Pos Adjustment WM Module'  ,'MBP',  'MMMovsByPlant'),  --Inventory +pos adjustment by plants that have the WM module.
    ('712', 'Neg Adjustment WM Module'  ,'MBP',  'MMMovsByPlant');  --Inventory -neg adjustment by plants that have the WM module.


  -- Create a combined temp table for PIC and PMPS
  IF OBJECT_ID('tempdb..#Records') IS NOT NULL DROP TABLE #Records;
  CREATE TABLE #Records (
    RecordKey INT,
    TableN VARCHAR(5),
    StatusCode VARCHAR(1),  
    MovType VARCHAR(10),
    MovTypeDescription VarChar(40), 
    Quantity FLOAT,
    UOM VARCHAR(10),
    Batch VARCHAR(50),
    Plant VARCHAR(4),  
    StorageLoc VARCHAR(4),
    ReceivingPlant VARCHAR(4),  
    CreateDateTime DATETIME, 
    InterfaceDate DATETIME,
    SAPMessage VARCHAR(500),  
    DocHeader VARCHAR(10),
    VenderBatch VARCHAR(15), 
    MaterialNumber VARCHAR(50),
    StatusInd VARCHAR(1),
    SAPDocument VARCHAR(10),
    DocDate DATE, 
    MaterialDocYear VARCHAR(4),
    PostingDate DATE,
    DateManufacture DATE,
    DateSLEDBBD DATE,
    LineItem INT,
    LineItemText VARCHAR(50),
    SAPCostCenter VARCHAR(10), 
    SOIAccount VARCHAR(14), 
    Comment VARCHAR(100), 
    PositionNumber INT,
    DocumentType VARCHAR(2),
    TransactionCode VARCHAR(20),
    PurchaseOrder VARCHAR(10),
    PurchaseOrderLine VARCHAR(10),
    DeliveryNo VARCHAR(10),
    SalesOrderNo VARCHAR(10),  
    TableName VARCHAR(50),  
    BeforeOrAfterRelease VARCHAR(20)
  );

  -- Create temp table for related records
  IF OBJECT_ID('tempdb..#RelatedRecords') IS NOT NULL DROP TABLE #RelatedRecords;
  CREATE TABLE #RelatedRecords (
    RecordKey INT,
    TableN VARCHAR(5),
    StatusCode VARCHAR(10),
    MovType VARCHAR(10),
    MovTypeDescription VarChar(40),
    Quantity FLOAT,
    UOM VARCHAR(10),  
    Batch VARCHAR(50),
    Plant VARCHAR(4),  
    StorageLoc VARCHAR(4),
    ReceivingPlant VARCHAR(4),  
    CreateDateTime DATETIME,
    InterfaceDate DATETIME,
    SAPMessage VARCHAR(500),
    DocHeader VARCHAR(10),
    VenderBatch VARCHAR(15),
    MaterialNumber VARCHAR(50),  
    StatusInd VARCHAR(1),
    SAPDocument VARCHAR(10),
    DocDate DATE, 
    MaterialDocYear VARCHAR(4),
    PostingDate DATE,
    DateManufacture DATE,
    DateSLEDBBD DATE,
    LineItem INT,
    LineItemText VARCHAR(50),
    SAPCostCenter VARCHAR(10), 
    SOIAccount VARCHAR(14), 
    Comment VARCHAR(100), 
    PositionNumber INT,
    DocumentType VARCHAR(2),
    TransactionCode VARCHAR(20),
    PurchaseOrder VARCHAR(10),
    PurchaseOrderLine VARCHAR(10),
    DeliveryNo VARCHAR(10),
    SalesOrderNo VARCHAR(10),  
    TableName VARCHAR(50),  
    BeforeOrAfterRelease VARCHAR(20)
  );

 
  --Create temp tables to get last error message from latest audit records.
  -- PIC 
  IF OBJECT_ID('tempdb..#LatestAuditPIC') IS NOT NULL DROP TABLE #LatestAuditPIC;
  CREATE TABLE #LatestAuditPIC (
    PostedInventoryConsumptionsKey INT,
    SAPMessage VARCHAR(500),
    RowNum INT
  );

  -- PMPS 
  IF OBJECT_ID('tempdb..#LatestAuditPMPS') IS NOT NULL DROP TABLE #LatestAuditPMPS;
  CREATE TABLE #LatestAuditPMPS (
    PostedManufacturedProductStockKey INT,
    SAPMessage VARCHAR(500),
    RowNum INT
  );

  -- MBP 
  IF OBJECT_ID('tempdb..#LatestAuditMBP') IS NOT NULL DROP TABLE #LatestAuditMBP;
  CREATE TABLE #LatestAuditMBP (
    MMMovsByPlantKey INT,
    SAPMessage VARCHAR(500),
    RowNum INT
  );

  -- Populate #LatestAuditPIC
  INSERT INTO #LatestAuditPIC
  SELECT 
      pica.PostedInventoryConsumptionsKey,
      pica.SAPMessage,
      ROW_NUMBER() OVER (PARTITION BY pica.PostedInventoryConsumptionsKey ORDER BY pica.AuditDate DESC) AS RowNum
  FROM PostedInventoryConsumptionsAudit pica (NOLOCK)
  WHERE pica.StatusCode = 'E';

  -- Populate #LatestAuditPMPS
  INSERT INTO #LatestAuditPMPS
  SELECT 
      pmpsa.PostedManufacturedProductStockKey,
      pmpsa.SAPMessage,
      ROW_NUMBER() OVER (PARTITION BY pmpsa.PostedManufacturedProductStockKey ORDER BY pmpsa.AuditDate DESC) AS RowNum
  FROM PostedManufacturedProductStockAudit pmpsa (NOLOCK)
  WHERE pmpsa.StatusCode = 'E';

  -- Populate #LatestAuditMBP
  INSERT INTO #LatestAuditMBP
  SELECT 
      mbpa.MMMovsByPlantKey,
      mbpa.SOIErrorMessage As SAPMessage,
      ROW_NUMBER() OVER (PARTITION BY mbpa.MMMovsByPlantKey ORDER BY mbpa.AuditDate DESC) AS RowNum
  FROM MMMovsbyPlantAudit mbpa (NOLOCK)
  WHERE mbpa.ProcessStatus = 'E';

  -- Load #Records with PIC data where waiting too long or failed
  INSERT INTO #Records
  SELECT
      pic.PostedInventoryConsumptionsKey AS RecordKey,
      mt.TableNameAbbreviation As TableN,
      pic.StatusCode,
      pic.MovType,
      mt.[Description],   
      pic.Quantity,
      pic.UOM,
      TRIM(pic.Batch),
      pic.Plant,    
      pic.StorageLoc,
      pic.LineAmount As ReceivingPlant,    
      pic.CreateDateTime,
      pic.InterfaceDate,
      la.SAPMessage,
      pic.DocHeader,
      '' As VendorBatch,
      pic.MaterialNumber,  
      '' As StatusInd,
      pic.SAPDocument,
      pic.DocDate, 
      pic.MaterialDocYear,
      pic.PostingDate,
      '' As DateManufacture,
      '' As DateSLEDBBD,
      pic.LineItem,
      pic.LineItemText,
      pic.SAPCostCenter, 
      pic.SOIAccount, 
      pic.Comment,
      '' As PositionNumber,
      '' As DocumentType,
      '' As TransactionCode,
      '' As PurchaseOrder,
      '' As PurchaseOrderLine,
      '' As DeliveryNo,
      '' As SalesOrderNo,     
      mt.TableName,    
      CASE WHEN pic.CreateDateTime > @BeforeReleaseDateTime THEN 'After Release' ELSE 'Before Release' END AS BeforeOrAfterRelease
  FROM PostedInventoryConsumptions pic WITH (NOLOCK)
  JOIN #MovTypeDescriptions mt On mt.MovType = pic.MovType And mt.TableNameAbbreviation = 'PIC'
  LEFT JOIN #LatestAuditPIC la WITH (NOLOCK) ON la.PostedInventoryConsumptionsKey = pic.PostedInventoryConsumptionsKey AND la.RowNum = 1
  WHERE pic.CreateDateTime BETWEEN @StartSearchDateTime AND @EndSearchDateTime
    AND (pic.StatusCode = 'X' OR (pic.StatusCode = 'W' AND DATEDIFF(MINUTE, pic.CreateDateTime, GETDATE()) > @WaitingTooLong))

  -- Load #Records with PMPS data where waiting too long or failed
  INSERT INTO #Records
  SELECT
      pmps.PostedManufacturedProductStockKey AS RecordKey,
      mt.TableNameAbbreviation As TableN,
      pmps.StatusCode,
      pmps.MovType,
      mt.[Description],
      pmps.Quantity,
      pmps.UOM,
      TRIM(pmps.Batch),
      pmps.Plant,    
      pmps.StorageLoc,
      '' As ReceivingPlant, 
      pmps.CreateDateTime,
      pmps.InterfaceDate,
      la.SAPMessage,       
      pmps.DocHeader,
      pmps.VendorBatch,
      pmps.MaterialNumber,  
      pmps.StatusInd,
      pmps.SAPDocument , 
      pmps.DocDate , 
      pmps.MaterialDocYear ,
      pmps.PostingDate ,
      pmps.DateManufacture ,
      pmps.DateSLEDBBD ,
      pmps.LineItem ,
      pmps.LineItemText ,
      pmps.SAPCostCenter , 
      '' As SOIAccount , 
      '' As Comment ,
      '' As PositionNumber,
      '' As DocumentType,
      '' As TransactionCode,
      '' AS PurchaseOrder,
      '' AS PurchaseOrderLine ,
      '' AS DeliveryNo ,
      '' AS SalesOrderNo ,     
      mt.TableName,    
      CASE WHEN pmps.CreateDateTime > @BeforeReleaseDateTime THEN 'After Release' ELSE 'Before Release' END AS BeforeOrAfterRelease
  FROM PostedManufacturedProductStock pmps WITH (NOLOCK)
  Join #MovTypeDescriptions mt On mt.MovType = pmps.MovType And mt.TableNameAbbreviation = 'PMPS'
  LEFT JOIN #LatestAuditPMPS la WITH (NOLOCK) ON la.PostedManufacturedProductStockKey = pmps.PostedManufacturedProductStockKey AND la.RowNum = 1
  WHERE pmps.CreateDateTime BETWEEN @StartSearchDateTime AND @EndSearchDateTime
    AND (pmps.StatusCode = 'X' OR (pmps.StatusCode = 'W' AND DATEDIFF(MINUTE, pmps.CreateDateTime, GETDATE()) > @WaitingTooLong));

  -- Populate #RelatedRecords with related PIC records
  INSERT INTO #RelatedRecords
  SELECT DISTINCT
    pic.PostedInventoryConsumptionsKey AS RecordKey,
    mt.TableNameAbbreviation As TableN,
    pic.StatusCode,
    pic.MovType,
    mt.[Description],
    pic.Quantity,
    pic.UOM,
    TRIM(pic.Batch),
    pic.Plant,
    pic.StorageLoc,
    pic.LineAmount As ReceivingPlant,
    pic.CreateDateTime,
    pic.InterfaceDate,
    la.SAPMessage,        
    pic.DocHeader,
    '' As VendorBatch,
    pic.MaterialNumber,  
    '' As StatusInd,
    pic.SAPDocument,
    pic.DocDate, 
    pic.MaterialDocYear,
    pic.PostingDate,
    '' As DateManufacture,
    '' As DateSLEDBBD,
    pic.LineItem,
    pic.LineItemText,
    pic.SAPCostCenter, 
    pic.SOIAccount, 
    pic.Comment,
    '' As PositionNumber,
    '' As DocumentType,
    '' As TransactionCode,
    '' As PurchaseOrder,
    '' As PurchaseOrderLine,
    '' As DeliveryNo,
    '' As SalesOrderNo,     
    mt.TableName,    
    CASE WHEN pic.CreateDateTime > @BeforeReleaseDateTime THEN 'After Release' ELSE 'Before Release' END AS BeforeOrAfterRelease
  FROM PostedInventoryConsumptions pic WITH (NOLOCK)
  JOIN #Records r ON pic.Batch = r.Batch 
  JOIN #MovTypeDescriptions mt On mt.MovType = pic.MovType And mt.TableNameAbbreviation = 'PIC'
  LEFT JOIN #LatestAuditPIC la WITH (NOLOCK) ON la.PostedInventoryConsumptionsKey = pic.PostedInventoryConsumptionsKey AND la.RowNum = 1
  WHERE pic.Batch <> '';

  -- Populate #RelatedRecords with related PMPS records
  INSERT INTO #RelatedRecords
  SELECT DISTINCT
    pmps.PostedManufacturedProductStockKey AS RecordKey,
    mt.TableNameAbbreviation As TableN,
    pmps.StatusCode,
    pmps.MovType,
    mt.[Description],
    pmps.Quantity,
    pmps.UOM,    
    TRIM(pmps.Batch),
    pmps.Plant,
    pmps.StorageLoc,
    '' As ReceivingPlant,    
    pmps.CreateDateTime,
    pmps.InterfaceDate,
    la.SAPMessage,
    pmps.DocHeader,
    pmps.VendorBatch,
    pmps.MaterialNumber,  
    pmps.StatusInd,
    pmps.SAPDocument, 
    pmps.DocDate, 
    pmps.MaterialDocYear,
    pmps.PostingDate,
    pmps.DateManufacture,
    pmps.DateSLEDBBD,
    pmps.LineItem,
    pmps.LineItemText,
    pmps.SAPCostCenter, 
    '' As SOIAccount, 
    '' As Comment,
    '' As PositionNumber,
    '' As DocumentType,
    '' As TransactionCode,
    '' AS PurchaseOrder,
    '' AS PurchaseOrderLine,
    '' AS DeliveryNo,
    '' AS SalesOrderNo,     
    mt.TableName,    
    CASE WHEN pmps.CreateDateTime > @BeforeReleaseDateTime THEN 'After Release' ELSE 'Before Release' END AS BeforeOrAfterRelease
  FROM PostedManufacturedProductStock pmps WITH (NOLOCK)
  JOIN #Records r ON pmps.Batch = r.Batch 
  Join #MovTypeDescriptions mt On mt.MovType = pmps.MovType And mt.TableNameAbbreviation = 'PMPS'
  LEFT JOIN #LatestAuditPMPS la WITH (NOLOCK) ON la.PostedManufacturedProductStockKey = pmps.PostedManufacturedProductStockKey AND la.RowNum = 1 
  WHERE pmps.Batch <> '';

  -- Populate #RelatedRecords with related MBP records
  INSERT INTO #RelatedRecords
  SELECT DISTINCT
    mbp.MMMovsByPlantKey AS RecordKey,
    mt.TableNameAbbreviation As TableN,
    mbp.ProcessStatus As StatusCode,
    mbp.MovType,
    mt.[Description],
    mbp.Quantity,
    mbp.UOM,    
    TRIM(mbp.Batch),
    mbp.Plant,
    mbp.StorageLoc,
    mbp.ReceivingPlant,    
    mbp.InterfaceDate As CreateDateTime,
    mbp.InterfaceDate,
    la.SAPMessage,
    '' As DocHeader,
    mbp.VendorBatch,
    mbp.MaterialNumber,  
    '' As StatusInd,
    mbp.MaterialDocNumber As SAPDocument, 
    mbp.EntryDate As DocDate, 
    mbp.MaterialDocYear,
    mbp.PostingDate,
    mbp.ManufactureDate AS DateManufacture,
    '' As DateSLEDBBD,
    '' As LineItem,
    '' As LineItemText,
    '' As SAPCostCenter, 
    '' As SOIAccount, 
    '' As Comment,
    mbp.PositionNumber,
    mbp.DocumentType,
    mbp.TransactionCode,
    mbp.PurchaseOrder,
    mbp.PurchaseOrderLine,
    mbp.DeliveryNo,
    mbp.SalesOrderNo,    
    mt.TableName,    
    CASE WHEN mbp.InterfaceDate > @BeforeReleaseDateTime THEN 'After Release' ELSE 'Before Release' END AS BeforeOrAfterRelease
  FROM MMMovsbyPlant mbp WITH (NOLOCK)
  JOIN #Records r ON mbp.Batch = r.Batch 
  Join #MovTypeDescriptions mt On mt.MovType = mbp.MovType And mt.TableNameAbbreviation = 'MBP'
  LEFT JOIN #LatestAuditMBP la WITH (NOLOCK) ON la.MMMovsByPlantKey = mbp.MMMovsByPlantKey AND la.RowNum = 1 
  WHERE mbp.Batch <> '';

  -- Final combined query
  SELECT Distinct r.* 
  FROM #Records r
  LEFT JOIN #RelatedRecords rr ON r.RecordKey = rr.RecordKey
  WHERE rr.RecordKey IS NULL
  UNION ALL
  SELECT Distinct * 
  FROM #RelatedRecords 
  ORDER BY 
    Batch,
    CreateDateTime; 

  -- Save server memory
  IF OBJECT_ID('tempdb..#MovTypeDescriptions') IS NOT NULL DROP TABLE #MovTypeDescriptions;
  IF OBJECT_ID('tempdb..#Records') IS NOT NULL DROP TABLE #Records;
  IF OBJECT_ID('tempdb..#RelatedRecords') IS NOT NULL DROP TABLE #RelatedRecords;
  IF OBJECT_ID('tempdb..#LatestAuditPIC') IS NOT NULL DROP TABLE #LatestAuditPIC;
  IF OBJECT_ID('tempdb..#LatestAuditPMPS') IS NOT NULL DROP TABLE #LatestAuditPMPS;
  IF OBJECT_ID('tempdb..#LatestAuditMBP') IS NOT NULL DROP TABLE #LatestAuditMBP;

End 

