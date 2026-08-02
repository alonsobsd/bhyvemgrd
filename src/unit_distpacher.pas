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

unit unit_distpacher;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson;

function ProcessRequest(Data:string):string;

implementation

uses
  unit_task, unit_vmmanager, jsonparser;

function ProcessRequest(Data:string):string;
var
  Request : TJSONObject;
  Response: TJSONObject;

  Id : string;
  Method : string;
  Params : TJSONObject;
begin
  Request := GetJSON(Data) as TJSONObject;

  Response := nil;

  try
    Id := Request.Get('id','');
    Method := Request.Get('method','');
    Params := Request.Objects['params'];

    case Method of
      'fs.chmod':
        Response := Chmod(Id, Params);
      'fs.chown':
        Response := Chown(Id, Params);
      'fs.mkdir':
        Response := Mkdir(Id, Params);
      'fs.rmdir':
        Response := Rmdir(Id, Params);
      'network.attach_bridge':
        Response := AttachToBridge(Id, Params);
      'network.create_device':
        Response := CreateNetworkDevice(Id, Params);
      'network.destroy_device':
        Response := DestroyNetworkDevice(Id, Params);
      'pf.load_rules':
        Response := PfLoadRules(Id, Params);
      'pf.unload_rules':
        Response := PfUnloadRules(Id, Params);
      'process.get_pid':
        Response := GetPidValue(Id, Params);
      'process.kill_pid':
        Response := KillPid(Id, Params);
      'service.restart':
        Response := RestartService(Id, Params);
      'vm.create':
        Response := VmCreate(Params);
      'vm.delete':
        Response := VmDelete(Params);
      'vm.destroy':
        Response := DestroyVirtualMachine(Id, Params);
      'vm.start':
        Response := VmStart(Params);
      'vm.stop':
        Response := VmStop(Params);
      'zfs.create_dataset':
        Response := ZfsCreateDataset(Id, Params);
      'zfs.create_zvol':
        Response := ZfsCreateZvol(Id, Params);
      'zfs.set_property':
        Response := ZfsSetPropertyValue(Id, Params);
      'zfs.destroy':
        Response := ZfsDestroy(Id, Params);
    else
      begin
        Response := TJSONObject.Create;
        Response.Add('success', False);
        Response.Add('error', 'unknown command');
      end;
    end;

    if Assigned(Response) then
    begin
      Result := Response.AsJSON;
      Response.Free;
    end
    else
      Result := '{"success" : false, "error" : "empty response"}';

  finally
    Request.Free;
  end;

end;
end.

