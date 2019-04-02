#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
## enable case insensitve matching
shopt -s nocaseglob

# if [ ! -z "$PHP_EXTRA_EXTENSIONS" ] ; then
#   for extension in ${PHP_EXTRA_EXTENSIONS//,/ } ; do
#     extension="${extension#php7-}"
#     extension=${extension#php-}
#     echo "Installing php extension: ${extension}"
#     apk-install "php-${extension}@php"
#   done
# fi

NGINX_DOMAINS=${NGINX_DOMAINS:-$HOSTNAME}

NGINX_DISABLE_REWRITES=${NGINX_DISABLE_REWRITES:-no}
NGINX_DISABLE_PAGESPEED=${NGINX_DISABLE_PAGESPEED:-no}
NGINX_DISABLE_GEOIP=${NGINX_DISABLE_GEOIP:-no}
NGINX_DISABLE_PHP=${NGINX_DISABLE_PHP:-no}
NGINX_PHP_FPM_HOST=${NGINX_PHP_FPM_HOST:-phpfpm}
NGINX_PHP_FPM_PORT=${NGINX_PHP_FPM_PORT:-9000}
NGINX_REDIRECT_WWW_TO_NON=${NGINX_REDIRECT_WWW_TO_NON:-yes}
NGINX_MAX_UPLOAD_SIZE=${NGINX_MAX_UPLOAD_SIZE:-32}

NGINX_WORDPRESS=${NGINX_WORDPRESS:-no}
NGINX_WORDPRESS_SUPERCACHE=${NGINX_WORDPRESS_SUPERCACHE:-no}
NGINX_WORDPRESS_CACHEENABLER=${NGINX_WORDPRESS_CACHEENABLER:-no}

echo "#### Nginx Generating Configs ####"
if [ -w "/etc/nginx/conf.d/" ] && [ -w "/etc/nginx/modules/" ] && [ -w "/etc/nginx/include.d/" ] && [ -w "/etc/nginx/server.d/" ] ; then

  # NGINX_MAX_UPLOAD_SIZE
  NGINX_MAX_UPLOAD_SIZE=${NGINX_MAX_UPLOAD_SIZE%%m}
  echo "client_max_body_size ${NGINX_MAX_UPLOAD_SIZE}m;" > /etc/nginx/conf.d/max_upload_size.conf

  if [ "$NGINX_DISABLE_GEOIP" == "yes" ] || [ "$NGINX_DISABLE_GEOIP" == "true" ] || [ "$NGINX_DISABLE_GEOIP" == "on" ] || [ "$NGINX_DISABLE_GEOIP" == "1" ] ; then
    echo "GEOIP Disabled"
    mv -f /etc/nginx/modules/http_geoip.conf /etc/nginx/modules/http_geoip.disabled
    mv -f /etc/nginx/conf.d/geoip.conf /etc/nginx/conf.d/geoip.disabled
  else
    if [ -f "/etc/nginx/modules/http_geoip.disabled" ] ; then
      mv -f /etc/nginx/modules/http_geoip.disabled /etc/nginx/modules/http_geoip.conf
    fi
    if [ -f "/etc/nginx/conf.d/geoip.disabled" ] ; then
      mv -f /etc/nginx/conf.d/geoip.disabled /etc/nginx/conf.d/geoip.conf
    fi
  fi
  if [ "$NGINX_DISABLE_PAGESPEED" == "yes" ] || [ "$NGINX_DISABLE_PAGESPEED" == "true" ] || [ "$NGINX_DISABLE_PAGESPEED" == "on" ] || [ "$NGINX_DISABLE_PAGESPEED" == "1" ] ; then
    echo "Pagespeed Disabled"
    mv -f /etc/nginx/conf.d/pagespeed.conf /etc/nginx/conf.d/pagespeed.disabled
    mv -f /etc/nginx/include.d/pagespeed.conf /etc/nginx/include.d/pagespeed.disabled
  else
    if [ -f "/etc/nginx/conf.d/pagespeed.disabled" ] ; then
      mv -f /etc/nginx/conf.d/pagespeed.disabled /etc/nginx/conf.d/pagespeed.conf
    fi
    if [ -f "/etc/nginx/include.d/pagespeed.disabled" ] ; then
      mv -f /etc/nginx/include.d/pagespeed.disabled /etc/nginx/include.d/pagespeed.conf
    fi
  fi
  if [ "$NGINX_DISABLE_PHP" == "yes" ] || [ "$NGINX_DISABLE_PHP" == "true" ] || [ "$NGINX_DISABLE_PHP" == "on" ] || [ "$NGINX_DISABLE_PHP" == "1" ] ; then
    echo "PHP Disabled"
    mv -f /etc/nginx/conf.d/php_upstream.conf /etc/nginx/conf.d/php_upstream.disabled
  else
    if [ -f "/etc/nginx/conf.d/php_upstream.disabled" ] ; then
      rm -f /etc/nginx/conf.d/php_upstream.disabled
    fi
    cat << EOF > /etc/nginx/conf.d/php_upstream.conf
