# Written by Miikka Valtonen 2018
# Written with loads of help from various sources, which are credited where proper
# Please don't use this as is in an important environment
# I take no responsibility for anything 


# Making sure necessities are installed

programs:
  pkg.installed:
    - pkgs:
      - apache2
      - libapache2-mod-php7.0

# NOTE!!!!!!!!!!!!!!!!!!! the password listed here will be the SQL root users password. You want to change this.
# Huge thanks to Tero Karvinen http://terokarvinen.com/2018/mysql-automatic-install-with-salt-preseed-database-root-password
# I had a lot of problems with preseeding, but this one seems to have done it.

debconf-utils: pkg.installed

mysqlroot:
  debconf.set:
    - data:
        'mysql-server/root_password': {'type': 'password', 'value': 'sqlroot'}
        'mysql-server/root_password_again': {'type': 'password', 'value': 'sqlroot'}

mysql-server: pkg.installed

mysql-client: pkg.installed

# Downloading nextcloud files from their server

nextclouddl:
  cmd.run:
    - name: sudo wget https://download.nextcloud.com/server/releases/nextcloud-13.0.2.tar.bz2 -P /var/www/

# Extracting the files https://docs.saltstack.com/en/latest/ref/states/all/salt.states.archive.html

nextcloudxf:
  cmd.run:
    - name: sudo tar -xf /var/www/nextcloud-13.0.2.tar.bz2

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

/etc/apache2/mods-enabled/headers.load:
  file.symlink:
    - target: /etc/apache2/mods-available/headers.load

/etc/apache2/mods-enabled/env.load:
  file.symlink:
    - target: /etc/apache2/mods-available/env.load

/etc/apache2/mods-enabled/dir.load:
  file.symlink:
    - target: /etc/apache2/mods-available/dir.load

/etc/apache2/mods-enabled/dir.conf:
  file.symlink:
    - target: /etc/apache2/mods-available/dir.conf

/etc/apache2/mods-enabled/mime.load:
  file.symlink:
    - target: /etc/apache2/mods-available/mime.load

/etc/apache2/mods-enabled/mime.conf:
  file.symlink:
    - target: /etc/apache2/mods-available/mime.conf

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

# https://stackoverflow.com/questions/32362573/salt-stack-mysql-grants-present-underscore-wildcard
# https://docs.saltstack.com/en/2017.7/ref/states/all/salt.states.mysql_database.html
# https://docs.saltstack.com/en/latest/ref/states/all/salt.states.mysql_user.html
# https://github.com/saltstack-formulas/mysql-formula
# NOTE!!!! in this case, we are setting the nextcloud users password as nextcloud
# CHANGE THE PASSWORD if you use this state in production. 

mysql1:
  mysql_query.run:
    - database: mysql
    - connection_user: root
    - connection_pass: sqlroot
    - connection_host: localhost
    - connection_charset: utf8
    - query: "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'nextcloud';"

mysql2:
  mysql_query.run:
    - database: mysql
    - connection_user: root
    - connection_pass: sqlroot
    - connection_host: localhost
    - connection_charset: utf8
    - query: "CREATE DATABASE IF NOT EXISTS nextcloud;"

mysql3:
  mysql_query.run:
    - database: mysql
    - connection_user: root
    - connection_pass: sqlroot
    - connection_host: localhost
    - connection_charset: utf8
    - query: "GRANT ALL PRIVILEGES ON nextcloud.* to 'nextcloud'@'localhost' IDENTIFIED BY 'nextcloud';"


# Making sure www-data has full access to nextcloud directories

ownership:
  cmd.run:
    - name: sudo chown -R www-data:www-data /var/www/nextcloud

# Performing the actual installation.
# PLEASE NOTE!!!!!!!!!!! You will have to again edit the passwords 
# --database-pass should be the SAME PASSWORD you wrote for the root user when you installed MySQL
# --admin-pass should be admin password that you will want to log into nextcloud with

installation:
  cmd.run:
    - name: cd /var/www/nextcloud/nextcloud/ && sudo -u www-data php occ maintenance:install --database "mysql" --database-name "nextclouddb" --database-user "root" --database-pass "sqlroot" --admin-user "admin" --admin-pass "password"
