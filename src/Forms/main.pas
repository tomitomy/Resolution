unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, FileUtil, Forms, Controls, Graphics,
  Dialogs, ComCtrls, StdCtrls, IniFiles;

type
              
  { TDisplay }

  TDisplay = class
    private
      AConfig: string;
      ACurrent: Integer;
      APrimary: Integer;
      AList: array of record
        Name: string;
        Disable: Boolean;
        Resolutions: string;
        Light: Integer;
      end;
      function GetCurrent: string;
      function GetOutputs: string;
      procedure SetCurrent(AValue: string);
      function GetPrimary: string;
      procedure SetPrimary(AValue: string);
      function GetName: string;
      procedure SetName(AValue: string);
      function GetDisable: Boolean;
      procedure SetDisable(AValue: Boolean);
      function GetResolutions: string;
      procedure SetResolutions(AValue: string);
      function GetLight: Integer;
      procedure SetLight(AValue: Integer);
      procedure Load;
      procedure Save;
    public
      constructor Create(ConfigFile: string);
      destructor Destroy; override;
      procedure Add;
      property Outputs: string read GetOutputs;
      property Primary: string read GetPrimary write SetPrimary;
      property Current: string read GetCurrent write SetCurrent;
      property Name: string read GetName write SetName;
      property Disable: Boolean read GetDisable write SetDisable;
      property Resolutions: string read GetResolutions write SetResolutions;
      property Light: Integer read GetLight write SetLight;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    chkbDisabled: TCheckBox;
    chkbPrimary: TCheckBox;
    combOutputs: TComboBox;
    lstbResolutions: TListBox;
    trcbLight: TTrackBar;
    procedure chkbDisabledChange(Sender: TObject);
    procedure chkbPrimaryChange(Sender: TObject);
    procedure combOutputsSelect(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lstbResolutionsDblClick(Sender: TObject);
    procedure trcbLightChange(Sender: TObject);
  private
  public
    Display: TDisplay;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}
        
{ Common }

function ExecuteCommand(strCommandLine: string): boolean;
var
  NewProcess: TProcess;
begin
  NewProcess := TProcess.Create(nil);
  try
    NewProcess.CommandLine := strCommandLine;
    NewProcess.Options := [poStderrToOutPut, poNoConsole, poUsePipes];

    NewProcess.Execute;
  finally
    NewProcess.Free;
    Result := True;
  end;
end;

function ExecuteCommand(strCommandLine: string; out strsOutPut : TStringList): boolean;
var
  NewProcess: TProcess;
begin
  NewProcess := TProcess.Create(nil);
  try
    NewProcess.CommandLine := strCommandLine;
    NewProcess.Options := [poStderrToOutPut, poNoConsole, poUsePipes];

    NewProcess.Execute;
    strsOutPut.LoadFromStream(NewProcess.Output);
  finally
    NewProcess.Free;
    Result := True;
  end;
end;

function GetSubString(S: string; Index: SizeInt; Splitter: Char = ' '): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do begin
    if S[i] = Splitter then begin
      if Result = '' then continue;
      if Index <= 1 then Exit;
      Dec(Index);
      Result := '';
    end else
      Result := Result + S[i];
  end;
end;

{ TDisplay }
               
constructor TDisplay.Create(ConfigFile: string);
begin
  inherited Create;
  AConfig := ConfigFile;
  ACurrent := -1;
  APrimary := -1;
  Load;
end;

destructor TDisplay.Destroy;
begin
  Save;
  SetLength(AList, 0);
  inherited Destroy;
end;

procedure TDisplay.Add;
begin
  ACurrent := Length(AList);
  SetLength(AList, ACurrent + 1);
end;
              
function TDisplay.GetOutputs: string;
var
  i: Integer;
begin
  Result := '';
  for i := Low(AList) to High(AList) do
    if Result = '' then
      Result := AList[i].Name
    else
      Result := Result + #10 + AList[i].Name;
end;

