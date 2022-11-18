#!/bin/sh

kill_pppoe_server() {
    if [ -n "$(pgrep pppoe-server)" ]; then
        kill "$(pgrep pppoe-server)"
    fi
}
restart_netkeeper() {
    ifdown netkeeper
    uci set network.netkeeper.username="$USERNAME"
    uci set network.netkeeper.password="$PASSWORD"
    uci commit network.netkeeper
    ifup netkeeper
}

kill_pppoe_server
# Start pppoe-server
pppoe-server -k -I br-lan

while :; do
    for PPPOE_ERRORS in 1 2 3 4; do
        if [ -z "$(ifconfig | grep "netkeeper")" ]; then
            cat /dev/null > /tmp/pppoe.log.0
            # After the loop executes three times, kill the pppoe-server process
            if [ "$PPPOE_ERRORS" -eq "4" ]; then
                kill_pppoe_server
                # Start pppoe-server
                pppoe-server -k -I br-lan
                continue
            fi
            ifdown netkeeper
            ifup netkeeper
            sleep 10s
            for PPPOE in 1 2 3; do
                # Read the last username and password in pppoe.log
                USERNAME="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 2)"
                PASSWORD="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
                if [ "$USERNAME" != "$USERNAME_OLD" ]; then
                    restart_netkeeper
                    USERNAME_OLD="$USERNAME"
                    logger -t netkeeper "new username $USERNAME"
                else
                    if [ -z "$(ifconfig | grep "netkeeper")" ]; then
                        restart_netkeeper
                    fi
                fi
                sleep 10s
            done
        else
            if [ ! -s "/tmp/pppoe.log.0" ]; then
                cat /tmp/pppoe.log > /tmp/pppoe.log.0
            fi
            # Clear pppoe.log
            cat /dev/null > /tmp/pppoe.log
        fi
    done
done
