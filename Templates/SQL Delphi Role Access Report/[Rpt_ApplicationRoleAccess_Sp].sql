USE [OKAppsSecurity]
GO
/****** Object:  StoredProcedure [dbo].[Rpt_ApplicationRoleAccess_Sp]    Script Date: 10/07/2024 3:29:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************
Programmers: Bruce Schleiff, Wayne Parker
Date: 07/13/2023
Purpose: HD#319592. New Application Security Report, "Application Role Access".
-- Modifications --
doc20231102BS, HD#338450. Added input parameter @ShowActiveUsers and
               @AppUserName, modified SQL as needed.
doc20231121TMH, HD#339705. Had to rewrite queries to accommodate new changes and bug fixes.
                Fixed bug that wouldn’t show roles that had no users in the role. 
                Also, fixed roles that wouldn’t show that had no components (forms or reports) in the role, but these may be deleted soon.
	              Fixed bug with duplicate users showing in roles (would happen in inventory roles).
	              Fixed bug with all users in a role not showing when using the user filter on the form.
	              Fixed the order of all records. Like in inventory the forms, reports, users would be out of order. Also, ordered by key user.
	              Added filtering for forms and reports to work with the new combo box filters on the prompt form.
	              Removed IF statements that were used with the checkboxes on the form. The checkboxes asked if you wanted users, forms, and reports to show.

-- Usage --
Execute Rpt_ApplicationRoleAccess_Sp '%', '%', '%', '%', 1, 1, 1, 0  -- Show Active users only.
Execute Rpt_ApplicationRoleAccess_Sp '%', '%', '%', '%', 1, 1, 1, 1  -- Show Active and Inactive users.
Execute Rpt_ApplicationRoleAccess_Sp '%', '%', '%', 'brucesc', 1, 1, 1, 0
Execute Rpt_ApplicationRoleAccess_Sp '61', '392', '%', 'brucesc', 1, 1, 1, 0
Execute Rpt_ApplicationRoleAccess_Sp '61', '392', '%', 'waynepa', 1, 1, 1, 0   --App=Inventory, KeyUser=christian, paul UserID=parker, wayne
Execute Rpt_ApplicationRoleAccess_Sp '%', '%', '%', 'bobma', 1, 1, 1, 0  
--new parameters after this.
Execute Rpt_ApplicationRoleAccess_Sp '95', '%', '%', '%', '660', '%', 0 
Execute Rpt_ApplicationRoleAccess_Sp '95', '%', '%', '8381', '%', '%', 0 
Execute Rpt_ApplicationRoleAccess_Sp '%', '%', '%', '%', '%', '%', 0 
*******************************************************************************/
ALTER Procedure [dbo].[Rpt_ApplicationRoleAccess_Sp](
  @ApplicationKey Varchar(6),
  @KeyUserID Varchar(6),
  @ApplicationRolesKey Varchar(6),
  --@AppUserName Varchar(30),     --doc20231102BS   --doc20231121TMH
  --@Users Bit,                                     --doc20231121TMH
  --@Forms Bit ,                                    --doc20231121TMH
  --@Reports Bit,                                   --doc20231121TMH
  @UserID VarChar(10),                              --doc20231121TMH
  @FormKey Varchar(6),                              --doc20231121TMH
  @ReportKey Varchar(6),                            --doc20231121TMH
  @ShowInactiveUsers Bit)                           --doc20231102BS 
As
Begin
Set NoCount On

