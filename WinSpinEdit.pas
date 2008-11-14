unit WinSpinEdit;

{
Copyright (c) 2008, Shinya Okano<xxshss@yahoo.co.jp>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

3. Neither the name of the authors nor the names of its contributors
   may be used to endorse or promote products derived from this
   software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

--
license: New BSD License
web: http://www.bitbucket.org/tokibito/winspinedit/overview/
}

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
    FUpDown: TUpDown;
    FEditable: Boolean;
    FOnUpDownChanging: TOnUpDownChanging;
    procedure Clean;
    function GetValue: Int64;
    procedure SetValue(NewValue: Int64);
    function GetShiftState: TShiftState;
    procedure ResizeEditRect;
    function GetMinHeight: Integer;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure CMEnter(var Message: TCMGotFocus); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure WMPaste(var Message: TWMPaste); message WM_PASTE;
    procedure WMCut(var Message: TWMCut); message WM_CUT;
  protected
    function IsValidChar(Key: Char): Boolean; virtual;
    procedure UpDownClick(Sender: TObject; Button: TUDBtnType); virtual;
    procedure UpDownMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property UpDown: TUpDown read FUpDown;
  published
    property Align;
    property Anchors;
    property AutoSelect;
    property AutoSize;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragMode;
    property Editable: Boolean read FEditable write FEditable default True;
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
      read FOnUpDownChanging write FOnUpDownChanging;
  end;

procedure Register;

implementation

constructor TWinSpinEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUpDown := TUpDown.Create(Self);
  FUpDown.Width := 15;
  FUpDown.Height := 18;
  FUpDown.Max := 32767;
  FUpDown.Min := (-32768);
  FUpDown.Visible := True;
  FUpDown.Parent := Self;
  FUpDown.OnClick := UpDownClick;
  FUpDown.OnMouseUp := UpDownMouseUp;
  Value := 0;
  ControlStyle := ControlStyle - [csSetCaption];
  FIncrement := 1;
  FEditable := True;
end;

destructor TWinSpinEdit.Destroy;
begin
  FUpDown := nil;
  inherited Destroy;
end;

procedure TWinSpinEdit.Clean;
var
  CleanedValue: Int64;
begin
  CleanedValue := StrToInt64Def(Text, FMinValue);
  if FMaxValue <> FMinValue then
  begin
    if CleanedValue > FMaxValue then
      CleanedValue := FMaxValue;
    if CleanedValue < FMinValue then
      CleanedValue := FMinValue;
  end;
  if IntToStr(CleanedValue) <> Text then
    Value := CleanedValue;
end;

function TWinSpinEdit.GetValue: Int64;
begin
  Clean;
  Result := StrToInt64(Text);
end;

procedure TWinSpinEdit.SetValue(NewValue: Int64);
begin
  Text := IntToStr(NewValue);
end;

function TWinSpinEdit.GetShiftState: TShiftState;
begin
  Result := [];
  if GetKeyState(VK_SHIFT) and $8000 <> 0 then
    Result := Result + [ssShift];
  if GetKeyState(VK_CONTROL) and $8000 <> 0 then
    Result := Result + [ssCtrl];
  if GetKeyState(VK_LBUTTON) and $8000 <> 0 then
    Result := Result + [ssLeft];
  if GetKeyState(VK_RBUTTON) and $8000 <> 0 then
    Result := Result + [ssRight];
  if GetKeyState(VK_MBUTTON) and $8000 <> 0 then
    Result := Result + [ssMiddle];
  if [ssLeft, ssRight] <= Result then
    Result := Result + [ssDouble];
end;

procedure TWinSpinEdit.UpDownClick(Sender: TObject; Button: TUDBtnType);
begin
  if ReadOnly then
    MessageBeep(0)
  else
    begin
      if Assigned(FOnUpDownChanging) then
        FOnUpDownChanging(Self, GetShiftState, Button);
      if Button = btNext then
        Value := Value + FIncrement
      else
        Value := Value - FIncrement;
    end;
end;

procedure TWinSpinEdit.UpDownMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FUpDown.Position := 0;
  if AutoSelect and not (csLButtonDown in ControlState) then
    SelectAll;
end;

procedure TWinSpinEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_UP then UpDownClick(Self, btNext)
  else if Key = VK_DOWN then UpDownClick(Self, btPrev);
  inherited KeyDown(Key, Shift);
end;

procedure TWinSpinEdit.KeyPress(var Key: Char);
begin
  if not IsValidChar(Key) then
  begin
    Key := #0;
    MessageBeep(0);
  end;
  if Key <> #0 then
    inherited KeyPress(Key);
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

{ resize edit }
procedure TWinSpinEdit.ResizeEditRect;
var
  Loc: TRect;
begin
  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));
  Loc.Bottom := ClientHeight + 1;  { +1 is workaround for windows paint bug }
  Loc.Right := ClientWidth - FUpDown.Width - 1;
  Loc.Top := 0;
  Loc.Left := 0;
  SendMessage(Handle, EM_SETRECTNP, 0, LongInt(@Loc));
end;

{ change edit styles }
procedure TWinSpinEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or ES_MULTILINE or WS_CLIPCHILDREN;
end;

procedure TWinSpinEdit.CreateWnd;
begin
  inherited CreateWnd;
  ResizeEditRect;
end;

procedure TWinSpinEdit.WMSize(var Message: TWMSize);
var
  MinHeight: Integer;
begin
  inherited;
  MinHeight := GetMinHeight;
  if Height < MinHeight then
    Height := MinHeight
  else if FUpDown <> nil then
  begin
    if NewStyleControls and Ctl3D then
      FUpDown.SetBounds(Width - FUpDown.Width - 3, (-1), FUpDown.Width, Height - 2)
    else
      FUpDown.SetBounds(Width - FUpDown.Width, 1, FUpDown.Width, Height - 3);
    ResizeEditRect;
  end;
end;

procedure TWinSpinEdit.CMEnter(var Message: TCMGotFocus);
begin
  if AutoSelect and not (csLButtonDown in ControlState) then
    SelectAll;
  inherited;
end;

procedure TWinSpinEdit.CMExit(var Message: TCMExit);
begin
  Clean;
  inherited;
end;

procedure TWinSpinEdit.WMPaste(var Message: TWMPaste);
begin
  if not FEditable or ReadOnly then Exit;
  inherited;
end;

procedure TWinSpinEdit.WMCut(var Message: TWMPaste);
begin
  if not FEditable or ReadOnly then Exit;
  inherited;
end;

function TWinSpinEdit.IsValidChar(Key: Char): Boolean;
begin
{$IFDEF UNICODE}
  Result := CharInSet(Key, [DecimalSeparator, '+', '-', '0'..'9'])
{$ELSE}
  Result := (Key in [DecimalSeparator, '+', '-', '0'..'9'])
{$ENDIF}
      or ((Key < #32) and (Key <> Chr(VK_RETURN)));
  if not FEditable and Result and ((Key >= #32)
      or (Key = Char(VK_BACK)) or (Key = Char(VK_DELETE))) then
    Result := False;
end;

{ register components }
procedure Register;
begin
  RegisterComponents('nullpobug', [TWinSpinEdit]);
end;

end.