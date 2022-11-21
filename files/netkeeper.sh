#!/bin/sh

kill_pppoe_server() {
    if [ -n "$(pgrep pppoe-server)" ]; then
        kill "$(pgrep pppoe-server)"
    fi
}

restart_pppoe_server() {
    kill_pppoe_server
    # Clear pppoe-server.log
    cat /dev/null > /var/log/pppoe-server.log
    # Start pppoe-server
    pppoe-server -k -I br-lan
}

main () {
    kill_pppoe_server
    # Start pppoe-server
    pppoe-server -k -I br-lan

    while :; do
        for PPPOE_ERRORS in 0 1 2; do
            if [ -z "$(ifconfig | grep "netkeeper")" ]; then
                # After the loop executes three times, restart the pppoe-server process
                if [ "$PPPOE_ERRORS" -eq 2 ]; then
                    restart_pppoe_server
                    continue
                fi
                # Clear ppp.log
                cat /dev/null > /var/log/ppp.log
                cat /dev/null > /var/log/ppp.log.0
                # Output log to ppp.log
                ifup netkeeper
                sleep 15s
                PPPOE="0"
                while [ "$PPPOE" -lt 2 ]; do
                    # Read the last username and password in pppoe-server.log
                    USERNAME="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 2)"
                    PASSWORD="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
                    if [ -n "$USERNAME" ]; then
                        PPPOE_USERNAME="$(uci -q get network.netkeeper.username)"
                        if [ "$USERNAME" != "$PPPOE_USERNAME" ]; then
                            uci set network.netkeeper.username="$USERNAME"
                            uci set network.netkeeper.password="$PASSWORD"
                            uci commit network
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
                if [ ! -s "/var/log/ppp.log.0" ]; then
                    cat /var/log/ppp.log > /var/log/ppp.log.0
                    sync
                    # Clear ppp.log
                    cat /dev/null > /var/log/ppp.log
                fi
                if [ "$(du -k /var/log/ppp.log | cut -f 1)" -gt 20 ]; then
                    # Clear ppp.log
                    cat /dev/null > /var/log/ppp.log
                fi
                # After the loop executes three times, restart the pppoe-server process
                if [ "$PPPOE_ERRORS" -eq 2 ]; then
                    restart_pppoe_server
                    continue
                fi
                sleep 10s
                # Read the last username and password in pppoe-server.log
                USERNAME="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 2)"
                PASSWORD="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
                if [ -n "$USERNAME" ]; then
                    PPPOE_USERNAME="$(uci -q get network.netkeeper.username)"
                    if [ "$USERNAME" != "$PPPOE_USERNAME" ]; then
                        uci set network.netkeeper.username="$USERNAME"
                        uci set network.netkeeper.password="$PASSWORD"
                        uci commit network
                    fi
                fi
            fi
        done
    done
}

main
