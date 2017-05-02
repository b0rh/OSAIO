#TODO: Add color support

function addreplace_conf {
    local _filepath=$1
    local _varname=$2
    local _varset=$3
    local _varvalue=$4

    # Remove value
    sudo grep -v -e $_varname $_filepath > $_filepath.tmp
    sudo mv $_filepath.tmp $_filepath -f

    # Add new variable
    sudo echo "${_varname}${_varset}${_varvalue}" >> $_filepath
}

function check_services_status {
    #Checking services status
    _srv_lst=$1
    echo -n "Waiting for $_srv_lst service(s) ..."
     while :
        do
            for _srv in $_srv_lst ; do _srv_sta+=$(sudo systemctl status $_srv | grep inactive) ; done
            if [ -z "$_srv_sta" ]; then echo;break;fi
            _srv_sta=''
            for((i=0;i<=6;i++));do sleep 0.5;echo -n ".";done
        done

}

function SHELL {
    local _cnt_nm=$1
    RUN $_cnt_nm 'source /etc/profile;sh'
}

function RUN {
    local _cnt_nm=$1
    local _cmd=$2
    local _path=$3

    if ! [ -n "$_path" ]; then  #empty
        local _path='/tmp'
    fi


    docker exec -it $_cnt_nm sh -c "cd $(echo $_path); $(echo $_cmd);exit"
}


function ECHO_TLT {
    local _msg=$1

    echo
    echo "---------------------------------------------------------------------"
    echo "$_msg"
    echo "---------------------------------------------------------------------"
    echo

}

function ECHO_MSG {
    local _msg=$1

    echo
    echo "$_msg"
    echo

}

function GET_CNT_PID {
    local _cnt_nm

    echo $(docker inspect --format='{{ .State.Pid }}' "$_cnt_nm")

}
