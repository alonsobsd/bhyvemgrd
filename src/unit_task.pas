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

unit unit_task;

{$mode ObjFPC}
{$modeswitch arrayoperators+}
{$H+}

interface

uses
  Classes, fpjson;

function Chmod(Id : String; Params:TJSONObject):TJSONObject;
function Chown(Id : String; Params:TJSONObject):TJSONObject;
function Mkdir(Id : String; Params:TJSONObject):TJSONObject;
function Rmdir(Id : String; Params:TJSONObject):TJSONObject;
function AttachToBridge(Id : String; Params:TJSONObject):TJSONObject;
function CreateNetworkDevice(Id : String; Params:TJSONObject):TJSONObject;
function DestroyNetworkDevice(Id : String; Params:TJSONObject):TJSONObject;
function PfLoadRules(Id : String; Params:TJSONObject):TJSONObject;
function PfUnloadRules(Id : String; Params:TJSONObject):TJSONObject;
function GetPidValue(Id : String; Params:TJSONObject):TJSONObject;
function KillPid(Id : String; Params:TJSONObject):TJSONObject;
function RestartService(Id : String; Params:TJSONObject):TJSONObject;
function DestroyVirtualMachine(Id : String; Params:TJSONObject):TJSONObject;
function ZfsCreateDataset(Id : String; Params:TJSONObject):TJSONObject;
function ZfsSetPropertyValue(Id : String; Params:TJSONObject):TJSONObject;
function ZfsDestroy(Id : String; Params:TJSONObject):TJSONObject;
function ZfsCreateZvol(Id : String; Params:TJSONObject):TJSONObject;

implementation

uses
  SysUtils, process, unit_configuration, unit_util, unit_global;

function AttachToBridge(Id : String; Params: TJSONObject): TJSONObject;
var
  BridgeName, DeviceName : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  BridgeName := Params.Get('bridge','');
  DeviceName := Params.Get('device','');

  if SetcredFlag then
  begin
    root_cmd:=IFCONFIG_CMD;
    parameters:=[BridgeName, 'addm', DeviceName];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[IFCONFIG_CMD, BridgeName, 'addm', DeviceName];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : AttachDeviceToBridge : '+ DeviceName+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id', Id);
  Result.Add('type', 'task');
  Result.Add('success', status);
  Result.Add('action', 'network.attach_bridge');
  Result.Add('bridge', BridgeName);
  Result.Add('device', DeviceName);
end;

function Chmod(Id : String; Params: TJSONObject): TJSONObject;
var
  Path, Mode : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  Path := Params.Get('path','');
  Mode := Params.Get('mode','');

  if SetcredFlag then
  begin
    root_cmd:=CHMOD_CMD;
    parameters:=[Mode, Path];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[CHMOD_CMD, Mode, Path];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
      begin
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Chmod : '+ Path+' : '+output);
      end;
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type','task');
  Result.Add('success',status);
  Result.Add('action', 'fs.chmod');
  Result.Add('path',Path);
  Result.Add('mode',Mode);
end;

function Chown(Id : String; Params: TJSONObject): TJSONObject;
var
  Path, Username, Groupname : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  root_cmd:=MDO_CMD;
  SetcredFlag:= RootMode = 'setcred';

  Path := Params.Get('path','');
  Username := Params.Get('username','root');
  Groupname := Params.Get('groupname','wheel');

  if SetcredFlag then
  begin
    root_cmd:=CHOWN_CMD;
    parameters:=[UserName+':'+Groupname, Path];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[CHOWN_CMD, UserName+':'+Groupname, Path];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
      begin
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ChownDir : '+ Path+' : '+output);
      end;
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success',status);
  Result.Add('action', 'fs.chown');
  Result.Add('path',Path);
  Result.Add('username',Username);
end;

function Mkdir(Id : String; Params: TJSONObject): TJSONObject;
var
  DirMode, UserName, GroupName, DirectoryPath : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  DirMode := Params.Get('mode','');
  UserName := Params.Get('username','');
  GroupName := Params.Get('groupname','');
  DirectoryPath := Params.Get('directory','');

  if SetcredFlag then
  begin
    root_cmd:=INSTALL_CMD;
    parameters:=['-d', '-m', DirMode, '-o', UserName, '-g', GroupName, DirectoryPath];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[INSTALL_CMD, '-d', '-m', DirMode, '-o', UserName, '-g', GroupName, DirectoryPath];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) and not DirectoryExists(DirectoryPath) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : CreateDirectory : '+ DirectoryPath+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id', Id);
  Result.Add('type', 'task');
  Result.Add('success', status);
  Result.Add('action', 'fs.mkdir');
  Result.Add('path', DirectoryPath);
