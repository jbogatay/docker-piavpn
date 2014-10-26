#!/bin/bash
set -e

# check env variables
[ ! -d /torrents ] && echo "[crit] torrent directory not moutned (-v /yourtorrentdir:/torrents )" && exit 1
[ ! -d /app/deluge ] && echo "[crit] deluge config directory not moutned (-v /yourdelugedir:/app/deluge )" && exit 1

# create the tun device
[ -d /dev/net ] || mkdir -p /dev/net
[ -c /dev/net/tun ] || mknod /dev/net/tun c 10 200

# setup route for deluge web ui
DEFAULT_GATEWAY=$(ip route show default | awk '/default/ {print $3}')
if [ -z "${HOST_SUBNET}" ]; then
	echo "[warn] HOST_SUBNET not specified, deluge web interface will not work"
else
	ip route add $HOST_SUBNET via $DEFAULT_GATEWAY
fi
echo "[info] current route"
ip route
echo "--------------------"

# only run the uid/gid creation on first run
if [ ! -f /app/runonce ]; then

  echo "Performing first time setup"
 
	# setup pia pw
	if [ ! -f /config/openvpn/pw ]; then
		[ -z "${PIA_USER}" ] && echo "[crit] PIA_USER not specified" && exit 1
		[ -z "${PIA_PASS}" ] && echo "[crit] PIA_PASS not specified" && exit 1
		echo "${PIA_USER}" > /etc/openvpn/pw
		echo "${PIA_PASS}" >> /etc/openvpn/pw
	fi
	
	# setup pia client
	if [ ! -f /etc/openvpn/pia_client ]; then
		if [ -z "${PIA_CLENT}" ]; then
	  	client_id=`head -n 100 /dev/urandom | md5sum | tr -d " -"`
	  	echo "[info] PIA client set to $client_id"
	  	echo "$client_id" > /etc/openvpn/pia_client
	  else
	  	echo "[info] using environment pia client id"
	  	echo "${PIA_CLENT}" > /etc/openvpn/pia_client
	  fi
	else
	  echo "[notice] using existing pia client id"
	fi   
	   
	# configure PIA gateway
	[ -z "${PIA_GATEWAY}" ] && echo "[crit] PIA_GATEWAY not specified" && exit 1
	sed "s/^remote\s.*$/remote ${PIA_GATEWAY} 1194/" -i /etc/openvpn/default.conf
	cat /etc/openvpn/default.conf
	
  #sanity check uid/gid
  if [ $DELUGE_UID -ne 0 -o $DELUGE_UID -eq 0 2>/dev/null ]; then
  	if [ $DELUGE_UID -lt 100 -o $DELUGE_UID -gt 65535 ]; then
    	echo "[warn] DELUGE_UID out of (100..65535) range, using default of 500"
      DELUGE_UID=500
    fi
  else
    echo "[warn] DELUGE_UID non-integer detected, using default of 500"
    DELUGE_UID=500
	fi

	if [ $DELUGE_GID -ne 0 -o $DELUGE_GID -eq 0 2>/dev/null ]; then
	  if [ $DELUGE_GID -lt 100 -o $DELUGE_GID -gt 65535 ]; then
	     echo "[warn] DELUGE_GID out of (100..65535) range, using default of 500"
	     DELUGE_GID=500
	  fi
	else
	  echo "[warn] DELUGE_GID non-integer detected, using default of 500"
	  DELUGE_GID=500
	fi

	# add UID/GID or use existing
	groupadd --gid $DELUGE_GID torrents || echo "Using existing group $DELUGE_GID"
	useradd --gid $DELUGE_GID --no-create-home --uid $DELUGE_UID torrents



   # set runonce so it... runs once
   touch /app/runonce

fi

chown -R $DELUGE_UID:$DELUGE_GID /app/deluge
chown -R $DELUGE_UID:$DELUGE_GID /torrents

# spin it up
exec /usr/sbin/runsvdir-start
                          