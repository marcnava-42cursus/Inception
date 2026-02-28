FROM alpine:3.23.3

LABEL author="marcnava"
LABEL email="marcnava@student.42madrid.com"

RUN apk update
RUN apk add --no-cache mariadb
RUN apk add --no-cache mariadb-client

RUN mkdir -p /run/mysqld
RUN mkdir -p /var/lib/mysql
RUN chown -R mysql:mysql /run/mysqld
RUN chown -R mysql:mysql /var/lib/mysql

COPY conf/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
COPY tools/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

WORKDIR /var/lib/mysql

EXPOSE 3306

STOPSIGNAL SIGTERM

CMD ["sh", "/usr/local/bin/start.sh"]
