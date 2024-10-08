USE [OKAppsSecurity]
GO
/****** Object:  StoredProcedure [dbo].[PRC_MirrorRestoreRemoveRoleAccess_SP]    Script Date: 10/07/2024 3:20:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*-- =============================================
doc09112023TMH, HD#334092: Created SP. Ran by form "Application Roles - Mirror, Restore, Remove". 
                           Mirror will copy one users access to another user.
                           Restore will make a user active again for everything they had access to when they left the company previously.
                           Remove will inactivate a user everywhere they are currently active.
                           The tables these operations modify are: ApplicationRoleUsers, WarehouseAccess, PrinterQueuesUsers, PlantUserXRef, 
                           ScanStationAccess, ScanStationEmpAccess, CodesAccess, ApplicationConnectionAccess.
doc01252024TMH, HD#343244: Fixed ScanStationAccess unique key error when dest user already has access to the same scan station as the source user but has
                           a different ScanIDFlag value.
-- =============================================
*/
ALTER   PROC [dbo].[PRC_MirrorRestoreRemoveRoleAccess_SP]
	(
    @DestUserID           Int, 
    @SourceUserID         Int,
    @RoleKeys             VarChar(8000),  --Comma delimited string list of keys.
    @CopyWarehouse        Bit,
    @CopyPrinterQueue     Bit,
    @CopyPlantUser        Bit,
    @CopyScanStation      Bit,
    @CopyCodes            Bit,
    @CopyConnection       Bit,
    @AccessOperation      Int       -- 0 = Mirror, 1 = Restore, 2 = Remove
  )                                                                    
AS
BEGIN
SET NOCOUNT ON;

Declare @RoleKey int --Note: @RoleKeys and @RoleKey are different.
Declare @AppKeys Table (AppKey Integer)   --Needed later for changing ApplicationConnectionAccess.

Insert Into @AppKeys(AppKey)   --loads table variable @AppKeys
Select Distinct ApplicationKey 
From ApplicationRoles 
Where ApplicationRolesKey in (Select [Value] From STRING_SPLIT(@RoleKeys, ','))

Drop Table If Exists #tempRoles
Create Table #tempRoles(
  RoleKey [int] NOT NULL,
  RoleName [varchar](100) NOT NULL,
  AppName [varchar](50) NOT NULL,
  RecordStatus [char] NOT NULL) --Used later in form "Application Roles - Mirror User" to display message. 'A'ctivated, 'N'othing changed, 'R'eactivated.
                                --Deleted/removed operation will not really need this.

Declare RC_CUR Cursor Fast_Forward For
  Select [Value] From STRING_SPLIT(@RoleKeys, ',')
  


