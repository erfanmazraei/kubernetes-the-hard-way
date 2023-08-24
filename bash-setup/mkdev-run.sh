#!/usr/bin/env bash


###### The container are usually run by low level runtimes like runc.
###### they don't know anything about images but they use container bundles.
###### container bundels are consist of 1.filesystem that has file needed to run container.
###### and the config file that shows how to run run a container. it's like docker run command parameters.

###### Other highlevel runtimes extract container bundle from container images.
###### umoci is a package that is used for modifying containerr images and make bundle from them.
wget https://github.com/opencontainers/umoci/releases/download/v0.4.7/umoci.amd64
chmod +x umoci.amd64
mv umoci.amd64 /usr/local/bin/umoci

###### after converting image to OCI format, you cat use umoci to extract bundle from it.
umoci raw unpack --image httpd:2.4.48 --rootless rootfs
umoci raw runtime-config --image httpd:2.4.48 --rootfs rootfs --rootless config.json
###### We have roofs that is the filesystem of container and config.json that has configuration to run container form it.


###### The popular low level container runtime is used is runc. This is used by many tools like docker, podman, C-RIO, etc.
wget https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64
chmod +x runc.amd64
mv runc.amd64 /usr/local/bin/runc

###### now we can run container with runc command.
runc run test
# AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
# AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.0.1. Set the 'ServerName' directive globally to suppress this message
# (13)Permission denied: AH00072: make_sock: could not bind to address [::]:80
# (13)Permission denied: AH00072: make_sock: could not bind to address 0.0.0.0:80
# no listening sockets available, shutting down
# AH00015: Unable to open logs

###### it fails because it want to use 80 port that need root privilege. we change the port to solve it
vim rootfs/usr/local/apache2/conf/httpd.conf
runc run test
###### now it's up and running but it's attached to terminal. the 'ps' command shows it.
# ps --forest -x
#     447 ?        Ssl   23:24 /usr/bin/containerd
#     448 ?        Ss     3:20 sshd: /usr/sbin/sshd -D [listener] 3 of 10-100 star
#  862682 ?        Ss     0:00  \_ sshd: root@pts/0
#  862705 pts/0    Ss     0:00  |   \_ -bash
#  864025 pts/0    Sl+    0:00  |       \_ runc run test
#  864034 pts/0    Ss+    0:00  |           \_ httpd -DFOREGROUND
#  864041 pts/0    Sl+    0:00  |               \_ httpd -DFOREGROUND
#  864042 pts/0    Sl+    0:00  |               \_ httpd -DFOREGROUND
#  864043 pts/0    Sl+    0:00  |               \_ httpd -DFOREGROUND
#  864009 ?        Ss     0:00  \_ sshd: [accepted]
#  864011 ?        Ss     0:00  \_ sshd: [accepted]

###### When we want to detach mode run container we use '--detach' flag.
runc run test --detach
# ERRO[0000] runc run failed: cannot allocate tty if runc will detach without setting console socket

###### this error is because of in config.json of container is requires terminal. change it and run it again.
vim config.json
runc run test --detach
# ps --forest -x
#  859873 ?        Ssl    0:02 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
#  862685 ?        Ss     0:00 /lib/systemd/systemd --user
#  862686 ?        S      0:00  \_ (sd-pam)
#  864169 ?        Ss     0:00 httpd -DFOREGROUND
#  864178 ?        Sl     0:00  \_ httpd -DFOREGROUND
#  864179 ?        Sl     0:00  \_ httpd -DFOREGROUND
#  864180 ?        Sl     0:00  \_ httpd -DFOREGROUND

###### Now it has detached and are working as we expect.
###### now runc save the configuration and process of containers in '/run/runc/' or "/run/<uid>/runc/" with container name folder.
cat /run/runc/test/state.json | jq
# {
#   "id": "test",
#   "init_process_pid": 864169,
#   "init_process_start": 510805162,
#   "created": "2023-07-30T14:59:20.223850401Z",
#   "config": {
#     "no_pivot_root": false,
#     "parent_death_signal": 0,
#     "rootfs": "/root/umoci/rootfs",
#     "umask": null,
#     "readonlyfs": false,
#     "rootPropagation": 0,
#     "mounts": [
#       {
#         "source": "proc",
#         "destination": "/proc",
#         "device": "proc",

###### Also these and other options are available too.
runc exec test whoami
# root
runc exec --tty test sh
# ls
# bin  build  cgi-bin  conf  error  htdocs  icons  include  logs	modules


###### There is also other lowlevel runtimes like crun that we can use, it's similar to runc but fully written in C.
