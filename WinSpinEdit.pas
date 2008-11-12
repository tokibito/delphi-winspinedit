//WinSpinEditコンポーネントv1.04
unit WinSpinEdit;

interface

uses Windows, Classes, StdCtrls, ExtCtrls, Controls, Messages, SysUtils,
   Menus, Buttons, ComCtrls, StrUtils;

type

  TOnUpDownChanging = procedure(Sender: TObject; ShiftState: TShiftState;
    Button: TUDBtnType) of object;

  TWinSpinEdit = class(TCustomEdit)
  private
    FMinValue: Int64;
    FMaxValue: Int64;
    FIncrement: Int64;
    FButton: TUpDown;
    FEditorEnabled: Boolean;
    fOnUpDownChanging: TOnUpDownChanging;
    function GetMinHeight: Integer;
    function GetValue: Int64;
    function CheckValue (NewValue: Int64): Int64;
    procedure SetValue (NewValue: Int64);
    procedure SetEditRect;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure CMEnter(var Message: TCMGotFocus); message CM_ENTER;
    procedure CMExit(var Message: TCMExit);   message CM_EXIT;
    procedure WMPaste(var Message: TWMPaste);   message WM_PASTE;
    procedure WMCut(var Message: TWMCut);   message WM_CUT;
  protected
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function IsValidChar(Key: Char): Boolean; virtual;
    procedure UpDownClick (Sender: TObject; Button: TUDBtnType); virtual;
    procedure InitPosition(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Button: TUpDown read FButton;
  published
    property Anchors;
    property AutoSelect;
    property AutoSize;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragMode;
    property EditorEnabled: Boolean read FEditorEnabled write FEditorEnabled
      default True;
    property Enabled;
    property Font;
    property Increment: Int64 read FIncrement write FIncrement default 1;
    property MaxLength;
    property MaxValue: Int64 read FMaxValue write FMaxValue;
    property MinValue: Int64 read FMinValue write FMinValue;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Value: Int64 read GetValue write SetValue;
    property Visible;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property OnUpDownChanging: TOnUpDownChanging
      read fOnUpDownChanging write fOnUpDownChanging;
  end;

procedure Register;

implementation

function GetShiftStateSp: TShiftState;
var
  ShiftState: TShiftState;
begin
  ShiftState:=[];
  if GetKeyState( VK_SHIFT ) and $8000 <> 0 then
    ShiftState:=ShiftState + [ssShift];
//  if GetKeyState( VK_ALT ) and $8000 <> 0 then
//    ShiftState:=ShiftState + [ssAlt];
  if GetKeyState( VK_CONTROL ) and $8000 <> 0 then
    ShiftState:=ShiftState + [ssCtrl];
  if GetKeyState( VK_LBUTTON ) and $8000 <> 0 then
    ShiftState:=ShiftState + [ssLeft];
  if GetKeyState( VK_RBUTTON ) and $8000 <> 0 then
    ShiftState:=ShiftState + [ssRight];
  if GetKeyState( VK_MBUTTON ) and $8000 <> 0 then
    ShiftState:=ShiftState + [ssMiddle];
  if [ssLeft,ssRight] <= ShiftState then
    ShiftState:=ShiftState + [ssDouble];
  Result:=ShiftState;
end;

constructor TWinSpinEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FButton := TUpDown.Create (Self);
  FButton.Width := 15;
  FButton.Height := 17;
  FButton.Max:=32767;
  FButton.Min:=(-32768);
  FButton.Visible := True;
  FButton.Parent := Self;
  FButton.OnClick := UpDownClick;
  FButton.OnMouseUp:=InitPosition;
  Text := '0';
  ControlStyle := ControlStyle - [csSetCaption];
  FIncrement := 1;
  FEditorEnabled := True;
  Value:=0;
end;

destructor TWinSpinEdit.Destroy;
begin
  FButton := nil;
  inherited Destroy;
end;

procedure Register;
begin
  RegisterComponents('toki', [TWinSpinEdit]);
end;

procedure TWinSpinEdit.GetChildren(Proc: TGetChildProc; Root: TComponent);
begin
end;

procedure TWinSpinEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_UP then UpDownClick (Self,btNext)
  else if Key = VK_DOWN then UpDownClick (Self,btPrev);
  inherited KeyDown(Key, Shift);
end;

procedure TWinSpinEdit.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  //if CheckValue (Value) <> Value then
  //  SetValue (Value);
end;

procedure TWinSpinEdit.KeyPress(var Key: Char);
begin
  if not IsValidChar(Key) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
  if Key <> #0 then inherited KeyPress(Key);
end;

function TWinSpinEdit.IsValidChar(Key: Char): Boolean;
begin
  Result := (Key in [DecimalSeparator, '+', '-', '0'..'9']) or
    ((Key < #32) and (Key <> Chr(VK_RETURN)));
  if not FEditorEnabled and Result and ((Key >= #32) or
      (Key = Char(VK_BACK)) or (Key = Char(VK_DELETE))) then
    Result := False;
end;

procedure TWinSpinEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
{  Params.Style := Params.Style and not WS_BORDER;  }
  Params.Style := Params.Style or ES_MULTILINE or WS_CLIPCHILDREN;
end;

procedure TWinSpinEdit.CreateWnd;
begin
  inherited CreateWnd;
  SetEditRect;
end;

procedure TWinSpinEdit.SetEditRect;
var
  Loc: TRect;
begin
  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));
  Loc.Bottom := ClientHeight + 1;  {+1 is workaround for windows paint bug}
  Loc.Right := ClientWidth - FButton.Width - 1;
  Loc.Top := 0;
  Loc.Left := 0;  
  SendMessage(Handle, EM_SETRECTNP, 0, LongInt(@Loc));
  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));  {debug}
