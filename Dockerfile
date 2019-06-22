#FROM pagespeed/nginx-pagespeed:latest
FROM nginx:mainline AS BUILD

LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

ENV NPS_VERSION 1.13.35.2-stable
ENV OSSL_VERSION 1.1.1

RUN echo "**** install packages ****" \
  && apt-get update && apt-get install -y \
  autoconf \
  automake \
  build-essential \
  ca-certificates \
  curl \
  dpkg-dev \
  git \
  libcurl4-openssl-dev \
  libgd-dev \
  libjansson-dev \
  libjpeg-dev \
  libjpeg62-turbo-dev \
  libpcre3 \
  libpcre3-dev \
  libpng-dev \
  libssl-dev \
  libtool \
  libwebp-dev \
  libxslt1-dev \
  python-pip \
  tar \
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
  && git clone --recursive https://github.com/openssl/openssl.git \
  && cd openssl \
  && git checkout OpenSSL_1_1_1-stable \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --with-openssl=/usr/local/src/openssl|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "**** Add Nginx Development Kit ****" \
  && cd /usr/local/src \
  && git clone --recursive https://github.com/simplresty/ngx_devel_kit.git \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --with-openssl=/usr/local/src/ngx_devel_kit|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "**** Add set misc ****" \
  && cd /usr/local/src \
  && git clone --recursive https://github.com/openresty/set-misc-nginx-module.git \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --with-openssl=/usr/local/src/set-misc-nginx-module|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "*** Add libbrotli ****" \
  && cd /usr/local/src \
  && git clone https://github.com/bagder/libbrotli.git \
  && cd libbrotli \
  && ./autogen.sh \
  && ./configure \
  && make -j $(nproc) \
  && make install \
  && ldconfig

RUN echo "**** Add Brotli ****" \
  && cd /usr/local/src \
  && git clone --recursive https://github.com/yverry/ngx_brotli.git \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --add-module=/usr/local/src/ngx_brotli|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "**** Add More Headers ****" \
  && cd /usr/local/src \
  && git clone --recursive https://github.com/openresty/headers-more-nginx-module.git \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --add-module=/usr/local/src/headers-more-nginx-module|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "**** Add Upload Progress ****" \
  && cd /usr/local/src \
  && git clone --recursive https://github.com/masterzen/nginx-upload-progress-module.git \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --add-module=/usr/local/src/nginx-upload-progress-module|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "**** Add Cache Purge ****" \
  && cd /usr/local/src \
  && git clone --recursive https://github.com/nginx-modules/ngx_cache_purge.git \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --add-module=/usr/local/src/ngx_cache_purge|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "*** Add libmaxminddb ****" \
  && cd /usr/local/src \
  && git clone --recursive https://github.com/maxmind/libmaxminddb.git \
  && cd libmaxminddb \
  && ./bootstrap \
  && ./configure \
  && make -j $(nproc) \
  && make install \
  && ldconfig

RUN echo "**** Add Geoip2 ****" \
  && cd /usr/local/src \
  && git clone --recursive https://github.com/leev/ngx_http_geoip2_module.git \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --add-module=/usr/local/src/ngx_http_geoip2_module |g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "**** Add pagespeed ****" \
  && pip install lastversion \
  && THISVERSION="$(lastversion apache/incubator-pagespeed-ngx)" \
  && curl --silent -o /tmp/ngx-pagespeed.tar.gz -L "https://github.com/apache/incubator-pagespeed-ngx/archive/v${THISVERSION}-stable.tar.gz" \
  && mkdir -p /usr/local/src/ngx-pagespeed \
  && tar xfz /tmp/ngx-pagespeed.tar.gz -C /usr/local/src/ngx-pagespeed \
  && rm -f /tmp/ngx-pagespeed.tar.gz \
  && mv -f /usr/local/src/ngx-pagespeed/*/* /usr/local/src/ngx-pagespeed \
  && curl --silent -o /tmp/psol.tar.gz -L "https://dl.google.com/dl/page-speed/psol/${THISVERSION}-x64.tar.gz" \
  && tar xfz /tmp/psol.tar.gz -C /usr/local/src/ngx-pagespeed \
  && rm -f /tmp/psol.tar.gz \
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --add-module=/usr/local/src/ngx-pagespeed |g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "*** Patch Nginx Build Config ***" \
  && NGINX_VERSION=$(nginx -v 2>&1 | nginx -v 2>&1 | cut -d'/' -f2) \
  && sed -i 's|CFLAGS="$CFLAGS -Werror"|#CFLAGS="$CFLAGS -Werror"|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/auto/cc/gcc \
  && sed -i 's|dh_shlibdeps -a|dh_shlibdeps -a --dpkg-shlibdeps-params=--ignore-missing-info|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

RUN echo "*** Build Nginx ***" \
  && NGINX_VERSION=$(nginx -v 2>&1 | nginx -v 2>&1 | cut -d'/' -f2) \
  && cd /usr/local/src/nginx/nginx-${NGINX_VERSION}/ \
  && apt build-dep nginx -y  \
  && dpkg-buildpackage -b \
  && cd /usr/local/src/nginx \
  && dpkg -i nginx*.deb

RUN echo "**** configure ****"
RUN mkdir -p /var/cache/pagespeed \
&& mkdir -p /var/cache/nginx
COPY rootfs/ /

RUN echo "**** install runtime packages ****" \
  && apt-get update && apt-get install -y netcat

RUN chmod 777 /xshok-init.sh

WORKDIR /var/www/html

EXPOSE 443

#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is working, check if response header returns 200 code OR die
HEALTHCHECK --interval=5s --timeout=5s CMD [ "200" = "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/)" ] || exit 1

STOPSIGNAL SIGTERM

CMD ["/xshok-init.sh"]
#CMD ["/bin/sleep","10000000"]
