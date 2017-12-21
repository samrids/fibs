
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

unit LogForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, Grids, StdCtrls, FibsData, Printers;

type
  TfmLog = class(TForm)
    lbLogPath: TLabel;
    btClose: TButton;
    btPrint: TButton;
    Memo1: TMemo;
    procedure btPrintClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
    LogFile: string;
    constructor Create(AOwner: TComponent; FibsRef: TdmFibs); reintroduce;
  end;

  var fmLog: TfmLog = nil;
implementation

{$R *.dfm}


uses ProgressForm, UDFConst, UDFUtils, UDFPresets;


procedure PrintStrings(Strings: TStrings);
var
  Prn: TextFile;
  i: word;
begin
  AssignPrn(Prn);
  try
    Rewrite(Prn);
    try
      for i := 0 to Strings.Count - 1 do
        writeln(Prn, Strings.Strings[i]);
    finally
      CloseFile(Prn);
    end;
  except
    on EInOutError do
      MessageDlg('Error Printing text.', mtError, [mbOk], 0);
  end;
end;

procedure TfmLog.btPrintClick(Sender: TObject);
begin
  PrintStrings(Memo1.Lines);
end;

constructor TfmLog.Create(AOwner: TComponent; FibsRef: TdmFibs);
var
  slLogFile: TStringList;
  sTaskName, sLogDir, sLogName, sLogNameExt, sLogPath: string;
begin
  sTaskName := UDFUtils.RemoveDatabaseSequenceTokens(FibsRef.qrTaskTASKNAME.Value);
  sLogName := 'LOG_' + sTaskName;
  sLogNameExt := 'LOG_' + sTaskName + '.TXT';
  sLogDir := FibsRef.qrOptionLOGDIR.Value;
  sLogPath := UDFPresets.MakeFull(sLogDir, sLogNameExt);
  if Length(Trim(sLogPath)) = 0 then
  begin
    MessageDlg('LOG Directory is empty!', mtError, [mbOk], 0);
    Exit;
  end;
  if not SysUtils.DirectoryExists(sLogDir) then
  begin
    MessageDlg('Given LOG Directory doesn''t exists!' + #13#10 + '(' + sLogDir + ')', mtError, [mbOk], 0);
    Exit;
  end;
  if not SysUtils.FileExists(sLogPath) then
  begin
    MessageDlg('LOG File for Task "' + sTaskName + '" is not exist!' + #13#10 + 'Log File will be created after executing a backup task.', mtError, [mbOk], 0);
    Exit;
  end;
  slLogFile:= TStringList.Create;
  inherited Create(AOwner);
  try
    Self.Caption := 'Task " ' + sTaskName + ' " LOG';
    Self.LogFile := sLogNameExt;
    Self.lbLogPath.Caption := 'Log File: ' + sLogPath;
    Memo1.Lines.LoadFromFile(sLogPath);
    Self.ShowModal;
  finally
    slLogFile.Free;
    Self.Release;
  end;
end;

end.
