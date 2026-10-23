{ SPDX-License-Identifier: BSD-3-Clause

Copyright (c) 2026, J. Alonso Cárdenas <acardenas@bsd-peru.org>

}

program bhyvemgrd;

{$mode ObjFPC}{$H+}

uses
{$IFDEF UNIX}
cthreads,
{$ENDIF}
SysUtils,
Unix,
Baseunix,
unit_configuration, unit_server, unit_util,
unit_global, unit_vmmanager;

procedure SignalHandler(sig: LongInt); cdecl;
begin
  case sig of
    SIGINT,
    SIGTERM:
      StopRequested := True;

    SIGHUP:
      ReloadRequested := True;
  end;
end;

procedure StartSignalHandler;
var
  NewSignal, OldSignal: SigActionRec;
begin
  NewSignal.sa_handler := sigActionHandler(@SignalHandler);
  FillChar(NewSignal.Sa_Mask, sizeof(NewSignal.Sa_Mask), #0);
  NewSignal.Sa_Flags := 0;

  fpSigAction(SIGINT,  @NewSignal, @OldSignal);
  fpSigAction(SIGTERM, @NewSignal, @OldSignal);
  fpSigAction(SIGHUP,  @NewSignal, @OldSignal);
end;

begin
  IsRunning:=True;
  StopRequested:=False;
  ReloadRequested:=False;

  StartSignalHandler;

  {$IFDEF DEBUG}
    if FileExists('heap.trc') then
      DeleteFile('heap.trc');
    SetHeapTraceOutput('heap.trc');
  {$ENDIF DEBUG}

  SetOsreldate(Trim(CheckSysctl('kern.osreldate')));

  if FileExists(CONFIG_FILE) and FileExists(COMMON_CONFIG_FILE) then
    LoadConfig(CONFIG_FILE, COMMON_CONFIG_FILE)
  else
  begin
    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : The '+CONFIG_FILE+' or '+COMMON_CONFIG_FILE+' configuration files do not exist.');
    Halt;
  end;

  if not (RootMode = 'mdo') and not ((GetOsreldate.ToInt64 >= 1501501) and (RootMode = 'setcred')) then
  begin
    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : RootMode '+RootMode+' value is not valid.');
    Halt;
  end;

  if (ExpandFileName(VmPath) = DirectorySeparator) or not (VmPath.Contains('/bhyvemgr')) then
  begin
    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : VmPath value is not valid.');
    Halt;
  end;

  LoadKernelModule('vmm');
  LoadKernelModule('nmdm');
  LoadKernelModule('mac_do');

  if not CheckKernelModule('vmm') or not CheckKernelModule('nmdm') or not CheckKernelModule('mac_do') then
  begin
    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Bhyvemgrd cannot start. Check that the vmm, nmdm, and mac_do kernel modules are loaded.');
    Exit;
  end;

  SetServerMessageCallback(@ServerToClientMessage);

  VmInitialize;

  try
    StartServer();
  finally
    VmFinalize();
  end;
end.
