#!/bin/sh

NETKEEPER_DB_PATH='/usr/lib/netkeeper/netkeeper.db'

kill_pppoe_server() {
    if [ -n "$(pgrep pppoe-server)" ]; then
        kill "$(pgrep pppoe-server)"
    fi
}

restart_pppoe_server() {
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

sqlite3_netkeeper_db() {
    if [ ! -f "$NETKEEPER_DB_PATH" ]; then
        sqlite3 "$NETKEEPER_DB_PATH" ".databases"
    fi
    if [ "$(sqlite3 $NETKEEPER_DB_PATH "select count(*) from sqlite_master where type = 'table' and name = 'netkeeper';")" -eq 0 ]; then
        sqlite3 "$NETKEEPER_DB_PATH" "create table netkeeper(id integer primary key, username text not null, password text not null);"
    fi
}

main () {
    restart_pppoe_server
    while :; do
        if [ -z "$(ifconfig | grep "netkeeper")" ]; then
            # Clear ppp.log.0
            cat /dev/null > /var/log/ppp.log.0
            clear_pppoe_server_log
            clear_ppp_log
            sqlite3_netkeeper_db
            if [ "$(sqlite3 $NETKEEPER_DB_PATH "select count(*) from netkeeper;")" -eq 0 ]; then
                sleep 15s
                if [ -f '/var/log/pppoe-server.log' ]; then
                    # Read the last username and password in pppoe-server.log
                    USERNAME="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | sed 's/.*user="//;s/" password=.*//')"
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
                        fi
                    fi
                fi
            else
                DATABASE_ID="$(netkeeper-db next_data | grep 'id = ' | sed 's/.*id = //')"
                USERNAME="$(netkeeper-db next_data | grep 'username = ' | sed 's/.*username = //')"
                PASSWORD="$(netkeeper-db next_data | grep 'password = ' | sed 's/.*password = //')"
                PPPOE_USERNAME="$(uci -q get network.netkeeper.username)"
                if [ "$USERNAME" != "$PPPOE_USERNAME" ]; then
                    set_network_macaddr
                    uci set network.netkeeper.username="$USERNAME"
                    uci set network.netkeeper.password="$PASSWORD"
                    uci commit network
                    sqlite3 "$NETKEEPER_DB_PATH" "delete from netkeeper where id=$DATABASE_ID"
                    logger -t netkeeper "delete from netkeeper where id=$DATABASE_ID"
                    ifup netkeeper
                    logger -t netkeeper "new username: $USERNAME"
                    sleep 15s
                fi
            fi
        else
            if [ ! -s '/var/log/ppp.log.0' ]; then
                if [ -s '/var/log/ppp.log' ]; then
                    cat /var/log/ppp.log > /var/log/ppp.log.0
                    sync
                fi
            fi
            clear_pppoe_server_log
            clear_ppp_log
            sqlite3_netkeeper_db
            sqlite3 "$NETKEEPER_DB_PATH" "delete from netkeeper where rowid not in (select min(rowid) from netkeeper group by username);"
            if [ "$(du -k "$NETKEEPER_DB_PATH" | cut -f 1)" -lt 200 ]; then
                if [ -f '/var/log/pppoe-server.log' ]; then
                    # Read the last username and password in pppoe-server.log
                    USERNAME="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | sed 's/.*user="//;s/" password=.*//')"
                    PASSWORD="$(grep 'user=' /var/log/pppoe-server.log | grep 'rcvd' | tail -n 1 | sed 's/.*password="//;s/".*//')"
                    if [ -n "$USERNAME" ]; then
                        PPPOE_USERNAME="$(uci -q get network.netkeeper.username)"
                        if [ "$USERNAME" != "$PPPOE_USERNAME" ]; then
                            sqlite3 "$NETKEEPER_DB_PATH" "insert into netkeeper values(null, '$USERNAME', '$PASSWORD');"
                            # Clear pppoe-server.log
                            cat /dev/null > /var/log/pppoe-server.log
                            sync
                        fi
                    fi
                fi
            fi
            sleep 5s
        fi
    done
}

main
