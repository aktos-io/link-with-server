#!/bin/bash

get_port_pid () {
    local port=$1
    lsof -t -i :$port
}

port=7100
i=0
while :; do 
  #echo "checking process for port $port"
  pid=$(get_port_pid $port)
  if [[ $pid != "" ]]; then     
    #echo "checking if port is responding...$((i++))"
    timeout 60 ssh-keyscan -p $port localhost > /dev/null 2>&1
    if [[ $? != 0 ]]; then 
      echo "can not connect to $port, killing the process (pid: $pid)"
      kill $pid
      echo "killed."
    else
      echo "...port works OK (pid: $pid) heartbeat: $((i++))"
    fi 
  else 
    echo "@@@ no process listening port: $port"
  fi 
  sleep 2
done