end;

function Rmdir(Id : String; Params: TJSONObject): TJSONObject;
var
  VmName, DireType, DirectoryName : String;
  Recursive : Boolean;
  root_cmd : String;
  output : String;
  parameters : TStringArray;
  status : Boolean;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  VmName := Params.Get('vmname','');
  DireType := Params.Get('diretype','');
  Recursive:= Params.Get('recursive', false);

  case DireType of
    'vm': DirectoryName:= VmPath+'/'+VmName;
    'vtcon': DirectoryName:=  VmPath+'/'+VmName+'/vtcon';
  end;

  if SetcredFlag then
  begin
    root_cmd:=RM_CMD;
    parameters:=[];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[RM_CMD];
  end;

  if Recursive then
    parameters:=parameters + ['-R'];

  parameters:=parameters + [DirectoryName];

  try
    if SetcredFlag then
      ActivateSetcred();

    if (FileExists(root_cmd) and DirectoryExists(DirectoryName) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr'))) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : RemoveDirectory : '+DirectoryName+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success',status);
  Result.Add('action', 'fs.rmdir');
  Result.Add('path', DirectoryName);
end;

function CreateNetworkDevice(Id : String; Params: TJSONObject): TJSONObject;
var
  DeviceName, VmName : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  DeviceName := Params.Get('device','');
  VmName := Params.Get('vmname','');

  if SetcredFlag then
  begin
    root_cmd:=IFCONFIG_CMD;
    parameters:=[DeviceName, 'create', 'descr', '"'+VmName+' VM"'];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[IFCONFIG_CMD, DeviceName, 'create', 'descr', '"'+VmName+' VM"'];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : '+VmName+' VM : CreateNetworkDevice : '+ DeviceName+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id', Id);
  Result.Add('type', 'task');
  Result.Add('success', status);
  Result.Add('action', 'network.create_device');
  Result.Add('device', DeviceName);
end;

function DestroyNetworkDevice(Id : String; Params: TJSONObject): TJSONObject;
var
  IfName : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  IfName := Params.Get('ifname','');

  if SetcredFlag then
  begin
    root_cmd:=IFCONFIG_CMD;
    parameters:=[IfName, 'destroy'];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[IFCONFIG_CMD, IfName, 'destroy'];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : DestroyNetworkInterface : '+ IfName+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success', status);
  Result.Add('action', 'network.destroy_device');
  Result.Add('ifname', IfName);
end;

function PfLoadRules(Id : String; Params: TJSONObject): TJSONObject;
var
  VmName, RuleType : String;
  root_cmd : String;
  output : String;
  anchor : String;
  rules_path : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  anchor:=EmptyStr;
  SetcredFlag:= RootMode = 'setcred';

  VmName := Params.Get('vmname','');
  RuleType := Params.Get('ruletype','');

  case RuleType of
    'nat':anchor:=NatAnchor+'/'+VmName;
    'rdr':anchor:=RdrAnchor+'/'+VmName;
    'pass-in':anchor:=PassInAnchor+'/'+VmName;
    'pass-out':anchor:=PassOutAnchor+'/'+VmName;
  end;

  rules_path:=VmPath+'/'+VmName+'/pf/'+RuleType+'.rules';

  if SetcredFlag then
  begin
    root_cmd:=PFCTL_CMD;
    parameters:=['-a', anchor, '-f', rules_path];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[PFCTL_CMD, '-a', anchor, '-f', rules_path];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) and FileExists(rules_path) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr')) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : PfLoadRules : '+ RuleType+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('action', 'pf.load_rules');
  Result.Add('success', status);
  Result.Add('ruletype', RuleType);
end;

