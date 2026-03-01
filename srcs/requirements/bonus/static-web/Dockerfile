FROM alpine:3.23.3 AS rbuilder

RUN apk update
RUN apk add --no-cache R

COPY tools/generate_web.R /tmp/generate_web.R
RUN mkdir -p /out
RUN Rscript /tmp/generate_web.R /out/index.html

FROM alpine:3.23.3

LABEL author="marcnava"
LABEL email="marcnava@student.42madrid.com"

RUN apk update
RUN apk add --no-cache nginx

RUN mkdir -p /run/nginx
RUN mkdir -p /var/www/static-web

COPY --from=rbuilder /out/index.html /var/www/static-web/index.html
COPY conf/default.conf /etc/nginx/http.d/default.conf

EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
