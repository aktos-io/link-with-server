#!/bin/bash
set -eu -o pipefail
set_dir(){ _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; }; set_dir
safe_source () { source $1; set_dir; }
# end of bash boilerplate

echo "Killing link-with-server"
killall link-with-server.sh
sleep 2
echo "restarting link-with-server"
$_dir/link-with-server.sh
