{ SPDX-License-Identifier: BSD-3-Clause

Copyright (c) 2026, J. Alonso Cárdenas <acardenas@bsd-peru.org>

}

unit unit_configuration;

{$mode objfpc}{$H+}

interface

procedure LoadConfig(const PathFile: String; const CommonPathFile: String);
function ReloadConfig(const PathFile: String; const CommonPathFile: String):Boolean;

function DebugMode: String;
function RootMode: String;
function VmPath: String;

implementation

uses
  sysutils, IniFiles, unit_global;

type
  TConfiguration = record
    DebugMode : String;
    RootMode : String;
    VmPath : String;
  end;

var
  FConfig: TConfiguration;

procedure LoadConfig(const PathFile: String; const CommonPathFile: String);
var
  ConfigFile: TIniFile;
  CommonConfigFile : TIniFile;
begin
  ConfigFile := TIniFile.Create(PathFile);
  CommonConfigFile := TIniFile.Create(CommonPathFile);

  try
    FConfig.DebugMode := ConfigFile.ReadString('daemon','debug','no');
    FConfig.RootMode := ConfigFile.ReadString('daemon','root_mode','mdo');
    FConfig.VmPath := CommonConfigFile.ReadString('common','vm_path','/usr/local/bhyvemgr');
  finally
    ConfigFile.Free;
    CommonConfigFile.Free;
  end;
end;

function ReloadConfig(const PathFile: String; const CommonPathFile: String):Boolean;
var
  ConfigFile: TIniFile;
  CommonConfigFile : TIniFile;
  TmpVmPath : String;
begin
  Result:=True;

  ConfigFile := TIniFile.Create(PathFile);
  CommonConfigFile := TIniFile.Create(CommonPathFile);
  try
    FConfig.DebugMode := ConfigFile.ReadString('daemon','debug','no');

    if (GetOsreldate.ToInt64 >= 1501501) and (ConfigFile.ReadString('daemon','root_mode', EmptyStr) = 'setcred') then
      FConfig.RootMode := ConfigFile.ReadString('daemon','root_mode','setcred')
    else
      FConfig.RootMode := ConfigFile.ReadString('daemon','root_mode','mdo');

    TmpVmPath:=CommonConfigFile.ReadString('common','vm_path','/usr/local/bhyvemgr');

    if VmPath <> TmpVmPath then
    begin
      Result:=False;
      FConfig.VmPath := VmPath;
    end;
  finally
    ConfigFile.Free;
    CommonConfigFile.Free;
  end;
end;

function DebugMode: String;
begin
  Result := FConfig.DebugMode;
end;

function RootMode: String;
begin
  Result := FConfig.RootMode;
end;

function VmPath: String;
begin
  Result := FConfig.VmPath;
end;

finalization

begin
  FConfig.DebugMode := '';
  FConfig.RootMode := '';
  FConfig.VmPath := '';
end;

end.

