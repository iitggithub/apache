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

# Apache gets grumpy about PID files pre-existing
rm -vf /var/run/httpd/httpd.pid

echo "httpd starting as process 1 ..."
exec httpd -DFOREGROUND