upstream php_upstream {
zone php_upstream_zone 128k;
server ${NGINX_PHP_FPM_HOST}:${NGINX_PHP_FPM_PORT};
keepalive 2;
}
EOF
  fi
  if [ "$NGINX_WORDPRESS" == "yes" ] || [ "$NGINX_WORDPRESS" == "true" ] || [ "$NGINX_WORDPRESS" == "on" ] || [ "$NGINX_WORDPRESS" == "1" ] ; then
    if [ -f "/etc/nginx/conf.d/wordpress.disabled" ] ; then
      mv -f /etc/nginx/conf.d/wordpress.disabled /etc/nginx/conf.d/wordpress.conf
    fi
  else
    echo "Wordpress Enabled"
    mv -f /etc/nginx/conf.d/wordpress.conf /etc/nginx/conf.d/wordpress.disabled
  fi
fi


for myhostnames in ${NGINX_DOMAINS//\;/ } ; do
  echo "${myhostnames}"
  primary_hostname="${myhostnames%%,*}"
  secondary_hostnames="${myhostnames#*,}"

  if [ "$secondary_hostnames" != "" ] && [ "$secondary_hostnames" != " " ]; then
    if [ "$NGINX_REDIRECT_WWW_TO_NON" == "yes" ] || [ "$NGINX_REDIRECT_WWW_TO_NON" == "true" ] || [ "$NGINX_REDIRECT_WWW_TO_NON" == "on" ] || [ "$NGINX_REDIRECT_WWW_TO_NON" == "1" ] ; then
      primary_hostname="${primary_hostname/www.}"
      secondary_hostnames="${secondary_hostnames/www.}"
      secondary_hostnames=",${secondary_hostnames},"
      secondary_hostnames="${secondary_hostnames/,${primary_hostname},}"
      secondary_hostnames="${secondary_hostnames/#,}"
      secondary_hostnames="${secondary_hostnames/%,}"
    else
      primary_hostname="${HOSTNAME}"
      secondary_hostnames=",${secondary_hostnames},"
      secondary_hostnames="${secondary_hostnames/,www.${primary_hostname},}"
      secondary_hostnames="${secondary_hostnames/,${primary_hostname},}"
      secondary_hostnames="${secondary_hostnames/#,}"
      secondary_hostnames="${secondary_hostnames/%,}"
    fi
    secondary_hostnames="${secondary_hostnames/\,/ }"
  fi



  # if [ "$PHP_REDIS_SESSIONS" == "yes" ] || [ "$PHP_REDIS_SESSIONS" == "true" ] || [ "$PHP_REDIS_SESSIONS" == "on" ] || [ "$PHP_REDIS_SESSIONS" == "1" ] ; then
  #   PHP_REDIS_HOST=${PHP_REDIS_HOST:-redis}
  #   PHP_REDIS_PORT=${PHP_REDIS_PORT:-6379}
  #
  #   echo "Enabling redis sessions"
  #   cat << EOF > /etc/php7/conf.d/zz-redis.ini
  #   session.save_handler = redis
  #   session.save_path = "tcp://${PHP_REDIS_HOST}:${PHP_REDIS_PORT}"
  # EOF
  #
  #   # wait for redis to start
  #   while ! echo PING | nc ${PHP_REDIS_HOST} ${PHP_REDIS_PORT} ; do
  #     echo "waiting for redis ${PHP_REDIS_HOST}:${PHP_REDIS_PORT}"
  #     sleep 5s
  #   done
  # fi

  echo "#### Nginx SSL requirements ####"
  if [ -d "/certs" ] && [ -w "/certs/" ] ; then
    if [ ! -f "/certs/dhparam.pem" ] ; then
      echo "==== Generating 4096 dhparam ===="
      openssl dhparam -out /certs/dhparam.pem 4096
      chmod 644 /certs/dhparam.pem
    fi
    if [ -r "/certs/${primary_hostname}/fullchain.pem" ] && [ -r "/certs/${primary_hostname}/privkey.pem" ] && [ -r "/certs/${primary_hostname}/chain.pem" ] ; then
      echo "==== Detected ${primary_hostname}: fullchain,privkey,chain ===="
    elif [ -r "/certs/cert.pem" ] && [ -r "/certs/privkey.pem" ] ; then
      echo "==== Detected: /certs: cert,privkey ===="
    else
      echo "==== Generating Self-signed certificate and key ===="
      openssl genrsa -des3 -passout pass:x -out /certs/server.pass.key 2048
      openssl rsa -passin pass:x -in /certs/server.pass.key -out /certs/privkey.pem
      rm -f /certs/server.pass.key
      openssl req -new -key /certs/privkey.pem -out /certs/server.csr -subj "/C=UK/ST=Warwickshire/L=Leamington/O=OrgName/OU=IT Department/CN=${primary_hostname}"
      openssl x509 -req -days 3650 -in /certs/server.csr -signkey /certs/privkey.pem -out /certs/cert.pem
      rm -f /certs/server.csr
      chmod 644 /certs/cert.pem
      chmod 644 /certs/privkey.pem

      if [ ! -r "/certs/cert.pem" ] || [ ! -r "/certs/privkey.pem" ] ; then
        echo "Failure: Generating certificate"
        sleep 60
        exit 1
      fi
    fi
  else
    while ! [ -r "/certs/dhparam.pem" ] ; do
      echo "Waiting for dhparam (/certs/dhparam.pem) to be provisioned..."
      sleep 3
    done
    while ! [ -r "/certs/${primary_hostname}/fullchain.pem" ] ; do
      echo "Waiting for certs (/certs/${primary_hostname}/fullchain.pe) to be provisioned..."
      sleep 3
    done
    while ! [ -r "/certs/${primary_hostname}/privkey.pem" ] ; do
      echo "Waiting for certs (/certs/${primary_hostname}/privkey.pem) to be provisioned..."
      sleep 3
    done
  fi

if ! grep -q "BEGIN DH PARAMETERS" /certs/dhparam.pem || ! grep -q "END DH PARAMETERS" /certs/dhparam.pem ; then
  echo "ERROR: Invalid DHPARAM /certs/dhparam.pem"
  sleep 60
  exit 1
fi


  echo "#### Nginx Generating Configs ####"
  if [ -w "/etc/nginx/conf.d/" ] && [ -w "/etc/nginx/modules/" ] && [ -w "/etc/nginx/include.d/" ] && [ -w "/etc/nginx/server.d/" ] ; then
    echo "#### Generating Nginx Domain config for ${primary_hostname} ####"
    echo "# $(date)" > "/etc/nginx/server.d/${primary_hostname}.conf"
    if [ "$NGINX_REDIRECT_WWW_TO_NON" == "yes" ] || [ "$NGINX_REDIRECT_WWW_TO_NON" == "true" ] || [ "$NGINX_REDIRECT_WWW_TO_NON" == "on" ] || [ "$NGINX_REDIRECT_WWW_TO_NON" == "1" ] ; then
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
########################## www httpS (443) to non-www https (443)  ##########################
server {
listen 443 ssl http2;
server_name www.${primary_hostname};
EOF
      if [ -r "/certs/${primary_hostname}/fullchain.pem" ] && [ -r "/certs/${primary_hostname}/privkey.pem" ] && [ -r "/certs/${primary_hostname}/chain.pem" ] ; then
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
ssl_certificate /certs/${primary_hostname}/fullchain.pem;
ssl_certificate_key /certs/${primary_hostname}/privkey.pem;
ssl_trusted_certificate /certs/${primary_hostname}/chain.pem;
EOF
      else
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
ssl_certificate /certs/cert.pem;
ssl_certificate_key /certs/privkey.pem;
EOF
      fi
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
return 302 https://${primary_hostname}\$request_uri;
}
########################## *. httpS (443) ##########################
server {
listen 443 ssl http2 backlog=256;
server_name ${primary_hostname};
EOF
    else
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
########################## *. httpS (443) ##########################
server {
listen 443 ssl http2 backlog=256;
EOF
      if [ "$NGINX_REDIRECT_WWW_TO_NON" != "yes" ] && [ "$NGINX_REDIRECT_WWW_TO_NON" != "true" ] && [ "$NGINX_REDIRECT_WWW_TO_NON" != "on" ] && [ "$NGINX_REDIRECT_WWW_TO_NON" != "1" ] && [ "${primary_hostname:0:4}" != "www." ] ; then
        echo "server_name ${primary_hostname} www.${primary_hostname} ${secondary_hostnames};" >> "/etc/nginx/server.d/${primary_hostname}.conf"
      else
        echo "server_name ${primary_hostname} ${secondary_hostnames};" >> "/etc/nginx/server.d/${primary_hostname}.conf"
      fi
    fi
    if [ -d "/var/www/${primary_hostname}/html" ] ; then
      echo "root /var/www/${primary_hostname}/html;" >> "/etc/nginx/server.d/${primary_hostname}.conf"
    else
      echo "root /var/www/html;" >> "/etc/nginx/server.d/${primary_hostname}.conf"
    fi
    cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
index index.htm index.html index.php;
access_log /dev/stdout;
error_log /dev/stderr warn;
EOF
    if [ -r "/certs/${primary_hostname}/fullchain.pem" ] && [ -r "/certs/${primary_hostname}/privkey.pem" ] && [ -r "/certs/${primary_hostname}/chain.pem" ] ; then
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
ssl_certificate /certs/${primary_hostname}/fullchain.pem;
ssl_certificate_key /certs/${primary_hostname}/privkey.pem;
ssl_trusted_certificate /certs/${primary_hostname}/chain.pem;
EOF
    else
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
ssl_certificate /certs/cert.pem;
ssl_certificate_key /certs/privkey.pem;
EOF
    fi
    if [ "$NGINX_DISABLE_PAGESPEED" != "yes" ] && [ "$NGINX_DISABLE_PAGESPEED" != "true" ] && [ "$NGINX_DISABLE_PAGESPEED" != "on" ] && [ "$NGINX_DISABLE_PAGESPEED" != "1" ] ; then
      if [ -r "/certs/${primary_hostname}/fullchain.pem" ] && [ -r "/certs/${primary_hostname}/privkey.pem" ] && [ -r "/certs/${primary_hostname}/chain.pem" ] ; then
        echo "pagespeed SslCertFile /certs/${primary_hostname}/chain.pem;" >> "/etc/nginx/server.d/${primary_hostname}.conf"
      fi
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
  pagespeed on;
  pagespeed Domain https://${primary_hostname};
  pagespeed SslCertDirectory /certs/;
  pagespeed LoadFromFile "https://${primary_hostname}" "/var/www/html";
  pagespeed LoadFromFile "https://www.${primary_hostname}" "/var/www/html";
EOF
    fi

    if [ "$NGINX_WORDPRESS" == "yes" ] || [ "$NGINX_WORDPRESS" == "true" ] || [ "$NGINX_WORDPRESS" == "on" ] || [ "$NGINX_WORDPRESS" == "1" ] ; then

if [ "$NGINX_WORDPRESS_SUPERCACHE" == "yes" ] || [ "$NGINX_WORDPRESS_SUPERCACHE" == "true" ] || [ "$NGINX_WORDPRESS_SUPERCACHE" == "on" ] || [ "$NGINX_WORDPRESS_SUPERCACHE" == "1" ] ; then
  cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/wordpress-supercache.conf;
location / {
  # for wordpress super cache plugin
  try_files /wp-content/cache/supercache/\$http_host/\$cache_uri/index.html \$uri \$uri/ /index.php?q=\$uri&\$args;
}
EOF
elif [ "$NGINX_WORDPRESS_CACHEENABLER" == "yes" ] || [ "$NGINX_WORDPRESS_CACHEENABLER" == "true" ] || [ "$NGINX_WORDPRESS_CACHEENABLER" == "on" ] || [ "$NGINX_WORDPRESS_CACHEENABLER" == "1" ] ; then
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/wordpress-cacheenabler.conf;
location / {
  # for wp cache enabler plugin
  try_files \$cache_enabler_uri \$uri \$uri/ \$custom_subdir/index.php?\$args;
}
EOF
else
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
location / {
  # Wordpress Permalinks
  try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
}
EOF
fi

cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
location ~* /(wp-login\.php) {
    limit_req zone=xwplogin burst=1 nodelay;
    limit_conn xwpconlimit 30;
    #auth_basic "Private";
    #auth_basic_user_file htpasswd.conf;
    include /etc/nginx/includes/php_geoip.conf;
}

location ~* /(xmlrpc\.php) {
    limit_req zone=xwprpc burst=45 nodelay;
    limit_conn xwpconlimit 30;
    include /etc/nginx/includes/php.conf;
}

location ~* /wp-admin/(load-scripts\.php) {
    limit_req zone=xwprpc burst=5 nodelay;
    limit_conn xwpconlimit 30;
    include /etc/nginx/includes/php.conf;
}

location ~* /wp-admin/(load-styles\.php) {
    limit_req zone=xwprpc burst=5 nodelay;
    limit_conn xwpconlimit 30;
    include /etc/nginx/includes/php.conf;
}

include /etc/nginx/includes/wordpress-secure.conf;
include /etc/nginx/includes/php_geoip.conf;
include /etc/nginx/include.d/*.conf;
}
EOF
    else
      if [ "$NGINX_DISABLE_REWRITES" != "yes" ] && [ "$NGINX_DISABLE_REWRITES" != "true" ] && [ "$NGINX_DISABLE_REWRITES" != "on" ] && [ "$NGINX_DISABLE_REWRITES" != "1" ] ; then
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/include.d/*.conf;

location @rewrite {
  include /etc/nginx/rewrite.d/*.conf;
}
location / {
  try_files \$uri \$uri/ @rewrite;
}
EOF
      else
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
  include /etc/nginx/include.d/*.conf;
location /
{
try_files \$uri \$uri/ /index.php?\$args;
}
EOF
      fi
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
location ~ .php/
{
  ## Forward paths like /js/index.php/x.js to relevant handler
  rewrite ^(.*.php)/ \$1 last;
}
EOF
      if [ "$NGINX_DISABLE_PHP" != "yes" ] && [ "$NGINX_DISABLE_PHP" != "true" ] && [ "$NGINX_DISABLE_PHP" != "on" ] && [ "$NGINX_DISABLE_PHP" != "1" ] ; then
        if [ "$NGINX_DISABLE_GEOIP" == "yes" ] || [ "$NGINX_DISABLE_GEOIP" == "true" ] || [ "$NGINX_DISABLE_GEOIP" == "on" ] || [ "$NGINX_DISABLE_GEOIP" == "1" ] ; then
          cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/php.conf;
}
EOF
        else
          cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/php_geoip.conf;
}
EOF
        fi
      else
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/php_disabled.conf;
}
EOF
      fi
    fi
  fi
done

if [ "$NGINX_DISABLE_PHP" != "yes" ] && [ "$NGINX_DISABLE_PHP" != "true" ] && [ "$NGINX_DISABLE_PHP" != "on" ] && [ "$NGINX_DISABLE_PHP" != "1" ] ; then
  while ! nc -z -v $NGINX_PHP_FPM_HOST $NGINX_PHP_FPM_PORT 2> /dev/null ; do
    echo "Waiting for PHP-FPM ${NGINX_PHP_FPM_HOST}:${NGINX_PHP_FPM_PORT} ..."
    sleep 2
  done
fi
if [ "$NGINX_DISABLE_GEOIP" != "yes" ] && [ "$NGINX_DISABLE_GEOIP" != "true" ] && [ "$NGINX_DISABLE_GEOIP" != "on" ] && [ "$NGINX_DISABLE_GEOIP" != "1" ] ; then
  while ! [ -f "/usr/share/GeoIP/GeoIP.dat" ] ; do
    echo "Waiting for /usr/share/GeoIP/GeoIP.dat ..."
    sleep 2
  done
fi

echo "#### Checking Nginx configs ####"
nginx -t
result=$?

if [ "$result" != "0" ] ; then
  echo "ERROR: CONFIG DAMAGED, sleeping ......"
  sleep 1d
  exit 1
fi

echo "#### Nginx Starting ####"
/usr/sbin/nginx -c /etc/nginx/nginx.conf
