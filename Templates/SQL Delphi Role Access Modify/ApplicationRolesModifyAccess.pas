{
doc06192023TMH, HD#317752: Created form. This allows modifying the role-based security tables.
  Pick application, add roles to an application, then add components and users to that role.
  Tables: ApplicationRoles, ApplicationRoleComponents, ApplicationRoleUsers.
  Green Applications have SecurityMethod = 'R' and are activly used as the security settings.
  Red users are inactive.
  Yellow components have a different key user than the role they are in. This is because the
  component use to belong to the role key user. These signify that they need to be changed by infrastructure.
doc09192023TMH, HD#:334092: Restricted access on modifying the tables for specific groups of users.
                            This is done by using access components.
11012023WP:  HD Ticket# 338452, added more search fields to the top of this form
doc11132023TMH, HD#:338259: Prompt allows setting up default production connection if user is
  added to role with no connections.
doc11172023TMH, HD#:339357: Fixed index out of bounds error if user tried using the lookup on Roles
  with Users box without a application selected.
doc11202023TMH, HD#:339580: Fixed bug that wasn’t showing a role if it didn’t have any components or if it
  didn’t have any role users. In sales there was 4 roles that wouldn’t show.
  Fixed bug that prevented the grids from requiring if the roles query had zero results for the previous query.
  Sped up the scrolling on the form slightly by removing filter condition on application components. Added
  join to their query.
  Reduced lines of code by setting ‘%’ in combo boxes as object just like the rest of the data in the
  combo boxes. Just like I did when I created the cbKeyUser.
  Created PRC_SearchApplicationRoles_SP and used dynamic SQL to fix the issues with the form’s filters
  not working correctly. This SP is used to populate the Roles grid.
doc12062023TMH, HD#:340643, Fixed the error when trying to delete some forms in roles.
doc12192023TMH, HD#:340736, HD#:339760, Added Role Name combobox for filtering.
                            Can now sort by user name, report name, and form name.
                            Dramatically increased the speed of scrolling in the roles grid.
                            Added clear button and rearranged filters in the header of the form.
                            Added Role Key to grid and the App Key to the top of the form.
                            Form no longer sets focus on role grid after choosing application.
                            Added text hint on Applications Combo box.
                            The '%' now shows in all combo boxes when form opens.
}

unit untApplicationRolesModifyAccess;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.DBCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.StdCtrls, Vcl.ExtCtrls, Data.Win.ADODB, Vcl.Buttons,
  Vcl.ComCtrls, System.UITypes, Vcl.Menus, Datasnap.DBClient;

