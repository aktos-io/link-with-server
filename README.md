# link-with-server

Creates a ssh connection between target system and your rendezvous server via SSH tunnel so you can reach your target system's SSH servers via your rendezvous server as follows: 

```
ssh you@rendezvous-server
ssh target_username@localhost -p ${target_port}
```


# Install

```
./link-with-server  

## this will create keys and configuration file, if not found. 
## if so, edit your configuration file accordingly and run the command again:
#./link-with-server

# all done. If you want to keep the tunnel alive all the time, run the following: 
./link-with-server install
```