--doc20231121TMH Everything below is brand new. Had to rewrite the SP with new logic.
Create Table #Report(
  ApplicationKey Integer, 
  ApplicationName VarChar(50), 
  RoleDescription VarChar(100),  
  KeyUserID Integer, 
  RoleOwner Varchar(60),
  AccessType VarChar(10),
  [Description] VarChar(255),
  [Permissions] VarChar(12),
  FinancialImpactFlag VarChar(1),
  ShowInMenu VarChar(1),
  ActiveFlag VarChar(1))   

  -- dynamic SQL to fix the missing records not showing.
  Declare 
    @SQL nvarchar(MAX), 
    @ParameterDef nvarchar(MAX),
    @FormKeyFilter nvarchar(MAX), 
    @ReportKeyFilter nvarchar(MAX), 
    @UserIDFilter nvarchar(MAX)

  Set @ParameterDef =   '@ApplicationKey nvarchar(6), 
                        @KeyUserID nvarchar(6),
                        @ApplicationRolesKey nvarchar(6),
                        @UserId nvarchar(10),
                        @FormKey nvarchar(10), 
                        @ReportKey nvarchar(10)' 
  
  -- @FormKeyFilter, @ReportKeyFilter, and @UserIDFilter are needed here to support finding all records.
  -- This is because if a role does not have a user or component to join to then that role won't be in the results.
  -- This happens when a '%' is used for those parameters. This fixed the missing roles issue.
  Set @FormKeyFilter = 
    Case When @FormKey = '%' 
    Then ''
    Else 
    '
    Join ApplicationRoleComponents fc On
    ar.ApplicationRolesKey = fc.ApplicationRolesKey
    And fc.ApplicationComponentKey Like @FormKey '
    End

  Set @ReportKeyFilter = 
    Case When @ReportKey = '%'
      Then ''
      Else
      '
      Join ApplicationRoleComponents rc On
      ar.ApplicationRolesKey = rc.ApplicationRolesKey
      And rc.ApplicationComponentKey Like @ReportKey '
      End

  Set @UserIDFilter = 
    Case When @UserID = '%'
      Then '' 
      Else 
      '
      Join ApplicationRoleUsers u On
      ar.ApplicationRolesKey = u.ApplicationRolesKey
      And u.UserId Like @UserId '
    End

  -- All filters passed from the form will be used here. 
  -- This way the rest of the queries that load the form, report, and users data will not need to filter their queries again.
  Set @SQL = 
    'Select Distinct
      ar.ApplicationKey,
      ah.ApplicationName,
      ar.ApplicationRolesKey,
      ar.[Description],
      ar.KeyUserID,
      um.FullName,
      ar.ActiveFlag
    From ApplicationRoles ar 
    Join ApplicationHdr ah With (NoLock) On
      ah.ApplicationKey = ar.ApplicationKey 
    Join UserMaster um With (NoLock) On
      um.UserID = ar.KeyUserID '
    + @FormKeyFilter +
    + @ReportKeyFilter +
    + @UserIDFilter + '
    Where
      ar.ApplicationKey Like @ApplicationKey
      And ar.KeyUserID Like @KeyUserID
      And ar.ApplicationRolesKey Like @ApplicationRolesKey'

  --Print @SQL

  Declare @Roles Table(ApplicationKey Integer,
                       ApplicationName VarChar(50),
                        ApplicationRolesKey Integer, 
                        RoleDescription varchar(100), 
                        KeyUserID Integer, 
                        RoleOwner VarChar(60),
                        ActiveFlag varchar(6))

  Insert Into @Roles
  Exec sp_Executesql @SQL, 
                     @ParameterDef, 
                     @ApplicationKey = @ApplicationKey, 
                     @KeyUserID = @KeyUserID, 
                     @ApplicationRolesKey = @ApplicationRolesKey, 
                     @FormKey = @FormKey, 
                     @ReportKey = @ReportKey, 
                     @UserId = @UserId

  
  --Find all Application Role Components (forms and reports) tied to the filtered roles in @Roles
  Insert Into #Report
  Select Distinct
    r.ApplicationKey,
    r.ApplicationName,
    r.RoleDescription,
    r.KeyUserID,
    r.RoleOwner,
    Case ac.ComponentType
        When 'F' Then 'Forms'
        Else 'Reports'
      End As AccessType,
    ac.ComponentName As [Description],
    Case ac.ComponentType
        When 'F' Then Case When (arc.ReadAccess   <> 0) Then 'R.' Else '' End + ' ' +
                      Case When (arc.UpdateAccess <> 0) Then 'U.' Else '' End + ' ' +
                      Case When (arc.InsertAccess <> 0) Then 'I.' Else '' End + ' ' +
                      Case When (arc.DeleteAccess <> 0) Then 'D.' Else '' End
        Else 'Read'
      End As [Permissions],
    FinancialImpactFlag,
    ShowInMenu,
    '' As ActiveFlag   
  From @Roles r
  Join ApplicationRoleComponents arc With (NoLock) On
    arc.ApplicationRolesKey = r.ApplicationRolesKey
  Join ApplicationComponents ac With (NoLock) On
    ac.ApplicationComponentKey = arc.ApplicationComponentKey
  Order By [Description]  

  ----Find all Application Role Users tied to the filtered roles in @Roles  
  Insert Into #Report
  Select Distinct
    r.ApplicationKey,
    r.ApplicationName,
    r.RoleDescription,
    r.KeyUserID,
    r.RoleOwner,
    'Users' As AccessType,
    um.FullName As [Description],
    '' As [Permissions],
    '' As FinancialImpactFlag,
    '' As ShowInMenu,
    aru.ActiveFlag  
  From @Roles r
  Join ApplicationRoleUsers aru With (NoLock) On
    r.ApplicationRolesKey = aru.ApplicationRolesKey
  Join UserMaster um With (NoLock) On
    aru.UserID = um.UserID
  Where um.[Status] Like Case When @ShowInactiveUsers = 0 Then 'A'      
                                When @ShowInactiveUsers = 1 Then '%'     
                           End  

  -- All the data needed for the report to display.
  Select 
    ApplicationKey, 
    ApplicationName, 
    RoleDescription,  
    KeyUserID, 
    RoleOwner,
    AccessType,
    [Description],
    [Permissions],
    FinancialImpactFlag,
    ShowInMenu,
    ActiveFlag
  From #Report
  Order By 
    ApplicationName,
    RoleOwner,
    RoleDescription,
    AccessType Desc,
    [Description],
    ActiveFlag


