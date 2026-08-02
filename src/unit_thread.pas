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

unit unit_thread;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, unit_global;

type
  TExitStatusEvent = procedure(const VmName : String; VmState : TVmState; VmPid : Integer; ExitCode : Integer);

  { VmThread }

  VmThread = class(TThread)
  private
    AppName : string;
    AppVmName : string;
    AppVmPath : string;
    AppResult : String;
    AppParams: TStringArray;
    AppPid : Integer;
    AppState : TVmState;
    ErrorMessage : String;
    ExitStatus : Integer;
    FOnExitStatus: TExitStatusEvent;
    procedure ShowStatus;
  protected
    procedure Execute; override;
  public
    constructor Create(const VmName : String);
    property OnExitStatus: TExitStatusEvent read FOnExitStatus write FOnExitStatus;
  end;

implementation

uses
  unit_configuration ,process;

{ VmThread }

procedure VmThread.ShowStatus;
begin
  if Assigned(FOnExitStatus) then
  begin
    FOnExitStatus(AppVmName, AppState, AppPid, ExitStatus);
  end;
end;

procedure VmThread.Execute;
var
  AppProcess: TProcess;
  I: Integer;
  AppProcessOutput: TStringList;
begin
  AppProcess := TProcess.Create(nil);
  AppProcessOutput:= TStringList.Create;

  AppProcess.InheritHandles := False;
  AppProcess.Options := [poUsePipes];
  AppProcess.ShowWindow := swoShow;
  for I := 1 to GetEnvironmentVariableCount do
    AppProcess.Environment.Add(GetEnvironmentString(I));
  AppProcess.Executable:= AppName;

  for I:=0 to Length(AppParams)-1 do
  begin
    AppProcess.Parameters.Add(AppParams[I]);
  end;

  try
    try
      AppProcess.Execute;

      AppPid:=AppProcess.ProcessID;

      AppProcess.WaitOnExit;

      ExitStatus:=AppProcess.ExitStatus;
      AppProcessOutput.LoadFromStream(AppProcess.Stderr);

      if (ExitStatus = -1) then
      begin
        AppResult:='True';
      end
      else
      begin
        case ExitStatus of
          0: AppState:=vmRebooted;
          1: AppState:=vmPowerOff;
          2: AppState:=vmHalted;
          3: AppState:=vmTripleFault;
          4: AppState:=vmExited;
          5: AppState:=vmSuspended;
          else
            AppState:=vmException;
            ExitStatus:=6;
            ErrorMessage:=AppProcessOutput.Text;
            Write('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : vmException : '+ErrorMessage);
          end;

        Synchronize(@Showstatus);
      end
    except
      on E: Exception do
      begin
        AppState:=vmException;
        ExitStatus:=6;
        ErrorMessage:=E.Message;

        Write('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : vmException : '+ErrorMessage);

        Synchronize(@Showstatus);
      end;
    end;
  finally
    AppProcessOutput.Free;
    AppProcess.Free;
  end;
end;

constructor VmThread.Create(const VmName : String);
begin
  AppName:=MDO_CMD;
  AppVmName:=VmName;
  AppVmPath:=VmPath;
  AppParams:=[BHYVE_CMD, '-k', Format('%s/%s/bhyve_config.conf', [VmPath, VmName])];

  inherited Create(True);
  FreeOnTerminate := true;
end;

end.


