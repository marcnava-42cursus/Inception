FROM alpine:3.22.4

LABEL author="marcnava"
LABEL email="marcnava@student.42madrid.com"

ARG DOMAIN_NAME=marcnava.42.fr

RUN apk update
RUN apk add --no-cache nginx
RUN apk add --no-cache openssl

RUN mkdir -p /etc/nginx/ssl
RUN mkdir -p /run/nginx
RUN mkdir -p /var/www/html

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=Inception/CN=${DOMAIN_NAME}"

COPY conf/default.conf /etc/nginx/http.d/default.conf
RUN sed -i "s|__DOMAIN_NAME__|${DOMAIN_NAME}|g" /etc/nginx/http.d/default.conf

EXPOSE 443

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
