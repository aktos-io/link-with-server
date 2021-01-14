#!/bin/bash
set -eu
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

exe="$_sdir/link-with-server.sh"
name=$(echo $(basename $exe) | sed "s/\..*//")

[[ $(whoami) = "root" ]] || { sudo $0 "$@"; exit 0; }

service_file="/etc/systemd/system/$name.service"
echo "Installing service file in $service_file"
echo "----------------------------------------"
cat << EOL | tee $service_file
[Unit]
Description=Startup services
After=systemd-networkd-wait-online.service
Wants=systemd-networkd-wait-online.service

[Service]
Type=simple
ExecStart=$(realpath $exe)
User=$SUDO_USER

[Install]
WantedBy=multi-user.target

EOL
echo "----------------------------------------"

chmod 644 $service_file

cat << EOL

To start service:

	sudo systemctl start $name

Enable on every boot:

	sudo systemctl enable $name

EOL

