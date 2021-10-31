#!/bin/bash

source /var/www/db_backup/db_backup.config

if [ -z "$CONNECT_STRING" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$UPLOADED_FILES_PATH" ] || [ -z "$LOGS_PATH" ]; then
    echo "Insufficient parameters";
    exit 0;
fi

view_help()
{
cat << _EOF_
____________________________________

-b, --backup  :make backup
-s, --sync    :synchronize
____________________________________
_EOF_
}

make_backup()
{
    if [ "${ENV_TYPE}" != "prod" ]; then
        exit 0;
    fi

    DUMP_FILENAME=dump_$DB_NAME_`date +%d-%m-%Y"_"%H_%M_%S`.sql
    pg_dump --dbname=postgresql://$DB_USER:$DB_PASS@postgresql:5432/$DB_NAME > /tmp/$DUMP_FILENAME

    echo "$(date) Backup started" >> /var/log/cron.log
    echo "mkdir $PROJECT_NAME" | sftp -P 23 $CONNECT_STRING
    echo "mkdir $PROJECT_NAME/sqls" | sftp -P 23 $CONNECT_STRING
    echo "put /tmp/$DUMP_FILENAME $PROJECT_NAME/sqls" | sftp -P 23 $CONNECT_STRING
    rsync -avz -e 'ssh -p23 -o StrictHostKeyChecking=no' --progress --ignore-existing $UPLOADED_FILES_PATH $CONNECT_STRING$PROJECT_NAME/files
    echo "$(date) Backup created" >> /var/log/cron.log

    rm /tmp/$DUMP_FILENAME
}

synchronize()
{
    LAST_SQL_BACKUP=$(echo "ls -lat $PROJECT_NAME/sqls" | sftp -P 23 $CONNECT_STRING | grep '.sql' | head -3 | tail -1 |  awk '{print $9}')

    if [ -z "$LAST_SQL_BACKUP" ]; then
        echo "Error get sql file path";
        exit 0;
    fi

    echo -n "Static files will be downloded from backup server. Existing tables from db '$DB_NAME' will be removed and replaced by schema and data from dump file '$LAST_SQL_BACKUP'. Are you sure? (type 'yes' to continue) > ";
    read answer;
    if [ "$answer" == 'yes' ]; then

        echo "$(date) Sync started" >> /var/log/cron.log
        echo "get $PROJECT_NAME/sqls/$LAST_SQL_BACKUP /tmp/" | sftp -P 23 $CONNECT_STRING
        rsync -avz -e 'ssh -p23' --progress --ignore-existing $CONNECT_STRING:$PROJECT_NAME/files $UPLOADED_FILES_PATH

        psql -h postgresql -p 5432 -U $DB_USER $DB_NAME -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO postgres; GRANT ALL ON SCHEMA public TO public;"

        psql -h postgresql -p 5432 -U $DB_USER $DB_NAME < /tmp/$LAST_SQL_BACKUP

        rm /tmp/$LAST_SQL_BACKUP

        echo "$(date) Sync finished" >> /var/log/cron.log

    else
        echo "Abort"
    fi
}

case $1 in
    -b | --backup ) 	make_backup
		                ;;
    -s | --sync ) 	    synchronize
		                ;;
    * )                 view_help
esac
