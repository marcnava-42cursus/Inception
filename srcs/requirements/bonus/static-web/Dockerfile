FROM alpine:3.22.4 AS rbuilder

RUN apk update && apk add --no-cache \
    R \
    R-dev \
    pandoc-cli \
    gcc \
    g++ \
    gfortran \
    make \
    musl-dev \
    linux-headers \
    curl-dev \
    openssl-dev \
    libxml2-dev \
    icu-dev \
    libuv-dev \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    pcre2-dev \
    ca-certificates

RUN R -q -e 'options(Ncpus=max(1, parallel::detectCores())); install.packages("rmarkdown", repos="https://cloud.r-project.org")'

WORKDIR /app
COPY site/  /app/site/
COPY tools/generate_web.R /app/tools/generate_web.R

RUN mkdir -p /out && Rscript /app/tools/generate_web.R /out/index.html

FROM alpine:3.22.4

LABEL author="marcnava"
LABEL email="marcnava@student.42madrid.com"

RUN apk update && apk add --no-cache nginx

RUN mkdir -p /run/nginx /var/www/static-web

COPY --from=rbuilder /out/index.html /var/www/static-web/index.html
COPY conf/default.conf /etc/nginx/http.d/default.conf

EXPOSE 8080
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