--doc20231121TMH this was the old SP. Had to rewrite all of it since records were missing in the report.
/*
  Declare @UserID Varchar(9)    --doc20231102BS
  If @AppUserName = '%'         --doc20231102BS
    Set @UserID = '%'           --doc20231102BS
  Else                          --doc20231102BS
    Set @UserID = (Select Cast(UserID As Varchar(9)) From UserMaster With (NoLock) Where AppUserName = @AppUserName)  --doc20231102BS

  Create Table #Roles(
    ApplicationKey Integer, 
    ApplicationName VarChar(50), 
    ApplicationRolesKey Integer, 
    KeyUserID Integer, 
    RoleDescription VarChar(100), 
    ActiveFlag VarChar(1),
    UserID Integer)    --doc20231102BS

  Create Table #Access(
    ApplicationRolesKey Integer, 
    RoleDescription VarChar(100), 
    AccessType VarChar(255), 
    FinancialImpactFlag VarChar(1) Null,
    ShowInMenu VarChar(1) Null, 
    Description VarChar(255),
    [Permissions] Varchar(12),
   	ActiveFlag VarChar(1),
    UserID Integer)   --doc20231102BS

  Insert Into #Roles
  Select     
    ar.ApplicationKey, 
    ah.ApplicationName,
    ar.ApplicationRolesKey, 
    ar.KeyUserID, 
    ar.Description, 
    ar.ActiveFlag,
    um.UserID
  From ApplicationRoles ar With (NoLock)
    Join ApplicationHdr ah With (NoLock) On
      ar.ApplicationKey = ah.ApplicationKey
    Join ApplicationRoleUsers aru With (NoLock) On
      ar.ApplicationRolesKey = aru.ApplicationRolesKey
    Join UserMaster um With (NoLock) On
      aru.UserID = um.UserID
  Where ah.SecurityMethod = 'R'
    And ar.ApplicationKey Like @ApplicationKey
    And ar.ApplicationRolesKey Like @ApplicationRolesKey
  	And ar.KeyUserID Like @KeyUserID
    And um.UserID Like @UserID          --doc20231102BS

  --DetailTypes
  --1 = Forms
  If @Forms = 1
    Begin
      Insert Into #Access
      Select 
        arc.ApplicationRolesKey,
        Roles.RoleDescription,
        [AccessType] = 'Forms',
        ac.FinancialImpactFlag,
        ac.ShowInMenu,
        ac.ComponentName,
        [Permissions] = Case When (arc.ReadAccess   <> 0) Then 'R.' Else '' End + ' ' +
                        Case When (arc.UpdateAccess <> 0) Then 'U.' Else '' End + ' ' +
                        Case When (arc.InsertAccess <> 0) Then 'I.' Else '' End + ' ' +
                        Case When (arc.DeleteAccess <> 0) Then 'D.' Else '' End,
        '' As ActiveFlag,   --Only showing ActiveFlag for Users
        um.UserID
      From ApplicationRoleComponents arc With (Nolock) 
        Join ApplicationComponents ac With (Nolock) On
         arc.ApplicationComponentKey = ac.ApplicationComponentKey
        Join ApplicationRoles ar With (NoLock) On
          arc.ApplicationRolesKey = ar.ApplicationRolesKey
        Join ApplicationRoleUsers aru With (NoLock) On
          ar.ApplicationRolesKey = aru.ApplicationRolesKey
        Join UserMaster um With (NoLock) On
          aru.UserID = um.UserID
       Join #Roles Roles On
         arc.ApplicationRolesKey = Roles.ApplicationRolesKey And
         aru.UserID = Roles.UserID    --doc20231102BS
      Where ac.ComponentType = 'F'
        And ar.ApplicationKey Like @ApplicationKey
        And ar.ApplicationRolesKey Like @ApplicationRolesKey
  	    And ar.KeyUserID Like @KeyUserID
        And um.UserID Like @UserID                                        --doc20231102BS
        And um.Status Like Case When @ShowInactiveUsers = 0 Then 'A'      --doc20231102BS
                                When @ShowInactiveUsers = 1 Then '%'      --doc20231102BS
                           End                                            --doc20231102BS
    End

--2 = Reports
  If @Reports = 1
    Begin
      Insert Into #Access
      Select Distinct
        arc.ApplicationRolesKey,
        Roles.RoleDescription ,
        [AccessType] = 'Reports',
        ac.FinancialImpactFlag,
        ac.ShowInMenu,
        ac.ComponentName,
        [Permissions] = 'Execute',
		    '' As ActiveFlag,   --Only showing ActiveFlag for Users
        um.UserID
      From ApplicationRoleComponents arc With (Nolock) 
        Join ApplicationComponents ac With (Nolock) On
         arc.ApplicationComponentKey = ac.ApplicationComponentKey
        Join ApplicationRoles ar With (NoLock) On
          arc.ApplicationRolesKey = ar.ApplicationRolesKey
        Join ApplicationRoleUsers aru With (NoLock) On
          ar.ApplicationRolesKey = aru.ApplicationRolesKey
        Join UserMaster um With (NoLock) On
          aru.UserID = um.UserID
       Join #Roles Roles On
         arc.ApplicationRolesKey = Roles.ApplicationRolesKey And
         aru.UserID = Roles.UserID    --doc20231102BS
      Where ac.ComponentType <> 'F'
        And ar.ApplicationKey Like  @ApplicationKey
        And ar.ApplicationRolesKey Like @ApplicationRolesKey
  	    And ar.KeyUserID Like @KeyUserID
        And um.UserID Like @UserID                                        --doc20231102BS
        And um.Status Like Case When @ShowInactiveUsers = 0 Then 'A'      --doc20231102BS
                                When @ShowInactiveUsers = 1 Then '%'      --doc20231102BS
                           End                                            --doc20231102BS
    End

  --3 = Users
  If @Users = 1
    Begin
      Insert Into #Access
      Select Distinct
        aru.ApplicationRolesKey,
        Roles.RoleDescription,
        [AccessType] = 'Users',
        FinancialImpactFlag = '',
        ShowInMenu = '',
        um.FullName,
        [Permissions] = '',
        aru.ActiveFlag,
        aru.UserID
      From ApplicationRoleComponents arc With (Nolock) 
        Join ApplicationComponents ac With (Nolock) On
         arc.ApplicationComponentKey = ac.ApplicationComponentKey
        Join ApplicationRoles ar With (NoLock) On
          arc.ApplicationRolesKey = ar.ApplicationRolesKey
        Join ApplicationRoleUsers aru With (NoLock) On
          ar.ApplicationRolesKey = aru.ApplicationRolesKey
        Join UserMaster um With (NoLock) On
          aru.UserID = um.UserID
       Join #Roles Roles On
         arc.ApplicationRolesKey = Roles.ApplicationRolesKey And
         aru.UserID = Roles.UserID          --doc20231102BS
      Where ar.ApplicationKey Like @ApplicationKey
        And ar.ApplicationRolesKey Like @ApplicationRolesKey
  	    And ar.KeyUserID Like @KeyUserID
        And um.UserID Like @UserID                                        --doc20231102BS
        And um.Status Like Case When @ShowInactiveUsers = 0 Then 'A'      --doc20231102BS
                                When @ShowInactiveUsers = 1 Then '%'      --doc20231102BS
                           End                                            --doc20231102BS
    End

  Select Distinct
    Roles.ApplicationKey,
    Roles.ApplicationName,
    Roles.RoleDescription,
    Roles.KeyUserID,
    RoleOwner = UserMaster.FullName,
    Access.AccessType,
    Access.Description,
    [Permissions],
    Access.FinancialImpactFlag,
    Access.ShowInMenu,
    Access.ActiveFlag
  From #Roles Roles
    Join UserMaster With (Nolock) On
      Roles.KeyUserID = UserMaster.UserID
    Join #Access Access On
      Roles.ApplicationRolesKey = Access.ApplicationRolesKey And
      Roles.UserID = Access.UserID  --doc20231102BS
  Order By
    Roles.ApplicationName,
    Roles.RoleDescription,
    Access.AccessType Desc,
    Access.ActiveFlag

  Drop Table If Exists #Roles
  Drop Table If Exists #Access
*/

End