function TDisplay.GetCurrent: string;
begin
  Result := '';
  if ACurrent = -1 then Exit;
  Result := AList[ACurrent].Name;
end;

procedure TDisplay.SetCurrent(AValue: string);
var
  i: Integer;
begin
  for i := Low(AList) to High(AList) do
    if AList[i].Name = AValue then begin
      ACurrent := i;
      Break;
    end;
end;
             
function TDisplay.GetPrimary: string;
begin
  Result := '';
  if APrimary = -1 then Exit;
  Result := AList[APrimary].Name;
end;

procedure TDisplay.SetPrimary(AValue: string);
var
  i: Integer;
begin
  for i := Low(AList) to High(AList) do
    if AList[i].Name = AValue then begin
      APrimary := i;
      Break;
    end;
end;

function TDisplay.GetName: string;
begin
  Result := '';
  if ACurrent = -1 then Exit;
  Result := AList[ACurrent].Name;
end;

procedure TDisplay.SetName(AValue: string);
begin
  if ACurrent = -1 then Exit;
  AList[ACurrent].Name := AValue;
end;

function TDisplay.GetDisable: Boolean;
begin                     
  Result := False;
  if ACurrent = -1 then Exit;
  Result := AList[ACurrent].Disable;
end;

procedure TDisplay.SetDisable(AValue: Boolean);
begin
  if ACurrent = -1 then Exit;
  AList[ACurrent].Disable := AValue;
end;

function TDisplay.GetResolutions: string;
begin                    
  Result := '';
  if ACurrent = -1 then Exit;
  Result := AList[ACurrent].Resolutions;
end;

procedure TDisplay.SetResolutions(AValue: string);
begin
  if ACurrent = -1 then Exit;
  AList[ACurrent].Resolutions := AValue;
end;

function TDisplay.GetLight: Integer;
begin
  Result := 1;
  if ACurrent = -1 then Exit;
  Result := AList[ACurrent].Light;
end;

procedure TDisplay.SetLight(AValue: Integer);
begin
  if ACurrent = -1 then Exit;
  AList[ACurrent].Light := AValue;
end;

procedure TDisplay.Load;
var
  i: Integer;
  Ini: TIniFile;
  strsOutPut: TStringList;
  CurrentName: string;
begin
  Ini := TIniFile.Create(AConfig);
  try
    strsOutPut := TStringList.Create;
    try
      ExecuteCommand('xrandr', strsOutPut);
      for i := 1 to strsOutPut.Count - 1 do begin
        if not strsOutPut[i].StartsWith('   ') then begin
          if GetSubString(strsOutPut[i], 2) = 'connected' then begin
            Add;
            Name := GetSubString(strsOutPut[i], 1);
            Disable := Ini.ReadBool(Name, 'Disabled', False);
            Light := Ini.ReadInteger(Name, 'Light', 6);
            Resolutions := StringReplace(Trim(Ini.ReadString(Name, 'Resolutions', '800 600|1024 768')), 'x', ' ', [rfReplaceAll]);
            if Ini.ReadBool(Name, 'Current', False) then CurrentName := Name;
            if GetSubString(strsOutPut[i], 3) = 'primary' then Primary := Name;
          end;
        end;
      end;
    finally
      strsOutPut.Free;
    end;
  finally
    Ini.Free;
  end;
  Current := CurrentName;
  if not FileExists(ChangeFileExt(Application.ExeName, '.ini')) then Save;
end;

procedure TDisplay.Save;
var
  i: Integer;
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(AConfig);
  try
    for i := Low(AList) to High(AList) do begin
      Ini.WriteBool(AList[i].Name, 'Current', AList[i].Name = Current);
      Ini.WriteBool(AList[i].Name, 'Disabled', AList[i].Disable);
      Ini.WriteInteger(AList[i].Name, 'Light', AList[i].Light);
      Ini.WriteString(AList[i].Name, 'Resolutions', AList[i].Resolutions);
    end;
  finally
    Ini.Free;
  end;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  Display := TDisplay.Create(ChangeFileExt(Application.ExeName, '.ini'));

  combOutputs.Items.Text := Display.Outputs;

  if (combOutputs.Items.Count > 0) then begin
    for i := 0 to combOutputs.Items.Count - 1 do
      if combOutputs.Items[i] = Display.Current then begin
        combOutputs.ItemIndex := i;
      end;
    if (combOutputs.ItemIndex = -1) then combOutputs.ItemIndex := 0;
  end;

  combOutputs.OnSelect(nil);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Display.Destroy;