function PfUnloadRules(Id : String; Params: TJSONObject): TJSONObject;
var
  VmName, RulesType : String;
  root_cmd : String;
  output : String;
  anchor : String;
  flush_type : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  anchor:=EmptyStr;
  flush_type:=EmptyStr;
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  VmName := Params.Get('vmname','');
  RulesType := Params.Get('ruletype','');

  case RulesType of
    'nat':
      begin
        anchor:=NatAnchor+'/'+VmName;
        flush_type:='nat';
      end;
    'rdr':
      begin
        anchor:=RdrAnchor+'/'+VmName;
        flush_type:='nat';
      end;
    'pass-in':
      begin
        anchor:=PassInAnchor+'/'+VmName;
        flush_type:='rules';
      end;
    'pass-out':
      begin
        anchor:=PassOutAnchor+'/'+VmName;
        flush_type:='rules';
      end;
  end;

  if SetcredFlag then
  begin
    root_cmd:=PFCTL_CMD;
    parameters:=['-a', anchor, '-F', flush_type];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[PFCTL_CMD, '-a', anchor, '-F', flush_type];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr')) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : PfUnLoadRules : '+ RulesType+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success', status);
  Result.Add('action', 'pf.unload_rules');
  Result.Add('ruletype', RulesType);
end;

function GetPidValue(Id : String; Params: TJSONObject): TJSONObject;
var
  Pattern : String;
  root_cmd : String;
  output : String;
  parameters : TStringArray;
  status : Boolean;
  pid : Int64;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';
  pid:=-1;

  Pattern := Params.Get('pattern','');

  if SetcredFlag then
  begin
    root_cmd:=PGREP_CMD;
    parameters:=['-fo', Pattern];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[PGREP_CMD, '-fo', Pattern];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut, poUsePipes]);

      if status then
        pid:=Trim(output).ToInt64
      else
      begin
        if not (output.IsEmpty) then
          LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : GetPidValue : '+output);
      end;
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id', Id);
  Result.Add('type', 'task');
  Result.Add('success', status);
  Result.Add('action', 'process.get_pid');
  Result.Add('pid', pid.ToString);
end;

function KillPid(Id : String; Params: TJSONObject): TJSONObject;
var
  Signal, Pid : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  Signal := Params.Get('signal','');
  Pid := Params.Get('pid', '');

  if SetcredFlag then
  begin
    root_cmd:=KILL_CMD;
    parameters:=[Signal, Pid];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[KILL_CMD, Signal, Pid];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut, poUsePipes]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : KillPid : '+Pid+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success',status);
  Result.Add('action', 'process.kill_pid');
  Result.Add('pid',Pid);
end;

function RestartService(Id : String; Params: TJSONObject): TJSONObject;
var
  Service : String;
  root_cmd : String;
  output : String;
  parameters : TStringArray;
  status : Boolean;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  Service := Params.Get('service','');

  if SetcredFlag then
  begin
    root_cmd:=SERVICE_CMD;
    parameters:=[Service, 'reload'];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[SERVICE_CMD, Service, 'reload'];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : RestartService : '+Service+' : OK')
      else
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : RestartService : '+Service+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success',status);
  Result.Add('action', 'service.restart');
  Result.Add('service',Service);
end;

function DestroyVirtualMachine(Id : String; Params: TJSONObject): TJSONObject;
var
  VmName : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  VmName := Params.Get('vmname','');

  if SetcredFlag then
  begin
    root_cmd:=BHYVECTL_CMD;
    parameters:=['--vm='+VmName, '--destroy'];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[BHYVECTL_CMD, '--vm='+VmName, '--destroy'];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) and CheckVmName(VmName) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : DestroyVirtualMachine : '+VmName+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success', status);
  Result.Add('action', 'vm.destroy');
  Result.Add('vmname', VmName);
end;

function ZfsCreateDataset(Id : String; Params: TJSONObject): TJSONObject;
var
  VmName, ZfsType, ZfsPath, ZfsOptions : String;
  WithMountPoint : Boolean;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  options : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';
  ZfsPath:=EmptyStr;

  VmName := Params.Get('vmname','');
  ZfsType := Params.Get('zfstype','');
  ZfsOptions := Params.Get('options','');
  WithMountPoint := Params.Get('mountpoint', false);

  options := ZfsOptions.Split(' ');

  case ZfsType of
    'root': ZfsPath:= VmPath.Remove(0,1);
    'vm': ZfsPath:=  VmPath.Remove(0,1)+'/'+VmName;
  end;

  if WithMountpoint then
    options:=options+['-o','mountpoint=/'+ZfsPath];

  if SetcredFlag then
  begin
    root_cmd:=ZFS_CMD;
    parameters:=['create']+ options;
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[ZFS_CMD, 'create']+ options;
  end;

  parameters:=parameters+[ZfsPath];

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) and not DirectoryExists('/'+ZfsPath) and (VmPath.Contains('/bhyvemgr')) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ZfsCreateDataset : '+  ZfsPath+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success',status);
  Result.Add('action', 'zfs.create_dataset');
  Result.Add('path', ZfsPath);
