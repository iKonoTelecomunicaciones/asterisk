#/bin/bash

source /.env

ASTERISK_VERSION=${1-"1.4.24.1"}

function validateExitStatus() {
  exit_status=$1
  if [ $exit_status -ne 0 ]; then
    echo "Error: $exit_status"
    exit 1
  fi
}

echo "Fetching Asterisk ${ASTERISK_VERSION} from git repository"
wget -qO- https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz | tar -xz
validateExitStatus $?
echo "Asterisk fetch complete!"

echo "Feching lcdial from git repository"
lcdial_path="asterisk-${ASTERISK_VERSION}/lcdial"
mkdir -p "$lcdial_path"
git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@${REPO_URL#https://} "$lcdial_path"
validateExitStatus $?
echo "LCDial fetch complete!"

echo "Patching Asterisk in asterisk-${ASTERISK_VERSION}"
for patch_file in patches.txt patches_ikono.txt; do
    echo "Applying patches in file ${patch_file}"
    n=0
    i=0
    while read patch; do
      echo $patch
      patch -s -d asterisk-${ASTERISK_VERSION} -p0 -i $PWD/$patch
      n=$((n+1))
      if [ $? -eq 0 ]; then
        i=$((i+1))
      fi
    done < <(cat ${patch_file} | grep -v "^#\|^$")
    echo -e "=====================> Applied ${i}/${n} patches the file ${patch_file} <=====================\n"
done

find -name "*.orig" -delete
