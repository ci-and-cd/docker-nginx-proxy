#!/usr/bin/env sh

set -e

echo "USER ${USER}"
echo "ls -la /etc/letsencrypt"
ls -la /etc/letsencrypt
if [ ! -L /etc/letsencrypt/live ]; then
    # /etc/letsencrypt/archive/<domain>/*
    # /etc/letsencrypt/keys/<domain>/cert.pem -> ../../archive/<domain>/cert1.pem
    # /etc/letsencrypt/keys/<domain>/chain.pem -> ../../archive/<domain>/chain1.pem
    # /etc/letsencrypt/keys/<domain>/fullchain.pem -> ../../archive/<domain>/fullchain1.pem
    # /etc/letsencrypt/keys/<domain>/privkey.pem -> ../../archive/<domain>/privkey1.pem

    if [ "${USER}" != "root" ]; then
        sudo ln -s /etc/letsencrypt/keys /etc/letsencrypt/live
        sudo chown nginx:nginx /etc/letsencrypt/live
    else
        ln -s /etc/letsencrypt/keys /etc/letsencrypt/live
        chown nginx:nginx /etc/letsencrypt/live
    fi
fi


if [ "${USER}" != "root" ]; then
    sudo mkdir -p /etc/nginx/certs/live
    sudo cp -Lrf /etc/letsencrypt/live/. /etc/nginx/certs/live/
    sudo chown -R nginx:nginx /etc/nginx/certs/live
else
    mkdir -p /etc/nginx/certs/live/keys
    cp -Lrf /etc/letsencrypt/live/. /etc/nginx/certs/live/
    chown -R nginx:nginx /etc/nginx/certs/live
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
