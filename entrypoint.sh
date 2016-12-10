#!/usr/bin/env ash

[ ! -z $MAX_INOTIFY_WATCHES ] && echo fs.inotify.max_user_watches=$MAX_INOTIFY_WATCHES | tee -a /etc/sysctl.conf && sysctl -p || true

# Check mount
[ ! -d $UNISON_SOURCE ] && (echo "No directory mounted on $UNISON_SOURCE"; exit 1)

UNISON_ARGS=""

# If osxfs mount use unison fsmonitor
# Else, synchronize every 2 seconds (Samba shares don't support inotify)
if mount -t fuse.osxfs | grep $UNISON_SOURCE > /dev/null; then
	UNISON_REPEAT="watch"
else
	UNISON_REPEAT="2"
fi

# Samba will mount a FAT filsystem which don't support all permission bits
if mount -t cifs | grep $UNISON_SOURCE > /dev/null; then
	UNISON_ARGS="-fat"
fi

# Configure Timezone
if [ -n ${TZ} ] && [ -f /usr/share/zoneinfo/${TZ} ]; then
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo ${TZ} > /etc/timezone
fi

rm -rf /home/docker/.unison/*
addgroup -g $UNISON_GID $UNISON_GROUP
adduser -u $UNISON_UID -D -G $UNISON_GROUP $UNISON_USER

# TODO: Verify that $UNISON_DIR is a docker volume
if [ ! -d /home/$UNISON_USER/.unison ];then
	chown $UNISON_USER:$UNISON_GROUP -R $UNISON_DIR $UNISON_SOURCE
fi

exec su-exec $UNISON_USER:$UNISON_GROUP unison $UNISON_SOURCE $UNISON_DIR -silent -auto -batch -repeat $UNISON_REPEAT -ignore 'Path .git' $UNISON_ARGS
