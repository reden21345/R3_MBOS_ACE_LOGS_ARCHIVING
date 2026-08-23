#!/bin/bash

#######################################################################################################################
#                                                                                                                     #
#================================================ VERSION CONTROL HISTORY ============================================#
#                                                                                                                     #
#######################################################################################################################
#REDMINE        AUTHOR/S                DATE                    VERSION         REMARKS                               #
#######################################################################################################################
#148998			Reden Mirandilla        August 2026				1.0				Initial Version. 
#######################################################################################################################

# NOTE: Modify the following variables per environment to provide its corressponding value;
#	1. DBNAME		--> Database Name
#	2. BackupDIR	--> NFS Datapump Backup Directory (Target)

printf "\n\n"
export TIMESTAMP=$(date +"%A | %B %d, %Y | %T")
echo "--------------------------------------------------------------------------"
echo "Start Time: " ${TIMESTAMP}
echo "--------------------------------------------------------------------------"
printf "\n\n"

# Environment Variables
export HOME=/home/controlm
#export ORACLE_HOME=${HOME}/oracle/client/19.0.0
#export TNS_ADMIN=${ORACLE_HOME}/network/admin
#export DBNAME=MBOSIDV
#export ORADB=`echo ${DBNAME} | tr [:upper:] [:lower:]`
#export LIBPATH=$ORACLE_HOME/lib:$LIBPATH
#export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
#export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$PATH
#export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

export ORACLE_BASE=/u01/app/mbosidv
export ORACLE_HOME=${ORACLE_BASE}/product/19.0.0/dbhome_1
export ORACLE_SID=mbosidv
export PATH=${ORACLE_HOME}/bin:${ORACLE_HOME}/OPatch/:${PATH}
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export LIBPATH=$ORACLE_HOME/lib:$LIBPATH
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/lib:/usr/lib
export CLASSPATH=${ORACLE_HOME}/JRE:${ORACLE_HOME}/jlib:$ORACLE_HOME/rdbms/jlib	

# Date and Time
export DATE=`date '+%Y%m%d'`
export TIME=`date '+%H%M%S'`

# Directories
export mbosAceArch="R3_MBOS_ACE_ARCH_JOB"
export mbosJob="MBOSISTG_IMPORT"
export JobName="R3_DAILY_${mbosJob}"
export ScriptDIR=${HOME}/TaskController/${mbosAceArch}/${JobName}
export ParFileDir=${ScriptDIR}/parfiles
export TempDIR=${ScriptDIR}/tmp
export LogDIR=${ScriptDIR}/logs
export BackupDIR=/DB_BACKUP/${ORACLE_SID}/export
export LogFile=${LogDIR}/${JobName}_${DATE}_${TIME}.log

############## End Time
ENDTIME(){
printf "\n\n"
export TIMESTAMP=$(date +"%A | %B %d, %Y | %T")
echo "--------------------------------------------------------------------------"
echo "End Time: " ${TIMESTAMP}
echo "--------------------------------------------------------------------------"
printf "\n\n"
}
##############


############## Cleanup files
CLEANUP(){
find "${ParFileDir}" -type f -name "IMPDP_${JobName}*" -mtime +14 -exec ls -ltr {} \; 2>/dev/null 
find "${ParFileDir}" -type f -name "IMPDP_${JobName}*" -mtime +14 -exec rm -f {} \; 2>/dev/null 
find "${BackupDIR}" -type f -name "IMPDP_${JobName}*" -mtime +14 -exec ls -ltr {} \; 2>/dev/null 
find "${BackupDIR}" -type f -name "IMPDP_${JobName}*" -mtime +14 -exec rm -f {} \; 2>/dev/null 
find "${LogDIR}" -type f -name "${JobName}*" -mtime +30 -exec ls -ltr {} \; 2>/dev/null 
find "${LogDIR}" -type f -name "${JobName}*" -mtime +30 -exec rm -f {} \; 2>/dev/null 
}
##############


# MBOSISTG Log Table Load
printf "\n\nMBOSISTG Log Tables are being loaded.....\n\n"
sh ${ScriptDIR}/${mbosJob}.sh > ${LogFile}


# Validate Error Count from logfile
export error_count=0
export error_count=`grep -c -i "ORA-|CPY-|SP2-|Warning:" ${LogFile}`

printf "\n\nChecking for errors.....\n\n"

if [[ $error_count -ne 0 ]]
then
	printf "\n\nERROR: ${JobName} encountered an error! \n\n"
	grep -i "ORA-|CPY-|SP2-|Warning:" ${LogFile}
	printf "\n\nSend logfile to DBA, located at ${LogFile}.\n"

	ENDTIME | tee -a ${LogFile}
	
	exit 1

else
	printf "\n\nCleaning up files.....\n\n" | tee -a ${LogFile}
	CLEANUP >> ${LogFile} # Cleanup files beyond retention
	
	printf "\n\n${JobName} Job Successful! \n"
	printf "Logfile located at ${LogFile}\n\n"
	
	ENDTIME | tee -a ${LogFile}
			
	exit 0

fi


