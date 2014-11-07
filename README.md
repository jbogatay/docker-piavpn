docker-piavpn
================

Ubuntu:1404 based Privateinternetaccess.com vpn with torrents/proxy (openvpn, deluged, deluge-web, dante-server)

Complete run command with all options

    docker run -d -p 8112:8112 -p 1080:1080 \
        --name vpn \
        --dns=8.8.8.8 \
        --cap-add=NET_ADMIN \    
        -v /mytorrentdir:/torrents \
        -v /mydelugeconfigdir:/app/deluge \
        -v /etc/localtime:/etc/localtime:ro \
        -e DELUGE_UID=500 -e DELUGE_GID=500 \
        -e HOST_SUBNET=192.168.1.0/24 \
        -e PIA_USER=<user> \
        -e PIA_PASS=<password> \
        -e PIA_CLIENT=<optionalpiaclient> \
        -e PIA_GATEWAY=piavpnaddress.com \        
        jbogatay/piavpn


Change directory mappings as appropriate (delugeconfig, torrents)

notes
=====

* DELUGE_UID and DELUGE_GID are optional, but will default to 500/500.   Specify the UID/GID that corresponds to the **HOST** UID/GID you want to own the downloads, config and movies directories.
* The deluge web will only work on your local subnet.   Policy based routing is what led me to this solution, I'm not going down that road again.  If you need access from the outside, either VPN or SSH/Port forward in.
* You must map a torrents directory, no torrents inside container
* If you want it to restart on reboot, add --restart=always
* If you leave the DNS out, your local dns servers will be used.  Not good for privacy.
* The NET_ADMIN capability is needed to create the TUN device
* The host subnet needs to be in CIDR notation.   For example if your host network is 192.168.1.x with a netmask of 255.255.255.0, then HOST_SUBNET=192.168.1.0/24
* The PIA_CLIENT is optional, but if you generate one yourself port mappings will be preserved between cold starts.   Here is one way to generate a PIA_CLIENT.


    head -n 100 /dev/urandom | md5sum | tr -d " -"
    

* PIA_GATEWAY is just a pia vpn hostname.  (ca.privateinternetaccess.com, nl.privateinternetaccess.com, etc)
* After running for the first time, setup deluge so all torrents begin with /torrents
