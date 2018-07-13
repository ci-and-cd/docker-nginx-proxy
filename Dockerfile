
# see: https://github.com/nginxinc/docker-nginx/blob/1.15.0/mainline/alpine/Dockerfile

FROM nginx:1.15.0-alpine


ARG IMAGE_ARG_ALPINE_MIRROR


COPY --chown=root:root docker /


RUN set -ex \
  && echo "http://${IMAGE_ARG_ALPINE_MIRROR:-dl-cdn.alpinelinux.org}/alpine/v3.7/main" > /etc/apk/repositories \
  && echo "http://${IMAGE_ARG_ALPINE_MIRROR:-dl-cdn.alpinelinux.org}/alpine/v3.7/community" >> /etc/apk/repositories \
  && echo "http://${IMAGE_ARG_ALPINE_MIRROR:-dl-cdn.alpinelinux.org}/alpine/edge/testing/" >> /etc/apk/repositories \
  && apk add --update jq shadow socat sudo \
  && usermod -u 1000 nginx \
  && groupmod -g 1000 nginx \
  && echo "nginx ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nginx \
  && chmod 777 /var/run \
  && chown -R nginx:nginx /var/log/nginx \
  && if [ -f /etc/nginx/conf.d/default.conf ]; then rm -f /etc/nginx/conf.d/default.conf; fi \
  && rm -rf /tmp/* /var/cache/apk/*


USER nginx


ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
