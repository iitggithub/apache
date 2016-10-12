FROM centos:7.2.1511

MAINTAINER "The Ignorant IT Guy" <iitg@gmail.com>

# Enables epel repo and remi repo w/ php 5.6 enabled.
COPY epel.repo /etc/yum.repos.d/epel.repo
COPY remi.repo /etc/yum.repos.d/remi.repo

RUN yum -y --nogpgcheck install \
                                httpd \
                                mod_ssl \
                                aide \
                                mailx \
                                php \
                                php-devel \
                                php-suhosin && \
                                yum clean all

# Secure Apache server as much as we can
COPY secure.conf /etc/httpd/conf.d/secure.conf

# Install the default AIDE configuration
COPY aide.conf /var/lib/aide/aide.conf

RUN sed -i 's/<Directory "\/var\/www\/html">/<Directory "\/var\/www\/html">\n<LimitExcept GET POST HEAD>\ndeny from all\n<\/LimitExcept>/1' /etc/httpd/conf/httpd.conf 

RUN sed -i 's/Options Indexes.*/Options -Indexes -Includes +FollowSymLinks/g' /etc/httpd/conf/httpd.conf

RUN sed -i -e 's/SSLProtocol.*/SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1/g' \
           -e 's/^SSLCipherSuite.*/SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256/g' \
           -e 's/#SSLHonorCipherOrder on/SSLHonorCipherOrder on\nHeader add Strict-Transport-Security "max-age=15768000"/g' \
           /etc/httpd/conf.d/ssl.conf

RUN sed -i -e 's/Listen 443 https/Listen 443 https\nSSLCompression off\nSSLUseStapling on\nSSLStaplingResponderTimeout 5\nSSLStaplingReturnResponderErrors off\nSSLStaplingCache shmcb:\/var\/run\/ocsp\(128000\)\n/g' \
           /etc/httpd/conf.d/ssl.conf

# Disable unused modules
RUN sed -i 's/LoadModule info_module/#LoadModule info_module/g' /etc/httpd/conf.modules.d/00-base.conf

# Allow overrides. Surely, there's gotta be a better way to do this...
RUN awk '/    AllowOverride None/{count++;if(count==2){sub("    AllowOverride None","    AllowOverride All")}}1' /etc/httpd/conf/httpd.conf >/etc/httpd/conf/httpd.conf.new
RUN mv /etc/httpd/conf/httpd.conf.new /etc/httpd/conf/httpd.conf

# Make sure /var/www/html knows who's boss.
RUN chown -R apache:apache /var/www/html

VOLUME ["/var/www/html"]
VOLUME ["/etc/httpd/ssl"]
VOLUME ["/etc/httpd/conf.d"]
VOLUME ["/var/lib/aide"]
VOLUME ["/var/log/httpd"]

EXPOSE 80
EXPOSE 443

COPY run.sh /run.sh
RUN chmod +x /run.sh

RUN /usr/sbin/aide --init -c /var/lib/aide/aide.conf && mv -f /tmp/aide.db.new.gz /var/lib/aide/aide.db.gz
RUN echo "0 2 * * * root test -n \"${AIDE_EMAIL}\" && test -n \"${AIDE_SLEEP}\" && sleep ${AIDE_SLEEP} && /usr/sbin/aide --check -c /var/lib/aide/aide.conf 2>&1 | mail -s \"[REPORT] AIDE Integrity Check on `hostname`\" ${AIDE_EMAIL}" >>/etc/crontab
RUN echo "0 2 * * * root test -n \"${AIDE_EMAIL}\" && test -z \"${AIDE_SLEEP}\" && /usr/sbin/aide --check -c /var/lib/aide/aide.conf 2>&1 | mail -s \"[REPORT] AIDE Integrity Check on `hostname`\" ${AIDE_EMAIL}" >>/etc/crontab

CMD ["/run.sh"]
