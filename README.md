# Hello! This is my Salt state for installing NextCloud.

## My objective was to automate the installation of a cloud storage server. This turned out to be a lot more difficult than I anticipated, but in the end I somehow managed to make it work. If you can't stand looking at workarounds for workarounds you might want to look away.

I do NOT encourage you to use this anywhere where you care about things. I see this state as a tool to use when quick access to a cloud server is needed. 

A couple of things to note before installing:

There are a few instances where you should change some passwords inside the init.sls file. 
By default very bad placeholders are used, which you should not use if you plan to use this for anything else than to see if it works.
Changing them is simple however, and I left some comments noting where and what should be changed.

If you run the state more than once, nothing should break but will get errors from the minion.

Some things that I should improve on/fix, that a proper release would have:

- Generated passwords used via pillars
- A better way to download and extract the NextCloud files
- SQL Usage is also a bit silly, as Salt offers better SQL modules, but they refused to work.


### Installation:

### On your master:

### $ sudo git clone https://github.com/Miikkb/nextcloudwithsalt /srv/salt/nextcloudwithsalt

### $ sudo sh /srv/salt/nextcloudwithsalt/nextcloudwithsalt.sh

### And you should be all set.

### If things don't work and you don't see anything at address/nextcloud, see if your port forwarding is ok.

### Also, you may need to add your IP address to the trusted domains list in nextcloud's config.php file, /var/www/nextcloud/config/config.php:

### 'trusted_domains' =>
### array (
###  0 => 'youraddressordomain',
###  1 => 'anotheraddress',
### ),
