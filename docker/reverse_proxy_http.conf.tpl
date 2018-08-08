
upstream backend_http_<SERVER_NAME> {
  server                      <BACKEND_HOST_PORT>;
}

server {



    listen                    0.0.0.0:<SERVER_PORT>;

    server_name               <SERVER_NAME>;










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
        proxy_set_header      X-Forwarded-Proto $scheme;
        proxy_set_header      X-Real-IP $remote_addr;

        proxy_pass            <SERVER_PROXY_PASS>;



    }
}
