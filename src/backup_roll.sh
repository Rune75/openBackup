#!/bin/sh

day=`date +%w`
#define and create targets
targetDir=$1
w_backup_dir=$targetDir/weekly #$name
d_backup_dir=$targetDir/daily #$name


mkdir -p $d_backup_dir/0_days #Create directory if first run
mkdir -p $d_backup_dir/1_days #Create directory if first run
mkdir -p $d_backup_dir/2_days #Create directory if first run
mkdir -p $d_backup_dir/3_days #Create directory if first run
mkdir -p $d_backup_dir/4_days #Create directory if first run
mkdir -p $d_backup_dir/5_days #Create directory if first run
mkdir -p $d_backup_dir/6_days #Create directory if first run



#day=0; echo $day

#Run weekly backup if end of week
if [ $day -eq 0 ]
then
    mkdir -p $w_backup_dir
    number=52

    rm -rf $w_backup_dir/$number"_weeks" 2> /dev/null
    #echo $w_backup_dir/$number"_weeks"

    for i in $(seq $number -1 2); do
        prev=$(($i - 1))
        cur=$i
        mv $w_backup_dir/$prev"_weeks" $w_backup_dir/$cur"_weeks" 2> /dev/null
    done

    mkdir -p $w_backup_dir/1_weeks
    cp -alv $d_backup_dir/6_days/*  $w_backup_dir/1_weeks > /dev/null #> $w_backup_dir/1_weeks/"backup_log_week"-`date +'%W'`.log

fi

#Roll daily backup array freeing position 0 and disposing last, oldest position

rm -rf $d_backup_dir/6_days 2> /dev/null
mv $d_backup_dir/5_days $d_backup_dir/6_days 2> /dev/null
mv $d_backup_dir/4_days $d_backup_dir/5_days 2> /dev/null
mv $d_backup_dir/3_days $d_backup_dir/4_days 2> /dev/null
mv $d_backup_dir/2_days $d_backup_dir/3_days 2> /dev/null
mv $d_backup_dir/1_days $d_backup_dir/2_days 2> /dev/null
mkdir -p $d_backup_dir/0_days #Create directory if first run
cp -al $d_backup_dir/0_days $d_backup_dir/1_days

