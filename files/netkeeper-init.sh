#!/bin/sh

change_ppp_options() {
    # Change log location, enable debug and show-password
    sed "s/\/dev\/null/\/tmp\/pppoe.log/" /etc/ppp/options -i
    sed "s/#debug/debug/" /etc/ppp/options -i
    echo "show-password" >> /etc/ppp/options
}

install_rp-pppoe_so() {
    #cp /etc/ppp/plugins/rp-pppoe.so /etc/ppp/plugins/rp-pppoe.so.bak
    PPPD_VERSION="$(ls /usr/lib/pppd)"
    cp /usr/lib/pppd/"${PPPD_VERSION}"/rp-pppoe.so /etc/ppp/plugins/rp-pppoe.so
}

add_network_netkeeper() {
    uci set network.netkeeper=interface
    uci set network.netkeeper.device='wan'
    uci set network.netkeeper.proto='pppoe'
    uci set network.netkeeper.username='username'
    uci set network.netkeeper.password='password'
    uci set network.netkeeper.metric='0'
    uci set network.netkeeper.auto='0'
    uci commit network
}

set_firewall_for_netkeeper() {
    uci set firewall.@zone[1].network='$(uci get firewall.@zone[1].network) netkeeper' 
    uci commit firewall
}

servers_restart() {
    /etc/init.d/firewall restart
    /etc/init.d/network reload
    /etc/init.d/network restart
}

enable_rp-pppoe-server() {
    cp /lib/netifd/proto/ppp.sh /lib/netifd/proto/ppp.sh.bak
    sed -i '/proto_run_command/i username=`echo -e "$username"`' /lib/netifd/proto/ppp.sh
}

enable_startup_service_file() {
    /etc/init.d/netkeeper enable
    sleep 5
    (/etc/init.d/netkeeper start &)
}

main() {
    echo "usage: $0 [command]"
    echo "       change_ppp_options"
    echo "       install_rp-pppoe_so"
    echo "       add_network_netkeeper"
    echo "       set_firewall_for_netkeeper"
    echo "       servers_restart"
    echo "       enable_rp-pppoe-server"
    #enable_startup_service_file
    exit 0
}

if [ "$#" -gt '0' ]; then
    if [ "$1" == '-h' ]; then
        main "$@"
    elif [ "$1" == '--help' ]; then
        main "$@"
    fi
    set -x
    "$@"
else
    main "$@"
fi