type
  TfrmApplicationRolesModifyAccess = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    lbApplicationName: TLabel;
    cbApplications: TComboBox;
    lbRoles: TLabel;
    aqryApplicationRoles: TADOQuery;
    Panel3: TPanel;
    sbClose: TSpeedButton;
    dbnvNav: TDBNavigator;
    dsApplicationRoles: TDataSource;
    aqryApplicationRolesApplicationRolesKey: TAutoIncField;
    aqryApplicationRolesRoleName: TStringField;
    aqryApplicationRolesKeyUserID: TIntegerField;
    aqryApplicationRolesActiveFlag: TStringField;
    aqryARCForms: TADOQuery;
    dsARCForms: TDataSource;
    Panel4: TPanel;
    pcAssignedToRole: TPageControl;
    lbComponents: TLabel;
    Forms: TTabSheet;
    Reports: TTabSheet;
    dbgARCForms: TDBGrid;
    dbgARCReports: TDBGrid;
    aqryARCReports: TADOQuery;
    dsARCReports: TDataSource;
    tsUsers: TTabSheet;
    aqryRoleUsers: TADOQuery;
    dsRoleUsers: TDataSource;
    dbgRoleUsers: TDBGrid;
    aqryRoleUsersApplicationRoleUsersKey: TAutoIncField;
    aqryUserLookup: TADOQuery;
    aqryUserLookupUserID: TAutoIncField;
    aqryApplicationRolesName: TStringField;
    aqryApplicationRolesApplicationKey: TIntegerField;
    aqryFormCompLookup: TADOQuery;
    aqryFormCompLookupApplicationComponentKey: TAutoIncField;
    aqryFormCompLookupComponentName: TStringField;
    aqryARCReportsRoleKey: TIntegerField;
    aqryARCReportsComponentKey: TIntegerField;
    aqryARCReportsRead: TBooleanField;
    aqryARCReportsInsert: TBooleanField;
    aqryARCReportsUpdate: TBooleanField;
    aqryARCReportsDelete: TBooleanField;
    aqryARCReportsComponentName: TStringField;
    aqryReportCompLookup: TADOQuery;
    AutoIncField1: TAutoIncField;
    StringField1: TStringField;
    aqryARCReportsActiveFlag: TStringField;
    aqryRoleUsersActiveFlag: TStringField;
    aqryRoleUsersRoleKey: TIntegerField;
    aqryFormCompLookupComponentType: TStringField;
    aqryARCReportsComponentType: TStringField;
    aqryReportCompLookupComponentType: TStringField;
    aqryApplicationsCB: TADOQuery;
    aqryApplicationsCBApplicationName: TStringField;
    aqryApplicationsCBApplicationKey: TAutoIncField;
    aqryApplicationsCBSecurityMethod: TStringField;
    aqryFormCompLookupShowInMenu: TStringField;
    aqryReportCompLookupShowInMenu: TStringField;
    aqryARCReportsShowInMenu: TStringField;
    aqryDeleteAppRole: TADOQuery;
    aqryUserLookupStatus: TStringField;
    aqryApplicationRolesStatus: TStringField;
    aqryUserLookupName: TStringField;
    cbShowInactive: TCheckBox;
    aqryFormCompLookupKeyUserID: TIntegerField;
    aqryReportCompLookupKeyUserID: TIntegerField;
    aqryARCReportsKeyUserID: TIntegerField;
    aqryARCFormsApplicationRolesKey: TIntegerField;
    aqryARCFormsApplicationComponentKey: TIntegerField;
    aqryARCFormsReadAccess: TBooleanField;
    aqryARCFormsInsertAccess: TBooleanField;
    aqryARCFormsUpdateAccess: TBooleanField;
    aqryARCFormsDeleteAccess: TBooleanField;
    aqryARCFormsComponentName: TStringField;
    aqryARCFormsShowInMenu: TStringField;
    aqryARCFormsKeyUserID: TIntegerField;
    aqryARCFormsComponentType: TStringField;
    aqryARCFormsActiveFlag: TStringField;
    aqryUserLookupForRoleUsers: TADOQuery;
    AutoIncField2: TAutoIncField;
    StringField2: TStringField;
    StringField3: TStringField;
    lbKeyUser: TLabel;
    cbKeyUser: TComboBox;
    aqryKeyUserCB: TADOQuery;
    IntegerField1: TIntegerField;
    StringField6: TStringField;
    aqryCanAddOrModifyInactiveRoles: TADOQuery;
    StringField4: TStringField;
    IntegerField2: TIntegerField;
    StringField5: TStringField;
    StringField7: TStringField;
    IntegerField3: TIntegerField;
    AutoIncField3: TAutoIncField;
    StringField8: TStringField;
    cbForms: TComboBox;
    aqryFormsCB: TADOQuery;
    aqryFormsCBApplicationComponentKey: TAutoIncField;
    aqryFormsCBComponentName: TStringField;
    Label1: TLabel;
    Label2: TLabel;
    cbReports: TComboBox;
    aqryReportsCB: TADOQuery;
    AutoIncField4: TAutoIncField;
    StringField9: TStringField;
    Label3: TLabel;
    ebUserName: TEdit;                                                          //doc11132023TMH
    aqryFindTopProdConnectionForApp: TADOQuery;                                 //doc11132023TMH
    aqryFindTopProdConnectionForAppConnectionKey: TIntegerField;
    aqryFindTopProdConnectionForAppConnectionName: TStringField;
    aqryAssignedConnections: TADOQuery;                                         //doc11132023TMH
    aqryAssignedConnectionsConnectionKey: TAutoIncField;                        //doc11132023TMH
    aspAddConnection: TADOStoredProc;
    cbRoleName: TComboBox;
    Label4: TLabel;
    aqryRoleNameCB: TADOQuery;
    dbgApplicationRoles: TDBGrid;                                               //doc11132023TMH
    Label5: TLabel;
    lblAppKeyData: TLabel;                                                      //doc12192023TMH
    btnClear: TButton;
    aqryRoleUsersName: TStringField;
    aqryRoleUsersUserID: TIntegerField;
    aqryRoleUsersUMStatus: TStringField;
    aqryARCFormsApplicationRoleComponentsKey: TIntegerField;
    aqryARCReportsApplicationRoleComponentsKey: TIntegerField;
    Timer1: TTimer;                                                          //doc12192023TMH
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure dbgARCFormsDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure dbgEnter(Sender: TObject);
    procedure sbCloseClick(Sender: TObject);
    procedure dbgARCFormsColEnter(Sender: TObject);
    procedure dbgARCFormsColExit(Sender: TObject);
    procedure dbgARCFormsCellClick(Column: TColumn);
    procedure aqryApplicationRolesNewRecord(DataSet: TDataSet);
    procedure dbgApplicationRolesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure dbgARCKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure aqryARCNewRecord(DataSet: TDataSet);
    procedure aqryRoleUsersNewRecord(DataSet: TDataSet);
    procedure dbgRoleUsersKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure aqryARCFormsFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure aqryARCReportsFilterRecord(DataSet: TDataSet;
      var Accept: Boolean);
    procedure aqryApplicationRolesBeforePost(DataSet: TDataSet);
    procedure aqryPostError(DataSet: TDataSet;
      E: EDatabaseError; var Action: TDataAction);
    procedure GetAppObjects();

    procedure FormDestroy(Sender: TObject);
    procedure cbApplicationsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure dbgTitleClick(Column: TColumn);
    procedure aqryApplicationRolesAfterPost(DataSet: TDataSet);
    procedure dbnvNavClick(Sender: TObject; Button: TNavigateBtn);
    procedure aqryARCFormsBeforePost(DataSet: TDataSet);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure aqryARCReportsBeforePost(DataSet: TDataSet);
    procedure aqryRoleUsersBeforePost(DataSet: TDataSet);
    procedure aqryApplicationRolesBeforeDelete(DataSet: TDataSet);
    procedure dbgApplicationRolesDrawColumnCell(Sender: TObject;
      const Rect: TRect; DataCol: Integer; Column: TColumn;
      State: TGridDrawState);
    procedure dbgRoleUsersDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure pcAssignedToRoleChange(Sender: TObject);
    procedure cbShowInactiveClick(Sender: TObject);
    procedure aqryRoleUsersFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure dbnvNavBeforeAction(Sender: TObject; Button: TNavigateBtn);
    procedure cbApplicationsCloseUp(Sender: TObject);
    procedure pcAssignedToRoleChanging(Sender: TObject;
      var AllowChange: Boolean);
    procedure dbgApplicationRolesExit(Sender: TObject);
    procedure dbgARCReportsDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure aqryARCFormsBeforeOpen(DataSet: TDataSet);
    procedure aqryARCReportsBeforeOpen(DataSet: TDataSet);
    procedure aqryRoleUsersBeforeOpen(DataSet: TDataSet);
    procedure aqryApplicationRolesBeforeOpen(DataSet: TDataSet);
    procedure cbKeyUserCloseUp(Sender: TObject);
    procedure dbgApplicationRolesKeyPress(Sender: TObject; var Key: Char);
    procedure aqryARCFormsBeforeDelete(DataSet: TDataSet);
    procedure aqryARCReportsBeforeDelete(DataSet: TDataSet);
    procedure aqryRoleUsersBeforeDelete(DataSet: TDataSet);
    procedure aqryApplicationRolesBeforeEdit(DataSet: TDataSet);
    procedure cbFormsCloseUp(Sender: TObject);
    procedure cbReportsCloseUp(Sender: TObject);
    procedure ebUserNameKeyDown(Sender: TObject; var Key: Word;                 //doc11132023TMH
      Shift: TShiftState);
    procedure ebUserNameExit(Sender: TObject);                                  //doc11132023TMH
    procedure aqryRoleUsersAfterPost(DataSet: TDataSet);                        //doc11132023TMH
    procedure cbRoleNameCloseUp(Sender: TObject);                               //doc12192023TMH
    procedure btnClearClick(Sender: TObject);                                   //doc12192023TMH
    procedure dsRoleUsersDataChange(Sender: TObject; Field: TField);            //doc12192023TMH
    procedure dsARCReportsDataChange(Sender: TObject; Field: TField);           //doc12192023TMH
    procedure dsARCFormsDataChange(Sender: TObject; Field: TField);             //doc12192023TMH
    procedure dsApplicationRolesDataChange(Sender: TObject; Field: TField);     //doc12192023TMH
    procedure Timer1Timer(Sender: TObject);                                     //doc12192023TMH
    procedure dbgApplicationRolesMouseWheel(Sender: TObject; Shift: TShiftState;//doc12192023TMH
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure dbgApplicationRolesCellClick(Column: TColumn);                    //doc12192023TMH
    procedure aqryFormCompLookupBeforeOpen(DataSet: TDataSet);
    procedure aqryReportCompLookupBeforeOpen(DataSet: TDataSet);
    procedure aqryUserLookupForRoleUsersBeforeOpen(DataSet: TDataSet);
    procedure aqryUserLookupBeforeOpen(DataSet: TDataSet);
    procedure aqryApplicationRolesAfterDelete(DataSet: TDataSet);               //doc12192023TMH
    procedure aqryApplicationRolesAfterCancel(DataSet: TDataSet);               //doc12192023TMH
  private
    var oldKeyUserID :integer;
    oldKeyUserName :string;
    KeyUserWasEdited :boolean;
    DefaultButtons : TNavButtonSet;                                             //doc09192023TMH
    GridOriginalOptions : TDBGridOptions;
    Counter : integer;                                                          //doc12192023TMH
    const waitTime : integer = 2;                                               //doc12192023TMH
    procedure LoadAndResetData();                                               //doc12192023TMH
    procedure RequeryFormsReportsUsers();
    procedure CheckBlanksAndValidateComponents(DataSet: TDataSet; Grid: TDBGrid; CompType: string);
    procedure GetKeyUsersAndChange(DataSet: TDataSet);
    procedure ReplaceKeyUser();
    procedure LoadApplicationRolesGrid;
    procedure LoadKeyUserComboBox;                                              //doc09192023TMH
    procedure LoadActiveFlagPickList;                                           //doc09192023TMH
    procedure CheckCanAddOrModifyInactiveRoles;                                 //doc09192023TMH
    Procedure LoadFormsComboBox;                                                //11012023WP
    Procedure LoadReportsComboBox;                                              //11012023WP
    procedure LoadRoleNameComboBox;                                             //doc12192023TMH
    procedure InsertConnection(ConnectionKey: Integer);                         //doc11132023TMH
    procedure AddConnectionAccessIfNeeded;                                      //doc11132023TMH
    procedure ResetFilterBoxes;                                                 //doc12192023TMH
    function GetUserIDFromUserNameEditBox() :string;                            //doc11132023TMH
    procedure SetNavBarAccess(Grid: TDBGrid);                                   //doc12192023TMH
  public

  end;

type TApp = class
  private
    fName: string;
    fKey: integer;
    fMethod: char;
  public
    property Name : string read fName;
    property Key : integer read fKey;
    property Method : char read fMethod;
    constructor Create(const name : string; const key : integer; const method : char) ;
  end;

type TString = class
  private
    fID: string;
  public
    property ID : string read fID;
    constructor Create(const id : string ) ;
  end;

var
  frmApplicationRolesModifyAccess: TfrmApplicationRolesModifyAccess;
  appObj : TApp;

implementation

{$R *.dfm}

uses untDataMod, untAppFunctions, untSecurity, untCommon, untLookupFunctionsInterface;

constructor TApp.Create(const name : string; const key : integer; const method : char) ;
begin
  fName := name;
  fKey := key;
  fMethod := method;
end;

constructor TString.Create(const id : string) ;
begin
  fID := id;
end;

procedure TfrmApplicationRolesModifyAccess.GetKeyUsersAndChange(DataSet: TDataSet);
var
  MsgForm: TForm;
  newName, custMsg: string;
begin
  newName := DataSet.FieldByName('KeyUserName').Value;
  custMsg := 'Would you like to change the key user for all roles within ' +
              cbApplications.Text + ', ' + sLineBreak + 'from ' + oldKeyUserName + ' to ' + newName + '?';
  MsgForm := CreateMessageDialog(custMsg , mtCustom, [mbYes, mbNo]);
  try
    MsgForm.Position := poScreenCenter;
    MsgForm.ShowModal;

    if MsgForm.ModalResult = mrYes then
      begin
        ReplaceKeyUser;
        MessageDlg('Success!', mtConfirmation, [mbOK], 0);
      end;
  finally
    MsgForm.Free;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.ReplaceKeyUser();
begin
  with TADOQuery.Create(nil) do
  try
    Connection := dmApplicationMaint.dbAppSecu;
    SQL.Add('Update ApplicationRoles Set KeyUserID = ' + aqryApplicationRoles.FieldByName('KeyUserID').AsString);
    SQL.Add('Where KeyUserID = ' + IntToStr(oldKeyUserID)
              + ' and ApplicationKey = ' + IntToStr(appObj.fKey));
    ExecSQL;
  finally
    Close;
    Free;
    aqryApplicationRoles.Requery([]);
  end;
end;

procedure TfrmApplicationRolesModifyAccess.aqryApplicationRolesAfterCancel(
  DataSet: TDataSet);
begin
RequeryFormsReportsUsers; //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.aqryApplicationRolesAfterDelete(
  DataSet: TDataSet);
