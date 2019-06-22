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
  libjansson-dev \
  libpcre3 \
  libpcre3-dev \
  libssl-dev \
  libtool \
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
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" --add-module=/usr/local/src/headers-more-nginx-module |g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

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
  && sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)"--add-module=/usr/local/src/ngx_http_geoip2_module |g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

## PAGESPEED
  # cd /usr/local/src
  # # Cleaning up in case of update
  # rm -r ngx_pagespeed-${NPS_VER}-beta 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
  # # Download and extract of PageSpeed module
  # echo -ne "       Downloading ngx_pagespeed      [..]\r"
  # wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VER}-beta.zip 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
  # unzip v${NPS_VER}-beta.zip 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
  # rm v${NPS_VER}-beta.zip
  # cd ngx_pagespeed-${NPS_VER}-beta
  # psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
  # [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
  # wget ${psol_url} 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
  # tar -xzvf $(basename ${psol_url}) 2>> /tmp/nginx-autoinstall-error.log 1>> /tmp/nginx-autoinstall-output.log
  # rm $(basename ${psol_url})

#  sed -i 's|--with-ld-opt="$(LDFLAGS)"|--with-ld-opt="$(LDFLAGS)" |g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

#
RUN echo "*** Patch Nginx Additional Modules ***" \
  && NGINX_VERSION=$(nginx -v 2>&1 | nginx -v 2>&1 | cut -d'/' -f2) \
  && sed -i 's|CFLAGS="$CFLAGS -Werror"|#CFLAGS="$CFLAGS -Werror"|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/auto/cc/gcc \
  && sed -i 's|dh_shlibdeps -a|dh_shlibdeps -a --dpkg-shlibdeps-params=--ignore-missing-info|g' /usr/local/src/nginx/nginx-${NGINX_VERSION}/debian/rules

  # NGINX_OPTIONS="
  # --prefix=/etc/nginx \
  # --sbin-path=/usr/sbin/nginx \
  # --conf-path=/etc/nginx/nginx.conf \
  # --error-log-path=/var/log/nginx/error.log \
  # --http-log-path=/var/log/nginx/access.log \
  # --pid-path=/var/run/nginx.pid \
  # --lock-path=/var/run/nginx.lock \
  # --http-client-body-temp-path=/var/cache/nginx/client_temp \
  # --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  # --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  # --user=nginx \
  # --group=nginx \
  # --with-cc-opt=-Wno-deprecated-declarations"
  #
  #
  # NGINX_MODULES="--without-http_ssi_module \
  # --without-http_scgi_module \
  # --without-http_uwsgi_module \
  # --without-http_geo_module \
  # --without-http_split_clients_module \
  # --without-http_memcached_module \
  # --without-http_empty_gif_module \
  # --without-http_browser_module \
  # --with-threads \
  # --with-file-aio \
  # --with-http_ssl_module \
  # --with-http_v2_module \
  # --with-http_mp4_module \
  # --with-http_auth_request_module \
  # --with-http_slice_module \
  # --with-http_stub_status_module \
  # --with-http_realip_module"

  # ARG NGINX_BUILD_CONFIG="\
  #         --prefix=/etc/nginx \
  #         --sbin-path=/usr/sbin/nginx \
  #         --modules-path=/usr/lib/nginx/modules \
  #         --conf-path=/etc/nginx/nginx.conf \
  #         --error-log-path=/var/log/nginx/error.log \
  #         --http-log-path=/var/log/nginx/access.log \
  #         --pid-path=/var/run/nginx.pid \
  #         --lock-path=/var/run/nginx.lock \
  #         --http-client-body-temp-path=/var/cache/nginx/client_temp \
  #         --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  #         --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  #         --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  #         --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  #         --user=nginx \
  #         --group=nginx \
  #         --with-http_ssl_module \
  #         --with-http_realip_module \
  #         --with-http_addition_module \
  #         --with-http_sub_module \
  #         --with-http_dav_module \
  #         --with-http_flv_module \
  #         --with-http_mp4_module \
  #         --with-http_gunzip_module \
  #         --with-http_gzip_static_module \
  #         --with-http_random_index_module \
  #         --with-http_secure_link_module \
  #         --with-http_stub_status_module \
  #         --with-http_auth_request_module \
  #         --with-http_xslt_module=dynamic \
  #         --with-http_image_filter_module=dynamic \
  #         --with-http_geoip_module=dynamic \
  #         --with-threads \
  #         --with-stream \
  #         --with-stream_ssl_module \
  #         --with-stream_ssl_preread_module \
  #         --with-stream_realip_module \
  #         --with-stream_geoip_module=dynamic \
  #         --with-http_slice_module \
  #         --with-mail \
  #         --with-mail_ssl_module \
  #         --with-compat \
  #         --with-file-aio \



# RUN echo "*** Build Nginx ***" \
#   && NGINX_VERSION=$(nginx -v 2>&1 | nginx -v 2>&1 | cut -d'/' -f2) \
#   && cd /usr/local/src/nginx/nginx-${NGINX_VERSION}/ \
#   && apt build-dep nginx -y  \
#   && dpkg-buildpackage -b \
#   && cd /usr/local/src/nginx \
#   && dpkg -i nginx*.deb

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
