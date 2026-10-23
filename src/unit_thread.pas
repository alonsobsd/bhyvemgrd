{ SPDX-License-Identifier: BSD-3-Clause

Copyright (c) 2026, J. Alonso Cárdenas <acardenas@bsd-peru.org>

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
  unit_configuration, unit_util, process;

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
  SetcredFlag : Boolean;
begin
  SetcredFlag:= RootMode = 'setcred';

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
      if SetcredFlag then
        ActivateSetcred();

      AppProcess.Execute;

      if SetcredFlag then
        DeactivateSetcred();

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
            LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : vmException : '+ErrorMessage);
          end;

        Synchronize(@Showstatus);
      end
    except
      on E: Exception do
      begin
        AppState:=vmException;
        ExitStatus:=6;
        ErrorMessage:=E.Message;

        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : vmException : '+ErrorMessage);

        Synchronize(@Showstatus);
      end;
    end;
  finally
    AppProcessOutput.Free;
    AppProcess.Free;
  end;
end;

constructor VmThread.Create(const VmName : String);
var
  SetcredFlag : Boolean;
  root_cmd : String;
begin
  SetcredFlag:= RootMode = 'setcred';

  if SetcredFlag then
  begin
    root_cmd:=BHYVE_CMD;
    AppParams:=['-k', Format('%s/%s/bhyve_config.conf', [VmPath, VmName])];
  end
  else
  begin
    root_cmd:=MDO_CMD;
    AppParams:=[BHYVE_CMD, '-k', Format('%s/%s/bhyve_config.conf', [VmPath, VmName])];
  end;

  AppName:=root_cmd;
  AppVmName:=VmName;
  AppVmPath:=VmPath;

  inherited Create(True);
  FreeOnTerminate := true;
end;

end.


