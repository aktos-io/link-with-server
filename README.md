# Link With Server

Creates a link between the NODE and the LINK UP SERVER.

**WARNING** : `StrictHostKeyChecking` is disabled, you must get prepared for MITM attacks.


# Setup SSH Server on Server Side (for the first time)

1. Install OpenSSH server if not installed.
2. **Recommended**:
    1. Create a standard Unix user account (eg. `adduser lws`) to manage the connections.
    2. Add following section to `/etc/ssh/sshd_config` file:
        
            Match User lws
                    AllowTcpForwarding yes
                    PermitTunnel yes
                    ForceCommand /home/lws/handler.sh  
                    PasswordAuthentication no
                    AuthorizedKeysFile /home/lws/your-authorized-keys-file
                    
    3. Create your handler script: `/home/lws/handler.sh` (don't forget to make it executable):

           #/bin/bash
           echo "original command was $SSH_ORIGINAL_COMMAND"

    3. Restart sshd on server:

            sudo /etc/init.d/ssh restart


# Setup per Node (Client) (on every node deployment)

       sudo apt install netcat
       git clone --recursive https://github.com/aktos-io/link-with-server
       cd link-with-server
       cp config.sh{.sample,}
       nano config.sh
       ./gen-private-key-if-necessary.sh 
       cat ${SSH_KEY_FILE}.pub  # | curl -F 'sprunge=<-' http://sprunge.us # to share with an external service.
       # Send it *manually* to your server. BEWARE Possible MITM attacks. 
       # Insert the line public key contents into /home/lws/your-authorized-keys-file 
       ./link-with-server.sh --test && ./register-to-boot.sh
       # Trigger the first run manually: sudo systemctl start ...


1. Clone this repository. 
2. Create `config.sh` (see `config.sh.sample`)
3. Create public/private key pair if necessary.
4. Append your node's public key to the `authorized_keys` file on your LINK_UP_SERVER. 
5. Test your connectivity with simply running `./link-with-server.sh --test`.
6. Start `./link-with-server.sh` as a long running application, by using `./register-to-boot.sh` or: 

        nohup ./link-with-server.sh & ; exit 

# Hooks

Place any scripts `on/connect` and `on/disconnect` folders.

# Recommended Tools

* [aktos-io/service-runner](https://github.com/aktos-io/service-runner): Run applications on boot and manage/debug them easily.
