program glaz;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  // SafeIniFiles in 'SafeIniFiles.pas',
  Winapi.Windows,
  Vcl.Dialogs;

var
  hMutex: THandle;

{$R *.res}
{$R *.dkl_const.res}

begin
  hMutex := 0;
  hMutex := CreateMutex(nil, False, '{BF1F3DE6-D3DF-4554-A223-D1F5AD7BB2B6}');
  try
    if (hMutex = INVALID_HANDLE_VALUE) or (GetLastError=ERROR_ALREADY_EXISTS) then
    begin
      MessageDlg('Another copy of this program is already running.', mtError, [mbOK], 0);
      Halt;
    end;
    Application.Initialize;
    Application.Title := 'NI Glaz';
    Application.CreateForm(TForm1, Form1);
    Application.Run;
  finally
    ReleaseMutex(hMutex);
    CloseHandle(hMutex);
  end;
end.
