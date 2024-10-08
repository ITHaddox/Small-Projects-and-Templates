USE [OKAppsSecurity]
GO
/****** Object:  StoredProcedure [dbo].[PRC_SearchApplicationRoles_SP]    Script Date: 10/07/2024 3:25:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/***********************************************************************************************************************************************
doc11202023TMH, HD#:339580, Created SP. This SP was created to populate the roles grid in the form "Application Roles - Modify Access". 
  The previous query in the form was not correct after the filters were added for forms, reports, and users in roles. 
  The issue was roles were not showing if the role didn’t have any components or if it didn’t have any role users. 
  In sales there was 4 roles that wouldn’t show.
doc11282023TMH, HD#:340124, Fixed issue with users not being able to edit records in the form. 
doc12192023TMH, HD#:340736, Added the parameter @RoleName so it can be used to filter records in the form based on the Role Name. 
***********************************************************************************************************************************************/
ALTER PROCEDURE [dbo].[PRC_SearchApplicationRoles_SP]
	@AppKey nvarchar(10) = '%', 
  @KeyUserID nvarchar(10) = '%',
  @FormKey nvarchar(10) = '%',
  @ReportKey nvarchar(10) = '%',
  @UserId nvarchar(10) = '%',
  @RoleName nvarchar(101) = '%'  --doc12192023TMH
AS
BEGIN
	SET NOCOUNT ON;

  Declare 
    @SQL nvarchar(MAX), 
    @ParameterDef nvarchar(MAX),
    @FormKeyFilter nvarchar(MAX), 
    @ReportKeyFilter nvarchar(MAX), 
    @UserIDFilter nvarchar(MAX)

  Set @ParameterDef =   '@AppKey nvarchar(10), 
                        @KeyUserID nvarchar(10), 
                        @FormKey nvarchar(10), 
                        @ReportKey nvarchar(10), 
                        @UserId nvarchar(10),
                        @RoleName nvarchar(101)'  --doc12192023TMH
            
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

  Set @SQL = 
    'Select Distinct
      ApplicationKey,
      ar.ApplicationRolesKey,
      Description,
      KeyUserID,
      CONCAT(um.fname, '' '', um.lname) As KeyUserName,
      ar.ActiveFlag
    From ApplicationRoles ar 
    Join UserMaster um On 
      ar.KeyUserID = um.UserID '
    + @FormKeyFilter +
    + @ReportKeyFilter +
    + @UserIDFilter + '
    Where
      ApplicationKey Like @AppKey 
      And KeyUserID Like @KeyUserID 
      And ar.Description Like @RoleName  
      Order By Description'
                                          --doc12192023TMH added the string above: "And ar.Description Like @RoleName". Added KeyUserName.

  --Print @SQL

  Exec sp_Executesql @SQL, 
                     @ParameterDef, 
                     @AppKey = @AppKey, 
                     @KeyUserID = @KeyUserID, 
                     @FormKey = @FormKey, 
                     @ReportKey = @ReportKey, 
                     @UserId = @UserId, 
                     @RoleName = @RoleName  --doc12192023TMH


  --doc11282023TMH begin
  --Declare @Roles Table(ApplicationKey Integer, 
  --                      ApplicationRolesKey Integer, 
  --                      [Description] varchar(100), 
  --                      KeyUserID Integer, 
  --                      ActiveFlag varchar(6))

  --Insert Into @Roles
  --Exec sp_Executesql @SQL, @ParameterDef, @AppKey = @AppKey, @KeyUserID = @KeyUserID, @FormKey = @FormKey, @ReportKey = @ReportKey, @UserId = @UserId

  --Select 
  --  ApplicationKey, 
  --  ApplicationRolesKey, 
  --  [Description], 
  --  KeyUserID, 
  --  ActiveFlag
  --From @Roles
  --doc11282023TMH end

END
