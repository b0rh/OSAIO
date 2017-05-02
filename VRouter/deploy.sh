#!/bin/bash

#TODO:
# https://linux.die.net/man/7/capabilities
# http://lxr.free-electrons.com/source/include/uapi/linux/capability.h?v=3.12
# https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/include/linux/capability.h?id=refs/tags/v3.10.104
# TODO: Test devices rm, in dockerfile

# Common functions
source ../LIB/libSDN.sh
source ../LIB/libCommon.sh

# Image conf
BASE_VER='BB'
BASE_NAME='openwrt'
PROJ_NAME='mysite'

# Container conf
CNT_TP="$PROJ_NAME/$BASE_NAME:$BASE_VER"
CNT_NM='VRouter'
CNT_TG='vr' # container tag
USR_HOME='/root'
SHARE_ETC='/change_me/VRouter/etc/' 



# Enable Coredump
addreplace_conf /etc/sysctl.conf kernel.core_uses_pid = 1
addreplace_conf /etc/sysctl.conf kernel.core_pattern = /root/core-%e-%s-%u-%g-%p-%t
addreplace_conf /etc/sysctl.conf fs.suid_dumpable = 2


# Tunning host kernel
addreplace_conf /etc/sysctl.conf net.ipv4.conf.default.arp_ignore = 1
addreplace_conf /etc/sysctl.conf net.ipv4.conf.all.arp_ignore = 1
addreplace_conf /etc/sysctl.conf net.ipv4.ip_forward = 1
addreplace_conf /etc/sysctl.conf net.ipv4.icmp_echo_ignore_broadcasts = 1
addreplace_conf /etc/sysctl.conf net.ipv4.icmp_ignore_bogus_error_responses = 1
addreplace_conf /etc/sysctl.conf net.ipv4.igmp_max_memberships = 100
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_ecn = 0
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_fin_timeout = 30
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_keepalive_time = 120
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_syncookies = 1
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_timestamps = 1
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_sack = 1
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_dsack = 1
addreplace_conf /etc/sysctl.conf net.ipv6.conf.default.forwarding = 1
addreplace_conf /etc/sysctl.conf net.ipv6.conf.all.forwarding = 1
addreplace_conf /etc/sysctl.conf net.netfilter.nf_conntrack_acct = 1
addreplace_conf /etc/sysctl.conf net.netfilter.nf_conntrack_checksum = 0
addreplace_conf /etc/sysctl.conf net.netfilter.nf_conntrack_max = 16384
addreplace_conf /etc/sysctl.conf net.netfilter.nf_conntrack_tcp_timeout_established = 7440
addreplace_conf /etc/sysctl.conf net.netfilter.nf_conntrack_udp_timeout = 60
addreplace_conf /etc/sysctl.conf net.netfilter.nf_conntrack_udp_timeout_stream = 180
addreplace_conf /etc/sysctl.conf net.bridge.bridge-nf-call-arptables = 1
addreplace_conf /etc/sysctl.conf net.bridge.bridge-nf-call-ip6tables = 1
addreplace_conf /etc/sysctl.conf net.bridge.bridge-nf-call-iptables = 1

# Download rootfs
rm openwrt-rootfs.tar.gz

# Check host Libc version compatibility ¡¡¡¡¡¡¡¡¡¡
# Chaos Calmer 15.05
#curl https://downloads.openwrt.org/chaos_calmer/15.05/x86/generic/openwrt-15.05-x86-generic-Generic-rootfs.tar.gz -o openwrt-rootfs.tar.gz
#curl https://downloads.openwrt.org/chaos_calmer/15.05/x86/64/openwrt-15.05-x86-64-rootfs.tar.gz -o openwrt-rootfs.tar.gz

