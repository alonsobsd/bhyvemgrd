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

unit unit_vmmanager;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fgl, fpjson, unit_global;

type
  TVmMap = specialize TFPGMap<String, TVmInfo>;
  TServerMessageProc = procedure(const JSON: String);

procedure VmLoadList;
procedure VmInitialize;
procedure VmFinalize;
procedure SetServerMessageCallback(Callback: TServerMessageProc);

function VmAdd(const VmName: String): Boolean;
function VmCreate(Params:TJSONObject):TJSONObject;
function VmDelete(Params:TJSONObject):TJSONObject;
function VmRemove(const VmName: String): Boolean; // Not used yet
function VmExists(const VmName: String): Boolean;
function VmGetInfo(const VmName: String; out VmInfo: TVmInfo): Boolean;
procedure VmSetState(const VmName: String; VmState: TVmState; VmPid : Integer; ExitCode : Integer);
function VmGetState(const VmName: String): TVmState;
function VmStart(Params:TJSONObject):TJSONObject;
function VmStop(Params:TJSONObject):TJSONObject; // Not used yet
function VmList: String;

implementation

uses
  unit_configuration, unit_thread, unit_util;

var
  FVirtualMachines : TVmMap;
  FServerMessage: TServerMessageProc;

function VmStateToString(State: TVmState): String;
begin
  Result:=EmptyStr;

  case State of
      vmRebooted: Result := 'vmRebooted';
      vmPowerOff : Result := 'vmPowerOff';
      vmHalted : Result := 'vmHalted';
      vmTripleFault : Result := 'vmTripleFault';
      vmExited : Result := 'vmExited';
      vmSuspended : Result := 'vmSuspended';
      vmRunning : Result := 'vmRunning';
      vmException : Result := 'vmException';
  end;
end;

procedure VmLoadList;
var
  i : Integer;
  VirtualMachineList : TStringList;
begin
  VirtualMachineList:= TStringList.Create;
  VirtualMachineList.Text := GetVmNameList(VmPath);
  try
    for i:=0 to VirtualMachineList.Count-1 do
    begin
      VmAdd(ExtractFileName(VirtualMachineList[i]));
    end;
  finally
    VirtualMachineList.Free;
    VirtualMachineList := nil;
  end;
end;

procedure VmInitialize;
begin
  FVirtualMachines := TVmMap.Create;
  FVirtualMachines.Sorted := True;

  VmLoadList;
end;

procedure VmFinalize;
begin
  FVirtualMachines.Free;
end;

procedure SetServerMessageCallback(Callback: TServerMessageProc);
begin
  FServerMessage := Callback;
end;

function VmAdd(const VmName: String): Boolean;
var
  VirtualMachine : TVmInfo;
  VmPid : Integer;
begin
  Result := False;

  if VmExists(VmName) then
    Exit;

  VirtualMachine.Name := VmName;
  VmPid:=CheckVmRunning(VmName);

  if VmPid > 0 then
  begin
    VirtualMachine.State := vmRunning;
    VirtualMachine.PID := VmPid;
  end
  else
  begin
    VirtualMachine.State := vmPowerOff;
    VirtualMachine.PID := 0;
  end;

  VirtualMachine.ExitCode := -1;
  FVirtualMachines.Add(VmName, VirtualMachine);

  Result := True;
end;

function VmCreate(Params: TJSONObject): TJSONObject;
var
  VirtualMachine : TVmInfo;
  VmName : String;
  SuccessCode : Boolean;
begin
  VmName:=Params.Get('vmname', '');
  SuccessCode:=False;

  Result := TJSONObject.Create;

  if not VmExists(VmName) then
  begin
    VirtualMachine.Name := VmName;
    VirtualMachine.State := vmPowerOff;
    VirtualMachine.PID := 0;
    VirtualMachine.ExitCode := -1;

    FVirtualMachines.Add(VmName, VirtualMachine);

    SuccessCode:=True;
  end;

  Result.Add('success', SuccessCode);
  Result.Add('type', 'task');
  Result.Add('vmname', VmName);
end;

function VmDelete(Params: TJSONObject): TJSONObject;
var
  VmName : String;
  SuccessCode : Boolean;
begin
  VmName:=Params.Get('vmname', '');
  SuccessCode:=False;

  Result := TJSONObject.Create;

  if VmExists(VmName) then
  begin
    FVirtualMachines.Remove(VmName);
    SuccessCode:=True;
  end;

  Result.Add('success', SuccessCode);
  Result.Add('type', 'task');
  Result.Add('vmname', VmName);
end;

function VmRemove(const VmName: String): Boolean;
var
  i : Integer;
  VirtualMachine : TVmInfo;
begin
  Result := False;

  i := FVirtualMachines.IndexOf(VmName);

  if i = -1 then
    Exit;

  VirtualMachine := FVirtualMachines.Data[i];

  if VirtualMachine.State = vmRunning then
    Exit;

  FVirtualMachines.Delete(i);

  Result := True;
