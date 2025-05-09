# syntax=docker/dockerfile:1
#
ARG IMAGEBASE=frommakefile
#
FROM ${IMAGEBASE}
#
# php version arg/envvar inherited from alpine-php
# ARG PHPMAJMIN
# ENV \
#     PHPMAJMIN=${PHPMAJMIN}
#
# ARG TTRREPO="https://git.tt-rss.org/fox"
ARG TTRREPO="https://gitlab.tt-rss.org/tt-rss"
ARG VERSION=master
#
ENV \
    TTRSSREPO="${TTRREPO}/tt-rss" \
    TTRSSSRC="/opt/ttrss/ttrss-${VERSION}.tar.gz" \
    TTRSSDIR="/config/www/ttrss"
    # TTRSSREPO="https://git.tt-rss.org/fox/tt-rss.git"
    # TTRSSREPO="https://gitlab.tt-rss.org/tt-rss/tt-rss.git"
#
RUN set -xe \
    && apk add --no-cache --purge -Uu \
        ca-certificates \
        git \
        # libxslt \
        # mysql-client \
        postgresql-client \
        tzdata \
#
        # php${PHPMAJMIN}-apcu \
        php${PHPMAJMIN}-ctype \
        php${PHPMAJMIN}-curl \
        php${PHPMAJMIN}-dom \
        php${PHPMAJMIN}-exif \
        php${PHPMAJMIN}-fileinfo \
        php${PHPMAJMIN}-gd \
        php${PHPMAJMIN}-iconv \
        php${PHPMAJMIN}-intl \
        php${PHPMAJMIN}-json \
        php${PHPMAJMIN}-mbstring \
        # php${PHPMAJMIN}-mysqli \
        # php${PHPMAJMIN}-mysqlnd \
        php${PHPMAJMIN}-opcache \
        php${PHPMAJMIN}-openssl \
        php${PHPMAJMIN}-pcntl \
        php${PHPMAJMIN}-pdo \
        # php${PHPMAJMIN}-pdo_mysql \
        php${PHPMAJMIN}-pdo_pgsql \
        php${PHPMAJMIN}-pecl-apcu \
        php${PHPMAJMIN}-pecl-xdebug \
        php${PHPMAJMIN}-pgsql \
        php${PHPMAJMIN}-phar \
        php${PHPMAJMIN}-posix \
        php${PHPMAJMIN}-session \
        php${PHPMAJMIN}-simplexml \
        php${PHPMAJMIN}-sockets \
        php${PHPMAJMIN}-sodium \
        php${PHPMAJMIN}-tokenizer \
        php${PHPMAJMIN}-xml \
        php${PHPMAJMIN}-xmlwriter \
        php${PHPMAJMIN}-xsl \
        php${PHPMAJMIN}-zip \
        php${PHPMAJMIN}-zlib \
#
    && mkdir -p \
        /defaults \
        $(dirname ${TTRSSSRC}) \
#
    && if [ -f "/etc/php${PHPMAJMIN}/php.ini" ]; then mv /etc/php${PHPMAJMIN}/php.ini /defaults/php.ini; fi \
    && if [ -f "/etc/php${PHPMAJMIN}/php-fpm.conf" ]; then mv /etc/php${PHPMAJMIN}/php-fpm.conf /defaults/php-fpm.conf; fi \
    && if [ -f "/etc/php${PHPMAJMIN}/php-fpm.d/www.conf" ]; then mv /etc/php${PHPMAJMIN}/php-fpm.d/www.conf /defaults/php-fpm-www.conf; fi \
#
# enable to download archived release (no need for git)
    # && curl -o ${TTRSSSRC} -SL "${TTRSSREPO}/archive/${VERSION}.tar.gz" \
#
# enable to shallow clone only specific branch e.g. master
    && git clone --branch ${VERSION} --depth 1 \
        ${TTRSSREPO}.git \
        /tmp/ttrss-${VERSION}/ \
