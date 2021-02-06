# Link With Server

Creates a link between the CLIENT and the LINK UP SERVER.

**WARNING** : `StrictHostKeyChecking` is disabled, you must get prepared for MITM attacks.


# Setup SSH Server on Server Side (for the first time)

1. Install OpenSSH server if not installed.
2. You may use an existing user account on the server side. However, setting up a new account is **recommended**:
    1. Create a standard user account: 
    
           adduser lws
           
    2. Add the following section to `/etc/ssh/sshd_config`:
        
            Match User lws
                    AllowTcpForwarding yes
                    PermitTunnel yes
                    ForceCommand /home/lws/handler.sh  
                    PasswordAuthentication no
                    AuthorizedKeysFile /home/lws/your-authorized-keys-file
                    
    3. Create your handler script: `/home/lws/handler.sh` (don't forget to make it executable):

       ```bash
       #!/bin/bash
       # This message will appear on the client side when the client 
       # tries to login to interactive shell:
       echo "ERROR: No shell access is allowed. Original command was: $SSH_ORIGINAL_COMMAND" 
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
./send-public-key.sh  # and follow the instructions 
./link-with-server.sh --test && ./register-to-boot.sh # or run manually: ./link-with-server.sh
./watch-logs.sh
```
        
# Usage

Assuming: 
1. You have SSH access to the LINK_UP_SERVER 
2. You want to connect to a client/node (`AAA`) that has put its SSHD port on `LINK_UP_SERVER:1234` and the username is `foo`.

You can connect to `foo@AAA` from anywhere by:
* Either using https://github.com/aktos-io/dcs-tools (provides advanced backup and management tools)
* Or using `link-with-server/ssh-jump.sh`:

      ./ssh-jump.sh -t 1234 -u foo

* Or with the following one liner without any dependencies: 

      # assuming you would normally connect to LINK_UP_SERVER by `ssh myuser@11.22.33.44 -p 2255`
      ssh_jump(){ ssh -J myuser@11.22.33.44:2255 ${2}@localhost -p ${1}; }; ssh_jump 1234 foo

# Hooks

Place any scripts `on/connect` and `on/disconnect` folders.

# Recommended Tools

* [aktos-io/service-runner](https://github.com/aktos-io/service-runner): Run applications on boot and manage/debug them easily.
