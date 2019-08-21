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

XS_DOMAINS=${NGINX_DOMAINS:-$HOSTNAME}

XS_CHOWN=${NGINX_CHOWN:-yes}

XS_DISABLE_REWRITES=${NGINX_DISABLE_REWRITES:-no}
XS_DISABLE_PAGESPEED=${NGINX_DISABLE_PAGESPEED:-no}
XS_DISABLE_GEOIP=${NGINX_DISABLE_GEOIP:-no}
XS_DISABLE_SECURITYBLOCKS=${NGINX_DISABLE_SECURITYBLOCKS:-no}
XS_DISABLE_BOTLIMIT=${NGINX_DISABLE_BOTLIMIT:-no}
XS_DISABLE_PHP=${NGINX_DISABLE_PHP:-no}
XS_PHP_FPM_HOST=${NGINX_PHP_FPM_HOST:-phpfpm}
XS_PHP_FPM_PORT=${NGINX_PHP_FPM_PORT:-9000}
XS_REDIRECT_WWW_TO_NON=${NGINX_REDIRECT_WWW_TO_NON:-yes}
XS_MAX_UPLOAD_SIZE=${NGINX_MAX_UPLOAD_SIZE:-32}

# redis will take preference if both are set "host:port"
XS_PAGESPEED_REDIS_HOST=${NGINX_PAGESPEED_REDIS:-no}
XS_PAGESPEED_REDIS_PORT=${NGINX_PAGESPEED_REDIS_PORT:-6379}
XS_PAGESPEED_MEMCACHED_HOST=${NGINX_PAGESPEED_MEMCACHED:-no}

# set page speed to use a cdn, "fqdn"
XS_PAGESPEED_CDN=${NGINX_PAGESPEED_CDN:-no}
XS_PAGESPEED_FORCE_CDN=${NGINX_PAGESPEED_FORCE_CDN:-no}

XS_WORDPRESS=${NGINX_WORDPRESS:-no}
XS_WORDPRESS_SUPERCACHE=${NGINX_WORDPRESS_SUPERCACHE:-no}
XS_WORDPRESS_CACHE_ENABLER=${NGINX_WORDPRESS_CACHE_ENABLER:-no}
XS_WORDPRESS_REDISCACHE=${NGINX_WORDPRESS_REDISCACHE:-no}
XS_WORDPRESS_MEMCACHED=${NGINX_WORDPRESS_MEMCACHED:-no}

