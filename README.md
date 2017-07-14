# Link With Server

Creates a link between the NODE and the RENDEZVOUS SERVER.

# Setup on Server

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


# Setup per Node

1. Copy your node's public key to `/home/forward/.ssh/authorized_keys` in your favourite way.
2. Setup your configuration file.
3. Setup to run `link-with-server.sh` on startup on node.

    > Running this script in background is your responsibility.
    > Preferred way is running with `aktos-io/service-runner`
    > Simplest method is: add following line in `/etc/rc.local` file:
    >
    >     nohup /path/to/link-with-server.sh &
    >
