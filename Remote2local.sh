#!/bin/bash
BACKUP=Remote2local

[ ! -f common.sh ] && {
	echo "Can not find common script"
	exit 1
}
. common.sh

LOGFILE=/tmp/$BACKUP.log
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
	SSH=`echo $NAME | sed 's/:.*//'`
	REMOTE=`eval "ssh $SSH 'uname -n'"`
	[ -z "$REMOTE" ] && {
		LOG "Get remote host name fail"
		FAIL="$FAIL $NAME"
		continue
	}
	echo "Backup from $NAME to $DIST/$REMOTE"
	# Backup to local device
	mkdir -p $DIST/$REMOTE/
	rsync -azzPR $NAME $DIST/$REMOTE/
	[ $? != 0 ] && {
		LOG "Backup $NAME to ${DIST}/$REMOTE fail"
		FAIL="$FAIL $NAME"
	}
done

[ -n "$FAIL" ] && ERR "Backup fail: $FAIL"
EXIT
