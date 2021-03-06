#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='12345678'
PROJECTFOLDER='mayfox'

# Create project folder, written in 3 single mkdir-statements to make sure this runs everywhere without problems
sudo mkdir "/var/www"
sudo mkdir "/var/www/html"
sudo mkdir "/var/www/html/${PROJECTFOLDER}"

sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get install -y apache2
sudo apt-get install -y php
sudo apt-get install php-pear php-fpm php-dev php-zip php-curl php-xmlrpc php-gd php-mysql php-mbstring php-xml libapache2-mod-php

sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
sudo apt-get install php7.2-mysql

sudo add-apt-repository universe
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin

# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html/${PROJECTFOLDER}/public"
    <Directory "/var/www/html/${PROJECTFOLDER}/public">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
sudo a2enmod rewrite

# restart apache
service apache2 restart

# install curl (needed to use git afaik)
sudo apt-get -y install curl
sudo apt-get -y install php7.2-curl

# install openssl (needed to clone from GitHub, as github is https only)
sudo apt-get -y install openssl

# install git
sudo apt-get -y install git

# git clone HUGE
sudo git clone https://github.com/panique/huge "/var/www/html/${PROJECTFOLDER}"

# git clone Userfrosting
sudo git clone https://github.com/userfrosting/UserFrosting.git "/var/www/html/userfrosting"

# install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# go to project folder, load Composer packages
cd "/var/www/html/${PROJECTFOLDER}"
composer install

# install node.js and npm
# sudo apt-get install nodejs

# run SQL statements from install folder
sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/application/_installation/01-create-database.sql"
sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/application/_installation/02-create-table-users.sql"
sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/application/_installation/03-create-table-notes.sql"

# writing rights to avatar folder
sudo chown -R www-data "/var/www/html/${PROJECTFOLDER}/public/avatars"
# if this didn't work for you, you can also try the hard way:
#sudo chmod 0777 -R "/var/www/html/${PROJECTFOLDER}/public/avatars"

# remove Apache's default demo file
sudo rm "/var/www/html/index.html"

# more userfrosting
cd "/var/www/html/userfrosting"
composer install
php bakery bake

# final feedback
echo "Nibba!"
