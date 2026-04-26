FROM alpine:3.23.3

LABEL author="marcnava"
LABEL email="marcnava@student.42madrid.com"

RUN apk update
RUN apk add --no-cache mariadb-client
RUN apk add --no-cache tzdata

RUN mkdir -p /backups
RUN mkdir -p /var/log

COPY tools/backup.sh /usr/local/bin/backup.sh
COPY tools/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/start.sh

STOPSIGNAL SIGTERM

CMD ["sh", "/usr/local/bin/start.sh"]
