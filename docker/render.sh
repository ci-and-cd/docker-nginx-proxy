#!/usr/bin/env sh

# arguments: server_name, server_port, server_port_exposed, server_resolver, target_directory
function proxy() {
    local server_name="$1"
    local server_port="$2"
    local server_port_exposed="$3"
    local server_resolver="$4"
    local target_directory="$5"
    local target="${target_directory}/proxy_${server_name}.conf"
    local template="proxy_http.conf.tpl"

    (>&2 echo "server_name: ${server_name}")
    (>&2 echo "server_port: ${server_port}")
    (>&2 echo "server_port_exposed: ${server_port_exposed}")
    (>&2 echo "server_resolver: ${server_resolver}")
    (>&2 echo "target_directory: ${target_directory}")
    (>&2 echo "target: ${target}")
    (>&2 echo "template: ${template}")

    if [ "${SKIP_CONF_GENERATION}" == "true" ]; then
        (>&2 echo "skip conf generation.")
        return
    fi

    if [ -f ${target} ] && [ "${OVERWRITE_EXISTING_CONF}" != "true" ]; then
        (>&2 echo "${target} already exists, skip.")
        cat ${target}
        return
    fi

    sed "s#<SERVER_PORT>#${server_port}#" ${template} | \
        sed "s#<SERVER_PORT_EXPOSED>#${server_port_exposed}#" | \
        sed "s#<SERVER_RESOLVER>#${server_resolver}#" | \
        sed "s#<SERVER_NAME>#${server_name}#" > ${target}

    (>&2 echo "${target} content:")
    cat ${target}
}

# arguments: anonymous (access, false, read, write), auth_header, backend_host_port, server_location, server_name, server_port, server_port_exposed, server_protocol, server_proxy_pass, target_directory
function reverse_proxy() {
    local anonymous="$1"
    local auth_header="$2"
    local backend_host_port="$3"
    local server_location="$4"
    local server_name="$5"
    local server_port="$6"
    local server_port_exposed="$7"
    local server_protocol="$8"
    local server_proxy_pass="$9"
    local target_directory="${10}"
    local target="${target_directory}/reverse_proxy_${server_protocol}_${server_name}.conf"
    local template="reverse_proxy_${server_protocol}.conf.tpl"

    (>&2 echo "backend_host_port: ${backend_host_port}")
    (>&2 echo "auth_header: ${auth_header}")
    (>&2 echo "server_location: ${server_location}")
    (>&2 echo "server_name: ${server_name}")
    (>&2 echo "server_port: ${server_port}")
    (>&2 echo "server_port_exposed: ${server_port_exposed}")
    (>&2 echo "server_protocol: ${server_protocol}")
    (>&2 echo "server_proxy_pass: ${server_proxy_pass}")
    (>&2 echo "target_directory: ${target_directory}")
    (>&2 echo "target: ${target}")
    (>&2 echo "template: ${template}")

    local anonymous_access='false'
    local anonymous_read='false'
    local anonymous_write='false'
    if [ "${anonymous}" == "access" ]; then
        anonymous_access='$http_authorization'
        anonymous_read='$http_authorization'
        anonymous_write='$http_authorization'
    elif [ "${anonymous}" == "read" ]; then
        anonymous_read='$http_authorization'
    elif [ "${anonymous}" == "write" ]; then
        anonymous_write='$http_authorization'
    fi

    local server_domain=""
    if [ "${server_protocol}" == "https" ]; then
        # see: https://stackoverflow.com/questions/25204179/removing-subdomain-with-bash
        if [ -z "${SERVER_DOMAIN}" ]; then server_domain=$(expr match "${server_name}" '.*\.\(.*\..*\)'); fi
        if [ -z "${server_domain}" ]; then server_domain="${server_name}"; fi
    fi
    (>&2 echo "server_domain: ${server_domain}")

    (>&2 echo "SKIP_CONF_GENERATION: ${SKIP_CONF_GENERATION}")
    if [ "${SKIP_CONF_GENERATION}" == "true" ]; then
        (>&2 echo "skip conf generation.")
        return
    fi

    (>&2 echo "OVERWRITE_EXISTING_CONF: ${OVERWRITE_EXISTING_CONF}")
    if [ -f ${target} ] && [ "${OVERWRITE_EXISTING_CONF}" != "true" ]; then
        (>&2 echo "${target} already exists, skip.")
        cat ${target}
        return
    fi

    sed "s#<BACKEND_HOST_PORT>#${backend_host_port}#; s#<SERVER_PORT>#${server_port}#" ${template} | \
        sed "s#<ANONYMOUS_ACCESS>#${anonymous_access}#" | \
        sed "s#<ANONYMOUS_READ>#${anonymous_read}#" | \
        sed "s#<ANONYMOUS_WRITE>#${anonymous_write}#" | \
        sed "s#<AUTH_HEADER>#${auth_header}#" | \
        sed "s#<SERVER_PORT_EXPOSED>#${server_port_exposed}#" | \
        sed "s#<SERVER_LOCATION>#${server_location}#" | \
        sed "s#<SERVER_NAME>#${server_name}#" | \
        sed "s#<SERVER_PROXY_PASS>#${server_proxy_pass}#" | \
        sed "s|<SERVER_DOMAIN>|${server_domain}|" > ${target}

    if [ "${anonymous_access}" != "false" ] || [ "${anonymous_read}" != "false" ] || [ "${anonymous_write}" != "false" ]; then
        sed -i 's|<PROXY_SET_HEADER_AUTHORIZATION>|proxy_set_header Authorization $authorization;|' ${target}
    else
        sed -i 's|<PROXY_SET_HEADER_AUTHORIZATION>|#anonymous_access not allowed|' ${target}
    fi

    (>&2 echo "${target} content:")
    cat ${target}
}

