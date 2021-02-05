#!/bin/bash

_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

show_help(){
    cat <<HELP

    $(basename $0) [options] PORT

    Creates Socks5 proxy on PORT.

    Options:

        -k, --known-hosts    : Path to known_hosts file.
        -c, --config FILE    : Config file. Default: ./config.sh

HELP
}

die(){
    echo
    echo "$@"
    show_help
    exit 1
}

SSH_OPTS="-o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o AddressFamily=inet"

# Parse command line arguments
# ---------------------------
# Initialize parameters
proxy_port=
known_hosts=
config="$_sdir/config.sh"
# ---------------------------
args_backup=("$@")
args=()
_count=1
while [ $# -gt 0 ]; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        -k|--known-hosts) shift
            known_hosts_file="--known-hosts $1"
            ;;
        -c|--config) shift
            config=$(realpath $1)
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            die "Unknown option: $1"
            ;;
        *)  # Generate the new positional arguments: $arg1, $arg2, ... and ${args[@]}
            if [[ ! -z ${1:-} ]]; then
                declare arg$((_count++))="$1"
                args+=("$1")
            fi
            ;;
    esac
    shift
    [[ -z ${1:-} ]] && break
done; set -- "${args_backup[@]}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  

[[ -f "$config" ]] || die "No configuration found."
source "$config"

proxy_port=${arg1:-}
[[ -z $proxy_port ]] && die "Proxy port is required."

[[ -n $known_hosts_file ]] \
    && UserKnownHostsFile="UserKnownHostsFile $known_hosts_file" \
    || UserKnownHostsFile=""

tmpfile=$(mktemp /tmp/$(basename $0).XXXXXX)

cleanup(){
    rm $tmpfile
}
trap cleanup EXIT

ssh_config=`cat << EOF > $tmpfile
Host *
    $UserKnownHostsFile
    IdentityFile $SSH_KEY_FILE

Host LINK_UP_SERVER
    Hostname    $SSH_HOST
    Port        $SSH_PORT
    User        $SSH_USER
EOF
`

ssh_cmd(){
    ssh $SSH_OPTS -F $tmpfile LINK_UP_SERVER $@
}

period=0
while sleep $period; do 
    ssh_cmd -C2qTnN -D $proxy_port &
    sleep 1
    curr_ip=$(curl ifconfig.me -s)
    for i in `seq 10`; do
        new_ip=$(timeout 5 curl --socks5 localhost:$proxy_port ifconfig.me -s)
        [[ -n $new_ip ]] && break
        echo "Retrying to get an ip address."
        sleep 2
    done
    if [[ -n $new_ip && $curr_ip != $new_ip ]]; then 
        echo "Socks proxy is working. New ip is: $new_ip".
    fi
    wait
    period=1
    echo "Reconnecting in ${period}s."
done
