{ SPDX-License-Identifier: BSD-3-Clause

Copyright (c) 2026, J. Alonso Cárdenas <acardenas@bsd-peru.org>

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
      'zfs.create_snapshot':
        Response := ZfsCreateSnapshot(Id, Params);
      'zfs.create_zvol':
        Response := ZfsCreateZvol(Id, Params);
      'zfs.set_property':
        Response := ZfsSetPropertyValue(Id, Params);
      'zfs.destroy':
        Response := ZfsDestroy(Id, Params);
      'zfs.destroy_snapshot':
        Response := ZfsDestroySnapshot(Id, Params);
      'zfs.rollback_snapshot':
        Response := ZfsRollbackSnapshot(Id, Params);
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

