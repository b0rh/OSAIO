# b0rh <francisco@garnelo.eu>
# https://github.com/b0rh/gitolite-scripts/

# TODO: local variables in functions
#       Check existence functions



function rm_netns {

    _cnt_nm=$1
    _cnt_pid=$(docker inspect --format='{{ .State.Pid }}' "$_cnt_nm")

    sudo ip netns del $_cnt_pid
}

function rm_macvlan {
#   $1 --> Container name
#   $2 --> Ethernet name into the container

    _cnt_nm=$1
    _C_eth_lst=$2 # Container device list names without p_
    _cnt_pid=$(docker inspect --format='{{ .State.Pid }}' "$_cnt_nm")

    for _C_eth in $_C_eth_lst; do
        sudo ip netns exec $_cnt_pid ip link delete "p_$_C_eth" up
    done
}

function rm_veth {

    _cnt_nm=$1
    _tag_nm=$2 # Tag name
    _C_eth_lst="$3" # Container dev name without e_

    for _C_eth in $_C_eth_lst; do
        _H_veth="veh_"$_tag_nm"_e_"$_C_eth # Host netns device
        sudo ip link delete $_H_veth
    done
}

function add_macvlan {
# Manage network namespaces at low level, to create and assign a
# bridge between a physical device to a running container virtual devices.


#   $1 --> Container name
#   $2 --> Ethernet name into the container
#   $3 --> Container device mac address
#   $4 --> Host Ethernet to bridge

    _cnt_nm=$1
    _cnt_pid=$(docker inspect --format='{{ .State.Pid }}' "$_cnt_nm")
    _C_eth="p_$2" # Container device name
    _C_mac=$3 # Container device mac address
    _H_eth=$4 # Host device name


    sudo ip link add $_C_eth link $_H_eth type macvlan mode bridge

    # Links and setups veth to container
    if [ ! -d "/var/run/netns" ]; then
        sudo mkdir -p "/var/run/netns"
    fi

    if [ ! -L "/var/run/netns/"$_cnt_pid ]; then
    sudo ln -s /proc/${_cnt_pid}/ns/net "/var/run/netns/"$_cnt_pid
    fi

    sudo ip link set $_C_eth netns ${_cnt_pid}

    # Set up the interface into container and configures custom mac
    #sudo ip netns exec $_cnt_pid ip link set dev $_C_eth down
    sudo ip netns exec $_cnt_pid ip link set dev $_C_eth address $_C_mac
    sudo ip netns exec $_cnt_pid ip link set dev $_C_eth up

}


function add_veth {
# Manage network namespaces at low level, to create and assign a
# veth to a running container, mapping it also in a host device.

# This function allows using L2/L3 host features such as openvswitch
# and other network manipulations not supported by docker.

#   $1 --> Container name
#   $2 --> Ethernet name into the container
#   $3 --> Tag name
    _cnt_nm=$1
    _tag_nm=$2 # Tag name
    _cnt_pid=$(docker inspect --format='{{ .State.Pid }}' "$_cnt_nm")
    _C_eth="e_$3" # Container dev name
    # Host dev name, virtual ethernet host format:
    # veh_<tag name>_<container dev name>
    _H_veth="veh_"$_tag_nm"_"$_C_eth # Host netns device
    _C_veth="vec_"$_tag_nm"_"$_C_eth # Container temporal dev name


    #echo " Adding nic $_C_eth in container $_cnt_nm as veth $_H_veth ..."
    # Veth creation
    sudo ip link add $_H_veth type veth peer name $_C_veth
    sudo ip link set dev $_H_veth up

    # Links and setups veth to container
    if [ ! -d "/var/run/netns" ]; then
        sudo mkdir -p "/var/run/netns"
    fi

    if [ ! -L "/var/run/netns/"$_cnt_pid ]; then
    sudo ln -s /proc/${_cnt_pid}/ns/net "/var/run/netns/"$_cnt_pid
    fi

    sudo ip link set $_C_veth netns ${_cnt_pid}

    # Change container veth name, I cannont use in first instance
    # due to conflicts with host ethernet names
    sudo ip netns exec $_cnt_pid ip link set dev $_C_veth name $_C_eth
    sudo ip netns exec $_cnt_pid ip link set dev $_C_eth up

    # Return new veth host system name
    echo $_H_veth
}


function rm_bridge {
# This function removes a bridge or bridges from a list

    _bridge_lst=$1 # Virtual network's list
    for br_nm in $_bridge_lst; do
        sudo ip link set dev  "vn_$br_nm" down
        sudo ovs-vsctl del-br "vn_$br_nm"
    done
}

function add_bridge {
# This function creates a bridge and set his IP address

    _bridge_nm="vn_$1" # Virtual network name
    _ip_addr=$2
    sudo ovs-vsctl add-br $_bridge_nm
    sudo ip link set dev  $_bridge_nm up
    sudo ip addr add dev $_bridge_nm $_ip_addr

}

function add_bridge_port {
# Thist function add a port or ports list to a bridge
    _bridge_nm=$1 # Bridge name without vn_
    _port_lst=$2
    for port_nm in $_port_lst; do
        sudo ovs-vsctl add-port vn_$_bridge_nm $port_nm
    done


}


function rm_bridge_port {
# Thist function remove a port or ports list to a bridge
    _bridge_nm=$1 # Bridge name without vn_
    _port_lst=$2
    for port_nm in $_port_lst; do
        sudo ovs-vsctl del-port vn_$_bridge_nm $port_nm
    done


}
