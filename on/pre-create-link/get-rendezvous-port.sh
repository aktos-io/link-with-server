public_key=$(get_public_key $SSH_KEY_FILE)
curr_fingerprint=$(get_fingerprint $public_key)

echo_stamp "Asking rendezvous port for: $curr_fingerprint"
rendezvous_port=$(ssh_socket_run_cmd $curr_fingerprint)

if [[ $rendezvous_port ]]; then
    echo_stamp "Received rendezvous port setting: $rendezvous_port"
    RENDEZVOUS_SSHD_PORT=$rendezvous_port
else
    echo_stamp "Using rendezvous port in config file: $RENDEZVOUS_SSHD_PORT"
fi
