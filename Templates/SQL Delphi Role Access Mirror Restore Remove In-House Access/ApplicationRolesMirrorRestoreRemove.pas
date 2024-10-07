{
doc06192023TMH, HD#318509: Created form,untApplicationRolesMirrorUser. This replicates the role security
                access a user has to another user. Displays what roles the source user is in via TTreeNodes.
                The tree shows the application name as the parent node and the child nodes are the roles.
                To restore access for a returning user uncheck "Active Only" then select same user for
                source and destination.
doc09192023TMH, HD#:334092: Renamed form, untApplicationRolesMirrorUser. Added radio group to top since
                the remove all option was needing to be added to role forms somewhere. The restore
                functionality was already in the form but added this as a option at the top as well.
                Added the ability to choose to modify CodesAccess and ApplicationConnectionAccess via checkboxes.

}
unit untApplicationRolesMirrorRestoreRemove;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.DBCtrls, Data.Win.ADODB, Vcl.ComCtrls,
  FireDAC.VCLUI.Controls;

type
  TfrmApplicationRolesMirrorRestoreRemove = class(TForm)
    Panel1: TPanel;
    cbSourceUser: TComboBox;
    cbDestUser: TComboBox;
    lbSourceUser: TLabel;
    lbDestUser: TLabel;
    Panel2: TPanel;
    Panel3: TPanel;
    aqryApplicationRoles: TADOQuery;
    aqryApplicationRolesApplicationRolesKey: TIntegerField;
    aqryApplicationRolesRoleName: TStringField;
    aqryApplicationRolesApplicationKey: TIntegerField;
    aqryApplicationRolesApplicationName: TStringField;
    btnOK: TButton;
    btnCancel: TButton;
    tvRoles: TTreeView;
    aqryApplicationRolesActiveFlag: TStringField;
    btnSelectAll: TButton;
    btnClear: TButton;
    aspMirrorRestoreRemoveRoleAccess: TADOStoredProc;
    cboActiveOnly: TCheckBox;
    aqryGetUsers: TADOQuery;
    lbSourceName: TLabel;
    lbDestName: TLabel;
    cboWarehouse: TCheckBox;
    cboPrinterQueue: TCheckBox;
    cboScanStation: TCheckBox;
    cboPlantUserXRef: TCheckBox;
    rgAccessOp: TRadioGroup;                                  //doc09192023TMH
    cboCodes: TCheckBox;                                      //doc09192023TMH
    cboConnection: TCheckBox;                                 //doc09192023TMH
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure tvRolesCheckStateChanged(Sender: TCustomTreeView; Node: TTreeNode;
      CheckState: TNodeCheckState);
    procedure tvRolesCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure btnSelectAllOrClearClick(Sender: TObject);
    procedure aqryAddUserToRolesPostError(DataSet: TDataSet; E: EDatabaseError;
      var Action: TDataAction);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cboActiveOnlyClick(Sender: TObject);
    procedure cbSourceUserSelect(Sender: TObject);
    procedure cbDestUserSelect(Sender: TObject);
    procedure rgAccessOpClick(Sender: TObject);                       //doc09192023TMH
  private
    { Private declarations }
    function GetFullName(userID: integer): string;
    procedure LoadDestUserCB();
    procedure LoadSourceUserCB();
    procedure GetRoleObjectsAndLoadNodes();
    procedure EnableOKButton();
    procedure CheckAllRoles(allRoles: Boolean);
    procedure GetRoleKeysToCopy(copiedRoles: TStringList);
//    function MirrorRoleAccessAndBuildCustMsg(notChanged: TStringList; reactivated: TStringList; activated: TStringList; copiedRoles: TStringList):String;      //doc09192023TMH
    function MirrorRoleAccessAndBuildCustMsg(copiedRoles: TStringList):String;  //doc09192023TMH
    var recursive : boolean;
    var sourceUserID : integer;
    var destUserID : integer;
  public
    { Public declarations }
  end;

