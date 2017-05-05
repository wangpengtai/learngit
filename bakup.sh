#!/bin/bash

TODAY=`date +%A`
DATE=`date +%Y%m%d`
DB_USER='root'
DB_PASSWORD='123456'
DB_PORT='3306'
BACKUPDIR='/tmp/mysqlbakup'
DB_PID='/data/mysql/log/mysqld.pid'

#Sunday

#Judge the mysql process is running or not.
#mysql stop return 1, mysql running return 0.
function DB_RUN(){
    if test -a $DB_PID;then
        return 0
    else
        return 1
    fi
}


function BACKDIR_EXSIT(){
     if test -d $BACKUPDIR;then
         return 0
     else
         return 1
     fi
}

#BACK_DIR

#
function FULL_BAKUP(){
    mysqldump -u$DB_USER -p$DB_PASSWORD -P$DB_PORT -A > $BACKUPDIR/db_fullbak_$DATE.sql
}

# function INCREASE_BAKUP(){

# }


DB_RUN
Run_process=`echo $?`
# if [[ $Run_process == 0 ]];then
    # if $TODAY="Sunday";then
        # BACK_DIR
        # File_exsit=`echo $?`
        # if [[ $File_exsit == 0 ]];then
            # echo "Starting backup the MySQL DB ..."
        # fi
    # fi
# else
    # echo "MySQL is stopped"
# fi

# if [[ $Run_process == 0 ]];then
    # echo "MySQL is running"
# else
    # echo "MySQL is stopped"
# fi




