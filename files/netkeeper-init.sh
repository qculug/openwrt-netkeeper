#!/bin/sh

change_ppp_options() {
    if [ -f '/etc/ppp/options.bak' ]; then
        echo "info: You may have executed this command."
        return 0
    fi
    cp /etc/ppp/options /etc/ppp/options.bak
    # Change log location, enable debug and show-password
    sed -i "s/\/dev\/null/\/tmp\/pppoe.log/" /etc/ppp/options
    sed -i "s/#debug/debug/" /etc/ppp/options
    echo "show-password" >> /etc/ppp/options
}

change_ppp_sh() {
    if [ -f '/lib/netifd/proto/ppp.sh.bak' ]; then
        echo "info: You may have executed this command."
        return 0
    fi
    cp /lib/netifd/proto/ppp.sh /lib/netifd/proto/ppp.sh.bak
    sed -i "/proto_run_command/i __username=\$(echo -e \"\$username\")" /lib/netifd/proto/ppp.sh
    sed -i 's/__username=/\tusername=/' /lib/netifd/proto/ppp.sh
}

add_network_netkeeper() {
    if [ -n "$(uci get network.netkeeper 2> /dev/null)" ]; then
        echo "info: network.netkeeper has been added, you may have executed this command."
        return 0
    fi
    uci set network.netkeeper=interface
    if [ -n "$(uci get network.wan.device 2> /dev/null)" ]; then
        # openwrt/openwrt
        uci set network.netkeeper.device="$(uci get network.wan.device)"
    else
        # coolsnowwolf/lede
        uci set network.netkeeper.ifname="$(uci get network.wan.ifname)"
    fi
    uci set network.netkeeper.proto='pppoe'
    uci set network.netkeeper.username='username'
    uci set network.netkeeper.password='password'
    uci set network.netkeeper.metric='0'
    uci set network.netkeeper.auto='0'
    uci commit network
}

set_firewall_for_netkeeper() {
    if [ -n "$(uci get firewall.@zone[1].network | grep netkeeper)" ]; then
        echo "info: netkeeper has been added to the firewall, you may have executed this command."
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
    for COMMANDS in change_ppp_options change_ppp_sh add_network_netkeeper set_firewall_for_netkeeper servers_restart; do
        "$COMMANDS"
        sleep 1s
        sync
    done
    exit 0
}

main() {
    echo "usage: $0 [command] --all"
    echo "       change_ppp_options"
    echo "       change_ppp_sh"
    echo "       add_network_netkeeper"
    echo "       set_firewall_for_netkeeper"
    echo "       servers_restart"
    exit 0
}

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
    main
fi
