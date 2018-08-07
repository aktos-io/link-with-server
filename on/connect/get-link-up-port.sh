public_key=$(get_public_key $SSH_KEY_FILE)
curr_fingerprint=$(get_fingerprint $public_key)

echo_stamp "Asking link up port for: $curr_fingerprint"
link_up_port=$(ssh_run_cmd $curr_fingerprint)

if [[ $link_up_port =~ ^[0-9]+$ ]] ; then # if number
    echo_stamp "Received link up port setting: $link_up_port"
    LINK_UP_SSHD_PORT=$link_up_port
else
    LINK_UP_SSHD_PORT=$ORIG_LINK_UP_PORT
    echo_yellow $(echo_stamp "Using link up port in config file: $LINK_UP_SSHD_PORT")
fi
