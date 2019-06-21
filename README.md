# docker-nginx-pagespeed
alpine nginx pagespeed

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

* Built on the lightweight and secure Alpine Linux distribution
* Very small Docker image size
* Optimized for 100 concurrent users
* Optimized to only use resources when there's traffic (by using PHP-FPM's ondemand PM)
* The servers Nginx run under a non-privileged user (nobody) to make it more secure
* The logs of all the services are redirected to the output of the Docker container (visible with `docker logs -f <container name>`)
* Follows the KISS principle (Keep It Simple, Stupid) to make it easy to understand and adjust the image


## Usage

Start the Docker container:

docker run -p 433:433 extremeshok/nginx-pagespeed
