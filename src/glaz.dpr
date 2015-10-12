program glaz;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  SafeIniFiles in 'SafeIniFiles.pas';

{$R *.res}
{$R *.dkl_const.res}

begin
  Application.Initialize;
  Application.Title := 'NI Glaz';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
