#!/usr/bin/env bash

# SYSTEM
# Preparing system
echo " "
echo "___@@@ Start preparing system..."

# Setup variables
export MYSQL_PASSWD='Dev2016'
export DEBIAN_FRONTEND=noninteractive

# Set up repository for NodeJS
curl -sL https://deb.nodesource.com/setup_4.x | bash -

# Update system
apt-get update
apt-get upgrade -y

# Setup locale
apt-get install -y language-pack-en-base htop
locale-gen "en_US.UTF-8"
echo 'export LANG="en_US" LC_ALL="en_US.utf-8"' >> /root/.bashrc
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# Set hostname and localhost
echo "moxy.local" > /etc/hostname
echo "127.0.0.1     moxy.local" >> /etc/hosts
hostnamectl set-hostname moxy.local

# DONE preparing system
echo "___@@@ Done preparing system"
echo " "

# DATABASE
# Install mysql using mariadb
echo " "
echo "___@@@ Install mysql..."
echo "mariadb-server-5.5 mysql-server/root_password password $MYSQL_PASSWD" | debconf-set-selections
echo "mariadb-server-5.5 mysql-server/root_password_again password $MYSQL_PASSWD" | debconf-set-selections
apt-get install -y mariadb-server libmariadbclient-dev libssl-dev mysql-utilities

# Setup databases
echo " "
echo "___@@@ Setup databases..."
mysql -u root -p$MYSQL_PASSWD -e "CREATE DATABASE moxy_django DEFAULT CHARACTER SET utf8";
mysql -u root -p$MYSQL_PASSWD -e "CREATE DATABASE moxy_magento DEFAULT CHARACTER SET utf8";
mysql -u root -p$MYSQL_PASSWD -e "CREATE DATABASE bilna_magento DEFAULT CHARACTER SET utf8";
mysql -u root -p$MYSQL_PASSWD -e "CREATE DATABASE bilna_django DEFAULT CHARACTER SET utf8";
mysql -u root -p$MYSQL_PASSWD -e "GRANT ALL ON *.* to root@'%' IDENTIFIED BY '$MYSQL_PASSWD'";
mysql -u root -p$MYSQL_PASSWD -e "flush privileges";

# INSTALATION
# Install magento related
echo " "
echo "___@@@ Install magento related..."
apt-get install -y libcurl3 php5-curl php5-gd php5-mcrypt php5-mysql php5-fpm php5-cli
apt-get install -y redis-server php5-redis git

# Install nginx
echo " "
echo "___@@@ Install nginx..."
apt-get install -y nginx

# Install nodejs and less
echo " "
echo "___@@@ Install nodejs and less..."
apt-get install -y nodejs
npm install -g less

# Install python related
echo " "
echo "___@@@ Install python related..."
apt-get install -y python-setuptools python-dev build-essential python-pip
apt-get install -y libjpeg-dev
apt-get install libffi-dev  # need by bpython :)
pip install --upgrade pip
pip install --upgrade virtualenv virtualenvwrapper supervisor

# Update profile
echo " "
echo "___@@@ Update .bashrc profile..."
echo ' ' >> /home/vagrant/.bashrc
echo 'export LANG="en_US" LC_ALL="en_US.utf-8"' >> /home/vagrant/.bashrc
echo ' ' >> /home/vagrant/.bashrc
echo '# virtualenvwrapper' >> /home/vagrant/.bashrc
echo 'export WORKON_HOME="~/.virtualenvs"' >> /home/vagrant/.bashrc
echo 'export PROJECT_HOME="/vagrant/src"' >> /home/vagrant/.bashrc
echo 'VIRTUALENVWRAPPER_PYTHON="/usr/bin/python"' >> /home/vagrant/.bashrc
echo 'source `which virtualenvwrapper.sh`' >> /home/vagrant/.bashrc
chown -R vagrant:vagrant /home/vagrant/.bashrc

