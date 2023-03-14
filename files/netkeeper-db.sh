#!/bin/sh

NETKEEPER_DB_PATH='/usr/lib/netkeeper/netkeeper.db'

help() {
    echo "usage: $0 [command]"
    echo "       next_data"
    echo "       update_password"
    echo "       select_all"
    echo "       delete_all"
    exit 0
}

next_data() {
    sqlite3 "$NETKEEPER_DB_PATH" << EOF
.header on
.mode line
select * from netkeeper order by id limit 1;
EOF
}

update_password() {
    echo -n "Please enter your new password: "
    read -r NEW_PASSWORD
    if [ -n "$NEW_PASSWORD" ]; then
        sqlite3 "$NETKEEPER_DB_PATH" "update netkeeper set password = $NEW_PASSWORD;"
    fi
}

select_all() {
    sqlite3 "$NETKEEPER_DB_PATH" << EOF
.header on
.mode column
select * from netkeeper;
EOF
}

delete_all() {
    echo -n "Are you sure you want to delete all the content in the table? [y/N]"
    read -r DEL_CHOOSE
    case "$DEL_CHOOSE" in
        [yY] | [yY][eE][sS])
            sqlite3 "$NETKEEPER_DB_PATH" "delete from netkeeper;";;
    esac
}

main() {
    if [ "$#" -gt '0' ]; then
        if [ "$1" = '-h' ]; then
            main
        elif [ "$1" = '--help' ]; then
            main
        fi
        set -x
        "$@"
    else
        help
    fi
}

main "$@"
