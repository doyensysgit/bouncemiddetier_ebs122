#!/bin/ksh
. /u01/.batchrc > /tmp/env.txt
. $FMW_HOME/wlserver_10.3/server/bin/setWLSEnv.sh > /tmp/env.txt
SCRIPT_LOCATION=/u01/scripts
LOG_LOCATION=/u01/script_logs
SHUTDOWN_SCRIPT=$SCRIPT_LOCATION/shutdown.py
STARTUP_SCRIPT=$SCRIPT_LOCATION/startup.py
STATUS_SCRIPT=$SCRIPT_LOCATION/status.py
HOST=`uname -a|awk '{print $2}'`

port=`cat $CONTEXT_FILE |grep wls_adminport|awk '{print $10}'|sed 's/>/> /g'|sed 's/</ < /g'|awk '{print ":"$2}'`
host=`hostname`
proto="t3://"
WL_URL=$proto$host$port; export WL_URL
cat $EBS_DOMAIN_HOME/config/config.xml|grep oacore_server|grep migratable|sed 's/<name>/<name> /g'|awk '{print $2}' > $HOME/oacorelist.txt
OACORE_LIST=$HOME/oacorelist.txt;export OACORE_LIST

ADMSRVR_STAT=`{ echo $WL_PWD; echo $APPS_PWD;}|sh $ADMIN_SCRIPTS_HOME/adadminsrvctl.sh status|grep "The AdminServer is running"|wc -l`

if [ $ADMSRVR_STAT -ne 1 ]
then
echo "ADMIN Server is not running, this script will fail, Exiting"
exit
fi

if [ ! -f $SHUTDOWN_SCRIPT ] && [ ! -f $STARTUP_SCRIPT ] && [ ! -f $OACORE_LIST ] 
then
echo " "
echo " "
echo "ERROR: Required files doesn't exists, this script will fail, Exiting"
printf "Please verify the below files are exists or not\n$SHUTDOWN_SCRIPT\n$STARTUP_SCRIPT\n$OACORE_LIST and\n$SCRIPT_LOCATION/apachestart.sh"
echo " "
exit
else
## RESTARTING APACHE SERVICES ###
echo "Restarting Apache"
echo " "
sqlplus -s apps/$APPS_PWD << EOF
spool $LOG_LOCATION/serverlist.txt
set head off
select NODE_NAME from fnd_nodes where SUPPORT_WEB = 'Y' and node_name <> upper('$HOST');
spool off
EOF
cat $LOG_LOCATION/serverlist.txt|grep -v "rows selected"|sed '/^$/d'|while read line;
do server=`echo $line| awk '{print $1}'`;
ssh $server $SCRIPT_LOCATION/apachestart.sh;
done
sh $SCRIPT_LOCATION/apachestart.sh
echo "Restarting Apache services completed"
echo " "

echo "Restarting OACORE services"
echo " "
java weblogic.WLST $SHUTDOWN_SCRIPT
java weblogic.WLST $STARTUP_SCRIPT
echo " "
echo " "
echo "Restarting OACORE Services are completed"
echo " "
echo " "
echo "Checking the OACORE Managed service status..."
echo " "
java weblogic.WLST $STATUS_SCRIPT
fi