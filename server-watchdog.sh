#!/bin/bash

port=$1


show_usage () {
    cat <<HELP

	usage: sudo $(basename $0) PORT

HELP
    exit
}

[ $port ] || show_usage

get_port_pid () {
    local port=$1
    #lsof -t -i :$port
    netstat -anp | grep :$port | grep -i listen | grep "^tcp " | awk '{print $7}' | cut -d/ -f1
}

connected=
connected0=
first_run=true
while :; do
  #echo "checking process for port $port"
  pid=$(get_port_pid $port)
  if [[ $pid != "" ]]; then     
    sshd_heartbeat=$(echo | timeout 10 nc localhost $port 2> /dev/null)
    if [[ "$sshd_heartbeat" == "" ]]; then 
      echo "port $port is not responding, killing its process (pid: $pid)"
      kill $pid
      connected=
    else
      connected=true
      if [ ! $connected0 ] && [ $connected ]; then
	 echo "...port $port works OK (pid: $pid)"
      fi
    fi 
  else 
    connected=
    if [ $connected0 ] && [ ! $connected ]; then
      echo "@@@ no process listening port: $port"
    fi
    if [[ $first_run ]]; then 
      echo "First report: no process listening port $port"
    fi
  fi 
  sleep 2
  connected0=$connected
  first_run=
done

