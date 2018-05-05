# Written by Miikka Valtonen 2018
# Please don't use this as is in an important environment.
# I take no responsibility for anything 
# Making sure necessities are installed

programs:
  pkg.installed:
    - pkgs:
      - apache2
      - libapache2-mod-php7.0
      - curl

# Credit to Tero Karvinen http://terokarvinen.com & Joona Leppalahti https://github.com/joonaleppalahti/CCM/blob/master/salt/srv/salt/mysql.sls
#!pyobjects

Pkg.installed("mysql-client")
# use pillars in production
pw="silli"

Pkg.installed("debconf-utils")
with Debconf.set("mysqlroot", data=
 {
 'mysql-server/root_password':{'type':'password', 'value':pw},
 'mysql-server/root_password_again': {'type':'password', 'value': pw}
 }):
 Pkg.installed("mysql-server")

# Downloading nextcloud files from their server

mkdir:
  cmd.run:
    - name: sudo mkdir /var/www/nextcloud

nextclouddl:
  cmd.run:
    - name: curl -L https://download.nextcloud.com/server/releases/nextcloud-13.0.2.tar.bz2 -o /var/www/nextcloud/
    - creates: /var/www/nextcloud/nextcloud-13.0.2.tar.bz2

# Extracting the files

nextcloudxf:
  cmd.run:
    - name: tar -xf /var/www/nextcloud/nextcloud-13.0.2.tar.bz2

# Installing various php-related dependencies

prereqs:
  pkg.installed:
    - pkgs:
      - php7.0-gd
      - php7.0-json
      - php7.0-mysql
      - php7.0-curl
      - php7.0-mbstring
      - php7.0-intl
      - php7.0-mcrypt
      - php-imagick
      - php7.0-xml
      - php7.0-zip

# Enabling apache modules

headers:
  apache_module.enabled:
    - name:
      - headers

env:
  apache_module.enabled:
    - name:
      - env

dir:
  apache_module.enabled:
    - name:
      - dir

mime:
  apache_module.enabled:
    - name:
      - mime

# Enabling nextcloud site and placing site .conf files, restarting apache after

/etc/apache2/sites-available/nextcloud.conf:
  file.managed:
    - source: salt://nextcloudwithsalt/nextcloud.conf

/etc/apache2/sites-enabled/nextcloud.conf:
  file.symlink:
    - target: /etc/apache2/sites-available/nextcloud.conf

apache2.service:
  service.running:
    - watch:
      - file: /etc/apache2/sites-available/nextcloud.conf

# trying sql shit :(
# NOTE!!!! in this case, we are setting the nextcloud users password as nextcloud
# CHANGE THE PASSWORD if you use this state in production. 
# You can do this by changing the word after IDENTIFIED BY 'password';

nextclouddb:
  mysql_database.present

nextcloud:
  mysql_user.present:
    - host: localhost
    - password: "password"    

nextcloudsqlgrant:
  mysql_grants.present:
    - grant: all privileges
    - database: nextclouddb
    - user: nextcloud
    - host: localhost
    - escape: False

# Making sure www-data has full access to nextcloud directories

ownership:
  cmd.run:
    - name: sudo chown -R www-data:www-data /var/www/nextcloud

# Performing the actual installation.
# PLEASE NOTE!!!!!!!!!!! You will have to again edit the passwords 
# --database-pass should be the SAME PASSWORD you wrote for the root user when you installed MySQL, in this case it's silli
# --admin-pass should be admin password that you will want to log into nextcloud with

installation:
  cmd.run:
    - name: cd /var/www/nextcloud && sudo -u www-data php occ maintenance:install --database "mysql" --database-name "nextclouddb" --database-user "root" --database-pass "silli" --admin-user "admin" --admin-pass "password"
