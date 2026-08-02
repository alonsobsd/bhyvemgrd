{ BSD 3-Clause License

Copyright (c) 2026, Alonso Cárdenas <acardenas@bsd-peru.org>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}

unit unit_configuration;

{$mode objfpc}{$H+}

interface

procedure LoadConfig(const PathFile: String);
function ReloadConfig(const PathFile: String):Boolean;

function DebugMode: String;
function RootMode: String;
function VmPath: String;

implementation

uses
  IniFiles;

type
  TConfiguration = record
    DebugMode : String;
    RootMode : String;
    VmPath : String;
  end;

var
  FConfig: TConfiguration;

procedure LoadConfig(const PathFile: String);
var
  ConfigFile: TIniFile;
begin
  ConfigFile := TIniFile.Create(PathFile);
  try
    FConfig.DebugMode := ConfigFile.ReadString('general','debug','no');
    FConfig.RootMode := ConfigFile.ReadString('general','rootmode','mdo');
    FConfig.VmPath := ConfigFile.ReadString('general','vm_path','/usr/local/bhyvemgr');
  finally
    ConfigFile.Free;
  end;
end;

function ReloadConfig(const PathFile: String):Boolean;
var
  ConfigFile: TIniFile;
  TmpVmPath : String;
begin
  Result:=True;

  ConfigFile := TIniFile.Create(PathFile);

  try
    FConfig.DebugMode := ConfigFile.ReadString('general','debug','no');
    FConfig.RootMode := ConfigFile.ReadString('general','rootmode','mdo');

    TmpVmPath:=ConfigFile.ReadString('general','vm_path','/usr/local/bhyvemgr');

    if VmPath <> TmpVmPath then
    begin
      Result:=False;
      FConfig.VmPath := VmPath;
    end;
  finally
    ConfigFile.Free;
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

