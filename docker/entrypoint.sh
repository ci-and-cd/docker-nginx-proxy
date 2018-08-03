#!/usr/bin/env sh

set -e

if [ ! -L /etc/letsencrypt/live ]; then ln -s /etc/letsencrypt/keys /etc/letsencrypt/live; fi

if [ "$1" == 'nginx' ]; then
    /render.sh "/etc/nginx/conf.d"

    if [ -n "${NONSECUREPORT}" ]; then
        sudo socat TCP-LISTEN:${NONSECUREPORT_EXPOSED:-80},fork TCP:127.0.0.1:${NONSECUREPORT} &
    fi
    if [ -n "${SECUREPORT}" ]; then
        sudo socat TCP-LISTEN:${SECUREPORT_EXPOSED:-443},fork TCP:127.0.0.1:${SECUREPORT} &
    fi

    exec "$@"
else
    exec "$@"
fi
