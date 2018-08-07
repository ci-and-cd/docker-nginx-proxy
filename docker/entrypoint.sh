#!/usr/bin/env sh

set -e

echo "whoami $(whoami)"
echo "ls -la /etc/letsencrypt"
ls -la /etc/letsencrypt
if [ ! -L /etc/letsencrypt/live ]; then
    if [ "$(whoami)" != "root" ]; then
        sudo ln -s /etc/letsencrypt/keys /etc/letsencrypt/live
        sudo chown nginx:nginx /etc/letsencrypt/live
    else
        ln -s /etc/letsencrypt/keys /etc/letsencrypt/live
        chown nginx:nginx /etc/letsencrypt/live
    fi
fi

if ([ "$1" == 'sudo' ] && [ "$2" == nginx ]) || [ "$1" == 'nginx' ]; then
    /render.sh "/etc/nginx/conf.d"

    if [ -n "${NONSECUREPORT}" ]; then
        sudo socat TCP-LISTEN:${NONSECUREPORT_EXPOSED:-80},fork TCP:127.0.0.1:${NONSECUREPORT} &
    fi
    if [ -n "${SECUREPORT}" ]; then
        sudo socat TCP-LISTEN:${SECUREPORT_EXPOSED:-443},fork TCP:127.0.0.1:${SECUREPORT} &
    fi

    echo exec "$@"
    exec "$@"
else
    echo exec "$@"
    exec "$@"
fi