begin
  RequeryFormsReportsUsers;          //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.aqryApplicationRolesAfterPost(
  DataSet: TDataSet);
begin
  if KeyUserWasEdited and not UserAccess.UserHasAccess('CanAddOrModifyOnlyInactiveRoles') then  //doc09192023TMH
    begin
      GetKeyUsersAndChange(DataSet);
    end;
  RequeryFormsReportsUsers;   //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.aqryApplicationRolesBeforeDelete(
  DataSet: TDataSet);
var btnSel: integer;
begin
  CheckCanAddOrModifyInactiveRoles;   //doc09192023TMH
  btnSel := MessageDlg('Warning! Deleting this role will also delete '
            +'Role Components and Role Users linked to this role.' + sLineBreak
            +'Users will lose access to these components if not setup in another role with them.',mtWarning, mbOKCancel, 0);
  if btnSel = mrOK then
    with aqryDeleteAppRole do
      begin
        Close;
        Parameters.ParamByName('ApplicationRolesKey').Value := DataSet.FieldByName('ApplicationRolesKey').AsInteger;
        ExecSQL;
      end
  else
    Abort;
end;

procedure TfrmApplicationRolesModifyAccess.aqryApplicationRolesBeforeEdit(
  DataSet: TDataSet);
begin
  CheckCanAddOrModifyInactiveRoles;      //doc09192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.aqryApplicationRolesBeforePost(
  DataSet: TDataSet);
var result : boolean;
begin
  CheckCanAddOrModifyInactiveRoles;    //doc09192023TMH

  //This saves info and uses it in the after post event for the feature that allows changing all roles with the old key user to the new key user.
  if (aqryApplicationRoles.State in [dsEdit])
      and (DataSet.FieldByName('KeyUserID').OldValue <> DataSet.FieldByName('KeyUserID').NewValue) then
    begin
      KeyUserWasEdited := true;
      oldKeyUserID := DataSet.FieldByName('KeyUserID').OldValue;
      oldKeyUserName := aqryUserLookup.Lookup('UserID', oldKeyUserID, 'Name');
    end
  else
    KeyUserWasEdited := false;
  //Blank role name
  if string.IsNullOrWhiteSpace(Dataset.FieldByName('Description').AsString) then
    begin
      MessageDlg('Description can not be blank.',mtError, [mbOK], 0);
      dbgApplicationRoles.SelectedIndex := GetColumnIndex(dbgApplicationRoles,'Description');
      Abort;
    end;
  //Blank key user
  if string.IsNullOrWhiteSpace(Dataset.FieldByName('KeyUserID').AsString) then
    begin
      MessageDlg('Key User ID can not be blank.',mtError, [mbOK], 0);
      dbgApplicationRoles.SelectedIndex := GetColumnIndex(dbgApplicationRoles,'KeyUserID');
      Abort;
    end;
  //Inactive key user
  if Dataset.FieldByName('Status').Value = 'I' then
    begin
      MessageDlg(aqryApplicationRolesName.Value + ' is not an active user.',mtError, [mbOK], 0);
      dbgApplicationRoles.SelectedIndex := GetColumnIndex(dbgApplicationRoles,'KeyUserID');
      Abort;
    end;

  //Can only set role key user if that user is key user over at least 1 form or 1 report in the application selected.
  result := true;
  with aqryFormCompLookup do
    begin
      Close;
      Open;
      if RecordCount = 0 then
        result := false;
    end;
    if result = false then
      with aqryReportCompLookup do
      begin
        Close;
        Open;
        if RecordCount = 0 then
          result := false
        else result := true;
      end;
    if result = false then
    begin
      MessageDlg('Can not set ' + aqryApplicationRolesName.Value + ' as the role key user. ' + slineBreak + slineBreak
                + aqryApplicationRolesName.Value + ' is not a key user for ANY form or report components within application ' + appObj.Name + '.',mtError, [mbOK], 0);
      dbgApplicationRoles.SelectedIndex := GetColumnIndex(dbgApplicationRoles,'KeyUserID');
      Abort;
    end;
end;

procedure TfrmApplicationRolesModifyAccess.aqryApplicationRolesNewRecord(
  DataSet: TDataSet);
begin
  Dataset.FieldByName('ApplicationKey').Value := AppObj.Key;
//  Dataset.FieldByName('ActiveFlag').Value := 'A';                             //doc09192023TMH
  Dataset.FieldByName('ActiveFlag').Value := 'I';                               //doc09192023TMH
  DataSet.FieldByName('Description').FocusControl;

  aqryARCForms.Close;           //doc12192023TMH
  aqryARCReports.Close;         //doc12192023TMH
  aqryRoleUsers.Close;          //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.aqryPostError(
  DataSet: TDataSet; E: EDatabaseError; var Action: TDataAction);
var FieldName :string;
begin
  FieldName := CheckForErrors('AppSecur', DataSet, E.Message);
  Action := daAbort;
  if FieldName = '' then
    DataSet.Fields[0].FocusControl;
end;

procedure TfrmApplicationRolesModifyAccess.aqryARCFormsFilterRecord(
  DataSet: TDataSet; var Accept: Boolean);
begin
//  Accept := DataSet.FieldByName('ComponentType').AsString = 'F'; //doc11202023TMH //doc12062023TMH //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.aqryARCReportsFilterRecord(
  DataSet: TDataSet; var Accept: Boolean);
begin
//  Accept := DataSet.FieldByName('ComponentType').AsString = 'D'; //doc11202023TMH //doc12062023TMH //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.aqryARCNewRecord(
  DataSet: TDataSet);
begin
  Dataset.FieldByName('ApplicationRolesKey').Value := dsApplicationRoles.DataSet.FieldByName('ApplicationRolesKey').AsInteger;
  Dataset.FieldByName('ActiveFlag').Value := 'A';
  Dataset.FieldByName('ReadAccess').Value := true;
  Dataset.FieldByName('InsertAccess').Value := true;
  Dataset.FieldByName('UpdateAccess').Value := true;
  Dataset.FieldByName('DeleteAccess').Value := true;
  Dataset.FieldByName('ApplicationComponentKey').FocusControl;
end;

procedure TfrmApplicationRolesModifyAccess.aqryApplicationRolesBeforeOpen(
  DataSet: TDataSet);
begin
  with aqryApplicationRoles do
  begin
    Parameters.ParamByName('AppKey').Value := appObj.Key;
    Parameters.ParamByName('KeyUserID').Value := (cbKeyUser.Items.Objects[cbKeyUser.ItemIndex] as TString).ID;
    Parameters.ParamByName('FormKey').Value := (cbForms.Items.Objects[cbForms.ItemIndex] as TString).ID;        //doc11202023TMH
    Parameters.ParamByName('ReportKey').Value := (cbReports.Items.Objects[cbReports.ItemIndex] as TString).ID;  //doc11202023TMH
    Parameters.ParamByName('UserId').Value := GetUserIDFromUserNameEditBox();                                   //doc11202023TMH
    Parameters.ParamByName('RoleName').Value := Trim(cbRoleName.Text);                                          //doc12192023TMH
  end;
end;

procedure TfrmApplicationRolesModifyAccess.aqryARCFormsBeforeOpen(
  DataSet: TDataSet);
begin
  aqryARCForms.Parameters.ParamByName('ApplicationRolesKey').Value := dsApplicationRoles.DataSet.FieldByName('ApplicationRolesKey').AsInteger;
end;

procedure TfrmApplicationRolesModifyAccess.aqryARCReportsBeforeOpen(
  DataSet: TDataSet);
