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
begin
  status:=False;
  root_cmd:=MDO_CMD;

  BridgeName := Params.Get('bridge','');
  DeviceName := Params.Get('device','');

  parameters:=[IFCONFIG_CMD, BridgeName, 'addm', DeviceName];

  if FileExists(root_cmd) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : AttachDeviceToBridge : '+ DeviceName+' : '+output);
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
begin
  status:=False;
  root_cmd:=MDO_CMD;

  Path := Params.Get('path','');
  Mode := Params.Get('mode','');

  parameters:=[CHMOD_CMD, Mode, Path];

  if FileExists(root_cmd) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
    begin
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Chmod : '+ Path+' : '+output);
    end;
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
  Path, Username : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
begin
  status:=False;
  root_cmd:=MDO_CMD;

  Path := Params.Get('path','');
  Username := Params.Get('username','');

  parameters:=[CHOWN_CMD, UserName+':', Path];

  if FileExists(root_cmd) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
    begin
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ChownDir : '+ Path+' : '+output);
    end;
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
  DirMode, UserName, DirectoryPath : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
begin
  status:=False;
  root_cmd:=MDO_CMD;

  DirMode := Params.Get('mode','');
  Username := Params.Get('username','');
  DirectoryPath := Params.Get('directory','');

  parameters:=[INSTALL_CMD, '-d', '-m', DirMode, '-o', UserName, DirectoryPath];

  if FileExists(INSTALL_CMD) and FileExists(root_cmd) and not DirectoryExists(DirectoryPath) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : CreateDirectory : '+ DirectoryPath+' : '+output);
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
begin
  status:=False;
  root_cmd:=MDO_CMD;

  VmName := Params.Get('vmname','');
  DireType := Params.Get('diretype','');
  Recursive:= Params.Get('recursive', false);

  case DireType of
    'vm': DirectoryName:= VmPath+'/'+VmName;
    'vtcon': DirectoryName:=  VmPath+'/'+VmName+'/vtcon';
  end;

  parameters:=[RM_CMD];

  if Recursive then
    parameters:=parameters + ['-R'];

  parameters:=parameters + [DirectoryName];

  if (FileExists(root_cmd) and DirectoryExists(DirectoryName) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr'))) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : RemoveDirectory : '+DirectoryName+' : '+output);
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
begin
  status:=False;
  root_cmd:=MDO_CMD;

  DeviceName := Params.Get('device','');
  VmName := Params.Get('vmname','');

  parameters:=[IFCONFIG_CMD, DeviceName, 'create', 'descr', '"'+VmName+' VM"'];

  if FileExists(root_cmd) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : '+VmName+' VM : CreateNetworkDevice : '+ DeviceName+' : '+output);
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
begin
  status:=False;
  root_cmd:=MDO_CMD;

  IfName := Params.Get('ifname','');

  parameters:=[IFCONFIG_CMD, IfName, 'destroy'];

  if FileExists(root_cmd) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : DestroyNetworkInterface : '+ IfName+' : '+output);
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
begin
  status:=False;
  anchor:=EmptyStr;

  root_cmd:=MDO_CMD;

  VmName := Params.Get('vmname','');
  RuleType := Params.Get('ruletype','');

  case RuleType of
    'nat':anchor:=NatAnchor+'/'+VmName;
    'rdr':anchor:=RdrAnchor+'/'+VmName;
    'pass-in':anchor:=PassInAnchor+'/'+VmName;
    'pass-out':anchor:=PassOutAnchor+'/'+VmName;
  end;

  rules_path:=VmPath+'/'+VmName+'/pf/'+RuleType+'.rules';

  parameters:=[PFCTL_CMD, '-a', anchor, '-f', rules_path];

  if FileExists(rules_path) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr')) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : PfLoadRules : '+ RuleType+' : '+output);
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
begin
  anchor:=EmptyStr;
  flush_type:=EmptyStr;
  status:=False;

  root_cmd:=MDO_CMD;

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

  parameters:=[PFCTL_CMD, '-a', anchor, '-F', flush_type];

  if FileExists(PFCTL_CMD) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr')) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : PfUnLoadRules : '+ RulesType+' : '+output);
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
begin
  status:=False;
  pid:=-1;
  root_cmd:=MDO_CMD;

  Pattern := Params.Get('pattern','');

  parameters:=[PGREP_CMD, '-fo', Pattern];

  if FileExists(root_cmd) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut, poUsePipes]);

    if status then
      pid:=Trim(output).ToInt64
    else
    begin
      if not (output.IsEmpty) then
        WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : GetPidValue : '+output);
    end;
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
begin
  status:=False;
  root_cmd:=MDO_CMD;

  Signal := Params.Get('signal','');
  Pid := Params.Get('pid', '');

  parameters:=[KILL_CMD, Signal, Pid];

  if FileExists(KILL_CMD) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut, poUsePipes]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : KillPid : '+Pid+' : '+output);
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
begin
  status:=False;
  root_cmd:=MDO_CMD;

  Service := Params.Get('service','');

  parameters:=[SERVICE_CMD, Service, 'restart'];

  if (FileExists(SERVICE_CMD)) and (FileExists(root_cmd)) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : RestartService : '+Service+' : OK')
    else
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : RestartService : '+Service+' : '+output);
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
begin
  status:=False;
  root_cmd:=MDO_CMD;

  VmName := Params.Get('vmname','');

  parameters:=[BHYVECTL_CMD, '--vm='+VmName, '--destroy'];

  if FileExists(BHYVECTL_CMD) and FileExists(root_cmd) and CheckVmName(VmName) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : DestroyVirtualMachine : '+VmName+' : '+output);
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
begin
  status:=False;
  root_cmd:=MDO_CMD;
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

  parameters:=[ZFS_CMD, 'create']+ options;
  parameters:=parameters+[ZfsPath];

  if FileExists(root_cmd) and FileExists(zfs_cmd) and not DirectoryExists('/'+ZfsPath) and (VmPath.Contains('/bhyvemgr')) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ZfsCreateDataset : '+  ZfsPath+' : '+output);
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
begin
  status:=False;
  output:=EmptyStr;

  root_cmd:=MDO_CMD;

  ZfsProperty := Params.Get('property','');
  ZfsValue := Params.Get('value','');
  ZfsPath := Params.Get('path','');

  parameters:=[ZFS_CMD, 'set', ZfsProperty+'='+ZfsValue, ZfsPath];

  if FileExists(ZFS_CMD) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ZfsSetPropertyValue : '+ ZfsProperty+'='+ZfsValue+' : '+ZfsPath+' : '+output);
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
  ZfsPath, VmName, ZfsType, ZfsDevice, Recursive, Force : String;
  root_cmd : String;
  output : String;
  status : Boolean;
  parameters : TStringArray;
