
LOG(){
	TIME=`date "+%Y%m%d %H:%M:%S"`
#	logger -t Backup -s "$$: $@"
	echo -e "$TIME $$: $@"
	echo -e "$TIME $$: $@" >>$LOGFILE
}
EXIT(){
	LOG "success"
	exit 0
}
ERR(){
	LOG "$@"
	exit 1
}

