///*********************************************************************************************************************
///  $Id: DKL_ConstEditor.pas 2013-12-06 00:00:00Z bjm $
///---------------------------------------------------------------------------------------------------------------------
///  DKLang Localization Package
///  Copyright 2002-2013 DK Software, http://www.dk-soft.org
///*********************************************************************************************************************
///
/// The contents of this package are subject to the Mozilla Public License
/// Version 1.1 (the "License"); you may not use this file except in compliance
/// with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/
///
/// Alternatively, you may redistribute this library, use and/or modify it under the
/// terms of the GNU Lesser General Public License as published by the Free Software
/// Foundation; either version 2.1 of the License, or (at your option) any later
/// version. You may obtain a copy of the LGPL at http://www.gnu.org/copyleft/
///
/// Software distributed under the License is distributed on an "AS IS" basis,
/// WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
/// specific language governing rights and limitations under the License.
///
/// The initial developer of the original code is Dmitry Kann, http://www.dk-soft.org/
///
/// Upgraded to Delphi 2009 by Bruce J. Miller, rules-of-thumb.com Dec 2008
///
/// Upgraded to Delphi XE5 (for FireMonkey) by Bruce J. Miller, rules-of-thumb.com Nov 2013
///
///**********************************************************************************************************************
// Designtime project constant editor dialog declaration
//
//

unit DKL_ConstEditor;

interface

uses
  WinApi.Windows, System.SysUtils, System.Classes,
  VCL.Controls, VCL.Forms, VCL.Dialogs,VCL.StdCtrls, VCL.Grids,
  DKLang, {Edwin_Searchability}Vcl.Graphics{Edwin_Searchability end},
  System.Generics.Collections;

