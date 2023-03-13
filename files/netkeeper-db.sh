#!/bin/sh

NETKEEPER_DB_PATH='/usr/lib/netkeeper/netkeeper.db'

help() {
    echo "usage: $0 [command]"
    echo "       next_data"
    echo "       select_all"
    echo "       delete_all"
    exit 0
}

next_data() {
    sqlite3 "$NETKEEPER_DB_PATH" << EOF
.header on
.mode line
SELECT * FROM netkeeper ORDER BY id LIMIT 1;
EOF

}
select_all() {
    sqlite3 "$NETKEEPER_DB_PATH" "select * from netkeeper;"
}

delete_all() {
    sqlite3 "$NETKEEPER_DB_PATH" "delete from netkeeper;"
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
