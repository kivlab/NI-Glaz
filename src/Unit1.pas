// NI Glaz - Reminder of the need to rest when you're working for PC

// Copyright (C) 2002-2015 - Nikolai Ivanov (http://www.kivlab.com/)

// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software Foundation,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Buttons, Spin, SafeINIFiles, ExtCtrls, ShellAPI,
  CoolTrayIcon, TextTrayIcon, Menus, Bass, Registry, ImgList, ActiveX, ShlObj,
  DKLang;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    TrackBar1: TTrackBar;
    Label2: TLabel;
    Edit1: TEdit;
    SpeedButton1: TSpeedButton;
    Label3: TLabel;
    Edit2: TEdit;
    SpeedButton2: TSpeedButton;
    GroupBox2: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    SpeedButton3: TSpeedButton;
    Label6: TLabel;
    SpeedButton4: TSpeedButton;
    TrackBar2: TTrackBar;
    Edit3: TEdit;
    Edit4: TEdit;
    CheckBox1: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    Label7: TLabel;
    SpinEdit1: TSpinEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    OpenDialog1: TOpenDialog;
    Timer1: TTimer;
    TextTrayIcon1: TTextTrayIcon;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    N11: TMenuItem;
    N12: TMenuItem;
    N13: TMenuItem;
    StaticText1: TStaticText;
    Button1: TButton;
    Button2: TButton;
    StaticText2: TStaticText;
    Button3: TButton;
    Button4: TButton;
    FontDialog1: TFontDialog;
    ColorDialog1: TColorDialog;
    CheckBox6: TCheckBox;
    Timer2: TTimer;
    ImageList1: TImageList;
    dklcMain: TDKLanguageController;
    N5: TMenuItem;
    mLanguage: TMenuItem;
    N14: TMenuItem;
    function MinToStr(minutes: integer): string;
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure CheckBox5Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TextTrayIcon1Startup(Sender: TObject; var ShowMainForm: Boolean);
    procedure N1Click(Sender: TObject);
    procedure TextTrayIcon1MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: integer);
    procedure TextTrayIcon1BalloonHintClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure CheckBox6Click(Sender: TObject);
    procedure TextTrayIcon1DblClick(Sender: TObject);
    procedure TextTrayIcon1Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure wait(sec: integer);
    // Sound-Begin
    procedure PlayMusic(filename: string; loop: Boolean);
    procedure StopMusic;
    // Sound-End
    procedure N11Click(Sender: TObject);
    procedure N10Click(Sender: TObject);
    procedure N12Click(Sender: TObject);
    procedure N13Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure UpdateStateNotify(Sender: TObject);
    procedure N14Click(Sender: TObject);
  private
    { Private declarations }
    strs: HSTREAM;
    TimeLeft, TimeToWork, TimeToRest: Integer;
    function GetSpecFolder(nFolder: integer): string;
    procedure PauseOrStart;
    function FileVersion: string;
    // Updates form interface
    procedure UpdateState;
     // Language item click handler
    procedure LanguageItemClick(Sender: TObject);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const
  RegK = '\Software\Microsoft\Windows\CurrentVersion\Run';
  { registry keys to start with Windows }
  RegK2 = '\Software\NI Software\NI Glaz';
  RegV = 'NI Glaz';

var
  workmode: Boolean = false;
  notwork: integer = 0;
  soundok: Boolean = true;
  waiting: Boolean = false;
  ppath, appdata: string;
  PAutoStart: Boolean = false;

  function _IntToStr(i, Wide: Cardinal): string;
  var
    i1: Cardinal;
  begin
    Result := '';
    repeat
      i1 := i mod 10;
      i := i div 10;
      Result := char(i1 + ord('0')) + Result;
      dec(Wide);
    until (Wide < 1) and (i < 1)
  end;

  function UC(s: string): string;
  var
    i: integer;
    st: string;
  begin
    try
      st := s;
      if st <> '' then
      begin
        for i := 1 to length(st) do
          st[i] := UpCase(st[i])
      end;
    finally
      Result := st
    end;
  end;

  procedure ColToRGB(Color: TColor; var r, g, b: byte);
  begin
    r := byte(Color);
    g := byte(Color shr 8);
    b := byte(Color shr 16);
  end;

  function DColor(c: TColor): TColor;
  var
    r, g, b: byte;
    col: TColor;
  begin
    col := clNone;
    try
      ColToRGB(c, r, g, b);
      r := 255 - r;
      g := 255 - g;
      b := 255 - b;
      col := RGB(r, g, b);
    finally
      Result := col
    end;
  end;