begin
  aqryARCReports.Parameters.ParamByName('ApplicationRolesKey').Value := dsApplicationRoles.DataSet.FieldByName('ApplicationRolesKey').AsInteger;
end;

procedure TfrmApplicationRolesModifyAccess.aqryRoleUsersBeforeOpen(
  DataSet: TDataSet);
begin
  aqryRoleUsers.Parameters.ParamByName('ApplicationRolesKey').Value := dsApplicationRoles.DataSet.FieldByName('ApplicationRolesKey').AsInteger;
end;

procedure TfrmApplicationRolesModifyAccess.aqryFormCompLookupBeforeOpen(
  DataSet: TDataSet);
begin
  aqryFormCompLookup.Parameters.ParamByName('ApplicationKey').Value := appObj.Key;
  aqryFormCompLookup.Parameters.ParamByName('KeyUserID').Value := dsApplicationRoles.DataSet.FieldByName('KeyUserID').AsInteger;
  aqryFormCompLookup.Parameters.ParamByName('ApplicationRolesKey').Value := dsApplicationRoles.DataSet.FieldByName('ApplicationRolesKey').AsInteger;
end;

procedure TfrmApplicationRolesModifyAccess.aqryReportCompLookupBeforeOpen(
  DataSet: TDataSet);
begin
  aqryReportCompLookUp.Parameters.ParamByName('ApplicationKey').Value := appObj.Key;
  aqryReportCompLookUp.Parameters.ParamByName('KeyUserID').Value := dsApplicationRoles.DataSet.FieldByName('KeyUserID').AsInteger;
  aqryReportCompLookUp.Parameters.ParamByName('ApplicationRolesKey').Value := dsApplicationRoles.DataSet.FieldByName('ApplicationRolesKey').AsInteger;
end;

procedure TfrmApplicationRolesModifyAccess.aqryUserLookupBeforeOpen(
  DataSet: TDataSet);
begin
  aqryUserLookup.Parameters.ParamByName('ApplicationKey').Value := appObj.Key;
end;

procedure TfrmApplicationRolesModifyAccess.aqryUserLookupForRoleUsersBeforeOpen(
  DataSet: TDataSet);
begin
  aqryUserLookupForRoleUsers.Parameters.ParamByName('ApplicationRolesKey').Value := dsApplicationRoles.DataSet.FieldByName('ApplicationRolesKey').AsInteger;
end;

procedure TfrmApplicationRolesModifyAccess.aqryRoleUsersAfterPost(              //doc11132023TMH
  DataSet: TDataSet);
begin
  AddConnectionAccessIfNeeded;
end;

procedure TfrmApplicationRolesModifyAccess.AddConnectionAccessIfNeeded;         //doc11132023TMH
var
  msg: string;
  connKey: string;
  connName: string;
begin
  msg := 'User ''%s'' does not have connection access.' + slinebreak + slinebreak + 'Would you like to set ''%s %s'' as an assigned connection?';

  with aqryAssignedConnections do
  begin
    Close;
    Parameters.ParamByName('ApplicationKey').Value := appObj.fKey;
    Parameters.ParamByName('UserID').Value := aqryRoleUsersUserID.AsString;
    Open;
  end;

  if aqryAssignedConnections.RecordCount < 1 then
  begin
    with aqryFindTopProdConnectionForApp do
    begin
      Close;
      Parameters.ParamByName('ApplicationKey').Value := appObj.fKey;
      Open;

      connKey := aqryFindTopProdConnectionForAppConnectionKey.AsString;
      connName := aqryFindTopProdConnectionForAppConnectionName.AsString;
      msg := Format(msg, [aqryRoleUsersName.AsString, connKey, connName]);

      if MessageDlg(msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        InsertConnection(connKey.ToInteger());
      end;
      Close;
    end;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.InsertConnection(ConnectionKey: Integer);  //doc11132023TMH
begin
  with aspAddConnection do
  begin
    Close;
    Parameters.ParamByName('@AppKey').Value	:= appObj.fKey;
    Parameters.ParamByName('@ConnKey').Value := ConnectionKey;
    Parameters.ParamByName('@UserID').Value	:= aqryRoleUsersUserID.AsInteger;
    Parameters.ParamByName('@ActiveFlag').Value	:= 'A';
    ExecProc;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.aqryRoleUsersBeforeDelete(
  DataSet: TDataSet);
begin
  CheckCanAddOrModifyInactiveRoles;         //doc09192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.aqryRoleUsersBeforePost(
  DataSet: TDataSet);
begin
  CheckCanAddOrModifyInactiveRoles;      //doc09192023TMH

  if string.IsNullOrWhiteSpace(Dataset.FieldByName('UserID').AsString) then
    begin
      MessageDlg('User ID can not be blank.',mtError, [mbOK], 0);
      dbgRoleUsers.SelectedIndex := GetColumnIndex(dbgRoleUsers,'UserID');
      Abort;
    end;
  if Dataset.FieldByName('Status').AsString = 'I' then
    begin
      MessageDlg('Can not insert user ' + (Dataset.FieldByName('Name').AsString
                + ', as they are inactive in User Master.'),mtError, [mbOK], 0);
      dbgRoleUsers.SelectedIndex := GetColumnIndex(dbgRoleUsers,'UserID');
      Abort;
    end;
end;

procedure TfrmApplicationRolesModifyAccess.aqryRoleUsersNewRecord(
  DataSet: TDataSet);
begin
  Dataset.FieldByName('ApplicationRolesKey').Value := dsApplicationRoles.DataSet.FieldByName('ApplicationRolesKey').AsInteger;
  Dataset.FieldByName('ActiveFlag').Value := 'A';
  Dataset.FieldByName('UserID').FocusControl;
end;

procedure TfrmApplicationRolesModifyAccess.btnClearClick(Sender: TObject);      //doc12192023TMH
begin
  cbApplications.ItemIndex := 0;
  LoadAndResetData;
end;

procedure TfrmApplicationRolesModifyAccess.LoadAndResetData();                  //doc12192023TMH
begin
  AppObj := cbApplications.Items.Objects[cbApplications.ItemIndex] as TApp;     //doc12192023TMH
  lblAppKeyData.Caption := AppObj.fKey.ToString;                                //doc12192023TMH
  ResetFilterBoxes;                                                             //doc11202023TMH
  LoadApplicationRolesGrid;
  RequeryFormsReportsUsers;                                                     //doc12192023TMH
  LoadKeyUserComboBox;                                                          //doc09192023TMH
  LoadFormsComboBox;                                                            //11012023WP
  LoadReportsComboBox;                                                          //11012023WP
  LoadRoleNameComboBox;                                                         //doc12192023TMH

  //    ebUserName.Text := '%';                       //11012023WP                //doc11202023TMH
  //    cbKeyUser.Clear;                              //doc09192023TMH            //doc11202023TMH
  //    cbKeyUser.AddItem('%', TString.Create('%'));  //doc09192023TMH            //doc11202023TMH
  //    cbKeyUser.ItemIndex := 0;                     //doc09192023TMH            //doc11202023TMH
end;

procedure TfrmApplicationRolesModifyAccess.cbApplicationsCloseUp(
  Sender: TObject);
begin
  LoadAndResetData;                               //doc12192023TMH put the code that was here in it's own procedure.
  SetNavBarAccess(dbgApplicationRoles);           //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.ResetFilterBoxes;                        //doc11202023TMH
begin
  ebUserName.Text := '%';

  cbKeyUser.Clear;
  cbKeyUser.AddItem('%', TString.Create('%'));
  cbKeyUser.ItemIndex := 0;

  cbForms.Clear;
  cbForms.AddItem('%', TString.Create('%'));
  cbForms.ItemIndex := 0;

  cbReports.Clear;
  cbReports.AddItem('%', TString.Create('%'));
  cbReports.ItemIndex := 0;

  cbRoleName.Clear;                                       //doc12192023TMH
  cbRoleName.AddItem('%', TString.Create('%'));           //doc12192023TMH
  cbRoleName.ItemIndex := 0;                              //doc12192023TMH
end;

