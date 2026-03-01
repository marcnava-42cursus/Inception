FROM alpine:3.23.3

LABEL author="marcnava"
LABEL email="marcnava@student.42madrid.com"

ARG ADMINER_VERSION=5.4.2

RUN apk update && apk add --no-cache php83 php83-session php83-mysqli curl
RUN mkdir -p /var/www/adminer
RUN curl -fsSL "https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php" -o /var/www/adminer/index.php

EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["php83", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]
