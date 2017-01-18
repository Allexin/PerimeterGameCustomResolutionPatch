unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, ShellAPI;

type
  TFormMain = class(TForm)
    Label1: TLabel;
    ComboBoxResolutions: TComboBox;
    ButtonPatch: TButton;
    StatusBar1: TStatusBar;
    ButtonPatchAndCreateTextues: TButton;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ComboBoxResolutionsChange(Sender: TObject);
    procedure ButtonPatchClick(Sender: TObject);
  private
    ApplicationData:PByteArray;
    ApplicationSize:integer;
    ResolutionAddress:array of integer;
    ResolutionCaptionAddress:array of integer;
    GraphicsAvailable:boolean;

    { Private declarations }
    Function CheckSequense(start:integer; size:integer; sequense:PByteArray):boolean;
    Procedure GetAddresses();
    Procedure CheckResolutionTextures();
  public
    { Public declarations }
    Procedure Start();
  end;

  TImageInfo = record
    path:string;
    name:string;
    width:integer;
    height:integer;
  end;

  TResolution = record
    width:integer;
    height:integer;
  end;

var
  FormMain: TFormMain;
const
  IMAGES_COUNT = 20;
  Images:array[0..IMAGES_COUNT-1] of TImageInfo =
  (
    (path:'Resource\Icons\intf\';name:'Back_hback.tga'; width:2048; height:1024;),
    (path:'Resource\Icons\intf\';name:'Back_mperia.tga'; width:2048; height:2048;),
    (path:'Resource\Icons\intf\';name:'Back_xodus.tga'; width:2048; height:1024;),
    (path:'Resource\Icons\intf\';name:'intf.tga'; width:2048; height:2048;),

    (path:'Resource\Icons\MainMenu\';name:'Logo_legion.tga'; width:256; height:512;),
    (path:'Resource\Icons\MainMenu\';name:'Main_menu.tga'; width:1024; height:2048;),
    (path:'Resource\Icons\MainMenu\';name:'main_menu_logo.tga'; width:1024; height:256;),
    (path:'Resource\Icons\MainMenu\';name:'New_death.tga'; width:2048; height:2048;),
    (path:'Resource\Icons\MainMenu\';name:'New_menu.tga'; width:2048; height:2048;),
    (path:'Resource\Icons\MainMenu\';name:'New_statistik.tga'; width:2048; height:2048;),

    (path:'Resource\Icons\Portraits\';name:'Portrait1.tga'; width:256; height:256;),
    (path:'Resource\Icons\Portraits\';name:'Portrait2.tga'; width:256; height:256;),
    (path:'Resource\Icons\Portraits\';name:'Portrait2x.tga'; width:256; height:256;),
    (path:'Resource\Icons\Portraits\';name:'Portrait3.tga'; width:256; height:256;),
    (path:'Resource\Icons\Portraits\';name:'Portrait3x.tga'; width:256; height:256;),
    (path:'Resource\Icons\Portraits\';name:'Portrait4.tga'; width:256; height:256;),
    (path:'Resource\Icons\Portraits\';name:'Portrait5.tga'; width:256; height:256;),
    (path:'Resource\Icons\Portraits\';name:'Portrait6.tga'; width:256; height:256;),
    (path:'Resource\Icons\Portraits\';name:'Portrait6x.tga'; width:256; height:256;),
    (path:'Resource\Icons\Portraits\';name:'Portrait7.tga'; width:256; height:256;)
  );

  RESOLUTION_PATTERN_LENGTH = 24;
  RESOLUTION_SHIFT = 24;
  ResolutionPattern:array[0..RESOLUTION_PATTERN_LENGTH-1] of byte =
  ($20,$03,$00,$00,
   $58,$02,$00,$00,
   $00,$04,$00,$00,
   $00,$03,$00,$00,
   $00,$05,$00,$00,
   $c0,$03,$00,$00);

    RESOLUTIONCAPTION_LENGTH = 9;

  RESOLUTIONCAPTION_PATTERN_LENGTH = 32;
  RESOLUTIONCAPTION_SHIFT = -13;
  ResolutionCaptionPattern:array[0..RESOLUTIONCAPTION_PATTERN_LENGTH-1] of byte =
  (
  $31,$32,$38,$30,$78,$39,$36,$30,$00,$00,$00,$00,
  $31,$30,$32,$34,$78,$37,$36,$38,$00,$00,$00,$00,
  $38,$30,$30,$78,$36,$30,$30,$00
  );

  ApplicationName:string = 'perimeter.exe';

  RESOLUTIONS_COUNT = 18;
  Resolutions: array[0..RESOLUTIONS_COUNT-1] of TResolution =
  (
    (width:320;height:240;),
    (width:480;height:576;),
    (width:640;height:480;),
    (width:854;height:480;),
    (width:960;height:540;),
    (width:1152;height:864;),
    (width:1400;height:1050;),
    (width:1440;height:900;),
    (width:1536;height:960;),
    (width:1600;height:1200;),
    (width:1680;height:1050;),
    (width:1920;height:1080;),
    (width:2048;height:1536;),
    (width:2560;height:1440;),
    (width:3200;height:1800;),
    (width:5120;height:2880;),
    (width:6400;height:4800;),
    (width:7680;height:4320;)
  );


implementation

{$R *.dfm}

Function CheckResolutionTexturesFolder(widthStr:string):boolean;
var
  i:integer;
begin
  Result:=false;
  if not DirectoryExists('Resource\Icons\intf\'+widthStr) then
    Exit;
  if not DirectoryExists('Resource\Icons\MainMenu\'+widthStr) then
    Exit;
  if not DirectoryExists('Resource\Icons\Portraits\'+widthStr) then
    Exit;

  for I := 0 to IMAGES_COUNT-1 do
    if not FileExists(Images[i].path+widthStr+'\'+Images[i].name) then
      Exit;

  Result:=true;
end;

Procedure MakeResolutionDir(dir:string; resolutionWidth:integer);
var
  s:string;
begin
  s:=dir+IntToStr(resolutionWidth);
  if DirectoryExists(s) then
    Exit;
  mkdir(s);
end;

function getPOT(v:integer):integer;
begin
  Result:=2;
  while Result<v do
    Result:=Result*2;
end;

procedure TFormMain.ButtonPatchClick(Sender: TObject);
var
  resolution:TResolution;
  i:integer;
  xScale,yScale:single;
  newWidth,newHeight:integer;
  newPOTWidth,newPOTHeight:integer;
  se:SHELLEXECUTEINFO;
  s:string;
  StringList:TStringList;
  F:integer;
begin
  resolution:=Resolutions[ComboBoxResolutions.ItemIndex];
  if not GraphicsAvailable then begin
    MakeResolutionDir('Resource\Icons\intf\',resolution.width);
    MakeResolutionDir('Resource\Icons\MainMenu\',resolution.width);
    MakeResolutionDir('Resource\Icons\Portraits\',resolution.width);

    xScale:=resolution.width / 1600;
    yScale:=resolution.height / 1200;
    for i := 0 to IMAGES_COUNT-1 do begin
      if not FileExists(Images[i].path+IntToStr(resolution.width)+'\'+Images[i].name) then begin
        StatusBar1.SimpleText:='Processing: '+Images[i].path+IntToStr(resolution.width)+'\'+Images[i].name;
        Application.ProcessMessages;

        newWidth:=trunc(Images[i].width*xScale);
        newHeight:=trunc(Images[i].height*yScale);
        newPOTWidth:=getPOT(newWidth);
        newPOTHeight:=getPOT(newHeight);

        ZeroMemory(@se,sizeof(se));
        se.cbSize:=sizeof(se);
        se.fMask:=SEE_MASK_NOCLOSEPROCESS;
        se.Wnd:=0;
        se.lpVerb:=nil;
        se.lpFile:='ImageMagick\convert.exe';
        se.lpParameters:=PWideChar('"'+Images[i].path+'1600'+'\'+Images[i].name+'"'+' -resize '+IntToStr(newWidth)+'x'+IntToStr(newHeight)+'! '+'"'+Images[i].path+IntToStr(resolution.width)+'\'+'tmp'+Images[i].name+'"');
        se.lpDirectory:=nil;
        se.nShow:=SW_HIDE;
        se.hInstApp:=0;
        ShellExecuteEx(@se);
        WaitForSingleObject(se.hProcess,INFINITE);


        ZeroMemory(@se,sizeof(se));
        se.cbSize:=sizeof(se);
        se.fMask:=SEE_MASK_NOCLOSEPROCESS;
        se.Wnd:=0;
        se.lpVerb:=nil;
        se.lpFile:='ImageMagick\convert.exe';
        se.lpParameters:=PWideChar('"'+Images[i].path+IntToStr(resolution.width)+'\'+'tmp'+Images[i].name+'"'+' -gravity southeast -background transparent -splice '+IntToStr(newPOTWidth-newWidth)+'x'+IntToStr(newPOTHeight-newHeight)+' '+'"'+Images[i].path+IntToStr(resolution.width)+'\'+Images[i].name+'"');
        se.lpDirectory:=nil;
        se.nShow:=SW_HIDE;
        se.hInstApp:=0;
        ShellExecuteEx(@se);
        WaitForSingleObject(se.hProcess,INFINITE);

        DeleteFile(Images[i].path+IntToStr(resolution.width)+'\'+'tmp'+Images[i].name);
      end;
    end;
  end;

  s:=IntToStr(resolution.width)+'x'+IntToStr(resolution.height);

    ApplicationData[ResolutionAddress[0]+0]:=resolution.width mod 256;
    ApplicationData[ResolutionAddress[0]+1]:=resolution.width div 256;
    ApplicationData[ResolutionAddress[0]+4]:=resolution.height mod 256;
    ApplicationData[ResolutionAddress[0]+5]:=resolution.height div 256;

    for I := 0 to RESOLUTIONCAPTION_LENGTH-1 do
      if i<=Length(s) then
        ApplicationData[ResolutionCaptionAddress[0]+i]:=ord(s[i])
      else
        ApplicationData[ResolutionCaptionAddress[0]+i]:=$00;

    F:=FileOpen(ApplicationName, fmOpenWrite);
    if (F=-1) then begin
      ShowMessage('Error: Can''t write to file "'+ApplicationName+'"');
      Exit;
    end;
    FileWrite(F, ApplicationData^, ApplicationSize);
    FileClose(F);

    StringList:=TStringList.Create;
    StringList.LoadFromFile('Perimeter.ini');

    for i := 0 to StringList.Count-1 do begin
      if pos('ScreenSizeX=',StringList.Strings[i])>0 then
        StringList.Strings[i]:='ScreenSizeX='+IntToStr(resolution.width);
      if pos('ScreenSizeY=',StringList.Strings[i])>0 then
        StringList.Strings[i]:='ScreenSizeY='+IntToStr(resolution.height);
    end;

    StringList.SaveToFile('Perimeter.ini');
    StringList.Free();

    ShowMessage('Resolution set');
    Close();
end;

procedure TFormMain.CheckResolutionTextures;
var
  resolution:TResolution;
begin
  GraphicsAvailable:=false;
  if (ComboBoxResolutions.ItemIndex=-1) then
    Exit;

  resolution:=Resolutions[ComboBoxResolutions.ItemIndex];
  GraphicsAvailable:=CheckResolutionTexturesFolder(IntToStr(resolution.width));

  ButtonPatch.Visible:=GraphicsAvailable;
  ButtonPatchAndCreateTextues.Visible:=not GraphicsAvailable;
end;

function TFormMain.CheckSequense(start, size: integer;
  sequense: PByteArray): boolean;
var
  i:integer;
  d,s:byte;
begin
  Result:=false;
  for i := 0 to size-1 do begin
    d:=ApplicationData[start+i];
    s:=sequense[i];
    if d<>s then
      Exit;
  end;
  Result:=true;
end;

procedure TFormMain.ComboBoxResolutionsChange(Sender: TObject);
begin
  CheckResolutionTextures();
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  i:integer;
begin
  ComboBoxResolutions.Items.Clear();
  for i := 0 to RESOLUTIONS_COUNT-1 do
    ComboBoxResolutions.Items.Add(IntToStr(Resolutions[i].width)+'x'+IntToStr(Resolutions[i].height));
  ComboBoxResolutions.ItemIndex:=-1;
end;

Procedure TFormMain.GetAddresses();
var
  i:integer;
  b:byte;
begin
  SetLength(ResolutionAddress,0);
  SetLength(ResolutionCaptionAddress,0);

  for i := 0 to ApplicationSize-1 do begin
    b:=ApplicationData[i];
    if (b=ResolutionPattern[0]) and (i+RESOLUTION_PATTERN_LENGTH<ApplicationSize) then begin
      if (CheckSequense(i,RESOLUTION_PATTERN_LENGTH,@ResolutionPattern[0])) then begin
        SetLength(ResolutionAddress,Length(ResolutionAddress)+1);
        ResolutionAddress[Length(ResolutionAddress)-1]:=i+RESOLUTION_SHIFT;;
      end;
    end;
    if (b=ResolutionCaptionPattern[0]) and (i+RESOLUTIONCAPTION_PATTERN_LENGTH<ApplicationSize) then begin
      if (CheckSequense(i,RESOLUTIONCAPTION_PATTERN_LENGTH,@ResolutionCaptionPattern[0])) then begin
        SetLength(ResolutionCaptionAddress,Length(ResolutionCaptionAddress)+1);
        ResolutionCaptionAddress[Length(ResolutionCaptionAddress)-1]:=i+RESOLUTIONCAPTION_SHIFT;
      end;
    end;
  end;
end;

procedure TFormMain.Start;
var
  F:integer;
  w,h:integer;
  i:integer;
begin
  F:=FileOpen(ApplicationName, fmOpenRead);
  if (F=-1) then begin
    ShowMessage('Critical error: Application "'+ApplicationName+'" not found.');
    Close();
    Exit;
  end;

  ApplicationSize:=GetFileSize(F,nil);
  if (ApplicationSize<=0) or (ApplicationSize>1024*1024*1024) then begin
    ShowMessage('Critical error: Can''t access file "'+ApplicationName+'"');
    Close();
    FileClose(F);
    Exit;
  end;

  ApplicationData:=GetMemory(ApplicationSize);
  FileRead(F, ApplicationData^, ApplicationSize);
  FileClose(F);

  GetAddresses();

  if (Length(ResolutionAddress)=0) or (Length(ResolutionCaptionAddress)=0) then begin
    ShowMessage('Critical error: Can''t find resolution sequenses in file "'+ApplicationName+'"');
    Close();
    Exit;
  end;

  if (Length(ResolutionAddress)>1) or (Length(ResolutionCaptionAddress)>1) then begin
    ShowMessage('Critical error: Found too many resolution sequenses in file "'+ApplicationName+'"');
    Close();
    Exit;
  end;

  StatusBar1.SimpleText:='Resolution address:'+intToHex(ResolutionAddress[0],6)+' Caption address: '+intToHex(ResolutionCaptionAddress[0],6);

  w:=ApplicationData[ResolutionAddress[0]+0] + ApplicationData[ResolutionAddress[0]+1]*256;
  h:=ApplicationData[ResolutionAddress[0]+4] + ApplicationData[ResolutionAddress[0]+5]*256;

  for i := 0 to RESOLUTIONS_COUNT-1 do begin
    if (Resolutions[i].width=w) and (Resolutions[i].height=h) then begin
      ComboBoxResolutions.ItemIndex:=i;
      break;
    end;
  end;

  CheckResolutionTextures();
end;

end.
