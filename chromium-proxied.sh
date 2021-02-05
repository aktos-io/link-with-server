#!/bin/bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

set -u
[[ -z ${1:-} ]] && { echo "Usage: $(basename $0) SOCKS_PROXY_PORT [chromium options]"; exit 1; }
proxy_port=$1
shift

data_dir="/tmp/chromium-proxied"

cleanup(){
    echo "Removing $data_dir"
    rm -r "$data_dir"
}
trap cleanup EXIT

LANGUAGE=en chromium --user-data-dir="$data_dir" \
    --no-first-run \
    --no-default-browser-check  \
    --password-store=basic \
    --proxy-server="socks5://127.0.0.1:${proxy_port}" \
    --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE 127.0.0.1" \
    --lang="en-US" \
    $@
