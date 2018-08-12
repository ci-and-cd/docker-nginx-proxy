
# see: https://github.com/nginxinc/docker-nginx/blob/1.15.0/mainline/alpine/Dockerfile

FROM nginx:1.15.0-alpine


ARG IMAGE_ARG_ALPINE_MIRROR


COPY --chown=root:root docker /


RUN set -ex \
  && echo "http://${IMAGE_ARG_ALPINE_MIRROR:-dl-cdn.alpinelinux.org}/alpine/v3.7/main" > /etc/apk/repositories \
  && echo "http://${IMAGE_ARG_ALPINE_MIRROR:-dl-cdn.alpinelinux.org}/alpine/v3.7/community" >> /etc/apk/repositories \
  && echo "http://${IMAGE_ARG_ALPINE_MIRROR:-dl-cdn.alpinelinux.org}/alpine/edge/testing/" >> /etc/apk/repositories \
  && apk add --no-cache --update certbot jq shadow socat sudo \
  && usermod -u 1000 nginx \
  && groupmod -g 1000 nginx \
  && echo "nginx ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nginx \
  && chmod 777 /var/run \
  && chown -R nginx:nginx /var/cache/nginx /var/log/nginx \
  && if [ -f /etc/nginx/conf.d/default.conf ]; then rm -f /etc/nginx/conf.d/default.conf; fi \
  && chown -R nginx:nginx /etc/nginx/conf.d \
  && ln -s /etc/letsencrypt /etc/nginx/certs \
  && rm -rf /tmp/* /var/cache/apk/*


USER nginx

# /etc/letsencrypt/archive and /etc/letsencrypt/keys contain all previous keys and certificates
# During the renewal /etc/letsencrypt/live symlinks to the latest versions
VOLUME ["/etc/letsencrypt/archive", "/etc/letsencrypt/keys", "/etc/nginx/conf.d", "/var/cache/nginx", "/var/log/letsencrypt", "/var/log/nginx"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["sudo", "nginx", "-g", "daemon off;"]