# Chaos Calmer 15.05.1
#curl https://downloads.openwrt.org/chaos_calmer/15.05.1/x86/generic/openwrt-15.05.1-x86-generic-Generic-rootfs.tar.gz -o openwrt-rootfs.tar.gz
#curl https://downloads.openwrt.org/chaos_calmer/15.05.1/x86/64/openwrt-15.05.1-x86-64-rootfs.tar.gz -o openwrt-rootfs.tar.gz

# Trunk
#curl https://downloads.openwrt.org/snapshots/trunk/x86/kvm_guest/openwrt-x86-generic-generic-rootfs.tar.gz -o openwrt-rootfs.tar.gz
#curl https://downloads.openwrt.org/chaos_calmer/15.05.1/x86/generic/openwrt-15.05.1-x86-generic-Generic-rootfs.tar.gz -o openwrt-rootfs.tar.gz

curl https://downloads.openwrt.org/snapshots/trunk/x86/64/openwrt-x86-64-generic-rootfs.tar.gz -o openwrt-rootfs.tar.gz

# Build base image
docker rmi $CNT_TP
docker build -t $CNT_TP .



# NOTE: Breaks some hardened kernels and SElinux, even in Permissive
#            --cap-add=WAKE_ALARM \
#            --cap-add=BLOCK_SUSPEND \


docker run  --cap-drop=all \
            --cap-add=FOWNER \
            --cap-add=FSETID \
            --cap-add=KILL \
            --cap-add=SETGID \
            --cap-add=SETUID \
            --cap-add=NET_BIND_SERVICE \
            --cap-add=NET_BROADCAST \
            --cap-add=NET_ADMIN \
            --cap-add=NET_RAW \
            --cap-add=IPC_LOCK \
            --cap-add=IPC_OWNER \
            --cap-add=SYS_PACCT \
            --cap-add=SYS_ADMIN \
            --cap-add=SYS_NICE \
            --cap-add=SYS_RESOURCE \
            --cap-add=SYS_TIME \
            --cap-add=SYS_TTY_CONFIG \
            --cap-add=MAC_OVERRIDE \
            --cap-add=MAC_ADMIN \
            --cap-add=SYSLOG \
            --cap-add=SYS_MODULE \
            -e "TERM=xterm-256color" \
            --net='none' \
            --dns=208.67.222.222 \
            --hostname ${CNT_NM}.dck.mysite \
            --name $CNT_NM \
            -v ${SHARE_ETC}:/etc/ \
            -d \
            $CNT_TP \
            sh -c '/sbin/init'

# OK
#docker run  --cap-drop=all \
#            --cap-add=CHOWN \
#            --cap-add=DAC_OVERRIDE \
#            --cap-add=DAC_READ_SEARCH \
#            --cap-add=FOWNER \
#            --cap-add=FSETID \
#            --cap-add=KILL \
#            --cap-add=SETGID \
#            --cap-add=SETUID \
#            --cap-add=SETPCAP \
#            --cap-add=LINUX_IMMUTABLE \
#            --cap-add=NET_BIND_SERVICE \
#            --cap-add=NET_BROADCAST \
#            --cap-add=NET_ADMIN \
#            --cap-add=NET_RAW \
#            --cap-add=IPC_LOCK \
#            --cap-add=IPC_OWNER \
#            --cap-add=SYS_MODULE \
#            --cap-add=SYS_RAWIO \
#            --cap-add=SYS_CHROOT \
#            --cap-add=SYS_PTRACE \
#            --cap-add=SYS_PACCT \
#            --cap-add=SYS_ADMIN \
#            --cap-add=SYS_BOOT \
#            --cap-add=SYS_NICE \
#            --cap-add=SYS_RESOURCE \
#            --cap-add=SYS_TIME \
#            --cap-add=SYS_TTY_CONFIG \
#            --cap-add=MKNOD \
#            --cap-add=LEASE \
#            --cap-add=AUDIT_WRITE \
#            --cap-add=AUDIT_CONTROL \
#            --cap-add=SETFCAP \
#            --cap-add=MAC_OVERRIDE \
#            --cap-add=MAC_ADMIN \
#            --cap-add=SYSLOG \
#            --net='none' \
#            --name $CNT_NM \
#            -d $CNT_TP


