#!/bin/sh

change_ppp_options() {
    if [ -f '/etc/ppp/options.orig.bak' ]; then
        echo "info: options.orig.bak file already exist."
        return 0
    fi
    cp /etc/ppp/options /etc/ppp/options.orig.bak
    # Enables connection debugging facilities
    sed -i 's/#debug/debug/' /etc/ppp/options
    # Change log location
    sed -i 's/\/dev\/null/\/var\/log\/ppp.log/' /etc/ppp/options
}

change_pppoe_server_options() {
    if [ -f '/etc/ppp/pppoe-server-options.orig.bak' ]; then
        echo "info: pppoe-server-options.orig.bak file already exist."
        return 0
    fi
    cp /etc/ppp/pppoe-server-options /etc/ppp/pppoe-server-options.orig.bak
    # Enables connection debugging facilities
    sed -i '/GPL/a debug' /etc/ppp/pppoe-server-options
    # Change log location
    sed -i '/debug/a logfile \/var\/log\/pppoe-server.log' /etc/ppp/pppoe-server-options
    # When logging the contents of the PAP packet, show the password string
    sed -i '/require-pap/a show-password' /etc/ppp/pppoe-server-options
    sed -i 's/login/#login/' /etc/ppp/pppoe-server-options
    sed -i 's/lcp-echo-interval/#lcp-echo-interval/' /etc/ppp/pppoe-server-options
    sed -i 's/lcp-echo-failure/#lcp-echo-failure/' /etc/ppp/pppoe-server-options
}

change_ppp_sh() {
    if [ -f '/lib/netifd/proto/ppp.sh.orig.bak' ]; then
        echo "info: ppp.sh.orig.bak file already exist."
        return 0
    fi
    cp /lib/netifd/proto/ppp.sh /lib/netifd/proto/ppp.sh.orig.bak
    sed -i "/proto_run_command/i __username=\$(echo -e \"\$username\")" /lib/netifd/proto/ppp.sh
    sed -i 's/__username=/\tusername=/' /lib/netifd/proto/ppp.sh
}

edit_network_wan_wan6_unmanaged() {
    uci set network.wan.proto='none'
    uci set network.wan6.proto='none'
    uci commit network
}

add_network_netkeeper() {
    NEWHOST="DESKTOP-$(dd if=/dev/urandom bs=1024 count=1 2>/dev/null | md5sum | cut -c 1-7 | tr a-z A-Z)"
    NEWMAC="$(dd if=/dev/urandom bs=1024 count=1 2>/dev/null | md5sum | sed -e 's/^\(..\)\(..\)\(..\)\(..\)\(..\)\(..\).*$/\1:\2:\3:\4:\5:\6/' -e 's/^\(.\)[13579bdf]/\10/')"

    if [ -n "$(uci -q get network.netkeeper)" ]; then
        echo "info: network.netkeeper has been added."
        return 0
    fi
    uci set network.netkeeper=interface
    if [ -n "$(uci -q get network.wan.device)" ]; then
        # openwrt/openwrt
        uci set network.netkeeper.device="$(uci get network.wan.device)"
    else
        # coolsnowwolf/lede
        uci set network.netkeeper.ifname="$(uci get network.wan.ifname)"
    fi
    uci set network.netkeeper.proto='pppoe'
    uci set network.netkeeper.auto='0'
    uci set network.netkeeper.hostname="$NEWHOST"
    uci set network.netkeeper.macaddr="$NEWMAC"
    uci set network.netkeeper.username='username'
    uci set network.netkeeper.password='password'
    uci set network.netkeeper.keepalive='0'
    uci set network.netkeeper.demand='0'
    uci commit network
}

set_firewall_for_netkeeper() {
    if [ -n "$(uci get firewall.@zone[1].network | grep netkeeper)" ]; then
        echo "info: netkeeper has been added to the firewall."
        return 0
    fi
    uci set firewall.@zone[1].network="$(uci get firewall.@zone[1].network) netkeeper"
    uci commit firewall
}

servers_restart() {
    /etc/init.d/network reload
    /etc/init.d/firewall reload
    /etc/init.d/netkeeper restart
}

command_all() {
    for COMMANDS in change_ppp_options change_pppoe_server_options change_ppp_sh edit_network_wan_wan6_unmanaged add_network_netkeeper set_firewall_for_netkeeper servers_restart; do
        "$COMMANDS"
        sleep 1s
        sync
    done
    exit 0
}

help() {
    echo "usage: $0 [command] --all"
    echo "       change_ppp_options"
    echo "       change_pppoe_server_options"
    echo "       change_ppp_sh"
    echo "       edit_network_wan_wan6_unmanaged"
    echo "       add_network_netkeeper"
    echo "       set_firewall_for_netkeeper"
    echo "       servers_restart"
    exit 0
}

main() {
    if [ "$#" -gt '0' ]; then
        if [ "$1" = '-h' ]; then
            main
        elif [ "$1" = '--help' ]; then
            main
        elif [ "$1" = '--all' ]; then
            set -x
            command_all
        fi
        set -x
        "$@"
    else
        help
    fi
}

main "$@"
