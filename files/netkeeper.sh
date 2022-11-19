#!/bin/sh

kill_pppoe_server() {
    if [ -n "$(pgrep pppoe-server)" ]; then
        kill "$(pgrep pppoe-server)"
    fi
}
restart_netkeeper() {
    ifdown netkeeper
    ifup netkeeper
}

kill_pppoe_server
# Start pppoe-server
pppoe-server -k -I br-lan

while :; do
    for PPPOE_ERRORS in 0 1 2; do
        if [ -z "$(ifconfig | grep "netkeeper")" ]; then
            # After the loop executes three times, kill the pppoe-server process
            if [ "$PPPOE_ERRORS" -eq "2" ]; then
                kill_pppoe_server
                # Start pppoe-server
                pppoe-server -k -I br-lan
                continue
            fi
            cat /dev/null > /tmp/pppoe.log.0
            restart_netkeeper
            sleep 15s
            PPPOE="0"
            while [ "$PPPOE" -lt "2" ]; do
                # Read the last username and password in pppoe.log
                USERNAME="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 2)"
                PASSWORD="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
                if [ -n "$USERNAME" ]; then
                    PPPOE_USERNAME="$(uci get network.netkeeper.username 2> /dev/null)"
                    if [ "$USERNAME" != "$PPPOE_USERNAME" ]; then
                        ifdown netkeeper
                        uci set network.netkeeper.username="$USERNAME"
                        uci set network.netkeeper.password="$PASSWORD"
                        uci commit network.netkeeper
                        ifup netkeeper
                        logger -t netkeeper "new username: $USERNAME"
                    else
                        if [ -z "$(ifconfig | grep "netkeeper")" ]; then
                            restart_netkeeper
                        fi
                    fi
                    sleep 10s
                else
                    continue
                fi
                PPPOE="$((PPPOE + 1))"
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
