USE [ODS-FSM]
GO
/****** Object:  StoredProcedure [CAT2].[Prc_Cat2IntegrationTableExport_SP]    Script Date: 03/08/2024 2:00:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tyler M Haddox
-- Create date: 09/08/2022
-- Description:	Copies data from Cat2 server to corporate server.
-- =============================================
/*
doc20230306TMH: HD#313066, The record being inserted into OKSQL01P.OK.INTF_Exports will now be transfered with STATUS = 'R'. 
doc20230623ER: HD#303007, Added additional columns to integration for receiving.
doc20230623ER: HD#303007, Added integration for the INTF_PRODORDTRANS table.
doc20231009ER: HD#337084, Added additional columns to the INTF_PRODORDTRANS table.
doc20231130TMH: HD#340314, HD#340916, Increased the speed of this storeprocedure.
	              Main change is removing the cursor and processing records in bulk.
doc20231212ER: HD#340916, Removed the link to INTF_HOLDCLASSIFICATION where it is updating the INTF_EXPORTS status. 
               There were some INTF_EXPORTS records that did not have a link to INTF_HOLDCLASSIFICATION causing the INTF_EXPORTS records to not get updated correctly.
doc20231212TMH: HD#340916, Added join to only insert pallets in INTF_Exports for the HoldClassifications section.
doc20231212TMH2: HD#340916, CAT2.INTF_CaseDtls gets StatusFlag updated to P if Transaction <> P else X
                CAT2.INTF_HoldClassifications gets StatusFlag updated to P if ObjectType = 'Pallet' Else X
                CAT2.INTF_Exports records that join to these other 2 tables will have the same condition and have the status updated the same way.
doc20231219ER:HD#341445, Corrected an issue where the process was trying to insert duplicate records into the INTF_EXPORTS table.
doc20231219TMH: HD#341256, 341357 Added condition, Where CoolerID <> '', when transfering INTF_CaseDtls. Sets those records to status = X. 
                This is because cases are getting produced without positioning it so it doesn't exist in a cooler when cases are removed.
                Added section the sets status to 'X' for any records in INTF_Exports that have ProcessIDs that we don't transfer.
                Made @TransferredProcessID to load the ones we do use.
doc20230104TMH: HD#342266, Fixed LBL INTF_CaseDtls and INTF_Exports from sending records not needed. 
doc20240129TMH: HD#343788, Filtered out audit records from sending to SOI in the INTF_CoolerMove table. Transaction = 'A' means it's an audit record.
doc20240213ER: HD#345126, Added new columns PRODUCTIONDATE_ITEM and SHIFT_ITEM to the INTF_COOLERMOVE table.
doc20240311TMH:HD#346644, Added code to only process 1 hold classification record per pallet(ObjectID). Using temp table named #UniquePalletAndCode 
                it will use the last created record for each ObjectID.
*/

