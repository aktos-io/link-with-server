# Link With Server

Creates a link between the CLIENT and the LINK UP SERVER.

**WARNING** : `StrictHostKeyChecking` is disabled, you must get prepared for MITM attacks.


# Setup SSH Server on Server Side (for the first time)

1. Install OpenSSH server if not installed.
2. **Recommended** (or you can use an existing account for this purpose):
    1. Create a standard Unix user account (eg. `adduser lws`) to manage the connections.
    2. Add following section to `/etc/ssh/sshd_config` file:
        
            Match User lws
                    AllowTcpForwarding yes
                    PermitTunnel yes
                    ForceCommand /home/lws/handler.sh  
                    PasswordAuthentication no
                    AuthorizedKeysFile /home/lws/your-authorized-keys-file
                    
    3. Create your handler script: `/home/lws/handler.sh` (don't forget to make it executable):

       ```bash
       #/bin/bash
       echo "original command was $SSH_ORIGINAL_COMMAND"
       ```

    3. Restart sshd on server:

            sudo /etc/init.d/ssh restart


# Setup per CLIENT on every deployment

```bash
sudo apt install netcat
git clone --recursive https://github.com/aktos-io/link-with-server
cd link-with-server
cp config.sh{.sample,} && nano config.sh  # edit accordingly
./gen-private-key-if-necessary.sh 
./send-public-key.sh
./link-with-server.sh --test && ./register-to-boot.sh # or run manually: ./link-with-server.sh
./watch-logs.sh monitor
```
        
# Usage

Assuming: 
* You are on some other machine where the link-with-server is setup (or you may already have an 
account on the LINK_UP_SERVER, use that credentials).
* You want to connect to a client/node that put its SSHD port on 1234 on LINK_UP_SERVER and 
the username you want to login as is `foo`.

* Either use https://github.com/aktos-io/dcs-tools
* Or use `ssh-jump.sh` (see `ssh-jump --help`): 

      ./ssh-jump.sh -t 1234 -u foo

* Or quickly connect to your target by: 

      source ./config.sh
      ssh_jump(){ ssh -J ${SSH_USER}@${SSH_HOST}:{SSH_PORT} ${2}@localhost -p ${1}; } 
      ssh_jump 1234 foo

# Hooks

Place any scripts `on/connect` and `on/disconnect` folders.

# Recommended Tools

* [aktos-io/service-runner](https://github.com/aktos-io/service-runner): Run applications on boot and manage/debug them easily.