type TRoleObj = class
  private
    fRoleKey: string;
    fRoleName: string;
    fAppKey: integer;
  public
    property RKey : string read fRoleKey;
    property RName : string read fRoleName;
    property AKey : integer read fAppKey;
    constructor Create(const rk : string; const rn : string; const ak : integer);
  end;

var
  frmApplicationRolesMirrorRestoreRemove: TfrmApplicationRolesMirrorRestoreRemove;
  roleObj : TRoleObj;

implementation

{$R *.dfm}

uses untDataMod, untAppFunctions, untSecurity, untMainForm, untCommon;

constructor TRoleObj.Create(const rk : string; const rn : string; const ak : integer);
begin
  fRoleKey := rk;
  fRoleName := rn;
  fAppKey := ak;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.aqryAddUserToRolesPostError(
  DataSet: TDataSet; E: EDatabaseError; var Action: TDataAction);
var FieldName :string;
begin
  FieldName := CheckForErrors('AppSecur', DataSet, E.Message);
  Action := daAbort;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.btnOKClick(Sender: TObject);           //doc09192023TMH replaced
var
  custMsg: string;
  copiedRoles: TStringList;
  MsgForm: TForm;
begin
  copiedRoles := TStringList.Create;
  GetRoleKeysToCopy(copiedRoles);

  custMsg := MirrorRoleAccessAndBuildCustMsg(copiedRoles);

  MsgForm := CreateMessageDialog(custMsg , mtCustom, [mbOK]);
  try
    MsgForm.Position := poScreenCenter;
    MsgForm.ShowModal;
  finally
    MsgForm.Free;
    copiedRoles.Free;
  end;
end;

//procedure TfrmApplicationRolesMirrorUser.btnOKClick(Sender: TObject);         //doc09192023TMH
//var
//  destUserID, custMsg: string;
//  copiedRoles, notChanged, reactivated, activated: TStringList;
//  MsgForm: TForm;
//begin
//  destUserID := IntToStr(frmMain.GetUserId(cbDestUser.Text));
//  notChanged := TStringList.Create;
//  reactivated := TStringList.Create;
//  activated := TStringList.Create;
//  copiedRoles := TStringList.Create;
//  GetRoleKeysToCopy(copiedRoles);
//  custMsg := MirrorRoleAccessAndBuildCustMsg(notChanged, reactivated, activated, copiedRoles);
//  MsgForm := CreateMessageDialog(custMsg , mtCustom, [mbOK]);
//  try
//    MsgForm.Position := poScreenCenter;
//    MsgForm.ShowModal;
//  finally
//    MsgForm.Free;
//    notChanged.Free;
//    reactivated.Free;
//    activated.Free;
//    copiedRoles.Free;
//  end;
//end;

procedure TfrmApplicationRolesMirrorRestoreRemove.GetRoleKeysToCopy(copiedRoles: TStringList);
var
  node: TTreeNode;
begin
  for node in tvRoles.Items do
    if (node.parent <> nil) and (node.Checked) then
      copiedRoles.Add(TRoleObj(node.Data).RKey);
end;

