#FROM pagespeed/nginx-pagespeed:latest
FROM nginx:mainline AS BUILD

LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

ENV NPS_VERSION 1.13.35.2-stable
ENV OSSL_VERSION 1.1.1

RUN echo "**** install packages ****" \
  && apt-get update && apt-get install -y \
  build-essential \
  dpkg-dev \
  git \
  libcurl4-openssl-dev \
  libjansson-dev \
  libpcre3 \
  libpcre3-dev \
  unzip \
  uuid-dev \
  wget \
  zlib1g-dev


RUN  echo "**** Add Nginx Repo ****" \
  && CODENAME=$(grep -Po 'VERSION="[0-9]+ \(\K[^)]+' /etc/os-release) \
  && wget http://nginx.org/keys/nginx_signing.key \
  && apt-key add nginx_signing.key \
  && echo "deb http://nginx.org/packages/mainline/debian/ ${CODENAME} nginx" >> /etc/apt/sources.list \
  && echo "deb-src http://nginx.org/packages/mainline/debian/ ${CODENAME} nginx" >> /etc/apt/sources.list \
  && apt-get update

RUN echo "**** Prepare Nginx ****" \
  && mkdir -p /usr/local/src/nginx && cd /usr/local/src/nginx/ \
  && apt source nginx

RUN echo "**** Add OpenSSL 1.1.1 ****" \
  && cd /usr/local/src \
  && git clone https://github.com/openssl/openssl.git \
  && cd openssl \
  && git checkout OpenSSL_1_1_1-stable

RUN echo "**** Add Brotli ****" \
  && cd /usr/local/src \
  && git clone --recursive https://github.com/yverry/ngx_brotli.git

RUN echo "*** Patch Nginx for OpenSSL and Brotli ***" \
  && NGINX_VERSION=$(nginx -v 2>&1 | nginx -v 2>&1 | cut -d'/' -f2) \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --with-openssl=/usr/local/src/openssl --add-module=/usr/local/src/ngx_brotli|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules \
  && sed -i 's|dh_shlibdeps -a|dh_shlibdeps -a --dpkg-shlibdeps-params=--ignore-missing-info|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules \
  && sed -i 's|CFLAGS="$CFLAGS -Werror"|#CFLAGS="$CFLAGS -Werror"|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/auto/cc/gcc

RUN echo "*** Build Nginx ***" \
  && NGINX_VERSION=$(nginx -v 2>&1 | nginx -v 2>&1 | cut -d'/' -f2) \
  && cd /usr/local/src/nginx/nginx-${NGINX_VERSION}/ \
  && apt build-dep nginx -y  \
  && dpkg-buildpackage -b \
  && cd /usr/local/src/nginx \
  && dpkg -i nginx*.deb

# cd /usr/local/src/nginx/nginx-1.17.0/
# apt build-dep nginx -y && dpkg-buildpackage -b
# NGINX_VERSION=$(nginx -v 2>&1 | nginx -v 2>&1 | cut -d'/' -f2)
#
# RUN apt-get build-dep -y nginx=${NGINX_VERSION}-1


RUN echo "**** configure ****"
RUN mkdir -p /var/cache/pagespeed \
&& mkdir -p /var/cache/nginx
COPY rootfs/ /

RUN chmod 777 /xshok-init.sh

WORKDIR /var/www/html

EXPOSE 443

#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is working, check if response header returns 200 code OR die
#HEALTHCHECK --interval=5s --timeout=5s CMD [ "200" = "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/)" ] || exit 1

STOPSIGNAL SIGTERM

#CMD ["/xshok-init.sh"]
CMD ["/bin/sleep","10000000"]
