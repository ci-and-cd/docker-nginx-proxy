#!/usr/bin/env sh

set -e

echo "USER $(whoami)"
if [ -d /etc/letsencrypt ]; then
    echo "find /etc/letsencrypt"
    find /etc/letsencrypt
fi

if ([ "$1" == 'sudo' ] && [ "$2" == nginx ]) || [ "$1" == 'nginx' ]; then

    if [ -d /etc/letsencrypt ]; then
        # /etc/letsencrypt/archive/<domain>/*
        # /etc/letsencrypt/live/<domain>/cert.pem -> ../../archive/<domain>/cert1.pem
        # /etc/letsencrypt/live/<domain>/chain.pem -> ../../archive/<domain>/chain1.pem
        # /etc/letsencrypt/live/<domain>/fullchain.pem -> ../../archive/<domain>/fullchain1.pem
        # /etc/letsencrypt/live/<domain>/privkey.pem -> ../../archive/<domain>/privkey1.pem
        if [ "$(whoami)" != "root" ]; then
            sudo chown -R root:1000 /etc/letsencrypt
            sudo chmod -R g+rx /etc/letsencrypt
            sudo find /etc/letsencrypt -type f -name 'priv*.pem' -exec sudo chmod g=rw,u=r,o= {} \;
        else
            chown -R root:1000 /etc/letsencrypt
            chmod -R g+rx /etc/letsencrypt
            find /etc/letsencrypt -type f -name 'priv*.pem' -exec sudo chmod g=rw,u=r,o= {} \;
        fi
    fi

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
