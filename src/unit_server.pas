{ BSD 3-Clause License              f

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

unit unit_server;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, BaseUnix, Sockets;

  function ReceiveMessage : String;
  procedure StartServer();
  procedure ServerToClientMessage(const JSON: String);

implementation

uses
  unit_configuration, unit_distpacher, unit_vmmanager, unit_global, unit_util;

{$I version.inc}

var
  FSocket: LongInt;
  InputBuffer  : String;
  OutputBuffer: String;

procedure SendMessage(const S: String);
begin
  if DebugMode = 'yes' then
    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : '+S);

  OutputBuffer := OutputBuffer + S + LineEnding;
end;

procedure FlushOutput;
var
  Sent: LongInt;
begin
  if OutputBuffer = EmptyStr then
    Exit;

  Sent := fpSend(FSocket, @OutputBuffer[1], Length(OutputBuffer), MSG_DONTWAIT or MSG_NOSIGNAL);

  if Sent > 0 then
    Delete(OutputBuffer, 1, Sent);
end;

function GetNextMessage(out Msg:String):Boolean;
var
  P : Integer;
begin
  Result := False;

  P := Pos(LineEnding, InputBuffer);

  if P = 0 then
    Exit;

  Msg := Copy(InputBuffer, 1, P-1);

  Delete(InputBuffer, 1, P + Length(LineEnding)-1);

  Result := True;
end;

procedure StartServer();
var
  ServerSock, ClientSock : LongInt;
  Addr: sockaddr_un;
  task_action:String;
  task_response : String;
  ReadSet : TFDSet;
  WriteSet : TFDSet;
  Timeout : TTimeVal;
  Ret     : Integer;
begin
  ClientSock := -1;
  FSocket := -1;

  try
    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Bhyvemgrd version : v'+ APP_VERSION);
    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Bhyvemgrd website : '+ APP_WEBSITE);

    if FileExists(SOCKET_FILE) then
      DeleteFile(SOCKET_FILE);

    ServerSock:=fpSocket(AF_UNIX, SOCK_STREAM, 0);

    FillChar(Addr, sizeof(Addr), 0);

    Addr.sun_family:=AF_UNIX;
    StrPLCopy(Addr.sun_path, SOCKET_FILE, SizeOf(Addr.sun_path)-1);

    if fpBind(ServerSock, @Addr, SizeOf(Addr.sun_family) + StrLen(@Addr.sun_path) + 1) <> 0 then
    begin
      LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Server stopped : Cannot create socket');
      Halt;
    end;

    FpChown(SOCKET_FILE, FpGetuid, FpGetgid);
    FpChmod(SOCKET_FILE, &770);

    fpListen(ServerSock, 20);

    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Server started');

    while IsRunning do
    begin
      CheckSynchronize(10);

      if ReloadRequested then
       begin
         ReloadRequested := False;

         if not ReloadConfig(CONFIG_FILE, COMMON_CONFIG_FILE) then
           LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Server warning : Reload vm_path rejected. A complete restart is needed for it.')
         else
           LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Server information : Configuration files were reloaded.');
       end;

       if StopRequested then
       begin
         if InterlockedCompareExchange(ActiveThreads,0,0) = 0  then
         begin
           IsRunning := False;
           Break;
         end
         else
         begin
           LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Server warning : Stop rejected because there are active virtual machine threads : '+ ActiveThreads.ToString);

           StopRequested := False;
         end;
       end;

      if ClientSock < 0 then
      begin
        ClientSock := fpAccept(ServerSock, nil, nil);

        if ClientSock >= 0 then
        begin
          FSocket := ClientSock;

          LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Client is connected');
          LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Send initial virtual machine states list to client');

          SendMessage(VmList);
        end;

        Continue;
      end;

      fpFD_ZERO(ReadSet);
      fpFD_ZERO(WriteSet);

      fpFD_SET(ClientSock, ReadSet);

      if OutputBuffer <> EmptyStr then
        fpFD_SET(ClientSock, WriteSet);

      Timeout.tv_sec := 0;
      Timeout.tv_usec := 200000;

      Ret := fpSelect(ClientSock + 1, @ReadSet, @WriteSet, nil, @Timeout);

      if Ret < 0 then
      begin
        if fpgeterrno = ESysEINTR then
            Continue;

        LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Socket error : '+ fpgeterrno.ToString);

        fpClose(ClientSock);
        ClientSock := -1;
        FSocket := -1;

        Continue;
      end;

      if Ret = 0 then
        Continue;

      if fpFD_ISSET(ClientSock, ReadSet) <> 0 then
      begin
        task_action := ReceiveMessage;

        if task_action = EmptyStr then
        begin
          LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Client is disconnected');

          fpClose(ClientSock);
          ClientSock := -1;
          FSocket := -1;

          Continue;
        end;

        InputBuffer := InputBuffer + task_action;

        while GetNextMessage(task_action) do
        begin
          task_response := ProcessRequest(task_action);
          SendMessage(task_response);
        end;
      end;

      if fpFD_ISSET(ClientSock, WriteSet) <> 0 then
      begin
        FlushOutput;
      end;
    end;
  finally
    LogMessage('['+FormatDateTime('DD-MM-YYYY HH:NN:SS', Now)+'] : Stopping server');

    if ClientSock >= 0 then
      fpClose(ClientSock);

    if ServerSock >= 0 then
      fpClose(ServerSock);

    FSocket := -1;

    if FileExists(SOCKET_FILE) then
      DeleteFile(SOCKET_FILE);

    InputBuffer := '';
    OutputBuffer := '';
  end;
end;

function ReceiveMessage:String;
var
  Buffer: array[0..1023] of Char;
  Len: LongInt;
  Data: String;
begin
  Result := EmptyStr;

  Len := fpRecv(FSocket, @Buffer, SizeOf(Buffer), 0);

  if Len <= 0 then
    Exit;

  SetString(Data, Buffer, Len);

  Result := Data;
end;

procedure ServerToClientMessage(const JSON: String);
begin
  SendMessage(JSON);
end;

end.

