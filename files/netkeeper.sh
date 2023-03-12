#!/bin/sh

kill_pppoe_server() {
    if [ -n "$(pgrep pppoe-server)" ]; then
        kill "$(pgrep pppoe-server)"
    fi
}

restart_pppoe_server() {
    # Clear pppoe-server.log
    #cat /dev/null > /var/log/pppoe-server.log
    kill_pppoe_server
    # Start pppoe-server
    pppoe-server -k -I br-lan
}

clear_pppoe_server_log() {
    if [ -f '/var/log/pppoe-server.log' ]; then
        if [ "$(du -k /var/log/pppoe-server.log | cut -f 1)" -gt 20 ]; then
            # Clear pppoe-server.log
            cat /dev/null > /var/log/pppoe-server.log
        fi
    else
        # Clear pppoe-server.log
        cat /dev/null > /var/log/pppoe-server.log
    fi
}

clear_ppp_log() {
    if [ -f '/var/log/ppp.log' ]; then
        if [ "$(du -k /var/log/ppp.log | cut -f 1)" -gt 20 ]; then
            # Clear ppp.log
            cat /dev/null > /var/log/ppp.log
        fi
    else
        # Clear ppp.log
        cat /dev/null > /var/log/ppp.log
    fi
}

set_network_macaddr() {
    NEWMAC="$(dd if=/dev/urandom bs=1024 count=1 2>/dev/null | md5sum | sed -e 's/^\(..\)\(..\)\(..\)\(..\)\(..\)\(..\).*$/\1:\2:\3:\4:\5:\6/' -e 's/^\(.\)[13579bdf]/\10/')"
    if [ -n "$(uci -q show network | grep @device | grep macaddr | awk -F '=' '{print $1}')" ]; then
        #uci set network.@device[1].macaddr="$NEWMAC"
        uci set "$(uci show network | grep @device | grep macaddr | awk -F '=' '{print $1}')"="$NEWMAC"
    else
        uci set network.netkeeper.macaddr="$NEWMAC"
    fi
}

main () {
    restart_pppoe_server
    while :; do
        #for PPPOE_ERRORS in 0 1 2; do
        if [ -z "$(ifconfig | grep "netkeeper")" ]; then
            # After the loop executes three times, restart the pppoe-server process
            #if [ "$PPPOE_ERRORS" -eq 2 ]; then
            #restart_pppoe_server
            #continue
            #fi
            # Clear pppoe-server.log.0
            cat /dev/null > /var/log/pppoe-server.log.0
            # Clear ppp.log.0
            cat /dev/null > /var/log/ppp.log.0
            clear_pppoe_server_log
            clear_ppp_log
            # Output log to ppp.log
            ifup netkeeper
            sleep 15s
            #PPPOE="0"
            #while [ "$PPPOE" -lt 2 ]; do
            if [ -f '/var/log/pppoe-server.log' ]; then
                # Read the last username and password in pppoe-server.log
                #USERNAME="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 2)"
                USERNAME="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | sed 's/.*user="//;s/" password=.*//')"
                #PASSWORD="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
                PASSWORD="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | sed 's/.*password="//;s/".*//')"
                if [ -n "$USERNAME" ]; then
                    PPPOE_USERNAME="$(uci -q get network.netkeeper.username)"
                    if [ "$USERNAME" != "$PPPOE_USERNAME" ]; then
                        set_network_macaddr
                        uci set network.netkeeper.username="$USERNAME"
                        uci set network.netkeeper.password="$PASSWORD"
                        uci commit network
                        ifup netkeeper
                        logger -t netkeeper "new username: $USERNAME"
                        sleep 15s
                        #else
                        #if [ -z "$(ifconfig | grep "netkeeper")" ]; then
                        #ifup netkeeper
                        #fi
                    fi
                    #sleep 15s
                    #PPPOE="$((PPPOE + 1))"
                    #else
                    #break
                fi
            fi
            #done
        else
            # After the loop executes three times, restart the pppoe-server process
            #if [ "$PPPOE_ERRORS" -eq 2 ]; then
            #restart_pppoe_server
            #continue
            #fi
            if [ ! -s '/var/log/pppoe-server.log.0' ]; then
                if [ -s '/var/log/pppoe-server.log' ]; then
                    cat /var/log/pppoe-server.log > /var/log/pppoe-server.log.0
                    sync
                    # Read the username in pppoe-server.log.0
                    USERNAME="$(grep 'user=' /var/log/pppoe-server.log.0 | grep 'rcvd' | tail -n 1 | sed 's/.*user="//;s/" password=.*//')"
                    if [ -n "$USERNAME" ]; then
                        PPPOE_USERNAME="$(uci -q get network.netkeeper.username)"
                        if [ "$USERNAME" = "$PPPOE_USERNAME" ]; then
                            uci set network.netkeeper.username='username'
                            uci set network.netkeeper.password='password'
                            uci commit network
                            # Clear pppoe-server.log
                            cat /dev/null > /var/log/pppoe-server.log
                        fi
                    fi
                fi
            fi
            if [ ! -s '/var/log/ppp.log.0' ]; then
                if [ -s '/var/log/ppp.log' ]; then
                    cat /var/log/ppp.log > /var/log/ppp.log.0
                    sync
                fi
            fi
            clear_pppoe_server_log
            clear_ppp_log
            sleep 30s
            if [ -f '/var/log/pppoe-server.log' ]; then
                # Read the last username and password in pppoe-server.log
                #USERNAME="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 2)"
                USERNAME="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | sed 's/.*user="//;s/" password=.*//')"
                #PASSWORD="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | cut -d \" -f 4)"
                PASSWORD="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | sed 's/.*password="//;s/".*//')"
                if [ -n "$USERNAME" ]; then
                    PPPOE_USERNAME="$(uci -q get network.netkeeper.username)"
                    if [ "$USERNAME" != "$PPPOE_USERNAME" ]; then
                        set_network_macaddr
                        uci set network.netkeeper.username="$USERNAME"
                        uci set network.netkeeper.password="$PASSWORD"
                        uci commit network
                    fi
                fi
            fi
        fi
        #done
    done
}

main
