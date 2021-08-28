#!/bin/bash
BACKUP=Local2local

[ ! -f common.sh ] && {
	echo "Can not find common script"
	exit 1
}
. common.sh

LOGFILE=/tmp/`basename $0`.log
export LOGFILE

HOST=`uname -n`

BACKUP_FILE=${BACKUP}.${HOST}.lst
[ ! -f $BACKUP_FILE ] && BACKUP_FILE=${BACKUP}.lst
[ ! -f $BACKUP_FILE ] && ERR "Can not find backup list file: $BACKUP_FILE"
. $BACKUP_FILE
[ -z "$SOURCE" -o -z "$DIST" ] && ERR "Invalid backup list file: \n\tSOURCE:($SOURCE)\n\tDIST:($DIST)"

mkdir -p $DIST
[ ! -d $DIST ] && ERR "Can not create dist folder: $DIST"

number=`expr ${#SOURCE[@]} "-" 1`
LOG "Backup list count: $number"

FAIL=""
for index in `seq 0 $number`
do
	NAME=${SOURCE[$index]}
	param=`echo "$NAME" | sed 's/.*&//'`
	dir=`echo "$NAME" | sed 's/&.*//'`
	[ ! -e $dir ] && {
		LOG "$dir not exist"
		continue
	}
	echo "Backup from $dir to $DIST"
	# Backup to local device
	DST=`dirname ${DIST}$dir`
	mkdir -p $DST
	rsync -aHAX $param $dir $DST/
	[ $? != 0 ] && {
		LOG "Backup $dir to ${DIST} fail"
		FAIL="$FAIL $dir"
	}
done

[ -n "$FAIL" ] && ERR "Backup fail: $FAIL"
EXIT
