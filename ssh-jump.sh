#!/bin/bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

show_help(){
    cat <<HELP

    $(basename $0) [options] -t PORT [-u USER] [-- [commands]]

    Reconnects if connection drops. (Requires Tmux on the remote side.)

    Options:

        -t TARGET_PORT          : Target's SSHD port on rendezvous server.
        -u USER                 : Username on the target. Defaults to \$USER
        -k, --known-hosts FILE  : Path to known_hosts file.
        -n, --no-reconnect      : Do not try to reconnect
        -- [commands]           : Use custom commands instead of a Tmux session.
        -c, --config FILE       : Alternative config file (default: ./config.sh)

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
target_user=$USER
target_port=
reconnect=true
no_reconnect=false
known_hosts_file=
cmd=()
default_cmd=true
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
        -u) shift
            target_user="$1"
            ;;
        -t) shift
            target_port="$1"
            ;;
        --) shift
            cmd=("$@")
            reconnect=false
            default_cmd=false
            break
            ;;
        -n|--no-reconnect)
            no_reconnect=true
            ;;
        -k|--known-hosts) shift
            known_hosts_file=$1
            ;;
        -c|--config) shift 
            config="$1"
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
    ssh $SSH_OPTS -F $tmpfile target "$@"
}

if $default_cmd; then
    cmd+=("-t")
    cmd+=('tmux a || tmux; bash --login')
fi

period=0
while sleep $period; do 
    ssh_jump ${cmd[@]} && break
    $no_reconnect && break
    period=1
    echo "Reconnecting in ${period}s."
done