// Version begin
function GetVersion(const FileName: String = '';
  const Fmt: String = '%d.%d.%d.%d'): String;
var
  sFileName: String;
  iBufferSize: DWORD;
  iDummy: DWORD;
  pBuffer: Pointer;
  pFileInfo: Pointer;
  iVer: array [1 .. 4] of Word;
begin
  // set default value
  Result := '';
  // get filename of exe/dll if no filename is specified
  sFileName := FileName;
  if (sFileName = '') then
  begin
    // prepare buffer for path and terminating #0
    SetLength(sFileName, MAX_PATH + 1);
    SetLength(sFileName, GetModuleFileName(hInstance, PChar(sFileName),
      MAX_PATH + 1));
  end;
  // get size of version info (0 if no version info exists)
  iBufferSize := GetFileVersionInfoSize(PChar(sFileName), iDummy);
  if (iBufferSize > 0) then
  begin
    GetMem(pBuffer, iBufferSize);
    try
      // get fixed file info (language independent)
      GetFileVersionInfo(PChar(sFileName), 0, iBufferSize, pBuffer);
      VerQueryValue(pBuffer, '\', pFileInfo, iDummy);
      // read version blocks
      iVer[1] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
      iVer[2] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
      iVer[3] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
      iVer[4] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
    finally
      FreeMem(pBuffer);
    end;
    // format result string
    Result := Format(Fmt, [iVer[1], iVer[2], iVer[3], iVer[4]]);
  end;
end;

function TForm1.FileVersion: string;
var
  v: string;
  i: integer;
begin
  try
    v := '';
    v := GetVersion;
    if length(v) > 4 then
      for i := 1 to 2 do
        if copy(v, length(v) - 1, 2) = '.0' then
          delete(v, length(v) - 1, 2);
  finally
    Result := v
  end;
end;
// Version end

// Sound-Begin
procedure TForm1.PlayMusic(filename: string; loop: Boolean);
var
  f: PChar;
  l: dword;
begin
  if soundok then
  begin
    BASS_ChannelStop(strs);
    f := PChar(filename);
    if loop then
      l := 4
    else
      l := 0;
    strs := BASS_StreamCreateFile(false, f, 0, 0, l + BASS_UNICODE);
    BASS_ChannelPlay(strs, false)
  end;
end;

procedure TForm1.StopMusic;
begin
  if soundok then
    BASS_ChannelStop(strs);
end;
// Sound-End

// delay on sec seconds
procedure TForm1.wait(sec: integer);
var
  h: THandle;
  i: integer;
begin
  if sec < 1 then
    exit;
  for i := 1 to sec * 10 do
  begin
    Application.ProcessMessages;
    h := CreateEvent(nil, true, false, '');
    WaitForSingleObject(h, 100);
    CloseHandle(h);
    Application.ProcessMessages
  end;
end;

function TForm1.MinToStr(minutes: integer): string;
var
  h, m: integer;
  s: string;
begin
  try
    s := '0 ' + DKLangConstW('Shour') + ' 00 ' + DKLangConstW('Smin');
    h := minutes div 60;
    m := minutes mod 60;
    s := IntToStr(h) + ' ' + DKLangConstW('Shour') + ' ' + _IntToStr(m, 2) + ' ' + DKLangConstW('Smin');
  finally
    Result := s
  end;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  Label1.Caption := DKLangConstW('Sworktime') + ': ' + MinToStr(TrackBar1.Position)
end;

procedure TForm1.TrackBar2Change(Sender: TObject);
begin
  Label4.Caption := DKLangConstW('Sresttime') + ': ' + MinToStr(TrackBar2.Position)
end;

procedure TForm1.UpdateState;
const
  awsModified: Array[Boolean] of UnicodeString = ('', '*');
  //---
  procedure UpdateLanguageMark;
  var
    i: Integer;
    CurLang: LANGID; // To avoid excess synch calls
  begin
    CurLang := LangManager.LanguageID;
    for i := 0 to mLanguage.Count-1 do
      with mLanguage[i] do Checked := Tag=CurLang;
  end;
  //---
begin
  // Update language menu
  UpdateLanguageMark;
end;

procedure TForm1.UpdateStateNotify(Sender: TObject);
begin
  UpdateState;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Reg: TRegistry;
  IniFile: TSafeIniFile;
  //
  procedure CreateLanguageMenu;
    var
      i: Integer;
      mi: TMenuItem;
  begin
    for i := 0 to LangManager.LanguageCount-1 do begin
      mi := NewItem(LangManager.LanguageNames[i], 0, False, True, LanguageItemClick, 0, '');
      mi.Tag := LangManager.LanguageIDs[i];
      mLanguage.Add(mi);
    end;
  end;
  //
begin
  try
    soundok := true;
    if not BASS_Init(1, 44100, 0, Handle, nil) then
      soundok := false
  except
    soundok := false
  end;
  try
    // Scan for language files in the app directory and register them in the LangManager object
    LangManager.ScanForLangFiles(ExtractFileDir(ParamStr(0)), '*.lng', False);
     // Create available languages menu
    CreateLanguageMenu;
     // Update interface elements
    UpdateState;
  except end;
  try
    TrackBar1Change(Self);
    TrackBar2Change(Self);
    ppath := ExtractFilePath(Application.ExeName);
    appdata := GetSpecFolder(CSIDL_APPDATA) + '\NI Glaz\';
    if not DirectoryExists(appdata) then
      if not ForceDirectories(appdata) then
        appdata := ppath;
  except
  end;
  { cheking start with Windows }
  try
    PAutoStart := false;
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey(RegK, true) then
      begin
        try
          if Reg.ValueExists(RegV) then
          begin
            N8.Checked := true;
            PAutoStart := true;
          end;
          Reg.CloseKey;
        except
        end;
      end;
    finally
      if Assigned(Reg) then Reg.Free;
      inherited;
    end;
  except
  end;
  try // INI-file reading
    IniFile := TSafeIniFile.Create(appdata + 'glaz.ini');
    // Work
    TimeToWork := IniFile.ReadInteger('Work', 'Time', 45);
    TrackBar1.Position := TimeToWork;
    Edit1.Text := IniFile.ReadWideString('Work', 'Msg', DKLangConstW('Sworkmsg'));
    Edit2.Text := IniFile.ReadWideString('Work', 'File', ppath + 'alarm.wav');
    StaticText1.Color := IniFile.ReadColor('Work', 'BgColor',
      StaticText1.Color);
    StaticText1.Font := IniFile.ReadFont('Work', 'Font', StaticText1.Font);
    CheckBox6.Checked := IniFile.ReadBool('Work', 'Border', true);
    TextTrayIcon1.Color := StaticText1.Color;
    TextTrayIcon1.Font := StaticText1.Font;
    TextTrayIcon1.Border := CheckBox6.Checked;
    TextTrayIcon1.IconVisible := true;
    // Rest
    TimeToRest := IniFile.ReadInteger('Rest', 'Time', 15);
    TrackBar2.Position := TimeToRest;
    Edit3.Text := IniFile.ReadWideString('Rest', 'Msg', DKLangConstW('Srestmsg'));
    Edit4.Text := IniFile.ReadWideString('Rest', 'File', ppath + 'alarm.wav');
    StaticText2.Color := IniFile.ReadColor('Rest', 'BgColor',
      StaticText2.Color);
    StaticText2.Font := IniFile.ReadFont('Rest', 'Font', StaticText2.Font);
    // Param
    CheckBox1.Checked := IniFile.ReadBool('Param', 'ExtPlayer', false);
    CheckBox3.Checked := IniFile.ReadBool('Param', 'BaloonHints', false);
    CheckBox4.Checked := IniFile.ReadBool('Param', 'MonitorPower', false);
    CheckBox5.Checked := IniFile.ReadBool('Param', 'UserActivity', false);
    SpinEdit1.Value := IniFile.ReadInteger('Param', 'UATime', 15);
    // LanguageID
    LangManager.LanguageID := IniFile.ReadInteger('Params', 'LanguageID', LangManager.LanguageID);
    UpdateState;
  finally
    FreeAndNil(IniFile);
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
    Reg: TRegistry;
    progpath: string;
    IniFile: TSafeIniFile;
begin
  { create / delete autostart registry key }
  try
    if N8.Checked <> PAutoStart then
    begin { * }
      progpath := Application.ExeName;
      Reg := TRegistry.Create;
      try
        Reg.RootKey := HKEY_CURRENT_USER;
        if Reg.OpenKey(RegK, true) then
        begin
          try
            if N8.Checked then
            begin { create key }
              Reg.WriteString(RegV, progpath);
            end
            else
            begin { delete key }
              if Reg.ValueExists(RegV) then
                Reg.DeleteValue(RegV);
            end;
            Reg.CloseKey;
          except
          end;
        end;
      finally
        if Assigned(Reg) then Reg.Free;
        inherited;
      end;
    end; { * }
  except
  end;
  try // INI - saving settings
    IniFile := TSafeIniFile.Create(appdata + 'glaz.ini');
    // Work
    IniFile.WriteInteger('Work', 'Time', TimeToWork);
    IniFile.WriteWideString('Work', 'Msg', Edit1.Text);
    IniFile.WriteWideString('Work', 'File', Edit2.Text);
    IniFile.WriteColor('Work', 'BgColor', StaticText1.Color);
    IniFile.WriteFont('Work', 'Font', StaticText1.Font);
    IniFile.WriteBool('Work', 'Border', CheckBox6.Checked);
    // Rest
    IniFile.WriteInteger('Rest', 'Time', TimeToRest);
    IniFile.WriteWideString('Rest', 'Msg', Edit3.Text);
    IniFile.WriteWideString('Rest', 'File', Edit4.Text);
    IniFile.WriteColor('Rest', 'BgColor', StaticText2.Color);
    IniFile.WriteFont('Rest', 'Font', StaticText2.Font);
    // Param
    IniFile.WriteBool('Param', 'ExtPlayer', CheckBox1.Checked);
    IniFile.WriteBool('Param', 'BaloonHints', CheckBox3.Checked);
    IniFile.WriteBool('Param', 'MonitorPower', CheckBox4.Checked);
    IniFile.WriteBool('Param', 'UserActivity', CheckBox5.Checked);
    IniFile.WriteInteger('Param', 'UATime', SpinEdit1.Value);
    // LanguageID
    IniFile.WriteInteger('Params', 'LanguageID', LangManager.LanguageID);
  finally
    FreeAndNil(IniFile);
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Form1.ActiveControl := BitBtn1;
end;

function TForm1.GetSpecFolder(nFolder: integer): string;
  var
    Allocator: IMalloc;
    SpecialDir: PItemIdList;
    FBuf: array [0 .. MAX_PATH] of char;
begin
  Result := '';
  try
    if SHGetMalloc(Allocator) = NOERROR then
    begin
      SHGetSpecialFolderLocation(Form1.Handle, nFolder, SpecialDir);
      SHGetPathFromIDList(SpecialDir, @FBuf[0]);
      Allocator.Free(SpecialDir);
      Result := string(FBuf);
    end;
  except
    Result := '';
  end;
end;

procedure TForm1.LanguageItemClick(Sender: TObject);
begin
  // We stored language ID in Tag of each menu item (which is Sender here)
  LangManager.LanguageID := (Sender as TComponent).Tag;
  UpdateState;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  Edit1.Text := ''
end;

procedure TForm1.SpeedButton3Click(Sender: TObject);
begin
  Edit3.Text := ''
end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    Edit2.Text := OpenDialog1.filename
end;

procedure TForm1.SpeedButton4Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    Edit4.Text := OpenDialog1.filename
end;

procedure TForm1.CheckBox5Click(Sender: TObject);
begin
  if CheckBox5.Checked then
  begin
    Label7.Enabled := true;
    SpinEdit1.Enabled := true
  end
  else
  begin
    Label7.Enabled := false;
    SpinEdit1.Enabled := false
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  press: Boolean;
  s, f: string;
label l1, l2, l3; // :)
// --------------------------
  function SecondsIdle: dword;
  var
    liInfo: TLastInputInfo;
  begin
    liInfo.cbSize := SizeOf(TLastInputInfo);
    GetLastInputInfo(liInfo);
    Result := (GetTickCount - liInfo.dwTime) DIV 1000;
  end;
// --------------------------
begin
  try
    Timer1.Enabled := false;
    if Timer2.Enabled then
    begin
      Timer2.Enabled := False;
      PauseOrStart;
      exit
    end;
    if TextTrayIcon1.Tag = 1 then
    begin
      TextTrayIcon1.Tag := 0;
      goto l1
    end;
    if Timer1.Interval <= 100 then
    begin
      Timer1.Interval := 60000;
      TimeLeft := TimeToWork;
      workmode := true;
      exit
    end;
  l3:;
    if TimeLeft < 1 then
    begin // 1 - if time is over
      // produce the necessary action - showing messages, run files, on-off monitor
      Timer2.Enabled := true;
      if not workmode then
      begin
        s := Edit1.Text;
        f := Edit2.Text
      end
      else
      begin
        s := Edit3.Text;
        f := Edit4.Text
      end;
      if (f <> '') and (FileExists(f)) then
      begin
        if ((not CheckBox1.Checked) and
          ( { music files } (UC(ExtractFileExt(f)) = '.MP3') or
          (UC(ExtractFileExt(f)) = '.WAV')))
        then { play }
          PlayMusic(f, true)
        else
          ShellExecute(0, nil, PChar(f), nil, nil, SW_RESTORE);
      end;
      // turn on monitor
      if CheckBox4.Checked and not workmode then
        SendMessage(Form1.Handle, WM_SYSCOMMAND, SC_MONITORPOWER, -1);
      // show message
      TextTrayIcon1.Enabled := false;
      if s <> '' then
        if CheckBox3.Checked then
        begin { baloonhints }
          TextTrayIcon1.ShowBalloonHint(Form1.Caption, s, bitInfo, 30);
          TextTrayIcon1.Tag := 1;
          goto l2
        end
        else
          MessageBox(Handle, PChar(s), PChar(Form1.Caption),
            MB_ICONINFORMATION + MB_OK + MB_TOPMOST);
    l1:;
      TextTrayIcon1.Enabled := true;
      Timer2.Enabled := false;
      StopMusic;
      // turn off monitor
      if CheckBox4.Checked and workmode then
      begin
        waiting := true;
        wait(3);
        waiting := false;
        SendMessage(Form1.Handle, WM_SYSCOMMAND, SC_MONITORPOWER, 2);
      end;
      // change the mode from rest to work or vice versa
      workmode := not workmode;
      notwork := 0;
      if workmode then
        TimeLeft := TimeToWork
      else
        TimeLeft := TimeToRest;
      if workmode then
      begin
        TextTrayIcon1.Color := StaticText1.Color;
        TextTrayIcon1.Font := StaticText1.Font
      end
      else
      begin
        TextTrayIcon1.Color := StaticText2.Color;
        TextTrayIcon1.Font := StaticText2.Font
      end;
    end // 1 - end
    else
    begin // 2 - reduce the time counter
      Dec(TimeLeft);
      // if there is a check of the user's activity
      if workmode and CheckBox5.Checked then
      begin
        press := false;
        if SecondsIdle < 59 then
          press := true;
        if not press then
          inc(notwork)
        else
          notwork := 0;
        if notwork = SpinEdit1.Value then
          Inc(TimeLeft, SpinEdit1.Value);
        if notwork > SpinEdit1.Value then
          Inc(TimeLeft);
      end;
      if TimeLeft = 0 then
      begin
        TextTrayIcon1.Text := '0';
        goto l3
      end;
    end; // 2 - end
  l2:;
  finally
    if TextTrayIcon1.Tag = 0 then
      Timer1.Enabled := true;
    try
      if TimeLeft > 99 then
        TextTrayIcon1.Text := IntToStr(TimeLeft div 60) + DKLangConstW('Sh')
      else
        TextTrayIcon1.Text := IntToStr(TimeLeft)
    except
    end
  end;
end;

procedure TForm1.TextTrayIcon1Startup(Sender: TObject;
  var ShowMainForm: Boolean);
begin
  ShowMainForm := false;
end;

procedure TForm1.N1Click(Sender: TObject);
begin
  Close
end;

procedure TForm1.TextTrayIcon1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
var
  s: string;
begin
  if Timer1.Enabled then
  begin
    if workmode then
      s := DKLangConstW('Sworktimes')
    else
      s := DKLangConstW('Sresttimes');
    TextTrayIcon1.Hint := 'NI Glaz - ' + s + ' ' + MinToStr(TimeLeft)
  end
  else
    TextTrayIcon1.Hint := 'NI Glaz - ' + DKLangConstW('Spauset')
end;

procedure TForm1.TextTrayIcon1BalloonHintClick(Sender: TObject);
begin
  Timer2.Enabled := false;
  StopMusic;
  if workmode then
  begin
    TextTrayIcon1.Color := StaticText1.Color;
    TextTrayIcon1.Font := StaticText1.Font
  end
  else
  begin
    TextTrayIcon1.Color := StaticText2.Color;
    TextTrayIcon1.Font := StaticText2.Font
  end;
  Timer1Timer(Self)
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  c: TStaticText;
begin
  if Sender = Button1 then
    c := StaticText1
  else
    c := StaticText2;
  ColorDialog1.Color := c.Color;
  if ColorDialog1.Execute then
    c.Color := ColorDialog1.Color
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  c: TStaticText;
begin
  if Sender = Button2 then
    c := StaticText1
  else
    c := StaticText2;
  FontDialog1.Font := c.Font;
  if FontDialog1.Execute then
    c.Font := FontDialog1.Font
end;

procedure TForm1.CheckBox6Click(Sender: TObject);
begin
  if CheckBox6.Checked then
  begin
    StaticText1.BorderStyle := sbsSingle;
    StaticText2.BorderStyle := sbsSingle
  end
  else
  begin
    StaticText1.BorderStyle := sbsNone;
    StaticText2.BorderStyle := sbsNone
  end;
end;

procedure TForm1.TextTrayIcon1DblClick(Sender: TObject);
var
  se1: integer;
  e1, e2, e3, e4: string;
  stc1, stc2: TColor;
  stf1, stf2: TFont;
  c1, c3, c4, c5, c6: Boolean;
begin
  if Timer2.Enabled then
    exit;
  if N3.Checked then
    exit;
  stf1 := TFont.Create();
  stf2 := TFont.Create();
  try
    TextTrayIcon1.Enabled := false;
    Timer1.Enabled := false;
    // remember settings
    se1 := SpinEdit1.Value;
    e1 := Edit1.Text;
    e2 := Edit2.Text;
    e3 := Edit3.Text;
    e4 := Edit4.Text;
    stc1 := StaticText1.Color;
    stc2 := StaticText2.Color;
    stf1.Assign(StaticText1.Font);
    stf2.Assign(StaticText2.Font);
    c1 := CheckBox1.Checked;
    c3 := CheckBox3.Checked;
    c4 := CheckBox4.Checked;
    c5 := CheckBox5.Checked;
    c6 := CheckBox6.Checked;
    if Form1.ShowModal <> mrOk then
    begin // restore settings
      TrackBar1.Position := TimeToWork;
      TrackBar2.Position := TimeToRest;
      SpinEdit1.Value := se1;
      Edit1.Text := e1;
      Edit2.Text := e2;
      Edit3.Text := e3;
      Edit4.Text := e4;
      StaticText1.Color := stc1;
      StaticText2.Color := stc2;
      StaticText1.Font := stf1;
      StaticText2.Font := stf2;
      CheckBox1.Checked := c1;
      CheckBox3.Checked := c3;
      CheckBox4.Checked := c4;
      CheckBox5.Checked := c5;
      CheckBox6.Checked := c6;
    end
    else  // if click OK
    begin // new color icons in the system tray and restart the timer
      workmode := true;
      Timer1.Interval := 100; // onTimer notice the change interval and makes adjustments
      TimeToWork := TrackBar1.Position;
      TimeLeft := TimeToWork;
      TimeToRest := TrackBar2.Position;
      TextTrayIcon1.Color := StaticText1.Color;
      TextTrayIcon1.Font := StaticText1.Font;
      TextTrayIcon1.Border := (StaticText1.BorderStyle = sbsSingle);
    end;
  finally
    FreeAndNil(stf1);
    FreeAndNil(stf2);
    TextTrayIcon1.Enabled := true;
    Timer1.Enabled := true
  end;
end;

procedure TForm1.TextTrayIcon1Click(Sender: TObject);
begin
  N3.Checked := not N3.Checked;
  PauseOrStart;
end;

procedure TForm1.PauseOrStart;
begin
  if waiting then
    exit;
  Timer1.Enabled := not N3.Checked;
  N6.Enabled := Timer1.Enabled;
  Timer2.Enabled := not Timer1.Enabled;
  if not N3.Checked then
    TextTrayIcon1.Text := IntToStr(TimeLeft)
  else
    TextTrayIcon1.Text := 'P';
  if not Timer2.Enabled then
  begin
    if workmode then
    begin
      TextTrayIcon1.Color := StaticText1.Color;
      TextTrayIcon1.Font := StaticText1.Font
    end
    else
    begin
      TextTrayIcon1.Color := StaticText2.Color;
      TextTrayIcon1.Font := StaticText2.Font
    end;
  end;
end;

procedure TForm1.N3Click(Sender: TObject);
begin
  PauseOrStart;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  TextTrayIcon1.Color := DColor(TextTrayIcon1.Color);
  TextTrayIcon1.Font.Color := DColor(TextTrayIcon1.Font.Color)
end;

procedure TForm1.N11Click(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://www.kivlab.com/', nil, nil, 1);
end;

procedure TForm1.N10Click(Sender: TObject);
begin
  ShellExecute(0, nil, PChar('mailto:support@kivlab.com?subject=NI%20Glaz%20' + FileVersion),
    nil, nil, 1);
end;

procedure TForm1.N12Click(Sender: TObject);
var
  str: String;
begin
  try
    Timer1.Enabled := false;
    TextTrayIcon1.Enabled := false;
    str := '"NI Glaz ' + FileVersion + '" (11.10.2015) [Freeware] ' + #13 + '' + #13 + DKLangConstW('Spinfo')
      + #13 + '' + #13 + '' + 'Support: support@kivlab.com' + #13 +
      'WWW: http://www.kivlab.com/soft/ ' + #13#13 +
      'Copyright © 2002-2015 by Nikolay Ivanov. ' + #13#13 +
      'Third Party Components:' + #13 +
      '- DKLang Localization Package (http://www.dk-soft.org/)' + #13 +
      '- CoolTrayIcon package (http://http://subsimple.com)' + #13 +
      '- BASS audio library (http://www.un4seen.com/)';
    MessageBox(0, PChar(str), ' About', MB_OK + MB_ICONINFORMATION +
      MB_TOPMOST);
  finally
    Timer1.Enabled := true;
    TextTrayIcon1.Enabled := true
  end;
end;

procedure TForm1.N13Click(Sender: TObject);
var
  helpfile: String;
begin
  { path to the help file }
  helpfile := ppath + 'help.chm';
  if FileExists(helpfile) then
    ShellExecute(0, nil, PChar(helpfile), nil, nil, 3);
end;

procedure TForm1.N14Click(Sender: TObject);
begin
  ShellExecute(0, nil, 'http://www.kivlab.com/donate/', nil, nil, 1);
end;

end.
