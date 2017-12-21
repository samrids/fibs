
{****************************************************************************}
{                                                                            }
{               FIBS Firebird-Interbase Backup Scheduler                     }
{                                                                            }
{                 Copyright (c) 2005-2006, Talat Dogan                       }
{                                                                            }
{ This program is free software; you can redistribute it and/or modify it    }
{ under the terms of the GNU General Public License as published by the Free }
{ Software Foundation; either version 2 of the License, or (at your option)  }
{ any later version.                                                         }
{                                                                            }
{ This program is distributed in the hope that it will be useful, but        }
{ WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY }
{ or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for}
{ more details.                                                              }
{                                                                            }
{ You should have received a copy of the GNU General Public License along    }
{ with this program; if not, write to the Free Software Foundation, Inc.,    }
{ 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA                      }
{                                                                            }
{ Contact : dogantalat@yahoo.com
{                                                                            }
{****************************************************************************}

unit FibsForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons, ActiveX, ShellApi, Menus, ExtCtrls, Grids, DBGrids,
  DBCtrls, FibsData, JvComponentBase, JvTrayIcon, JvThreadTimer, DB,
  System.NetEncoding;

const
  WM_ICONTRAY = WM_USER + 1; // User-defined message

type

  TfmFibs = class(TForm)
    mmMenu: TMainMenu;
    MenuPrefs: TMenuItem;
    ButtonPanel: TPanel;
    ButtonLogs: TSpeedButton;
    ButtonQuit: TSpeedButton;
    ButtonEditTask: TSpeedButton;
    StatPanel: TPanel;
    LabelPanel: TPanel;
    MenuTask: TMenuItem;
    MenuNew: TMenuItem;
    MenuEditTask: TMenuItem;
    TaskGrid: TDBGrid;
    MenuActivate: TMenuItem;
    N1: TMenuItem;
    MenuDeactivate: TMenuItem;
    N2: TMenuItem;
    MenuExit: TMenuItem;
    MenuHelp: TMenuItem;
    MenuAbout: TMenuItem;
    LabelClock: TLabel;
    ButtonBackupNow: TSpeedButton;
    LabelAllTaskCompleted: TLabel;
    LabelNextBackup: TLabel;
    Label5: TLabel;
    N3: TMenuItem;
    MenuDelete: TMenuItem;
    N4: TMenuItem;
    MenuPlan: TMenuItem;
    MenuTimeSettings: TMenuItem;
    ButtonPlan: TSpeedButton;
    MenuLog: TMenuItem;
    N6: TMenuItem;
    MenuActivateAll: TMenuItem;
    MenuDeactivateAll: TMenuItem;
    MenuBackupNow: TMenuItem;
    N7: TMenuItem;
    pmTray: TPopupMenu;
    miTrayShow: TMenuItem;
    miTrayExit: TMenuItem;
    N8: TMenuItem;
    miTrayHide: TMenuItem;
    MenuView: TMenuItem;
    MenuHelpHelp: TMenuItem;
    N5: TMenuItem;
    miTrayStopService: TMenuItem;
    Label2: TLabel;
    ButtonPrefs: TSpeedButton;
    pmTask: TPopupMenu;
    miTaskDuplicate: TMenuItem;
    tiTray: TJvTrayIcon;
    ttTimer: TJvThreadTimer;
    miTaskEdit: TMenuItem;
    miTaskBackup: TMenuItem;
    procedure MenuPrefsClick(Sender: TObject);
    procedure MenuEditTaskClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuNewClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure MenuActivateClick(Sender: TObject);
    procedure MenuDeactivateClick(Sender: TObject);
    procedure TaskGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure MenuTaskClick(Sender: TObject);
    procedure MenuDeleteClick(Sender: TObject);
    procedure TaskGridKeyPress(Sender: TObject; var Key: Char);
    procedure MenuPlanClick(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
    procedure MenuTimeSettingsClick(Sender: TObject);
    procedure MenuLogClick(Sender: TObject);
    procedure MenuActivateAllClick(Sender: TObject);
    procedure MenuDeactivateAllClick(Sender: TObject);
    procedure MenuBackupNowClick(Sender: TObject);
    procedure miTrayShowClick(Sender: TObject);
    procedure miTrayHideClick(Sender: TObject);
    procedure MenuViewClick(Sender: TObject);
    procedure MenuHelpHelpClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure miTrayStopServiceClick(Sender: TObject);
    procedure pmTrayPopup(Sender: TObject);
    procedure miTaskDuplicateClick(Sender: TObject);
    procedure pmTaskPopup(Sender: TObject);
    procedure tiTrayDblClick(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ttTimerTimer(Sender: TObject);
    procedure miTaskEditClick(Sender: TObject);
    procedure miTaskBackupClick(Sender: TObject);
  private
    procedure InitAlarms;
    procedure SetAlarms;
    procedure DeleteAlarmsFromTimeList;
    procedure BackUpDatabase(ARecNo: string; AAlarmDateTime: TDateTime);
    procedure ManualBackUp(AAlarmDateTime: TDateTime; TaskName, GBakPath, UserName, Password, FullDBPath, BUPath, MirrorPath, Mirror2Path, Mirror3Path, ACompDegree: string; ADoZip, ADoValidate: Boolean);
    procedure GetAlarmTimeList(T: string);
    procedure DeleteCurrentTaskFromTimeList;
    procedure DeactivateAll;
    procedure ActivateAll;
    procedure ActivateOne;
    procedure ActivateAllLeavedActive;
    procedure SetApplicationPriorty;
  public
  end;

var
  fmFibs: TfmFibs;

implementation

uses Registry, Variants, StrUtils, PrefForm, TaskForm, UDFConst, UDFBackup,
  ProgressForm, BackupForm, UDFUtils, PlanListForm,
  AboutForm, LogForm, UDFPresets, DateUtils,
  UDFServiceBackup, Soap.EncdDecd;

{$R *.DFM}

procedure TfmFibs.SetApplicationPriorty;
var
  cpProcess: THandle;
  iPriority: Integer;
  sPriority: string;
begin
  cpProcess := Windows.GetCurrentProcess;
  iPriority := THREAD_PRIORITY_NORMAL;
  sPriority := dmFibs.qrOptionBPRIORTY.Value;
  if sPriority = 'Idle' then
    iPriority := Windows.THREAD_PRIORITY_IDLE
  else
    if sPriority = 'Lowest' then
      iPriority := Windows.THREAD_PRIORITY_LOWEST
    else
      if sPriority = 'Lower' then
        iPriority := Windows.THREAD_PRIORITY_BELOW_NORMAL
      else
        if sPriority = 'Normal' then
          iPriority := Windows.THREAD_PRIORITY_NORMAL
        else
          if sPriority = 'Higher' then
            iPriority := Windows.THREAD_PRIORITY_ABOVE_NORMAL
          else
            if sPriority = 'Highest' then
              iPriority := Windows.THREAD_PRIORITY_HIGHEST;
  Windows.SetThreadPriority(cpProcess, iPriority);
end;

procedure TfmFibs.MenuPrefsClick(Sender: TObject);
begin
  TfmPref.ShowPrefs(Self, dmFibs);
end;

procedure TfmFibs.MenuEditTaskClick(Sender: TObject);
var
  i: Integer;
begin
  if dmFibs.qrTask.RecordCount > 0 then
  begin
    if TfmTask.EditTask(Self, dmFibs, False) then
    begin
      Self.DeleteCurrentTaskFromTimeList;
      Self.GetAlarmTimeList(dmFibs.qrTaskBOXES.AsString);
      UDFConst.PreservedInHour := AlarmInHour;
      UDFConst.PreservedInDay := AlarmInDay;
      UDFConst.PreservedInMonth := AlarmInDay * AlarmInMonth;
      if dmFibs.qrTaskACTIVE.AsInteger = 1 then
      begin
        for i := 0 to AlarmTimeList.Count - 1 do
          UDFConst.TimeList.Add(UDFConst.AlarmTimeList.Strings[i]);
        Self.InitAlarms;
      end;
    end;
  end
  else
    MessageDlg('No Task to Edit!', mtError, [mbOk], 0);
end;

procedure TfmFibs.DeleteCurrentTaskFromTimeList;
var
  X, Y: string;
  i, L, StartPos, ALen: Integer;
begin
  if UDFConst.TimeList.Count > 0 then
  begin
    Y := dmFibs.qrTaskTASKNO.AsString;
    for i := UDFConst.TimeList.Count - 1 downto 0 do
    begin
      StartPos := Pos(' - ', UDFConst.TimeList.Strings[i]) + 3;
      X := UDFConst.TimeList[i];
      L := Pos(' + ', UDFConst.TimeList.Strings[i]);
      ALen := L - StartPos;
      X := copy(UDFConst.TimeList.Strings[i], StartPos, ALen);
      if X = Y then
        UDFConst.TimeList.Delete(i);
    end;
  end;
end;

procedure TfmFibs.GetAlarmTimeList(T: string);
var
  PDot, h, minu: Integer;
  //  MaxDay :integer;
  AYear, AMonth, ADay, AMinute, ASecond, AMilliSecond: Word;
  AlarmDateTimeStr: string;
  AlarmDateTime: TDateTime;
begin
  AMinute := 0;
  ASecond := 0;
  AMilliSecond := 0;
  AlarmInHour := 0;
  AlarmInDay := 0;
  AlarmInMonth := 0;
  AlarmTimeList.Clear;
  DecodeDate(Date, AYear, AMonth, ADay);
  //  MaxDay:=DaysInAMonth(AYear,AMonth);
  for h := 0 to 23 do
  begin
    if T[h + 1] = '1' then
    begin
      inc(AlarmInDay);
      for minu := 0 to 59 do
      begin
        if T[minu + 25] = '1' then
        begin
          inc(AlarmInHour);
          AlarmDateTime := EncodeDateTime(AYear, AMonth, ADay, h, minu, ASecond, AMilliSecond);
          AlarmDateTimeStr := '000' + FloatToStr(AlarmDateTime - StartOfTheDay(AlarmDateTime));
          {$IF CompilerVersion = 7} // 7 = DELPHI 7
                  PDot := Pos(DecimalSeparator, AlarmDateTimeStr);
          {$ELSE}
                  PDot := Pos(FormatSettings.DecimalSeparator, AlarmDateTimeStr);
          {$IFEND}

          if (PDot > 0) then
            Delete(AlarmDateTimeStr, 1, PDot - 4)
          else
            AlarmDateTimeStr := RightStr(AlarmDateTimeStr, 3);
          AlarmTimeList.Add(AlarmDateTimeStr + ' - ' + dmFibs.qrTaskTASKNO.AsString + ' + ' + dmFibs.qrTaskTASKNAME.AsString);
        end;
      end;
    end;
  end;
end;

procedure TfmFibs.FormCreate(Sender: TObject);
begin
  Application.CreateForm(TdmFibs, dmFibs);
  Self.SetApplicationPriorty;
  if DataFilesInvalid then
    Exit;
  Windows.SetThreadLocale(LOCALE_SYSTEM_DEFAULT);
  SysUtils.GetFormatSettings;
  Application.UpdateFormatSettings := False;
  UDFConst.SyncLog := TMultiReadExclusiveWriteSynchronizer.Create;
  UDFConst.AlarmTimeList := TStringList.Create;
  UDFConst.AlarmTimeList.Sorted := True;
  UDFConst.TimeList := TStringList.Create;
  UDFConst.TimeList.Sorted := True;
  Self.ttTimer.Enabled := True;
  Self.caption := 'FIBS  ' + PrgInfo + ' Ver. ' + ReleaseInfo;
  Self.ActivateAllLeavedActive;
  // Hide process messages when FIBS is minimised.
  if BackupIsService then
  begin
    Self.Hide;
    UDFConst.MainFormHidden := True;
  end
  else
  begin
    Application.ShowMainForm := False;
    UDFConst.MainFormHidden := True;
  end;
  if UDFConst.RunningAsService then
    Self.tiTray.Hint := UDFConst.PrgName + ' is running As a Service.'
  else
    Self.tiTray.Hint := UDFConst.PrgName + ' is running As a Application.';
  Self.tiTray.Active := True;
  Self.tiTray.HideApplication;
end;

procedure TfmFibs.FormDestroy(Sender: TObject);
begin
  UDFConst.AlarmTimeList.Free;
  UDFConst.TimeList.Free;
  UDFConst.SyncLog.Free;
end;

procedure TfmFibs.MenuNewClick(Sender: TObject);
var
  i: Integer;
  s: string;
  bul: Boolean;
  TN: string;
begin
  dmFibs.qrTask.DisableControls;
  try
    TN := dmFibs.qrTaskTASKNO.Value;
    dmFibs.qrTask.First;
    bul := dmFibs.qrTask.Locate('ACTIVE', 1, []);
    dmFibs.qrTask.First;
    dmFibs.qrTask.Locate('TASKNO', TN, []);
  finally
    dmFibs.qrTask.EnableControls;
  end;
  if bul then
  begin
    MessageDlg('You MUST DEACTIVE all active Tasks before adding a new Task!', mtError, [mbOk], 0);
    Exit;
  end;
  TfmTask.EditTask(Self, dmFibs, True);
end;

procedure TfmFibs.DeleteAlarmsFromTimeList;
var
  X, Y: string;
  i: Integer;
  StartPos, Uzun: Integer;
begin
  if TimeList.Count > 0 then
  begin
    Y := dmFibs.qrTaskTASKNO.AsString;
    for i := TimeList.Count - 1 downto 0 do
    begin
      StartPos := Pos(' - ', TimeList.Strings[i]) + 3;
      Uzun := Pos(' + ', TimeList.Strings[i]) - StartPos;
      X := copy(TimeList.Strings[i], StartPos, Uzun);
      if X = Y then
        TimeList.Delete(i);
    end;
  end;
end;

procedure TfmFibs.MenuExitClick(Sender: TObject);
begin
  if BackupIsService then
  begin
    MessageDlg(PrgName + ' is running as a Windows Service now.'#13#10 +
      'If you want to stop FIBSBackupService please use FIBS tray icon''s "Stop Service" menu'#13#10 +
      'or use FIBSSM FIBS Service Manager.', mtInformation, [mbOk], 0);
    Exit;
  end
  else
  begin
    Show;
    if MessageDlg('Do you really want to exit?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      Self.ttTimer.Enabled := False;
      Close;
    end;
  end;
end;

procedure TfmFibs.MenuActivateClick(Sender: TObject);
var
  gd, ld: string;
begin
  if dmFibs.qrTask.RecordCount < 1 then
  begin
    MessageDlg('No backup task to be activated!', mtError, [mbOk], 0);
    Exit;
  end;
  gd := Trim(dmFibs.qrOptionPATHTOGBAK.Value);
  if gd = '' then
  begin
    MessageDlg('GBAK Directory is empty!', mtError, [mbOk], 0);
    Exit;
  end
  else
    if DirectoryExists(gd) = False then
    begin
      MessageDlg('Gbak Directory doesn''t exists!', mtError, [mbOk], 0);
      ModalResult := mrNone;
      Exit;
    end
    else
      if FileExists(gd + '\gbak.exe') = False then
      begin
        MessageDlg('Gbak.exe cannot be found onto given Gbak Dir!', mtError, [mbOk], 0);
        ModalResult := mrNone;
        Exit;
      end;
  ld := Trim(dmFibs.qrOptionLOGDIR.Value);
  if (ld = '') then
  begin
    MessageDlg('LOG Directory is empty!', mtError, [mbOk], 0);
    Exit;
  end
  else
    if DirectoryExists(ld) = False then
    begin
      MessageDlg('Given LOG Directory doesn''t exists!' + #13#10 + '(' + ld + ')', mtError, [mbOk], 0);
      ModalResult := mrNone;
      Exit;
    end;

  if MessageDlg('Do you want to ACTIVATE ' + dmFibs.qrTaskTASKNAME.Value + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ActivateOne;
  end;
end;

procedure TfmFibs.MenuDeactivateClick(Sender: TObject);
begin
  if MessageDlg('Do you want to DEACTIVATE ' + dmFibs.qrTaskTASKNAME.Value + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    DeleteAlarmsFromTimeList;
    dmFibs.qrTask.Edit;
    dmFibs.qrTaskACTIVE.AsInteger := 0;
    dmFibs.qrTask.Post;
    InitAlarms;
  end;
end;

procedure TfmFibs.BackUpDatabase(ARecNo: string; AAlarmDateTime: TDateTime);
var
  GenelOptions, BackUpOptions: string;
  FullDBPath, DBNameExt, DBExt: string;
  MirrorPath, Mirror2Path, Mirror3Path, FullMirrorPath, FullMirror2Path, FullMirror3Path: string;
  FullBUPath, BUPath, BUNameExt, LogName, LogNameExt: string;
  GBakPath, komut, VKomut, UserName, Password: string;
  DeleteAll, PVAdet, PVUnit, LenExt: Integer;
  currdir: string;
  FtpConnType: Integer;
  BatchFile, MailTo, Book, TaskName: string;
  DoValidate, CompressBackup, DoMirror, DoMirror2, DoMirror3: Boolean;
  BackupPriorityStr, CompDegree, s, BackupNo, FullLogPath: string;
  BackupPriority: TThreadPriority;
  SmtpServer, SendersMail, MailUserName, MailPassword: string;
  ShowBatchWin, UseParams: Boolean;
  Backup: TThread;
  SequenceIncremented: Boolean;
  ArchiveDir: string;
begin
  dmFibs.qrTask.DisableControls;
  Book := dmFibs.qrTaskTASKNO.AsString;
  try
    dmFibs.qrTask.Locate('TASKNO', ARecNo, []);
    TaskName := dmFibs.qrTaskTASKNAME.Value;
    GBakPath := dmFibs.qrOptionPATHTOGBAK.Value;
    UserName := dmFibs.qrTaskUSER.Value;
    Password := Soap.EncdDecd.DecodeString(dmFibs.qrTaskPASSWORD.AsString);
    DoValidate := dmFibs.qrTaskDOVAL.AsBoolean;
    BatchFile := dmFibs.qrTaskBATCHFILE.Value;
    ShowBatchWin := dmFibs.qrTaskSHOWBATCHWIN.AsBoolean;
    UseParams := dmFibs.qrTaskUSEPARAMS.AsBoolean;

    SmtpServer := dmFibs.qrOptionSMTPSERVER.Value;
    SendersMail := dmFibs.qrOptionSENDERSMAIL.Value;
    MailUserName := dmFibs.qrOptionMAILUSERNAME.Value;
    MailPassword := Soap.EncdDecd.DecodeString(dmFibs.qrOptionMAILPASSWORD.AsString);

    MailTo := dmFibs.qrTaskMAILTO.Value;
    FtpConnType := StrToIntDef(dmFibs.qrOptionFTPCONNTYPE.AsString, 0);

    CompDegree := dmFibs.qrTaskCOMPRESS.Value;
    if dmFibs.qrTaskDELETEALL.AsString='T' then
      DeleteAll := 1 //dmFibs.qrTaskDELETEALL.AsInteger; samrids 8/12/2017
    else
      DeleteAll := 0;

    PVAdet := dmFibs.qrTaskPVAL.AsInteger;
    PVUnit := -1; // For init
    if dmFibs.qrTaskPUNIT.Value = 'Backups' then
      PVUnit := 0
    else
      if dmFibs.qrTaskPUNIT.Value = 'Hour''s Backup' then
        PVUnit := 1
      else
        if dmFibs.qrTaskPUNIT.Value = 'Day''s Backup' then
          PVUnit := 2
        else
          if dmFibs.qrTaskPUNIT.Value = 'Month''s Backup' then
            PVUnit := 3;

    FullDBPath := dmFibs.qrTaskDBNAME.Value;
    BUPath := dmFibs.qrTaskBACKUPDIR.Value;
    MirrorPath := dmFibs.qrTaskMIRRORDIR.Value;
    Mirror2Path := dmFibs.qrTaskMIRROR2DIR.Value;
    Mirror3Path := dmFibs.qrTaskMIRROR3DIR.Value;
    currdir := ExtractFilePath(Application.ExeName);
    BackupNo := RightStr('0000' + dmFibs.qrTaskBCOUNTER.AsString, 4);

    if (MirrorPath <> '') then
      DoMirror := True
    else
      DoMirror := False;
    if (Mirror2Path <> '') then
      DoMirror2 := True
    else
      DoMirror2 := False;
    if (Mirror3Path <> '') then
      DoMirror3 := True
    else
      DoMirror3 := False;
    CompressBackup := dmFibs.qrTaskZIPBACKUP.AsBoolean;

    DBNameExt := ExtractFileName(FullDBPath);
    DBExt := UpperCase(ExtractFileExt(DBNameExt));
    LenExt := Length(DBExt);
    if DBExt = '.GDB' then
      BUNameExt := TaskName + '.GBK'
    else
      if DBExt = '.FDB' then
        BUNameExt := TaskName + '.FBK'
      else
        if DBExt = '.IB' then
          BUNameExt := TaskName + '.IBK'
        else
          BUNameExt := TaskName + '.XBK';

    FullBUPath := MakeFull(BUPath, BUNameExt);
    FullMirrorPath := MakeFull(MirrorPath, BUNameExt);
    FullMirror2Path := MakeFull(Mirror2Path, BUNameExt);
    FullMirror3Path := MakeFull(Mirror2Path, BUNameExt);

    LogName := 'LOG_' + TaskName;
    LogNameExt := 'LOG_' + TaskName + '.TXT';
    FullLogPath := MakeFull(dmFibs.qrOptionLOGDIR.Value, LogNameExt);

    BackupPriorityStr := dmFibs.qrOptionBPRIORTY.Value;
    BackupPriority := tpNormal; //for Init
    if BackupPriorityStr = 'Idle' then
      BackupPriority := tpIdle
    else
      if BackupPriorityStr = 'Lowest' then
        BackupPriority := tpLowest
      else
        if BackupPriorityStr = 'Lower' then
          BackupPriority := tpLower
        else
          if BackupPriorityStr = 'Normal' then
            BackupPriority := tpNormal
          else
            if BackupPriorityStr = 'Higher' then
              BackupPriority := tpHigher
            else
              if BackupPriorityStr = 'Highest' then
                BackupPriority := tpHighest;

    dmFibs.qrTask.Edit;
    if ((StrToInt(BackupNo) + 1) > 9999) then
      dmFibs.qrTaskBCOUNTER.AsInteger := 0
    else
      dmFibs.qrTaskBCOUNTER.AsInteger := StrToInt(BackupNo) + 1;
    dmFibs.qrTask.Post;

    GenelOptions := '-v';
    s := dmFibs.qrTaskBOPTIONS.Value;
    BackUpOptions := '';
    if (s[1] = '1') then
      BackUpOptions := BackUpOptions + ' -t'; //Create Tranpostable Backup
    if (s[2] = '1') then
      BackUpOptions := BackUpOptions + ' -g'; //Do not Perform Garbage Collection
    if (s[3] = '1') then
      BackUpOptions := BackUpOptions + ' -co'; //Convert External Tables to Internal Tables
    if (s[4] = '1') then
      BackUpOptions := BackUpOptions + ' -ig'; //Ignore Checksum Error
    if (s[5] = '1') then
      BackUpOptions := BackUpOptions + ' -l'; //Ignore Limbo Transactions
    if (s[6] = '1') then
      BackUpOptions := BackUpOptions + ' -m'; //Only Backup Metadata
    if (s[7] = '1') then
      BackUpOptions := BackUpOptions + ' -e'; //Create Uncompressed Backup
    if (s[8] = '1') then
      BackUpOptions := BackUpOptions + ' -nt'; //Use Non-Tranpostable Format

    komut := GBakPath + '\gbak.exe' +
      ' ' + GenelOptions +
      ' ' + BackUpOptions +
      ' -user ' + UserName +
      ' -password ' + Password;

    VKomut := '"' + GBakPath + '\gfix.exe"' +
      ' -v -n -user ' + UserName +
      ' -password ' + Password;
    SequenceIncremented := dmFibs.CheckDatabaseSequenceIncrement;
    ArchiveDir := dmFibs.qrOptionARCHIVEDIR.Value;
    Backup := TBackupTask.Create(AAlarmDateTime, komut, VKomut, currdir, TaskName, BackUpOptions,
      FullDBPath, FullBUPath, FullMirrorPath, FullMirror2Path,
      FullMirror3Path, FullLogPath, BackupNo, CompDegree, SmtpServer,
      SendersMail, MailUserName, MailPassword, MailTo, BatchFile,
      UseParams, ShowBatchWin, DoMirror, DoMirror2, DoMirror3, True,
      CompressBackup, DoValidate, PVAdet, PVUnit, DeleteAll, FtpConnType,
      BackupPriority, SequenceIncremented, ArchiveDir);
      Backup.Resume;
  finally
    dmFibs.qrTask.Locate('TASKNO', Book, []);
    dmFibs.qrTask.EnableControls;
    {try
      Backup.WaitFor;
    except
      raise;
    end;
    if SequenceIncremented then
      Self.BackUpDatabase(ARecNo, AAlarmDateTime);  }
  end;
end;

procedure TfmFibs.ManualBackUp(AAlarmDateTime: TDateTime; TaskName, GBakPath, UserName, Password, FullDBPath, BUPath, MirrorPath, Mirror2Path, Mirror3Path, ACompDegree: string; ADoZip, ADoValidate: Boolean);
var
  GenelOptions, BackUpOptions: string;
  DBNameExt, DBExt: string;
  FullMirrorPath, FullMirror2Path, FullMirror3Path, FullBUPath, BUNameExt, LogName, LogNameExt: string;
  komut, VKomut: string;
  DeleteAll, PVAdet, PVUnit, LenExt: Integer;
  MailTo, s, FullLogPath, currdir: string;
  DoMirror, DoMirror2, DoMirror3: Boolean;
  BackupPriorityStr, BackupNo: string;
  BackupPriority: TThreadPriority;
  FtpConnType: Integer;
  BatchFile, SmtpServer, SendersMail, MailUserName, MailPassword: string;
  ShowBatchWin, UseParams: Boolean;
  Backup: TThread;
  SequenceIncremented: Boolean;
  ArchiveDir: string;
begin
  BackupNo := RightStr('0000' + dmFibs.qrTaskBCOUNTER.AsString, 4);
  currdir := ExtractFilePath(Application.ExeName);
  if (MirrorPath <> '') then
    DoMirror := True
  else
    DoMirror := False;
  if (Mirror2Path <> '') then
    DoMirror2 := True
  else
    DoMirror2 := False;
  if (Mirror3Path <> '') then
    DoMirror3 := True
  else
    DoMirror3 := False;
  DBNameExt := ExtractFileName(FullDBPath);
  DBExt := UpperCase(ExtractFileExt(DBNameExt));
  LenExt := Length(DBExt);

  if DBExt = '.GDB' then
    BUNameExt := TaskName + '.GBK'
  else
    if DBExt = '.FDB' then
      BUNameExt := TaskName + '.FBK'
    else
      if DBExt = '.IB' then
        BUNameExt := TaskName + '.IBK'
      else
        BUNameExt := TaskName + '.XBK';

  FullBUPath := MakeFull(BUPath, BUNameExt);
  FullMirrorPath := MakeFull(MirrorPath, BUNameExt);
  FullMirror2Path := MakeFull(Mirror2Path, BUNameExt);
  FullMirror3Path := MakeFull(Mirror3Path, BUNameExt);

  //showmessage(dmFibs.qrTaskDELETEALL.Asstring);
  if dmFibs.qrTaskDELETEALL.Asstring='T' then

  DeleteAll := 1 //dmFibs.qrTaskDELETEALL.AsInteger;
  else
  DeleteAll := 0;


  BackupPriorityStr := dmFibs.qrOptionBPRIORTY.Value;
  BackupPriority := tpNormal; // For Init
  if BackupPriorityStr = 'Idle' then
    BackupPriority := tpIdle
  else
    if BackupPriorityStr = 'Lowest' then
      BackupPriority := tpLowest
    else
      if BackupPriorityStr = 'Lower' then
        BackupPriority := tpLower
      else
        if BackupPriorityStr = 'Normal' then
          BackupPriority := tpNormal
        else
          if BackupPriorityStr = 'Higher' then
            BackupPriority := tpHigher
          else
            if BackupPriorityStr = 'Highest' then
              BackupPriority := tpHighest;

  PVAdet := dmFibs.qrTaskPVAL.AsInteger;
  PVUnit := -1;
  if dmFibs.qrTaskPUNIT.Value = 'Backups' then
    PVUnit := 0
  else
    if dmFibs.qrTaskPUNIT.Value = 'Hour''s Backup' then
      PVUnit := 1
    else
      if dmFibs.qrTaskPUNIT.Value = 'Day''s Backup' then
        PVUnit := 2
      else
        if dmFibs.qrTaskPUNIT.Value = 'Month''s Backup' then
          PVUnit := 3;

  SmtpServer := dmFibs.qrOptionSMTPSERVER.Value;
  SendersMail := dmFibs.qrOptionSENDERSMAIL.Value;
  MailUserName := dmFibs.qrOptionMAILUSERNAME.Value;
  MailPassword := Soap.EncdDecd.DecodeString(dmFibs.qrOptionMAILPASSWORD.AsString);

  BatchFile := dmFibs.qrTaskBATCHFILE.Value;
  ShowBatchWin := dmFibs.qrTaskSHOWBATCHWIN.AsBoolean;
  UseParams := dmFibs.qrTaskUSEPARAMS.AsBoolean;
  MailTo := dmFibs.qrTaskMAILTO.Value;
  FtpConnType := StrToIntDef(dmFibs.qrOptionFTPCONNTYPE.AsString, 1);

  LogName := 'LOG_' + TaskName;
  LogNameExt := 'LOG_' + TaskName + '.TXT';
  FullLogPath := MakeFull(dmFibs.qrOptionLOGDIR.Value, LogNameExt);
  dmFibs.qrTask.Edit;
  if ((StrToInt(BackupNo) + 1) > 9999) then
    dmFibs.qrTaskBCOUNTER.AsInteger := 0
  else
    dmFibs.qrTaskBCOUNTER.AsInteger := StrToInt(BackupNo) + 1;
  dmFibs.qrTask.Post;
  GenelOptions := '-v';
  s := dmFibs.qrTaskBOPTIONS.Value;
  BackUpOptions := '';
  if (s[1] = '1') then
    BackUpOptions := BackUpOptions + ' -t'; //Create Tranpostable Backup
  if (s[2] = '1') then
    BackUpOptions := BackUpOptions + ' -g'; //Do not Perform Garbage Collection
  if (s[3] = '1') then
    BackUpOptions := BackUpOptions + ' -co'; //Convert External Tables to Internal Tables
  if (s[4] = '1') then
    BackUpOptions := BackUpOptions + ' -ig'; //Ignore Checksum Error
  if (s[5] = '1') then
    BackUpOptions := BackUpOptions + ' -l'; //Ignore Limbo Transactions
  if (s[6] = '1') then
    BackUpOptions := BackUpOptions + ' -m'; //Only Backup Metadata
  if (s[7] = '1') then
    BackUpOptions := BackUpOptions + ' -e'; //Create Uncompressed Backup
  if (s[8] = '1') then
    BackUpOptions := BackUpOptions + ' -nt'; //Use Non-Tranpostable Format

  komut := GBakPath + '\gbak.exe' +
    ' ' + GenelOptions +
    ' ' + BackUpOptions +
    ' -user ' + UserName +
    ' -password ' + Password;
  VKomut := '"' + GBakPath + '\gfix.exe"' +
    ' -v -n -user ' + UserName +
    ' -password ' + Password;
  SequenceIncremented := dmFibs.CheckDatabaseSequenceIncrement;
  ArchiveDir := dmFibs.qrOptionARCHIVEDIR.Value;
  Backup := TBackupTask.Create(AAlarmDateTime, komut, VKomut, currdir, TaskName, BackUpOptions,
    FullDBPath, FullBUPath, FullMirrorPath, FullMirror2Path,
    FullMirror3Path, FullLogPath, BackupNo, ACompDegree, SmtpServer,
    SendersMail, MailUserName, MailPassword, MailTo, BatchFile,
    UseParams, ShowBatchWin, DoMirror, DoMirror2, DoMirror3, False,
    ADoZip, ADoValidate, PVAdet, PVUnit, DeleteAll, FtpConnType,
    BackupPriority, SequenceIncremented, ArchiveDir);
  Backup.Resume;
  {try
    Backup.WaitFor;
    Sleep(200);
  except
  end;
  if SequenceIncremented then
    if MessageDlg('A new database sequence [' + FormatFloat('0000', UDFUtils.GetDatabaseSequence(dmFibs.qrTaskDBNAME.AsString)) + '] is found. Backup now?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      Self.ManualBackUp(AAlarmDateTime, dmFibs.qrTaskTASKNAME.AsString, GBakPath, UserName, Password, dmFibs.qrTaskDBNAME.AsString, BUPath, MirrorPath, Mirror2Path, Mirror3Path, ACompDegree, ADoZip, ADoValidate);}
end;

function GetTrapTime(s: string): TDateTime;
begin
  Result := StrToFloat(copy(s, 1, Pos(' - ', s) - 1))
end;

procedure TfmFibs.InitAlarms;
var
  NamePos, KeyPos, i: Integer;
  ATrapStr: string;
  ATrap: TDateTime;
  DT: TDateTime;
  AlarmFound: Boolean;
begin
  //Find CurrentTime
  DT := Now;
  LabelClock.caption := DateTimeToStr(DT);
  CurrentTime := DT - StartOfTheDay(DT);
  //Find next alarm time and owner
  CurrentOwner := '-';
  CurrentOwnerName := '-';
  ;
  CurrentAlarm := 0; //TdateTime
  CurrentItem := 0;
  AlarmFound := False;

  for i := 0 to TimeList.Count - 1 do
  begin
    CurrentItem := i;
    KeyPos := Pos(' - ', TimeList[i]);
    NamePos := Pos(' + ', TimeList[i]);
    ATrapStr := copy(TimeList[i], 1, KeyPos - 1);
    ATrap := StrToFloat(ATrapStr);
    // Exit loop if the alarm point is greater then CurrentTime..
    if ATrap > CurrentTime then
    begin
      CurrentAlarm := ATrap;
      CurrentOwner := copy(TimeList[i], KeyPos + 3, NamePos - (KeyPos + 3));
      CurrentOwnerName := RightStr(TimeList[i], Length(TimeList[i]) - NamePos - 2);
      AlarmFound := True;
      break;
    end;
  end;
  if (TimeList.Count = 0) then
  begin
    NoItemToExecute := True;
    Label5.Visible := False;
  end
  else
  begin
    NoItemToExecute := False;
    if AlarmFound = True then
    begin
      LastItemExecuted := False;
      Label5.caption := '  Next Backup : ' + CurrentOwnerName + ' on ' + MyDateTimeToStr(CurrentAlarm + StartOfTheDay(Now));
      Label5.Visible := True;
    end
    else
    begin
      LastItemExecuted := True;
      Label5.Visible := False;
    end;
  end;
  LabelAllTaskCompleted.Visible := LastItemExecuted;
  LabelNextBackup.Visible := NoItemToExecute;
end;

procedure TfmFibs.SetAlarms;
var
  NamePos, KeyPos: Integer;
  ATrapStr: string;
  ATrap: TDateTime;
  ItemStr: string;
begin
  // if current items is not at the bottom of the list increase List Item Number.
  if (CurrentItem < (TimeList.Count - 1)) then
  begin
    CurrentItem := CurrentItem + 1;
    ItemStr := TimeList[CurrentItem];
    KeyPos := Pos(' - ', ItemStr);
    NamePos := Pos(' + ', ItemStr);
    ATrapStr := copy(ItemStr, 1, KeyPos - 1);
    ATrap := StrToFloat(ATrapStr);
    CurrentAlarm := ATrap;
    CurrentOwner := copy(TimeList[CurrentItem], KeyPos + 3, NamePos - (KeyPos + 3));
    CurrentOwnerName := RightStr(TimeList[CurrentItem], Length(TimeList[CurrentItem]) - NamePos - 2);
    Label5.caption := '  Next Backup : ' + CurrentOwnerName + ' on ' + MyDateTimeToStr(CurrentAlarm + StartOfTheDay(Now));
  end;
end;

procedure TfmFibs.TaskGridDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
begin
  if dmFibs.qrTask.RecordCount = 0 then
    Exit;
  if not (State = [gdSelected]) then
  begin
    if DataCol = 0 then
    begin
      if dmFibs.qrTaskACTIVE.AsInteger = 1 then
      begin
        TaskGrid.Canvas.Brush.Color := $00DBFFCD;
        TaskGrid.Canvas.Font.Color := $00DBFFCD;
      end
      else
      begin
        TaskGrid.Canvas.Brush.Color := clRed;
        TaskGrid.Canvas.Font.Color := clRed;
      end;
      TaskGrid.DefaultDrawColumnCell(Rect, DataCol, Column, State);
    end;
  end;
end;

procedure TfmFibs.MenuTaskClick(Sender: TObject);
begin
  MenuActivate.Enabled := dmFibs.qrTaskACTIVE.AsString = '0'; //Rev.2.0.1-2 ; this was "MenuActivate.Enabled:=dmFibs.qrTaskACTIVE.AsInteger=0;"
  MenuDeactivate.Enabled := not MenuActivate.Enabled;
  MenuDeactivateAll.Enabled := not NoItemToExecute;
  if dmFibs.qrTask.RecordCount < 1 then
  begin
    MenuDelete.caption := 'Delete Task';
    MenuActivate.caption := 'Activate Task';
    MenuDeactivate.caption := 'Deactivate Task';
  end
  else
  begin
    MenuDelete.caption := 'Delete Task "' + dmFibs.qrTaskTASKNAME.Value + ' "';
    MenuActivate.caption := 'Activate "' + dmFibs.qrTaskTASKNAME.Value + ' "';
    MenuDeactivate.caption := 'Deactivate "' + dmFibs.qrTaskTASKNAME.Value + ' "';
  end;
end;

procedure TfmFibs.MenuDeleteClick(Sender: TObject);
begin
  if dmFibs.qrTask.RecordCount > 0 then
  begin
    if dmFibs.qrTaskACTIVE.AsInteger = 0 then
    begin
      if MessageDlg('Do you want to DELETE' + dmFibs.qrTaskTASKNAME.Value + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        DeleteAlarmsFromTimeList;
        dmFibs.qrTask.Delete;
        InitAlarms;
      end;
    end
    else
      MessageDlg('Deactivate Task before Delete!', mtWarning, [mbOk], 0);
  end
  else
    MessageDlg('No Task to Delete!', mtError, [mbOk], 0);
end;

procedure TfmFibs.TaskGridKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    MenuEditTask.Click;
end;

procedure TfmFibs.MenuPlanClick(Sender: TObject);
begin
  TfmPlanList.ShowPlan(Self);
end;

procedure TfmFibs.MenuAboutClick(Sender: TObject);
begin
  TfmAbout.ShowAbout(Self);
end;

procedure TfmFibs.MenuTimeSettingsClick(Sender: TObject);
begin
  if dmFibs.qrTask.RecordCount < 1 then
  begin
    MessageDlg('No backup task to be seen the backup time settings!', mtError, [mbOk], 0);
    Exit;
  end;
  Self.GetAlarmTimeList(dmFibs.qrTaskBOXES.Value);
  TfmPlanList.ShowTaskPlan(Self, dmFibs.qrTaskTASKNAME.AsString, UDFConst.AlarmTimeList);
end;

procedure TfmFibs.MenuLogClick(Sender: TObject);
begin
  if dmFibs.qrTask.RecordCount < 1 then
  begin
    MessageDlg('No task log to be viewed!', mtError, [mbOk], 0);
    Exit;
  end;
  if fmLog=nil then  
  fmLog := TfmLog.Create(Self, dmFibs);
end;

procedure TfmFibs.ActivateAllLeavedActive;
var
  i: Integer;
  gd, ld, Mirr, Mirr2, Mirr3: string;
  bValidMirrors: Boolean;
begin
  gd := Trim(dmFibs.qrOptionPATHTOGBAK.Value);
  ld := Trim(dmFibs.qrOptionLOGDIR.Value);
  if (gd = '') or (DirectoryExists(gd) = False) or (FileExists(gd + '\gbak.exe') = False) or
    (ld = '') or (DirectoryExists(ld) = False) then
  begin
    DeactivateAll;
    Exit;
  end;
  dmFibs.qrTask.DisableControls;
  try
    dmFibs.qrTask.First;
    while not dmFibs.qrTask.eof do
    begin
      if dmFibs.qrTaskACTIVE.AsInteger = 1 then
      begin
        if FileExistsRem(UDFUtils.RemoveDatabaseSequenceTokens(dmFibs.qrTaskDBNAME.Value), dmFibs.qrTaskLOCALCONN.AsBoolean) then
        begin
          if UDFUtils.IsValidDirectory(dmFibs.qrTaskBACKUPDIR.Value) then
          begin
            bValidMirrors := UDFUtils.IsValidDirectory(dmFibs.qrTaskMIRRORDIR.Value) and UDFUtils.IsValidDirectory(dmFibs.qrTaskMIRROR2DIR.Value) and UDFUtils.IsValidDirectory(dmFibs.qrTaskMIRROR3DIR.Value);
            bValidMirrors := (not ActiveTaskValidMirrorDirectory) or bValidMirrors;
            if bValidMirrors then
            begin
              DeleteCurrentTaskFromTimeList;
              GetAlarmTimeList(dmFibs.qrTaskBOXES.Value);
              for i := 0 to AlarmTimeList.Count - 1 do
                TimeList.Add(AlarmTimeList[i]);
            end;
          end;
        end;
      end;
      dmFibs.qrTask.Next;
    end;
    InitAlarms;
  finally
    dmFibs.qrTask.First;
    dmFibs.qrTask.EnableControls;
  end;
end;

procedure TfmFibs.ActivateOne;
var
  i: Integer;
  Mirr, Mirr2, Mirr3: string;
  bValidMirrors: Boolean;
begin
  ShowProgress('Tasks are being activating..'#13#10'Please Wait..');
  dmFibs.qrTask.DisableControls;
  try
    if dmFibs.qrTaskACTIVE.AsInteger = 0 then
    begin
      if FileExistsRem(UDFUtils.RemoveDatabaseSequenceTokens(dmFibs.qrTaskDBNAME.Value), dmFibs.qrTaskLOCALCONN.AsBoolean) then
      begin
        if UDFUtils.IsValidDirectory(dmFibs.qrTaskBACKUPDIR.Value) then
        begin
          bValidMirrors := UDFUtils.IsValidDirectory(dmFibs.qrTaskMIRRORDIR.Value) and UDFUtils.IsValidDirectory(dmFibs.qrTaskMIRROR2DIR.Value) and UDFUtils.IsValidDirectory(dmFibs.qrTaskMIRROR3DIR.Value);
          bValidMirrors := (not ActiveTaskValidMirrorDirectory) or bValidMirrors;
          if bValidMirrors then
          begin
            DeleteCurrentTaskFromTimeList;
            GetAlarmTimeList(dmFibs.qrTaskBOXES.Value);
            for i := 0 to AlarmTimeList.Count - 1 do
              TimeList.Add(AlarmTimeList[i]);
            dmFibs.qrTask.Edit;
            dmFibs.qrTaskACTIVE.AsInteger := 1;
            dmFibs.qrTask.Post;
            InitAlarms;
          end;
        end
        else
          MessageDlg('This Task can''t be Activated'#13#10'Because Directory "' + dmFibs.qrTaskBACKUPDIR.Value + '" is not Exists!', mtError, [mbOk], 0); //1.0.12
      end
      else
        MessageDlg('This Task can''t be Activated'#13#10 + 'Because Database "' + dmFibs.qrTaskDBNAME.Value + '" is not exists!', mtError, [mbOk], 0); //1.0.12
    end;
  finally
    dmFibs.qrTask.EnableControls;
    CloseProgress;
  end;
end;

procedure TfmFibs.ActivateAll;
var
  i: Integer;
  Book: Integer;
  Mirr, Mirr2, Mirr3: string;
  bValidMirrors: Boolean;

  function ValidDirectory(ADir: string): Boolean;
  begin
    ADir := Trim(ADir);
    Result := (ADir = '') or ((DirectoryExists(ADir) or IsFtpPath(ADir)));
  end;
begin
  ShowProgress('Tasks are being activating..'#13#10'Please Wait..');
  dmFibs.qrTask.DisableControls;
  Book := dmFibs.qrTaskTASKNO.AsInteger;
  try
    dmFibs.qrTask.First;
    while not dmFibs.qrTask.eof do
    begin
      if dmFibs.qrTaskACTIVE.AsInteger = 0 then
      begin
        if FileExistsRem(UDFUtils.RemoveDatabaseSequenceTokens(dmFibs.qrTaskDBNAME.Value), dmFibs.qrTaskLOCALCONN.AsBoolean) then
        begin
          if DirectoryExists(dmFibs.qrTaskBACKUPDIR.Value) then
          begin
            bValidMirrors := ValidDirectory(dmFibs.qrTaskMIRRORDIR.Value) and ValidDirectory(dmFibs.qrTaskMIRROR2DIR.Value) and ValidDirectory(dmFibs.qrTaskMIRROR3DIR.Value);
            bValidMirrors := (not ActiveTaskValidMirrorDirectory) or bValidMirrors;
            if bValidMirrors then
            begin
              DeleteCurrentTaskFromTimeList;
              GetAlarmTimeList(dmFibs.qrTaskBOXES.Value);
              for i := 0 to AlarmTimeList.Count - 1 do
                TimeList.Add(AlarmTimeList[i]);
              dmFibs.qrTask.Edit;
              dmFibs.qrTaskACTIVE.AsInteger := 1;
            end;
          end;
        end;
      end;
      dmFibs.qrTask.Next;
    end;
    dmFibs.qrTask.CheckBrowseMode;
    InitAlarms;
  finally
    dmFibs.qrTask.Locate('TASKNO', Book, []);
    dmFibs.qrTask.EnableControls;
    CloseProgress;
  end;
end;

procedure TfmFibs.MenuActivateAllClick(Sender: TObject);
var
  gd, ld: string;
begin
  if dmFibs.qrTask.RecordCount < 1 then
  begin
    MessageDlg('No backup task to be activated!', mtError, [mbOk], 0);
    Exit;
  end;
  gd := Trim(dmFibs.qrOptionPATHTOGBAK.Value);
  if gd = '' then
  begin
    MessageDlg('GBAK Directory is empty!', mtError, [mbOk], 0);
    Exit;
  end
  else
    if DirectoryExists(gd) = False then
    begin
      MessageDlg('Gbak Directory doesn''t exists!', mtError, [mbOk], 0);
      ModalResult := mrNone;
      Exit;
    end
    else
      if FileExists(gd + '\gbak.exe') = False then
      begin
        MessageDlg('Gbak.exe cannot be found onto given Gbak Dir!', mtError, [mbOk], 0);
        ModalResult := mrNone;
        Exit;
      end;
  ld := Trim(dmFibs.qrOptionLOGDIR.Value);
  if (ld = '') then
  begin
    MessageDlg('LOG Directory is empty!', mtError, [mbOk], 0);
    Exit;
  end
  else
    if DirectoryExists(ld) = False then
    begin
      MessageDlg('Given LOG Directory doesn''t exists!' + #13#10 + '(' + ld + ')', mtError, [mbOk], 0);
      ModalResult := mrNone;
      Exit;
    end;
  if MessageDlg('Only error-free-defined tasks will be activated !!'#13#10 +
    '(But no error message will be shown !)'#13#10#13#10 +
    'Do you want to ACTIVATE all deactive tasks?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ActivateAll;
  end;
end;

procedure TfmFibs.DeactivateAll;
var
  Book: Integer;
begin
  ShowProgress('Tasks are being deactivating..'#13#10'Please Wait..');
  dmFibs.qrTask.DisableControls;
  Book := dmFibs.qrTaskTASKNO.AsInteger;
  try
    dmFibs.qrTask.First;
    while not dmFibs.qrTask.eof do
    begin
      if dmFibs.qrTaskACTIVE.AsInteger = 1 then
      begin
        DeleteAlarmsFromTimeList;
        dmFibs.qrTask.Edit;
        dmFibs.qrTaskACTIVE.AsInteger := 0;
      end;
      dmFibs.qrTask.Next;
    end;
    dmFibs.qrTask.CheckBrowseMode;
    InitAlarms;
  finally
    dmFibs.qrTask.Locate('TASKNO', Book, []);
    dmFibs.qrTask.EnableControls;
    CloseProgress;
  end;
end;

procedure TfmFibs.MenuDeactivateAllClick(Sender: TObject);
begin
  if MessageDlg('Do you want to activate All deactive tasks ?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    DeactivateAll;
  end;
end;

procedure TfmFibs.MenuBackupNowClick(Sender: TObject);
var
  sTaskName,
    sGbakDir,
    sUserName,
    sPassword,
    sDatabaseName,
    sBackupDir,
    sMirrorDir1,
    sMirrorDir2,
    sMirrorDir3,
    sCompressLevel: string;
  bDoValidate,
    bCompressBackup: Boolean;
begin
  if dmFibs.qrTask.RecordCount < 1 then
  begin
    MessageDlg('No backup task to execute!', mtError, [mbOk], 0);
    Exit;
  end;
  if TfmBackup.ShowBackup(Self, dmFibs) then
  begin
    sTaskName := dmFibs.qrTaskTASKNAME.Value;
    sDatabaseName := dmFibs.qrTaskDBNAME.Value;
    sBackupDir := dmFibs.qrTaskBACKUPDIR.Value;
    sMirrorDir1 := dmFibs.qrTaskMIRRORDIR.Value;
    sMirrorDir2 := dmFibs.qrTaskMIRROR2DIR.Value;
    sMirrorDir3 := dmFibs.qrTaskMIRROR3DIR.Value;
    sUserName := dmFibs.qrTaskUSER.Value;
    sPassword :=  Soap.EncdDecd.DecodeString(dmFibs.qrTaskPASSWORD.AsString);
    sGbakDir := dmFibs.qrOptionPATHTOGBAK.Value;
    bCompressBackup := dmFibs.qrTaskZIPBACKUP.AsBoolean;
    sCompressLevel := dmFibs.qrTaskCOMPRESS.Value;
    bDoValidate := dmFibs.qrTaskDOVAL.AsBoolean;
    Self.ManualBackUp(Now, sTaskName, sGbakDir, sUserName, sPassword, sDatabaseName, sBackupDir, sMirrorDir1, sMirrorDir2, sMirrorDir3, sCompressLevel, bCompressBackup, bDoValidate);
  end;
end;

procedure TfmFibs.miTrayShowClick(Sender: TObject);
begin
  if Self.Visible = False then
  begin
    Application.ShowMainForm := True;
    Self.Show;
    MainFormHidden := False;
  end
  else
    screen.ActiveForm.SetFocus;
end;

procedure TfmFibs.miTrayHideClick(Sender: TObject);
begin
  if screen.ActiveForm = nil then
    Exit;
  if screen.ActiveForm = Self then
  begin
    Self.Hide;
    MainFormHidden := True;
  end
  else
    MessageDlg('Close window "' + screen.ActiveForm.caption + '" first!', mtError, [mbOk], 0);
end;

procedure TfmFibs.MenuViewClick(Sender: TObject);
begin
  MenuPlan.caption := 'Backup Executing Times in Today (' + DateToStr(Now) + ')';
  if dmFibs.qrTask.RecordCount < 1 then
  begin
    MenuTimeSettings.caption := 'Backup Time Settings of Current Task';
    MenuLog.caption := 'LOG of Selected Task';
  end
  else
  begin
    MenuTimeSettings.caption := 'Backup Time Settings of Task "' + dmFibs.qrTaskTASKNAME.Value + ' "';
    MenuLog.caption := 'LOG of Task "' + dmFibs.qrTaskTASKNAME.Value + '"';
  end;
end;

procedure TfmFibs.MenuHelpHelpClick(Sender: TObject);
var
  HelpPath: string;
  res: Integer;
  sMsg: string;
begin
  HelpPath := GetCurrentDir + '\fibs.hlp';
  res := ShellExecute(Handle, 'open', PChar(HelpPath), nil, nil, SW_SHOWNORMAL);
  case res of
    0: sMsg := 'Error opening help file "' + HelpPath + '"'#13#10'The operating system is out of memory or resources.';
    SE_ERR_FNF: sMsg := 'Error opening help file !!'#13#10'Help file "' + HelpPath + '" couldn''t found.';
    SE_ERR_OOM: sMsg := 'Error opening help file "' + HelpPath + '"'#13#10'There was not enough memory to complete the operation.';
    SE_ERR_SHARE: sMsg := 'Error opening help file "' + HelpPath + '"'#13#10'A sharing violation occurred.';
  end;
  MessageDlg(sMsg, mtError, [mbOk], 0);
  {
  0	The operating system is out of memory or resources.
  ERROR_FILE_NOT_FOUND	The specified file was not found.
  ERROR_PATH_NOT_FOUND	The specified path was not found.
  ERROR_BAD_FORMAT	The .EXE file is invalid (non-Win32 .EXE or error in .EXE image).
  SE_ERR_ACCESSDENIED	The operating system denied access to the specified file.
  SE_ERR_ASSOCINCOMPLETE	The filename association is incomplete or invalid.
  SE_ERR_FNF	The specified file was not found.
  SE_ERR_NOASSOC	There is no application associated with the given filename extension.
  SE_ERR_OOM	There was not enough memory to complete the operation.
  SE_ERR_PNF	The specified path was not found.
  SE_ERR_SHARE	A sharing violation occurred.
  }
end;

procedure TfmFibs.FormShow(Sender: TObject);
begin
  Self.BringToFront;
end;

procedure TfmFibs.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if BackupIsService then
    Action := caNone
  else
    Action := caFree;
end;

procedure TfmFibs.miTrayStopServiceClick(Sender: TObject);
begin
  if BackupIsService then
    PostThreadMessage(BackupService.ServiceThread.ThreadID, WM_QUIT, 0, 0)
  else
    Application.Terminate;
end;

procedure TfmFibs.pmTrayPopup(Sender: TObject);
begin
  if BackupIsService then
    Self.miTrayStopService.Visible := True
  else
    Self.miTrayStopService.Visible := False;
  Self.miTrayExit.Visible := not Self.miTrayStopService.Visible;
end;

procedure TfmFibs.miTaskDuplicateClick(Sender: TObject);
begin
  dmFibs.DuplicateTask(False);
  Self.MenuEditTaskClick(nil);
end;

procedure TfmFibs.pmTaskPopup(Sender: TObject);
begin
  Self.miTaskDuplicate.Enabled := dmFibs.qrTask.RecordCount > 0;
end;

procedure TfmFibs.tiTrayDblClick(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Self.miTrayShowClick(nil);
end;

procedure TfmFibs.ttTimerTimer(Sender: TObject);
var
  DT: TDateTime;
begin
  DT := Now;
  LabelClock.caption := DateTimeToStr(DT);
  CurrentTime := DT - StartOfTheDay(DT);
  CurrentDay := DayOf(DT);
  if (CurrentDay <> ThatDay) then
  begin
    ThatDay := CurrentDay;
    InitAlarms;
    Exit;
  end;
  if NoItemToExecute = True then
    Exit;
  if LastItemExecuted then
    Exit;
  if ((ExecutedItem <> CurrentItem) and (CurrentAlarm <= CurrentTime)) then
  begin
    BackUpDatabase(CurrentOwner, CurrentAlarm + StartOfTheDay(Now));
    ExecutedItem := CurrentItem;
    if (CurrentItem = TimeList.Count - 1) then
    begin
      LastItemExecuted := True;
      LabelAllTaskCompleted.Visible := LastItemExecuted;
      Label5.Visible := False;
    end
    else
    begin
      LastItemExecuted := False;
      LabelAllTaskCompleted.Visible := LastItemExecuted;
    end;
    SetAlarms;
  end;
end;

procedure TfmFibs.miTaskEditClick(Sender: TObject);
begin
  Self.MenuEditTaskClick(nil);
end;

procedure TfmFibs.miTaskBackupClick(Sender: TObject);
begin
  Self.MenuBackupNowClick(nil);
end;

end.

