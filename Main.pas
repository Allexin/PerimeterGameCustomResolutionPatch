unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, ShellAPI, IOUtils, Registry;

type
  TFormMain = class(TForm)
    Label1: TLabel;
    ComboBoxResolutions: TComboBox;
    ButtonPatch: TButton;
    StatusBar1: TStatusBar;
    Label2: TLabel;
    ComboBoxLang: TComboBox;
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

  TSize = record
    width:integer;
    height:integer;
  end;

  TImageInfo = record
    path:string;
    name:string;
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
    (path:'Resource\Icons\intf\';name:'Back_hback.tga';),
    (path:'Resource\Icons\intf\';name:'Back_mperia.tga'; ),
    (path:'Resource\Icons\intf\';name:'Back_xodus.tga'; ),
    (path:'Resource\Icons\intf\';name:'intf.tga'; ),

    (path:'Resource\Icons\MainMenu\';name:'Logo_legion.tga';),
    (path:'Resource\Icons\MainMenu\';name:'Main_menu.tga'; ),
    (path:'Resource\Icons\MainMenu\';name:'main_menu_logo.tga';),
    (path:'Resource\Icons\MainMenu\';name:'New_death.tga'; ),
    (path:'Resource\Icons\MainMenu\';name:'New_menu.tga'; ),
    (path:'Resource\Icons\MainMenu\';name:'New_statistik.tga'; ),

    (path:'Resource\Icons\Portraits\';name:'Portrait1.tga'; ),
    (path:'Resource\Icons\Portraits\';name:'Portrait2.tga'; ),
    (path:'Resource\Icons\Portraits\';name:'Portrait2x.tga'; ),
    (path:'Resource\Icons\Portraits\';name:'Portrait3.tga'; ),
    (path:'Resource\Icons\Portraits\';name:'Portrait3x.tga'; ),
    (path:'Resource\Icons\Portraits\';name:'Portrait4.tga'; ),
    (path:'Resource\Icons\Portraits\';name:'Portrait5.tga'; ),
    (path:'Resource\Icons\Portraits\';name:'Portrait6.tga'; ),
    (path:'Resource\Icons\Portraits\';name:'Portrait6x.tga'; ),
    (path:'Resource\Icons\Portraits\';name:'Portrait7.tga'; )
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
var
  Resolutions:array of TResolution;
  SourceResolutions:array of TResolution;

implementation

{$R *.dfm}
type
 TAnoPipe=record
    Input : THandle;
    Output: THandle;
  end;

function ExecAndCapture(const ACmdLine: string; var AOutput: string): Integer;
const
  cBufferSize = 2048;
var
  vBuffer: Pointer;
  vStartupInfo: TStartUpInfo;
  vSecurityAttributes: TSecurityAttributes;
  vReadBytes: DWord;
  vProcessInfo: TProcessInformation;
  vStdInPipe : TAnoPipe;
  vStdOutPipe: TAnoPipe;
begin
  Result := 0;

  with vSecurityAttributes do
  begin
    nlength := SizeOf(TSecurityAttributes);
    binherithandle := True;
    lpsecuritydescriptor := nil;
  end;

  // Create anonymous pipe for standard input
  if not CreatePipe(vStdInPipe.Output, vStdInPipe.Input, @vSecurityAttributes, 0) then
    raise Exception.Create('Failed to create pipe for standard input. System error message: ' + SysErrorMessage(GetLastError));

  try
    // Create anonymous pipe for standard output (and also for standard error)
    if not CreatePipe(vStdOutPipe.Output, vStdOutPipe.Input, @vSecurityAttributes, 0) then
      raise Exception.Create('Failed to create pipe for standard output. System error message: ' + SysErrorMessage(GetLastError));

    try
      GetMem(vBuffer, cBufferSize);
      try
        // initialize the startup info to match our purpose
        FillChar(vStartupInfo, Sizeof(TStartUpInfo), #0);
        vStartupInfo.cb         := SizeOf(TStartUpInfo);
        vStartupInfo.wShowWindow:= SW_HIDE;  // we don't want to show the process
        // assign our pipe for the process' standard input
        vStartupInfo.hStdInput  := vStdInPipe.Output;
        // assign our pipe for the process' standard output
        vStartupInfo.hStdOutput := vStdOutPipe.Input;
        vStartupInfo.dwFlags    := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;

        if not CreateProcess(nil
                             , PChar(ACmdLine)
                             , @vSecurityAttributes
                             , @vSecurityAttributes
                             , True
                             , NORMAL_PRIORITY_CLASS
                             , nil
                             , nil
                             , vStartupInfo
                             , vProcessInfo) then
          raise Exception.Create('Failed creating the console process. System error msg: ' + SysErrorMessage(GetLastError));

        try
          // wait until the console program terminated
          while WaitForSingleObject(vProcessInfo.hProcess, 50)=WAIT_TIMEOUT do
            Sleep(0);

          // clear the output storage
          AOutput := '';
          // Read text returned by the console program in its StdOut channel
          repeat
            ReadFile(vStdOutPipe.Output, vBuffer^, cBufferSize, vReadBytes, nil);
            if vReadBytes > 0 then
            begin
              AOutput := AOutput + StrPas(PAnsiChar(vBuffer));
              Inc(Result, vReadBytes);
            end;
          until (vReadBytes < cBufferSize);
        finally
          CloseHandle(vProcessInfo.hProcess);
          CloseHandle(vProcessInfo.hThread);
        end;
      finally
        FreeMem(vBuffer);
      end;
    finally
      CloseHandle(vStdOutPipe.Input);
      CloseHandle(vStdOutPipe.Output);
    end;
  finally
    CloseHandle(vStdInPipe.Input);
    CloseHandle(vStdInPipe.Output);
  end;
end;

Function CheckResolutionTexturesFolder(widthStr:string; heightStr:string):boolean;
var
  i:integer;
begin
  Result:=false;
  if not DirectoryExists('CustomResolution\Resource\Icons\intf\'+widthStr+'x'+heightStr) then
    Exit;
  if not DirectoryExists('CustomResolution\Resource\Icons\MainMenu\'+widthStr+'x'+heightStr) then
    Exit;
  if not DirectoryExists('CustomResolution\Resource\Icons\Portraits\'+widthStr+'x'+heightStr) then
    Exit;

  for I := 0 to IMAGES_COUNT-1 do
    if not FileExists('CustomResolution\'+Images[i].path+widthStr+'x'+heightStr+'\'+Images[i].name) then
      Exit;

  Result:=true;
end;

Procedure MakeResolutionDir(dir:string; resolutionWidth,resolutionHeight:integer);
var
  s:string;
begin
  s:=dir+IntToStr(resolutionWidth)+'x'+IntToStr(resolutionHeight);
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
  aspect:single;
  src:string;
  dst:string;
  GenF:TextFile;
  res:string;
  Size:TSize;
  p:integer;
  minDiff:single;
  minID:integer;
  diff:single;
var R: TRegistry;
begin
  resolution:=Resolutions[ComboBoxResolutions.ItemIndex];
  if not GraphicsAvailable then begin
    MakeResolutionDir('CustomResolution\Resource\Icons\intf\',resolution.width,resolution.height);
    MakeResolutionDir('CustomResolution\Resource\Icons\MainMenu\',resolution.width,resolution.height);
    MakeResolutionDir('CustomResolution\Resource\Icons\Portraits\',resolution.width,resolution.height);

    AssignFile(GenF,'CustomResolution\Resource\Icons\MainMenu\'+IntToStr(resolution.width)+'x'+IntToStr(resolution.height)+'\Gen');
    Rewrite(GenF);
    CloseFile(GenF);

    aspect:=resolution.width / resolution.height;

    minDiff:=abs(SourceResolutions[0].width/SourceResolutions[0].height-aspect);
    minID:=0;
    for i := 1 to Length(SourceResolutions)-1 do begin
       diff:=abs(SourceResolutions[i].width/SourceResolutions[i].height - aspect);
       if diff<minDiff then begin
         minDiff:=diff;
         minID:=i;
       end;
    end;


    dst:=IntToStr(resolution.width)+'x'+IntToStr(resolution.height);
    src:=IntToStr(SourceResolutions[minID].width)+'x'+IntToStr(SourceResolutions[minID].height);
    xScale:=resolution.width / SourceResolutions[minID].width;
    yScale:=resolution.height / SourceResolutions[minID].height;

    for i := 0 to IMAGES_COUNT-1 do begin
      if not FileExists('CustomResolution\'+Images[i].path+dst+'\'+Images[i].name) then begin
        StatusBar1.SimpleText:='Processing: '+'CustomResolution\'+Images[i].path+dst+'\'+Images[i].name;
        Application.ProcessMessages;

        ExecAndCapture('ImageMagick\identify.exe '+' -format "%wx%h" "CustomResolution\'+Images[i].path+src+'\'+Images[i].name+'" > '+'"CustomResolution\'+Images[i].path+src+'\'+Images[i].name+'.info"',res);

        p:=pos('x',res);
        if p>0 then begin
          if TryStrToInt(copy(res,1,p-1),Size.width) and TryStrToInt(copy(res,p+1),Size.height) then begin

          end
          else begin
            ShowMessage('Cant create new resolution. Incorrect source '+src);
            Exit;
          end;
        end;

        newWidth:=trunc(Size.width*xScale);
        newHeight:=trunc(Size.height*yScale);
        newPOTWidth:=getPOT(newWidth);
        newPOTHeight:=getPOT(newHeight);

        ZeroMemory(@se,sizeof(se));
        se.cbSize:=sizeof(se);
        se.fMask:=SEE_MASK_NOCLOSEPROCESS;
        se.Wnd:=0;
        se.lpVerb:=nil;
        se.lpFile:='ImageMagick\convert.exe';
        se.lpParameters:=PWideChar('"CustomResolution\'+Images[i].path+src+'\'+Images[i].name+'"'+' -resize '+IntToStr(newWidth)+'x'+IntToStr(newHeight)+'! '+'"CustomResolution\'+Images[i].path+dst+'\'+'tmp'+Images[i].name+'"');
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
        se.lpParameters:=PWideChar('"CustomResolution\'+Images[i].path+dst+'\'+'tmp'+Images[i].name+'"'+' -gravity southeast -background transparent -splice '+IntToStr(newPOTWidth-newWidth)+'x'+IntToStr(newPOTHeight-newHeight)+' '+'"CustomResolution\'+Images[i].path+dst+'\'+Images[i].name+'"');
        se.lpDirectory:=nil;
        se.nShow:=SW_HIDE;
        se.hInstApp:=0;
        ShellExecuteEx(@se);
        WaitForSingleObject(se.hProcess,INFINITE);

        DeleteFile(Images[i].path+IntToStr(resolution.width)+'\'+'tmp'+Images[i].name);
      end;
    end;
  end;

  ZeroMemory(@se,sizeof(se));
  se.cbSize:=sizeof(se);
  se.fMask:=SEE_MASK_NOCLOSEPROCESS;
  se.Wnd:=0;
  se.lpVerb:=nil;
  se.lpFile:=PWideChar('resolutions\'+IntToStr(resolution.width)+'x'+IntToStr(resolution.height)+'.bat');
  se.lpParameters:=PWideChar(ComboBoxLang.Items[ComboBoxLang.ItemIndex]);
  se.lpDirectory:=nil;
  se.nShow:=SW_SHOWNORMAL;
  se.hInstApp:=0;
  ShellExecuteEx(@se);
  WaitForSingleObject(se.hProcess,INFINITE);


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

  R := TRegistry.Create();
  R.RootKey:=HKEY_CURRENT_USER;
  try
    if R.OpenKey('Software\Codemasters\Perimeter\Intf', True) then begin
      R.WriteString('Locale', ComboBoxLang.Items[ComboBoxLang.ItemIndex]);
    end;
  finally
    R.Free;
    ShowMessage('Resolution set');
    Close();
  end;
end;

procedure TFormMain.CheckResolutionTextures;
var
  resolution:TResolution;
begin
  GraphicsAvailable:=false;
  if (ComboBoxResolutions.ItemIndex=-1) then
    Exit;

  resolution:=Resolutions[ComboBoxResolutions.ItemIndex];
  GraphicsAvailable:=CheckResolutionTexturesFolder(IntToStr(resolution.width),IntToStr(resolution.height));
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
  fullName,fileName, folderName:string;

  R:TResolution;
  p:integer;
begin
  ComboBoxResolutions.Items.Clear();
  for fullName in TDirectory.GetFiles('resolutions\') do begin
    if UpperCase(ExtractFileExt(fullName))='.BAT' then begin
      fileName:=ExtractFileName(fullName);
      fileName:=copy(fileName, 1, length(filename)-4);
      p:=pos('x',fileName);
      if p>0 then begin
        if TryStrToInt(copy(fileName,1,p-1),R.width) and TryStrToInt(copy(fileName,p+1),R.height) then begin
          SetLength(Resolutions,Length(Resolutions)+1);
          Resolutions[Length(Resolutions)-1]:=R;
          ComboBoxResolutions.Items.Add(IntToStr(R.width)+'x'+IntToStr(R.height));
        end;
      end;
    end;
  end;
  ComboBoxResolutions.ItemIndex:=-1;

  for fullName in TDirectory.GetDirectories('CustomResolution\Resource\Icons\MainMenu\') do begin
    folderName:=ExtractFileName(fullName);
    p:=pos('x',folderName);
    if p>0 then begin
      if TryStrToInt(copy(folderName,1,p-1),R.width) and TryStrToInt(copy(folderName,p+1),R.height) then begin
        if CheckResolutionTexturesFolder(IntToStr(r.width),IntToStr(r.height)) then begin
          if not FileExists('CustomResolution\Resource\Icons\MainMenu\'+IntToStr(r.width)+'x'+IntToStr(r.height)+'\Gen') then begin
            SetLength(SourceResolutions,Length(SourceResolutions)+1);
            SourceResolutions[Length(SourceResolutions)-1]:=R;
          end;
        end;
      end;
    end;
  end;

  if Length(SourceResolutions)=0 then begin
    ShowMessage('cant find source textures to generate new resolutions');
    Close;
  end;
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
  StringList:TStringList;
begin
  if not FileExists('Perimeter.ini') then begin
    ShowMessage('Critical error: Config "Perimeter.ini" not found.');
    Close();
    Exit;
  end;


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

  for i := 0 to Length(Resolutions)-1 do begin
    if (Resolutions[i].width=w) and (Resolutions[i].height=h) then begin
      ComboBoxResolutions.ItemIndex:=i;
      break;
    end;
  end;

  StringList:=TStringList.Create;
  StringList.LoadFromFile('Perimeter.ini');

  for i := 0 to StringList.Count-1 do begin
    if pos('DefaultLanguage=Russian',StringList.Strings[i])>0 then begin
      ComboBoxLang.ItemIndex:=0;
      break;
    end;
    if pos('DefaultLanguage=English',StringList.Strings[i])>0 then begin
      ComboBoxLang.ItemIndex:=1;
      break;
    end;
  end;
  StringList.Free();

  CheckResolutionTextures();
end;

end.
