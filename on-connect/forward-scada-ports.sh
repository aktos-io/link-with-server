echo_stamp "forwarding REMOTE:4008 to LOCAL:14008 as scada port"
ssh_run_via_socket -L 14008:localhost:4008
