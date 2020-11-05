#/bin/bash
# variables define
BACKUP_LIST=(/etc/apache2 
	/home/www/conf 
	/home/www/data/pages
	'/home/www/data/attic#--exclude _dummy'
	'/home/www/data/media*#--exclude _dummy'
	'/home/www/data/meta#--exclude _dummy'
	'/home/homeassistant/.homeassistant#--exclude *.db* --exclude .storage --exclude *.log'
	)

echo "${BACKUP_LIST[@]}"

BACKUP_SERVER="root@192.168.1.2:/mnt/SSD_120G/Backup"
LABEL=backup	#block device label for backup

LOGFILE=/tmp/`basename $0`.log
touch $LOGFILE
MOUNT=/mnt/$LABEL
BACKUP_DEV=`blkid --label $LABEL`
[ -z "$BACKUP_DEV" ] && LOG "Can not find block device with label $LABEL"

#Limit logfile size
LINES=`wc -l $LOGFILE | awk '{print $1}'`
[ $LINES -gt 100 ] && {
	tail -n 100 $LOGFILE >${LOGFILE}.tmp
	mv ${LOGFILE}.tmp $LOGFILE
}

# Functions
LOG(){
	TIME=`date "+%Y%m%d %H:%M:%S"`
	logger -t Backup -s "$$: $@"
	echo "$TIME $$: $@" >>$LOGFILE
}
EXIT(){
	LOG "success"
	[ -n "$BACKUP_DEV" ] && umount -f $BACKUP_DEV 2>/dev/null &
	exit 0
}
ERR(){
	LOG "$@"
	[ -n "$BACKUP_DEV" ] && umount -f $BACKUP_DEV 2>/dev/null &
	exit 1
}

[ -n "$BACKUP_DEV" ] && {
	if grep -q "$BACKUP_DEV" /proc/mounts;then
		LOG "$BACKUP_DEV already mounted, force unmount it"
		umount -f $BACKUP_DEV
	fi
	mkdir -p $MOUNT
	mount $BACKUP_DEV $MOUNT
	[ $? != 0 ] && ERR "Mount $BACKUP_DEV to $MOUNT fail"
}

LOCAL_FAIL=""
REMOTE_FAIL=""
number=`expr ${#BACKUP_LIST[@]} "-" 1`
for index in `seq 0 $number`
do
	NAME=${BACKUP_LIST[$index]}
	param=`echo "$NAME" | sed 's/.*#//'`
	name=`echo "$NAME" | sed 's/#.*//'`
	# Backup to local device
	[ -n "$BACKUP_DEV" ] && {
		DST=`dirname ${MOUNT}$name`
		mkdir -p $DST
		LOG "Backup $name to $DST"
		rsync -aHAX $param $name $DST/
		[ $? != 0 ] && {
			LOG "Backup $name to $BACKUP_DEV fail"
			LOCAL_FAIL="$LOCAL_FAIL $name"
		}
	}
	# Backup to backup server
	[ -z "$BACKUP_SERVER" ] && continue
	for server in $BACKUP_SERVER;do
		LOG "Backup $name to $server: /usr/bin/rsync -azzPR $name $server/"
		/usr/bin/rsync -azzPR $param $name $server/
		[ $? != 0 ] && {
			LOG "Backup $name to $server fail"
			REMOTE_FAIL="$REMOTE_FAIL $name"
		}
	done
done

[ -n "$LOCAL_FAIL$REMOTE_FAIL" ] && ERR "Backup fail: $LOCAL_FAIL $REMOTE_FAIL"
EXIT