# Create moxy virtual env
echo " "
echo "___@@@ Create moxy virtual env..."
sudo -u vagrant virtualenv /home/vagrant/.virtualenvs/moxy

# Install django requirement
echo " "
echo "___@@@ Install django requirement..."
sudo -u vagrant -H /home/vagrant/.virtualenvs/moxy/bin/pip install -r /vagrant/src/moxy/moxy/requirements.txt
sudo -u vagrant -H /home/vagrant/.virtualenvs/moxy/bin/pip install MySQL-python whoosh gunicorn bpython

# SETTING UP
# Setup magento moxy
echo " "
echo "___@@@ Setup moxy magento..."
sudo -u vagrant cp /vagrant/provisions/templates/magento/moxy/local.xml /vagrant/src/moxy-indonesia/app/etc/
echo " "
echo "___@@@ Setup bilna magento..."
sudo -u vagrant cp /vagrant/provisions/templates/magento/bilna/local.xml /vagrant/src/bilna-magento/app/etc/

# Import magento development data
echo " "
echo "___@@@ Import moxy magento dev data..."
mysql -u root -p$MYSQL_PASSWD moxy_magento < /vagrant/provisions/db/moxy/magento_moxy_dump.sql
echo " "
echo "___@@@ Import bilna magento dev data..."
mysql -u root -p$MYSQL_PASSWD -e "SET GLOBAL FOREIGN_KEY_CHECKS=0";
mysql -u root -p$MYSQL_PASSWD -e "SET GLOBAL SQL_MODE='NO_AUTO_VALUE_ON_ZERO'";
for i in {1..27}; do
    echo "___@@@ Importing $i.sql"
    mysql -u root -p$MYSQL_PASSWD bilna_magento < /vagrant/provisions/db/bilna/$i.sql
done
echo "___@@@ Importing core_config_data"
mysql -u root -p$MYSQL_PASSWD bilna_magento < /vagrant/provisions/db/bilna/core_config_data.sql
mysql -u root -p$MYSQL_PASSWD -e "SET GLOBAL FOREIGN_KEY_CHECKS=1";
mysql -u root -p$MYSQL_PASSWD -e "UPDATE `bilna_magento`.`core_config_data` SET `value`= '0' WHERE `core_config_data`.`config_id`=1104";

# Setup magento admin password
echo " "
echo "___@@@ Setup moxy magento admin password..."
mysql -u root -p$MYSQL_PASSWD moxy_magento -e "UPDATE admin_user SET password=CONCAT(MD5('123admin12345'), ':123') WHERE username='admin'";
echo " "
echo "___@@@ Setup bilna magento admin password..."
mysql -u root -p$MYSQL_PASSWD bilna_magento -e "UPDATE admin_user SET password=CONCAT(MD5('123admin12345'), ':123') WHERE username='eka'";

# Setup nginx
echo " "
echo "___@@@ Setup nginx..."
cp /vagrant/provisions/templates/nginx/moxy.local.conf /etc/nginx/sites-available/
cp /vagrant/provisions/templates/nginx/bilna.local.conf /etc/nginx/sites-available/
cp /vagrant/provisions/templates/nginx/sellercenter.moxy.local.conf /etc/nginx/sites-available/
cp /vagrant/provisions/templates/nginx/api.moxy.local.conf /etc/nginx/sites-available/
cp /vagrant/provisions/templates/nginx/magazine.bilna.local.conf /etc/nginx/sites-available/
[ ! -h /etc/nginx/sites-enabled/moxy.local.conf ] && ln -s /etc/nginx/sites-available/moxy.local.conf /etc/nginx/sites-enabled/moxy.local.conf
[ ! -h /etc/nginx/sites-enabled/bilna.local.conf ] && ln -s /etc/nginx/sites-available/bilna.local.conf /etc/nginx/sites-enabled/bilna.local.conf
[ ! -h /etc/nginx/sites-enabled/sellercenter.moxy.local.conf ] && ln -s /etc/nginx/sites-available/sellercenter.moxy.local.conf /etc/nginx/sites-enabled/sellercenter.moxy.local.conf
[ ! -h /etc/nginx/sites-enabled/api.moxy.local.conf ] && ln -s /etc/nginx/sites-available/api.moxy.local.conf /etc/nginx/sites-enabled/api.moxy.local.conf
[ ! -h /etc/nginx/sites-enabled/magazine.bilna.local.conf ] && ln -s /etc/nginx/sites-available/magazine.bilna.local.conf /etc/nginx/sites-enabled/magazine.bilna.local.conf