end;

function ZfsSetPropertyValue(Id : String; Params: TJSONObject): TJSONObject;
var
  ZfsProperty, ZfsValue, ZfsPath : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  output:=EmptyStr;
  SetcredFlag:= RootMode = 'setcred';

  ZfsProperty := Params.Get('property','');
  ZfsValue := Params.Get('value','');
  ZfsPath := Params.Get('path','');

  if SetcredFlag then
  begin
    root_cmd:=ZFS_CMD;
    parameters:=['set', ZfsProperty+'='+ZfsValue, ZfsPath];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[ZFS_CMD, 'set', ZfsProperty+'='+ZfsValue, ZfsPath];
  end;

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ZfsSetPropertyValue : '+ ZfsProperty+'='+ZfsValue+' : '+ZfsPath+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success',status);
  Result.Add('action', 'zfs.set_property');
  Result.Add('output', Trim(output));
end;

function ZfsDestroy(Id : String; Params: TJSONObject): TJSONObject;
var
  ZfsPath, VmName, ZfsType, ZfsDevice : String;
  Recursive, Force : Boolean;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  Recursive := Params.Get('recursive', false);
  Force := Params.Get('force', false);
  VmName := Params.Get('vmname','');
  ZfsType := Params.Get('zfstype','');
  ZfsDevice := Params.Get('zfsdevice','');

  case ZfsType of
    'vm': ZfsPath:= VmPath.Remove(0,1)+'/'+VmName;
    'zvol': ZfsPath:=  VmPath.Remove(0,1)+'/'+VmName+'/'+ZfsDevice;
  end;

  if SetcredFlag then
  begin
    root_cmd:=ZFS_CMD;
    parameters:=['destroy'];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[ZFS_CMD, 'destroy'];
  end;

  if Recursive then
    parameters:=parameters + ['-r'];

  if Force then
    parameters:=parameters + ['-f'];

  parameters:=parameters + [ZfsPath];

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr')) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ZfsDestroy : '+ ZfsPath+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success',status);
  Result.Add('action', 'zfs.destroy');
end;

function ZfsCreateZvol(Id : String; Params: TJSONObject): TJSONObject;
var
  VmName, DiskName, ZfsVolSize, ZfsPath : String;
  ZvolSparse : Boolean;
  root_cmd : String;
  output : String;
  sparse : String;
  status : Boolean;
  parameters : TStringArray;
  SetcredFlag : Boolean;
begin
  status:=False;
  SetcredFlag:= RootMode = 'setcred';

  VmName:= Params.Get('vmname', '');
  DiskName:= Params.Get('diskname', '');
  ZvolSparse := Params.Get('sparse', false);
  ZfsVolSize := Params.Get('volsize','');

  ZfsPath := VmPath.Remove(0,1)+'/'+VmName+'/'+DiskName;

  if ZvolSparse then
    sparse:='-sV'
  else
    sparse:='-V';

  if SetcredFlag then
  begin
    root_cmd:=ZFS_CMD;
    parameters:=['create', sparse, ZfsVolSize, '-o','volmode=dev'];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    parameters:=[ZFS_CMD,'create', sparse, ZfsVolSize, '-o','volmode=dev'];
  end;

  parameters:=parameters+[ZfsPath];

  try
    if SetcredFlag then
      ActivateSetcred();

    if FileExists(root_cmd) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr')) then
    begin
      status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

      if not status then
        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ZfsCreateZvol : '+ ZfsPath+' : '+output);
    end;
  finally
    if SetcredFlag then
      DeactivateSetcred();
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success',status);
  Result.Add('action', 'zfs.create_zvol');
end;
end.