function TfrmApplicationRolesMirrorRestoreRemove.MirrorRoleAccessAndBuildCustMsg(copiedRoles: TStringList):String; //doc09192023TMH replaced
var custMsg, targetUser: string;
var notChanged, reactivated, activated, removed: TStringList;
begin
  notChanged := TStringList.Create;
  reactivated := TStringList.Create;
  activated := TStringList.Create;
  removed := TStringList.Create;

  try
    with aspMirrorRestoreRemoveRoleAccess do
    begin
      Close;
      case rgAccessOp.ItemIndex of
      0 : begin
            targetUser := cbDestUser.Text;
            Parameters.ParamByName('@DestUserID').Value := destUserID;
            Parameters.ParamByName('@AccessOperation').Value := 0;
          end;
      1 : begin
            targetUser := cbSourceUser.Text;
            Parameters.ParamByName('@DestUserID').Value := sourceUserID;
            Parameters.ParamByName('@AccessOperation').Value := 1;
          end;
      2 : begin
            targetUser := cbSourceUser.Text;
            Parameters.ParamByName('@DestUserID').Value := sourceUserID;
            Parameters.ParamByName('@AccessOperation').Value := 2;
          end;
      end;

      Parameters.ParamByName('@SourceUserID').Value := sourceUserID;
      Parameters.ParamByName('@RoleKeys').Value := copiedRoles.CommaText;
      Parameters.ParamByName('@CopyWarehouse').Value := cboWarehouse.Checked;
      Parameters.ParamByName('@CopyPrinterQueue').Value := cboPrinterQueue.Checked;
      Parameters.ParamByName('@CopyPlantUser').Value := cboPlantUserXRef.Checked;
      Parameters.ParamByName('@CopyScanStation').Value := cboScanStation.Checked;
      Parameters.ParamByName('@CopyCodes').Value := cboCodes.Checked;
      Parameters.ParamByName('@CopyConnection').Value := cboConnection.Checked;
      Open;
      while not EOF do
      begin
        if Fields[3].AsString = 'A' then
          activated.Add('    ' + Fields[2].AsString + ' --> ' + Fields[1].asString)
        else if Fields[3].AsString = 'R' then
          reactivated.Add('    ' + Fields[2].AsString + ' --> ' + Fields[1].asString)
        else if Fields[3].AsString = 'N' then
          notChanged.Add('    ' + Fields[2].AsString + ' --> ' + Fields[1].asString)
        else if Fields[3].AsString = 'D' then
          removed.Add('    ' + Fields[2].AsString + ' --> ' + Fields[1].asString);
        Next;
      end;
    end;

    custMsg := targetUser + sLineBreak + sLineBreak;
    if activated.Count <> 0 then
      custMsg := custMsg + 'Successfully added to the following roles: ' + slineBreak + activated.Text + sLineBreak;
    if reactivated.Count <> 0 then
      custMsg := custMsg + 'Reactivated in the following roles: ' + slineBreak + reactivated.Text + sLineBreak;
    if notChanged.Count <> 0 then
      custMsg := custMsg + 'Already had access for the following roles: ' + slineBreak + notChanged.Text;
    if removed.Count <> 0 then
      custMsg := custMsg + 'Removed from the following roles: ' + slineBreak + removed.Text;

  finally
    aspMirrorRestoreRemoveRoleAccess.close;
    notChanged.Free;
    reactivated.Free;
    activated.Free;
    removed.Free;
  end;

  Result := custMsg;
end;

//doc09192023TMH
//function TfrmApplicationRolesMirrorUser.MirrorRoleAccessAndBuildCustMsg(notChanged: TStringList; reactivated: TStringList; activated: TStringList; copiedRoles: TStringList):String;
//var custMsg: string;
//begin
//  try
//    try
//      with aspCopyRoleAccess do
//      begin
//        Close;
//        Parameters.ParamByName('@DestUserID').Value := destUserID;
//        Parameters.ParamByName('@SourceUserID').Value := sourceUserID;
//        Parameters.ParamByName('@RoleKeys').Value := copiedRoles.CommaText;
//
//        Parameters.ParamByName('@CopyWarehouse').Value := cboWarehouse.Checked;
//        Parameters.ParamByName('@CopyPrinterQueue').Value := cboPrinterQueue.Checked;
//        Parameters.ParamByName('@CopyPlantUser').Value := cboPlantUserXRef.Checked;
//        Parameters.ParamByName('@CopyScanStation').Value := cboScanStation.Checked;
//        Open;
//        while not EOF do
//        begin
//          if Fields[3].AsString = 'A' then
//            activated.Add('    ' + Fields[2].AsString + ' --> ' + Fields[1].asString)
//          else if Fields[3].AsString = 'R' then
//            reactivated.Add('    ' + Fields[2].AsString + ' --> ' + Fields[1].asString)
//          else if Fields[3].AsString = 'N' then
//            notChanged.Add('    ' + Fields[2].AsString + ' --> ' + Fields[1].asString);
//          Next;
//        end;
//      end;
//    except
//      on E: Exception do
//        ShowMessage(E.Message);
//    end;
//  finally
//    aspCopyRoleAccess.close;
//  end;
//
//  if activated.Count <> 0 then
//    custMsg := 'Successfully added ' + cbDestUser.Text + ' to the following roles: ' + slineBreak + activated.Text + sLineBreak;
//  if reactivated.Count <> 0 then
//    custMsg := custMsg + 'Reactivated in the following roles: ' + slineBreak + reactivated.Text + sLineBreak;
//  if notChanged.Count <> 0 then
//    custMsg := custMsg + 'Already had access for the following roles: ' + slineBreak + notChanged.Text;
//
//  Result := custMsg;
//end;

