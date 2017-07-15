generate_ssh_id () {
	# usage:
	#   generate_ssh_id /path/to/ssh_id_file
	local SSH_ID_FILE=$1
	local SSH_ID_DIR=$(dirname "$SSH_ID_FILE")

	#debug
	#echo "SSH ID FILE: $SSH_ID_FILE"
	#echo "DIRNAME: $SSH_ID_DIR"
	#exit

	if [ ! -f "$SSH_ID_FILE" ]; then
		echolog "Generating SSH ID Key..."
		mkdir -p "$SSH_ID_DIR"
		ssh-keygen -N "" -f "$SSH_ID_FILE"
	else
		echolog "SSH ID Key exists, continue..."
	fi
}


get_ssh_id_fingerprint() {
  local FINGERPRINT="$(ssh-keygen -E md5 -lf "$SSH_ID_FILE" 2> /dev/null | awk '{print $2}' | sed 's/^MD5:\(.*\)$/\1/')"
  if [[ "$FINGERPRINT" == "" ]]; then
    FINGERPRINT="$(ssh-keygen -lf "$SSH_ID_FILE" | awk '{print $2}')"
  fi
  echo $FINGERPRINT
}