type
  TdDKL_ConstEditor = class(TForm)
    bCancel: TButton;
    bErase: TButton;
    bLoad: TButton;
    bOK: TButton;
    bSave: TButton;
    cbSaveToLangSource: TCheckBox;
    gMain: TStringGrid;
    lCount: TLabel;
    lDeleteHint: TLabel;
    edtSearch: TEdit;
    btnGotoFirstMatch: TButton;
    btnGotoNextMatch: TButton;
    lblSearchPos: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure bEraseClick(Sender: TObject);
    procedure bLoadClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure btnGotoFirstMatchClick(Sender: TObject);
    procedure btnGotoNextMatchClick(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure gMainDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure gMainKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure gMainMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure gMainSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  strict private
    function IsRowMatch(aRow: Integer; aSearchStr: string): Boolean;
  private
     // The constants being edited
    FConsts: TDKLang_Constants;
     // True if the constants are to be erased from the project resources
    FErase: Boolean;
    // Edwin_Searchability
    // Stores all the matching row numbers.
    FMatchingRows: TList<Integer>;
    FCurrentMatchingIndex: Integer;
    // Edwin_Searchability end.
     // Initializes the dialog
    procedure InitializeDialog(AConsts: TDKLang_Constants; bEraseAllowed: Boolean);
     // Updates the count info
    procedure UpdateCount;
     // Storing/restoring the settings
    procedure SaveSettings;
    procedure LoadSettings;
     // Updates gMain columns' widths so that they both fit into the client area
    procedure UpdateGridColumnWidths;
     // Raises an exception if entry (constant) index is not valid
    procedure CheckEntryIndexValidity(iIndex: Integer);
     // Ensures a virtual row is available at the end of the table
    procedure EnsureVirtualRowExists;
     // Returns True if the specified row has neither name nor value
    function  IsRowEmpty(iRow: Integer): Boolean;
     // Raises an exception if constant names are not valid (includes uniqueness checking)
    procedure CheckNamesValid;
     // Deletes the specified entry
    procedure DeleteEntry(iIndex: Integer);
     // Prop handlers
    function  GetEntryCount: Integer;
    function  GetEntryNames(Index: Integer): UnicodeString;
    function  GetEntryValues(Index: Integer; bEncoded: Boolean): UnicodeString;
    procedure SetEntryCount(iCount: Integer);
    procedure SetEntryNames(Index: Integer; const wsValue: UnicodeString);
    procedure SetEntryValues(Index: Integer; bEncoded: Boolean; const wsValue: UnicodeString);
    procedure PerformSearch;
    function GotoFirstMatchingRow: Boolean;
    procedure SetCurrentMatchingIndex(const Value: Integer);
    procedure ShowCurrentSearchLocation;
    procedure GotoNextMatchingRow(const aStep: Integer = 1);
  protected
    procedure DoClose(var Action: TCloseAction); override;
    procedure DoShow; override;
    procedure Resize; override;
  public
     // Props
     // -- Entry (constant) count
    property EntryCount: Integer read GetEntryCount write SetEntryCount;
     // -- Constant names by index
    property EntryNames[Index: Integer]: UnicodeString read GetEntryNames write SetEntryNames;
     // -- Constant names by index. If bEncoded=True, the constant value is represented 'encoded', with no literal
     //    control chars; if bEncoded=False, the value is represented 'as is', with linebreaks, tabs, etc. in it
    property EntryValues[Index: Integer; bEncoded: Boolean]: UnicodeString read GetEntryValues write SetEntryValues;
    // Pointer to FMatchingRows.
    property CurrentMatchingIndex: Integer read FCurrentMatchingIndex write SetCurrentMatchingIndex;
  end;

const
  SRegKey_DKLangConstEditor = 'Software\DKSoftware\DKLang\ConstEditor';

   // Show constant editor dialog
   //   AConsts       - The constants being edited
   //   bEraseAllowed - Entry: is erase allowed (ie constant resource exists); return: True if user has pressed Erase
   //                   button
  function EditConstants(AConsts: TDKLang_Constants; var bEraseAllowed: Boolean): Boolean;

implementation
{$R *.dfm}
uses System.Win.Registry, System.StrUtils;

const
   // gMain's column indexes
  IColIdx_Name  = 0;
  IColIdx_Value = 1;

  function EditConstants(AConsts: TDKLang_Constants; var bEraseAllowed: Boolean): Boolean;
  begin
    with TdDKL_ConstEditor.Create(Application) do
      try
        InitializeDialog(AConsts, bEraseAllowed);
        Result := ShowModal=mrOK;
        bEraseAllowed := FErase;
      finally
        Free;
      end;
  end;

procedure TdDKL_ConstEditor.FormCreate(Sender: TObject);
begin
  // Edwin_Searchability
  FMatchingRows := TList<Integer>.Create;
  FCurrentMatchingIndex := -1;
  lblSearchPos.Caption := '';

  // Allow pressing TAB to jump between columns.
  gMain.Options := gMain.Options + [goTabs];
  // Edwin_Searchability end.
end;

   //===================================================================================================================
   // TdDKL_ConstEditor
   //===================================================================================================================

  procedure TdDKL_ConstEditor.bEraseClick(Sender: TObject);
  begin
    if Application.MessageBox('Are you sure you want to delete the constants from project resources?', 'Confirm', MB_ICONEXCLAMATION or MB_OKCANCEL)=IDOK then begin
      FErase := True;
      ModalResult := mrOK;
    end;
  end;

  procedure TdDKL_ConstEditor.bLoadClick(Sender: TObject);

    procedure DoLoad(const wsFileName: UnicodeString);
    var
      SL: TStringList;
      i: Integer;
    begin
      SL := TStringList.Create;
      try
        SL.LoadFromFile(wsFileName);
        EntryCount := SL.Count;
        for i := 0 to SL.Count-1 do begin
          EntryNames [i]       := SL.Names[i];
          EntryValues[i, True] := SL.ValueFromIndex[i]; // Assume the value is already encoded in the file
        end;
      finally
        SL.Free;
      end;
    end;

  begin
    with TOpenDialog.Create(Self) do
      try
        DefaultExt := 'txt';
        Filter     := 'All files (*.*)|*.*';
        Options    := [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing];
        Title      := 'Select a text file to load from';
        if Execute then DoLoad(FileName);
      finally
        Free;
      end;
  end;

  procedure TdDKL_ConstEditor.bOKClick(Sender: TObject);
  var i: Integer;
  begin
     // Check that all names are valid
    CheckNamesValid;
     // Copy the constans from the editor back into FConsts
    FConsts.Clear;
    FConsts.AutoSaveLangSource := cbSaveToLangSource.Checked;
    for i := 0 to EntryCount-1 do FConsts.Add(EntryNames[i], EntryValues[i, False], []);
    ModalResult := mrOK;
  end;

  procedure TdDKL_ConstEditor.bSaveClick(Sender: TObject);

    procedure DoSave(const wsFileName: UnicodeString);
    var
      SL: TStringList;
      i: Integer;
    begin
      SL := TStringList.Create;
      try
        for i := 0 to EntryCount-1 do SL.Add(EntryNames[i]+'='+EntryValues[i, True]);
        SL.Sort;
        SL.SaveToFile(wsFileName);
      finally
        SL.Free;
      end;
    end;

  begin
    with TSaveDialog.Create(Self) do
      try
        DefaultExt := 'txt';
        Filter     := 'All files (*.*)|*.*';
        Options    := [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing];
        Title      := 'Select a text file to save to';
        if Execute then DoSave(FileName);
      finally
        Free;
      end;
  end;

procedure TdDKL_ConstEditor.btnGotoFirstMatchClick(Sender: TObject);
begin
  GotoNextMatchingRow(-1);
end;

procedure TdDKL_ConstEditor.btnGotoNextMatchClick(Sender: TObject);
begin
  GotoNextMatchingRow(1);
end;

  procedure TdDKL_ConstEditor.CheckEntryIndexValidity(iIndex: Integer);
  begin
    if (iIndex<0) or (iIndex>=EntryCount) then raise EDKLangError.CreateFmt('Invalid entry index (%d)', [iIndex]);
  end;

  procedure TdDKL_ConstEditor.CheckNamesValid;
  var
    SL: TStringList;
    ws: UnicodeString;
    i: Integer;
  begin
    SL := TStringList.Create;
    try
      SL.Sorted := True;
      for i := 0 to EntryCount-1 do begin
        ws := EntryNames[i];
        if ws='' then raise EDKLangError.Create('Constant name cannot be empty');
        if not IsValidIdent(ws) then raise EDKLangError.CreateFmt('Invalid constant name: "%s"', [ws]);
        if SL.IndexOf(ws)<0 then SL.Add(ws) else raise EDKLangError.CreateFmt('Duplicate constant name: "%s"', [ws]);
      end;
    finally
      SL.Free;
    end;
  end;

  procedure TdDKL_ConstEditor.DeleteEntry(iIndex: Integer);
  var i: Integer;
  begin
    CheckEntryIndexValidity(iIndex);
     // Shift the grid contents
    for i := iIndex to EntryCount-2 do begin
      EntryNames [i]       := EntryNames [i+1];
      EntryValues[i, True] := EntryValues[i+1, True];
    end;
     // Remove the last row
    EntryCount := EntryCount-1;  
  end;

  procedure TdDKL_ConstEditor.DoClose(var Action: TCloseAction);
  begin
    inherited DoClose(Action);
    SaveSettings;
  end;

  procedure TdDKL_ConstEditor.DoShow;
  begin
    inherited DoShow;
    LoadSettings;
  end;

  procedure TdDKL_ConstEditor.EnsureVirtualRowExists;
  var i: Integer;
  begin
     // Determine the index of last non-empty row
    i := gMain.RowCount-1;
    while (i>0) and IsRowEmpty(i) do Dec(i);
     // Set the number of rows
    EntryCount := i;
  end;

  function TdDKL_ConstEditor.GetEntryCount: Integer;
  begin
    Result := gMain.RowCount-2; // One for the header, one more for the virtual row
  end;

  function TdDKL_ConstEditor.GetEntryNames(Index: Integer): UnicodeString;
  begin
    CheckEntryIndexValidity(Index);
    Result := Trim(gMain.Cells[IColIdx_Name, Index+1]); // One more row to skip the header
  end;

  function TdDKL_ConstEditor.GetEntryValues(Index: Integer; bEncoded: Boolean): UnicodeString;
  begin
    CheckEntryIndexValidity(Index);
    Result := Trim(gMain.Cells[IColIdx_Value, Index+1]); // One more row to skip the header
    if not bEncoded then Result := DecodeControlChars(Result);
  end;


  procedure TdDKL_ConstEditor.gMainKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  begin
    if (Key=VK_DELETE) and (Shift=[ssCtrl]) and (gMain.Row<gMain.RowCount-1) then begin
      DeleteEntry(gMain.Row-1);
      Key := 0;
    end
    // Edwin_Searchability
    else if (Key = VK_ESCAPE) and (Shift = []) then
    begin
      Key := 0;
      ModalResult := mrCancel;
    end
    else if (Key = Ord('F')) and (Shift = [ssCtrl]) then
    begin
     edtSearch.SetFocus;
    end;
    // Edwin_Searchability end.
  end;

  procedure TdDKL_ConstEditor.gMainMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  begin
     // Believe mouse up is linked to column resizing...
    UpdateGridColumnWidths;
  end;

  procedure TdDKL_ConstEditor.gMainSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  begin
    EnsureVirtualRowExists;
    CheckNamesValid;
    UpdateCount;
  end;

  procedure TdDKL_ConstEditor.InitializeDialog(AConsts: TDKLang_Constants; bEraseAllowed: Boolean);
  var i: Integer;
      key: UnicodeString;
      keys: TList<UnicodeString>;
  begin
    FConsts                    := AConsts;
    cbSaveToLangSource.Checked := FConsts.AutoSaveLangSource;
    bErase.Enabled             := bEraseAllowed;
    FErase                     := False;
     // Setup the editor
    gMain.Cells[IColIdx_Name,  0] := 'Constant name';
    gMain.Cells[IColIdx_Value, 0] := 'Constant value';
     // Copy the constans into the editor
     // TDictionary is not sorted, so get keys and sort
    keys := TList<UnicodeString>.Create(FConsts.Keys);
    try
      keys.Sort;
      EntryCount := FConsts.Count;
      i :=0;
      for key in keys do begin
        EntryNames [i]        := FConsts[key].wsName;
        EntryValues[i, False] := FConsts[key].wsValue;
        inc(i);
      end;
    finally
      keys.Free;
    end;
     // Update count info
    UpdateCount;
  end;

  function TdDKL_ConstEditor.IsRowEmpty(iRow: Integer): Boolean;
  begin
    Result := (Trim(gMain.Cells[IColIdx_Name, iRow])='') and (Trim(gMain.Cells[IColIdx_Value, iRow])='');
  end;

  procedure TdDKL_ConstEditor.LoadSettings;
  var
    rif: TRegIniFile;
    rBounds: TRect;
  begin
    rif := TRegIniFile.Create(SRegKey_DKLangConstEditor);
    try
       // Restore form bounds
      rBounds := Rect(
        rif.ReadInteger('', 'Left',   MaxInt),
        rif.ReadInteger('', 'Top',    MaxInt),
        rif.ReadInteger('', 'Right',  MaxInt),
        rif.ReadInteger('', 'Bottom', MaxInt));
       // If all the coords are valid
      if (rBounds.Left<MaxInt) and (rBounds.Top<MaxInt) and (rBounds.Right<MaxInt) and (rBounds.Bottom<MaxInt) then
        BoundsRect := rBounds;
       // Load other settings
      gMain.ColWidths[IColIdx_Name] := rif.ReadInteger('', 'NameColWidth', gMain.ClientWidth div 2);
      UpdateGridColumnWidths;
    finally
      rif.Free;
    end;
  end;

  procedure TdDKL_ConstEditor.Resize;
  begin
    inherited Resize;
    UpdateGridColumnWidths;
  end;

  procedure TdDKL_ConstEditor.SaveSettings;
  var
    rif: TRegIniFile;
    rBounds: TRect;
  begin
    rif := TRegIniFile.Create(SRegKey_DKLangConstEditor);
    try
       // Store form bounds
      rBounds := BoundsRect;
      rif.WriteInteger('', 'Left',         rBounds.Left);
      rif.WriteInteger('', 'Top',          rBounds.Top);
      rif.WriteInteger('', 'Right',        rBounds.Right);
      rif.WriteInteger('', 'Bottom',       rBounds.Bottom);
       // Store other settings
      rif.WriteInteger('', 'NameColWidth', gMain.ColWidths[IColIdx_Name]);
    finally
      rif.Free;
    end;
  end;

  procedure TdDKL_ConstEditor.SetEntryCount(iCount: Integer);
  begin
    gMain.RowCount := iCount+2; // One for the header, one more for the virtual row
     // Cleanup the virtual row
    gMain.Cells[IColIdx_Name,  iCount+1] := '';
    gMain.Cells[IColIdx_Value, iCount+1] := '';
  end;

  procedure TdDKL_ConstEditor.SetEntryNames(Index: Integer; const wsValue: UnicodeString);
  begin
    CheckEntryIndexValidity(Index);
    gMain.Cells[IColIdx_Name, Index+1] := wsValue; // One more row to skip the header
  end;

  procedure TdDKL_ConstEditor.SetEntryValues(Index: Integer; bEncoded: Boolean; const wsValue: UnicodeString);
  var ws: UnicodeString;
  begin
    CheckEntryIndexValidity(Index);
    ws := wsValue;
    if not bEncoded then ws := EncodeControlChars(ws);
    gMain.Cells[IColIdx_Value, Index+1] := ws; // One more row to skip the header
  end;

  procedure TdDKL_ConstEditor.UpdateCount;
  begin
    lCount.Caption := Format('%d constants', [EntryCount]);
  end;

  procedure TdDKL_ConstEditor.UpdateGridColumnWidths;
  var iwClient, iwName: Integer;
  begin
    iwClient := gMain.ClientWidth;
    iwName   := gMain.ColWidths[IColIdx_Name];
     // Do not allow columns be narrower than 20 pixels
    if iwName<20 then iwName := 20
    else if iwName>iwClient-20 then iwName := iwClient-22;
     // Update column widths
    gMain.ColWidths[IColIdx_Name]  := iwName;
    gMain.ColWidths[IColIdx_Value] := iwClient-iwName-2;
  end;

procedure TdDKL_ConstEditor.gMainDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State:
    TGridDrawState);
