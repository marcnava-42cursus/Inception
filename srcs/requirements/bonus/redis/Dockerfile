FROM alpine:3.22.4

LABEL author="marcnava"
LABEL email="marcnava@student.42madrid.com"

RUN apk update
RUN apk add --no-cache redis

COPY conf/redis.conf /etc/redis.conf

EXPOSE 6379

STOPSIGNAL SIGTERM

CMD ["redis-server", "/etc/redis.conf"]
