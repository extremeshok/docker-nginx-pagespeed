# docker-nginx-pagespeed
nginx pagespeed

## Nginx Modules
Using a custom nginx build which always follows the latest official releases : https://github.com/extremeshok/docker-nginx

## Enviroment Varibles

* NGINX_DISABLE_GEOIP=no
* NGINX_DISABLE_PAGESPEED=no
* NGINX_DISABLE_PHP=no

* NGINX_PHP_FPM_HOST=phpfpm
* NGINX_PHP_FPM_PORT=8000

* NGINX_DOMAINS=${NGINX_DOMAINS:-$HOSTNAME}

* NGINX_DOMAINS=www.domain.com,domain.com;my.otherdomain.net;www.randomdomain.com

* root /var/www/${primary_hostname}/html or root /var/www/html

* NGINX_WORDPRESS=yes
* NGINX_WORDPRESS_SUPERCACHE=
* NGINX_WORDPRESS_CACHE_ENABLER=


### redis will take preference if both are set
* NGINX_PAGESPEED_REDIS_HOST=no (specify host and port NGINX_PAGESPEED_REDIS_HOST="redis:6379")
* NGINX_PAGESPEED_MEMCACHED_HOST=no
* NGINX_PAGESPEED_CDN=no (specifiy fqdn of your cdn)
* NGINX_PAGESPEED_FORCE_CDN=no (true to rewrite the urls to that of the cdn)

## Features
* Very small Docker image size
* The logs of all the services are redirected to the output of the Docker container (visible with `docker logs -f <container name>`)

## Usage
Development / Testing
```
docker pull extremeshok/nginx-pagespeed:latest && docker run --rm -ti extremeshok/nginx-pagespeed:latest /bin/bash
```