ALTER PROCEDURE [CAT2].[Prc_Cat2IntegrationTableExport_SP] 
AS
BEGIN
	SET NOCOUNT ON;
  SET XACT_ABORT ON

	Declare               
		@ErrorMessage VarChar(4000),
		@ErrorSeverity Integer
    
  Declare @TransferredProcessID Table (ProcessID VarChar(3))  --doc20231219TMH has to be in it's own declare.

  Create Table #ReadyToProcess(
	  RecordID char(40),
    GUIDRef char(40)
  )
  

  /**********************************************************************************
  Transfer INTF_CoolerMove
  **********************************************************************************/

  Insert Into @TransferredProcessID Values ('ECM') --doc20231219TMH

  Insert Into #ReadyToProcess
  Select RECORDID, GUIDREF                     
  From [ODS-FSM].[CAT2].INTF_EXPORTS
  Where [STATUS] = 'R'
    And PROCESSID = 'ECM'
  Order By CREATEDATETIME    

  Begin Try
    Begin Distributed Transaction

      Insert Into OKSQL01P.OK.dbo.INTF_COOLERMOVE
        ([SERIAL]
        ,[RECORDID]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[SERIALNUMBER]
        ,[PRODUCTCODE]
        ,[ORIGPRODCODE]
        ,[PRODUCTUOM]
        ,[PRODUCTHUNIT]
        ,[PRODUCTIONDATE]
        ,[ACTIVELOT]
        ,[NETWEIGHT]
        ,[TOTALUNITS]
        ,[MOVEMENT]
        ,[TRANSACTION]
        ,[CASETYPE]
        ,[SOURCE_DEPT]
        ,[SOURCE_SUBDEPT]
        ,[SOURCE_PRODORDER]
        ,[SOURCE_COOLER]
        ,[SOURCE_SLOT]
        ,[DEST_DEPT]
        ,[DEST_SUBDEPT]
        ,[DEST_PRODORDER]
        ,[DEST_COOLER]
        ,[DEST_SLOT]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[STATUSFLAG]
        ,[DETAILSTATUSFLAG]
        ,[MESSAGEID]
        ,[DETAILMESSAGEID]
        ,[DETAILPROCESSEDDATETIME]
        ,[KILLDATETIME]
        ,[REWORKREASONCODE]
        ,[REWORKREASONDESC]
        ,[TEMPCOOLERID]
        ,[ERPCOMPANYCODE]
        ,[ERPWAREHOUSE]
        ,[LEGACYUNIQUEBARCODE]
        ,[TAREWEIGHT]
        ,[NUMBEROFCASES]
        ,[UNITSPERCASE]
        ,[PACKDATE]
        ,[ONHOLD]
        ,[GUID_AUDIT]
        ,[PRIORTRANS]
        ,[RECOVERTRANS]
        ,[DAYLOT]
        ,[PALLETNUMBER]
        ,[EMPLOYEENO]
				,[PRODUCTIONDATE_ITEM]	--doc20240213ER
				,[SHIFT_ITEM]						--doc20240213ER
				)
      Select
        cm.[SERIAL]
        ,cm.[RECORDID]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[SERIALNUMBER]
        ,[PRODUCTCODE]
        ,[ORIGPRODCODE]
        ,[PRODUCTUOM]
        ,[PRODUCTHUNIT]
        ,[PRODUCTIONDATE]
        ,[ACTIVELOT]
        ,[NETWEIGHT]
        ,[TOTALUNITS]
        ,[MOVEMENT]
        ,[TRANSACTION]
        ,[CASETYPE]
        ,[SOURCE_DEPT]
        ,[SOURCE_SUBDEPT]
        ,[SOURCE_PRODORDER]
        ,[SOURCE_COOLER]
        ,[SOURCE_SLOT]
        ,[DEST_DEPT]
        ,[DEST_SUBDEPT]
        ,[DEST_PRODORDER]
        ,[DEST_COOLER]
        ,[DEST_SLOT]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[STATUSFLAG]
        ,[DETAILSTATUSFLAG]
        ,[MESSAGEID]
        ,[DETAILMESSAGEID]
        ,[DETAILPROCESSEDDATETIME]
        ,[KILLDATETIME]
        ,[REWORKREASONCODE]
        ,[REWORKREASONDESC]
        ,[TEMPCOOLERID]
        ,[ERPCOMPANYCODE]
        ,[ERPWAREHOUSE]
        ,[LEGACYUNIQUEBARCODE]
        ,[TAREWEIGHT]
        ,[NUMBEROFCASES]
        ,[UNITSPERCASE]
        ,[PACKDATE]
        ,[ONHOLD]
        ,[GUID_AUDIT]
        ,[PRIORTRANS]
        ,[RECOVERTRANS]
        ,[DAYLOT]
        ,[PALLETNUMBER]
        ,[EMPLOYEENO]
				,[PRODUCTIONDATE_ITEM]	--doc20240213ER
				,[SHIFT_ITEM]						--doc20240213ER
      From #ReadyToProcess r
      Join INTF_COOLERMOVE cm With (NoLock) On
        cm.MESSAGEID = r.GUIDRef And
        cm.[TRANSACTION] <> 'A'                               --doc20240129TMH

      Update INTF_COOLERMOVE
	    --Set STATUSFLAG = 'P'                                  --doc20240129TMH
      Set STATUSFLAG = CASE                                   --doc20240129TMH                     
                         When cm.[Transaction] = 'A' 
                           Then 'X' 
                         Else 'P' 
                       End,
        PROCESSEDDATETIME = GETDATE()
      From #ReadyToProcess r 
      Join INTF_COOLERMOVE cm With (NoLock) On      
        cm.MESSAGEID = r.GUIDRef

      Update INTF_EXPORTS
      --Set [STATUS] = 'P'                                    --doc20240129TMH
      Set [STATUS] = CASE                                     --doc20240129TMH               
                         When cm.[Transaction] = 'A' 
                           Then 'X' 
                         Else 'P' 
                       End,
        COMPLETEDATETIME = GETDATE()     
      From #ReadyToProcess r
      Join INTF_Exports e With (NoLock) On  
        e.RECORDID = r.RecordID
      Join INTF_COOLERMOVE cm With (NoLock) On                --doc20240129TMH
        cm.MESSAGEID = r.GUIDRef

      Insert Into OKSQL01P.OK.dbo.INTF_EXPORTS(
        [RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      [GUIDREF],
	      [STATUS],
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
        )
      Select
        e.[RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      e.[GUIDREF],
	      'T',           
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
      From #ReadyToProcess r 
      Join INTF_EXPORTS e With (NoLock) On 
        e.RECORDID = r.RecordID And
        e.[STATUS] = 'P'                                     --doc20240129TMH

    Commit Transaction

  End Try
  Begin Catch
    If @@TRANCOUNT > 0
      RollBack Transaction
    Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  End Catch
   
/**********************************************************************************
Transfer INTF_CASEDTLS
**********************************************************************************/

  Insert Into @TransferredProcessID Values ('LBL') --doc20231219TMH

  Truncate Table #ReadyToProcess

  Insert Into #ReadyToProcess
  Select RECORDID, GUIDREF
  From INTF_EXPORTS
  Where [STATUS] = 'R'
    And PROCESSID = 'LBL'
  Order By CREATEDATETIME   

  Begin Try
    Begin Distributed Transaction

      INSERT INTO OKSQL01P.OK.dbo.INTF_CASEDTLS(
        [RECORDID]
        ,[SERIAL]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[SERIALNUMBER]
        ,[SCALEID]
        ,[PRODUCTIONDATE]
        ,[KILLDATE]
        ,[PACKDATE]
        ,[PRODUCTCODE]
        ,[PRODUCTUOM]
        ,[PRODUCTHUNIT]
        ,[ACTIVELOT]
        ,[NETWEIGHT]
        ,[TRANSACTION]
        ,[SOURCE_DEPT]
        ,[SOURCE_SUBDEPT]
        ,[SOURCE_PRODORDER]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[STATUSFLAG]
        ,[DELETESTATUSFLAG]
        ,[MESSAGEID]
        ,[DELETEMESSAGEID]
        ,[DELETEPROCESSEDDATETIME]
        ,[SALEABLEUNITS]
        ,[LEGACYUNIQUEBARCODE]
        ,[TAREWEIGHT]
        ,[UNITSPERCASE]
        ,[NUMBEROFCASES]
        ,[PALLETNUMBER]
        ,[CASENUM]
        ,[MAXCASES]
        ,[LASTONPALLET]
        ,[NPLUS1CASE]
        ,[QASTATUS]
        ,[HEADCOUNT]
        ,[QA_STATUS]
        ,[COOLERID]
        ,[DAYLOT]
        ,[SHIFT]
        )
      Select
        cd.[RECORDID]
        ,[SERIAL]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[SERIALNUMBER]
        ,[SCALEID]
        ,[PRODUCTIONDATE]
        ,[KILLDATE]
        ,[PACKDATE]
        ,[PRODUCTCODE]
        ,[PRODUCTUOM]
        ,[PRODUCTHUNIT]
        ,[ACTIVELOT]
        ,[NETWEIGHT]
        ,[TRANSACTION]
        ,[SOURCE_DEPT]
        ,[SOURCE_SUBDEPT]
        ,[SOURCE_PRODORDER]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[STATUSFLAG]
        ,[DELETESTATUSFLAG]
        ,[MESSAGEID]
        ,[DELETEMESSAGEID]
        ,[DELETEPROCESSEDDATETIME]
        ,[SALEABLEUNITS]
        ,[LEGACYUNIQUEBARCODE]
        ,[TAREWEIGHT]
        ,[UNITSPERCASE]
        ,[NUMBEROFCASES]
        ,[PALLETNUMBER]
        ,[CASENUM]
        ,[MAXCASES]
        ,[LASTONPALLET]
        ,[NPLUS1CASE]
        ,[QASTATUS]
        ,[HEADCOUNT]
        ,[QA_STATUS]
        ,[COOLERID]
        ,[DAYLOT]
        ,[SHIFT]
      From #ReadyToProcess r
      Join INTF_CASEDTLS cd With (NoLock) On
        cd.MESSAGEID = r.GUIDRef
      Where cd.[Transaction] <> 'P'
        And cd.COOLERID <> ''                       --doc20230104TMH
        --Or cd.COOLERID <> ''   --doc20231219TMH   --doc20230104TMH

      Update INTF_CASEDTLS        
      --Set STATUSFLAG = 'P',                                                       --doc20231212TMH2
      --Set STATUSFLAG = CASE When cd.[Transaction] <> 'P' Then 'P' Else 'X' End,   --doc20231212TMH2  --doc20231219TMH
      Set STATUSFLAG = CASE                                                         --doc20231219TMH
                         When (cd.[Transaction] = 'P') Or (cd.COOLERID = '') 
                           Then 'X' 
                         Else 'P' 
                       End,
        PROCESSEDDATETIME = GETDATE()    
      From #ReadyToProcess r
      Join INTF_CASEDTLS cd With (NoLock) On
        cd.MESSAGEID = r.GUIDRef
      --Where [Transaction] <> 'P'                                                  --doc20231212TMH2

      Update INTF_EXPORTS
      --Set [STATUS] = 'P',                                                         --doc20231212TMH2
      --Set [STATUS] = CASE When cd.[Transaction] <> 'P' Then 'P' Else 'X' End,     --doc20231212TMH2
      Set [STATUS] = CASE                                                           --doc20231219TMH
                       When (cd.[Transaction] = 'P') Or (cd.COOLERID = '') 
                         Then 'X' 
                       Else 'P' 
                     End,
        COMPLETEDATETIME = GETDATE()     
      From #ReadyToProcess r
      Join INTF_Exports e With (NoLock) On
        e.RECORDID = r.RecordID
      Join INTF_CASEDTLS cd With (NoLock) On
        cd.MESSAGEID = r.GUIDRef
      --Where [Transaction] <> 'P'                                              --doc20231212TMH2

      Insert Into OKSQL01P.OK.dbo.INTF_EXPORTS(
        [RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      [GUIDREF],
	      [STATUS],
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
        )
      Select
        e.[RECORDID], 
	      e.[SERIAL],
	      e.[PROCESSID],
	      e.[COMPANYCODE],
	      e.[WAREHOUSECODE],
	      e.[GUIDREF],
	      'T',           
	      e.[CREATEDATETIME],
	      e.[BUSYFLAG],
	      e.[STATUSMESSAGE],
	      e.[GUIDREFTABLE],
	      e.[GUIDDEST],
	      e.[GUIDDESTTABLE]
      From #ReadyToProcess r 
      Join INTF_EXPORTS e With (NoLock) On 
        e.RECORDID = r.RecordID And
        e.[Status] = 'P'                          --doc20230104TMH
      --Join INTF_CASEDTLS cd With (NoLock) On    --doc20230104TMH
      --  cd.MESSAGEID = r.GUIDRef
      --Where cd.[Transaction] <> 'P'
      --  Or cd.COOLERID <> ''   --doc20231219TMH

    Commit Transaction

  End Try
  Begin Catch
    If @@TRANCOUNT > 0
      RollBack Transaction
    Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  End Catch


/**********************************************************************************
Transfer INTF_PALLETHDR
**********************************************************************************/
  --Insert Into @TransferredProcessID Values ('PAL') --doc20231219TMH putting this here so if this gets uncommented it will already work.
  
  --Truncate Table #ReadyToProcess

  --Insert Into #ReadyToProcess
  --Select RECORDID, GUIDREF
  --From INTF_EXPORTS
  --Where [STATUS] = 'R'
  --  And PROCESSID = 'PAL'
  --Order By CREATEDATETIME  

  --Begin Try
  --  Begin Distributed Transaction 
    
  --    Insert Into OKSQL01P.OK.dbo.INTF_PALLETHDR(
		--    RECORDID,
		--    COMPANYCODE,
		--    WAREHOUSECODE,
		--    PALLETNUMBER,
		--    PRODUCTCODE,
		--    PRODUCTIONDATE,
		--    CASECOUNT,
		--    PALLETWEIGHT,
		--    PALTYPE,
		--    CREATEDATETIME,
		--    PROCESSEDDATETIME,
		--    STATUSFLAG,
		--    LEGACYUNIQUEBARCODE,
		--    STATIONID,
  --      MESSAGEID
		--    )
	 --   Select
		--    ph.RECORDID,
		--    COMPANYCODE,
		--    WAREHOUSECODE,
		--    PALLETNUMBER,
		--    PRODUCTCODE,
		--    PRODUCTIONDATE,
		--    CASECOUNT,
		--    PALLETWEIGHT,
		--    PALTYPE,
		--    CREATEDATETIME,
		--    PROCESSEDDATETIME,
		--    STATUSFLAG,
		--    LEGACYUNIQUEBARCODE,
		--    STATIONID,
  --      MESSAGEID
	 --   From INTF_PALLETHDR ph With (NoLock)
		--  Join #ReadyToProcess r On
  --      ph.MessageId = r.GUIDRef

  --    Insert Into OKSQL01P.OK.dbo.INTF_PALLETDTL(
  --      [RECORDID]
  --      ,[HDRRECORDID]
  --      ,[PALLETNUMBER]
  --      ,[SERIALNUM]
  --      ,[SECSERIALNUMBER]
  --      ,[PRODUCTCODE]
  --      ,[SCALEID]
  --      ,[PRODUCTIONDATE]
  --      ,[SHIFT]
  --      ,[PRICE]
  --      ,[KILLDATE]
  --      ,[PACKDATE]
  --      ,[WEIGHT]
  --      ,[SCALEWEIGHT]
  --      ,[TAREWEIGHT]
  --      ,[CREATEDATETIME]
  --      ,[PROCESSEDDATETIME]
  --      ,[STATUSFLAG]
  --      ,[LEGACYUNIQUEBARCODE]
  --      ,[LOTNUMBER])		      
	 --   Select
  --      d.[RECORDID]
  --      ,d.[HDRRECORDID]
  --      ,d.[PALLETNUMBER]
  --      ,d.[SERIALNUM]
  --      ,d.[SECSERIALNUMBER]
  --      ,d.[PRODUCTCODE]
  --      ,d.[SCALEID]
  --      ,d.[PRODUCTIONDATE]
  --      ,d.[SHIFT]
  --      ,d.[PRICE]
  --      ,d.[KILLDATE]
  --      ,d.[PACKDATE]
  --      ,d.[WEIGHT]
  --      ,d.[SCALEWEIGHT]
  --      ,d.[TAREWEIGHT]
  --      ,d.[CREATEDATETIME]
  --      ,d.[PROCESSEDDATETIME]
  --      ,d.[STATUSFLAG]
  --      ,d.[LEGACYUNIQUEBARCODE]
  --      ,d.[LOTNUMBER]
	 --   From INTF_PALLETDTL d With (NoLock)
  --    Join INTF_PALLETHDR h With (NoLock) On                      
  --      d.HDRRECORDID = h.RECORDID 
  --    Join #ReadyToProcess r On
  --      h.MessageId = r.GUIDRef

  --    Update INTF_PALLETHDR
  --    Set STATUSFLAG = 'P', PROCESSEDDATETIME = GETDATE()    
	 --   From INTF_PALLETHDR h With (NoLock) 
  --    Join #ReadyToProcess r On
  --      h.messageid = r.GUIDRef

  --    Update INTF_PALLETDTL
  --    Set STATUSFLAG = 'P', PROCESSEDDATETIME = GETDATE()    
  --    From INTF_PALLETDTL d With (NoLock)
  --    Join INTF_PALLETHDR h With (NoLock) On
  --      d.HDRRECORDID = h.RECORDID
  --    Join #ReadyToProcess r On
  --      h.MessageId = r.GUIDRef

  --    Update INTF_EXPORTS
  --    Set [STATUS] = 'P', COMPLETEDATETIME = GETDATE()     
  --    From INTF_Exports e
  --    Join #ReadyToProcess r On
  --      e.RECORDID = r.RecordID
  
  --    Insert Into OKSQL01P.OK.dbo.INTF_EXPORTS(
  --      [RECORDID], 
	 --     [SERIAL],
	 --     [PROCESSID],
	 --     [COMPANYCODE],
	 --     [WAREHOUSECODE],
	 --     [GUIDREF],
	 --     [STATUS],
	 --     [CREATEDATETIME],
	 --     [BUSYFLAG],
	 --     [STATUSMESSAGE],
	 --     [GUIDREFTABLE],
	 --     [GUIDDEST],
	 --     [GUIDDESTTABLE]
  --      )
  --    Select
  --      e.[RECORDID], 
	 --     [SERIAL],
	 --     [PROCESSID],
	 --     [COMPANYCODE],
	 --     [WAREHOUSECODE],
	 --     e.[GUIDREF],
	 --     'T',           
	 --     [CREATEDATETIME],
	 --     [BUSYFLAG],
	 --     [STATUSMESSAGE],
	 --     [GUIDREFTABLE],
	 --     [GUIDDEST],
	 --     [GUIDDESTTABLE]
      --From #ReadyToProcess r 
      --Join INTF_EXPORTS e With (NoLock) On 
        --e.RECORDID = r.RecordID

  --  Commit Transaction

  --End Try
  --Begin Catch
  --  If @@TRANCOUNT > 0
  --    RollBack Transaction
  --  Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		--Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  --End Catch


/**********************************************************************************
Transfer INTF_PORECEIPTHDR
**********************************************************************************/

  Insert Into @TransferredProcessID Values ('POR') --doc20231219TMH

  Truncate Table #ReadyToProcess

  Insert Into #ReadyToProcess
  Select RECORDID, GUIDREF
  From INTF_EXPORTS
  Where [STATUS] = 'R'
    And PROCESSID = 'POR'
  Order By CREATEDATETIME  

  Begin Try
    Begin Distributed Transaction      
      Insert Into OKSQL01P.OK.dbo.INTF_PORECEIPTHDR(
        [RECORDID]
        ,[SERIAL]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[PONUMBER]
        ,[PURCHASEDQTY]
        ,[COMPLETEFLAG]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[STATUSFLAG]
        ,[ERRORMESSAGE]
        ,[ERP_INTERFACEGROUPID]
        ,[ERP_INTERFACEID]
        ,[EMPLOYEENO]
        ,[RECEIVEDWEIGHT]
        ,[EXTERNALID]
        ,[MESSAGEID])
      Select 
        h.[RECORDID]
        ,[SERIAL]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[PONUMBER]
        ,[PURCHASEDQTY]
        ,[COMPLETEFLAG]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[STATUSFLAG]
        ,[ERRORMESSAGE]
        ,[ERP_INTERFACEGROUPID]
        ,[ERP_INTERFACEID]
        ,[EMPLOYEENO]
        ,[RECEIVEDWEIGHT]
        ,[EXTERNALID]
        ,[MESSAGEID]
      From #ReadyToProcess r 
      Join INTF_PORECEIPTHDR h With (NoLock) On
        h.MESSAGEID = r.GUIDRef  

      Insert Into OKSQL01P.OK.dbo.INTF_PORECEIPTDTL(
        [RECORDID]
        ,[SERIAL]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[HDRRECORDID]
        ,[LINENUMBER]
        ,[ITEMCODE]
        ,[PURCHASEDQTY]
        ,[DATERECEIVED]
        ,[ERP_RECORDID]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[STATUSFLAG]
        ,[ERRORMESSAGE]
        ,[ERP_INTERFACEGROUPID]
        ,[ERP_INTERFACEID]
        ,[MOVEMENTTYPE]
        ,[REASONCODE]
        ,[VENDORDELIVERY]
        ,[SERIALNUM]
        ,[VENDORLOT]
        ,[COOLERID]
        ,[RECEIVEQTY]
        ,[RECEIVEUOM]
        ,[VENDORNUMBER]
        ,[RECEIVEWEIGHT]
        ,[PRODUCTIONDATETIME]
        ,[PACKDATETIME]
        ,[EXPIRATIONDATE]
        ,[EMPLOYEENO]
        ,[MIXLOT]
        ,[DocumentNumber]
        ,[ERP_ReceiveQty]
        ,[customfield1] --doc20230623ER
	      ,[customfield2]	--doc20230623ER
	      ,[customfield3]	--doc20230623ER
	      ,[customfield4]	--doc20230623ER
	      ,[customfield5]	--doc20230623ER
	      ,[customfield6]	--doc20230623ER
	      ,[customfield7]	--doc20230623ER
	      ,[customfield8]	--doc20230623ER
	      ,[customfield9]	--doc20230623ER
	      ,[customfield10]	--doc20230623ER
	      ,[receiveproddate]	--doc20230623ER
	      ,[receiveshift]	--doc20230623ER
				,[daylot]	--doc20230623ER
				,[adjweight]	--doc20230623ER
				)
      Select
        d.[RECORDID]
        ,d.[SERIAL]
        ,d.[COMPANYCODE]
        ,d.[WAREHOUSECODE]
        ,d.[HDRRECORDID]
        ,d.[LINENUMBER]
        ,d.[ITEMCODE]
        ,d.[PURCHASEDQTY]
        ,d.[DATERECEIVED]
        ,d.[ERP_RECORDID]
        ,d.[CREATEDATETIME]
        ,d.[PROCESSEDDATETIME]
        ,d.[STATUSFLAG]
        ,d.[ERRORMESSAGE]
        ,d.[ERP_INTERFACEGROUPID]
        ,d.[ERP_INTERFACEID]
        ,d.[MOVEMENTTYPE]
        ,d.[REASONCODE]
        ,d.[VENDORDELIVERY]
        ,d.[SERIALNUM]
        ,d.[VENDORLOT]
        ,d.[COOLERID]
        ,d.[RECEIVEQTY]
        ,d.[RECEIVEUOM]
        ,d.[VENDORNUMBER]
        ,d.[RECEIVEWEIGHT]
        ,d.[PRODUCTIONDATETIME]
        ,d.[PACKDATETIME]
        ,d.[EXPIRATIONDATE]
        ,d.[EMPLOYEENO]
        ,d.[MIXLOT]
        ,d.[DocumentNumber]
        ,d.[ERP_ReceiveQty]
        ,d.[customfield1]	--doc20230623ER
	      ,d.[customfield2]	--doc20230623ER
	      ,d.[customfield3]	--doc20230623ER
	      ,d.[customfield4]	--doc20230623ER
	      ,d.[customfield5]	--doc20230623ER
	      ,d.[customfield6]	--doc20230623ER
	      ,d.[customfield7]	--doc20230623ER
	      ,d.[customfield8]	--doc20230623ER
	      ,d.[customfield9]	--doc20230623ER
	      ,d.[customfield10]	--doc20230623ER
	      ,d.[receiveproddate]	--doc20230623ER
	      ,d.[receiveshift]	--doc20230623ER
				,d.[daylot]	--doc20230623ER
				,d.[adjweight]	--doc20230623ER
      From #ReadyToProcess r 
      Join INTF_PORECEIPTHDR h With (NoLock) On 
        h.MESSAGEID = r.GUIDRef 
      Join INTF_PORECEIPTDTL d With (NoLock) On            
        d.HDRRECORDID = h.RECORDID 

      Update INTF_PORECEIPTHDR
      Set STATUSFLAG = 'P', PROCESSEDDATETIME = GETDATE()   
	    From #ReadyToProcess r
      Join INTF_PORECEIPTHDR h With (NoLock) On
        h.MESSAGEID = r.GUIDRef

      Update INTF_PORECEIPTDTL
      Set STATUSFLAG = 'P', PROCESSEDDATETIME = GETDATE()  
      From #ReadyToProcess r 
      Join INTF_PORECEIPTHDR h With (NoLock) On
        h.MESSAGEID = r.GUIDRef
      Join INTF_PORECEIPTDTL d With (NoLock) On
        d.HDRRECORDID = h.RECORDID       

      Update INTF_EXPORTS
      Set [STATUS] = 'P', COMPLETEDATETIME = GETDATE()     
      From #ReadyToProcess r
      Join INTF_Exports e With (NoLock) On
        e.RECORDID = r.RecordID
     
      Insert Into OKSQL01P.OK.dbo.INTF_EXPORTS(
        [RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      [GUIDREF],
	      [STATUS],
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
        )
      Select
        e.[RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      e.[GUIDREF],
	      'T',           
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
      From #ReadyToProcess r 
      Join INTF_EXPORTS e With (NoLock) On 
        e.RECORDID = r.RecordID
        
    Commit Transaction

  End Try
  Begin Catch
    If @@TRANCOUNT > 0
      RollBack Transaction 
    Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  End Catch

/**********************************************************************************
Transfer INTF_ORDERSTATUS
**********************************************************************************/
  --Insert Into @TransferredProcessID Values ('ORS') --doc20231219TMH putting this here so if this gets uncommented it will already work.

  
  --Truncate Table #ReadyToProcess

  --Insert Into #ReadyToProcess
  --Select RECORDID, GUIDREF
  --From INTF_EXPORTS
  --Where [STATUS] = 'R'
  --  And PROCESSID = 'ORS'
  --Order By CREATEDATETIME  

  --Begin Try
  --  Begin Distributed Transaction
  --    Insert Into OKSQL01P.OK.dbo.INTF_ORDERSTATUS
  --      ([SERIAL]
  --      ,[RECORDID]
  --      ,[COMPANYCODE]
  --      ,[WAREHOUSECODE]
  --      ,[CHANGEDATETIME]
  --      ,[ORDERSTATUS]
  --      ,[ORDERNUMBER]
  --      ,[LOADNUMBER]
  --      ,[ISLASTTRUCK]
  --      ,[BOLNUMBER]
  --      ,[CUSTOMERCODE]
  --      ,[CUSTOMERPONUMBER]
  --      ,[STATUSFLAG]
  --      ,[LINENUMBER]
  --      ,[ITEMSTATUS]
  --      ,[MESSAGEID]
  --      ,[PROCESSEDDATETIME])
  --    Select
  --      [SERIAL]
  --      ,o.[RECORDID]
  --      ,[COMPANYCODE]
  --      ,[WAREHOUSECODE]
  --      ,[CHANGEDATETIME]
  --      ,[ORDERSTATUS]
  --      ,[ORDERNUMBER]
  --      ,[LOADNUMBER]
  --      ,[ISLASTTRUCK]
  --      ,[BOLNUMBER]
  --      ,[CUSTOMERCODE]
  --      ,[CUSTOMERPONUMBER]
  --      ,[STATUSFLAG]
  --      ,[LINENUMBER]
  --      ,[ITEMSTATUS]
  --      ,[MESSAGEID]
  --      ,[PROCESSEDDATETIME]
  --    From INTF_ORDERSTATUS o With (NoLock)
  --    Join #ReadyToProcess r On
  --      o.MESSAGEID = r.GUIDRef 

  --    Update INTF_ORDERSTATUS
  --    Set STATUSFLAG = 'P', PROCESSEDDATETIME = GETDATE()   
	 --   From INTF_ORDERSTATUS o
  --    Join #ReadyToProcess r On
  --      o.MESSAGEID = r.GUIDRef

  --    Update INTF_EXPORTS
  --    Set [STATUS] = 'P', COMPLETEDATETIME = GETDATE()     
  --    From INTF_Exports e
  --    Join #ReadyToProcess r On
  --      e.RECORDID = r.RecordID

  --    --Put Exports in temp then process at the end      
  --    Insert Into #ReadyToProcess_INTF_Exports 
  --    Select RecordID
  --    From #ReadyToProcess
      
  --  Commit Transaction

  --End Try
  --Begin Catch
  --  If @@TRANCOUNT > 0
  --    RollBack Transaction
  --  Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		--Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  --End Catch

/**********************************************************************************
Transfer INTF_SHIPPINGHDR
**********************************************************************************/

  Insert Into @TransferredProcessID Values ('SHC') --doc20231219TMH

  Truncate Table #ReadyToProcess

  Insert Into #ReadyToProcess
  Select RECORDID, GUIDREF
  From INTF_EXPORTS
  Where [STATUS] = 'R'
    --And PROCESSID = 'SHP'	--doc20231212ER
		And PROCESSID = 'SHC'	--doc20231212ER
  Order By CREATEDATETIME   

  Begin Try
    Begin Distributed Transaction
      Insert Into OKSQL01P.OK.dbo.INTF_SHIPPINGHDR
        ([SERIAL]
        ,[RECORDID]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[ORDERNUMBER]
        ,[LOADNUMBER]
        ,[TOTALGROSSWEIGHT]
        ,[TOTALNETWEIGHT]
        ,[TOTALUNITS]
        ,[FRESHFROZENFLAG]
        ,[CUSTOMERPONUMBER]
        ,[TRAILERID]
        ,[LOADDATE]
        ,[CLOSEDATE]
        ,[ORDERTYPE]
        ,[ERPORDERNUMBER]
        ,[COMPLETEFLAG]
        ,[CUSTOMERCODE]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[statusflag]
        ,[ERPCOMPANY]
        ,[ERPWAREHOUSE]
        ,[ORDERGROUPING]
        ,[RECEIVEDATWAREHOUSE]
        ,[DELIVERYCODE]
        ,[DELLOCATIONNO]
        ,[CAPTUREDBY]
        ,[COMMENTS]
        ,[ROUTE]
        ,[CARRIERCODE]
        ,[ISLASTTRUCK]
        ,[BOLNUMBER]
        ,[DRIVER]
        ,[PROMISEDATETIME]
        ,[DROPNUMBER]
        ,[TEMPLOGGERID]
        ,[TEMP1]
        ,[TEMP2]
        ,[TEMP3]
        ,[DELIVERYDATETIME]
        ,[PALLETSIN]
        ,[PALLETSOUT]
        ,[CUSTOMERNAME]
        ,[DELIVERYNAME]
        ,[DELIVERYADDRESS]
        ,[DELIVERYTELEPHONE]
        ,[TEMPERATURE]
        ,[TEMPERATURESCALE]
        ,[SHAG]
        ,[WASH]
        ,[SHIPPINGTERM]
        ,[CARRIERNAME]
        ,[DISTANCE]
        ,[DELIVERYPO]
        ,[DELIVERYDATEREQUESTED]
        ,[EXTERNALID]
        ,[SEAL]
        ,[SEAL2]
        ,[SEAL3]
        ,[SEAL4]
        ,[CUSTOMFIELD1]
        ,[CUSTOMFIELD2]
        ,[CUSTOMFIELD3]
        ,[CUSTOMFIELD4]
        ,[CUSTOMFIELD5]
        ,[MESSAGEID])
      Select
        [SERIAL]
        ,h.[RECORDID]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[ORDERNUMBER]
        ,[LOADNUMBER]
        ,[TOTALGROSSWEIGHT]
        ,[TOTALNETWEIGHT]
        ,[TOTALUNITS]
        ,[FRESHFROZENFLAG]
        ,[CUSTOMERPONUMBER]
        ,[TRAILERID]
        ,[LOADDATE]
        ,[CLOSEDATE]
        ,[ORDERTYPE]
        ,[ERPORDERNUMBER]
        ,[COMPLETEFLAG]
        ,[CUSTOMERCODE]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[statusflag]
        ,[ERPCOMPANY]
        ,[ERPWAREHOUSE]
        ,[ORDERGROUPING]
        ,[RECEIVEDATWAREHOUSE]
        ,[DELIVERYCODE]
        ,[DELLOCATIONNO]
        ,[CAPTUREDBY]
        ,[COMMENTS]
        ,[ROUTE]
        ,[CARRIERCODE]
        ,[ISLASTTRUCK]
        ,[BOLNUMBER]
        ,[DRIVER]
        ,[PROMISEDATETIME]
        ,[DROPNUMBER]
        ,[TEMPLOGGERID]
        ,[TEMP1]
        ,[TEMP2]
        ,[TEMP3]
        ,[DELIVERYDATETIME]
        ,[PALLETSIN]
        ,[PALLETSOUT]
        ,[CUSTOMERNAME]
        ,[DELIVERYNAME]
        ,[DELIVERYADDRESS]
        ,[DELIVERYTELEPHONE]
        ,[TEMPERATURE]
        ,[TEMPERATURESCALE]
        ,[SHAG]
        ,[WASH]
        ,[SHIPPINGTERM]
        ,[CARRIERNAME]
        ,[DISTANCE]
        ,[DELIVERYPO]
        ,[DELIVERYDATEREQUESTED]
        ,[EXTERNALID]
        ,[SEAL]
        ,[SEAL2]
        ,[SEAL3]
        ,[SEAL4]
        ,[CUSTOMFIELD1]
        ,[CUSTOMFIELD2]
        ,[CUSTOMFIELD3]
        ,[CUSTOMFIELD4]
        ,[CUSTOMFIELD5]
        ,[MESSAGEID]
      From #ReadyToProcess r 
      Join INTF_SHIPPINGHDR h With (NoLock) On
        h.MESSAGEID = r.GUIDRef   

      Insert Into OKSQL01P.OK.dbo.INTF_SHIPPINGDTL
        ([RECORDID]
        ,[HDRRECORDID]
        ,[SERIALNUMBER]
        ,[PRODUCTCODE]
        ,[ACTIVELOT]
        ,[GROSSWEIGHT]
        ,[LABELWEIGHT]
        ,[TAREWEIGHT]
        ,[NETWEIGHT]
        ,[TOTALUNITS]
        ,[CASETYPE]
        ,[PRODUCTIONDATE]
        ,[ORDERNUMBER]
        ,[LOADNUMBER]
        ,[PRODUCTUOM]
        ,[PRODUCTHUNIT]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[COOLERID]
        ,[PACKDATE]
        ,[ORDERLINENUMBER]
        ,[ISSUBSTITUTE]
        ,[SUBPRODUCTCODE]
        ,[SUBAUTHORIZATION]
        ,[LOTNUMBER]
        ,[PALLETNUMBER]
        ,[KILLDATETIME]
        ,[SUBSTITUTEORDERLINENUMBER]
        ,[EXPIRATIONDATETIME]
        ,[EDIPALLETNUMBER]
        ,[EDISERIALNUM]
        ,[MEASURE_COLOR]
        ,[DAYLOT]
        ,[statusflag]
        ,[ERP_ReceiveQty]
        ,[ShipBy])
      Select
        d.[RECORDID]
        ,d.[HDRRECORDID]
        ,d.[SERIALNUMBER]
        ,d.[PRODUCTCODE]
        ,d.[ACTIVELOT]
        ,d.[GROSSWEIGHT]
        ,d.[LABELWEIGHT]
        ,d.[TAREWEIGHT]
        ,d.[NETWEIGHT]
        ,d.[TOTALUNITS]
        ,d.[CASETYPE]
        ,d.[PRODUCTIONDATE]
        ,d.[ORDERNUMBER]
        ,d.[LOADNUMBER]
        ,d.[PRODUCTUOM]
        ,d.[PRODUCTHUNIT]
        ,d.[CREATEDATETIME]
        ,d.[PROCESSEDDATETIME]
        ,d.[COOLERID]
        ,d.[PACKDATE]
        ,d.[ORDERLINENUMBER]
        ,d.[ISSUBSTITUTE]
        ,d.[SUBPRODUCTCODE]
        ,d.[SUBAUTHORIZATION]
        ,d.[LOTNUMBER]
        ,d.[PALLETNUMBER]
        ,d.[KILLDATETIME]
        ,d.[SUBSTITUTEORDERLINENUMBER]
        ,d.[EXPIRATIONDATETIME]
        ,d.[EDIPALLETNUMBER]
        ,d.[EDISERIALNUM]
        ,d.[MEASURE_COLOR]
        ,d.[DAYLOT]
        ,d.[statusflag]
        ,d.[ERP_ReceiveQty]
        ,d.[ShipBy]
      From #ReadyToProcess r
      Join INTF_ShippingHdr h With (NoLock) On 
        h.MESSAGEID = r.GUIDRef  
      Join INTF_SHIPPINGDTL d With (NoLock) On
        d.HDRRECORDID = h.RECORDID        

      Insert Into OKSQL01P.OK.dbo.INTF_SHIPPINGLINEITMS
        ([SERIAL]
        ,[RECORDID]
        ,[HDRRECORDID]
        ,[LINENUMBER]
        ,[PRODUCTCODE]
        ,[PRICE]
        ,[INITQTY]
        ,[INITWGT]
        ,[SHIPMENTQTY]
        ,[SHIPMENTWGT]
        ,[DISPATCHQTY]
        ,[DISPATCHWGT]
        ,[RECEIVEDQTY]
        ,[RECEIVEDWGT]
        ,[PRODUCTUOM]
        ,[PRODUCTHUNIT]
        ,[ISFROZEN]
        ,[GENERALNOTES]
        ,[LOADDATE]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[DISPATCHGROSSWGT]
        ,[LoadInv_Qty]
        ,[ERP_RecordID])
      Select
        d.[SERIAL]
        ,d.[RECORDID]
        ,d.[HDRRECORDID]
        ,d.[LINENUMBER]
        ,d.[PRODUCTCODE]
        ,d.[PRICE]
        ,d.[INITQTY]
        ,d.[INITWGT]
        ,d.[SHIPMENTQTY]
        ,d.[SHIPMENTWGT]
        ,d.[DISPATCHQTY]
        ,d.[DISPATCHWGT]
        ,d.[RECEIVEDQTY]
        ,d.[RECEIVEDWGT]
        ,d.[PRODUCTUOM]
        ,d.[PRODUCTHUNIT]
        ,d.[ISFROZEN]
        ,d.[GENERALNOTES]
        ,d.[LOADDATE]
        ,d.[CREATEDATETIME]
        ,d.[PROCESSEDDATETIME]
        ,d.[DISPATCHGROSSWGT]
        ,d.[LoadInv_Qty]
        ,d.[ERP_RecordID]
      From #ReadyToProcess r
      Join INTF_ShippingHdr h With (NoLock) On 
        h.MESSAGEID = r.GUIDRef   
      Join INTF_SHIPPINGLINEITMS d With (NoLock)  On                    
        d.HDRRECORDID = h.RECORDID       

      Update INTF_SHIPPINGHDR
      Set STATUSFLAG = 'P', PROCESSEDDATETIME = GETDATE()      
      From #ReadyToProcess r 
      Join INTF_SHIPPINGHDR h With (NoLock) On
        h.MESSAGEID = r.GUIDRef

      Update INTF_SHIPPINGDTL
      Set STATUSFLAG = 'P', PROCESSEDDATETIME = GETDATE()
      From #ReadyToProcess r
      Join INTF_ShippingHdr h With (NoLock) On 
        h.messageid = r.GUIDRef
      Join INTF_SHIPPINGDTL d With (NoLock) On
        d.HDRRECORDID = h.RECORDID       

      Update INTF_SHIPPINGLINEITMS
      Set PROCESSEDDATETIME = GETDATE()                        
      From #ReadyToProcess r 
      Join INTF_ShippingHdr h With (NoLock) On
        h.messageid = r.GUIDRef
      Join INTF_SHIPPINGLINEITMS d With (NoLock) On
        d.HDRRECORDID = h.RECORDID       

      Update INTF_EXPORTS
      Set [STATUS] = 'P', COMPLETEDATETIME = GETDATE()     
      From #ReadyToProcess r
      Join INTF_Exports e On
        e.RECORDID = r.RecordID
  
      Insert Into OKSQL01P.OK.dbo.INTF_EXPORTS(
        [RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      [GUIDREF],
	      [STATUS],
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
        )
      Select
        e.[RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      e.[GUIDREF],
	      'T',           
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
      From #ReadyToProcess r 
      Join INTF_EXPORTS e With (NoLock) On 
        e.RECORDID = r.RecordID

    Commit Transaction

  End Try
  Begin Catch
    If @@TRANCOUNT > 0
      RollBack Transaction
    Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  End Catch


/**********************************************************************************
Transfer INTF_HOLDCLASSIFICATION
**********************************************************************************/
  Insert Into @TransferredProcessID Values ('EHC') --doc20231219TMH

  Truncate Table #ReadyToProcess

  Insert Into #ReadyToProcess
  Select RECORDID, GUIDREF
  From CAT2.INTF_EXPORTS
  Where [STATUS] = 'R'
    And PROCESSID = 'EHC'
  Order By CREATEDATETIME  
           
  Create Table #UniquePalletAndCode(                    --doc20240311TMH begin                           
	  ObjectID char(200),
    Serial int,
	  MessageID char(40)
  )  

  -- Find most current record per objectID. Only 1 record needs processed per objectID(pallet) with the most current classification code.
  Insert Into #UniquePalletAndCode                                                  
  Select
    h.[OBJECTID]    
    ,MAX(h.SERIAL) As Serial
    ,null
  From #ReadyToProcess 
  Join CAT2.INTF_HOLDCLASSIFICATION h On
    h.messageid = #ReadyToProcess.GUIDRef And
    h.OBJECTTYPE = 'Pallet'
  Group By h.OBJECTID                                        

  -- Find and Set messageID for each of the records inserted previously.
  Update u
  Set u.MessageID = h.MessageID
  From #UniquePalletAndCode u
  Join CAT2.INTF_HOLDCLASSIFICATION h On
    h.SERIAL = u.Serial And
    h.OBJECTID = u.ObjectID And  --for reassurance
    h.OBJECTTYPE = 'Pallet'      --for reassurance      --doc20240311TMH end

  Begin Try
    Begin Distributed Transaction

      Insert Into OKSQL01P.OK.dbo.INTF_HOLDCLASSIFICATION
        ([SERIAL]
        ,[GUID]
        ,[CREATIONDATE]
        ,[PROCESSEDDATE]
        ,[STATUSFLAG]
        ,[OBJECTTYPE]
        ,[OBJECTID]
        ,[CLASSIFICATIONCODE]
        ,[MESSAGEID])
      Select
        h.[SERIAL]
        ,h.[GUID]
        ,h.[CREATIONDATE]
        ,h.[PROCESSEDDATE]
        ,h.[STATUSFLAG]
        ,h.[OBJECTTYPE]
        ,h.[OBJECTID]
        ,h.[CLASSIFICATIONCODE]
        ,h.[MESSAGEID]             
      From #UniquePalletAndCode u                                     --doc20240311TMH  begin        
      Join CAT2.INTF_HOLDCLASSIFICATION h (NoLock) On
        u.messageid = h.messageid

      --From #ReadyToProcess r  
      --Join INTF_HOLDCLASSIFICATION h (NoLock) On
      --  h.MessageId = r.GUIDRef
      --Where h.[OBJECTTYPE] = 'Pallet'	            --doc20231211ER   --doc20240311TMH end      

      Update CAT2.INTF_HOLDCLASSIFICATION
	    --Set STATUSFLAG = 'P',		                                                --doc20231211ER
			--Set STATUSFLAG = CASE When h.OBJECTTYPE = 'Pallet' Then 'P' Else 'X' End,	--doc20231211ER     --doc20240311TMH
      Set STATUSFLAG = CASE When h.messageid = u.messageid Then 'P' Else 'X' End,                     --doc20240311TMH
        PROCESSEDDATE = GETDATE()                                          
	    From #ReadyToProcess r 
      Join CAT2.INTF_HOLDCLASSIFICATION h (NoLock) On
        h.messageid = r.GUIDRef
      Left Join #UniquePalletAndCode u (NoLock) On                                     --doc20240311TMH 
        u.messageid = h.messageid

      Update CAT2.INTF_EXPORTS
      Set [STATUS] = CASE When e.GUIDREF = u.messageid Then 'P' Else 'X' End,	         --doc20240311TMH
        COMPLETEDATETIME = GETDATE()                                      
	    From #ReadyToProcess r
      Join CAT2.INTF_Exports e (NoLock) On
        e.RECORDID = r.RecordID
      Left Join #UniquePalletAndCode u (NoLock) On                                     --doc20240311TMH 
        u.messageid = r.GUIDRef

   --   Update INTF_EXPORTS
	  --  --Set [STATUS] = 'P',		                                                --doc20231211ER	--doc20231212ER --doc20231212TMH2
			----Set [STATUS] = CASE When h.OBJECTTYPE = 'Pallet' Then 'P' Else 'X' End,	  --doc20231211ER	--doc20231212ER --doc20231212TMH2
   --   Set [STATUS] = CASE When e.GUIDREF = u.messageid Then 'P' Else 'X' End,	         --doc20240311TMH
   --     COMPLETEDATETIME = GETDATE()                                      
	  --  From #ReadyToProcess r
   --   Join INTF_Exports e (NoLock) On
   --     e.RECORDID = r.RecordID     
   --   Left Join #UniquePalletAndCode u (NoLock) On                                     --doc20240311TMH 
   --     u.messageid = r.GUIDRef
   --   --Join INTF_HOLDCLASSIFICATION h (NoLock) On	--doc20231212ER --doc20231212TMH2   
   --   --  h.messageid = r.GUIDRef --doc20231212TMH2
   --   --  --h.messageid = e.GUIDREF	--doc20231212ER                                    --doc20240311TMH end


      Insert Into OKSQL01P.OK.dbo.INTF_EXPORTS(
        [RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      [GUIDREF],
	      [STATUS],
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
        )
      Select Distinct		--doc20231219ER
        e.[RECORDID], 
	      e.[SERIAL],
	      e.[PROCESSID],
	      e.[COMPANYCODE],
	      e.[WAREHOUSECODE],
	      e.[GUIDREF],
	      'T',           
	      e.[CREATEDATETIME],
	      e.[BUSYFLAG],
	      e.[STATUSMESSAGE],
	      e.[GUIDREFTABLE],
	      e.[GUIDDEST],
	      e.[GUIDDESTTABLE]
        From #UniquePalletAndCode                                             --doc20240311TMH begin
        Join CAT2.INTF_Exports e (NoLock) On
          e.GUIDREF = #UniquePalletAndCode.messageid
          
      --From #ReadyToProcess r 
      --Join INTF_EXPORTS e With (NoLock) On 
      --  e.RECORDID = r.RecordID
      --Join INTF_HOLDCLASSIFICATION h With (NoLock) On   --doc20231212TMH
      --  h.messageid = r.GUIDRef                         --doc20231212TMH
      --Where [OBJECTTYPE] = 'Pallet'                     --doc20231212TMH    --doc20240311TMH end

      Drop Table If Exists #UniquePalletAndCode  --doc20240311TMH

    Commit Transaction

  End Try
  Begin Catch
    If @@TRANCOUNT > 0
      RollBack Transaction
    Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  End Catch


/**********************************************************************************
Transfer INTF_PRODORDTRANS
**********************************************************************************/
  Insert Into @TransferredProcessID Values ('POT') --doc20231219TMH

  Truncate Table #ReadyToProcess

  Insert Into #ReadyToProcess
  Select RECORDID, GUIDREF
  From INTF_EXPORTS
  Where [STATUS] = 'R'
    And PROCESSID = 'POT'
  Order By CREATEDATETIME  

  Begin Try
    Begin Distributed Transaction
      INSERT INTO OKSQL01P.OK.dbo.INTF_PRODORDTRANS
        ([RECORDID]
        ,[COMPANYCODE]
        ,[WAREHOUSECODE]
        ,[PRODORDERNUMBER]
        ,[PRODUCTCODE]
        ,[TRANSTYPE]
        ,[QUANTITY]
        ,[WEIGHT]
        ,[UOM]
        ,[LOTNUMBER]
        ,[ACTIVITY_NAME]
        ,[SALESORDERNUMBER]
        ,[PRODUCTIONDATE]
        ,[CREATEDATETIME]
        ,[PROCESSEDDATETIME]
        ,[STATUSFLAG]
        ,[FREEZER]
        ,[PRODORDSUBDEPT]
        ,[SERIALNUM]
        ,[MIXLOT]
        ,[LINENUMBER]
        ,[DESTPRODUCTCODE]
        ,[DESTACTIVITYNAME]
        ,[DAYLOT]
        ,[DESTDEPARTMENT]
        ,[DESTSUBDEPARTMENT]
        ,[messageid]
				,[Shift]										--doc20231009ER
				,[PlantNum]								--doc20231009ER
				,[Shift_Item]							--doc20231009ER
				,[ProductionDate_Item]			--doc20231009ER
				)
      SELECT 
				p.[RECORDID]
				,[COMPANYCODE]
				,[WAREHOUSECODE]
				,[PRODORDERNUMBER]
				,[PRODUCTCODE]
				,[TRANSTYPE]
				,[QUANTITY]
				,[WEIGHT]
				,[UOM]
				,[LOTNUMBER]
				,[ACTIVITY_NAME]
				,[SALESORDERNUMBER]
				,[PRODUCTIONDATE]
				,[CREATEDATETIME]
				,[PROCESSEDDATETIME]
				,[STATUSFLAG]
				,[FREEZER]
				,[PRODORDSUBDEPT]
				,[SERIALNUM]
				,[MIXLOT]
				,[LINENUMBER]
				,[DESTPRODUCTCODE]
				,[DESTACTIVITYNAME]
				,[DAYLOT]
				,[DESTDEPARTMENT]
				,[DESTSUBDEPARTMENT]
				,[messageid]
				,[Shift]								--doc20231009ER
				,[PlantNum]							--doc20231009ER			
				,[Shift_Item]						--doc20231009ER
				,[ProductionDate_Item]	--doc20231009ER
			FROM #ReadyToProcess r
      Join [CAT2].[INTF_PRODORDTRANS] p With (NoLock) On
        p.messageid = r.GUIDRef

      Update INTF_PRODORDTRANS 
	    Set STATUSFLAG = 'P', PROCESSEDDATETIME = GETDATE()     
      From #ReadyToProcess r 
	    Join INTF_PRODORDTRANS p With (NoLock) On
        p.messageid = r.GUIDRef

      Update INTF_EXPORTS
      Set [STATUS] = 'P', COMPLETEDATETIME = GETDATE()
	    From #ReadyToProcess r 
      Join INTF_Exports e With (NoLock) On
        e.RECORDID = r.RecordID

      Insert Into OKSQL01P.OK.dbo.INTF_EXPORTS(
        [RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      [GUIDREF],
	      [STATUS],
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
        )
      Select
        e.[RECORDID], 
	      [SERIAL],
	      [PROCESSID],
	      [COMPANYCODE],
	      [WAREHOUSECODE],
	      e.[GUIDREF],
	      'T',           
	      [CREATEDATETIME],
	      [BUSYFLAG],
	      [STATUSMESSAGE],
	      [GUIDREFTABLE],
	      [GUIDDEST],
	      [GUIDDESTTABLE]
      From #ReadyToProcess r 
      Join INTF_EXPORTS e With (NoLock) On 
        e.RECORDID = r.RecordID

    Commit Transaction

  End Try
  Begin Catch
    If @@TRANCOUNT > 0
      RollBack Transaction
    Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  End Catch

/**********************************************************************************
doc20231219TMH Added section.
Change status in INTF_EXPORTS for ProcessID's we don't transfer/use. 
This will be any ProcessIDs NOT in @TransferredProcessID.
**********************************************************************************/

  Begin Try
    Begin Distributed Transaction

      Update CAT2.INTF_Exports
      Set [Status] = 'X'      
      Where ProcessID Not In (Select ProcessID From @TransferredProcessID)
        And [Status] = 'R'

    Commit Transaction

  End Try
  Begin Catch
    If @@TRANCOUNT > 0
      RollBack Transaction
    Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  End Catch


/**********************************************************************************
Change status for the INTF_EXPORTS that were sent to OKSQL01P
**********************************************************************************/


  Begin Try
    Begin Distributed Transaction

      Update OKSQL01P.OK.dbo.INTF_Exports
      Set [Status] = 'R'
      Where [Status] = 'T'
      
    Commit Transaction

  End Try
  Begin Catch
    If @@TRANCOUNT > 0
      RollBack Transaction
    Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()
		Raiserror(@ErrorMessage, @ErrorSeverity, 1) 
  End Catch

END

