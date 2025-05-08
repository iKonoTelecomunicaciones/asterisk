#!/bin/sh

echo "╭───────────── 🚀 docker-entrypoint.sh 🚀 ─────────────╮"
echo "│                                                      │"
echo "│          Starting the configuration script           │"
echo "│                                                      │"
echo "╰──────────────────────────────────────────────────────╯"

# run as user asterisk and UID 5038 by default
ASTERISK_USER=${ASTERISK_USER:-asterisk}
ASTERISK_UID=${ASTERISK_UID:-5038}

# if the user is root, UID must be the one assigned to root
if [ "${ASTERISK_USER}" == "root" ]; then
  ASTERISK_UID=$(id -u root)
fi

# if GID is not set, use same as UID
if [[ -z "${ASTERISK_GID}" ]]; then
  ASTERISK_GID=${ASTERISK_UID}
fi

# if GID not exists in the system, create a new group
SYS_GID=$(id -g ${ASTERISK_GID} 2> /dev/null)
if [[ -z "${SYS_GID}" ]]; then
  groupdel -f asterisk
  groupadd -g ${ASTERISK_GID} ${ASTERISK_USER}
fi

# if UID exists in the system
SYS_UID=$(id -u ${ASTERISK_USER} 2> /dev/null)
if [[ -n "${SYS_UID}" ]]; then
  # if UID is different from the one in the system, recreate user
  if [ "${ASTERISK_UID}" != "${SYS_UID}" ]; then
    userdel asterisk
    useradd --no-create-home --uid ${ASTERISK_UID} --gid ${ASTERISK_GID} ${ASTERISK_USER}
  fi
# The user exists, let's check if the UID belongs to other user
elif [ "$(id -un ${ASTERISK_UID})" != "${ASTERISK_USER}" ]; then
  echo "The user ${ASTERISK_USER} already exists with UID ${ASTERISK_UID}"
  exit 1
else
  useradd --no-create-home --uid ${ASTERISK_UID} --gid ${ASTERISK_GID} ${ASTERISK_USER}
fi

sed -i -E "s/(runuser\s*=\s*)[a-z_][a-z0-9_-]*(.*)/\1${ASTERISK_USER}\2/" /etc/asterisk/asterisk.conf
sed -i -E "s/(rungroup\s*=\s*)[a-z_][a-z0-9_-]*(.*)/\1${ASTERISK_GROUP}\2/" /etc/asterisk/asterisk.conf

alternatives --set mta /usr/sbin/sendmail.ssmtp

# Load modules
asterisk_modules_dir="/usr/lib/asterisk/modules"
new_modules_dir="/opt/volumes/modules"
for module in $(ls $new_modules_dir/); do
  if [ ! -f $asterisk_modules_dir/$module ]; then
    cp $new_modules_dir/$module $asterisk_modules_dir/
    chmod u+x $asterisk_modules_dir/$module
  fi
done

# Verify permissions
find /{usr,var}/{lib,log,run,spool}/asterisk /etc/asterisk ! -user ${ASTERISK_USER} -exec chown ${ASTERISK_USER}:${ASTERISK_GROUP} {} +

ASTERISK_GROUP=$(id -n -g ${ASTERISK_GID})
if [ "$1" = "" ]; then
  COMMAND="/usr/sbin/asterisk -T -U ${ASTERISK_USER} -G ${ASTERISK_GROUP} -p -vvvf"
else
  COMMAND="$@"
fi

# Remove this after the Dockerfile ARGS are corrected
COMMAND="/usr/sbin/asterisk -T -U ${ASTERISK_USER} -G ${ASTERISK_GROUP} -p -vvvf"

exec ${COMMAND}
