make install
make samples

find /etc/asterisk /var/*/asterisk /usr/*/asterisk /usr/lib64/asterisk ! -user asterisk -exec chown asterisk:asterisk {} +
chmod -R 750 /var/spool/asterisk

cd /
rm -rf /usr/src/asterisk \
       /usr/src/codecs

yum -y clean all
rm -rf /var/cache/yum/*

exec rm -f /build-asterisk.sh
