FROM pagespeed/nginx-pagespeed:latest
LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"
#
# Install packages
RUN apk --no-cache add curl bash ca-certificates

# RUN apk --no-cache add php7 php7-fpm php7-mysqli php7-json php7-openssl php7-curl \
#     php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype \
#     php7-mbstring php7-iconv php7-gd php7-pdo php7-bcmath php7-pdo_mysql php7-gd php7-pcntl \
#     php7-posix pcre nginx supervisor curl imagemagick wget unzip vim
#
# # Install IONCUBE
# RUN mkdir -p /tmp/ioncube \
#   && cd /tmp/ioncube \
#   && wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.zip -O /tmp/ioncube/ioncube.zip \
#   && unzip -o -q -j ioncube.zip \
#   && cp -rf /tmp/ioncube/ioncube_loader_lin_$(php -v | head -n1 | cut -d" " -f 2 | cut -d"." -f 1,2 | xargs).so /usr/lib/php7/modules/ \
#   && chmod +x /usr/lib/php7/modules/ioncube_* \
#   && echo "zend_extension = /usr/lib/php7/modules/ioncube_loader_lin_$(php -v | head -n1 | cut -d" " -f 2 | cut -d"." -f 1,2 | xargs).so" >  /etc/php7/conf.d/00-ioncube.ini \
#   && rm -rf /tmp/ioncube/*
#
# # Configure
# COPY rootfs/etc/nginx/nginx.conf /etc/nginx/nginx.conf
# COPY rootfs/etc/nginx/includes/rewrite.conf /etc/nginx/includes/rewrite.conf
# COPY rootfs/etc/php7/conf.d/zz_custom.ini /etc/php7/conf.d/zz_custom.ini
# COPY rootfs/etc/php7/php-fpm.d/www.conf /etc/php7/php-fpm.d/www.conf
# COPY rootfs/etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# COPY rootfs/var/www/html /var/www/html
#
# # Make sure files/folders needed by the processes are accessable when they run under the nobody user
# RUN chown -R nobody.nobody /run \
#  && chown -R nobody.nobody /var/lib/nginx \
#  && chown -R nobody.nobody /var/tmp/nginx \
#  && chown -R nobody.nobody /var/log/nginx \
#  && chown -R nobody.nobody /var/www/html \
#  && chmod 777 /var/www/html

#USER root

RUN echo "**** configure ****"
RUN mkdir -p /var/cache/pagespeed \
&& mkdir -p /var/cache/nginx
COPY rootfs/ /

RUN chmod 777 /xshok-init.sh

WORKDIR /var/www/html

EXPOSE 443


#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is working, check if response header returns 200 code OR die
HEALTHCHECK --interval=5s --timeout=5s CMD [ "200" = "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/)" ] || exit 1

STOPSIGNAL SIGTERM

CMD ["/xshok-init.sh"]
#CMD ["/bin/sleep","10000000"]
