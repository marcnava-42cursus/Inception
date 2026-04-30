FROM alpine:3.22.4

LABEL author="marcnava"
LABEL email="marcnava@student.42madrid.com"

RUN apk update
RUN apk add --no-cache vsftpd
RUN apk add --no-cache shadow

RUN mkdir -p /var/run/vsftpd/empty
RUN mkdir -p /var/www/html

COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf
COPY tools/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 21 40000-40010

STOPSIGNAL SIGTERM

CMD ["sh", "/usr/local/bin/start.sh"]
