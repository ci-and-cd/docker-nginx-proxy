# docker-nginx-proxy

Proxy for infrastructure services

## certbot usage

Example:
```bash
# Register a new certificate
/usr/bin/certbot certonly --standalone -d example.com

# Multi-domain certificate
/usr/bin/certbot certonly --standalone -d example.com -d example.org

# Renew certificates now
/usr/bin/certbot renew --no-self-upgrade

# auto-renew twice daily
/usr/sbin/crond -fd15
```

## Add modules

see: [Compiling Third-Party Dynamic Modules for NGINX and NGINX Plus](https://www.nginx.com/blog/compiling-dynamic-modules-nginx-plus/)
