#ddev-generated
ARG FRANKENPHP_DOCKER_IMAGE=scratch
FROM ${FRANKENPHP_DOCKER_IMAGE}

SHELL ["/bin/bash", "-eu", "-o", "pipefail", "-c"]

# Add a new user and give it ownership of frankenphp related files
ARG username
ARG uid
ARG gid
RUN <<EOF
    getent group tty || groupadd tty
    (groupadd --gid $gid "$username" || groupadd "$username" || true) && (useradd -G tty -l -m -s "/bin/bash" --gid "$username" --comment '' --uid $uid "$username" || useradd -G tty -l -m -s "/bin/bash" --gid "$username" --comment '' "$username" || useradd  -G tty -l -m -s "/bin/bash" --gid "$gid" --comment '' "$username" || useradd -G tty -l -m -s "/bin/bash" --comment '' $username )
    setcap -r /usr/local/bin/frankenphp
    chown -R ${username}:${username} /data/caddy /config/caddy
EOF

RUN (apt-get update || true) && apt-get install -y --no-install-recommends sudo \
    && rm -rf /var/lib/apt/lists/*

# CAROOT for `mkcert` to use, has the CA config
ENV CAROOT=/mnt/ddev-global-cache/mkcert
# Give the `${username}` user full `sudo` privileges
RUN mkdir -p /etc/sudoers.d && echo "${username} ALL=(ALL) NOPASSWD: ALL" >> "/etc/sudoers.d/${username}" && chmod 0440 "/etc/sudoers.d/${username}"
# Install the correct architecture binary of `mkcert`
ARG TARGETARCH
RUN mkdir -p /usr/local/bin && curl --fail -JL -s -o /usr/local/bin/mkcert "https://dl.filippo.io/mkcert/latest?for=linux/${TARGETARCH}" && chmod +x /usr/local/bin/mkcert

# Install PHP extensions provided by user
# Always install xdebug, but disable it by default
ARG FRANKENPHP_PHP_EXTENSIONS=""
RUN install-php-extensions xdebug ${FRANKENPHP_PHP_EXTENSIONS} && rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Enable xdebug on demand with custom DDEV config
ARG FRANKENPHP_XDEBUG=false
RUN <<EOF
    if [ "${FRANKENPHP_XDEBUG}" = "true" ]; then
        {
            echo "zend_extension=xdebug.so";
            echo "xdebug.client_host=host.docker.internal";
            echo "xdebug.discover_client_host=1";
            echo "xdebug.client_port=9003";
            echo "xdebug.mode=debug,develop";
            echo "xdebug.start_with_request=yes";
            echo "xdebug.max_nesting_level=1000";
        } > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;
    fi
EOF

# Run FrankenPHP under created user
USER ${username}
