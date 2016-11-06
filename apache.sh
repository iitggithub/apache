#!/bin/sh
set -e

# This file does lots of running around before launching httpd

# Try to set servername
if [ -n "${APACHE_SERVERNAME}" ]
  then
  echo "Setting ServerName to '${APACHE_SERVERNAME}' in /etc/httpd/conf.d/server_name.conf."
  echo "ServerName ${APACHE_SERVERNAME}" >/etc/httpd/conf.d/server_name.conf
fi

# Configure SSL certificates if they exist
test -f /etc/httpd/ssl/server.crt && echo "Found /etc/httpd/ssl/server.crt. Configuring /etc/httpd/conf.d/ssl.conf." && sed -i "s/^SSLCertificateFile.*/SSLCertificateFile \/etc\/httpd\/ssl\/server.crt/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/server.key && echo "Found /etc/httpd/ssl/server.key. Configuring /etc/httpd/conf.d/ssl.conf." && sed -i "s/^SSLCertificateKeyFile.*/SSLCertificateKeyFile \/etc\/httpd\/ssl\/server.key/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/server-chain.crt && echo "Found /etc/httpd/ssl/server-chain.crt. Configuring /etc/httpd/conf.d/ssl.conf." && sed -i "s/^#SSLCertificateChainFile.*/SSLCertificateChainFile \/etc\/httpd\/ssl\/server-chain.crt/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/ca-bundle.crt && echo "Found /etc/httpd/ssl/ca-bundle.crt. Configuring /etc/httpd/conf.d/ssl.conf." && sed -i "s/^#SSLCACertificateFile.*/SSLCACertificateFile \/etc\/httpd\/ssl\/ca-bundle.crt/g" /etc/httpd/conf.d/ssl.conf

if [ -f /var/lib/aide/aide.conf ]
  then
  # override the existing AIDE configuration file if exists
  # in the database directory.
  echo "Found /var/lib/aide/aide.conf. Overriding the default configuration with this."
  ln -sf /var/lib/aide/aide.conf /etc/aide.conf
  chmod 600 /var/lib/aide/aide.conf
fi

# Move modsecurity files to the custom data
# directory so the user can edit them as they need to.
if [ ! -f modsecurity_crs_10_setup.conf ]
  then
  tar zxvf /tmp/mod_security.tar.gz -C /data/conf.d
fi

# Redirect mod_security. This is done at runtime to make sure the file can be edited by
# other docker images

sed -i 's/IncludeOptional modsecurity.d/IncludeOptional \/data\/conf.d/g' /etc/httpd/conf.d/mod_security.conf

# Allows the user to turn mod_security off
if [ -n "${MOD_SECURITY_ENABLE}" ]
  then
  if [ ${MOD_SECURITY_ENABLE} -eq 0 ]
    then
    sed -i 's/SecRuleEngine On/SecRuleEngine DetectionOnly/g' /etc/httpd/conf.d/mod_security.conf
    else
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/httpd/conf.d/mod_security.conf
  fi
fi

# Apache gets grumpy about PID files pre-existing
rm -vf /var/run/httpd/httpd.pid

if [ ! -f /var/lib/aide/aide.db.gz ]
  then
  echo "Generating a new AIDE database in /var/lib/aide/aide.db.gz..."
  /usr/sbin/aide --init && mv -vf /tmp/aide.db.new.gz /var/lib/aide/aide.db.gz
fi

echo "httpd starting as process 1 ..."
exec httpd -DFOREGROUND
