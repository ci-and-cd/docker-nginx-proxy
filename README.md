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
