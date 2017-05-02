#!/bin/bash

function initconf_ssh {
    _homepath=$1
    mkdir -p $_homepath/.ssh
    ssh-keygen -f $_homepath/.ssh/id_rsa -N ''
    chmod 500 $_homepath/.ssh -R

}


# ----------------------------- #
#       CONFIGURE ENVIROMENT    #
# ----------------------------- #

# Set enviroment

touch /__OSAIO__

# LOCALES
# Some images remove all locales
yum -y reinstall glibc-common

# TODO: Check errors without full privileged
#Failed to issue method call: Connection timed out
#Failed to set keymap: Connection timed out
#Failed to set keymap: Connection timed out

localectl set-locale LANG=es_ES.utf8
localectl set-x11-keymap es
localectl set-keymap es

# Remove all devices
#TODO: Create new container with minimal devices
#rm -rf /dev
#mkdir -m 755 /dev
#
##LOOP devices
## First 30 loop devices reserv to host
#rm -rf /dev/loop*
#for n in {31..200};do mknod -m 660 /dev/loop$n b 7 $n;done
#
##Basic devices
#    mknod -m 600 /dev/initctl p
#    mknod -m 666 /dev/full c 1 7
#    mknod -m 666 /dev/null c 1 3
#    mknod -m 444 /dev/random c 1 8
#
#    mknod -m 444 /dev/urandom c 1 9
#    mknod -m 666 /dev/zero c 1 5
#
##Virtualization
#    mknod -m 666 /dev/kvm c 10 232
## Virtual networking and VPN
#    mkdir /dev/net
#    mknod -m 666  /dev/net/tun c 10 200
## Char devices (tty, pseudotty, virtual console, serial ...)
#    # Basic and special ttys
#    mknod -m 666 /dev/tty c 5 0
#    mknod -m 622 /dev/console c 5 1
#    mknod -m 666 /dev/ptmx c 5 2
#    chown -v root:tty /dev/{console,ptmx,tty}
#
#    # TTYs creation
#    for n in {0..63}; do mknod -m 666 /dev/tty$n c 4 $n;done
#    for n in '' {0..32}; do chown root:tty /dev/tty$n ;done
#
#    # Serial consoles
#    for n in {64..94}; do mknod -m 666 /dev/ttyS$(expr $n - 64) c 4 $n;done
#    for n in {64..94}; do chown root:dialout /dev/ttyS$(expr $n - 64) ;done
#
#    # Virtual consoles
#    mknod -m 666 /dev/vcs c 7 0
#    for n in {1..6}; do mknod -m 666 /dev/vcs$n c 7 $n;done
#    for n in '' {1..6}; do chown root:tty /dev/vcs$n ;done
#
#    mknod -m 666 /dev/vcsa c 7 128
#    for n in {129..131}; do mknod -m 666 /dev/vcsa$n c 7 $n;done
#    for n in '' {129..131}; do chown root:tty /dev/vcsa$n ;done
#
#    # Pseudo terminals
#    mkdir /dev/pts
    mount -vt devpts -o gid=5,mode=620 none /dev/pts


## Share memory device
#    mkdir /dev/shm
#    mount -vt tmpfs none /dev/shm
#
#
## Standar input/outpur/errors and others fd
#    ln -s /proc/self/fd/0 /dev/stdin
#    ln -s /proc/self/fd/1 /dev/stdout
#    ln -s /proc/self/fd/2 /dev/stderr
#    ln -s /proc/self/fd /dev/fd


## Adds hosts file with public and private osaio networks hostnames
## TODO: Patch puppet or manual postconf before rdo deploy
#file_path='/etc/hosts'
#mv $file_path $file_path.original
#cat > $file_path << EOF
#
#127.0.0.1	localhost
#::1     localhost ip6-localhost ip6-loopback
#fe00::0 ip6-localnet
#ff00::0 ip6-mcastprefix
#ff02::1 ip6-allnodes
#ff02::2 ip6-allrouters
#
## TODO: Fix crash with autohost puppet dashboard script
##192.168.168.1   pub-osaio.dck.etrea pub-osaio
##10.10.10.10	priv-osaio.dck.etrea priv-osaio
#
#EOF


# Patch fake /proc/sys/net/bridge cloned from host
# WORKAROUND: To complete neutron installation, docker don't publish netfilter bridge state
mkdir -p /proc_aux
mount -t proc proc /proc_aux -o rw,nosuid,nodev,noexec,relatime

mkdir -p /tmp/net
mount --bind /tmp/net /proc/sys/net

