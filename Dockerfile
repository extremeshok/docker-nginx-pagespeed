FROM extremeshok/nginx-pagespeed-build:latest AS BUILD

LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

FROM nginx:mainline AS BASE

ENV DEBIAN_FRONTEND noninteractive

RUN echo "**** install runtime packages ****" \
  && apt-get update && apt-get install -y netcat \
  && rm -rf /var/lib/apt/lists/*

ENV BUILD_DIR=/usr/local/src/nginx
ENV DEST_DIR=/tmp/build

USER root

RUN mkdir -p $DEST_DIR

COPY --from=BUILD $BUILD_DIR $DEST_DIR

RUN cd $DEST_DIR \
&& dpkg -i nginx*.deb

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
