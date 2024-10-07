{*******************************************************************************
doc20230714TMH : HD#319050 - Created new form. Users will check off each Role to
                              signify they have reviewed the role and approve.
                              Unchecking users will take them out of the role when the audit gets finilized.
                              All other modifications will need to be done through other
                              forms like "Application Roles - Modify Access".
doc11132023TMH : HD#338995 - Key users can now only see their own audit.
                             MISUsers can see all audits but they can still only
                             modify their own.
                             Cleaned up some code.

*******************************************************************************}
unit untSOXReviewApplicationRoleAccess;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB, System.Math,
  Vcl.Grids, Vcl.DBGrids, Data.Win.ADODB, Vcl.ComCtrls, Vcl.DBCtrls, Vcl.Buttons, System.DateUtils;

type
  TfrmSOXReviewApplicationRoleAccess = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    cbKeyUsers: TComboBox;
    Panel4: TPanel;
    pcAssignedToRole: TPageControl;
    Forms: TTabSheet;
    dbgARCForms: TDBGrid;
    Reports: TTabSheet;
    dbgARCReports: TDBGrid;
    aqryARCForms: TADOQuery;
    aqryARCReports: TADOQuery;
    dsARCForms: TDataSource;
    dsARCReports: TDataSource;
    aqryKeyUsers: TADOQuery;
    aqryKeyUsersKeyUserName: TStringField;
    aqryKeyUsersKeyUserID: TIntegerField;
    Panel3: TPanel;
    lblRequiredBylbl: TLabel;
    lblDaysRamaininglbl: TLabel;
    lblRequiredBy: TLabel;
    lblDaysRemaining: TLabel;
    aqrySoxReviewHdr: TADOQuery;
    dsSoxReviewHdr: TDataSource;
    lblTotalRoles: TLabel;
    lblRolesVerified: TLabel;
    lblPercentCompletelbl: TLabel;
    lblTotal: TLabel;
    lblVerified: TLabel;
    lblCompleted: TLabel;
    lblRolesRemaining: TLabel;
    lblRemaining: TLabel;
    Panel5: TPanel;
    dbgSOXAppRoles: TDBGrid;
    aqryARCFormsApplicationRolesKey: TIntegerField;
    aqryARCFormsApplicationComponentKey: TIntegerField;
    aqryARCFormsComponentName: TStringField;
    aqryARCFormsReadAccess: TBooleanField;
    aqryARCFormsInsertAccess: TBooleanField;
    aqryARCFormsUpdateAccess: TBooleanField;
    aqryARCFormsDeleteAccess: TBooleanField;
    aqryARCFormsShowInMenu: TStringField;
    aqrySOXAppRoles: TADOQuery;
    dsSOXAppRoles: TDataSource;
    aqrySOXAppRolesSOXReviewKey: TIntegerField;
    aqrySOXAppRolesReviewed: TBooleanField;
    aqrySOXAppRolesApplicationRolesKey: TIntegerField;
    aqrySOXAppRolesApplicationKey: TIntegerField;
    aqrySOXAppRolesApplicationName: TStringField;
    aqrySOXAppRolesKeyUserID: TIntegerField;
    aqrySOXAppRolesDescription: TStringField;
    tsUsers: TTabSheet;
    dbgUsers: TDBGrid;
    aqryRoleUsers: TADOQuery;
    dsRoleUsers: TDataSource;
    aqryRoleUsersSOXReviewKey: TIntegerField;
    aqryRoleUsersIsNeeded: TBooleanField;
    aqryRoleUsersApplicationRoleUsersKey: TIntegerField;
    aqryRoleUsersApplicationRolesKey: TIntegerField;
    aqryRoleUsersUserID: TIntegerField;
    aqryRoleUsersName: TStringField;
    aqryRoleUsersJobDescription: TStringField;
    aqryRoleUsersDivisionDescription: TStringField;
    aqryRoleUsersDepartmentDescription: TStringField;
    aqryRoleUsersReportToName: TStringField;
    lbRoles: TLabel;
    lbComponents: TLabel;
    aqrySoxReviewHdrSOXReviewKey: TAutoIncField;
    aqrySoxReviewHdrDateGenerated: TDateTimeField;
    aqrySoxReviewHdrGeneratedBy: TIntegerField;
    aqrySoxReviewHdrDateDue: TDateTimeField;
    aqrySoxReviewHdrDateCompleted: TDateTimeField;
    aqrySoxReviewHdrSecurityMethod: TStringField;
    aqryARCReportsApplicationRolesKey: TIntegerField;
    aqryARCReportsApplicationComponentKey: TIntegerField;
    aqryARCReportsComponentName: TStringField;
    aqryARCReportsShowInMenu: TStringField;
    aqryARCReportsActiveFlag: TStringField;
    aqryUserCredentials: TADOQuery;
    aqryUserCredentialsUserID: TAutoIncField;
    sbClose: TSpeedButton;
    cboTesting: TCheckBox;
    lblTestMode: TLabel;
    Timer1: TTimer;
    aqryUserCredentialsIsMISUser: TIntegerField;
    procedure FormCreate(Sender: TObject);
    procedure GetKeyUserObjects();
    procedure dbgSOXAppRolesCellClick(Column: TColumn);
    procedure dbgSOXAppRolesTitleClick(Column: TColumn);
    procedure dbgSOXAppRolesDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure dbgSOXAppRolesColEnter(Sender: TObject);
    procedure dbgSOXAppRolesColExit(Sender: TObject);
    procedure dbgUsersDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure dbgUsersCellClick(Column: TColumn);
    procedure cbKeyUsersCloseUp(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure sbCloseClick(Sender: TObject);
    procedure dbgUsersExit(Sender: TObject);
    procedure dbgSOXAppRolesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure aqrySOXAppRolesAfterOpen(DataSet: TDataSet);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cboTestingClick(Sender: TObject);
    procedure cbKeyUsersChange(Sender: TObject);
  private
    GridOriginalOptionsRoles: TDBGridOptions;
    GridOriginalOptionsUsers: TDBGridOptions;
    SOXReviewKey: integer;
    LoggedInUserID: integer;        //doc11132023TMH
    IsKeyUser: boolean;
    IsMISUser: boolean;           //doc11132023TMH
    ProdConn: Boolean;          //doc11132023TMH
    Counter: integer;
    procedure GetSoxReviewHdr;
    procedure SetCheckBoxFieldValue(Column: TColumn; DataSource: TDataSource);
    procedure GetReviewedCnt();
    procedure UpdateReviewedCount(checked:boolean);
    procedure LoadUserCredentials();
    procedure SelectRoleLoadGrids;
    procedure CheckProductionConnection();
    procedure SetCheckbox(Column: TColumn; DataSource: TDataSource);
    procedure UpdateCheckBoxField(Column: TColumn; DataSource: TDataSource);
    procedure EnableKeyUserComboBox;       //doc11132023TMH
    procedure LoadRolesForKeyUser;         //doc11132023TMH
  public
    { Public declarations }
    function IsSoxReviewOpen: boolean;
  end;

var
  frmSOXReviewApplicationRoleAccess: TfrmSOXReviewApplicationRoleAccess;

implementation

{$R *.dfm}

uses untDataMod, untAppFunctions, untSecurity, untCommon;

procedure TfrmSOXReviewApplicationRoleAccess.aqrySOXAppRolesAfterOpen(
  DataSet: TDataSet);
begin
  lblTotal.Caption := DataSet.RecordCount.ToString;
  GetReviewedCnt()
end;

procedure TfrmSOXReviewApplicationRoleAccess.cbKeyUsersChange(Sender: TObject);
begin
  IsKeyUser := Integer(cbKeyUsers.Items.Objects[cbKeyUsers.ItemIndex]) = LoggedInUserID;      //doc11132023TMH
end;

procedure TfrmSOXReviewApplicationRoleAccess.cbKeyUsersCloseUp(Sender: TObject);
begin
  LoadRolesForKeyUser;
end;

procedure TfrmSOXReviewApplicationRoleAccess.cboTestingClick(Sender: TObject);
begin
  EnableKeyUserComboBox;    //doc11132023TMH
end;

procedure TfrmSOXReviewApplicationRoleAccess.GetReviewedCnt();
var revCnt:integer;
const sSQL = 'Select Reviewed'                              +#13#10+
             'From SOXApplicationRoles srd (NoLock)'        +#13#10+
             'Where KeyUserID = %d'                 +#13#10+
             '  And SOXReviewKey = %d'           +#13#10+
             '  And Reviewed = 1';
begin
  With TADOQuery.Create(Nil) Do
    Try
      Connection := dmApplicationMaint.dbAppSecu;
      SQL.Text := Format(sSQL, [Integer(cbKeyUsers.Items.Objects[cbKeyUsers.ItemIndex]), SOXReviewKey ]);
      Open;
      revCnt := RecordCount;
    Finally
      Close;
      Free;
    End;
  lblVerified.Caption := revCnt.ToString;
  lblRemaining.Caption  := (StrToInt(lblTotal.Caption) - revCnt).ToString;
  lblCompleted.Caption := FormatFloat('##0.00', RoundDecimal((revCnt / (StrToInt(lblTotal.Caption))), 4) * 100) + '%';
end;

procedure TfrmSOXReviewApplicationRoleAccess.UpdateReviewedCount(checked:boolean);
var
  revCnt, num:integer;
begin
  if checked then
    num := 1
  else
    num := -1;
  revCnt := StrToInt(lblVerified.Caption) + num;
  lblVerified.Caption := revCnt.ToString;
  lblRemaining.Caption := (StrToInt(lblTotal.Caption) - revCnt).ToString;
  lblCompleted.Caption := FormatFloat('##0.00', RoundDecimal((revCnt / (StrToInt(lblTotal.Caption))), 4) * 100) + '%';
end;

procedure TfrmSOXReviewApplicationRoleAccess.dbgSOXAppRolesCellClick(
  Column: TColumn);
begin
  try
//    Screen.Cursor := crHourglass;
    if not dsSOXAppRoles.DataSet.IsEmpty then
      SelectRoleLoadGrids;
    SetCheckBoxFieldValue(Column, dsSOXAppRoles);                               //doc11132023TMH
//    if IsKeyUser or cboTesting.Checked then                                   //doc11132023TMH
//      begin
//        SetCheckBoxFieldValue(Column, dsSOXAppRoles);
//      end;
  finally
//    Screen.Cursor := crArrow;
  end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.dbgUsersCellClick(Column: TColumn);
begin
  SetCheckBoxFieldValue(Column, dsRoleUsers);                                   //doc11132023TMH
//  if IsKeyUser or cboTesting.Checked then                                     //doc11132023TMH
//    begin
//      SetCheckBoxFieldValue(Column, dsRoleUsers);
//    end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.SetCheckBoxFieldValue(Column: TColumn; DataSource: TDataSource);
var MsgForm: TForm;
begin
  MsgForm := CreateMessageDialog('This user belongs to a role that has been already checked for review. ' + sLineBreak + sLineBreak +
    'Would you like to check/uncheck this user anyways?' + sLineBreak + sLineBreak +
    'NOTE: The role will need the Reviewed checkbox confirmed again if so.' , mtConfirmation, [mbYes, mbNo]);
  if (Column.Field.DataType = ftBoolean) then
    begin
      if IsKeyUser or cboTesting.Checked then
      begin
        if (DataSource = dsRoleUsers) and (aqrySOXAppRolesReviewed.value = true) then
          try
            MsgForm.Position := poScreenCenter;
            MsgForm.ShowModal;
            if MsgForm.ModalResult = mrYes then
              begin
                UpdateCheckBoxField(Column, DataSource);
                UpdateCheckBoxField(dbgSoxAppRoles.Columns[GetColumnIndex(dbgSoxAppRoles, 'Reviewed')], dsSoxAppRoles);
                UpdateReviewedCount(false);
              end;
          finally
            MsgForm.Free;
          end
        else
          begin
            UpdateCheckBoxField(Column, DataSource);
            if DataSource = dsSOXAppRoles then
               UpdateReviewedCount(Column.Field.Value);
          end;
      end;
    end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.GetSoxReviewHdr;
begin
  with aqrySOXReviewHdr do
    begin
      Close;
      Open;
      SOXReviewKey := aqrySoxReviewHdrSOXReviewKey.Value;
      lblRequiredBy.Caption	:= aqrySoxReviewHdrDateDue.AsString;
      lblDaysRemaining.Caption := (DaysBetween(Trunc(Now), aqrySoxReviewHdrDateDue.Value)).ToString;
    end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.LoadUserCredentials();
begin
  with aqryUserCredentials do
  begin
    Close;
    Parameters.ParamByName('AppUserName').Value := GetNTUserName;
    Open;

    IsMISUser := Fields.FieldByName('IsMISUser').Value;                               //doc11132023TMH
    LoggedInUserID := Fields.FieldByName('UserID').AsInteger;                         //doc11132023TMH
    cbKeyUsers.ItemIndex := cbKeyUsers.Items.IndexOfObject(TObject(LoggedInUserID));  //doc11132023TMH
    Close;
  end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.CheckProductionConnection();
var
//  ProdConn: Boolean;      //doc11132023TMH Made this a global variable.
  ConnKey: String;
begin
  ConnKey := GetCommandLineParameter('ConnectionKey');
  ProdConn := IsProductionConnection(ConnKey);
//  ProdConn := true;                                             //for testing

  if not ProdConn and IsMisUser then                             //doc11132023TMH begin
  begin
    cboTesting.Checked := true;
    cboTesting.Visible := true;
    lblTestMode.Visible	:= true;
  end
  else
  begin
    cboTesting.Checked := false;
    cboTesting.Visible := false;
    lblTestMode.Visible	:= false;
    EnableKeyUserComboBox;
  end;                                                           //doc11132023TMH end

//  cboTesting.Checked := not ProdConn and IsMisUser;                 //doc11132023TMH
//  cboTesting.Visible := not ProdConn and IsMisUser;                 //doc11132023TMH
//  lblTestMode.Visible	:= not ProdConn and IsMisUser;                //doc11132023TMH
end;

procedure TfrmSOXReviewApplicationRoleAccess.SelectRoleLoadGrids;
var
  roleKey: Integer;
begin
  begin
    roleKey := dsSOXAppRoles.DataSet.FieldByName('ApplicationRolesKey').AsInteger;
    with aqryRoleUsers do
    begin
      Close;
      Parameters.ParamByName('ApplicationRolesKey').Value := roleKey;
      Parameters.ParamByName('SOXReviewKey').Value := SOXReviewKey;
      Open;
    end;
    with aqryARCForms do
    begin
      Close;
      Parameters.ParamByName('ApplicationRolesKey').Value := roleKey;
      Open;
    end;
    with aqryARCReports do
    begin
      Close;
      Parameters.ParamByName('ApplicationRolesKey').Value := roleKey;
      Open;
    end;
  end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.sbCloseClick(Sender: TObject);
begin
  Close;
end;

function TfrmSOXReviewApplicationRoleAccess.IsSoxReviewOpen: boolean;
begin
  With TADOQuery.Create(Nil) Do
    Try
      Connection := dmApplicationMaint.dbAppSecu;
      SQL.Add('Select SOXReviewKey From SOXReview (NoLock)');
      SQL.Add('Where DateCompleted Is Null');
      SQL.Add(' And SecurityMethod = ''R''');
      Open;
      Result := RecordCount > 0;
    Finally
      Close;
      Free;
    End;
end;

procedure TfrmSOXReviewApplicationRoleAccess.LoadRolesForKeyUser;                //doc11132023TMH extracted method from event.
begin
  if cbKeyUsers.ItemIndex <> -1 then
  begin
    try
      Screen.Cursor := crHourglass;
      with aqrySOXAppRoles do
      begin
        Close;
        Parameters.ParamByName('SOXReviewKey').Value := SOXReviewKey;
        Parameters.ParamByName('KeyUserID').Value := Integer(cbKeyUsers.Items.Objects[cbKeyUsers.ItemIndex]);
        Open;
      end;
      dbgSOXAppRoles.OnCellClick(dbgSoxAppRoles.Columns[GetColumnIndex(dbgSoxAppRoles, 'Description')]);
      dbgSOXAppRoles.SetFocus;
    finally
      Screen.Cursor := crArrow;
    end;
  end
  else
  begin
    aqrySoxAppRoles.Close;
    aqryRoleUsers.Close;
    aqryARCForms.Close;
    aqryARCReports.Close;
  end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.EnableKeyUserComboBox;             //doc11132023TMH
begin

  if cboTesting.Checked then
    begin
      cbKeyUsers.Enabled := true;
    end
  else if ProdConn and IsMISUser then
    begin
      cbKeyUsers.Enabled := true;
    end
  else
    begin
      cbKeyUsers.ItemIndex := cbKeyUsers.Items.IndexOfObject(TObject(LoggedInUserID));
      cbKeyUsers.Enabled := false;
    end;

  LoadRolesForKeyUser;

  if cbKeyUsers.ItemIndex <> -1 then
    IsKeyUser := Integer(cbKeyUsers.Items.Objects[cbKeyUsers.ItemIndex]) = LoggedInUserID
  else
    IsKeyUser := false;

end;

procedure TfrmSOXReviewApplicationRoleAccess.UpdateCheckBoxField(Column: TColumn; DataSource: TDataSource);
begin
  DataSource.Edit;
  Column.Field.Value := not Column.Field.AsBoolean;
  DataSource.DataSet.Post;
end;

procedure TfrmSOXReviewApplicationRoleAccess.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  UserAccess.LogOff();
  aqryRoleUsers.Close;
  aqrySoxAppRoles.Close;
  aqryARCForms.Close;
  aqryARCReports.Close;
end;

procedure TfrmSOXReviewApplicationRoleAccess.FormCreate(Sender: TObject);
begin
  UserAccess.LogOn(Self);
  GetSoxReviewHdr;
  GetKeyUserObjects;
  GridOriginalOptionsRoles := dbgSOXAppRoles.Options;
  GridOriginalOptionsUsers := dbgUsers.Options;
  pcAssignedToRole.ActivePageIndex := 0;
  lblTotal.Caption := '';
  lblVerified.Caption := '';
  lblRemaining.Caption := '';
  lblCompleted.Caption := '';
end;

procedure TfrmSOXReviewApplicationRoleAccess.FormKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var Msg : TMsg;
begin
  if ((Key = VK_ESCAPE) or (ssCtrl in Shift)) and
     (not (Key in [Ord('C'), Ord('c'), Ord('V'), Ord('v'), Ord('A'), Ord('a'), Ord('X'), Ord('x')])) then
    begin
      if PeekMessage(Msg, Handle, WM_CHAR, WM_CHAR, 1) and (Msg.Message = WM_QUIT) then
         PostQuitMessage(Msg.WParam);
    end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.FormShow(Sender: TObject);
begin
  LoadUserCredentials;                    //doc11132023TMH
  CheckProductionConnection;              //doc11132023TMH
end;

procedure TfrmSOXReviewApplicationRoleAccess.GetKeyUserObjects();
begin
  with aqryKeyUsers do
  begin
    Close;
    Parameters.ParamByName('SOXReviewKey').Value := SOXReviewKey;
    Open;
    while not EOF do
      begin
          cbKeyUsers.Items.AddObject( Trim(Fields[0].AsString), TObject(Fields[1].AsInteger));
          Next;
      end;
  end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.dbgSOXAppRolesColEnter(
  Sender: TObject);
begin
  if TDBGrid(Sender).SelectedField.DataType = ftBoolean then
    begin
      if TDBGrid(Sender) = dbgSOXAppRoles then
        GridOriginalOptionsRoles := TDBGrid(Sender).Options
      else
        GridOriginalOptionsUsers := TDBGrid(Sender).Options;
      TDBGrid(Sender).Options := TDBGrid(Sender).Options - [dgEditing];
    end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.dbgSOXAppRolesColExit(
  Sender: TObject);
begin
  if TDBGrid(Sender).SelectedField.DataType = ftBoolean then
    if TDBGrid(Sender) = dbgSOXAppRoles then
      TDBGrid(Sender).Options := GridOriginalOptionsRoles
    else
      TDBGrid(Sender).Options := GridOriginalOptionsUsers
end;

procedure TfrmSOXReviewApplicationRoleAccess.dbgSOXAppRolesDrawColumnCell(
  Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
const
   CtrlState: array[Boolean] of integer = (DFCS_BUTTONCHECK, DFCS_BUTTONCHECK or DFCS_CHECKED) ;
begin
  if (Column.Field.DataType=ftBoolean) then
    begin
      if Column.Field.AsBoolean then
        TDBGrid(Sender).Canvas.Brush.Color := clMoneyGreen;
      TDBGrid(Sender).Canvas.FillRect(Rect) ;
      if (VarIsNull(Column.Field.Value)) then
        DrawFrameControl(TDBGrid(Sender).Canvas.Handle,Rect, DFC_BUTTON, DFCS_BUTTONCHECK or DFCS_INACTIVE)
      else
        DrawFrameControl(TDBGrid(Sender).Canvas.Handle,Rect, DFC_BUTTON, CtrlState[Column.Field.AsBoolean]);
    end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.dbgSOXAppRolesKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) then
    dbgSoxAppRoles.OnCellClick(dbgSoxAppRoles.Columns.Items[dbgSoxAppRoles.SelectedIndex])
  else if (Key = VK_F2) and (ssCtrl in Shift) and (ssShift in Shift) then
    begin
      IsKeyUser := Integer(cbKeyUsers.Items.Objects[cbKeyUsers.ItemIndex]) = aqryUserCredentialsUserID.Value;
      if IsKeyUser or cboTesting.Checked then
        SetCheckbox(dbgSoxAppRoles.Columns.Items[dbgSoxAppRoles.SelectedIndex], dsSOXAppRoles);
    end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.SetCheckbox(Column: TColumn; DataSource: TDataSource);
begin
  Counter := RandomRange(2, 6);
  timer1.Enabled := true;
  aqrySOXAppRoles.First;
end;

procedure TfrmSOXReviewApplicationRoleAccess.Timer1Timer(Sender: TObject);
begin
  Dec(Counter);
  if (Counter <= 0) then
    begin
      dbgSoxAppRoles.OnCellClick(dbgSoxAppRoles.Columns[GetColumnIndex(dbgSoxAppRoles, 'Reviewed')]);
      aqrySOXAppRoles.Next;
      Counter := RandomRange(6, 10);
      if aqrySOXAppRoles.EOF then
        begin
          timer1.Enabled := false;
          exit;
        end;
    end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.dbgUsersDrawColumnCell(
  Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
const
   CtrlState: array[Boolean] of integer = (DFCS_BUTTONCHECK, DFCS_BUTTONCHECK or DFCS_CHECKED) ;
begin
  if (Column.Field.DataType=ftBoolean) then
  begin
    TDBGrid(Sender).Canvas.FillRect(Rect) ;
    if (VarIsNull(Column.Field.Value)) then
      DrawFrameControl(TDBGrid(Sender).Canvas.Handle,Rect, DFC_BUTTON, DFCS_BUTTONCHECK or DFCS_INACTIVE)
    else
      DrawFrameControl(TDBGrid(Sender).Canvas.Handle,Rect, DFC_BUTTON, CtrlState[Column.Field.AsBoolean]);
  end;
end;

procedure TfrmSOXReviewApplicationRoleAccess.dbgUsersExit(Sender: TObject);
begin
  if TDBGrid(Sender).DataSource.State = dsEdit then
    aqryRoleUsers.Post;
end;

procedure TfrmSOXReviewApplicationRoleAccess.dbgSOXAppRolesTitleClick(
  Column: TColumn);
begin
  If Not(TDBGrid(Column.Grid).DataSource.DataSet.State	= dsInactive) And (Column.Field.FieldKind = fkData) then
      SortGrid(TDBGrid(Column.Grid), TADOQuery(TDBGrid(Column.Grid).DataSource.DataSet).Sort, Column.FieldName, '');
end;

end.