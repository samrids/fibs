{*******************************************************}
{                                                       }
{       FIBS Firebird-Interbase Backup Scheduler        }
{                                                       }
{       Copyright (c) 2005-2006, Talat Dogan            }
{                                                       }
{*******************************************************}

program fibs;

uses
  Windows,
  Messages,
  SysUtils,
  Forms,
  Dialogs,
  WinSvc,
  Classes,
  UDFConst in 'UDFConst.pas',
  UDFPresets in 'UDFPresets.pas',
  UDFTask in 'UDFTask.pas',
  UDFValidation in 'UDFValidation.pas',
  UDFBackup in 'UDFBackup.pas',
  UDFUtils in 'UDFUtils.pas',
  UDFEmail in 'UDFEmail.pas',
  UDFsys in 'UDFsys.pas',
  UDFServiceBackup in 'UDFServiceBackup.pas',
  UDFServiceUtils in 'UDFServiceUtils.pas',
  FibsData in 'FibsData.pas' {dmFibs: TDataModule},
  FibsForm in 'FibsForm.pas' {fmFibs},
  PrefForm in 'PrefForm.pas' {fmPref},
  TaskForm in 'TaskForm.pas' {fmTask},
  ProgressForm in 'ProgressForm.pas' {fmProgress},
  BackupForm in 'BackupForm.pas' {fmBackup},
  PlanListForm in 'PlanListForm.pas' {fmPlanList},
  AboutForm in 'AboutForm.pas' {fmAbout},
  LogForm in 'LogForm.pas' {fmLog};

//{$R 'UAC.res' 'UAC.rc'}
{$R *.RES}

begin
  // Check if FIBS is running as a service
  if ServiceRunning(nil, 'FIBSBackupService') then
  begin
    MessageDlg('FIBS is still running as a service!', mtError, [mbOk], 0);
    Exit;
  end;
  // FIBS is not running as a service.
  // Check if FIBS is running as an application.
  if AlreadyRun then
  begin
    MessageDlg('FIBS is still running as a desktop Application!', mtError, [mbOk], 0);
    Exit;
  end;
  // FIBS is not running as a service nor an application.
  // Check if FIBS is installed as a service.
  if BackupStartService('FIBSBackupService') then
  begin
    // FIBS is installed as a service.
    // Check Datafiles are exist.
    if DataFilesExists then
    begin
      BackupService.SetTitle('FIBS');
      RunningAsService := True;
      BackupService.CreateForm(TfmFibs, fmFibs);
      // Check Datafiles are not corrupt nor old version.
      if DataFilesInvalid then
      begin
        dmFibs.Free;
        fmFibs.Release;
        MessageDlg('ERROR!' + 'prefs.dat or tasks.dat is not exists or corrupt or old version!!'#13#10'FIBS cannot start!', mtError, [mbOk], 0);
        PostThreadMessage(BackupService.ServiceThread.ThreadID, WM_QUIT, 0, 0);
        Exit;
      end;
      SetCurrentDir(ExtractFileDir(ServiceExeName));
      // Create MainForm
      BackupService.Run;
    end;
    Exit;
  end;
  // FIBS is not installed as a service.
  // Check again if FIBS is running as an application.
  if AlreadyRun = False then
  begin
    // FIBS is not running as an application.
    // Run it as an application.
    Application.Title := 'FIBS';
    Application.HelpFile := 'fibs.hlp';
    Application.Initialize;
    // Check Datafiles are exist.
    if DataFilesExists then
    begin
      RunningAsService := False;
      Application.CreateForm(TfmFibs, fmFibs);
  // Check Datafiles are not corrupt nor old version.
      if DataFilesInvalid then
      begin
        dmFibs.Free;
        fmFibs.Free;
        MessageDlg('ERROR!'#13#10 + 'prefs.dat and/or tasks.dat is/are not exist, old version or corrupt!'#13#10'FIBS cannot start!', mtError, [mbOk], 0);
        Application.Terminate;
        Exit;
      end;
      SetCurrentDir(ExtractFileDir(Application.ExeName)); //Beta-13
      Application.Run;
    end;
  end
  else
    MessageDlg('FIBS Firebird-Interbase Backup Scheduler can run only one instance!', mtError, [mbOk], 0);
end.

