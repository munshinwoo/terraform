#!/bin/bash
# Apache webserver user data script
yum -y -q install httpd mod_ssl
echo "My webserver" > /var/www/html/index.html
systemctl enalbe --now httpd