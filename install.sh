#!/bin/bash

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee /tmp/installlog.txt)
# Without this, only stdout would be captured
exec 2>&1

# Check if sources.list is a symlink and make a copy so `apt-get update` succeeds
if [ -f /etc/apt/sources.list ] && [ -L /etc/apt/sources.list ]; then
  sudo mv /etc/apt/sources.list /etc/apt/sources.list.old
  sudo cp /etc/apt/sources.list.old /etc/apt/sources.list
fi

# Update Composer
sudo /usr/bin/composer self-update

# Add php5 Repository
LC_ALL=C.UTF-8 sudo add-apt-repository ppa:ondrej/php -y
sudo apt-add-repository ppa:rwky/redis -y
sudo apt-get update

# Update Heroku Toolbelt
wget -O- https://toolbelt.heroku.com/install-ubuntu.sh | sh

# Install php5 & Redis
sudo apt-get install -qq php5-fpm php5-cli php5-common php5-json php5-mysql \
php5-gd php5-imap php5-ldap php5-pgsql php5-pspell php5-recode php5-tidy php5-dev \
php5-intl php5-gd php5-curl redis-server

#sudo apt-get install -qq php5-phpdbg php5-opcache php5-mbstring php5-zip php5-xml

sudo apt-get purge -qq apache2 mysql-server mysql-client

# Stop all the services

# Apache2
sudo service apache2 stop
# NGINX
sudo service nginx stop


# Set them up!

# NGINX:
# Listen port 80, change document root, setup indexes, configure PHP sock
# set up the try_url thing (Drupal is not Worpress)...
# Thankfully, I already modified this in the repo!
sudo wget https://raw.githubusercontent.com/GabrielGil/c9-lemp/master/c9 --output-document=/etc/nginx/sites-available/c9
sudo chmod 755 /etc/nginx/sites-available/c9
sudo ln -s /etc/nginx/sites-available/c9 /etc/nginx/sites-enabled/c9


# PHP:
sudo sed -i 's/user = www-data/user = ubuntu/g' /etc/php5/fpm/pool.d/www.conf
sudo sed -i 's/group = www-data/group = ubuntu/g' /etc/php5/fpm/pool.d/www.conf
sudo sed -i 's/pm = dynamic/pm = ondemand/g' /etc/php5/fpm/pool.d/www.conf # Reduce number of processes..

# Install Redis Driver
cd ~
git clone https://github.com/phpredis/phpredis.git
cd phpredis
git checkout php5
phpize
./configure
make && sudo make install
cd ..
rm -rf phpredis
sudo sh -c 'echo "extension=redis.so" > /etc/php5/mods-available/redis.ini'
sudo ln -sf /etc/php5/mods-available/redis.ini /etc/php5/fpm/conf.d/20-redis.ini
sudo mkdir /etc/php5/conf.d/
sudo ln -sf /etc/php5/mods-available/redis.ini /etc/php5/conf.d/20-redis.ini

# Install helper
sudo wget https://raw.githubusercontent.com/bergerrc/c9-lemp/master/lemp --output-document=/usr/bin/lemp
sudo chmod 755 /usr/bin/lemp

# Start the party!
sudo service nginx start
sudo service nginx reload
sudo service php5-fpm start

# Are we ready?
echo Check all services are up.
sleep 5
sudo service nginx status
sudo service php5-fpm status
lemp restart
