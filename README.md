# Link With Server

Creates a link between the NODE and the RENDEZVOUS SERVER.

# Setup on Server (for the first time)

1. Install OpenSSH server if not installed.
2. Create a standard unix user account (say `forward`)
3. Add following section to `/etc/ssh/sshd_config` file:

        Match User forward
                AllowTcpForwarding yes
                PermitTunnel yes
                ForceCommand echo "This account is only for making link with server"
                PasswordAuthentication no


4. Restart sshd on server:

        sudo /etc/init.d/ssh restart

5. Place any server side programs in `/home/forward` folder and start on system startup


# Setup per Node (on every node deployment)

1. Clone this repository: 

       git clone https://github.com/aktos-io/link-with-server --init --recursive 

2. Create public/private key pair: 

       ssh-keygen -N '' -t rsa -b 4096 -C "your_email@example.com"

3. Copy your node's public key to `/home/forward/.ssh/authorized_keys` file on RENDEZVOUS_SERVER in your favourite way.

        # Basically, just copy and paste your public key: 
        $ cat ~/.ssh/id_rsa.pub
        ....your public key to select, copy and paste into authorized_keys...
        
4. Edit the configuration file (`./config.sh`).

5. Make `link-with-server.sh` run on startup.

    > Running this script in background is your responsibility.
    > Preferred way is running with `aktos-io/service-runner`
    > Simplest method is: add following line in `/etc/rc.local` file:
    >
    >     nohup /path/to/link-with-server.sh &
    >
    
    
# Usage 

1. Run `./link-with-server.sh` to create a link with server. 

    > When "tunnel is established", the `RENDEZVOUS_SSHD_PORT` on server 
    > is representing the ssh port (22) of the NODE. 
    
2. If you have any scripts to run on connection, place them under `on-connect` folder. 
3. If you have any scripts to run on disconnection, place them under `on-disconnect` folder. 



