# Bhyvemgrd
Bhyvemgrd exposes a JSON-based IPC interface over a UNIX domain socket, allowing the [bhyvemgr](https://github.com/alonsobsd/bhyvemgr) client to request privileged operations required for bhyve virtual machines, execute system-level tasks, monitor VM process states, and receive asynchronous state notifications.

# Dependencies
Almost all FreeBSD versions have a complete support for use [mdo](https://man.freebsd.org/cgi/man.cgi?query=mdo&apropos=0&sektion=0&manpath=FreeBSD+14.4-RELEASE&format=html) tool and [mac_do](https://man.freebsd.org/cgi/man.cgi?query=mac_do&apropos=0&sektion=0&manpath=FreeBSD+14.4-RELEASE&format=html). Bhyvemgrd uses mac_do/mdo for execute commands with root credentials but it runs using an unpriviliged user.
By default, bhyvemgrd port adds an user **(bhyvemgrd/833)** and group **(bhyvemgrd/833)** so it must be used to define the mac_do rules.

```sh
# kldload mac_do
# sysctl security.mac.do.rules="uid=833>uid=0,gid=*,+gid=*"
```

If you want to do these settings persistent, add the following lines:

```sh
# ee /boot/loader.conf
mac_do_load=YES
# ee /etc/sysctl.conf
security.mac.do.rules="uid=833>uid=0,gid=*,+gid=*"
```

The **vmm** and **nmdm** modules are other dependencies, but these can be loaded by bhyvemgrd automatically if previous settings are defined. Otherwise, you can put the following lines in your /boot/loader.conf:

```sh
# ee /boot/loader.conf
vmm_load=YES
nmdm_load=YES
```

Finally, the bhvemgrd needs two configuration files to run: **daemon.conf** and **common.conf**. The first is installed by bhyvemgrd port and the last one is created by [bhyvemgr](https://github.com/alonsobsd/bhyvemgr) GUI on first time and it only contains **vm_path** setting. The vm_path defines the path where virtual machines files are stored in your system.
Both files are stored at **/usr/local/etc/bhyvemgrd** directory.

```sh
# service bhyvemgrd enable
# service bhyvemgrd start
```
# Note
- The bhyvemgrd daemon only can be used by bhyvemgr >= 2.0.0
- Start bhyvemgrd service only after bhyvemgr generated gui.conf and common.conf files. Othwerwise, it will not start. Look at **/var/log/bhyvemgrd.log** for the reason
- Changes in **/usr/local/etc/bhyvmgrd/daemon.conf** can be reload using **service bhyvemgrd reload**
- A **service bhyvemgrd restart** is not allowed if you have virtual machines running in that time
