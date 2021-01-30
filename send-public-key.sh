#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

show_help(){
    cat <<HELP

    $(basename $0) [options] 

    Options:

        --only-show      : Display the public key.
        --over-sprunge   : Upload public key to sprunge.com 
                           and display the share link.

HELP
}

die(){
    >&2 echo
    >&2 echo "$@"
    exit 1
}

help_die(){
    >&2 echo
    >&2 echo "$@"
    show_help
    exit 1
}

config="$_sdir/config.sh"
[[ -f "$config" ]] || die "ERROR: No configuration file ($config) found."

source "$config"

# Parse command line arguments
# ---------------------------
# Initialize parameters
action_taken=false
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
        --only-show)
            cat ${SSH_KEY_FILE}.pub
            action_taken=true
            ;;
        --over-sprunge)
            cat ${SSH_KEY_FILE}.pub | curl -F 'sprunge=<-' http://sprunge.us
            action_taken=true
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
    [[ -z ${1:-} ]] && break || shift
done; set -- "${args_backup[@]}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  

$action_taken || { show_help && exit; }

cat <<EOL

    Deliver your public key to the LINK_UP_SERVER and 
    add it into "/home/lws/your-authorized-keys-file".

EOL

