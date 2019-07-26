
upstream backend_https_<SERVER_NAME> {
  server                      <BACKEND_HOST_PORT>;
}

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

    location <SERVER_LOCATION> {

        set $authorization false;
        if ($request_method = GET) { set $authorization <ANONYMOUS_READ>; } # false or $http_authorization
        if ($request_method = HEAD) { set $authorization <ANONYMOUS_READ>; } # false or $http_authorization
        if ($request_method = OPTIONS) { set $authorization <ANONYMOUS_READ>; } # false or $http_authorization
        if ($request_method = DELETE) { set $authorization <ANONYMOUS_WRITE>; } # false or $http_authorization
        if ($request_method = POST) { set $authorization <ANONYMOUS_WRITE>; } # false or $http_authorization
        if ($request_method = PUT) { set $authorization <ANONYMOUS_WRITE>; } # false or $http_authorization
        if ($request_method = CONNECT) { set $authorization <ANONYMOUS_ACCESS>; } # false or $http_authorization
        if ($request_method = TRACE) { set $authorization <ANONYMOUS_ACCESS>; } # false or $http_authorization
        if ($authorization = '') { set $authorization '<AUTH_HEADER>'; }
        if ($authorization = false) { set $authorization $http_authorization; }
        <PROXY_SET_HEADER_AUTHORIZATION>

        proxy_redirect        off;
        # note: not $host:$proxy_port, $proxy_port is backend_port
        proxy_set_header      Host $host:<SERVER_PORT_EXPOSED>;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header      X-Forwarded-Proto "https";
        proxy_set_header      X-Real-IP $remote_addr;

        # Fix move request '502 bad gateway' for upstream WebDAV servers
        # see: https://codeday.me/bug/20181122/398608.html
        # see: https://github.com/viossat/docker-keeweb-webdav/issues/4
        # to avoid 502 Bad Gateway:
        # http://vanderwijk.info/Members/ivo/articles/ComplexSVNSetupFix
        set $destination $http_destination;
        if ($destination ~* ^https(.+)$) { set $destination http$1; }
        proxy_set_header      Destination $destination;

        proxy_pass            <SERVER_PROXY_PASS>;

        #sub_filter "http://<SERVER_NAME>:<SERVER_PORT_EXPOSED>/" "https://<SERVER_NAME>:<SERVER_PORT_EXPOSED>/";
        #sub_filter_once off;
    }
}
