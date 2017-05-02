#!/bin/bash
#
# Create a base CentOS Docker image.

# Compose example:

#FROM centos:7
#MAINTAINER "b0rh" <francisco@garnelo.eu>
#ENV container docker
#RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i ==
#systemd-tmpfiles-setup.service ] || rm -f $i; done); \
#rm -f /lib/systemd/system/multi-user.target.wants/*;\
#rm -f /etc/systemd/system/*.wants/*;\
#rm -f /lib/systemd/system/local-fs.target.wants/*; \
#rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
#rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
#rm -f /lib/systemd/system/basic.target.wants/*;\
#rm -f /lib/systemd/system/anaconda.target.wants/*;
#VOLUME [ "/sys/fs/cgroup" ]
#CMD ["/usr/sbin/init"]



# option defaults
yum_config=/etc/yum.conf
if [ -f /etc/dnf/dnf.conf ] && command -v dnf &> "$target"/dev/null; then
	yum_config=/etc/dnf/dnf.conf
	alias yum=dnf
fi
clone_host=true
name=$1

if [[ -z $name ]]; then
    name='centos-jail'
fi

echo $name


target= /tmp/


#target=$(mktemp -d --tmpdir $(basename $0).XXXXXX)
target="/tmp/${name}_rootfs"
echo "target:$target"
mkdir $target

set -x
if ( $clone_host ); then
    echo "CLONE..."
    # TODO: Adds minimal devices to support kvm,lvm,etc ...
    # WORKAROUND: Created into container using provisioning script setup.sh
    #cp -r "$target"/dev "$target"   # Import host devices case, (mandatory to create a aio openstack container)
    cp -r /etc/yum.repos.d "$target"/etc # Import repositories conf from host
    install_packages="$install_packages iproute net-tools yum initscripts nano iputils openssh-server openssh systemd passwd traceroute hostname net-tools pwgen wget curl tar unzip mlocate patch" # Add networking internal configuration tool
    #Adding strace for debugging, comment out when not needed.
    install_packages="$install_packages strace"
    rm -rf "$target"/dev
    mkdir -m 755 "$target"/dev

#LOOP devices
# First 30 loop devices reserv to host
rm -rf "$target"/dev/loop*
for n in {31..200};do mknod -m 660 "$target"/dev/loop$n b 7 $n;done

#Basic devices
    mknod -m 600 "$target"/dev/initctl p
    mknod -m 666 "$target"/dev/full c 1 7
    mknod -m 666 "$target"/dev/null c 1 3
    mknod -m 444 "$target"/dev/random c 1 8

    mknod -m 444 "$target"/dev/urandom c 1 9
    mknod -m 666 "$target"/dev/zero c 1 5

#Virtualization
    mknod -m 666 "$target"/dev/kvm c 10 232
# Virtual networking and VPN
    mkdir "$target"/dev/net
    mknod -m 666  "$target"/dev/net/tun c 10 200
# Char devices (tty, pseudotty, virtual console, serial ...)
    # Basic and special ttys
    mknod -m 666 "$target"/dev/tty c 5 0
    mknod -m 622 "$target"/dev/console c 5 1
    mknod -m 666 "$target"/dev/ptmx c 5 2
    chown -v root:tty "$target"/dev/{console,ptmx,tty}

    # TTYs creation
    for n in {0..63}; do mknod -m 666 "$target"/dev/tty$n c 4 $n;done
    for n in '' {0..32}; do chown root:tty "$target"/dev/tty$n ;done

    # Serial consoles
    for n in {64..94}; do mknod -m 666 "$target"/dev/ttyS$(expr $n - 64) c 4 $n;done
    for n in {64..94}; do chown root:dialout "$target"/dev/ttyS$(expr $n - 64) ;done

    # Virtual consoles
    mknod -m 666 "$target"/dev/vcs c 7 0
    for n in {1..6}; do mknod -m 666 "$target"/dev/vcs$n c 7 $n;done
    for n in '' {1..6}; do chown root:tty "$target"/dev/vcs$n ;done

    mknod -m 666 "$target"/dev/vcsa c 7 128
    for n in {129..131}; do mknod -m 666 "$target"/dev/vcsa$n c 7 $n;done
    for n in '' {129..131}; do chown root:tty "$target"/dev/vcsa$n ;done

    # Pseudo terminals
    mkdir "$target"/dev/pts

    rm "$target"/dev/sd*
    rm "$target"/dev/dm*
    rm "$target"/dev/md* -rf
    rm "$target"/dev/vg0 -rf
    rm "$target"/dev/sg*
    rm "$target"/dev/kvm
    rm "$target"/dev/kmsg
    rm "$target"/dev/kcore

