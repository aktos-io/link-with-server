echo_stamp "forwarding 4008 as scada port"
ssh_run_via_socket -L 14008:localhost:4008
