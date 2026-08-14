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

unit unit_util;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, BaseUnix;

function ActivateSetcred():Boolean;
function DeactivateSetcred():Boolean;
function CheckKernelModule(Module: String): Boolean;
function CheckSysctl(const Name: String):String;
function CheckVmName(const Name: String): Boolean;
function CheckVmRunning(const VmName: String): Integer;
function GetPidValue(const Pattern: String): Integer;
function GetVmNameList(const VmPath: String): String;
function LoadKernelModule(const Module: String): Boolean;
procedure LogMessage(const Message : String);

implementation

uses
  Process, RegExpr, unit_global, unit_configuration;

function setcred(flags: cuint; cred: Pointer; size: size_t): cint; cdecl; external 'c';

function ActivateSetcred(): Boolean;
var
  cred: TSetCred;
begin
  Result:=True;

  FillChar(cred, SizeOf(cred), 0);

  cred.sc_uid   := 0;
  cred.sc_ruid  := 0;
  cred.sc_svuid := 0;

  cred.sc_gid   := 0;
  cred.sc_rgid  := 0;
  cred.sc_svgid := 0;

  if setcred(SETCREDF_UID or SETCREDF_RUID or SETCREDF_SVUID or SETCREDF_GID or
  SETCREDF_RGID or SETCREDF_SVGID, @cred, SizeOf(cred)) < 0 then
  begin
    Result:=False;
  end;
end;

function DeactivateSetcred(): Boolean;
var
  cred: TSetCred;
begin
  Result:=True;

  FillChar(cred, SizeOf(cred), 0);

  cred.sc_uid   := BHYVEMGRD_USER;
  cred.sc_ruid  := BHYVEMGRD_USER;
  cred.sc_svuid := BHYVEMGRD_USER;

  cred.sc_gid   := BHYVEMGRD_GROUP;
  cred.sc_rgid  := BHYVEMGRD_GROUP;
  cred.sc_svgid := BHYVEMGRD_GROUP;

  if setcred(SETCREDF_UID or SETCREDF_RUID or SETCREDF_SVUID or SETCREDF_GID or
  SETCREDF_RGID or SETCREDF_SVGID, @cred, SizeOf(cred)) < 0 then
  begin
    Result:=False;
  end;
end;

function CheckKernelModule(Module: String): Boolean;
var
  output : String;
  status : Boolean;
begin
  Result:=False;

  if FileExists(KLDSTAT_CMD) then
  begin
    status:=RunCommand(KLDSTAT_CMD, ['-q', '-m', module], output, [poStderrToOutPut, poUsePipes]);

    if status then
      Result:=status
    else
      LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : CheckKernelModule : '+ Module+' : '+output);
  end;
end;

function CheckSysctl(const Name: String): String;
var
  output : String;
  status : Boolean;
begin
  Result:=EmptyStr;

  if FileExists(SYSCTL_CMD) then
  begin
    status:=RunCommand(SYSCTL_CMD, ['-n', Name], output, [poStderrToOutPut]);

    if status then
      Result:=output
    else
      LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : CheckSysCtl : '+ Name+' : '+output);
  end;
end;

function CheckVmRunning(const VmName: String): Integer;
var
  PidNumber : Integer;
begin
  Result:=-1;

  PidNumber:= GetPidValue(Format('^bhyve: %s$', [VmName]));

  if PidNumber > 0 then
    Result:=PidNumber
  else
  begin
    PidNumber:=GetPidValue(Format('^%s -k %s/%s/bhyve_config.conf', [BHYVECTL_CMD, VmPath, VmName]));

    if PidNumber  > 0 then
      Result:=PidNumber;
  end;
end;

function CheckVmName(const Name: String): Boolean;
var
  RegText: TRegExpr;
begin
  Result:=False;

  RegText := TRegExpr.Create('^[a-z0-9]{1,64}$');

  if RegText.Exec(Name) then
  begin
    Result:=True;
  end;

  RegText.Free
end;

function CustomFindAllDirectories(const VmPath: String): String;
var
  SearchRecord: TSearchRec;
  SearchRecordList : TStringList;
begin
  Result := EmptyStr;

  SearchRecordList := TStringList.Create;

  try
    if FindFirst(IncludeTrailingPathDelimiter(VmPath) + '*', faAnyFile, SearchRecord) = 0 then
    try
      repeat
        if ((SearchRecord.Attr and faDirectory) <> 0) and
           (SearchRecord.Name <> '.') and
           (SearchRecord.Name <> '..') then
          SearchRecordList.Add(IncludeTrailingPathDelimiter(VmPath) +
                   SearchRecord.Name);

      until FindNext(SearchRecord) <> 0;

    finally
      FindClose(SearchRecord);
    end;

    Result := SearchRecordList.Text;
  finally
    SearchRecordList.Free;
  end;
end;

function GetPidValue(const Pattern: String): Integer;
var
  root_cmd : String;
  output : String;
  parameters : TStringArray;
  status : Boolean;
begin
  Result:=-1;
  root_cmd:=MDO_CMD;

  parameters:=[PGREP_CMD, '-fo', Pattern];

  if FileExists(root_cmd) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut, poUsePipes]);

    if status then
      Result:=Trim(output).ToInt64
    else
    begin
      if not (output.IsEmpty) then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : GetPidValue : '+output);
    end;
  end;
end;

function GetVmNameList(const VmPath: String): String;
var
  i : Integer;
  Directories : TStringList;
begin
  Directories:= TStringList.Create;

  try
    Directories.Text:=CustomFindAllDirectories(VmPath);
    Directories.Sorted:=True;

    for i:=Directories.Count-1 downto 0 do
    begin
      if not FileExists(Directories[i]+'/bhyve_config.conf') and not FileExists(Directories[i]+'/'+ExtractFileName(Directories[i])+'.conf') then
          Directories.Delete(i);
    end;

    Result:=Directories.Text;
  finally
    Directories.Free;
  end;
end;

function LoadKernelModule(const Module: String): Boolean;
var
  root_cmd : String;
  output : String;
  parameters : TStringArray;
  status : Boolean;
begin
  Result:=False;

  root_cmd:=MDO_CMD;

  parameters:=[KLDLOAD_CMD, Module];

  if (FileExists(KLDLOAD_CMD)) and (FileExists(root_cmd)) and not (CheckKernelModule(Module)) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if status then
      Result:=status
    else
      LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : LoadKernelModule : '+Module+' : '+output);
  end;
end;

procedure LogMessage(const Message: String);
begin
  WriteLn(Message);
  Flush(Output);
end;

end.

