//**********************************************************************************************************************
//  $Id: DKLang_Frames_Demo.dpr,v 1.4 2006-08-10 16:34:20 dale Exp $
//----------------------------------------------------------------------------------------------------------------------
//  DKLang Localization Package
//  Copyright 2002-2006 DK Software, http://www.dk-soft.org
//**********************************************************************************************************************
program DKLang_Frames_VCL_Demo;

uses
  Forms,
  Main in 'Main.pas' {fMain},
  ufrFontSettings in 'ufrFontSettings.pas' {frFontSettings: TFrame};

{$R *.res}
{$R *.dkl_const.res}

begin
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
