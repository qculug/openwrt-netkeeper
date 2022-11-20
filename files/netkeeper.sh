#!/bin/sh

kill_pppoe_server() {
    if [ -n "$(pgrep pppoe-server)" ]; then
        kill "$(pgrep pppoe-server)"
    fi
}
restart_pppoe_server() {
    kill_pppoe_server
    # Clear pppoe.log
    cat /dev/null > /tmp/pppoe.log
    # Start pppoe-server
    pppoe-server -k -I br-lan
}

kill_pppoe_server
# Start pppoe-server
pppoe-server -k -I br-lan

while :; do
    for PPPOE_ERRORS in 0 1 2; do
        if [ -z "$(ifconfig | grep "netkeeper")" ]; then
            # After the loop executes three times, restart the pppoe-server process
            if [ "$PPPOE_ERRORS" -eq "2" ]; then
                restart_pppoe_server
                continue
            fi
            cat /dev/null > /tmp/pppoe.log.0
            # Output log to pppoe.log
            ifup netkeeper
            sleep 15s
            PPPOE="0"
            while [ "$PPPOE" -lt "2" ]; do
                # Read the last username and password in pppoe.log
                USERNAME="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 2)"
                PASSWORD="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
                if [ -n "$USERNAME" ]; then
                    PPPOE_USERNAME="$(uci get network.netkeeper.username 2> /dev/null)"
                    if [ "$USERNAME" != "$PPPOE_USERNAME" ]; then
                        uci set network.netkeeper.username="$USERNAME"
                        uci set network.netkeeper.password="$PASSWORD"
                        uci commit network.netkeeper
                        ifup netkeeper
                        logger -t netkeeper "new username: $USERNAME"
                    else
                        if [ -z "$(ifconfig | grep "netkeeper")" ]; then
                            ifup netkeeper
                        fi
                    fi
                    sleep 15s
                    PPPOE="$((PPPOE + 1))"
                else
                    break
                fi
            done
        else
            if [ ! -s "/tmp/pppoe.log.0" ]; then
                cat /tmp/pppoe.log > /tmp/pppoe.log.0
                sync
                # Clear pppoe.log
                cat /dev/null > /tmp/pppoe.log
            fi
            # After the loop executes three times, restart the pppoe-server process
            if [ "$PPPOE_ERRORS" -eq "2" ]; then
                restart_pppoe_server
                continue
            fi
            sleep 10s
            # Read the last username and password in pppoe.log
            USERNAME="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 2)"
            PASSWORD="$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
            if [ -n "$USERNAME" ]; then
                PPPOE_USERNAME="$(uci get network.netkeeper.username 2> /dev/null)"
                if [ "$USERNAME" != "$PPPOE_USERNAME" ]; then
                    uci set network.netkeeper.username="$USERNAME"
                    uci set network.netkeeper.password="$PASSWORD"
                    uci commit network.netkeeper
                fi
            fi
        fi
    done
done
