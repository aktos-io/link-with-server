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
    lsof -t -i :$port
}

i=0
while :; do 
  #echo "checking process for port $port"
  pid=$(get_port_pid $port)
  if [[ $pid != "" ]]; then     
    #echo "checking if port is responding...$((i++))"

    sshd_heartbeat=$(echo | timeout 10 nc localhost $port 2> /dev/null)
    if [[ "$sshd_heartbeat" == "" ]]; then 
      echo "can not connect to $port, killing the process (pid: $pid)"
      kill $pid
      echo "killed."
    else
      echo "...port $port works OK (pid: $pid) heartbeat: $((i++))"
    fi 
  else 
    echo "@@@ no process listening port: $port"
  fi 
  sleep 2
done