var
  mySearch: string;
  myStr: string;
begin
  //Edwin_Searchability
  if (EntryCount < 1) or (ARow < 1) then
    Exit;

  //  if ACol = IColIdx_Name then
  //    myStr := gMain.Cells[IColIdx_Name, ARow]
  //  else
  //    myStr := gMain.Cells[IColIdx_Value, ARow];
  myStr := gMain.Cells[ACol, ARow];

  mySearch := Trim(edtSearch.Text);

  //highlight the matching items with red
  //if SameText(myStr, mySearch) or ContainsText(myStr, mySearch) then
  if FMatchingRows.Contains(ARow) then
  begin
    gMain.Canvas.Font.Color := clRed;
    gMain.Canvas.Font.Style := [fsBold];
    gMain.Canvas.TextRect(Rect, Rect.Left + 2, Rect.Top + 2, myStr);
  end;
  // Edwin_Searchability end.
end;

procedure TdDKL_ConstEditor.edtSearchChange(Sender: TObject);
begin
  // Edwin_Searchability
  PerformSearch;
  // Edwin_Searchability end.
end;

// Edwin_Searchability end.

// Edwin_Searchability
function TdDKL_ConstEditor.IsRowMatch(aRow: Integer; aSearchStr: string): Boolean;
begin
  Result :=  ContainsText(gMain.Cells[IColIdx_Name, ARow], aSearchStr)
    or ContainsText(gMain.Cells[IColIdx_Value, ARow], aSearchStr);
