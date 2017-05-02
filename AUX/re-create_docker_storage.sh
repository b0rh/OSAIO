#!/bin/bash
systemctl stop docker
rm -rf /dev/loop*
for n in {0..30};do mknod -m 660 /dev/loop$n b 7 $n;done
docker-storage-setup --reset
rm -rf /var/lib/docker
systemctl restart docker
systemctl status docker
