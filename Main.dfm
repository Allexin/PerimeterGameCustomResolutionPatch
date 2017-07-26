object FormMain: TFormMain
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Perimeter GW Custom Resolution and fixes'
  ClientHeight = 209
  ClientWidth = 391
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    391
    209)
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
    Left = 296
    Top = 173
    Width = 87
    Height = 13
    Caption = 'Created by @!!ex'
  end
  object Label3: TLabel
    Left = 8
    Top = -65
    Width = 21
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'Log:'
    ExplicitTop = 173
  end
  object ListBoxLog: TListBox
    Left = 8
    Top = 192
    Width = 375
    Height = 230
    Anchors = [akLeft, akTop, akRight]
    ItemHeight = 13
    TabOrder = 4
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
    Left = 308
    Top = 142
    Width = 75
    Height = 25
    Caption = 'Patch'
    TabOrder = 1
    OnClick = ButtonPatchClick
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 190
    Width = 391
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object ComboBoxLang: TComboBox
    Left = 8
    Top = 54
    Width = 145
    Height = 21
    Style = csDropDownList
    TabOrder = 2
    Items.Strings = (
      'Use default')
  end
  object CheckBoxFullScreen: TCheckBox
    Left = 8
    Top = 80
    Width = 97
    Height = 17
    Caption = 'Fullscreen'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end
  object CheckBoxFreeCamera: TCheckBox
    Left = 8
    Top = 120
    Width = 97
    Height = 17
    Caption = 'Free camera'
    TabOrder = 6
  end
  object CheckBoxEditorMode: TCheckBox
    Left = 8
    Top = 140
    Width = 97
    Height = 17
    Caption = 'Editor mode'
    TabOrder = 7
    OnClick = CheckBoxEditorModeClick
  end
  object CheckBoxSplash: TCheckBox
    Left = 8
    Top = 100
    Width = 97
    Height = 17
    Caption = 'Show intro'
    TabOrder = 8
  end
end
