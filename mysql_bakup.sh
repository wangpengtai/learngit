#!/bin/bash
#Date:2017/5/2
#Author:wangpengtai
#Blog:http://wangpengtai.blog.51cto.com

#At Sunday, we will backup the completed databases and the incresed binary log during Saturday to Sunday.
#In other weekdays, we only backup the increaing binary log at that day!

################################
#the globle variables for MySQL#
################################
DB_USER='root'
DB_PASSWORD='123456'
DB_PORT='3306'
BACKUPDIR='/tmp/mysqlbakup'
BACKUPDIR_OLDER='/tmp/mysqlbakup_older'
DB_PID='/data/mysql/log/mysqld.pid'
DB_SOCK='/data/mysql/log/mysql.sock'
LOG_DIR='/data/mysql/log'
BACKUP_LOG='/tmp/mysqlbakup/backup.log'
DB_BIN='/usr/local/mysql/bin'
#time variables for completed backup
FULL_BAKDAY='Sunday'
TODAY=`date +%A`
DATE=`date +%Y%m%d`

###########################
#time variables for binlog#
###########################

#liftcycle for saving binlog 
DELETE_OLDLOG_TIME=$(date "-d 14 day ago" +%Y%m%d%H%M%S)

#The start time point to backup binlog, the usage of mysqlbinlog is --start-datetime、--stop-datetime, time format is %Y%m%d%H%M%S, eg:20170502171054, time zones is  [start-datetime, stop-datetime)
#The date to start backup binlog is yesterday at this very moment!
START_BACKUPBINLOG_TIMEPOINT=$(date "-d 1 day ago" +"%Y-%m-%d %H:%M:%S")
BINLOG_LIST=`cat /data/mysql/log/mysql-bin.index`

##############################################
#Judge the mysql process is running or not.  #
#mysql stop return 1, mysql running return 0.#
##############################################
function DB_RUN(){
    if test -a $DB_PID && test -a $DB_SOCK;then
        return 0
    else
        return 1
    fi
}

###################################################################################################
#Judge the bacup directory is exsit not.                                                          #
#If the mysqlbakup directory was exsited, there willed return 0.                                  #
# If there is no a mysqlbakup directory, the fuction will create the directory and return value 1.#
###################################################################################################
function BACKDIR_EXSIT(){
    if test -d $BACKUPDIR;then
#        echo "$BACKUPDIR was exist."
        return 0
    else
        echo "$BACKUPDIR is not exist, now create it."
        mkdir -pv $BACKUPDIR 
        return 1
    fi
}

###################################################
#The full backup for all Databases                #
#This function is use to backup the all databases.#
###################################################
function FULL_BAKUP(){
    echo "At `date +%D\ %T`: Starting full backup the MySQL DB ... "
#    rm -fr $BACKUPDIR/db_fullbak_$DATE.sql  #for test !!
    $DB_BIN/mysqldump --lock-all-tables --flush-logs --master-data=2 -u$DB_USER -p$DB_PASSWORD -P$DB_PORT -A |gzip > $BACKUPDIR/db_fullbak_$DATE.sql.gz
    FULL_HEALTH=`echo $?`
    if [[ $FULL_HEALTH == 0 ]];then
        echo "At `date +%D\ %T`: MySQL DB incresed backup successfully"
    else
        echo "MySQL DB full backup failed!"
    fi
}
#python
# >>> with open('/data/mysql/log/mysql-bin.index','r') as obj:
# ...    for i in obj:
# ...       print os.path.basename(i)  
# ... 
# mysql-bin.000006

# mysql-bin.000007

# mysql-bin.000008

# mysql-bin.000009