begin
  status:=False;
  root_cmd:=MDO_CMD;

  Recursive := Params.Get('recursive','');
  Force := Params.Get('force','');
  VmName := Params.Get('vmname','');
  ZfsType := Params.Get('zfstype','');
  ZfsDevice := Params.Get('zfsdevice','');

  case ZfsType of
    'vm': ZfsPath:= VmPath.Remove(0,1)+'/'+VmName;
    'zvol': ZfsPath:=  VmPath.Remove(0,1)+'/'+VmName+'/'+ZfsDevice;
  end;

  parameters:=[ZFS_CMD, 'destroy'];

  if StrToBool(Recursive) then
    parameters:=parameters + ['-r'];

  if StrToBool(Force) then
    parameters:=parameters + ['-f'];

  parameters:=parameters + [ZfsPath];

  if FileExists(ZFS_CMD) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr')) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ZfsDestroy : '+ ZfsPath+' : '+output);
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
begin
  status:=False;

  root_cmd:=MDO_CMD;

  VmName:= Params.Get('vmname', '');
  DiskName:= Params.Get('diskname', '');
  ZvolSparse := Params.Get('sparse', false);
  ZfsVolSize := Params.Get('volsize','');

  ZfsPath := VmPath.Remove(0,1)+'/'+VmName+'/'+DiskName;

  if ZvolSparse then
    sparse:='-sV'
  else
    sparse:='-V';

  parameters:=[ZFS_CMD,'create', sparse, ZfsVolSize, '-o','volmode=dev'];
  parameters:=parameters+[ZfsPath];

  if FileExists(root_cmd) and FileExists(ZFS_CMD) and CheckVmName(VmName) and (VmPath.Contains('/bhyvemgr')) then
  begin
    status:=RunCommand(root_cmd, parameters, output, [poStderrToOutPut]);

    if not status then
      WriteLn('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : ZfsCreateZvol : '+ ZfsPath+' : '+output);
  end;

  Result := TJSONObject.Create;
  Result.Add('id',Id);
  Result.Add('type', 'task');
  Result.Add('success',status);
  Result.Add('action', 'zfs.create_zvol');
end;
end.

