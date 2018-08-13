#!/bin/bash
set -u -o pipefail
set_dir(){ _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; }; set_dir
safe_source () { source $1; set_dir; }
# end of bash boilerplate

if [[ -z ${TMUX:-} ]]; then
    echo "Not inside a TMUX session, won't continue"
    exit 1
fi

echo "Killing link-with-server"
killall link-with-server.sh > /dev/null 
sleep 2
echo "restarting link-with-server"
exec $_dir/link-with-server.sh 
