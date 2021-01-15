#!/bin/bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

show_help(){
    cat <<HELP

    $(basename $0) [options] -t PORT -u USER [-c [commands]]

    Reconnects if connection drops. (Requires Tmux on the remote side.)

    Options:

        -t TARGET_PORT       : Target's SSHD port on rendezvous (link up) server.
        -u USER              : Username to use while logging in to the target.
        -c, --cmd [commands] : Do not reconnect, make a simple connection.
        -k, --known-hosts    : Path to known_hosts file.

HELP
}

die(){
    echo
    echo "$@"
    show_help
    exit 1
}

config="$_sdir/config.sh"
[[ -f "$config" ]] || die "No configuration found."
source "$config"

# Parse command line arguments
# ---------------------------
# Initialize parameters
target_user=
target_port=
reconnect=true
known_hosts_file=
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
        -u) shift
            target_user="$1"
            ;;
        -t) shift
            target_port="$1"
            ;;
        -c|--cmd)
            reconnect=false
            ;;
        -k|--known-hosts) shift
            known_hosts_file=$1
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

[[ -z "$target_user" ]] && die "Target user missing."
[[ -z "$target_port" ]] && die "Target port missing."


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

Host target
    Hostname localhost
    Port $target_port
    User $target_user
    ProxyJump LINK_UP_SERVER
EOF
`

ssh_jump(){
    ssh -F $tmpfile target "$@"
}

if ! $reconnect; then
    # simple connection
    ssh_jump "$args"
else
    # with auto reconnect
    if [ ${#args[@]} -gt 0 ]; then
        echo "Warning: Discarding commands: ${args[@]}"
        sleep 1
    fi
    while sleep 1; do 
        ssh_jump -t 'tmux a || tmux; bash --login' && break
        echo "Reconnecting in 1 second."
    done
fi