# Setup php-fpm
echo " "
echo "___@@@ Setup php-fpm..."
cp /vagrant/provisions/templates/php-fpm/www.conf /etc/php5/fpm/pool.d/

# TODO: install magento crontab

# Setup django server
echo " "
echo "___@@@ Setup django server..."
echo "___@@@ Django :: Copy local setting file..."
sudo -u vagrant cp /vagrant/src/moxy/moxy/settings/local_magazine.py.example /vagrant/src/moxy/moxy/settings/local_magazine.py
sudo -u vagrant cp /vagrant/src/moxy/moxy/settings/local_sellercenter.py.example /vagrant/src/moxy/moxy/settings/local_sellercenter.py
echo " "
echo "___@@@ Django :: Migrate db..."
sudo -u vagrant -H /home/vagrant/.virtualenvs/moxy/bin/python /vagrant/src/moxy/moxy/manage.py makemigrations --settings=settings.magazine
sudo -u vagrant -H /home/vagrant/.virtualenvs/moxy/bin/python /vagrant/src/moxy/moxy/manage.py migrate --noinput --no-initial-data --settings=settings.magazine
echo " "
echo "___@@@ Django :: Collect static..."
sudo -u vagrant -H /home/vagrant/.virtualenvs/moxy/bin/python /vagrant/src/moxy/moxy/manage.py collectstatic --noinput --settings=settings.magazine
echo " "
echo "___@@@ Django :: Running vagrant setup script..."
sudo -u vagrant -H /home/vagrant/.virtualenvs/moxy/bin/python /vagrant/src/moxy/moxy/manage.py vagrant_setup --settings=settings.magazine

# Setup sellercenter frontend
echo " "
echo "___@@@ Install sellercenter frontend..."
npm install -g ember-cli bower phantomjs
cd /vagrant/src/sellercenter && sudo -u vagrant -H npm install && sudo -u vagrant -H bower install
cd /vagrant/src/sellercenter && sudo -u vagrant -H ember build

# Setup Supervisord
echo " "
echo "___@@@ Setting supervisord..."
[ ! -d /etc/supervisord.d ] && mkdir /etc/supervisord.d
cp /vagrant/provisions/templates/supervisord/supervisord.conf /etc/supervisord.conf
cp /vagrant/provisions/templates/supervisord/init.sh /etc/init.d/supervisord
chmod ugo+x /etc/init.d/supervisord
cp /vagrant/provisions/templates/supervisord/magazine.ini /etc/supervisord.d
cp /vagrant/provisions/templates/supervisord/sellercenter.ini /etc/supervisord.d
update-rc.d supervisord defaults

# Cleanup packages
echo " "
echo "___@@@ Cleanup packages..."
apt-get autoremove

# Restart services
echo " "
echo "___@@@ Restart services..."
service mysql restart
service supervisord restart
service nginx restart
service php5-fpm restart

# Extra
echo " "
echo "___@@@ Extra"
chown -R vagrant:vagrant /usr/local/lib
echo " "
echo "___@@@ Install phpmyadmin"
apt-get install -y phpmyadmin
chown -R vagrant:vagrant /usr/share/phpmyadmin
ln -sf /usr/share/phpmyadmin /usr/share/nginx/html/phpmyadmin
chown -h vagrant:vagrant /usr/share/nginx/html/phpmyadmin
cp /vagrant/provisions/templates/phpmyadmin/config-db.php /etc/phpmyadmin/config-db.php

echo " "
echo "Provision is done!"
