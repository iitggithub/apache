FROM centos:7.2.1511

MAINTAINER "The Ignorant IT Guy" <iitg@gmail.com>

# Make placeholder directories for the end user to mount against
RUN mkdir -p /data/conf.d

# Enables epel repo and remi repo w/ php enabled.
COPY epel.repo /etc/yum.repos.d/epel.repo
COPY remi.repo /etc/yum.repos.d/remi.repo

RUN yum -y --nogpgcheck install \
                                httpd \
                                mod_ssl \
                                mod_security \
                                aide \
                                mailx \
                                php \
                                php-devel \
                                php-suhosin && \
                                yum clean all


# Install the default AIDE configuration
COPY aide.conf /etc/aide.conf

RUN sed -i -e 's/<Directory "\/var\/www\/html">/<Directory "\/var\/www\/html">\n<LimitExcept GET POST HEAD>\ndeny from all\n<\/LimitExcept>/1' \
           -e 's/Options Indexes.*/Options -Indexes -Includes +FollowSymLinks/g' /etc/httpd/conf/httpd.conf

# Allow overrides. Surely, there's gotta be a better way to do this...
RUN awk '/    AllowOverride None/{count++;if(count==2){sub("    AllowOverride None","    AllowOverride All")}}1' /etc/httpd/conf/httpd.conf >/etc/httpd/conf/httpd.conf.new
RUN mv /etc/httpd/conf/httpd.conf.new /etc/httpd/conf/httpd.conf

# Secure Apache server as much as we can
COPY secure.conf /etc/httpd/conf.d/secure.conf

# Disable unused modules
RUN sed -i 's/LoadModule info_module/#LoadModule info_module/g' /etc/httpd/conf.modules.d/00-base.conf

# Configure SSL
RUN sed -i -e 's/SSLProtocol.*/SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1/g' \
           -e 's/^SSLCipherSuite.*/SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256/g' \
           -e 's/#SSLHonorCipherOrder on/SSLHonorCipherOrder on\nHeader add Strict-Transport-Security "max-age=15768000"/g' \
           -e 's/Listen 443 https/Listen 443 https\nSSLCompression off\nSSLUseStapling on\nSSLStaplingResponderTimeout 5\nSSLStaplingReturnResponderErrors off\nSSLStaplingCache shmcb:\/var\/run\/ocsp\(128000\)\n/g' \
           /etc/httpd/conf.d/ssl.conf

# Include end user apache configuration files
RUN echo -e "# Include custom apache configuration files\nIncludeOptional /data/conf.d/*.conf" >/etc/httpd/conf.d/custom.conf

# Make sure /var/www/html knows who's boss.
RUN chown -R apache:apache /var/www/html

VOLUME ["/var/www/html"]
VOLUME ["/etc/httpd/ssl"]
VOLUME ["/data/conf.d"]
VOLUME ["/var/lib/aide"]
VOLUME ["/var/log/httpd"]
VOLUME ["/etc/httpd/modsecurity.d/activated_rules"]

EXPOSE 80
EXPOSE 443

# This doesn't work from inside the container so its been disabled.
# Crontab AIDE check reports. Both require AIDE_EMAIL to be set to something.
# One requires a sleep timer and the other will only run if there isn't a sleep timer.
#RUN echo -e '# Period AIDE database checking.\n0 2 * * * root test -n "${AIDE_EMAIL}" && test -n "${AIDE_SLEEP}" && sleep ${AIDE_SLEEP} && /usr/sbin/aide --check -c /var/lib/aide/aide.conf 2>&1 | mail -s "[REPORT] AIDE Integrity Check on `hostname`" ${AIDE_EMAIL}\n0 2 * * * root test -n "${AIDE_EMAIL}" && test -z "${AIDE_SLEEP}" && /usr/sbin/aide --check -c /var/lib/aide/aide.conf 2>&1 | mail -s "[REPORT] AIDE Integrity Check on `hostname`" ${AIDE_EMAIL}' >>/etc/crontab

COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]
