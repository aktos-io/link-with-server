#!/bin/bash
# Author : Cerem Cem ASLAN cem@aktos.io
# Date   : 30.05.2014
set -u -o pipefail
set_dir(){ _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; }; set_dir
safe_source () { source $1; set_dir; }
# end of bash boilerplate

# Strategy
# 1. Connect to server
# 2. Create a reverse port forward to put localhost:22 to server:$LUP
# 3. Create a local port forward to get back server:$LUP to localhost:2222
# 4. get host finger print of port 22 and port 2222, if they are equal, tunnel
#    is working

safe_source $_dir/config.sh || die "Required config file (./config.sh)"
ORIG_LINK_UP_PORT=$LINK_UP_SSHD_PORT

safe_source $_dir/aktos-bash-lib/basic-functions.sh
safe_source $_dir/aktos-bash-lib/ssh-functions.sh

get_host_fingerprint(){
    local host=$1
    local port=${2:-22}
    local file=$(mktemp)
    timeout 10 ssh-keyscan -p $port $host 2> /dev/null > $file
    ssh-keygen -l -f $file 2> /dev/null | grep ECDSA | awk '{print $2}'
}

SSH="$SSH -q -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null \
    -oPreferredAuthentications=publickey $SSH_USER@$SSH_HOST -p $SSH_PORT -i $SSH_KEY_FILE"

ssh_run_cmd(){
    $SSH $@
}

on_connect_scripts_dir=$_dir/on/connect
on_disconnect_scripts_dir=$_dir/on/disconnect

run_event_scripts () {
    local search_dir=$1
    while IFS= read -r file; do
        echo_green $(echo_stamp "running event script: ${file#"$_dir/"}")
        safe_source $file
    done < <(find $search_dir -type f -iname "*.sh")
}

link_pid=
create_link () {
    if [[ ! -z $link_pid ]]; then
        echo "Killing previous link pid: $link_pid"
        kill $link_pid 2> /dev/null
        [[ $? -gt 0 ]] && echo "...killed already?"
    fi
    $SSH -N                                     \
        -R $LINK_UP_SSHD_PORT:localhost:22      \
        -L 2222:localhost:$LINK_UP_SSHD_PORT &  # for echo purposes
    link_pid=$!
}


is_port_forward_working () {
    # maybe we could try something like `ssh localhost -p 2222 exit 0`
    # in the future
    local proxied=$(get_host_fingerprint 127.0.0.1 2222)
    local orig=$(get_host_fingerprint 127.0.0.1 22)

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

cleanup () {
    echo_stamp "cleaning up..."
    if [ $link_pid ]; then
        echo "SSH pid found ($link_pid), killing."
        kill $link_pid 2> /dev/null
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
        local msg="Yes, I can directly make SSH connection to this machine"
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

connected=false
while :; do
    run_event_scripts $on_connect_scripts_dir
    echo_stamp "creating link 22 -> $LINK_UP_SSHD_PORT"
    create_link
    i=0
    while :; do
        if ! is_port_forward_working; then
            if [[ $connected == true ]]; then
                echo_stamp "connection is broken now."
                break
            else
                echo_stamp "seems not working ($i)..."
                i=$((i + 1))
                [[ $i -gt 5 ]] && break
            fi
        else
            if [[ $connected == false ]]; then
                echo_stamp "waiting for tunnel to break..."
            fi
            connected=true
            i=0
        fi
        sleep 5
    done
    connected=false
    [[ $shutting_down == true ]] && sleep 2m
    echo_stamp "tunnel seems broken. cleaning up."
    run_event_scripts $on_disconnect_scripts_dir
    reconnect_delay=3
    echo_stamp "reconnecting in $reconnect_delay seconds..."
    shutting_down=false
    sleep $reconnect_delay
done
