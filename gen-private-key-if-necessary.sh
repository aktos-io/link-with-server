#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

config="$_sdir/config.sh"
[[ -f "$config" ]] || { echo "ERROR: No configuration file ($config) found."; exit 1; }

source "$config"
[[ -f "$SSH_KEY_FILE" ]] && { echo "ERROR: SSH_KEY_FILE ($SSH_KEY_FILE) already exists."; exit 1; }

ssh-keygen -N '' -t rsa -b 4096 -C "$USER@$HOSTNAME" -f "$SSH_KEY_FILE"

