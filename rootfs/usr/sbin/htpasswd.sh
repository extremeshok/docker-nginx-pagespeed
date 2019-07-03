#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
## small script to generate an encoded htpasswd password from a string

if [ -z "$1" ] ; then
  echo "Missing password, run $0 yourpassword"
else
  openssl passwd -apr1 $1
fi