#
# enable to clone whole repo and switch to specific commit
# (detached head but we don't care, rm-rf-ing .git before packing release anyway)
    # && git clone \
    #     ${TTRSSREPO}.git \
    #     /tmp/ttrss-${VERSION}/ \
    # && (cd /tmp/ttrss-${VERSION}/ && git checkout ${VERSION}) \
#
    && ( cd /tmp/ttrss-${VERSION} \
        && echo "$(git rev-parse --abbrev-ref HEAD)@$(git rev-parse --short HEAD)" \
            > $(dirname ${TTRSSSRC})/version ) \
    && rm -rf /tmp/ttrss-${VERSION}/.git \
#
    && git clone --depth=1 \
        ${TTRREPO}/plugins/ttrss-nginx-xaccel.git \
        /tmp/ttrss-${VERSION}/plugins.local/nginx_xaccel \
    && ( cd /tmp/ttrss-${VERSION}/plugins.local/nginx_xaccel \
        && echo "$(git rev-parse --abbrev-ref HEAD)@$(git rev-parse --short HEAD)" \
            > /tmp/ttrss-${VERSION}/plugins.local/nginx_xaccel/version ) \
    && rm -rf /tmp/ttrss-${VERSION}/plugins.local/nginx_xaccel/.git \
#
    && tar -czf ${TTRSSSRC} -C /tmp/ttrss-${VERSION}/ . \
# git is not included by default,
# pass it at runtime in S6_NEEDED_PACKAGES when local plugin updates is required
    && apk del --purge git \
    && rm -rf /var/cache/apk/* /tmp/*
#
COPY root/ /
#
# ${WEBDIR} from alpine-nginx/alpine-php (default: /config/www)
# VOLUME ${TTRSSDIR}/cache/ ${TTRSSDIR}/config.d/ ${TTRSSDIR}/feed-icons/ ${TTRSSDIR}/plugins.local/ ${TTRSSDIR}/templates.local/ ${TTRSSDIR}/themes.local/
#
ENV \
    TTRSS_DB_TYPE="pgsql" \
    TTRSS_PHP_EXECUTABLE="/usr/bin/php${PHPMAJMIN}" \
    TTRSS_PLUGINS="auth_internal, note, nginx_xaccel" \
    TTRSS_NGINX_XACCEL_PREFIX=/ttrss
    # TTRSS_MYSQL_CHARSET="UTF8"

# required at runtime
    # TTRSS_DB_HOST="postgresql"
    # TTRSS_DB_PORT="5432"
    # TTRSS_DB_USER="ttrss"
    # TTRSS_DB_PASS="insecurebydefault"
# disable local-plugin updates with
    # NO_STARTUP_PLUGIN_UPDATES="1"
# disable schema updates with
    # NO_STARTUP_SCHEMA_UPDATES="1"
# ADMIN_USER_* are applied on every startup, if set
#   see classes/UserHelper.php ACCESS_LEVEL_*
#   setting this to -2 would effectively disable built-in admin user
#   unless single user mode is enabled
    # ADMIN_USER_PASS=""
    # ADMIN_USER_ACCESS_LEVEL=""
# AUTO_CREATE_USER_* are applied unless user already exists
    # AUTO_CREATE_USER=""
    # AUTO_CREATE_USER_PASS=""
    # AUTO_CREATE_USER_ACCESS_LEVEL="0"
    # AUTO_CREATE_USER_ENABLE_API=""
# for xdebug
    # XDEBUG_ENABLED=""
    # XDEBUG_HOST=""
    # XDEBUG_PORT="9000"
#
HEALTHCHECK \
    --interval=2m \
    --retries=5 \
    --start-period=5m \
    --timeout=10s \
    CMD \
    wget --quiet --tries=1 --no-check-certificate --spider ${HEALTHCHECK_URL:-"http://localhost:80/ttrss/public.php?op=healthcheck"} || exit 1
#
# ports, entrypoint etc from nginx
# ENTRYPOINT ["/init"]
