#!/bin/bash

#######################################################################################################################
#                                                                                                                     #
#================================================ VERSION CONTROL HISTORY ============================================#
#                                                                                                                     #
#######################################################################################################################
#REDMINE        AUTHOR/S                DATE                    VERSION         REMARKS                               #
#######################################################################################################################
#FF				Reden Mirandilla        August 2026				1.0				Initial Version. 
#######################################################################################################################

# NOTE: Modify the following variables per environment to provide its corressponding value;
#	1. DBNAME		--> Database Name
#	2. BackupDIR	--> NFS Datapump Backup Directory (Source)

printf "\n\n"
export TIMESTAMP=$(date +"%A | %B %d, %Y | %T")
echo "--------------------------------------------------------------------------"
echo "Start Time: " ${TIMESTAMP}
echo "--------------------------------------------------------------------------"
printf "\n\n"

# Environment Variables
export HOME=/home/controlm
export ORACLE_HOME=${HOME}/oracle/client/19.0.0
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export PATH=${ORACLE_HOME}/bin:${ORACLE_HOME}/OPatch:${PATH}
export DBNAME=MBOSIDV
export ORADB=`echo ${DBNAME} | tr [:upper:] [:lower:]`

# Date and Time
export DATE=`date '+%Y%m%d'`
export TIME=`date '+%H%M%S'`

# Directories
export mbosArch="R3_MBOS_ARCH_JOB"
export mbosJob="MBOS_EXPORT"
export JobName="R3_DAILY_${mbosJob}"
export ScriptDIR=${HOME}/${mbosArch}/${JobName}
export ParFileDir=${ScriptDIR}/parfiles
export TempDIR=${ScriptDIR}/tmp
export LogDIR=${ScriptDIR}/logs
export BackupDIR=/DB_BACKUP/${ORADB}/export
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
find "${ParFileDir}" -type f -name "EXPDP_${JobName}*" -mtime +3 -exec ls -ltr {} \; 2>/dev/null 
find "${ParFileDir}" -type f -name "EXPDP_${JobName}*" -mtime +3 -exec rm -f {} \; 2>/dev/null 
find "${BackupDIR}" -type f -name "EXPDP_${JobName}*" -mtime +3 -exec ls -ltr {} \; 2>/dev/null 
find "${BackupDIR}" -type f -name "EXPDP_${JobName}*" -mtime +3 -exec rm -f {} \; 2>/dev/null 
find "${LogDIR}" -type f -name "${JobName}*" -mtime +30 -exec ls -ltr {} \; 2>/dev/null 
find "${LogDIR}" -type f -name "${JobName}*" -mtime +30 -exec rm -f{} \; 2>/dev/null 
}
##############


# MBOS Log Table Backup
printf "\n\nMBOS Log Tables are being backed up.....\n\n"
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

