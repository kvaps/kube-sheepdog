#!/bin/sh

CONFIG_DIR="${CONFIG_DIR:-/config}"
ZOOCONF_DIR="${ZOOCONF_DIR:-/etc/zookeeper/conf}"

#CLIENT_PORT=$(cat "$CONFIG_DIR/zoo.cfg" | sed -n 's/^clientPort=\([0-9]\+\)/\1/p')
SERVER_LIST=$(cat "$CONFIG_DIR/zoo.cfg" | sed -n 's/^server\.\([0-9]\+\)=\(.*\)\:\([0-9]\+\)\:\([0-9]\+\)$/\1 \2 \3 \4/p')

if [ -z "$MYID" ]; then
    while read ID HOST PORT1 PORT2; do
        IP=$(getent hosts "$HOST" | awk '{print $1}')
    
        if ip -o addr | grep -q "inet6\? $IP\(/\| \|\$\)"; then
            if [ -z "$MYID" ]; then
                MYID="$ID"
            else
                >&2 echo "error: Can not identify MYID, multiple IPs found."
                exit 1
            fi
        fi
    
    done < <(echo "$SERVER_LIST")

    if [ -z "$MYID" ]; then
        >&2 echo "error: Can not identify MYID, no IPs found."
        exit 1
    fi
fi

mkdir -p "$ZOOCONF_DIR"
find "$CONFIG_DIR/" -mindepth 1 -maxdepth 1 ! -name myid -exec cp -a "{}" "$ZOOCONF_DIR/" \;
echo "$MYID" > "$ZOOCONF_DIR/myid"

/usr/share/zookeeper/bin/zkServer.sh start-foreground