for d in /proc_aux/sys/net/*; do mkdir -p /proc/sys/net/$(basename $d); mount --bind $d /proc/sys/net/$(basename $d) ;done
cp ./bridge /proc/sys/net/ -rf


#cp /etc/sudoers /etc/sudoers.old
## Adds temporal root privilegis to sp without passwd
#echo "sp      ALL=(ALL)	NOPASSWD:ALL" >> /etc/sudoers

# ----------------------------------------- #
#       INSTALL ENVIROMENT DEPENDENCIES     #
# ----------------------------------------- #

# BASIC TOOLS
yum install -y iproute net-tools yum nano iputils sudo

# EXTRAS
yum install -y bash-completion bash-completion-extras virt-install

# ----------------------------- #
#       INSTALL DEPENDENCIES    #
# ----------------------------- #

# Add centos openstack repositories
#yum install -y centos-release-openstack-mitaka
yum install -y centos-release-openstack-newton
yum update -y

# Openstack packstack dependencies
yum install -y iproute net-tools yum nano iputils net-tools pwgen wget curl tar unzip mlocate deltarpm

# Install packstack
yum install -y openstack-packstack

# Openssh
yum install -y openssh-server openssh policycoreutils hostname initscripts dhclient
systemctl enable sshd
systemctl start sshd

adduser sp
cp /home/sp/.bashrc /root
initconf_ssh "/home/sp"
chown sp:sp /home/sp -R

initconf_ssh "/root"
cat /home/sp/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# Rabbitmq
yum install -y rabbitmq-server
systemctl daemon-reload


# NFS server
# Cinder storge backend 10.10.10.10:/NFS-cinder-storage
storage_path='/NFS-cinder-storage'
service_ip='10.10.10.10'

# NFS utils
yum install -y nfs-utils libnfsidmap

# Configure shares
mkdir $storage_path
chmod 777 $storage_path
echo "$storage_path $service_ip(rw,sync,no_root_squash)" > /etc/exports


# Set to run at boot
systemctl enable rpcbind
systemctl enable nfs-server

# Start services and dependencies
systemctl start rpcbind
systemctl start nfs-server
systemctl start rpc-statd
systemctl start nfs-idmapd

# Reload and show NFS conf
exportfs -r
exportfs -v

# ----------------------------- #
#       APPLY PATCHES           #
# ----------------------------- #

yum install -y patch

# NOTE: Step 0 -> Clean all .orig and .patch: (be case with path, .orig files in use outside this project) ### find /usr/share/ -type f -name "*.orig" -exec bash -c 'dir=$(dirname '{}');fm=$(basename '{}');fo=${fm%.*}; cd $dir; rm $fo $fo.patch; mv $fm $fo ' \; ###
# NOTE: Step 1 -> Create patch files: ### find / -type f -name "*.docker.mod" -exec bash -c 'dir=$(dirname '{}');fo=$(basename '{}' .docker.mod );fm=$(basename '{}'); cd $dir; diff -u $fo $fm > ${fo}.patch ' \; ###
# NOTE: Step 2 -> Pack all patches: ### find / -type f \( -name "*.patch" -o -name "*.docker.mod" \) -print0 | tar -czvf /tmp/patches.tgz --null -T - ###

# Extract patches
tar xfvz patches.tgz -C /
# Apply patches
find / -type f -name "*.patch" -exec bash -c 'cd $(dirname '{}'); patch -b < $(basename '{}') ' \;
#echo "pause 300s"; sleep 300

# ----------------------------- #
#       DEPLOY OPENSTACK        #
# ----------------------------- #

# Prepare answer.txt
mkdir -p /home/sp/CLOUD
cp ./answer.txt /home/sp/CLOUD/
chown sp:sp /home/sp/CLOUD -R

#su -c "packstack --answer-file=/home/sp/CLOUD/answer.txt" sp

# Disable auditd
chkconfig auditd off

packstack --answer-file=answer.txt


# ------------------------------------ #
#       POST DEPLOY CONFIGURATIONS     #
# ------------------------------------ #

# Set KVM virtualization to run in baremetal (use qemu option to VM)
#sudo openstack-config --set /etc/nova/nova.conf DEFAULT compute_driver libvirt.LibvirtDriver
#sudo openstack-config --set /etc/nova/nova.conf libvirt virt_type kvm
#systemctl restart openstack-nova-*


# TODO: Add support nova-docker
# TODO: Add network conf


# ---------------- #
#       CLEAN      #
# ---------------- #

# Clean temporal packstack files
#rm /var/tmp/ -r

#systemctl restart openstack-nova-*
## Clean install
##echo "" > /root/.ssh/authorized_keys
#rm /etc/sudoers
#mv /etc/sudoers.old /etc/sudoers


/bin/bash
