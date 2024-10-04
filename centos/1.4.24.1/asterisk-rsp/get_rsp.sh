#/bin/bash

ASTERISK_VERSION=${1-"1.4.24.1"}
SVN_USER=myuser
SVN_PASS=mypass
SVN_DOMAIN=https://mydomain.com

#rm -rf asterisk-${ASTERISK_VERSION}
echo "Fetching Asterisk ${ASTERISK_VERSION} from git repository"
#wget https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz
#wget https://github.com/asterisk/asterisk/archive/refs/tags/${ASTERISK_VERSION}.tar.gz -O asterisk-${ASTERISK_VERSION}.tar.gz
#tar xvzf asterisk-${ASTERISK_VERSION}.tar.gz
#wget -qO- http://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-addons-${ASTERISK_ADDONS_VERSION}.tar.gz | tar -xz
wget -qO- https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz | tar -xz
echo "Asterisk fetch complete!"

echo "Feching lcdial from svn repository"
svn export --quiet --no-auth-cache --username $SVN_USER --password $SVN_PASS "$SVN_DOMAIN/svn/app_asterisk/app_lcdial/trunk/" asterisk-${ASTERISK_VERSION}/lcdial
echo "LCDial fetch complete!"

echo "Patching Asterisk in asterisk-${ASTERISK_VERSION}"
for patch_file in patches.txt patches_ikono.txt; do
    echo "Applying patches in file ${patch_file}"
    while read patch; do
      echo $patch
      patch -s -d asterisk-${ASTERISK_VERSION} -p0 -i $PWD/$patch
      n=$[0${n}+1];
      if [ $? -e 0 ]; then
        i=$[0${i}+1];
      fi
    done < <(cat ${patch_file} | grep -v "^#\|^$")
    echo "Applied ${i}/${n} patches"
done

find -name "*.orig" -delete

find -name "*menu*"
ls -lh 
