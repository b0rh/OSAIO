#!/bin/bash

# b0rh <francisco@garnelo.eu>
# https://github.com/b0rh/gitolite-scripts/

# Target
CNT_NM='osaio'
CNT_TG='os' # container tag

VETH_LS='int ext'
BRD_LS='int ext'

# Common functions
source ../LIB/libSDN.sh
source ../LIB/libCommon.sh


ECHO_TLT "                            CLEANING DEPLOY"

ECHO_MSG "Deleting virtual network  interfaces ..."
rm_veth $CNT_NM $CNT_TG "$VETH_LS"

ECHO_MSG "Deleting network namespace ..."
rm_netns $CNT_NM

ECHO_MSG "Removing ports in OVS bridges ..."
rm_bridge_port 'ext' "veh_${CNT_TG}_e_ext"
rm_bridge_port 'int' "veh_${CNT_TG}_e_int"

ECHO_MSG "Removing OVS bridges (virtual networks, vn) ..."
rm_bridge "$BRD_LS"

ECHO_MSG " Stoping container ..."
docker stop $CNT_NM

ECHO_MSG " Removing container ..."
docker rm $CNT_NM

ECHO_TLT "                            DONE"