# arguments: row
function render_conf() {
    local row="$1"

    _jq() {
     echo ${row} | base64 -d | jq -r ${1}
    }

    local anonymous=$(_jq '.anonymous')
    local backend_host=$(_jq '.host')
    local server_name=$(_jq '.server_name')
    local server_port=$(_jq '.server_port')
    local server_port_exposed=$(_jq '.server_port_exposed')

    local server_mode=""
    if [ "${backend_host}" != "null" ] && [ ! -z "${backend_host}" ]; then
        # reverse_proxy mode
        (>&2 echo "backend_host not null, reverse_proxy mode.")
        server_mode="reverse_proxy"
    else
        # proxy mode
        (>&2 echo "backend_host is null, proxy mode.")
        server_mode="proxy"
    fi

    local server_protocol=$(_jq '.server_protocol')
    if [ "${server_port}" == "null" ] || [ -z "${server_port}" ]; then
        if [ "${server_protocol}" == "http" ]; then
            if [ "${NONSECUREPORT}" == "null" ] || [ -z "${NONSECUREPORT}" ]; then server_port="80"; else server_port="${NONSECUREPORT}"; fi
        elif [ "${server_protocol}" == "https" ]; then
            if [ "${SECUREPORT}" == "null" ] || [ -z "${SECUREPORT}" ]; then server_port="443"; else server_port="${SECUREPORT}"; fi
        else
            server_port="80"
        fi
    fi

    if [ "${server_port_exposed}" == "null" ] || [ -z "${server_port_exposed}" ]; then
        if [ "${server_protocol}" == "http" ]; then
            if [ "${NONSECUREPORT_EXPOSED}" == "null" ] || [ -z "${NONSECUREPORT_EXPOSED}" ]; then server_port_exposed="80"; else server_port_exposed="${NONSECUREPORT_EXPOSED}"; fi
        elif [ "${server_protocol}" == "https" ]; then
            if [ "${SECUREPORT_EXPOSED}" == "null" ] || [ -z "${SECUREPORT_EXPOSED}" ]; then server_port_exposed="443"; else server_port_exposed="${SECUREPORT_EXPOSED}"; fi
        else
            server_port_exposed="80"
        fi
    fi

    if [ "${server_mode}" == "reverse_proxy" ]; then
        local backend_port=$(_jq '.port')
        local backend_protocol=$(_jq '.protocol')
        local basic_auth_pass=$(_jq '.pass')
        local basic_auth_user=$(_jq '.user')
        local server_location=$(_jq '.server_location')
        local server_proxy_pass_context=$(_jq '.server_proxy_pass_context')

        if [ "${anonymous}" == "null" ] || [ -z "${anonymous}" ]; then anonymous="false"; fi
        if [ "${backend_port}" == "null" ] || [ -z "${backend_port}" ]; then backend_port="8081"; fi
        if [ "${backend_protocol}" == "null" ] || [ -z "${backend_protocol}" ]; then backend_protocol="http"; fi

        local auth_header=""
        if [ "${basic_auth_pass}" != "null" ] && [ ! -z "${basic_auth_pass}" ] && [ "${basic_auth_user}" != "null" ] && [ ! -z "${basic_auth_user}" ]; then
            auth_header="Basic $(echo -ne "${basic_auth_user}:${basic_auth_pass}" | base64)";
        fi

        if [ "${server_location}" == "null" ] || [ -z "${server_location}" ]; then server_location="/"; fi
        if [ "${server_name}" == "null" ] || [ -z "${server_name}" ]; then server_name="nexus"; fi
        if [ "${server_protocol}" == "null" ] || [ -z "${server_protocol}" ]; then server_protocol="http"; fi

        local server_proxy_pass="${backend_protocol}://backend_${server_protocol}_${server_name}"
        if [ "${server_proxy_pass_context}" != "null" ] && [ ! -z "${server_proxy_pass_context}" ]; then server_proxy_pass="${server_proxy_pass}${server_proxy_pass_context}"; fi

        (>&2 echo "anonymous: ${anonymous}")
        (>&2 echo "backend_host: ${backend_host}, backend_port: ${backend_port}, backend_protocol: ${backend_protocol}")
        (>&2 echo "auth_header: ${auth_header}")
        (>&2 echo "server_location: ${server_location}")
        (>&2 echo "server_name: ${server_name}")
        (>&2 echo "server_port: ${server_port}")
        (>&2 echo "server_port_exposed: ${server_port_exposed}")
        (>&2 echo "server_protocol: ${server_protocol}")
        (>&2 echo "server_proxy_pass: ${server_proxy_pass}")
        (>&2 echo "TARGET_DIRECTORY: ${TARGET_DIRECTORY}")

        reverse_proxy "${anonymous}" "${auth_header}" "${backend_host}:${backend_port}" "${server_location}" "${server_name}" "${server_port}" "${server_port_exposed}" "${server_protocol}" "${server_proxy_pass}" "${TARGET_DIRECTORY}"
    else
        if [ "${server_name}" == "null" ] || [ -z "${server_name}" ]; then server_name="*"; fi
        local server_resolver=$(cat /etc/resolv.conf | grep -i nameserver | head -n1 | cut -d ' ' -f2)

        (>&2 echo "server_name: ${server_name}")
        (>&2 echo "server_port: ${server_port}")
        (>&2 echo "server_port_exposed: ${server_port_exposed}")
        (>&2 echo "server_resolver: ${server_resolver}")
        (>&2 echo "TARGET_DIRECTORY: ${TARGET_DIRECTORY}")

        proxy "${server_name}" "${server_port}" "${server_port_exposed}" "${server_resolver}" "${TARGET_DIRECTORY}"
    fi
}


TARGET_DIRECTORY="$1"

echo NGINX_PROXY_CONFIG: ${NGINX_PROXY_CONFIG}
echo TARGET_DIRECTORY: ${TARGET_DIRECTORY}

if [ "${OVERWRITE_EXISTING_CONF}" == "true" ]; then
    (>&2 echo "rm -rf ${TARGET_DIRECTORY}/*.conf")
    rm -rf ${TARGET_DIRECTORY}/*.conf
fi

for row in $(echo "${NGINX_PROXY_CONFIG}" | jq -r '.[] | @base64'); do
    render_conf "${row}"
done
