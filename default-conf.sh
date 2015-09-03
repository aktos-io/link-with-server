# 1. create a user (PROXY_USERNAME) on PROXY_HOST
# 2. reserve MOBMAC_SSHD_PORT_ON_PROXY

proxy_settings() {
	PROXY_USERNAME="mobmac_user"
	PROXY_HOST="aktos-elektronik.com"
	PROXY_SSHD_PORT=443
}

mobmac_settings() {
	MOBMAC_ID="$(get_ssh_id_fingerprint)"
	MOBMAC_SSHD_PORT_ON_PROXY="$(get_mobmac_sshd_port_on_proxy $MOBMAC_ID)"
	MOBMAC_SSHD_PORT=$(get_mobmac_sshd_port)
}




