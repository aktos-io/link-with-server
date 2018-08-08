# Link With Server

Creates a link between the NODE and the LINK UP SERVER.

**WARNING** : `StrictHostKeyChecking` is disabled, you must prepare for a MITM attack.


# Setup SSH Server on Server Side (for the first time)

1. Install OpenSSH server if not installed.
2. **Recommended**:
    1. Create a standard unix user account (say `forward`) and use it for the connections.
    2. Add following section to `/etc/ssh/sshd_config` file:

            Match User forward
                    AllowTcpForwarding yes
                    PermitTunnel yes
                    ForceCommand echo "This account is only for making link with server"
                    PasswordAuthentication no

        or use a handler script:
        
            Match User forward
                    AllowTcpForwarding yes
                    PermitTunnel yes
                    ForceCommand /path/to/handler.sh
                    PasswordAuthentication no
                    
        *handler.sh*:

           #/bin/bash
           echo "original command was $SSH_ORIGINAL_COMMAND"

    3. Restart sshd on server:

            sudo /etc/init.d/ssh restart


# Setup per Node (on every node deployment)

1. Clone this repository:

       git clone --recursive https://github.com/aktos-io/link-with-server

2. Create public/private key pair:

       cd link-with-server
       ./gen-private-key.sh

3. Append your node's public key to `/home/forward/.ssh/authorized_keys` file on LINK_UP_SERVER in your favourite way.

        # Basically, just copy and paste the following command's output:
        $ cat ~/.ssh/id_rsa.pub
        ssh-rsa AAAAB3NzaC1yc2EAA...UCSo974furRP5N foo@example.com  

4. Edit the configuration file (`./config.sh`) to set host and port.

5. Make `link-with-server.sh` run on startup.

    > Running this script in background is your responsibility. <br />
    > Recommended way: Use [aktos-io/service-runner](https://github.com/aktos-io/service-runner) <br />
    > Simplistic way:  Add following line into the `/etc/rc.local` file:
    >
    >     nohup /path/to/link-with-server.sh &
    >


# Usage

1. Run `./link-with-server.sh` to create a link with server.

    > When "tunnel is established", the `LINK_UP_SSHD_PORT` on server
    > is representing the ssh port (22) of the NODE.

2. Place any scripts:

    1. to run before actual link is created: `on/connect` folder.
    3. to run on disconnect: `on/disconnect` folder.

# Recommended Tools

* [aktos-io/service-runner](https://github.com/aktos-io/service-runner): Run applications on boot and manage/debug them easily.