end;
// Edwin_Searchability END.

// Edwin_Searchability
procedure TdDKL_ConstEditor.PerformSearch;
var
  i: Integer;
  searchStr: string;
begin
  CurrentMatchingIndex := -1;
  FMatchingRows.Clear;

  searchStr := Trim(edtSearch.Text);
  for i := 1 to gMain.RowCount do
  begin
    if IsRowMatch(i, searchStr) then
    begin
      FMatchingRows.Add(i);
    end;
  end;

  // Locate the first matching row if any.
  if not GotoFirstMatchingRow then
  begin
    gMain.Invalidate;
    ShowCurrentSearchLocation;
  end;
end;
// Edwin_Searchability end.

// Edwin_Searchability
function TdDKL_ConstEditor.GotoFirstMatchingRow: Boolean;
begin
  Result := False;
  if FMatchingRows.Count < 1 then
    Exit;

  CurrentMatchingIndex := 0;
  Result := True;
end;
// Edwin_Searchability end.

// Edwin_Searchability
procedure TdDKL_ConstEditor.SetCurrentMatchingIndex(const Value: Integer);
begin
  FCurrentMatchingIndex := Value;

  if (FCurrentMatchingIndex >= 0) and (FCurrentMatchingIndex < FMatchingRows.Count) then
  begin
    gMain.Row := FMatchingRows[FCurrentMatchingIndex];
    gMain.Invalidate;
  end;


  ShowCurrentSearchLocation;
end;
// Edwin_Searchability end.


procedure TdDKL_ConstEditor.ShowCurrentSearchLocation;
const
  // Something like '1 of 5 matches'.
  cSearchLocationString = '%d of %d matches';
begin
  lblSearchPos.Caption := Format(cSearchLocationString, [FCurrentMatchingIndex + 1, self.FMatchingRows.Count]);
end;
// Edwin_Searchability end.

// Edwin_Searchability
procedure TdDKL_ConstEditor.GotoNextMatchingRow(const aStep: Integer = 1);
var
  newIdx: Integer;
begin
  if FMatchingRows.Count < 1 then
    Exit;

  newIdx := CurrentMatchingIndex + aStep;
  if newIdx > (FMatchingRows.Count - 1) then
    newIdx := FMatchingRows.Count - 1;
  if newIdx < 0 then
    newIdx := 0;

  CurrentMatchingIndex := newIdx;
  gMain.SetFocus;
end;
// Edwin_Searchability end.

end.
