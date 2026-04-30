FROM alpine:3.22.4

LABEL author="marcnava"
LABEL email="marcnava@student.42madrid.com"

ARG WP_VERSION=6.5.5

RUN apk update
RUN apk add --no-cache curl
RUN apk add --no-cache tar
RUN apk add --no-cache mariadb-client
RUN apk add --no-cache php83 php83-fpm php83-mysqli php83-curl php83-dom php83-exif
RUN apk add --no-cache php83-fileinfo php83-gd php83-mbstring php83-openssl php83-phar
RUN apk add --no-cache php83-session php83-xml php83-zip
RUN apk add --no-cache php83-ctype
RUN apk add --no-cache php83-tokenizer
RUN apk add --no-cache php83-pecl-redis
RUN apk add --no-cache su-exec
RUN ln -sf /usr/bin/php83 /usr/bin/php

RUN mkdir -p /var/www/html
RUN mkdir -p /run/php

RUN curl -fsSL "https://wordpress.org/wordpress-${WP_VERSION}.tar.gz" -o /tmp/wordpress.tar.gz
RUN tar -xzf /tmp/wordpress.tar.gz -C /tmp
RUN cp -a /tmp/wordpress/. /var/www/html/
RUN rm -rf /tmp/wordpress /tmp/wordpress.tar.gz

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp

RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php83/php-fpm.d/www.conf
RUN sed -i 's|^;clear_env = no|clear_env = no|' /etc/php83/php-fpm.d/www.conf

RUN chown -R nobody:nobody /var/www/html

COPY tools/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

WORKDIR /var/www/html

EXPOSE 9000

STOPSIGNAL SIGTERM

CMD ["sh", "/usr/local/bin/start.sh"]