function INCREASE_BAKUP(){
    echo "At `date +%D\ %T`: Starting increased backup the MySQL DB ... "
    $DB_BIN/mysqladmin -u$DB_USER -p$DB_PASSWORD -P$DB_PORT flush-logs
    $DB_BIN/mysql -u$DB_USER -p$DB_PASSWORD -P$DB_PORT -e "purge master logs before ${DELETE_OLDLOG_TIME}"  
    for i in $BINLOG_LIST
    do
        $DB_BIN/mysqlbinlog -u$DB_USER -p$DB_PASSWORD -P$DB_PORT --start-datetime="$START_BACKUPBINLOG_TIMEPOINT" $i |gzip >> $BACKUPDIR/db_daily_$DATE.sql.gz 
    done
    # $DB_BIN/mysqlbinlog -u$DB_USER -p$DB_PASSWORD -P$DB_PORT --start-datetime="$START_BACKUPBINLOG_TIME" $LOG_DIR/mysql-bin.[0-9]* |gzip >> $BACKUPDIR/db_daily_$DATE.sql.gz
    INCREASE_HEALTH=`echo $?`
    if [[ $INCREASE_HEALTH == 0 ]];then
        echo "At `date +%D\ %T`: MySQL DB incresed backup successfully"
    else
        echo "MySQL DB incresed backup failed!"
    fi
}

function OLDER_BACKDIR_EXSIT(){
    if test -d $BACKUPDIR_OLDER;then
#        echo "$BACKUPDIR_OLDER was exist."
        return 0
    else
        echo "$BACKUPDIR_OLDER is not exist, now create it."
        mkdir -pv $BACKUPDIR_OLDER 
#        return 1
    fi
}

function BAKUP_CLEANER(){
    #move the backuped file that created time out of 7 days to the BACKUPDIR_OLDER directory
    echo "----------------------"
    echo "Moving the older backuped file out of 7 days to $BACKUPDIR_OLDER."
    echo "The moved file list is:"
    find $BACKUPDIR -name "*.sql.gz" -mtime +7 -exec ls -lh {} \;
    find $BACKUPDIR -name "*.sql.gz" -mtime +7 -exec mv {} $BACKUPDIR_OLDER \;
    echo "-----------------------"
    #delete the backuped file that created time out of 14 days from BACKUPDIR_OLDER directory.
    echo "Delete the older backuped file out of 14 days from $BACKUPDIR_OLDER."
    echo "The deleted files list is:"
    find $BACKUPDIR_OLDER -name "*.sql.gz" -mtime +14 -exec ls -lh {} \;
    find $BACKUPDIR_OLDER -name "*.sql.gz" -mtime +14 -exec rm -fr {} \;
}

####################################
#--------------main----------------#
####################################
function MAIN(){
    DB_RUN #Judge the process is run or not, if not run, the script will not bakup db
    Run_process=`echo $?`
    if [[ $Run_process == 0 ]];then
        echo "**********START**********"
        echo $(date +"%y-%m-%d %H:%M:%S")
        echo "~~~~~~~~~~~~~~~~~~~~~~~"
        BACKDIR_EXSIT
        OLDER_BACKDIR_EXSIT
        if [[ $TODAY == $FULL_BAKDAY ]];then
            echo "Start completed bakup ..."
            FULL_BAKUP    #full backup to all DB
            INCREASE_BAKUP
            BAKUP_CLEANER
        else 
            echo "Start increaing bakup ..."
            INCREASE_BAKUP
        fi
        echo "~~~~~~~~~~~~~~~~~~~~~~~"
        echo $(date +"%y-%m-%d %H:%M:%S")
        echo "**********END**********"
    else
        echo "**********START**********"
        echo $(date +"%y-%m-%d %H:%M:%S")
        echo "~~~~~~~~~~~~~~~~~~~~~~~"
        echo "Sorry, MySQL was not running, the db could not be backuped!" 
        echo "~~~~~~~~~~~~~~~~~~~~~~~"
        echo $(date +"%y-%m-%d %H:%M:%S")
        echo "**********END**********"
    fi
}

#starting runing
MAIN >> $BACKUP_LOG