else # Default case

    mkdir -m 755 "$target""$target"/dev
    mknod -m 600 "$target""$target"/dev/console c 5 1
    mknod -m 600 "$target""$target"/dev/initctl p
    mknod -m 666 "$target""$target"/dev/full c 1 7
    mknod -m 666 "$target""$target"/dev/null c 1 3
    mknod -m 666 "$target""$target"/dev/ptmx c 5 2
    mknod -m 666 "$target""$target"/dev/random c 1 8
    mknod -m 666 "$target""$target"/dev/tty c 5 0
    mknod -m 666 "$target""$target"/dev/tty0 c 4 0
    mknod -m 666 "$target""$target"/dev/urandom c 1 9
    mknod -m 666 "$target""$target"/dev/zero c 1 5
fi


# amazon linux yum will fail without vars set
if [ -d /etc/yum/vars ]; then
	mkdir -p -m 755 "$target"/etc/yum
	cp -a /etc/yum/vars "$target"/etc/yum/
fi

if [[ -n "$install_groups" ]];
then
    yum -c "$yum_config" --installroot="$target" --releasever=/ --setopt=tsflags=nodocs \
        --setopt=group_package_types=mandatory -y groupinstall $install_groups
fi

if [[ -n "$install_packages" ]];
then
    yum -c "$yum_config" --installroot="$target" --releasever=/ --setopt=tsflags=nodocs \
        --setopt=group_package_types=mandatory -y install $install_packages
fi

yum -c "$yum_config" --installroot="$target" -y clean all

cat > "$target"/etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=localhost.localdomain
EOF

# Clean unnecesary systemd scripts
#rm -f "$target"/lib/systemd/system/multi-user.target.wants/*
#rm -f "$target"/etc/systemd/system/*.wants/*
#rm -f "$target"/lib/systemd/system/local-fs.target.wants/*
#rm -f "$target"/lib/systemd/system/sockets.target.wants/*udev*
#rm -f "$target"/lib/systemd/system/sockets.target.wants/*initctl*
#rm -f "$target"/lib/systemd/system/basic.target.wants/*
#rm -f "$target"/lib/systemd/system/anaconda.target.wants/*

# effectively: febootstrap-minimize --keep-zoneinfo --keep-rpmdb --keep-services "$target".
#  locales
##rm -rf "$target"/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
##  docs and man pages
#rm -rf "$target"/usr/share/{man,doc,info,gnome/help}
##  cracklib
#rm -rf "$target"/usr/share/cracklib
##  i18n
#rm -rf "$target"/usr/share/i18n
##  yum cache
#rm -rf "$target"/var/cache/yum
#mkdir -p --mode=0755 "$target"/var/cache/yum
##  sln
#rm -rf "$target"/sbin/sln
##  ldconfig
#rm -rf "$target"/etc/ld.so.cache "$target"/var/cache/ldconfig
#mkdir -p --mode=0755 "$target"/var/cache/ldconfig

version=
for file in "$target"/etc/{redhat,system}-release
do
    if [ -r "$file" ]; then
        version="$(sed 's/^[^0-9\]*\([0-9.]\+\).*$/\1/' "$file")"
        break
    fi
done

if [ -z "$version" ]; then
    echo >&2 "warning: cannot autodetect OS version, using '$name' as tag"
    version=$name
fi

tar --numeric-owner -c -C "$target" . | docker import - $name:$version

docker run -i -t --rm $name:$version /bin/bash -c 'echo success'

rm -rf "$target"
