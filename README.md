# Apache/PHP Based Docker Container

This image is a CentOS 7 based container which contains slightly more secure versions of Apache 2.4.6 w/ openssl and mod_security web application firewall and AIDE (Advanced Intrusion Detection Environment) file and directory integrity checker.

Versions 5+ include a PHP (depending which version you use) complete with the PHP suhosin patch which was was designed to protect servers and users from known and unknown flaws in PHP applications and the PHP core.

# Notes

The dockerfile is based on some hardening guides for php, apache and openssl.

# Supported PHP versions

PHP Version | Git branch | Tag name
------------| ---------- |---------
5.6         | master     | latest
7.1         | 7.1        | 7.1
7.0         | 7.0        | 7.0
5.6         | 5.6        | 5.6
5.5         | 5.5        | 5.5
5.4         | 5.4        | 5.4
none        | 2.4.6      | 2.4.6


# Getting Started

There's two ways to get up and running, the easy way and the hard way.

## The Hard Way (Standalone)

Fire up apache

```
docker run -d --name apache -p 80:80 -p 443:443 -v /data/apache/conf.d:/data/conf.d -v /data/apache/html:/var/www/html:ro -v /data/apache/ssl:/etc/httpd/ssl:ro -v /data/apache/aide:/var/lib/aide -v /data/apache/log:/var/log/httpd iitgdocker/apache:latest
```

## The Easy Way (Docker Compose)

The github repo contains a docker-compose.yml you can use as a base. The docker-compose.yml is compatible with docker-compose 1.5.2+.

```
web-server:
  image: iitgdocker/apache:latest
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - /data/apache/conf.d:/data/conf.d
    - /data/apache/html:/var/www/html:ro
    - /data/apache/ssl:/etc/httpd/ssl:ro
    - /data/apache/aide:/var/lib/aide
    - /data/apache/log:/var/log/httpd
  #environment:
    #- APACHE_SERVERNAME=wingsof.chicken.com
    - MOD_SECURITY_ENABLE=1
```

By running 'docker-compose up -d' from within the same directory as your docker-compose.yml, you'll be able to bring the container up.

# Volumes

## SSL Certificates

If you want to use your own SSL certificates you'll need to mount a volume onto /etc/httpd/ssl. Your certificates MUST be named as follows:

```
server.crt
server.key
server-chain.crt
ca-bundle.crt
```

run.sh will check for each of those files before modifying /etc/httpd/conf.d/ssl.conf accordingly.

## Apache Configuration Files /data/conf.d

Apache will look in /data/conf.d for any files that end in .conf. By mounting a volume onto /data/conf.d you can add your own application specific configuration files which will be loaded when the container starts.

## Apache Document Root /var/www/html

The default /var/www/html directory is available for your web files. Stick them here. Using the default configuration above, these directories will be mounted read only (ro) meaning that they cannot be modified from within the container. Obviously, if you have dynamic content or you need to support file uploads within this directory, you can remove the :ro from the volume mount command.

## Apache logs directory /var/log/httpd

Exposes the apache log directory. This is useful for palming the logs off to a centralised syslog server or something like fail2ban to automatically ban troublesome IPs.

## AIDE Integrity Database /var/lib/aide

/var/lib/aide contains the AIDE integrity database file aide.db.tar.gz. If this file does not exist when the container starts, it will be created automatically. It is strongly recommended that this file be backed up to a secure location. This database is your baseline from which all filesystem changes are compared against so keep a copy somewhere safe.

If run.sh finds a file called aide.conf in this directory, AIDE will use this instead of its default configuration file.

If changes are made to the container after its been started, you'll probably need to update the AIDE integrity database. You can do this from outside of the container by running the following command against your container:

Replace container_name with the name/id of your running container.

```
docker exec -it <container_name> /usr/sbin/aide --init
docker exec -it <container_name> mv -f /tmp/aide.db.new.gz /var/lib/aide/aide.db.gz
```

# Environment Variables

Other than the standard mysql container environment variables which can be better explained on their respective docker pages, there aren't any to note (yet).

Variable                 | Default Value (docker-compose) | Description
------------------------ | ------------------------------ |------------
APACHE_SERVERNAME        | unset                          | Sets the Apache server name.
MOD_SECURITY_ENABLE      | 1                              | Enables the mod_security web application firewall. 0 to disable.

# Apache Mod Security

This docker image has apache mod_security enabled by default using the 2.2.9 ruleset. If you don't know, ModSecurity is one of the Apache server modules that provides website protection by defending from hackers and other malicious attacks. It is a set of rules with regular expressions that helps to instantly ex-filtrate the commonly known exploits. Modsecurity obstructs the processing of invalid data (code injection attacks) to reinforce and nourish server's security.

So in other words, don't disable it if you can help it!

The ruleset will be copied into /data/conf.d at runtime where you can modify it as necessary.

# The End