procedure TfrmApplicationRolesMirrorRestoreRemove.rgAccessOpClick(Sender: TObject);      //doc09192023TMH
begin
  case rgAccessOp.ItemIndex of
    0 : begin
          lbDestUser.Enabled := true;
          cbDestUser.Enabled := true;
          lbDestName.Enabled := true;
          btnOK.Caption := 'Mirror';
          lbSourceUser.Caption := 'Source User';
          cbSourceUser.TextHint := 'Select User to Mirror';
          EnableOKButton();
        end;
    1 : begin
          lbDestUser.Enabled := false;
          cbDestUser.ItemIndex := -1;
          cbDestUser.Enabled := false;
          lbDestName.Caption := '';
          btnOK.Caption := 'Restore';
          lbSourceUser.Caption := 'Restore User';
          cbSourceUser.TextHint := 'Select User to Restore';
          EnableOKButton();
        end;
    2 : begin
          lbDestUser.Enabled := false;
          cbDestUser.ItemIndex := -1;
          cbDestUser.Enabled := false;
          lbDestName.Caption := '';
          btnOK.Caption := 'Remove';
          lbSourceUser.Caption := 'Remove User';
          cbSourceUser.TextHint := 'Select User to Remove';
          EnableOKButton();
        end;
  end;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.btnSelectAllOrClearClick(Sender: TObject);
begin
  if TButton(Sender) = btnSelectAll then
    CheckAllRoles(true)
  else
    CheckAllRoles(false);
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.cbSourceUserSelect(Sender: TObject);
begin
  if cbSourceUser.ItemIndex <> -1 then
    begin
      sourceUserID := Integer(cbSourceUser.Items.Objects[cbSourceUser.ItemIndex]);
      lbSourceName.Caption := GetFullName(sourceUserID);
      GetRoleObjectsAndLoadNodes();
      EnableOKButton();
    end
  else
    begin
      lbSourceName.Caption := '';
      tvRoles.Items.Clear;
      EnableOKButton();
    end;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.cbDestUserSelect(Sender: TObject);
begin
  if cbDestUser.ItemIndex <> -1 then
    begin
      destUserID := Integer(cbDestUser.Items.Objects[cbDestUser.ItemIndex]);
      lbDestName.Caption := GetFullName(destUserID);
      EnableOKButton();
    end;
end;

function TfrmApplicationRolesMirrorRestoreRemove.GetFullName(userID: integer): string;
begin
  Result := 'Name not found';
  With TADOQuery.Create(Nil) Do
  Try
    Connection := dmApplicationMaint.dbAppSecu;
//    SQL.Add('Select CONCAT(FName, '' '', LName) As Name From UserMaster With (NoLock)');            //doc09192023TMH
    SQL.Add('Select CONCAT(UserID, '' - '', FName, '' '', LName) As Name From UserMaster With (NoLock)'); //doc09192023TMH
    SQL.Add('Where UserID = ' + IntToStr(userID));
    Open;
    Result := Fields[0].AsString;
  Finally
    Close;
    Free;
  End;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.cboActiveOnlyClick(Sender: TObject);
begin
  LoadSourceUserCB;
  cbSourceUser.OnSelect(cbSourceUser);
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  UserAccess.LogOff;
  aqryGetUsers.Close;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.FormCreate(Sender: TObject);
begin
  UserAccess.LogOn(Self);
  lbSourceName.Caption := '';
  lbDestName.Caption := '';
  LoadSourceUserCB;
  LoadDestUserCB;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.LoadSourceUserCB();
var
  sourceList : TStringList;