end;

procedure TWinSpinEdit.WMSize(var Message: TWMSize);
var
  MinHeight: Integer;
begin
  inherited;
  MinHeight := GetMinHeight;
    { text edit bug: if size to less than minheight, then edit ctrl does
      not display the text }
  if Height < MinHeight then   
    Height := MinHeight
  else if FButton <> nil then
  begin
    if NewStyleControls and Ctl3D then
      FButton.SetBounds(Width - FButton.Width - 3, -1, FButton.Width, Height - 2)
    else FButton.SetBounds (Width - FButton.Width, 1, FButton.Width, Height - 3);
    SetEditRect;
  end;
end;

function TWinSpinEdit.GetMinHeight: Integer;
var
  DC: HDC;
  SaveFont: HFont;
  I: Integer;
  SysMetrics, Metrics: TTextMetric;
begin
  DC := GetDC(0);
  GetTextMetrics(DC, SysMetrics);
  SaveFont := SelectObject(DC, Font.Handle);
  GetTextMetrics(DC, Metrics);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
  I := SysMetrics.tmHeight;
  if I > Metrics.tmHeight then I := Metrics.tmHeight;
  Result := Metrics.tmHeight + I div 4 + GetSystemMetrics(SM_CYBORDER) * 4 + 2;
end;

procedure TWinSpinEdit.UpDownClick (Sender: TObject; Button: TUDBtnType);
begin
  if ReadOnly then MessageBeep(0)
    else
    begin
      if Assigned(fOnUpDownChanging) then
        fOnUpDownChanging(Self, GetShiftStateSp, Button);
      if Button=btNext then
        Value := CheckValue(Value + FIncrement)
      else
        Value := CheckValue(Value - FIncrement);
    end;
end;

procedure TWinSpinEdit.InitPosition(Sender: TObject; Button:
  TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FButton.Position:=0;
end;

procedure TWinSpinEdit.WMPaste(var Message: TWMPaste);
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;

procedure TWinSpinEdit.WMCut(var Message: TWMPaste);   
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;

procedure TWinSpinEdit.CMExit(var Message: TCMExit);
begin
  inherited;
  if CheckValue (Value) <> Value then
    SetValue (CheckValue (Value));
end;

function TWinSpinEdit.GetValue: Int64;
begin
  try
    Result := StrToInt64 (Text);
  except
    //Value:=FMinValue;
    Result := FMinValue;
    //if AutoSelect and not (csLButtonDown in ControlState) then
    //  SelectAll;
  end;
end;

procedure TWinSpinEdit.SetValue (NewValue: Int64);
begin
  Text := IntToStr (NewValue);//CheckValue (NewValue));
end;

function TWinSpinEdit.CheckValue (NewValue: Int64): Int64;
begin
  Result := NewValue;
  if (FMaxValue <> FMinValue) then
  begin
    if NewValue < FMinValue then
      Result := FMinValue
    else if NewValue > FMaxValue then
      Result := FMaxValue;
  end;
end;

procedure TWinSpinEdit.CMEnter(var Message: TCMGotFocus);
begin
  if AutoSelect and not (csLButtonDown in ControlState) then
    SelectAll;
  inherited;
end;

end.