# clean the ENV's
XS_PAGESPEED_CDN=${XS_PAGESPEED_CDN//\"}
XS_PAGESPEED_REDIS_HOST=${XS_PAGESPEED_REDIS_HOST//\"}
XS_PAGESPEED_REDIS_PORT=${XS_PAGESPEED_REDIS_PORT//\"}
XS_PAGESPEED_MEMCACHED_HOST=${XS_PAGESPEED_MEMCACHED_HOST//\"}

#varibles
XS_PHP_CONF="php.conf"

echo "#### Nginx Generating Configs ####"
if [ -w "/etc/nginx/conf.d/" ] && [ -w "/etc/nginx/modules/" ] && [ -w "/etc/nginx/include.d/" ] && [ -w "/etc/nginx/server.d/" ] ; then

  # XS_MAX_UPLOAD_SIZE
  XS_MAX_UPLOAD_SIZE=${XS_MAX_UPLOAD_SIZE%%m}
  echo "client_max_body_size ${XS_MAX_UPLOAD_SIZE}m;" > /etc/nginx/conf.d/max_upload_size.conf

  if [ "$XS_DISABLE_SECURITYBLOCKS" == "yes" ] || [ "$XS_DISABLE_SECURITYBLOCKS" == "true" ] || [ "$XS_DISABLE_SECURITYBLOCKS" == "on" ] || [ "$XS_DISABLE_SECURITYBLOCKS" == "1" ] ; then
    echo "Securityblocks Disabled"
    mv -f /etc/nginx/include.d/securityblocks.conf /etc/nginx/include.d/securityblocks.disabled
  else
    if [ -f "/etc/nginx/include.d/securityblocks.disabled" ] ; then
      mv -f /etc/nginx/include.d/securityblocks.disabled /etc/nginx/include.d/securityblocks.conf
    fi
  fi

  if [ "$XS_DISABLE_BOTLIMIT" == "yes" ] || [ "$XS_DISABLE_BOTLIMIT" == "true" ] || [ "$XS_DISABLE_BOTLIMIT" == "on" ] || [ "$XS_DISABLE_BOTLIMIT" == "1" ] ; then
    echo "Botlimit Disabled"
    mv -f /etc/nginx/include.d/blockbots.conf /etc/nginx/include.d/blockbots.disabled
    mv -f /etc/nginx/conf.d/botlimit.conf /etc/nginx/conf.d/botlimit.disabled
  else
    if [ -f "/etc/nginx/include.d/blockbots.disabled" ] ; then
      mv -f /etc/nginx/include.d/blockbots.disabled /etc/nginx/include.d/blockbots.conf
    fi
    if [ -f "/etc/nginx/conf.d/botlimit.disabled" ] ; then
      mv -f /etc/nginx/conf.d/botlimit.disabled /etc/nginx/conf.d/botlimit.conf
    fi
  fi

  if [ "$XS_DISABLE_GEOIP" != "yes" ] && [ "$XS_DISABLE_GEOIP" != "true" ] && [ "$XS_DISABLE_GEOIP" != "on" ] && [ "$XS_DISABLE_GEOIP" != "1" ] ; then
    if [ -f "/usr/share/GeoIP/GeoIP.dat" ] ; then
      echo "GeoIPv1 database detected, disabling GeoIP. This server requires GeoIPv2 databases, please remove /usr/share/GeoIP/GeoIP.dat ..."
      XS_DISABLE_GEOIP="yes"
    fi
  fi
  if [ "$XS_DISABLE_GEOIP" == "yes" ] || [ "$XS_DISABLE_GEOIP" == "true" ] || [ "$XS_DISABLE_GEOIP" == "on" ] || [ "$XS_DISABLE_GEOIP" == "1" ] ; then
    echo "GEOIP Disabled"
    if [ -f "/etc/nginx/modules/http_geoip2.conf" ] ; then
      mv -f /etc/nginx/modules/http_geoip2.conf /etc/nginx/modules/http_geoip2.disabled
    fi
    if [ -f "/etc/nginx/conf.d/geoip2.conf" ] ; then
      mv -f /etc/nginx/conf.d/geoip2.conf /etc/nginx/conf.d/geoip2.disabled
    fi
  else
    if [ -f "/etc/nginx/modules/http_geoip2.disabled" ] ; then
      mv -f /etc/nginx/modules/http_geoip2.disabled /etc/nginx/modules/http_geoip2.conf
    fi
    if [ -f "/etc/nginx/conf.d/geoip2.disabled" ] ; then
      mv -f /etc/nginx/conf.d/geoip2.disabled /etc/nginx/conf.d/geoip2.conf
    fi
    XS_PHP_CONF="php_geoip.conf"
  fi
  if [ "$XS_DISABLE_PAGESPEED" == "yes" ] || [ "$XS_DISABLE_PAGESPEED" == "true" ] || [ "$XS_DISABLE_PAGESPEED" == "on" ] || [ "$XS_DISABLE_PAGESPEED" == "1" ] ; then
    echo "Pagespeed Disabled"
    mv -f /etc/nginx/conf.d/pagespeed.conf /etc/nginx/conf.d/pagespeed.disabled
    mv -f /etc/nginx/include.d/pagespeed.conf /etc/nginx/include.d/pagespeed.disabled
    if [ -f "/etc/nginx/conf.d/pagespeed_redis.conf" ] ; then
      rm -f /etc/nginx/conf.d/pagespeed_redis.conf
    fi
    if [ -f "/etc/nginx/conf.d/pagespeed_memcached.conf" ] ; then
      rm -f /etc/nginx/conf.d/pagespeed_memcached.conf
    fi
    if [ -f "/etc/nginx/conf.d/pagespeed_cdn.conf" ] ; then
      rm -f /etc/nginx/conf.d/pagespeed_cdn.conf
    fi
  else
    echo "Pagespeed Enabled"
    if [ -f "/etc/nginx/conf.d/pagespeed.disabled" ] ; then
      mv -f /etc/nginx/conf.d/pagespeed.disabled /etc/nginx/conf.d/pagespeed.conf
    fi
    if [ -f "/etc/nginx/include.d/pagespeed.disabled" ] ; then
      mv -f /etc/nginx/include.d/pagespeed.disabled /etc/nginx/include.d/pagespeed.conf
    fi

    if [ "$XS_PAGESPEED_REDIS_HOST" != "" ] && [ "$XS_PAGESPEED_REDIS_HOST" != " " ] && [ "$XS_PAGESPEED_REDIS_HOST" != "no" ]; then
      echo "Pagespeed Redis Enabled ${XS_PAGESPEED_REDIS_HOST}"
      XS_PAGESPEED_MEMCACHED_HOST=""
      cat << EOF > /etc/nginx/conf.d/pagespeed_redis.conf
pagespeed RedisServer "${XS_PAGESPEED_REDIS_HOST}:${XS_PAGESPEED_REDIS_PORT}";
pagespeed RedisTTLSec 86400;
EOF
    else
      if [ -f "/etc/nginx/conf.d/pagespeed_redis.conf" ] ; then
        rm -f /etc/nginx/conf.d/pagespeed_redis.conf
      fi
    fi
    if [ "$XS_PAGESPEED_MEMCACHED_HOST" != "" ] && [ "$XS_PAGESPEED_MEMCACHED_HOST" != " " ] && [ "$XS_PAGESPEED_MEMCACHED_HOST" != "no" ]; then
      echo "Pagespeed Memcached Enabled ${XS_PAGESPEED_MEMCACHED_HOST}"
      cat << EOF > /etc/nginx/conf.d/pagespeed_memcached.conf
pagespeed MemcachedThreads 1;
pagespeed MemcachedServers "${XS_PAGESPEED_MEMCACHED_HOST}";
pagespeed MemcachedTimeoutUs 100000;
EOF
    else
      if [ -f "/etc/nginx/conf.d/pagespeed_memcached.conf" ] ; then
        rm -f /etc/nginx/conf.d/pagespeed_memcached.conf
      fi
    fi
    echo "Pagespeed CDN Enabled ${XS_PAGESPEED_CDN}"
    if [ "$XS_PAGESPEED_CDN" != "" ] && [ "$XS_PAGESPEED_CDN" != " " ] && [ "$XS_PAGESPEED_CDN" != "no" ]; then
      cat << EOF > /etc/nginx/conf.d/pagespeed_cdn.conf
pagespeed Domain "${HOSTNAME}";
pagespeed Domain "https://${HOSTNAME}";
pagespeed Domain "${XS_PAGESPEED_CDN}";
pagespeed Domain "https://${XS_PAGESPEED_CDN}";
EOF
      if [ "$XS_PAGESPEED_FORCE_CDN" == "yes" ] || [ "$XS_PAGESPEED_FORCE_CDN" == "true" ] || [ "$XS_PAGESPEED_FORCE_CDN" == "on" ] || [ "$XS_PAGESPEED_FORCE_CDN" == "1" ] ; then
        cat << EOF >> /etc/nginx/conf.d/pagespeed_cdn.conf
pagespeed MapOriginDomain "https://${primary_hostname}" "https://${XS_PAGESPEED_CDN}";
pagespeed MapRewriteDomain "https://${XS_PAGESPEED_CDN}" "https://${HOSTNAME}";
EOF

      fi
    else
      if [ -f "/etc/nginx/conf.d/pagespeed_cdn.conf" ] ; then
        rm -f /etc/nginx/conf.d/pagespeed_cdn.conf
      fi
    fi
  fi
  if [ "$XS_DISABLE_PHP" == "yes" ] || [ "$XS_DISABLE_PHP" == "true" ] || [ "$XS_DISABLE_PHP" == "on" ] || [ "$XS_DISABLE_PHP" == "1" ] ; then
    echo "PHP Disabled"
    mv -f /etc/nginx/conf.d/php_upstream.conf /etc/nginx/conf.d/php_upstream.disabled
  else
    if [ -f "/etc/nginx/conf.d/php_upstream.disabled" ] ; then
      rm -f /etc/nginx/conf.d/php_upstream.disabled
    fi
    cat << EOF > /etc/nginx/conf.d/php_upstream.conf
upstream php_upstream {
zone php_upstream_zone 128k;
server ${XS_PHP_FPM_HOST}:${XS_PHP_FPM_PORT};
server ${XS_PHP_FPM_HOST}:${XS_PHP_FPM_PORT} backup;
keepalive 128;
}
EOF
  fi
  if [ "$XS_WORDPRESS" == "yes" ] || [ "$XS_WORDPRESS" == "true" ] || [ "$XS_WORDPRESS" == "on" ] || [ "$XS_WORDPRESS" == "1" ] ; then
    if [ -f "/etc/nginx/conf.d/wordpress.disabled" ] ; then
      mv -f /etc/nginx/conf.d/wordpress.disabled /etc/nginx/conf.d/wordpress.conf
    fi
  else
    echo "Wordpress Enabled"
    mv -f /etc/nginx/conf.d/wordpress.conf /etc/nginx/conf.d/wordpress.disabled
  fi
fi


for myhostnames in ${XS_DOMAINS//\;/ } ; do
  echo "${myhostnames}"
  primary_hostname="${myhostnames%%,*}"
  secondary_hostnames="${myhostnames#*,}"

  if [ "$secondary_hostnames" != "" ] && [ "$secondary_hostnames" != " " ]; then
    if [ "$XS_REDIRECT_WWW_TO_NON" == "yes" ] || [ "$XS_REDIRECT_WWW_TO_NON" == "true" ] || [ "$XS_REDIRECT_WWW_TO_NON" == "on" ] || [ "$XS_REDIRECT_WWW_TO_NON" == "1" ] ; then
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
      echo "Waiting for certs (/certs/${primary_hostname}/fullchain.pem) to be provisioned..."
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
    if [ "$XS_REDIRECT_WWW_TO_NON" == "yes" ] || [ "$XS_REDIRECT_WWW_TO_NON" == "true" ] || [ "$XS_REDIRECT_WWW_TO_NON" == "on" ] || [ "$XS_REDIRECT_WWW_TO_NON" == "1" ] ; then
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
listen 443 ssl http2 backlog=256 reuseport;
server_name ${primary_hostname};
EOF
    else
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
########################## *. httpS (443) ##########################
server {
listen 443 ssl http2 backlog=256 reuseport;
EOF
      if [ "$XS_REDIRECT_WWW_TO_NON" != "yes" ] && [ "$XS_REDIRECT_WWW_TO_NON" != "true" ] && [ "$XS_REDIRECT_WWW_TO_NON" != "on" ] && [ "$XS_REDIRECT_WWW_TO_NON" != "1" ] && [ "${primary_hostname:0:4}" != "www." ] ; then
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
    if [ "$XS_DISABLE_PHP" != "yes" ] && [ "$XS_DISABLE_PHP" != "true" ] && [ "$XS_DISABLE_PHP" != "on" ] && [ "$XS_DISABLE_PHP" != "1" ] ; then
      echo "index index.php index.html index.htm;" >> "/etc/nginx/server.d/${primary_hostname}.conf"
    else
      echo "index index.html index.htm;" >> "/etc/nginx/server.d/${primary_hostname}.conf"
    fi

    cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
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
    if [ "$XS_DISABLE_PAGESPEED" != "yes" ] && [ "$XS_DISABLE_PAGESPEED" != "true" ] && [ "$XS_DISABLE_PAGESPEED" != "on" ] && [ "$XS_DISABLE_PAGESPEED" != "1" ] ; then
      if [ -r "/certs/${primary_hostname}/fullchain.pem" ] && [ -r "/certs/${primary_hostname}/privkey.pem" ] && [ -r "/certs/${primary_hostname}/chain.pem" ] ; then
        echo "pagespeed SslCertFile /certs/${primary_hostname}/chain.pem;" >> "/etc/nginx/server.d/${primary_hostname}.conf"
      fi
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
pagespeed Domain https://${primary_hostname};
EOF
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
pagespeed LoadFromFile "https://${primary_hostname}" "/var/www/html";
pagespeed LoadFromFileRuleMatch disallow .*;
pagespeed LoadFromFileRuleMatch allow \.css\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.js\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.gif\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.jpe?g\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.jpg\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.png\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.webp\$ps_dollar;
EOF
      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
pagespeed LoadFromFile "https://www.${primary_hostname}" "/var/www/html";
pagespeed LoadFromFileRuleMatch disallow .*;
pagespeed LoadFromFileRuleMatch allow \.css\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.js\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.gif\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.jpe?g\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.jpg\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.png\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.webp\$ps_dollar;
EOF
      if [ "$XS_PAGESPEED_CDN" != "" ] && [ "$XS_PAGESPEED_CDN" != " " ] && [ "$XS_PAGESPEED_CDN" != "no" ]; then
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
pagespeed LoadFromFile "https://www.${XS_PAGESPEED_CDN}" "/var/www/html";
pagespeed LoadFromFileRuleMatch disallow .*;
pagespeed LoadFromFileRuleMatch allow \.css\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.js\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.gif\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.jpe?g\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.jpg\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.png\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.webp\$ps_dollar;
EOF

cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
pagespeed LoadFromFile "https://${XS_PAGESPEED_CDN}" "/var/www/html";
pagespeed LoadFromFileRuleMatch disallow .*;
pagespeed LoadFromFileRuleMatch allow \.css\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.js\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.gif\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.jpe?g\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.jpg\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.png\$ps_dollar;
pagespeed LoadFromFileRuleMatch allow \.webp\$ps_dollar;
EOF
      fi

    fi

    if [ "$XS_WORDPRESS" == "yes" ] || [ "$XS_WORDPRESS" == "true" ] || [ "$XS_WORDPRESS" == "on" ] || [ "$XS_WORDPRESS" == "1" ] ; then

      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
pagespeed off;
pagespeed Disallow "*/wp-admin/*";
pagespeed Allow "*/wp-admin/*.css";
EOF

      if [ "$XS_WORDPRESS_CACHE_ENABLER" == "yes" ] || [ "$XS_WORDPRESS_CACHE_ENABLER" == "true" ] || [ "$XS_WORDPRESS_CACHE_ENABLER" == "on" ] || [ "$XS_WORDPRESS_CACHE_ENABLER" == "1" ] ; then
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/wordpress-cacheenabler.conf;
location / {
  # for wp cache enabler plugin
  try_files \$cache_enabler_uri \$uri \$uri/ /index.php?\$args;
}
EOF
      elif [ "$XS_WORDPRESS_SUPERCACHE" == "yes" ] || [ "$XS_WORDPRESS_SUPERCACHE" == "true" ] || [ "$XS_WORDPRESS_SUPERCACHE" == "on" ] || [ "$XS_WORDPRESS_SUPERCACHE" == "1" ] ; then
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/wordpress-supercache.conf;
location / {
  # for wordpress super cache plugin
  try_files /var/www/cache/\$cache_uri/index.html \$uri \$uri/ /index.php?q=\$uri&\$args;
}
EOF
      elif [ "$XS_WORDPRESS_REDISCACHE" == "yes" ] || [ "$XS_WORDPRESS_REDISCACHE" == "true" ] || [ "$XS_WORDPRESS_REDISCACHE" == "on" ] || [ "$XS_WORDPRESS_REDISCACHE" == "1" ] ; then
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/wordpress-rediscache.conf;
location / {
  # Nginx level redis Wordpress
  try_files \$uri \$uri/ /index.php?\$args;
}
EOF
      elif [ "$XS_WORDPRESS_MEMCACHED" == "yes" ] || [ "$XS_WORDPRESS_MEMCACHED" == "true" ] || [ "$XS_WORDPRESS_MEMCACHED" == "on" ] || [ "$XS_WORDPRESS_MEMCACHED" == "1" ] ; then
        cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/wordpress-memcached.conf;
location / {
  # Nginx level redis Wordpress
  try_files \$uri \$uri/ @memcached;
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

if [ "$XS_DISABLE_PAGESPEED" == "yes" ] || [ "$XS_DISABLE_PAGESPEED" == "true" ] || [ "$XS_DISABLE_PAGESPEED" == "on" ] || [ "$XS_DISABLE_PAGESPEED" == "1" ] ; then
  disable_pagespeed_string="pagespeed off;"
else
  disable_pagespeed_string=""
fi

      cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
location ~* /(wp-login\.php) {
    limit_req zone=xwplogin burst=1 nodelay;
    limit_conn xwpconlimit 30;
    #auth_basic "Private";
    #auth_basic_user_file htpasswd.conf;
    include /etc/nginx/includes/${XS_PHP_CONF};
}

location ~* /(xmlrpc\.php) {
    ${disable_pagespeed_string}
    limit_req zone=xwprpc burst=45 nodelay;
    limit_conn xwpconlimit 30;
    include /etc/nginx/includes/php.conf;
}

location ~* /wp-admin/(load-scripts\.php) {
    ${disable_pagespeed_string}
    limit_req zone=xwprpc burst=5 nodelay;
    limit_conn xwpconlimit 30;
    include /etc/nginx/includes/php.conf;
}

location ~* /wp-admin/(load-styles\.php) {
    ${disable_pagespeed_string}
    limit_req zone=xwprpc burst=5 nodelay;
    limit_conn xwpconlimit 30;
    include /etc/nginx/includes/php.conf;
}

location ~* /wp-admin/(admin-ajax\.php) {
    ${disable_pagespeed_string}
    limit_req zone=xwprpc burst=5 nodelay;
    limit_conn xwpconlimit 30;
    include /etc/nginx/includes/php.conf;
}

location ~* /wp-admin/ {
    ${disable_pagespeed_string}
    include /etc/nginx/includes/php.conf;
}

pagespeed on;

include /etc/nginx/includes/wordpress-secure.conf;
include /etc/nginx/includes/${XS_PHP_CONF};
include /etc/nginx/include.d/*.conf;
}
EOF
    else
      if [ "$XS_DISABLE_REWRITES" != "yes" ] && [ "$XS_DISABLE_REWRITES" != "true" ] && [ "$XS_DISABLE_REWRITES" != "on" ] && [ "$XS_DISABLE_REWRITES" != "1" ] ; then
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
      if [ "$XS_DISABLE_PHP" != "yes" ] && [ "$XS_DISABLE_PHP" != "true" ] && [ "$XS_DISABLE_PHP" != "on" ] && [ "$XS_DISABLE_PHP" != "1" ] ; then
        if [ "$XS_DISABLE_GEOIP" == "yes" ] || [ "$XS_DISABLE_GEOIP" == "true" ] || [ "$XS_DISABLE_GEOIP" == "on" ] || [ "$XS_DISABLE_GEOIP" == "1" ] ; then
          cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/php.conf;
}
EOF
        else
          cat <<EOF >> "/etc/nginx/server.d/${primary_hostname}.conf"
include /etc/nginx/includes/${XS_PHP_CONF};
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

if [ "$XS_DISABLE_PHP" != "yes" ] && [ "$XS_DISABLE_PHP" != "true" ] && [ "$XS_DISABLE_PHP" != "on" ] && [ "$XS_DISABLE_PHP" != "1" ] ; then
  while ! nc -z -v $XS_PHP_FPM_HOST $XS_PHP_FPM_PORT 2> /dev/null ; do
    echo "Waiting for PHP-FPM ${XS_PHP_FPM_HOST}:${XS_PHP_FPM_PORT} ..."
    sleep 2
  done
fi
if [ "$XS_DISABLE_GEOIP" != "yes" ] && [ "$XS_DISABLE_GEOIP" != "true" ] && [ "$XS_DISABLE_GEOIP" != "on" ] && [ "$XS_DISABLE_GEOIP" != "1" ] ; then
  while ! [ -f "/usr/share/GeoIP/GeoLite2-Country.mmdb" ] ; do
    echo "Waiting for /usr/share/GeoIP/GeoLite2-Country.mmdb ..."
    sleep 2
  done
  while ! [ -f "/usr/share/GeoIP/GeoLite2-City.mmdb" ] ; do
    echo "Waiting for /usr/share/GeoIP/GeoLite2-City.mmdb ..."
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

if [ "$XS_DISABLE_PAGESPEED" != "yes" ] && [ "$XS_DISABLE_PAGESPEED" != "true" ] && [ "$XS_DISABLE_PAGESPEED" != "on" ] && [ "$XS_DISABLE_PAGESPEED" != "1" ] ; then
  echo "Configuring pagespeed cache dir : /var/cache/pagespeed"
  mkdir -p /var/cache/pagespeed/shm_metadata_cache
  mkdir -p /var/cache/pagespeed/shared
  mkdir -p /var/cache/pagespeed/log
  mkdir -p /var/cache/pagespeed/v3
  touch '/var/cache/pagespeed/!clean!time!'
  chmod -R 777 /var/cache/pagespeed
fi

if [ "$XS_CHOWN" == "yes" ] || [ "$XS_CHOWN" == "true" ] || [ "$XS_CHOWN" == "on" ] || [ "$XS_CHOWN" == "1" ] ; then
  echo "Setting ownership of /var/cache/nginx"
  chown -f -R nginx:nginx /var/cache/nginx
  if [ "$XS_DISABLE_PAGESPEED" != "yes" ] && [ "$XS_DISABLE_PAGESPEED" != "true" ] && [ "$XS_DISABLE_PAGESPEED" != "on" ] && [ "$XS_DISABLE_PAGESPEED" != "1" ] ; then
    echo "Setting ownership of /var/cache/pagespeed"
    chown -f -R nginx:nginx /var/cache/pagespeed
  fi
  chmod -R 777 /var/cache
fi

echo "#### Nginx Starting ####"
/usr/sbin/nginx -c /etc/nginx/nginx.conf
