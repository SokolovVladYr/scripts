#!/bin/bash
################
# Configuration
################

# Backup path
backup_path="/tmp"

#Save N old backups and delete the rest
del_old_backup="yes"
Nbackups="4"

# Script log file. Create a directory if you save the log to a non-standard directory
log_file="/tmp/log/backup.log"  #standard directory /var/log

# Directories to backup
backup_dir_enable="yes"
backup_directories="/var/lib/docker/volumes/infomaximum-clickhouse"

#Sart service
servive_clickhouse_start="no"
#################################################################
#################################################################
#################################################################

################
# Do the backup
################

# Main variables
color='\033[0;36m'
color_fail='\033[0;31m'
nc='\033[0m'
hostname=$(hostname -s)
date_now=$(date +"%Y-%m-%d %H:%M:%S")

path_date=infomaximum-clickhouse-$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p $backup_path/Backup/$path_date 2>> $log_file
echo -e "\n ${color}--- $date_now Backup started. \n${nc}"
echo "$date_now Backup started." >> $log_file

sleep 1
# Service delete
docker service rm infomaximum-clickhouse

sleep 5

# Backing up the directories
if [ $backup_dir_enable = "yes" ]
then
    echo "" > $log_file
    echo -e "\n ${color}--- $date_now Backing up directories \n${nc}"
    echo "$date_now Backing up directories" >> $log_file
    for backup_dirs in $backup_directories
    do
        echo "--> $backup_dirs" | tee -a $log_file
            dir_name=`echo $backup_dirs | cut -d / -f2- | sed "s/\//-/g"`
            tar -czvf $backup_path/Backup/$path_date/$dir_name.tar.gz $backup_dirs/ 2>> $log_file
    done
    echo
fi
sleep 1

# Delete old backup

if [ $del_old_backup = "yes" ]
then
   echo >> $log_file
   echo "### Delete old Backups ###" >> $log_file
   echo >> $log_file
   cd $backup_path/Backup/ && ls -tr | head -n -$Nbackups >> $log_file
   echo >> $log_file
   cd $backup_path/Backup/ && ls -tr | head -n -$Nbackups | xargs --no-run-if-empty rm --recursive
   echo "#########################" >> $log_file
fi

sleep 1

# Service start
if [ $servive_clickhouse_start = "yes" ]
then
docker service create --name infomaximum-clickhouse \
--secret infomaximum_app_user \
--secret infomaximum_app_user_password_hash \
--secret infomaximum_external_user \
--secret infomaximum_external_user_password_hash \
--secret infomaximum_clickhouse_dhparam.pem \
--secret infomaximum_clickhouse.crt \
--secret infomaximum_clickhouse.key \
--publish published=8123,target=8123,mode=host \
--mount type=volume,src=infomaximum-clickhouse,target=/var/lib/clickhouse/ \
--mount type=volume,src=infomaximum-clickhouse-log,target=/var/log/clickhouse-server \
--restart-max-attempts 5 \
--restart-condition "on-failure" \
--no-resolve-image \
infomaximum/infomaximum-clickhouse:20.4.5.36p4
fi

exit 0
