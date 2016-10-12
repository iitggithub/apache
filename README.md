# Apache/PHP Based Docker Container

This image is a CentOS 7 based container which contains slightly more secure versions of Apache 2.4.6, openssl and PHP w/ suhosin patch and AIDE (Advanced Intrusion Detection Environment) file and directory integrity checker.

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


# Getting Started

There's two ways to get up and running, the easy way and the hard way.

## The Hard Way (Standalone)

Fire up apache

```
docker run -d --name apache -p 80:80 -p 443:443 -v /data/apache/conf.d:/data/conf.d -v /data/apache/html:/var/www/html:ro -v /data/apache/ssl:/etc/httpd/ssl:ro -v /data/apache/aide:/var/lib/aide:ro -v /data/apache/log:/var/log/httpd iitgdocker/apache:latest
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
    - /data/apache/conf.d:/etc/httpd/conf.d
    - /data/apache/html:/var/www/html:ro
    - /data/apache/ssl:/etc/httpd/ssl:ro
    - /data/apache/aide:/var/lib/aide:ro
    - /data/apache/log:/var/log/httpd
  #environment:
    #- APACHE_SERVERNAME=wingsof.chicken.com
    #- AIDE_SERVERNAME=wingsof.chicken.com
    #- AIDE_EMAIL=me@chicken.com
    #- AIDE_SLEEP=43200
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

## Apache Configuration Files /etc/httpd/conf.d

Apache will look in /etc/httpd/conf.d for any files that end in .conf. By mounting a volume onto /etc/httpd/conf.d you can add your own application specific configuration files which will be loaded when the container starts.

## Apache Document Root /var/www/html

The default /var/www/html directory is available for your web files. Stick them here. Using the default configuration above, these directories will be mounted read only (ro) meaning that they cannot be modified from within the container. Obviously, if you have dynamic content or you need to support file uploads within this directory, you can remove the :ro from the volume mount command.

## Apache logs directory /var/log/httpd

Exposes the apache log directory. This is useful for palming the logs off to a centralised syslog server or something like fail2ban to automatically ban troublesome IPs.

## AIDE Integrity Database /var/lib/aide

/var/lib/aide contains the AIDE integrity database file aide.db.tar.gz. Using the default configuration above, these directories will be mounted read only (ro) meaning that they cannot be modified from within the container. This is an absolute MUST for this volume but will require you to make changes to these files on your container host.

Also, if make any changes to the container after its been built, you'll probably need to update the AIDE integrity database. You can do this from outside of the container by running the following command against your container:

Replace container_name with the name/id of your running container.

```
docker exec -it <container_name> /usr/bin/aide --init -c /var/lib/aide/aide.conf
docker cp <container_name>:/tmp/aide.db.new.gz <aide_database_dir>/aide.db.gz
```

# Environment Variables

Other than the standard mysql container environment variables which can be better explained on their respective docker pages, there aren't any to note (yet).

Variable                 | Default Value (docker-compose) | Description
------------------------ | ------------------------------ |------------
APACHE_SERVERNAME        | unset                          | Sets the Apache server name.
AIDE_SERVERNAME          | (containername)                | Sets the AIDE server name. Will use the container name if none specified.
AIDE_EMAIL               | unset                          | AIDE check output will be emailed to this address. No email is sent if not specified.
AIDE_SLEEP               | unset                          | Number of seconds to delay AIDE checking. If 2am GMT doesn't work for you enable this and delay the check.

# The End
