#!/bin/bash
# Author : Cerem Cem ASLAN cem@aktos.io
# Date   : 30.05.2014

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }; set_dir
safe_source () { source $1 2> /dev/null; x=$?; set_dir; return $x; }

safe_source $DIR/config.sh || die "Required config file (./config.sh)"
ORIG_LINK_UP_PORT=$LINK_UP_SSHD_PORT

safe_source $DIR/aktos-bash-lib/basic-functions.sh
safe_source $DIR/aktos-bash-lib/ssh-functions.sh


SSH="$SSH -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oPreferredAuthentications=publickey"

on_connect_scripts_dir=$DIR/on/connect
on_disconnect_scripts_dir=$DIR/on/disconnect

run_event_scripts () {
    local search_dir=$1
    while IFS= read -r file; do
        echo_green $(echo_stamp "running event script: ${file#"$DIR/"}")
        safe_source $file
    done < <(find $search_dir -type f -iname "*.sh")
}

ssh_pid=
start_connection () {
    # DONT USE -f OPTION, $ssh_pid is changing after a few seconds otherwise.
    $SSH $SSH_USER@$SSH_HOST -p $SSH_PORT -i $SSH_KEY_FILE -N -M -S $SSH_SOCKET_FILE \
        -L 2223:localhost:22 &
    ssh_pid=$!
}

create_link () {
    ssh_socket_make_forward -R $LINK_UP_SSHD_PORT:localhost:22 \
        -L 2222:localhost:$LINK_UP_SSHD_PORT
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

shutting_down=false

reconnect () {
    start_connection
    echo -n $(echo_stamp "starting connection (pid: $ssh_pid)")
    for max_retry in {60..1}; do
        if ! is_sshd_heartbeating localhost 2223; then
            #echo_yellow "!! Broken port forward !! retry: $max_retry"
            [[ $shutting_down == true ]] || >&2 echo -e -n "."
        else
            echo
            echo_green $(echo_stamp "Connection is working")
            shutting_down=false
            connected=true
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
sure_exit () {
    if [[ $connected != true  ]]; then
        echo_yellow "Never connected yet, shutting down immediately."
        kill $$
    fi
    shutting_down=true
    {
    if prompt_yes_no "Do you want to shut down this service?"; then
        local msg="Yes, I have physical access to this machine"
        read -p "Type \"$msg\" : " reply
        if [[ "$msg" == "$reply" ]]; then
            echo_red "Okay, you really wanted this."
            kill $$
        else
            echo "reply: $reply"
            echo_yellow "You typed wrongly. Try stopping again."
        fi
    else
        echo_green $(echo_stamp "I thought so.")
    fi
    } &
}


trap sure_exit SIGINT
trap cleanup EXIT

echo_green "using socket file: $SSH_SOCKET_FILE"
while :; do
    reconnect
    run_event_scripts $on_connect_scripts_dir
    echo_stamp "creating link 22 -> $LINK_UP_SSHD_PORT"
    create_link
    if [ $? == 0 ]; then
        echo_stamp "waiting for tunnel to break..."
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
    run_event_scripts $on_disconnect_scripts_dir

    reconnect_delay=2
    echo_stamp "reconnecting in $reconnect_delay seconds..."
    shutting_down=false
    sleep $reconnect_delay
done