#docker run  --cap-drop=all \
#            --cap-add=CHOWN \
#            --cap-add=DAC_OVERRIDE \
#            --cap-add=DAC_READ_SEARCH \
#            --cap-add=FOWNER \
#            --cap-add=FSETID \
#            --cap-add=KILL \
#            --cap-add=SETGID \
#            --cap-add=SETUID \
#            --cap-add=SETPCAP \
#            --cap-add=LINUX_IMMUTABLE \
#            --cap-add=NET_BIND_SERVICE \
#            --cap-add=NET_BROADCAST \
#            --cap-add=NET_ADMIN \
#            --cap-add=NET_RAW \
#            --cap-add=IPC_LOCK \
#            --cap-add=IPC_OWNER \
#            --cap-add=SYS_MODULE \
#            --cap-add=SYS_RAWIO \
#            --cap-add=SYS_CHROOT \
#            --cap-add=SYS_PTRACE \
#            --cap-add=SYS_PACCT \
#            --cap-add=SYS_ADMIN \
#            --cap-add=SYS_BOOT \
#            --cap-add=SYS_NICE \
#            --cap-add=SYS_RESOURCE \
#            --cap-add=SYS_TIME \
#            --cap-add=SYS_TTY_CONFIG \
#            --cap-add=MKNOD \
#            --cap-add=LEASE \
#            --cap-add=AUDIT_WRITE \
#            --cap-add=AUDIT_CONTROL \
#            --cap-add=SETFCAP \
#            --cap-add=MAC_OVERRIDE \
#            --cap-add=MAC_ADMIN \
#            --cap-add=SYSLOG \
#            --cap-add=WAKE_ALARM \
#            --cap-add=BLOCK_SUSPEND \
#            --net='none' \
#            --dns=208.67.222.222 \
#            --hostname $CNT_NM \
#            --name $CNT_NM \
#            -d $CNT_TP


# Create missing directories
RUN $CNT_NM 'mkdir -pv /var/run'
RUN $CNT_NM 'mkdir -pv /var/lock'


# Remove all modules
#RUN $CNT_NM 'rm /lib/modules/*/*'

# Adds bridges and set ip address
add_bridge 'ext' '192.168.1.254/24'
add_bridge 'int' '10.10.1.254/24'

# Creates and attachs veth to bridges
add_bridge_port 'ext' $(add_veth $CNT_NM $CNT_TG ext)
add_bridge_port 'int' $(add_veth $CNT_NM $CNT_TG int)

# Passthrough using macvlan to physical devices eth0 to p_eth0 into container
# to use OVH or hetzner public ips
add_macvlan VRouter hzt '00:XX:XXXX:XX:XX' eth0

# Load conf
#RUN $CNT_NM "rm /etc/config/network"
#RUN $CNT_NM "cp $USR_HOME/PROV/network /etc/config/"
#RUN $CNT_NM "reload_config"

# Restart all services
#RUN $CNT_NM 'for S in /etc/init.d/* ; do $S enabled && $S start; done'
RUN $CNT_NM 'for sct in $(find /etc/rc.d -name 'S*') ; do $sct start;done'
#RUN $CNT_NM 'for sct in $(find /etc/rc.d -name 'S*') ; do $sct start;done'
# Test tools and conf
#RUN $CNT_NM 'udhcpc -i p_hzt'
#RUN $CNT_NM 'opkg update'
#RUN $CNT_NM 'opkg install nano strace gdb'
#RUN $CNT_NM 'ubusd&'
#RUN $CNT_NM '/etc/init.d/uhttpd start'
#RUN $CNT_NM 'source /etc/profile;sh'

    #docker exec -it VRouter sh -c 'source /etc/profile;sh'
#SHELL
