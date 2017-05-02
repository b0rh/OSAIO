#!/bin/bash

# b0rh <francisco@garnelo.eu>
# https://github.com/b0rh/gitolite-scripts/

# Remember to add non-root user to docker and add all packages.
# Relogin to apply new permission, if you don't it docker fails.
# sudo /usr/sbin/usermod -aG docker <non-root user>

# Common functions
source ../LIB/libSDN.sh
source ../LIB/libCommon.sh

# Image conf
BASE_VER='newton'
BASE_NAME='osaio'
PROJ_NAME='mysite'

# Container conf
CNT_TP='centos-jail:7.3.1611' # Container distro
CNT_NM='osaio' # Container name
#CNT_TP="$PROJ_NAME/$BASE_NAME:$BASE_VER" # Container distro
CNT_TG='os' # container tag
CNT_PV="PROV" # Container provisioning directory

CNT_storage_path='/changeME/VOLS/NFS-cinder-storage'

ECHO_TLT "      SETTING VIRTUAL SYSTEMS &  VIRTUAL NETWORKS"

# Enable commands echo
#set -x

check_services_status "docker.service openvswitch.service"

#sudo ifconfig docker0 down


ECHO_MSG "Creating docker container ..."

# Create/reCreate osaio base image from Dockerfile
#docker build -t $CNT_TP .


mkdir -p $CNT_storage_path
# Run docker container
docker create --privileged \
            --cap-add=ALL  \
            -e "container=docker" \
            -e "TERM=xterm-256color" \
            --net='none' \
            --dns=74.82.42.42\
            --hostname ${CNT_NM}.dck.mysite \
            --name $CNT_NM \
            -v /sys/fs/cgroup:/sys/fs/cgroup \
            -v /lib/modules:/lib/modules \
            -v /dev/log:/dev/log\
            -v $CNT_storage_path:/NFS-cinder-storage \
            $CNT_TP \
            /usr/sbin/init

docker start $CNT_NM 


ECHO_TLT "  Conectivity configurations:"

# Deploy VRouter
../VRouter/deploy.sh

#ECHO_MSG "Creating OVS bridges (virtual networks, vn) ..."
## Creates bridges
add_bridge 'ext' '192.168.1.254/24'
add_bridge 'int' '10.10.1.254/24'


ECHO_MSG "Assigning OVS bridges port(s) to ${CNT_NM} container ..."

# Creates and attachs veth to bridges
add_bridge_port 'ext' $(add_veth $CNT_NM $CNT_TG ext)
add_bridge_port 'int' $(add_veth $CNT_NM $CNT_TG int)





ECHO_TLT "   Tunning host kernel"
ECHO_MSG " Enable ip fordwarding, netfilter in bridge and tunning keepalive in host-POC."

sudo modprobe br_netfilter bridge

addreplace_conf /etc/sysctl.conf net.ipv4.ip_forward = 1
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_keepalive_intvl = 1
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_keepalive_time = 5
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_keepalive_probes = 5
addreplace_conf /etc/sysctl.conf net.bridge.bridge-nf-call-ip6tables = 1
addreplace_conf /etc/sysctl.conf net.bridge.bridge-nf-call-iptables = 1
addreplace_conf /etc/sysctl.conf net.bridge.bridge-nf-call-arptables = 1

# From /usr/share/openstack-puppet/modules/packstack/manifests/amqp.pp

addreplace_conf /etc/sysctl.conf net.ipv4.tcp_keepalive_intvl = 1
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_keepalive_time = 5
addreplace_conf /etc/sysctl.conf net.ipv4.tcp_keepalive_probes = 5


# From /usr/share/openstack-puppet/modules/packstack/manifests/neutron/bridge.pp

addreplace_conf /etc/sysctl.conf net.bridge.bridge-nf-call-ip6tables = 1
addreplace_conf /etc/sysctl.conf net.bridge.bridge-nf-call-iptables = 1
addreplace_conf /etc/sysctl.conf net.bridge.bridge-nf-call-arptables = 1

sysctl -p

ECHO_TLT "  Openstack all in one ($CNT_NM) container configurations:"

RUN $CNT_NM 'ifconfig e_ext 192.168.1.10/24'
#RUN $CNT_NM 'ifconfig e_ext inet6 add fc00:501:ffff:100::1/64'
RUN $CNT_NM 'ifconfig e_int 10.10.1.10/24'

# TODO: add outside IPv6 gateway
RUN $CNT_NM 'route add default gw 192.168.1.1 dev e_ext'

ECHO_MSG " Coping provisioning to Openstack container..."

chmod +x ./$CNT_PV/setup.sh
docker cp ./$CNT_PV $CNT_NM:/root
docker cp /proc/sys/net/bridge/ $CNT_NM:/root/$CNT_PV


ECHO_MSG " Executing setup.sh into container..."
RUN $CNT_NM './setup.sh' "/root/$CNT_PV/"


ECHO_TLT "                            DONE"
