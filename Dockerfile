FROM extremeshok/nginx:latest AS BUILD

LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

ENV DEBIAN_FRONTEND noninteractive

USER root

RUN echo "**** install runtime packages ****" \
  && apt-get update && apt-get install -o Dpkg::Options::="--force-confmiss" -o Dpkg::Options::="--force-confold" -y \
  netcat \
  curl \
  inotify-tools \
  && rm -rf /var/lib/apt/lists/*

COPY rootfs/ /

RUN chmod 777 /xshok-init.sh \
&& chmod 755 /usr/sbin/htpasswd.sh \
&& chmod 755 /xshok-monitor-certs.sh

RUN echo "**** Fetch Latest globalblacklist ****" \
  && curl --compressed --fail --retry 5 -o "/etc/nginx/conf.d/globalblacklist.conf" -z "/etc/nginx/conf.d/globalblacklist.conf" "https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/conf.d/globalblacklist.conf"

WORKDIR /var/www/html

EXPOSE 443

# Configure a healthcheck to validate that everything is working, check if response header returns 200 code OR die
HEALTHCHECK --interval=5s --timeout=5s CMD [ "200" = "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/)" ] || exit 1

STOPSIGNAL SIGTERM

CMD ["/xshok-init.sh"]
#CMD ["/bin/sleep","10000000"]
