Scripts in these folders will be sourced upon appropriate event. 

You can safely delete every script in this folders. In this case, `link-with-server` will use `config.sh` and create only rendezvous port link.

# Examples: 

Example `post-create-link` script that forwards port 4008 to localhost:14008: 

    echo_stamp "forwarding scada port: R:4008 -> L:14008 "
    ssh_socket_make_forward -L 14008:localhost:4008

Example `disconnect` script that logs every disconnec event: 

    echo_stamp "disconnected." >> disconnect.log

Example `pre-create-link` script that fetces rendezvous port setting: 

    public_key=$(get_public_key $SSH_KEY_FILE)
    curr_fingerprint=$(get_fingerprint $public_key)

    echo_stamp "Getting rendezvous port."
    rendezvous_port=$(ssh_socket_run_cmd $curr_fingerprint)

    if [[ $rendezvous_port ]]; then
        echo_stamp "Received rendezvous port setting: $rendezvous_port"
        RENDEZVOUS_SSHD_PORT=$rendezvous_port
    else
         echo_stamp "Using rendezvous port in config file: $RENDEZVOUS_SSHD_PORT"
    fi


