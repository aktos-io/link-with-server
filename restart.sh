#!/bin/bash
set -u -o pipefail
set_dir(){ _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; }; set_dir
safe_source () { source $1; set_dir; }
# end of bash boilerplate

if [[ -z ${TMUX:-} ]]; then
    # if we are not in a TMUX session, then dropping our connection
    # will also kill this script, so link-with-server will be never 
    # restarted. 
    # Simply refuse running this script unless we are in a TMUX session. 
    echo "Not inside a TMUX session, $0 won't operate."
    exit 1
fi


ignore_sigint(){
    local timeout=20
    echo "--------------------------------------"
    echo "WARNING: IGNORING SIGINT IN restart.sh"
    echo "If you want to stop the process, use the"
    echo "command in $timeout seconds:"
    echo "kill $$"
    echo "--------------------------------------"
    sleep $timeout
}

trap ignore_sigint SIGINT

echo "Killing link-with-server"
pkill link-with-server.sh > /dev/null 
sleep 2
echo "restarting link-with-server"
exec $_dir/link-with-server.sh 