end;

procedure TForm1.combOutputsSelect(Sender: TObject);
begin
  if (combOutputs.ItemIndex = -1) then begin
    chkbPrimary.Enabled := False;
    chkbDisabled.Enabled := False;
    lstbResolutions.Enabled := False;
    trcbLight.Enabled := False;
    Exit;
  end;
  Display.Current := combOutputs.Text;
  lstbResolutions.Items.Delimiter := '|';
  lstbResolutions.Items.StrictDelimiter := True;
  lstbResolutions.Items.DelimitedText := Display.Resolutions;
  trcbLight.Position := Display.Light;
  if chkbPrimary.Checked <> (Display.Current = Display.Primary) then
    chkbPrimary.Checked := (Display.Current = Display.Primary)
  else
    chkbPrimary.OnChange(nil);
end;
             
procedure TForm1.chkbPrimaryChange(Sender: TObject);
begin           
  chkbPrimary.Enabled := not chkbPrimary.Checked;
  chkbDisabled.Enabled := not chkbPrimary.Checked;
  if chkbPrimary.Checked then begin
    Display.Primary := Display.Current;
    chkbDisabled.Checked := False;
    ExecuteCommand('xrandr --output ' + Display.Current + ' --primary');
  end else
    chkbDisabled.Checked := Display.Disable;
end;

procedure TForm1.chkbDisabledChange(Sender: TObject);
begin
  lstbResolutions.Enabled := not chkbDisabled.Checked;
  trcbLight.Enabled := not chkbDisabled.Checked;

  Display.Disable := chkbDisabled.Checked;
  if chkbDisabled.Checked then begin
    ExecuteCommand('xrandr --output ' + Display.Current + ' --off');
  end else begin
    ExecuteCommand('xrandr --output ' + Display.Current + ' --auto');
  end;
end;

procedure TForm1.lstbResolutionsDblClick(Sender: TObject);
var
  i: Integer;
  Modeline: string;
  Resolution: string;
  strsOutPut : TStringList;
begin
  if (combOutputs.Text = '') or (lstbResolutions.ItemIndex < 0) or (chkbDisabled.Checked) then Exit;
  strsOutPut := TStringList.Create;
  try
    ExecuteCommand('cvt ' + lstbResolutions.Items[lstbResolutions.ItemIndex], strsOutPut);
    for i := 0 to strsOutPut.Count - 1 do begin
      if strsOutPut[i].StartsWith('Modeline', True) then begin
        Modeline := Copy(strsOutPut[i], 10, Length(strsOutPut[i]) - 10);
        resolution := Copy(ModeLine, 2, Length(ModeLine) - 1);
        resolution := Copy(Modeline, 2, Pos('"', resolution) - 1);
      end;
    end;
    ExecuteCommand('xrandr --newmode ' + ModeLine);
    ExecuteCommand('xrandr --addmode ' + combOutputs.Text + ' ' + resolution);
    ExecuteCommand('xrandr --output ' + combOutputs.Text + ' --mode ' + resolution);
  finally
    strsOutPut.Free;
  end;
  trcbLight.OnChange(nil);
end;
    
procedure TForm1.trcbLightChange(Sender: TObject);
begin
  if (Display.Current = '') or (Display.Disable) then Exit;
  ExecuteCommand('xrandr --output ' + Display.Current + ' --brightness ' + FloatToStr(trcbLight.Position/10));
  Display.Light := trcbLight.Position;
end;

end.

