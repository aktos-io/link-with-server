#!/bin/bash
# Author : Cerem Cem ASLAN cem@aktos.io
# Date   : 30.05.2014

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }; set_dir
safe_source () { source $1 2> /dev/null; x=$?; set_dir; return $x; }

safe_source $DIR/config.sh || die "Required config file (./config.sh)"
safe_source $DIR/aktos-bash-lib/basic-functions.sh
safe_source $DIR/aktos-bash-lib/ssh-functions.sh
safe_source $DIR/app-lib.sh


ssh_pid=
start_connection () {
    # DONT USE -f OPTION, $ssh_pid is changing after a few seconds otherwise.
    $SSH $SSH_USER@$SSH_HOST -p $SSH_PORT -i $SSH_KEY_FILE -N -M -S $SSH_SOCKET_FILE \
        -L 2223:localhost:22 &
    ssh_pid=$!
}

create_link () {
    ssh_socket_make_forward -R $RENDEZVOUS_SSHD_PORT:localhost:22 \
        -L 2222:localhost:$RENDEZVOUS_SSHD_PORT
}

is_sshd_heartbeating () {
    local host=$1
    local port=$2
    local replay="$(echo | timeout 10 nc $host $port 2> /dev/null)"
    if [[ "$replay" != "" ]]; then
        return 0
    else
        return 1
    fi
}

is_port_forward_working () {
    # maybe we could try something like `ssh localhost -p 2222 exit 0`
    # in the future
    local nc_timeout=10
    local proxied=$(echo | timeout $nc_timeout nc localhost 2222 2> /dev/null)
    local orig=$(echo | timeout $nc_timeout nc localhost 22 2> /dev/null)

    #echo "proxied: $proxied, orig: $orig"
    if [[ "$proxied" == "" ]]; then
        #echo "no answer, tunnel is broken."
        return 55
    else
        if [[ "$proxied" == "$orig" ]]; then
            #echo "tunnel is working."
            return 0
        else
            #echo "ssh server responses differs!"
            return 1
        fi
    fi
}

reconnect () {
    start_connection
    echo -n $(echo_stamp "starting connection (pid: $ssh_pid)")
    for max_retry in {60..1}; do
        if ! is_sshd_heartbeating localhost 2223; then
            #echo_yellow "!! Broken port forward !! retry: $max_retry"
            echo -n "."
        else
            echo
            echo_green $(echo_stamp "Connection is working")
            return 0
        fi
        sleep 1s
    done
    return 1
}

cleanup () {
    echo_stamp "cleaning up..."
    if [ $ssh_pid ]; then
        #echo "SSH pid found ($ssh_pid), killing."
        kill $ssh_pid 2> /dev/null
    fi
}


# ------------------------- APPLICATION --------------------------------- #

trap cleanup EXIT

echo_green "using socket file: $SSH_SOCKET_FILE"
while :; do
    reconnect

    while IFS= read -r file; do
        echo_green $(echo_stamp "running: ${file#"$DIR/"}")
        safe_source $file
    done < <(find $DIR/on/pre-create-link/ -type f)

    echo_stamp "creating link 22 -> $RENDEZVOUS_SSHD_PORT"
    create_link
    if [ $? == 0 ]; then
        echo_stamp "waiting for tunnel to break..."
        # run "on-connection" scripts here
        while IFS= read -r file; do
            echo_green $(echo_stamp "running: ${file#"$DIR/"}")
            safe_source $file
        done < <(find $DIR/on/post-create-link/ -type f)
    else
        echo_stamp "....unable to create a tunnel."
    fi
    while :; do
        if ! is_port_forward_working; then
            break
        fi
        sleep 5
    done
    echo_stamp "tunnel seems broken. cleaning up."
    cleanup
    while IFS= read -r file; do
        echo_yellow $(echo_stamp "running: ${file#"$DIR/"}")
        safe_source $file
    done < <(find $DIR/on/disconnect/ -type f)
    reconnect_delay=2
    echo_stamp "reconnecting in $reconnect_delay seconds..."
    sleep $reconnect_delay
done
