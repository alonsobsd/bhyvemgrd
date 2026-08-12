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

  if not (RootMode = 'mdo') then
  begin
    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : RootMode value is not valid.');
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
