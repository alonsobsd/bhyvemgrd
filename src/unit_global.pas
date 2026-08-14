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

unit unit_global;

{$mode ObjFPC}{$H+}

interface

uses
  Unix;

type
  TVmState = (vmRebooted, vmPowerOff, vmHalted, vmTripleFault, vmExited, vmSuspended, vmRunning, vmException);

  TVmInfo = record
    Name     : String;
    State    : TVmState;
    PID      : Integer;
    ExitCode : Integer;
  end;

  TSetCred = record
    sc_uid: uid_t;
    sc_ruid: uid_t;
    sc_svuid: uid_t;
    sc_gid: gid_t;
    sc_rgid: gid_t;
    sc_svgid: gid_t;
    sc_pad: cuint;
    sc_supp_groups_nb: cuint;
    sc_supp_groups: ^gid_t;
    sc_label: Pointer;
  end;

{ General section }
function GetOsreldate:string;
procedure SetOsreldate(const Value:string);

{ General section }
property Osreldate:string read GetOsreldate write SetOsreldate;

const
  { Setcred flags }
  SETCREDF_UID      = $00000001;
  SETCREDF_RUID     = $00000002;
  SETCREDF_SVUID    = $00000004;
  SETCREDF_GID      = $00000008;
  SETCREDF_RGID     = $00000010;
  SETCREDF_SVGID    = $00000020;
  { User and group ids }
  BHYVEMGRD_USER = 833;
  BHYVEMGRD_GROUP = 833;
  { Program paths }
  BHYVE_CMD = '/usr/sbin/bhyve';
  BHYVECTL_CMD  = '/usr/sbin/bhyvectl';
  CHMOD_CMD = '/bin/chmod';
  CHOWN_CMD = '/usr/sbin/chown';
  IFCONFIG_CMD = '/sbin/ifconfig';
  INSTALL_CMD = '/usr/bin/install';
  KILL_CMD = '/bin/kill';
  KLDLOAD_CMD = '/sbin/kldload';
  KLDSTAT_CMD = '/sbin/kldstat';
  MDO_CMD = '/usr/bin/mdo';
  PFCTL_CMD = '/sbin/pfctl';
  PGREP_CMD = '/usr/bin/pgrep';
  RM_CMD = '/bin/rm';
  SERVICE_CMD = '/usr/sbin/service';
  SYSCTL_CMD = '/sbin/sysctl';
  ZFS_CMD = '/sbin/zfs';
  { Configuration file path }
  COMMON_CONFIG_FILE = '/usr/local/etc/bhyvemgrd/common.conf';
  CONFIG_FILE = '/usr/local/etc/bhyvemgrd/daemon.conf';
  { Socket file path }
  SOCKET_FILE = '/var/run/bhyvemgrd/bhyvemgrd.sock';
  { Packet filter anchors }
  NatAnchor = 'bhyvemgr-nat';
  RdrAnchor = 'bhyvemgr-rdr';
  PassInAnchor = 'bhyvemgr-in';
  PassOutAnchor = 'bhyvemgr-out';

var
  StopRequested: Boolean = False;
  ReloadRequested: Boolean = False;
  ActiveThreads: LongInt = 0;
  IsRunning : Boolean = False;

implementation

var
  OsreldateVar: String;

function GetOsreldate: string;
begin
  Result := OsreldateVar;
end;

procedure SetOsreldate(const Value: string);
begin
  OsreldateVar := Value;
end;

end.