function TfrmApplicationRolesModifyAccess.GetUserIDFromUserNameEditBox() :string;  //doc11202023TMH
begin
  if ebUserName.Text = '%' then
    Result := '%'
  else
    begin
      with TADOQuery.Create(nil) do
      try
        Connection := dmApplicationMaint.dbAppSecu;
        SQL.Add('Select UserID From UserMaster Where AppUserName = ''' + ebUserName.Text + '''');
        Open;
        Result := Fields.FieldByName('UserID').AsString;
      finally
        Close;
        Free;
      end;
    end;
end;

procedure TfrmApplicationRolesModifyAccess.LoadApplicationRolesGrid;
begin
//  if cbApplications.ItemIndex	<> -1 then                //doc11172023TMH
  begin
    Screen.Cursor := crHourglass;
    try
      aqryApplicationRoles.Close;
      aqryApplicationRoles.Open;
//      dbgApplicationRoles.SetFocus;                                           //doc12192023TMH
      dbgApplicationRoles.SelectedField := dbgApplicationRoles.Fields[1];
//      RequeryFormsReportsUsers;                                               //doc12192023TMH
      dbnvNav.DataSource := dsApplicationRoles;
    finally
      Screen.Cursor := crArrow;
    end;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.LoadFormsComboBox;                           //11012023WP
begin
//  cbForms.Items.Clear;                                                        //doc11202023TMH
//  cbForms.Items.Add('%');                                                     //doc11202023TMH
  with aqryFormsCB do
  begin
    Close;
    Parameters.ParamByName('ApplicationKey').Value := aqryApplicationRoles.Fields.FieldByName('ApplicationKey').Value;
    Open;
    if RecordCount > 0 then
    while not EOF do
      begin
        cbForms.AddItem(Fields.FieldByName('ComponentName').AsString,
                        TString.Create(Fields.FieldByName('ApplicationComponentKey').AsString));
        Next;
      end;
    Close;
  end;
//  cbForms.ItemIndex := 0;                                                     //doc11202023TMH
end;

procedure TfrmApplicationRolesModifyAccess.LoadKeyUserComboBox;                 //doc09192023TMH
begin
  with aqryKeyUserCB do
  begin
    Close;
    Parameters.ParamByName('appKey').Value := appObj.Key;
    Open;
    while not EOF do
    begin
      cbKeyUser.AddItem(Fields.FieldByName('Name').AsString,
                        TString.Create(Fields.FieldByName('KeyUserID').AsString));
      next;
    end;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.LoadReportsComboBox;                         //11012023WP
begin
//  cbReports.Items.Clear;                                                      //doc11202023TMH
//  cbReports.Items.Add('%');                                                   //doc11202023TMH
  with aqryReportsCB do
  begin
    Close;
    Parameters.ParamByName('ApplicationKey').Value := aqryApplicationRoles.Fields.FieldByName('ApplicationKey').Value;
    Open;
    if RecordCount > 0 then
    while not EOF do
      begin
        cbReports.AddItem(Fields.FieldByName('ComponentName').AsString,
                          TString.Create(Fields.FieldByName('ApplicationComponentKey').AsString));
        Next;
      end;
    Close;
  end;
//  cbReports.ItemIndex := 0;                                                   //doc11202023TMH
end;

procedure TfrmApplicationRolesModifyAccess.LoadRoleNameComboBox;   //doc12192023TMH
begin
  with aqryRoleNameCB do
  begin
    Close;
    Parameters.ParamByName('appKey').Value := appObj.Key;
    Open;
    while not EOF do
    begin
      cbRoleName.AddItem( Fields.FieldByName('Description').AsString, TString.Create('0'));
      next;
    end;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.cbApplicationsDrawItem(
  Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
  with cbApplications do
  begin
    if Index = 0 then
      begin
        Canvas.Font.Color := clGray;
        Canvas.Brush.Color := clWindow;
      end
    else
      begin
        Canvas.Font.Color := clBlack;
        if TApp(Items.Objects[Index]).Method = 'R' then
          Canvas.Brush.Color := clmoneygreen
        else
          Canvas.Brush.Color := clSilver;
      end;
    Canvas.FillRect(Rect);
    Canvas.TextOut(Rect.Left, Rect.Top, Items[Index]);
  end;
end;


procedure TfrmApplicationRolesModifyAccess.cbKeyUserCloseUp(Sender: TObject);  //doc09192023TMH
begin
  if cbApplications.ItemIndex	> 0 then          //doc12192023TMH
  begin
    LoadApplicationRolesGrid;
    RequeryFormsReportsUsers;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.cbFormsCloseUp(Sender: TObject);            //11012023WP
begin
//  if aqryApplicationRoles.Active then                  //doc11202023TMH
//    if aqryApplicationRoles.RecordCount > 0 then       //doc11202023TMH

  if cbApplications.ItemIndex	> 0 then                   //doc12192023TMH
  begin
    LoadApplicationRolesGrid;
    RequeryFormsReportsUsers;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.cbReportsCloseUp(Sender: TObject);      //11012023WP
begin
//  if aqryApplicationRoles.Active then                  //doc11202023TMH
//    if aqryApplicationRoles.RecordCount > 0 then       //doc11202023TMH

  if cbApplications.ItemIndex	> 0 then                   //doc12192023TMH
  begin
    LoadApplicationRolesGrid;
    RequeryFormsReportsUsers;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.cbRoleNameCloseUp(Sender: TObject);       //doc12192023TMH
begin
  if cbApplications.ItemIndex	> 0 then
  begin
    LoadApplicationRolesGrid;
    RequeryFormsReportsUsers;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.cbShowInactiveClick(Sender: TObject);
begin
  dbnvNav.OnClick(dbnvNav, nbCancel);
  if cbShowInactive.Checked then
    begin
      aqryRoleUsers.Filtered := false;
    end
  else
    begin
      aqryRoleUsers.Filtered := true;
    end;
  if not dsApplicationRoles.DataSet.IsEmpty then
    begin
      dbgApplicationRoles.SetFocus;
    end;
  RequeryFormsReportsUsers;        //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.aqryRoleUsersFilterRecord(
  DataSet: TDataSet; var Accept: Boolean);
begin
  Accept := DataSet.FieldByName('ActiveFlag').AsString = 'A';
end;

procedure TfrmApplicationRolesModifyAccess.RequeryFormsReportsUsers();
begin
//  if dbgApplicationRoles.Focused = false then             //doc12192023TMH
//    Exit;                                                //doc12192023TMH
//  if not dsApplicationRoles.DataSet.IsEmpty then
//  begin
  try
    Screen.Cursor := crHourglass;
    case pcAssignedToRole.ActivePageIndex of                                    //doc12192023TMH
      0 : begin
            aqryFormCompLookup.Close;
            aqryFormCompLookup.Open;
            aqryARCForms.Close;
            aqryARCForms.Open;
          end;
      1 : begin
            aqryReportCompLookup.Close;
            aqryReportCompLookup.Open;
            aqryARCReports.Close;
            aqryARCReports.Open;
          end;
      2 : begin
            aqryUserLookupForRoleUsers.Close;
            aqryUserLookupForRoleUsers.Open;
            aqryRoleUsers.Close;
            aqryRoleUsers.Open;
          end;
    end;
  finally
    Screen.Cursor := crArrow;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.aqryARCFormsBeforeDelete(            //doc09192023TMH
  DataSet: TDataSet);
begin
  CheckCanAddOrModifyInactiveRoles;
end;

procedure TfrmApplicationRolesModifyAccess.aqryARCReportsBeforeDelete(          //doc09192023TMH
  DataSet: TDataSet);
begin
  CheckCanAddOrModifyInactiveRoles;
end;

procedure TfrmApplicationRolesModifyAccess.dbgApplicationRolesCellClick(        //doc12192023TMH
  Column: TColumn);
begin
  RequeryFormsReportsUsers;
  timer1.Enabled := false;
end;

procedure TfrmApplicationRolesModifyAccess.dbgEnter(
  Sender: TObject);
begin
  SetNavBarAccess(TDBGrid(Sender));        //doc12192023TMH changed and moved to SetNavBarAccess.

end;

procedure TfrmApplicationRolesModifyAccess.SetNavBarAccess(                     //doc12192023TMH
  Grid: TDBGrid);
begin
  dbnvNav.VisibleButtons := DefaultButtons;
  dbnvNav.DataSource := Grid.DataSource;
  if Grid = dbgApplicationRoles then
    UserAccess.SetNavigatorButtons('CanAddOrModifyRoles', dbnvNav, False)
  else if (Grid = dbgARCForms) or (Grid = dbgARCReports) then
    UserAccess.SetNavigatorButtons('CanAddOrModifyFormsOrReportsInRoles', dbnvNav, False)
  else if Grid = dbgRoleUsers then
    UserAccess.SetNavigatorButtons('CanAddOrModifyUsersInRoles', dbnvNav, False);

//doc12192023TMH begin
//  if (TDBGrid(Sender) = dbgApplicationRoles) then //doc09192023TMH
//    begin
//      dbnvNav.VisibleButtons := DefaultButtons;
//      dbnvNav.DataSource := dsApplicationRoles;
//      UserAccess.SetNavigatorButtons('CanAddOrModifyRoles', dbnvNav, False);
//    end
//  else if not aqryApplicationRoles.IsEmpty then
//    begin
//      dbnvNav.VisibleButtons := DefaultButtons;
//      dbnvNav.DataSource := TDBGrid(Sender).DataSource;
//      if Sender = dbgRoleUsers then
//        begin
//          UserAccess.SetNavigatorButtons('CanAddOrModifyUsersInRoles', dbnvNav, False);
//        end
//      else if (Sender = dbgARCForms) or (Sender = dbgARCReports) then
//        begin
//          UserAccess.SetNavigatorButtons('CanAddOrModifyFormsOrReportsInRoles', dbnvNav, False);
//          if (Sender = dbgARCForms) then
//            dbgARCFormsColEnter(Sender);
//        end;
//    end;
//  if (TDBGrid(Sender) = dbgApplicationRoles) then                   //doc09192023TMH
//    dbnvNav.DataSource := TDBGrid(Sender).DataSource
//  else
//    if not aqryApplicationRoles.IsEmpty then
//    begin
//      dbnvNav.DataSource := TDBGrid(Sender).DataSource;
//      if Sender = dbgARCForms then
//        dbgARCFormsColEnter(Sender);
//    end;
//doc12192023TMH end
end;

procedure TfrmApplicationRolesModifyAccess.Timer1Timer(Sender: TObject);        //doc12192023TMH
begin
  Dec(Counter);
  if (Counter <= 0) then
    begin
      RequeryFormsReportsUsers;
      timer1.Enabled := false;
    end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgApplicationRolesMouseWheel(       //doc12192023TMH
  Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean);
begin
  timer1.Enabled := true;
  Counter := waitTime;
end;

procedure TfrmApplicationRolesModifyAccess.dbgTitleClick(
  Column: TColumn);
  var grid : TDBGrid;
begin
  grid := TDBGrid(Column.Grid);
  if not grid.DataSource.DataSet.IsEmpty then                                   //doc12192023TMH
  begin
    SortGrid(grid, TADOQuery(grid.DataSource.DataSet).Sort, Column.FieldName, '');
  end;

//  if not TDBGrid(Column.Grid).DataSource.DataSet.IsEmpty then                     //doc12192023TMH
//    if Column.Field.FieldKind = fkData then
//      SortGrid(TDBGrid(Column.Grid), TADOQuery(TDBGrid(Column.Grid).DataSource.DataSet).Sort, Column.FieldName, '');

end;

procedure TfrmApplicationRolesModifyAccess.dbnvNavBeforeAction(Sender: TObject;
  Button: TNavigateBtn);
begin
  if Button = nbDelete then
    dbnvNav.ConfirmDelete := not (dbnvNav.DataSource.DataSet = aqryApplicationRoles);
end;

procedure TfrmApplicationRolesModifyAccess.aqryARCFormsBeforePost(
  DataSet: TDataSet);
begin
  CheckCanAddOrModifyInactiveRoles;                                             //doc09192023TMH

  if (aqryARCFormsInsertAccess.Value = False) and (aqryARCFormsDeleteAccess.Value = False)
      and (aqryARCFormsUpdateAccess.Value = False) and (aqryARCFormsReadAccess.Value = False) then
    begin
      MessageDlg('There must be at least one checkbox checked for the access R.U.I.D. checkboxs. '
                  + 'Otherwise, delete the component from this role.',mtError, [mbOK], 0);
      Abort;
    end;

  CheckBlanksAndValidateComponents(DataSet, dbgARCForms, 'Form');
end;

procedure TfrmApplicationRolesModifyAccess.aqryARCReportsBeforePost(
  DataSet: TDataSet);
begin
  CheckCanAddOrModifyInactiveRoles;                                             //doc09192023TMH
  CheckBlanksAndValidateComponents(DataSet, dbgARCReports, 'Report');
end;

procedure TfrmApplicationRolesModifyAccess.CheckBlanksAndValidateComponents(DataSet: TDataSet; Grid: TDBGrid; CompType: string);
begin
  if string.IsNullOrWhiteSpace(Dataset.FieldByName('ApplicationComponentKey').AsString) then
  begin
    MessageDlg('Component Key can not be blank.', mtError, [mbOK], 0);
    Grid.SelectedIndex := GetColumnIndex(Grid, 'ApplicationComponentKey');
    Abort;
  end;
  if string.IsNullOrWhiteSpace(Dataset.FieldByName('ComponentName').AsString) then
  begin
    MessageDlg(CompType + ' Component Key ' + Dataset.FieldByName('ApplicationComponentKey').AsString + ' does not exists for '
                + aqryApplicationRolesName.Value + ' in ' + appObj.Name + '.', mtError, [mbOK], 0);
    Grid.SelectedIndex := GetColumnIndex(Grid, 'ApplicationComponentKey');
    Abort;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.dbnvNavClick(Sender: TObject;
  Button: TNavigateBtn);
begin
  if Button = nbInsert then
    dbnvNav.DataSource.DataSet.Append;
end;

procedure TfrmApplicationRolesModifyAccess.dsApplicationRolesDataChange(                //doc12192023TMH
  Sender: TObject; Field: TField);
begin
  aqryApplicationRoles.Properties['Unique Table'].Value := 'ApplicationRoles';
end;

procedure TfrmApplicationRolesModifyAccess.dsARCFormsDataChange(Sender: TObject;        //doc12192023TMH
  Field: TField);
begin
  aqryARCForms.Properties['Unique Table'].Value := 'ApplicationRoleComponents';
end;

procedure TfrmApplicationRolesModifyAccess.dsARCReportsDataChange(                      //doc12192023TMH
  Sender: TObject; Field: TField);
begin
  aqryARCReports.Properties['Unique Table'].Value := 'ApplicationRoleComponents';
end;

procedure TfrmApplicationRolesModifyAccess.dsRoleUsersDataChange(                       //doc12192023TMH
  Sender: TObject; Field: TField);
begin
  aqryRoleUsers.Properties['Unique Table'].Value := 'ApplicationRoleUsers';
end;

procedure TfrmApplicationRolesModifyAccess.FormCreate(Sender: TObject);
begin
//  UserAccess.SetNavigatorButtons(Self.Caption, dbnvNav, False);               //doc09192023TMH
  UserAccess.LogOn(Self);
  GetAppObjects();
  GridOriginalOptions := dbgARCForms.Options;
  pcAssignedToRole.ActivePageIndex := 0;
  DefaultButtons := dbnvNav.VisibleButtons;
  LoadActiveFlagPickList;                                                       //doc09192023TMH
  ResetFilterBoxes;                                                             //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.GetAppObjects();
var
  akey: integer;
  aname: string;
  amethod: char;
begin
  cbApplications.Items.AddObject('Select an application here first', Tapp.Create('', 0, ' ')); //doc12192023TMH
  aqryApplicationsCB.Close;
  aqryApplicationsCB.Open;
  with aqryApplicationsCB do
  begin
    while not EOF do
      begin
        aname := Trim(Fields[0].AsString);
        akey := Fields[1].AsInteger;
        amethod := Fields[2].AsString[1];
        cbApplications.Items.AddObject( aname, TApp.Create(aname, akey, amethod)) ;
        Next;
      end;
  end;
  cbApplications.ItemIndex := 0;   //doc12192023TMH
end;

procedure TfrmApplicationRolesModifyAccess.CheckCanAddOrModifyInactiveRoles;    //doc09192023TMH
begin
  if (aqryApplicationRoles.FieldByName('ActiveFlag').Value = 'A')
      and UserAccess.UserHasAccess('CanAddOrModifyOnlyInactiveRoles') then
    begin
      MessageDlg('Can only add or modify inactive roles.',mtError,[mbOK],0);
      Abort;
    end;

  //if user has this component then they can not change the active flag.
  aqryApplicationRoles.FieldByName('ActiveFlag').ReadOnly := UserAccess.UserHasAccess('CanAddOrModifyOnlyInactiveRoles')
end;

procedure TfrmApplicationRolesModifyAccess.pcAssignedToRoleChange(
  Sender: TObject);
begin
  RequeryFormsReportsUsers;                     //doc12192023TMH
  case pcAssignedToRole.ActivePageIndex of                                      //doc09192023TMH
    0 : begin
          cbShowInactive.Visible := false;
          dbgARCForms.OnEnter(dbgARCForms);
        end;
    1 : begin
          cbShowInactive.Visible := false;
          dbgARCReports.OnEnter(dbgARCReports);
        end;
    2 : begin
          cbShowInactive.Visible := true;
          dbgRoleUsers.OnEnter(dbgRoleUsers);
        end;
  end;
//  if pcAssignedToRole.ActivePageIndex = 2 then                                //doc09192023TMH
//    cbShowInactive.Visible := true
//  else
//    cbShowInactive.Visible := false;
end;

procedure TfrmApplicationRolesModifyAccess.pcAssignedToRoleChanging(
  Sender: TObject; var AllowChange: Boolean);
begin
  if (aqryApplicationRoles.State in [dsInsert, dsEdit])
      or (aqryARCForms.State in [dsInsert, dsEdit])
      or (aqryARCReports.State in [dsInsert, dsEdit])
      or (aqryRoleUsers.State in [dsInsert, dsEdit]) then
    begin
      MessageDlg('Please Post or Cancel before changing tabs.',mtWarning,[mbOK],0);
      AllowChange := false;
    end
  else
    pcAssignedToRole.SetFocus;
end;

procedure TfrmApplicationRolesModifyAccess.dbgApplicationRolesExit(
  Sender: TObject);
begin
  if TDBGrid(Sender).DataSource.State In [dsEdit, dsInsert] then
    begin
      MessageDlg('Please Post or Cancel before leaving grid.',mtWarning,[mbOK],0);
      TDBGrid(Sender).SetFocus;
    end;
end;

procedure TfrmApplicationRolesModifyAccess.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if (aqryApplicationRoles.State In [dsInsert, dsEdit])
      or (aqryARCForms.State In [dsInsert, dsEdit])
      or (aqryARCReports.State In [dsInsert, dsEdit])
      or (aqryRoleUsers.State In [dsInsert, dsEdit]) then
    begin
      Action := caNone;
      MessageDlg('Please Post or Cancel before closing.',mtWarning,[mbOK],0);
    end
  else
    begin
      UserAccess.LogOff;
      Action := caFree;
    end;
end;

procedure TfrmApplicationRolesModifyAccess.FormDestroy(Sender: TObject);
var i:integer;
begin
  for I := 0 to cbApplications.Items.Count -1 do
    cbApplications.Items.Objects[i].Free;
  aqryUserLookup.Close;
  aqryFormCompLookup.Close;
  aqryReportCompLookup.Close;
end;

procedure TfrmApplicationRolesModifyAccess.ebUserNameExit(Sender: TObject);         //11012023WP
begin
//  if aqryApplicationRoles.Active then                                         //doc12192023TMH
//  if aqryApplicationRoles.RecordCount > 0 then

  if ebUserName.Text = '' then
    ebUserName.Text := '%';
  if cbApplications.ItemIndex	> 0 then                                          //doc12192023TMH
  begin
    LoadApplicationRolesGrid;                                                   //doc12192023TMH
    RequeryFormsReportsUsers;                                                   //doc12192023TMH
  end;
end;

procedure TfrmApplicationRolesModifyAccess.LoadActiveFlagPickList;              //doc09192023TMH
var idx: Integer;
begin
  idx := GetColumnIndex(dbgApplicationRoles, 'ActiveFlag');
  with TADOQuery.Create(nil) do
  try
    Connection := dmApplicationMaint.dbAppSecu;
    SQL.Text := 'Select Code, Description From CodesDetail With (NoLock) Where TableCodesName = ''ActiveFlag''';
    Open;
    while not EOF do
      begin
        dbgApplicationRoles.Columns[idx].PickList.Add(FieldByName('Code').AsString + ' - ' + FieldByName('Description').AsString);
        Next;
      end;
    Close;
  finally
    free;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgARCFormsCellClick(Column: TColumn);
begin
  if dsARCForms.State in [dsEdit, dsInsert] then
    if (Column.Field.DataType=ftBoolean) then
      begin
        Column.Field.Value := not Column.Field.AsBoolean;
        if (Column.FieldName = 'ReadAccess') and (aqryARCFormsReadAccess.Value = false) then
          begin
            aqryARCFormsInsertAccess.Value := false;
            aqryARCFormsUpdateAccess.Value := false;
            aqryARCFormsDeleteAccess.Value := false;
          end
        else if (aqryARCFormsInsertAccess.Value = true) or (aqryARCFormsDeleteAccess.Value = true) or (aqryARCFormsUpdateAccess.Value = true) then
          begin
            aqryARCFormsReadAccess.Value := true;
          end;
      end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgARCFormsColEnter(Sender: TObject);
begin
  if dbgARCForms.SelectedField.DataType = ftBoolean then
    begin
      GridOriginalOptions := dbgARCForms.Options;
      dbgARCForms.Options := dbgARCForms.Options - [dgEditing];
    end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgARCFormsColExit(Sender: TObject);
begin
  if dbgARCForms.SelectedField.DataType = ftBoolean then
    dbgARCForms.Options := GridOriginalOptions;
end;

procedure TfrmApplicationRolesModifyAccess.dbgApplicationRolesDrawColumnCell(
  Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
begin
  if (DataCol = GetColumnIndex(dbgApplicationRoles, 'KeyUserID')) or
     (DataCol = GetColumnIndex(dbgApplicationRoles, 'Name'))  then
    if aqryApplicationRoles.FieldByName('Status').AsString = 'I' then
      dbgApplicationRoles.Canvas.Brush.Color := $008080FF;
  dbgApplicationRoles.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TfrmApplicationRolesModifyAccess.dbgARCFormsDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
const
   CtrlState: array[Boolean] of integer = (DFCS_BUTTONCHECK, DFCS_BUTTONCHECK or DFCS_CHECKED) ;
var CheckBoxRectangle : TRect;
begin
  if aqryApplicationRoles.FieldByName('ApplicationRolesKey').Value = aqryARCForms.FieldByName('ApplicationRolesKey').Value then //doc12192023TMH prevents a drawing-to-early bug.
  begin
    if (DataCol = GetColumnIndex(dbgARCForms, 'ApplicationComponentKey')) or
       (DataCol = GetColumnIndex(dbgARCForms, 'ComponentName')) then
      if aqryARCForms.FieldByName('KeyUserID').Value <> null then
        if aqryApplicationRoles.FieldByName('KeyUserID').Value <> aqryARCForms.FieldByName('KeyUserID').Value	then
          dbgARCForms.Canvas.Brush.Color := $0080FFFF;
    dbgARCForms.DefaultDrawColumnCell(Rect, DataCol, Column, State);
    if (Column.Field.DataType = ftBoolean) then
    begin
      TDBGrid(Sender).Canvas.Brush.Color := clWindow;
      TDBGrid(Sender).Canvas.FillRect(Rect);
      CheckBoxRectangle.Left := Rect.Left + 2;
      CheckBoxRectangle.Right := Rect.Right - 2;
      CheckBoxRectangle.Top := Rect.Top + 2;
      CheckBoxRectangle.Bottom := Rect.Bottom - 2;
      if (VarIsNull(Column.Field.Value)) then
        DrawFrameControl(TDBGrid(Sender).Canvas.Handle,CheckBoxRectangle, DFC_BUTTON, DFCS_BUTTONCHECK or DFCS_INACTIVE)
      else
        DrawFrameControl(TDBGrid(Sender).Canvas.Handle,CheckBoxRectangle, DFC_BUTTON, CtrlState[Column.Field.AsBoolean]);
    end;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgARCKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  Code : TStringList;
  compType: char;
begin
  if (Key = VK_Return) and (TDBGrid(Sender).DataSource.DataSet.State In [dsEdit, dsInsert]) then
    begin
      with TDBGrid(Sender) do
        if Columns[SelectedIndex].Field.FieldName = 'ApplicationComponentKey' then
          begin
            if TDBGrid(Sender) = dbgARCForms then
              compType := 'F'
            else
              compType := 'D';
              Code := LookupApplicationComponent(IntToStr(appObj.Key), compType, aqryApplicationRolesKeyUserID.AsString);
            if (Code.Values['ApplicationComponentKey'] <> '') then
              begin
                DataSource.DataSet.FieldByName('ApplicationComponentKey').Value := Code.Values['ApplicationComponentKey'];
                DataSource.DataSet.FieldByName('ComponentName').Value := Code.Values['ComponentName'];
              end;
            SelectedIndex := GetColumnIndex(TDBGrid(Sender),'ComponentName');
          end
    end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgARCReportsDrawColumnCell(
  Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
begin
  if aqryApplicationRoles.FieldByName('ApplicationRolesKey').Value = aqryARCReports.FieldByName('ApplicationRolesKey').Value then //doc12192023TMH prevents a drawing-to-early bug.
  begin
    if (DataCol = GetColumnIndex(dbgARCReports, 'ApplicationComponentKey')) or
      (DataCol = GetColumnIndex(dbgARCReports, 'ComponentName')) then
      if aqryARCReports.FieldByName('KeyUserID').Value <> null then
        if aqryApplicationRoles.FieldByName('KeyUserID').Value <> aqryARCReports.FieldByName('KeyUserID').Value	then
          dbgARCReports.Canvas.Brush.Color := $0080FFFF;
    dbgARCReports.DefaultDrawColumnCell(Rect, DataCol, Column, State);
  end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgRoleUsersDrawColumnCell(
  Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
begin
  if aqryApplicationRoles.FieldByName('ApplicationRolesKey').Value = aqryRoleUsers.FieldByName('ApplicationRolesKey').Value then //doc12192023TMH prevents a drawing-to-early bug.
  begin
    if aqryRoleUsers.FieldByName('ActiveFlag').AsString = 'I' then
      dbgRoleUsers.Canvas.Brush.Color := $008080FF;
    dbgRoleUsers.DefaultDrawColumnCell(Rect, DataCol, Column, State);
  end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgRoleUsersKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var Code : TStringList;
begin
  if Key = VK_Return then
    if aqryRoleUsers.State In [dsEdit, dsInsert] then
      with dbgRoleUsers do
        if Columns[SelectedIndex].Field.FieldName = 'UserID' then
          begin
            Code := LookUpUser;
            if (Code.Values['UserID'] <> '') then
              DataSource.DataSet.FieldByName('UserID').Value := Code.Values['UserID'];
            SelectedIndex := GetColumnIndex(dbgRoleUsers,'Name');
          end
end;

procedure TfrmApplicationRolesModifyAccess.FormKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var Msg : TMsg;
begin
  if ((Key = VK_ESCAPE) or (ssCtrl in Shift)) and
     (not (Key in [Ord('C'), Ord('c'), Ord('V'), Ord('v'), Ord('A'), Ord('a'), Ord('X'), Ord('x')])) then
    begin
      NavigatorClick(dbnvNav,Key);
      if PeekMessage(Msg, Handle, WM_CHAR, WM_CHAR, 1) and (Msg.Message = WM_QUIT) then
         PostQuitMessage(Msg.WParam);
    end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgApplicationRolesKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
var Code : TStringList;
begin
  if Key = VK_Return then
    if aqryApplicationRoles.State in [dsEdit, dsInsert] then
      with dbgApplicationRoles do
        if Columns[SelectedIndex].Field.FieldName = 'KeyUserID' then
          begin
            Code := LookUpUser;
            if (Code.Values['UserID'] <> '') then
              DataSource.DataSet.FieldByName('KeyUserID').Value := Code.Values['UserID'];
            SelectedIndex := GetColumnIndex(dbgApplicationRoles,'Name');
          end;

  if (Key = VK_DOWN) or (Key = VK_UP) then          //doc12192023TMH
    begin
      timer1.Enabled := true;
      Counter := waitTime;
    end;
end;

procedure TfrmApplicationRolesModifyAccess.dbgApplicationRolesKeyPress(
  Sender: TObject; var Key: Char);
begin
  if ((aqryApplicationRoles.State In [dsInsert, dsEdit]) and
      (dbgApplicationRoles.Columns[dbgApplicationRoles.SelectedIndex].Field.FieldName = 'ActiveFlag')) then
    begin
      Key := UpCase(Key);
      if not(Key In ['A', 'I', #8]) then
        Key := #0;
    end;
end;

procedure TfrmApplicationRolesModifyAccess.ebUserNameKeyDown(Sender: TObject;     //11012023WP
  var Key: Word; Shift: TShiftState);
var
  UserList: TStringList;
begin
  UserList := TStringList.Create;
  try
    if Key = VK_RETURN then
      try
        UserList := LookupUser();
        if (UserList.Values['UserName'] <> '') then
        begin
          ebUserName.Text := UserList.Values['UserName'];
          if cbApplications.ItemIndex	> 0 then                                  //doc12192023TMH
            begin
              LoadApplicationRolesGrid;
              RequeryFormsReportsUsers;
            end;
        end;
        finally
          cbRoleName.SetFocus;
      end;
  finally
    UserList.Free;
  end;
end;

procedure TfrmApplicationRolesModifyAccess.sbCloseClick(Sender: TObject);
begin
  Close;
end;

////doc11172023TMH Rewrote this procedure since it was getting so many commented out areas.
//procedure TfrmApplicationRolesModifyAccess.LoadApplicationRolesGrid;
//var
//  keyUserIDStr : TString;
//  ApplicationComponentKey : TString;
//  ApplicationReportComponentKey : TString;
//  OleStr : PWideChar;
//  Str:string;
//  i :integer;
//begin
//  if cbApplications.ItemIndex	<> -1 then                //doc11172023TMH
//  begin
//    Screen.Cursor := crHourglass;
//    AppObj := cbApplications.Items.Objects[cbApplications.ItemIndex] as TApp;
//    keyUserIDStr := cbKeyUser.Items.Objects[cbKeyUser.ItemIndex] as TString;
//    ApplicationComponentKey := cbForms.Items.Objects[cbForms.ItemIndex] as TString;                 //doc11202023TMH
//    ApplicationReportComponentKey := cbReports.Items.Objects[cbReports.ItemIndex] as TString;       //doc11202023TMH
//
////    if cbForms.Text <> '%' then                                                                   //11012023WP  //doc11202023TMH
////      ApplicationComponentKey := cbForms.Items.Objects[cbForms.ItemIndex] as TString;             //11012023WP  //doc11202023TMH
////    if cbReports.Text <> '%' then                                                                 //11012023WP  //doc11202023TMH
////      ApplicationReportComponentKey := cbReports.Items.Objects[cbReports.ItemIndex] as TString;   //11012023WP  //doc11202023TMH
//
//    try
////      with aqryApplicationRoles do
//      with aspSearchApplicationRoles do
//      begin
//        Close;
//        Parameters.ParamByName('appKey').Value := appObj.Key;
//        Parameters.ParamByName('keyUserID').Value := keyUserIDStr.ID;
//        Parameters.ParamByName('ApplicationComponentKey').Value := ApplicationComponentKey.ID;              //doc11202023TMH
//        Parameters.ParamByName('ApplicationReportComponentKey').Value := ApplicationReportComponentKey.ID;  //doc11202023TMH
//
////        if cbForms.Text = '%' then                                                                   //11012023WP  //doc11202023TMH
////          Parameters.ParamByName('ApplicationComponentKey').Value := '%'                             //11012023WP  //doc11202023TMH
////        else                                                                                         //11012023WP  //doc11202023TMH
////          Parameters.ParamByName('ApplicationComponentKey').Value := ApplicationComponentKey.ID;     //11012023WP  //doc11202023TMH
////        if cbReports.Text = '%' then                                                                 //11012023WP  //doc11202023TMH
////          Parameters.ParamByName('ApplicationReportComponentKey').Value := '%'                       //11012023WP  //doc11202023TMH
////        else                                                                                         //11012023WP  //doc11202023TMH
////          Parameters.ParamByName('ApplicationReportComponentKey').Value := ApplicationReportComponentKey.ID;   //11012023WP  //doc11202023TMH
//
////        Parameters.ParamByName('AppUserName').Value := ebUserName.Text;                              //11012023WP //doc11202023TMH
//
//        Str := ebUserName.Text;                                                 //doc11202023TMH
//        GetMem(OleStr, (Length(Str)+1) * SizeOf(WideChar));
//        OleStr := StringToWideChar(Str, OleStr, Length(Str) + 1);
//        i := GetUserID(OleStr);
//        Parameters.ParamByName('UserID').Value := i;
//
//        Open;
//      end;
//      dbgApplicationRoles.SetFocus;
//      dbgApplicationRoles.SelectedField := dbgApplicationRoles.Fields[1];
//      RequeryFormsReportsUsers;
//      dbnvNav.DataSource := dsApplicationRoles;
//    finally
//      Screen.Cursor := crArrow;
//    end;
//  end;
//end;

end.