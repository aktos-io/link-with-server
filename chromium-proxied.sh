#!/bin/bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

set -u
[[ -z ${1:-} ]] && { echo "Usage: $(basename $0) SOCKS_PROXY_PORT [--auto] [chromium options]"; exit 1; }
proxy_port=$1
shift

auto_proxy=${1:-}
proxy_pid=
if [[ "$auto_proxy" == "--auto" ]]; then
    shift
    # create proxy connection automatically
    $_sdir/create-socks5.sh $proxy_port &
    proxy_pid=$!
fi

cleanup(){
    echo "Cleaning up..."
    if [[ -n $proxy_pid ]]; then
        echo "Killing proxy connection"
        kill $proxy_pid
    fi
    echo "Done."
}

trap 'cleanup' EXIT INT

data_dir="$HOME/.config/chromium-proxied"

LANGUAGE=en chromium --user-data-dir="$data_dir" \
    --no-first-run \
    --no-default-browser-check  \
    --password-store=basic \
    --proxy-server="socks5://127.0.0.1:${proxy_port}" \
    --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE 127.0.0.1" \
    --lang="en-US" \
    $@

