#!/bin/bash
## Install the needed packages and enable the services(MariaDb, Apache)
sudo yum update -y
sudo yum install git -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd mariadb-server
sudo yum install -y php-gd php-mbstring php-xml php-mysqlnd nfs-utils git unzip

## Pre-fetch wp-force-login plugin so instances don't need network access to wordpress.org at boot
sudo curl -L -o /opt/wp-force-login.zip https://downloads.wordpress.org/plugin/wp-force-login.zip

## Modify Apache configuration safely
sudo sed -i '151s/None/All/' /etc/httpd/conf/httpd.conf

## Configure Keepalive settings
sudo /sbin/sysctl -w net.ipv4.tcp_keepalive_time=200 net.ipv4.tcp_keepalive_intvl=200 net.ipv4.tcp_keepalive_probes=5

## Add ec2-user to Apache group
sudo usermod -a -G apache ec2-user

## Download and install WP-CLI globally using sudo to avoid permission blocks
cd /tmp
sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

## Grant final ownership and permissions to /var/www for Apache and ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www
sudo find /var/www -type d -exec chmod 2775 {} \;
sudo find /var/www -type f -exec chmod 0664 {} \;

## Enable and Restart Apache
sudo systemctl enable httpd
sudo systemctl restart httpd
