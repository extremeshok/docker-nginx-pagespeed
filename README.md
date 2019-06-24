# docker-nginx-pagespeed
alpine nginx pagespeed

## Work in progress
http_image_filter_module
http_xslt_module

## Nginx Modules
Using a custom nginx-pagespeed build which always follows the latest official releases : https://github.com/extremeshok/docker-nginx-pagespeed-build

## Enviroment Varibles

NGINX_DISABLE_GEOIP=no
NGINX_DISABLE_PAGESPEED=no
NGINX_DISABLE_PHP=no

NGINX_PHP_FPM_HOST=phpfpm
NGINX_PHP_FPM_PORT=8000

NGINX_DOMAINS=${NGINX_DOMAINS:-$HOSTNAME}

NGINX_DOMAINS=www.domain.com,domain.com;my.otherdomain.net;www.randomdomain.com

root /var/www/${primary_hostname}/html or root /var/www/html

NGINX_WORDPRESS=yes
NGINX_WORDPRESS_SUPERCACHE=
NGINX_WORDPRESS_CACHE_ENABLER=


## Features
* Very small Docker image size
* The logs of all the services are redirected to the output of the Docker container (visible with `docker logs -f <container name>`)

## Usage
Development / Testing
```
docker pull extremeshok/nginx-pagespeed:edge && docker run --rm -ti extremeshok/nginx-pagespeed:edge /bin/bash
```
