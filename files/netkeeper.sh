#!/bin/sh

# Start pppoe-server
if [ -n "$(pgrep pppoe-server)" ]; then
    kill "$(pgrep pppoe-server)"
fi
pppoe-server -k -I br-lan

# Clear log
cat /dev/null > /tmp/pppoe.log

# Wait 15 seconds for the service to restart,
# otherwise there will be an error "you have accessed in"
sleep 15s

logger -t netkeeper "try to login at power on"

ifdown netkeeper
ifup netkeeper

while :; do
    # Read the last username and password in pppoe.log
    USERNAME="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 2)"
    PASSWORD="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
    if [ "$USERNAME" != "$USERNAME_OLD" ]; then
        ifdown netkeeper
        uci set network.netkeeper.username="$USERNAME"
        uci set network.netkeeper.password="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
        uci commit
        ifup netkeeper
        USERNAME_OLD="$USERNAME"
        logger -t netkeeper "new username $USERNAME"
    fi
    sleep 10
    # Close pppoe if log show fail
    if [ -z "$(ifconfig | grep "netkeeper")" ]; then
        ifdown netkeeper
    fi
done
