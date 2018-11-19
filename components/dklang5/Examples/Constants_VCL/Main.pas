//**********************************************************************************************************************
//  $Id: Main.pas,v 1.8 2006/08/11 12:15:50 dale Exp $
//----------------------------------------------------------------------------------------------------------------------
//  DKLang Localization Package
//  Copyright 2002-2006 DK Software, http://www.dk-soft.org
//**********************************************************************************************************************
unit Main;

interface

uses
  Windows, Messages, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  DKLang, StdCtrls;

type
  TfMain = class(TForm)
    bTest: TButton;
    cbLanguage: TComboBox;
    lcMain: TDKLanguageController;
    lSampleMessage: TLabel;
    procedure bTestClick(Sender: TObject);
    procedure cbLanguageChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  end;

var
  fMain: TfMain;

implementation
{$R *.dfm}
uses SysUtils;

  procedure TfMain.bTestClick(Sender: TObject);
  begin
    MessageBoxW(
      Application.Handle,
      PChar(DKLangConstW('STestMessage')),
      PChar(DKLangConstW('SMessageCaption')),
      MB_ICONINFORMATION or MB_OK);
  end;

  procedure TfMain.cbLanguageChange(Sender: TObject);
  var iIndex: Integer;
  begin
    iIndex := cbLanguage.ItemIndex;
    if iIndex<0 then iIndex := 0; // When there's no valid selection in cbLanguage we use the default language (Index=0)
    LangManager.LanguageID := LangManager.LanguageIDs[iIndex];
  end;

  procedure TfMain.FormCreate(Sender: TObject);
  var i: Integer;
  begin
     // Scan for language files in the app directory and register them in the Languager Manager
    LangManager.ScanForLangFiles(IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))), '*.lng', False);
     // Fill cbLanguage with available languages
    for i := 0 to LangManager.LanguageCount-1 do cbLanguage.Items.Add(LangManager.LanguageNames[i]);
     // Index=0 always means the default language
    cbLanguage.ItemIndex := 0;
  end;

end.