/**********************************************************************
Remove/Delete
**********************************************************************/
If @AccessOperation = 2
Begin
  Open RC_CUR
  Fetch Next From RC_CUR Into @RoleKey
  While @@FETCH_STATUS = 0
  Begin  
    If Exists(Select UserID 
              From ApplicationRoleUsers ru
              Where ApplicationRolesKey = @RoleKey
                And UserID = @DestUserID) 
      Begin
        --Delete From ApplicationRoleUsers
        --Where ApplicationRolesKey = @RoleKey
        --  And UserID = @DestUserID
        Update ApplicationRoleUsers
        Set ActiveFlag = 'I'
        Where ApplicationRolesKey = @RoleKey
          And UserID = @DestUserID

        Insert Into #tempRoles
        Select
          @RoleKey, 
          [Description], 
          ApplicationName,
          'D' --deleted/removed 
        From ApplicationRoles r
        Join ApplicationHdr h On
          h.ApplicationKey = r.ApplicationKey
        Where ApplicationRolesKey = @RoleKey
      End 
  
    Fetch Next From RC_Cur Into @RoleKey
  End
  Close RC_CUR
  Deallocate RC_CUR

  If (@CopyWarehouse = 1)
    Begin
      Update OK.dbo.WarehouseAccess 
      Set ActiveFlag = 'I'
      Where UserId = @SourceUserID
    End

  If (@CopyPrinterQueue = 1)
    Begin
      Update LabelSystem.dbo.PrinterQueuesUsers 
      Set ActiveFlag = 'I'
      Where UserId = @SourceUserID
    End

  If (@CopyPlantUser = 1)
    Begin
		  Update LabelSystem.dbo.PlantUserXref 
      Set ActiveFlag = 'I'
      Where UserId = @SourceUserID
    End
  
  If (@CopyScanStation = 1)
    Begin
      Update OK.dbo.ScanStationAccess
      Set ActiveFlag = 'I'
      Where UserId = (Select AppUserName From OKAppsSecurity.dbo.UserMaster Where UserId = @SourceUserID)

      Update OK.dbo.ScanStationEmpAccess
      Set ActiveFlag = 'I'
      Where EmployeeNo In (Select EmployeeNo From OKAppsSecurity.dbo.UserMaster Where UserId = @SourceUserID)
    End
  
  If @CopyCodes = 1
  Begin
    Update CodesAccess
    Set ActiveFlag = 'I'
    Where UserID = @SourceUserID
  End

  If @CopyConnection = 1
  Begin
    Update ApplicationConnectionAccess
    Set ActiveFlag = 'I'
    Where UserID = @SourceUserID
      And ApplicationKey In (Select AppKey From @AppKeys)
  End
End

