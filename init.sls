# Written by Miikka Valtonen 2018
# Please don't use this as is in an important environment.
# I take no responsibility for anything 
# Making sure necessities are installed

programs:
  pkg.installed:
    - pkgs:
      - apache2
      - mysql-server
      - libapache2-mod-php7.0

# Downloading nextcloud files from their server

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

modules:
  apache_module.enabled:
    - name:
      - headers
      - env
      - dir
      - mime

# Enabling nextcloud site and placing site .conf files, restarting apache after

/etc/apache2/sites-enabled/nextcloud.conf:
  file.symlink:
    - target: /etc/apache2/sites-available/nextcloud.conf

/etc/apache2/sites-available/nextcloud.conf:
  file.managed:
    - source: salt://nextcloudwithsalt/nextcloud.conf

apache2.service:
  service.running:
    - watch: /etc/apache2/sites-available/nextcloud.conf

# Running a MySQL command that creates the necessary database for nextcloud to work
# NOTE!!!! in this case, we are setting the nextcloud users password as nextcloud
# CHANGE THE PASSWORD if you use this state in production. 
# You can do this by changing the word after IDENTIFIED BY 'password';

mysql:
  mysql_query.run:
    - order: 2
    - database: '*'
    - query: |
      - CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'nextcloud';
      - CREATE DATABASE IF NOT EXISTS nextcloud;
      - GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost' IDENTIFIED BY 'nextcloud';

# Making sure www-data has full access to nextcloud directories

ownership:
  cmd.run:
    - name: sudo chown -R www-data:www-data /var/www/nextcloud

# Performing the actual installation.
# PLEASE NOTE!!!!!!!!!!! You will have to again edit the passwords 
# --database-pass should be the SAME PASSWORD you wrote for the root user when you installed MySQL.
# --admin-pass should be admin password that you will want to log into nextcloud with

installation:
  cmd.run:
    - name: cd /var/www/nextcloud && sudo -u www-data php occ maintenance:install --database "mysql" --database-name "nextcloud" --database-user "root" --database-pass "password" --admin-user "admin" --admin-pass "password"
