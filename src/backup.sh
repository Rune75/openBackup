#!/bin/sh

day=`date +%w`

targetBackupDir=$1
d_backup_dir=$1/daily
logfile=$targetBackupDir/Day_$day.log

# Roll local backup array
/usr/local/bin/backup_roll.sh $targetBackupDir

# Do local backup
#do backup to position 0 copying only changes from last backup
rsync -avs --delete $(cat $targetBackupDir/backup_folders.txt) $d_backup_dir/0_days/ | tee $logfile

#Send warning mail if filesystem has changed since last backup
log_Z=`wc -l $logfile|cut -d ' ' -f 1`
echo $log_Z
if [ $log_Z -gt 4 ]
then
    echo "sending mail"
    cat $logfile | mailx -A gmail -s "Filesystem changes detected when backing up to local backup" rune.bekkevold@gmail.com
fi





