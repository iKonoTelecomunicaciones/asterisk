#!/bin/bash

PROGNAME=$(basename $0)

if test -z ${ASTERISK_VERSION}; then
  echo "${PROGNAME}: ASTERISK_VERSION required" >&2
  exit 1
fi

set -ex

useradd --system asterisk

mkdir -p /usr/src/asterisk \
         /usr/src/asterisk/addons

cd /usr/src/asterisk/addons
curl -vsL http://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-addons-${ASTERISK_ADDONS_VERSION}.tar.gz | tar --strip-components 1 -xz

cd /usr/src/asterisk

# 1.5 jobs per core works out okay
: ${JOBS:=$(( $(nproc) + $(nproc) / 2 ))}

mkdir -p /etc/asterisk/ \
         /var/spool/asterisk/fax

./configure
make -j ${JOBS}
sed -i -e "
s/\(MENUSELECT_CORE_SOUNDS=\).*/\1CORE-SOUNDS-EN-WAV CORE-SOUNDS-EN-ULAW CORE-SOUNDS-EN-ALAW CORE-SOUNDS-EN-GSM CORE-SOUNDS-EN-G729 CORE-SOUNDS-EN-G722/g
s/\(MENUSELECT_MOH=\).*/\1MOH-FREEPLAY-WAV MOH-FREEPLAY-ULAW MOH-FREEPLAY-ALAW MOH-FREEPLAY-GSM MOH-FREEPLAY-G729 MOH-FREEPLAY-G722/g
s/\(MENUSELECT_EXTRA_SOUNDS=\).*/\1EXTRA-SOUNDS-EN-WAV EXTRA-SOUNDS-EN-ULAW EXTRA-SOUNDS-EN-ALAW EXTRA-SOUNDS-EN-GSM EXTRA-SOUNDS-EN-G729 EXTRA-SOUNDS-EN-G722/g
s/\(MENUSELECT_IKONO_SOUNDS=\).*/\1IKONO-SOUNDS-ES-WAV IKONO-SOUNDS-ES-ULAW IKONO-SOUNDS-ES-ALAW IKONO-SOUNDS-ES-GSM IKONO-SOUNDS-ES-G729 IKONO-SOUNDS-ES-G722/g
" menuselect.makeopts
make install
make config

make samples
make dist-clean

# set runuser and rungroup
sed -i -E 's/^;(run)(user|group)/\1\2/' /etc/asterisk/asterisk.conf
sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk

cd /usr/src/asterisk/addons

./configure --libdir=/usr/lib64
make -j ${JOBS}

sed -i -e "
s/\(MENUSELECT_RES=\).*/\1MENUSELECT_RES=res_config_mysql/g
" menuselect.makeopts

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
