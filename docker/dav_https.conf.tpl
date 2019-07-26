
# see: https://github.com/lostintime/nginx-webdav
# see: [Do not set up WebDAV server using nginx](https://brouken.com/2016/11/do-not-set-up-webdav-server-using-nginx/)


server {



    listen                    <SERVER_PORT> ssl http2;
    #listen                    [::]:<SERVER_PORT> ssl http2 ipv6only=on;
    server_name               <SERVER_NAME>;

    # [warn] the "ssl" directive is deprecated, use the "listen ... ssl" directive instead
    #ssl on;
    ssl_certificate           /etc/nginx/certs/live/<SERVER_DOMAIN>/fullchain.pem;
    ssl_certificate_key       /etc/nginx/certs/live/<SERVER_DOMAIN>/privkey.pem;
    ssl_ciphers               HIGH:!kEDH:!ADH:!MD5:@STRENGTH;
    ssl_prefer_server_ciphers on;
    ssl_session_cache         shared:TLSSSL:16m;
    ssl_session_timeout       10m;

    root                      /data/www;
    client_body_temp_path     /data/client_temp;
    dav_methods               PUT DELETE MKCOL COPY MOVE;
    create_full_put_path      on;
    dav_access                group:rw  all:r;
}
