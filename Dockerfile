#FROM pagespeed/nginx-pagespeed:latest
FROM extremeshok/baseimage-alpine:3.10 AS BUILD

LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

RUN \
  echo "**** install nginx ****" \
  && apk-install nginx

RUN \
  echo "**** install bash runtime packages ****" \
  && apk-install \
    bash \
    coreutils \
    curl \
    openssl \
    rsync \
    tzdata


#
# Install packages
RUN apk --no-cache add curl bash ca-certificates

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
