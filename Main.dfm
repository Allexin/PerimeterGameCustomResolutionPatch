object FormMain: TFormMain
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Perimeter GW Custom Resolution'
  ClientHeight = 121
  ClientWidth = 390
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 54
    Height = 13
    Caption = 'Resolution:'
  end
  object Label2: TLabel
    Left = 302
    Top = 87
    Width = 81
    Height = 13
    Caption = 'Create by @!!ex'
  end
  object ComboBoxResolutions: TComboBox
    Left = 8
    Top = 27
    Width = 375
    Height = 21
    Style = csDropDownList
    TabOrder = 0
    OnChange = ComboBoxResolutionsChange
  end
  object ButtonPatch: TButton
    Left = 157
    Top = 54
    Width = 75
    Height = 25
    Caption = 'Patch'
    TabOrder = 1
    OnClick = ButtonPatchClick
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 102
    Width = 390
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object ButtonPatchAndCreateTextues: TButton
    Left = 117
    Top = 54
    Width = 156
    Height = 25
    Caption = 'Patch and create textures'
    TabOrder = 3
    OnClick = ButtonPatchClick
  end
end