/**********************************************************************
Mirror/Restore
Notes: The reason these two options, Mirror and Restore, are together is... 
       Mirror uses a source user and dest user variable, that's obvious... 
       Restore uses the source user in BOTH the source user AND dest user variables. This way there isn't another 
        section for restore that basically does the same as the mirror logic.
**********************************************************************/
If (@AccessOperation In (0,1))
Begin
  /**** Mirror/Restore ApplicationRoleUsers ****/
  Open RC_CUR
  Fetch Next From RC_CUR Into @RoleKey
  While @@FETCH_STATUS = 0
  Begin
    If Not Exists(Select UserID 
                  From ApplicationRoleUsers ru
                  Where ApplicationRolesKey = @RoleKey
                        And UserID = @DestUserID) 
      Begin
        Insert Into ApplicationRoleUsers 
          Values(@RoleKey, @DestUserID, 'A') 

        Insert Into #tempRoles
        Select
          @RoleKey, 
          [Description], 
          ApplicationName,
          'A' --activated - RoleKey and UserID didn't exist in role so new record inserted. 
        From ApplicationRoles r
        Join ApplicationHdr h On
          h.ApplicationKey = r.ApplicationKey
        Where ApplicationRolesKey = @RoleKey
      End 
    Else 
      Begin
        Insert Into #tempRoles
        Select
          @RoleKey,
          [Description],
          ApplicationName,
          Case 
            When UserID = @DestUserID and u.ActiveFlag = 'A' Then 'N' -- nothing changed - already had access
            When UserID = @DestUserID and u.ActiveFlag = 'I' Then 'R' --reactivated
            end 
        From ApplicationRoleUsers u
        Join ApplicationRoles r On
          r.ApplicationRolesKey = u.ApplicationRolesKey
        Join ApplicationHdr h On
          h.ApplicationKey = r.ApplicationKey
        Where UserID = @DestUserID
          And u.ApplicationRolesKey = @RoleKey

        Update ApplicationRoleUsers 
        Set ActiveFlag = 'A'
        Where ApplicationRolesKey = @RoleKey
          And UserID = @DestUserID  
          And ActiveFlag = 'I'    
      End 
  
    Fetch Next From RC_Cur Into @RoleKey
  End
  Close RC_CUR
  Deallocate RC_CUR

  /**** Mirror/Restore OK.dbo.WarehouseAccess ****/
  If @CopyWarehouse = 1
  Begin 
    Drop Table If Exists #tempWA
    Create Table #tempWA(
      Warehouse int NOT NULL, 
      AccessLevel int NULL)

    If Exists(Select Status From UserMaster With (NoLock) Where UserID = @SourceUserID And [Status] = 'I')
	    Begin
        Insert Into #tempWA
        Select Warehouse, AccessLevel
        From OK.dbo.WarehouseAccessAudit
        Where UserId = @SourceUserID
					and Action = 'U'
					and AuditDate = ( Select MAX(AuditDate)
								            From OK.dbo.WarehouseAccessAudit (NoLock)
								            Where UserId = @SourceUserID
								              And Action = 'U')
      End
    Else --source user is still active
      Begin
        Insert Into #tempWA
        Select Warehouse, AccessLevel
        From OK.dbo.WarehouseAccess
        Where UserId = @SourceUserID
					And ActiveFlag = 'A'
      End
    
    Declare @Warehouse int, @AccessLevel int
    Declare WA_CUR Cursor Fast_Forward For
    Select Warehouse, AccessLevel From #tempWA
    Open WA_CUR
    Fetch Next From WA_CUR Into @Warehouse, @AccessLevel

    While @@FETCH_STATUS = 0
      Begin
        Update OK.dbo.WarehouseAccess
        Set ActiveFlag = 'A', AccessLevel = @AccessLevel
        Where Warehouse = @Warehouse
          And UserId = @DestUserID

        If @@ROWCOUNT = 0
        Begin
          Insert OK.dbo.WarehouseAccess(Warehouse, UserId, ActiveFlag, AccessLevel)
          Values (@Warehouse, @DestUserID, 'A', @AccessLevel)          
        End

        Fetch Next From WA_Cur Into @Warehouse, @AccessLevel
      End

    Close WA_Cur
    Deallocate WA_Cur
  End

  /**** Mirror/Restore LabelSystem.dbo.PrinterQueuesUsers ****/
  If @CopyPrinterQueue = 1
  Begin
    Drop Table If Exists #tempPQU
    Create Table #tempPQU(
      PrinterQueuesKey int NOT NULL)

    If Exists(Select Status From UserMaster With (NoLock) Where UserID = @SourceUserID And [Status] = 'I')
	    Begin
        Insert Into #tempPQU
        Select PrinterQueuesKey
        From LabelSystem.dbo.PrinterQueuesUsersAudit
        Where UserId = @SourceUserID
					and Action = 'U'
					and AuditDate = ( Select MAX(AuditDate)
								            From LabelSystem.dbo.PrinterQueuesUsersAudit (NoLock)
								            Where UserId = @SourceUserID
								              And Action = 'U')
      End
    Else --source user is still active
      Begin
        Insert Into #tempPQU
        Select PrinterQueuesKey
        From LabelSystem.dbo.PrinterQueuesUsers
        Where UserId = @SourceUserID
					And ActiveFlag = 'A'
      End
    
    Declare @PrinterQueuesKey int
    Declare PQU_CUR Cursor Fast_Forward For
    Select PrinterQueuesKey From #tempPQU
    Open PQU_CUR
    Fetch Next From PQU_CUR Into @PrinterQueuesKey

    While @@FETCH_STATUS = 0
      Begin
        Update LabelSystem.dbo.PrinterQueuesUsers
        Set ActiveFlag = 'A'
        Where PrinterQueuesKey = @PrinterQueuesKey
          And UserId = @DestUserID

        If @@ROWCOUNT = 0
        Begin
          Insert LabelSystem.dbo.PrinterQueuesUsers(UserId, PrinterQueuesKey, ActiveFlag)
          Values (@DestUserID, @PrinterQueuesKey, 'A')          
        End

        Fetch Next From PQU_CUR Into @PrinterQueuesKey
      End

    Close PQU_CUR
    Deallocate PQU_CUR    
  End

  /**** Mirror/Restore LabelSystem.dbo.PlantUserXref ****/
  If @CopyPlantUser = 1
  Begin
    Drop Table If Exists #tempPUX
    Create Table #tempPUX(
      Plant int NOT NULL,
      Line varchar(6) NOT NULL)

    If Exists(Select Status From UserMaster With (NoLock) Where UserID = @SourceUserID And [Status] = 'I')
	    Begin
        Insert Into #tempPUX
        Select Plant, Line
        From LabelSystem.dbo.PlantUserXrefAudit
        Where UserId = @SourceUserID
					and Action = 'U'
					and AuditDate = ( Select MAX(AuditDate)
								            From LabelSystem.dbo.PlantUserXrefAudit (NoLock)
								            Where UserId = @SourceUserID
								              And Action = 'U')
      End
    Else --source user is still active
      Begin
        Insert Into #tempPUX
        Select Plant, Line
        From LabelSystem.dbo.PlantUserXref
        Where UserId = @SourceUserID
					And ActiveFlag = 'A'
      End
    
    Declare @Plant int, @Line varchar(6)
    Declare PUX_CUR Cursor Fast_Forward For
    Select Plant, Line From #tempPUX
    Open PUX_CUR
    Fetch Next From PUX_CUR Into @Plant, @Line

    While @@FETCH_STATUS = 0
      Begin
        Update LabelSystem.dbo.PlantUserXref
        Set ActiveFlag = 'A'
        Where Plant = @Plant
          And Line = @Line
          And UserId = @DestUserID

        If @@ROWCOUNT = 0
        Begin
          Insert LabelSystem.dbo.PlantUserXref(Plant, UserId, ActiveFlag, Line)
          Values (@Plant, @DestUserID, 'A', @Line)          
        End

        Fetch Next From PUX_CUR Into @Plant, @Line
      End

    Close PUX_CUR
    Deallocate PUX_CUR    
  End

  /**** Mirror ScanStationAccess and ScanStationEmpAccess ****/
  If (@CopyScanStation = 1)
  Begin
    Declare @SourceAppUserName varchar(24), @DestAppUserName varchar(24)
    Set @SourceAppUserName = (Select AppUserName From OKAppsSecurity.dbo.UserMaster Where UserId = @SourceUserID)
    Set @DestAppUserName = (Select AppUserName From OKAppsSecurity.dbo.UserMaster Where UserId = @DestUserID)

    Drop Table If Exists #tempSSA
    Create Table #tempSSA(
      ScanStationKey int NOT NULL
      ,ScanIdFlag varchar(1) NULL    
      )     

    If Exists(Select [Status] From UserMaster With (NoLock) Where UserID = @SourceUserID And [Status] = 'I')
	    Begin
        Insert Into #tempSSA
        Select ScanStationKey, ScanIdFlag     
        From OK.dbo.ScanStationAccessAudit
        Where UserId = @SourceAppUserName
					and [Action] = 'U'
					and AuditDate = ( Select MAX(AuditDate)
								            From OK.dbo.ScanStationAccessAudit (NoLock)
								            Where UserId = @SourceAppUserName
								              And [Action] = 'U')
      End
    Else --source user is still active
      Begin
        Insert Into #tempSSA
        Select ScanStationKey, ScanIdFlag
        From OK.dbo.ScanStationAccess
        Where UserId = @SourceAppUserName
					And ActiveFlag = 'A'
      End
    
    Declare @ScanStationKey int, @ScanIdFlag varchar(1)
    Declare SSA_CUR Cursor Fast_Forward For
    Select ScanStationKey, ScanIdFlag From #tempSSA
    Open SSA_CUR
    Fetch Next From SSA_CUR Into @ScanStationKey, @ScanIdFlag

    While @@FETCH_STATUS = 0
      Begin
        Update OK.dbo.ScanStationAccess
        --Set ActiveFlag = 'A'                              --doc01252024TMH
        Set ActiveFlag = 'A', ScanIDFlag = @ScanIDFlag      --doc01252024TMH
        Where ScanStationKey = @ScanStationKey
          --And ScanIdFlag = @ScanIdFlag                    --doc01252024TMH
          And UserId = @DestAppUserName

        If @@ROWCOUNT = 0
        Begin
          Insert OK.dbo.ScanStationAccess(ScanStationKey, UserId, ActiveFlag, ScanIdFlag)
          Values (@ScanStationKey, @DestAppUserName, 'A', @ScanIdFlag)          
        End

        Fetch Next From SSA_CUR Into @ScanStationKey, @ScanIdFlag
      End

    Close SSA_CUR
    Deallocate SSA_CUR   

    --Second part for scan station - ScanStationEmpAccess
    Declare @SourceEmployeeNo int, @DestEmployeeNo int
    Set @SourceEmployeeNo = (Select EmployeeNo From OKAppsSecurity.dbo.UserMaster Where UserId = @SourceUserID)
    Set @DestEmployeeNo = (Select EmployeeNo From OKAppsSecurity.dbo.UserMaster Where UserId = @DestUserID)

    Drop Table If Exists #tempSSEA
    Create Table #tempSSEA(
      ScanStationKey int NOT NULL,
      EmployeeNo int NOT NULL)

    If Exists(Select [Status] From UserMaster With (NoLock) Where UserID = @SourceUserID And [Status] = 'I')
	    Begin
        Insert Into #tempSSEA
        Select ScanStationKey, EmployeeNo
        From OK.dbo.ScanStationEmpAccessAudit
        Where EmployeeNo = @SourceEmployeeNo
					and Action = 'U'
					and AuditDate = ( Select MAX(AuditDate)
								            From OK.dbo.ScanStationEmpAccessAudit (NoLock)
								            Where EmployeeNo = @SourceEmployeeNo
								              And Action = 'U')
      End
    Else --source user is still active
      Begin
        Insert Into #tempSSEA
        Select ScanStationKey, EmployeeNo
        From OK.dbo.ScanStationEmpAccess
        Where EmployeeNo = @SourceEmployeeNo
					And ActiveFlag = 'A'
      End
    
    Declare @ScanStationKeySSEA int, @EmployeeNo int
    Declare SSEA_CUR Cursor Fast_Forward For
    Select ScanStationKey, EmployeeNo From #tempSSEA
    Open SSEA_CUR
    Fetch Next From SSEA_CUR Into @ScanStationKeySSEA, @EmployeeNo

    While @@FETCH_STATUS = 0
      Begin
        Update OK.dbo.ScanStationEmpAccess
        Set ActiveFlag = 'A'
        Where ScanStationKey = @ScanStationKeySSEA
          And EmployeeNo = @DestEmployeeNo

        If @@ROWCOUNT = 0
        Begin
          Insert OK.dbo.ScanStationEmpAccess(ScanStationKey, EmployeeNo, ActiveFlag)
          Values (@ScanStationKeySSEA, @DestEmployeeNo, 'A')          
        End

        Fetch Next From SSEA_CUR Into @ScanStationKeySSEA, @EmployeeNo
      End

    Close SSEA_CUR
    Deallocate SSEA_CUR   
  End

  /**** Mirror/Restore CodesAccess ****/
  If @CopyCodes = 1
  Begin
    Drop Table If Exists #tempCA
    Create Table #tempCA(
      CodeComponentsKey int NOT NULL)

    If Exists(Select Status From UserMaster With (NoLock) Where UserID = @SourceUserID And [Status] = 'I')
	    Begin
        Insert Into #tempCA
        Select CodeComponentsKey
        From CodesAccessAudit
        Where UserId = @SourceUserID
					and Action = 'U'
					and AuditDate = ( Select MAX(AuditDate)
								            From CodesAccessAudit (NoLock)
								            Where UserId = @SourceUserID
								              And Action = 'U')
      End
    Else --source user is still active
      Begin
        Insert Into #tempCA
        Select CodeComponentsKey
        From CodesAccess
        Where UserId = @SourceUserID
					And ActiveFlag = 'A'
      End
    
    Declare @CodeComponentsKey int
    Declare CA_CUR Cursor Fast_Forward For
    Select CodeComponentsKey From #tempCA
    Open CA_CUR
    Fetch Next From CA_CUR Into @CodeComponentsKey

    While @@FETCH_STATUS = 0
      Begin
        Update CodesAccess
        Set ActiveFlag = 'A'
        Where CodeComponentsKey = @CodeComponentsKey
          And UserId = @DestUserID

        If @@ROWCOUNT = 0
        Begin
          Insert CodesAccess(CodeComponentsKey, UserId, ActiveFlag)
          Values (@CodeComponentsKey, @DestUserID, 'A')          
        End

        Fetch Next From CA_CUR Into @CodeComponentsKey
      End

    Close CA_CUR
    Deallocate CA_CUR       
  End

  /**** Mirror/Restore ApplicationConnectionAccess ****/
  If @CopyConnection = 1
  Begin
    Drop Table If Exists #tempACA
    Create Table #tempACA(
      ApplicationKey Int NOT NULL,
      ConnectionKey Int NOT NULL,
      DefaultConnection char(1))

    If Exists(Select Status From UserMaster With (NoLock) Where UserID = @SourceUserID And [Status] = 'I')
	    Begin
        Insert Into #tempACA
        Select ApplicationKey, ConnectionKey, DefaultConnection
        From ApplicationConnectionAccessAudit
        Where UserId = @SourceUserID
					And Action = 'U'
          And ApplicationKey In (Select AppKey From @AppKeys)
					And AuditDate = ( Select MAX(AuditDate)
								            From ApplicationConnectionAccessAudit (NoLock)
								            Where UserId = @SourceUserID
								              And Action = 'U'
                              And ApplicationKey In (Select AppKey From @AppKeys))
      End
    Else --source user is still active
      Begin
        Insert Into #tempACA
        Select ApplicationKey, ConnectionKey, DefaultConnection
        From ApplicationConnectionAccess
        Where UserId = @SourceUserID
					And ActiveFlag = 'A'
          And ApplicationKey In (Select AppKey From @AppKeys)
      End
    
    Declare @ApplicationKey int, @ConnectionKey int, @DefaultConnection char(1)
    Declare ACA_CUR Cursor Fast_Forward For
    Select ApplicationKey, ConnectionKey, DefaultConnection From #tempACA
    Open ACA_CUR
    Fetch Next From ACA_CUR Into @ApplicationKey, @ConnectionKey, @DefaultConnection

    While @@FETCH_STATUS = 0
      Begin
        Update ApplicationConnectionAccess
        Set ActiveFlag = 'A', DefaultConnection = @DefaultConnection
        Where ApplicationKey = @ApplicationKey
          And ConnectionKey = @ConnectionKey
          And UserId = @DestUserID

        If @@ROWCOUNT = 0
        Begin
          Insert ApplicationConnectionAccess(ApplicationKey, ConnectionKey, UserId, DefaultConnection, ActiveFlag)
          Values (@ApplicationKey, @ConnectionKey, @DestUserID, @DefaultConnection, 'A')          
        End

        Fetch Next From ACA_CUR Into @ApplicationKey, @ConnectionKey, @DefaultConnection
      End

    Close ACA_CUR
    Deallocate ACA_CUR 
  End

End

--Select * From #tempWA
--Select * From #tempPUX
--Select * From #tempPQU
--Select * From #tempSSA
--Select * From #tempSSEA
--Select * From #tempCA
--Select * From #tempACA

Select RoleKey, RoleName, AppName, RecordStatus From #tempRoles     -- Needed for the form to display a custom message dialog.

End