end;

function VmExists(const VmName: String): Boolean;
begin
  Result := FVirtualMachines.IndexOf(VmName) <> -1;
end;

function VmGetInfo(const VmName: String; out VmInfo: TVmInfo): Boolean;
var
  i : Integer;
begin
  i := FVirtualMachines.IndexOf(VmName);

  Result := i <> -1;

  if Result then
    VmInfo := FVirtualMachines.Data[i];
end;

procedure VmSetState(const VmName: String; VmState: TVmState; VmPid : Integer; ExitCode : Integer);
var
  i : Integer;
  VirtualMachine  : TVmInfo;
  VirtualMachineJson : TJSONObject;
begin
  i := FVirtualMachines.IndexOf(VmName);

  if i = -1 then
    Exit;

  try
    if not (VmState = vmRebooted) then
      InterlockedDecrement(ActiveThreads);

    VirtualMachineJson:=TJSONObject.Create;

    VirtualMachine := FVirtualMachines.Data[i];
    VirtualMachine.PID := VmPid;
    VirtualMachine.State := VmState;
    VirtualMachine.ExitCode := ExitCode;

    FVirtualMachines.Data[i] := VirtualMachine;

    VirtualMachineJson.Add('type', 'event');
    VirtualMachineJson.Add('event', 'vm_state_changed');
    VirtualMachineJson.Add('vmname', FVirtualMachines.Data[i].Name);
    VirtualMachineJson.Add('state', VmStateToString(FVirtualMachines.Data[i].State));

    if Assigned(FServerMessage) then
      FServerMessage(VirtualMachineJson.AsJSON);
  finally
    VirtualMachineJson.Free;
  end;
end;

function VmGetState(const VmName: String): TVmState;
var
  VirtualMachine : TVmInfo;
begin

  if VmGetInfo(VmName, VirtualMachine) then
    Result := VirtualMachine.State
  else
    Result := vmExited;
end;

function VmStart(Params:TJSONObject):TJSONObject;
var
  i : Integer;
  VmName : String;
  IsRebooting : String;
  EventType : String;
  VirtualMachine : TVmInfo;
  SuccessCode : Boolean;
  MyVmThread: VmThread;
begin
  SuccessCode := False;
  VmName := Params.Get('vmname','');
  IsRebooting := Params.Get('isrebooting', EmptyStr);

  if not (IsRebooting = 'True') then
    EventType:='vm_state_init'
  else
    EventType:='vm_state_keep';

  Result := TJSONObject.Create;

  if not (CheckVmRunning(VmName) > 0) then
  begin
    i := FVirtualMachines.IndexOf(VmName);

    if i <> -1 then
    begin
      if FileExists(MDO_CMD) and FileExists(BHYVE_CMD) then
      begin
        VirtualMachine := FVirtualMachines.Data[i];

        MyVmThread := VmThread.Create(VmName);
        MyVmThread.OnExitStatus := @VmSetState;
        MyVmThread.Start;

        VirtualMachine.State := vmRunning;
        FVirtualMachines.Data[i] := VirtualMachine;

        if EventType = 'vm_state_init' then
          InterlockedIncrement(ActiveThreads);

        SuccessCode := True;
      end;
    end;
  end;

  Result.Add('success', SuccessCode);
  Result.Add('type', 'event');
  Result.Add('event', EventType);
  Result.Add('vmname', VmName);
end;

function VmStop(Params:TJSONObject):TJSONObject;
var
  VirtualMachine : TVmInfo;
  SuccessCode : Boolean;
  VmName : String;
begin
  SuccessCode := False;
  VmName := Params.Get('vmname','');

  Result := TJSONObject.Create;

  if not VmGetInfo(VmName, VirtualMachine) then
    Exit;

  if VirtualMachine.PID=0 then
    Exit;

  //VmSetState(VmName, vmPowerOff);
  // fpKill(VM.PID,SIGTERM)
  //

  Result.Add('success', SuccessCode);
  Result.Add('type', 'event');
  Result.Add('event', 'vm_state_stop');
  Result.Add('vmname', VmName);
end;

function VmList: String;
var
  i : Integer;
  RootJson : TJSONObject;
  VirtualMachine : TJSONObject;
  VirtualMachineList : TJSONObject;
begin
  RootJson := TJSONObject.Create;
  try
    RootJson.Add('type', 'snapshot');

    VirtualMachineList := TJSONObject.Create;
    RootJson.Add('vms', VirtualMachineList);

    for i:=0 to FVirtualMachines.Count-1 do
    begin
      VirtualMachine := TJSONObject.Create;
      VirtualMachine.Add('state', VmStateToString(FVirtualMachines.Data[i].State));
      VirtualMachineList.Add(FVirtualMachines.Data[i].Name, VirtualMachine);
    end;

    Result:=RootJson.AsJSON;
  finally
    RootJson.Free;
  end;
end;

end.