begin
  cbSourceUser.Clear;
  if cboActiveOnly.Checked then
    sourceList := GetAllUsers()
  else
    sourceList := GetAllUsersWithInactive();
  cbSourceUser.Items.AddStrings(sourceList);
  sourceList.Free;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.LoadDestUserCB();
var
  destList : TStringList;
begin
  destList := GetAllUsers;
  cbDestUser.Items.AddStrings(destList);
  destList.Free;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.tvRolesCheckStateChanged(
  Sender: TCustomTreeView; Node: TTreeNode; CheckState: TNodeCheckState);
var
  cNode : TTreeNode;
  partial:integer;
begin
  if (CheckState = ncsPartial) and (not recursive) then
    begin
      Node.CheckState := ncsUnChecked;
    end;
  if recursive then
    begin
      recursive := false;
      Exit;
    end;
  if Node.HasChildren then
    begin
      cNode := Node.getFirstChild;
      while cNode <> nil do
        begin
          recursive := true;
          cNode.Checked := Node.Checked;
          cNode := Node.GetNextChild(cNode);
        end;
    end;
  if (Node.Parent <> nil) then
    begin
      cNode := Node.Parent.getFirstChild;
      recursive := true;
      partial := 0;
      while cNode <> nil do
        begin
          if cNode.Checked then
            begin
              partial := Partial + 1;
            end;
          cNode := Node.Parent.GetNextChild(cNode);
        end;
      if partial = 0 then
        Node.Parent.checked := false
      else if partial = Node.Parent.IndexOf(Node.Parent.GetLastChild) + 1 then
        Node.Parent.Checked := true
      else
        Node.Parent.CheckState := ncsPartial;
    end;
  recursive := false;
  EnableOKButton();
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.tvRolesCustomDrawItem(
  Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState;
  var DefaultDraw: Boolean);
begin
  if Node.Level = 0 then
    begin
      Sender.Canvas.Font.Color := $00804000;
      Sender.Canvas.Font.Style := [fsBold];
      Sender.Canvas.Font.Size := 10;
    end;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.EnableOKButton();
var childChecked:boolean;
  node : TTreeNode;
begin
  childChecked:= false;
  for node in tvRoles.Items do
    begin
      if (node.Parent <> nil) and (node.Checked) then
        childChecked := true;
    end;
  btnOK.Enabled := not ((String.IsNullOrWhiteSpace(cbSourceUser.Text))
//                        Or (String.IsNullOrWhiteSpace(cbDestUser.Text))       //doc09192023TMH
                        Or (String.IsNullOrWhiteSpace(cbDestUser.Text) And (rgAccessOp.ItemIndex	= 0)) //doc09192023TMH
                        Or (not childChecked));
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.CheckAllRoles(allRoles: Boolean);
var
  node: TTreeNode;
begin
  for node in tvRoles.Items do
    begin
      if node.Level = 0 then
        begin
          node.Checked := allRoles;
          node.Expand(false);
        end;
    end;
end;

procedure TfrmApplicationRolesMirrorRestoreRemove.GetRoleObjectsAndLoadNodes();
var
  appKey: integer;
  roleKey, roleName, appName, oldAppName: string;
  parentNode: TTreeNode;
begin
  oldAppName := '';
  tvRoles.Items.Clear;
  parentNode := TTreeNode.Create(nil);
  try
    with aqryApplicationRoles do
    begin
      Parameters.ParamByName('UserID').Value := sourceUserID;
      Close;
      Open;
      First;
      while not EOF do
        begin
          roleKey := Fields[0].AsString;
          roleName := Trim(Fields[1].AsString);
          appKey := Fields[2].AsInteger;
          appName := Trim(Fields[3].AsString);
          if oldAppName <> appName then
            begin
              parentNode := tvRoles.Items.AddObject(nil, appName, TObject(appKey));
              oldAppName := appName;
            end;
          tvRoles.Items.AddChildObject(parentNode, roleName, TRoleObj.Create(roleKey,roleName,appKey));
          Next;
        end;
    end;
    btnSelectAll.Click;
  finally
    aqryApplicationRoles.Close;
  end;
end;

end.