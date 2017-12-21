object fmLog: TfmLog
  Left = 486
  Top = 204
  BorderIcons = [biSystemMenu, biMaximize]
  BorderStyle = bsDialog
  Caption = ' Backup Log Viewer'
  ClientHeight = 360
  ClientWidth = 600
  Color = clBtnFace
  DefaultMonitor = dmMainForm
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  DesignSize = (
    600
    360)
  PixelsPerInch = 96
  TextHeight = 13
  object lbLogPath: TLabel
    Left = 8
    Top = 328
    Width = 47
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'lbLogPath'
    Color = clBtnFace
    Font.Charset = ANSI_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    Layout = tlCenter
  end
  object btClose: TButton
    Left = 496
    Top = 328
    Width = 96
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = '&Close'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object btPrint: TButton
    Left = 392
    Top = 328
    Width = 96
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = '&Print'
    TabOrder = 1
    OnClick = btPrintClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 584
    Height = 314
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssBoth
    TabOrder = 2
  end
end
