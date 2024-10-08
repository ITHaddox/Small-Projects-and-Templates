USE [SOITOSAP]
GO
/****** Object:  StoredProcedure [dbo].[PRC_UpdateWaitingSAPIntegration_SP]    Script Date: 09/10/2024 9:58:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/******************************************************************************************************************************************	
  doc20240619TMH:HD#351037: Manages waiting statuses, ensuring sequential processing for SOI to SAP production, adjustments, transfers
                and hold status changes.
  doc20240621TMH:HD#351037: Waiting records to not continue to wait for related records older than release date of stored procedure.    
  doc20240703TMH:HD#353442: Predicted production and adjustment temp tables were using integer for LotNoKey since the datatype is 
                determined when those tables are created. This caused the SP to fail on the job when trying to compare waiting records 
                for batch 'I30727500'.
  doc20240805TMH:HD#354291,353541: Added logic for K056 303 wait on 311 to happen. This is to support BMEX's changes to fix storage location errors.
                Removed @StartDateTime condition since it has been long enough that this condition will always be false.
                Changed StopWaiting column to datatype to Bit. 
  doc20240910TMH:HD#367662: Supporting the previous WM release by not making K056 transfer-out records wait for 311s if the batch was already 
                in storageLoc 9003 when the code released on 9/1/24. This was already a known issue previous to launch but it was
                discussed to not have me make changes at that time. 

  Exec [dbo].[PRC_UpdateWaitingSAPIntegration_SP]
*******************************************************************************************************************************************/
ALTER PROCEDURE [dbo].[PRC_UpdateWaitingSAPIntegration_SP] 
As
Begin
	Set NOCOUNT On
  Set XACT_ABORT On

  Declare 
    @StartDateTime DateTime = DATEADD(DAY, -30, GETDATE()), --GETDATE() doc20240805TMH
    @RelatedStartDateTime DateTime = '2024-06-21 12:16:00:000'    --doc20240621TMH

  /* doc20240805TMH It has been long enough that this condition will always be false, so not needed anymore.
  Set @StartDateTime = Case When DATEADD(DAY, -30, @StartDateTime) < '2024-06-21' Then '2024-06-21'
                      Else DATEADD(DAY, -30, @StartDateTime)
                  End */  

  /*================================================================================================================================================================
  Insert into #Waiting all records in PIC and PMPS that have 'W'aiting StatusCode. All records will be defaulted with StopWaiting = 1 which means True. 
  ================================================================================================================================================================*/
  Drop Table If Exists #Waiting
  Create Table #Waiting (
    StopWaiting Bit,  --Varchar(3), doc20240805TMH
    RecordKey Int,
    DocHeader VarChar(10),
    MovType VarChar(3),
    Plant VarChar(4),
    StorageLoc VarChar(4), --doc20240805TMH
    Batch VarChar(14),
    CreateDateTime DateTime)

  Insert Into #Waiting
  Select 1, PostedManufacturedProductStockKey, DocHeader, MovType, Plant, StorageLoc, Batch, CreateDateTime
  From PostedManufacturedProductStock pmps (NoLock)
  Where pmps.StatusCode = 'W' 
    And CreateDateTime >= @StartDateTime
  Union All
  Select 1, PostedInventoryConsumptionsKey, DocHeader, MovType, Plant, StorageLoc, Batch, CreateDateTime
  From PostedInventoryConsumptions pic (NoLock)
  Where pic.StatusCode = 'W' 
    And CreateDateTime >= @StartDateTime

  /*================================================================================================================================================================
  Load #PendingProduction and #PendingAdjustments for 501, 502, and 202 records that are not in PMPS and PIC yet due to delay of SQL jobs that exocute
  [Prc_SOIToSAPPostedManufacturedProductStock_SP] and [Prc_SOIToSAPPostedInventoryConsumptions_SP]. Nothing waits for 201 negative adjustment so those are ignored.
  ================================================================================================================================================================*/
  Select Distinct 
    Cast(ln.LotNoKey As VarChar(14)) As Batch, 
    pw.SAPLogisticCenter As Plant
  Into #PendingProduction
  From OK.dbo.ProductionAdjustmentDetail pad
    Join OK.dbo.ProductionAdjustment pa On 
      pa.ProductionAdjustmentNo = pad.ProductionAdjustmentNo
    Join OK.dbo.Product p On 
      pad.ProductCode = p.ProductCode
    Join SOIToSAP.dbo.PlantWarehouse pw On 
      pa.Warehouse = pw.SOIWarehouse
    Join OK.dbo.LotNo ln On 
      ln.ProductCode = pad.ProductCode And 
      ln.LotNo = pad.LotNo And 
      ln.DateProduced = pad.DateProduced
  Where pa.TransactionType = 'P' 
    And pa.EnterDate >= @StartDateTime
    And pw.SystemCode = 1
    And p.SystemCode = 1
    And pw.ActiveFlag = 'A'
    And pad.SAPReportedFlag = 'N'
    And pad.ProductionAdjustmentDetail > 36624484  
    
  Select Distinct 
    Case 
      When p.SystemCode = 2 And p.NonLotTracked = 'N' Then pad.LotNo
      When p.SystemCode = 1 Then Cast(ln.LotNoKey As VarChar(14)) --doc20240703TMH
      Else ''
    End As Batch,
    pw.SAPLogisticCenter As Plant,
    pad.AuditDate
  Into #PendingAdjustments
  From OK.dbo.ProductionAdjustmentDetail pad
    Join OK.dbo.ProductionAdjustment pa On 
      pad.ProductionAdjustmentNo = pa.ProductionAdjustmentNo
    Join OK.dbo.Product p On 
      pad.Productcode = p.ProductCode 
    Join SOIToSAP.dbo.PlantWarehouse pw On 
      pw.SystemCode = p.SystemCode And 
      pa.Warehouse = pw.SOIWarehouse
    Join OK.dbo.LotNo ln On 
      ln.ProductCode = pad.ProductCode And 
      ln.DateProduced = pad.DateProduced And 
      ln.LotNo = pad.LotNo
  Where pa.TransactionType = 'A'
    And pa.SAPMaterialDocNumber Is Null 
    And pad.SAPReportedFlag = 'N'
    And pa.EnterDate >= @StartDateTime  
    And pad.ProductCode <> 500144 
    And pad.Units > 0.0000
    And pw.ActiveFlag = 'A'

  /*================================================================================================================================================================
  This section takes the #Waiting records and finds any records/movTypes they still need to wait for that happened before them.
  ================================================================================================================================================================*/    
  -- Wait for all production that isn't a 501 yet. 
  Update w
  Set StopWaiting = 0
  From #Waiting w
  Join #PendingProduction pp On
    w.Batch = pp.Batch And
    w.Plant = pp.Plant

  -- Wait for adjustments that are not a 202 yet. 
  Update w
  Set StopWaiting = 0
  From #Waiting w
  Join #PendingAdjustments pa On
    w.Batch = pa.Batch And
    w.Plant = pa.Plant And
    w.CreateDateTime > pa.AuditDate

  -- Wait for other MovTypes in PMPS (production/hold status) if created before them.
  Update w
  Set StopWaiting = 0
  From #Waiting w
  Join PostedManufacturedProductStock pmps On
    w.Batch = pmps.Batch And
    w.Plant = pmps.Plant    
  Where pmps.StatusCode In ('X', 'E', 'R', 'N', 'W') And 
        pmps.CreateDateTime >= @RelatedStartDateTime And --doc20240621TMH
        pmps.CreateDateTime < w.CreateDateTime 

  -- Wait for other MovTypes in PIC (adjustments/transfers) if created before them. (Nothing waits for 201) 
  Update w
  Set StopWaiting = 0
  From #Waiting w
  Join PostedInventoryConsumptions pic On
    w.Batch = pic.Batch    
  Where pic.StatusCode In ('X', 'E', 'R', 'N', 'W')
    And pic.CreateDateTime >= @RelatedStartDateTime --doc20240621TMH
    And pic.CreateDateTime < w.CreateDateTime
    And pic.MovType <> '201'
    And (w.Plant = pic.Plant Or (w.DocHeader = pic.DocHeader And    --Checking for 305s looking for 303s since they will have different plants. DocHeader = TransferDetailKey.
                                 pic.MovType = '303' And
                                 w.MovType = '305'))
  
  -- Wait for 311 if 303 is made by K056. This is to support BMEX's changes to fix storage location errors. A 311 changes the batch's storage location. doc20240805TMH 
  Update w
  Set StopWaiting = 0 --keep waiting
  From #Waiting w
  Left Join BatchesPreLaunch_K056_9003 b On         --doc20240910TMH
    w.Batch = b.Batch And                     
    b.HasShippedOnce = 0                      
  Left Join MMMovsbyPlant mbp311 On 
    w.Batch = mbp311.Batch And 
    w.Plant = mbp311.Plant And
    mbp311.MovType = '311' And
    mbp311.StorageLoc = '9001' And
    mbp311.ReceivingStorageLoc = '9003'
  Where b.Batch Is Null                             --doc20240910TMH
    And mbp311.Batch Is Null
    And w.Plant = 'K056'
    And w.MovType = '303'
    And w.StorageLoc = '9003'     

  -- Wait for 311 if record is a 321 or 343 related to a transfer for K056.
  Update w
  Set StopWaiting = 0 --keep waiting
  From #Waiting w
  Left Join BatchesPreLaunch_K056_9003 b On         --doc20240910TMH
    w.Batch = b.Batch And
    b.HasShippedOnce = 0      
  Left Join MMMovsbyPlant mbp311 On 
    w.Batch = mbp311.Batch And 
    w.Plant = mbp311.Plant And
    mbp311.MovType = '311' And
    mbp311.StorageLoc = '9001' And
    mbp311.ReceivingStorageLoc = '9003'
  Left Join MMMovsbyPlant mbpHold On
    mbp311.Batch = mbpHold.Batch And 
    mbp311.Plant = mbpHold.Plant And
    mbpHold.MovType In ('322','344') And
    mbpHold.StorageLoc = '9003' And
    mbpHold.InterfaceDate > mbp311.InterfaceDate
  Where b.Batch Is Null                             --doc20240910TMH
    And mbpHold.Batch Is Null
    And w.Plant = 'K056'
    And w.MovType In ('321', '343')
    And w.StorageLoc = '9003'   

 
  /*================================================================================================================================================================
  This section tells records to stop waiting if they didn't find anything to wait for in previous queries.
  ================================================================================================================================================================*/
  Update PostedManufacturedProductStock
  Set StatusCode = 'N', Resends = 1
  From #Waiting w
  Where PostedManufacturedProductStockKey = w.RecordKey
    And w.StopWaiting = 1

  Update PostedInventoryConsumptions
  Set StatusCode = 'N', Resends = 1
  From #Waiting w
  Where PostedInventoryConsumptionsKey = w.RecordKey
    And w.StopWaiting = 1

  /*================================================================================================================================================================
  doc20240910TMH Remove this section if all records in table BatchesPreLaunch_K056_9003 have a HasShippedOnce = 1.
  This is to support the WM changes made K056 on 9/1/24. There were 446 batches that were already in K056 9003. 
  ================================================================================================================================================================*/
  Update b                                          --doc20240910TMH
  Set HasShippedOnce = 1
  From BatchesPreLaunch_K056_9003 b 
  Join PostedInventoryConsumptions pic On
    pic.Batch = b.Batch
  Where b.HasShippedOnce = 0
    And pic.Plant = 'K056' 
    And pic.MovType = '303' 
    And pic.StatusCode = 'C'
    And pic.CreateDateTime > '2024-09-01 16:17:42'
End

GO