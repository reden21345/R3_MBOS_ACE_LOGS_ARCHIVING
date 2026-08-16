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
#	2. BackupDIR	--> NFS Datapump Backup Directory (Target)
#	3. R3ACEPW		--> SYS user password


# Environment Variables
export HOME=/home/controlm
export ORACLE_HOME=${HOME}/oracle/client/19.0.0
export TNS_ADMIN=${ORACLE_HOME}/network/admin
export PATH=${ORACLE_HOME}/bin:${ORACLE_HOME}/OPatch:${PATH}
export DBNAME=MBACEDV
export ORADB=`echo ${DBNAME} | tr [:upper:] [:lower:] | sed 's/.$//'`

# Date and Time
export DATE=`date '+%Y%m%d'`
export TIME=`date '+%H%M%S'`

# Directories
export mbosAceArch="R3_MBOS_ACE_ARCH_JOB"
export JobName="R3_MBACECIBX_CLEANUP"
export ScriptDIR=${HOME}/${mbosAceArch}/${JobName}
export ParFileDir=${ScriptDIR}/parfiles
export TempDIR=${ScriptDIR}/tmp
export BackupDIR=/DB_BACKUP/${ORADB}/export
export LogDIR=${ScriptDIR}/logs
export LogFile=${LogDIR}/${JobName}_${DATE}_${TIME}.log
export checkpartition=${TempDIR}/checkpartition.tmp
# export ACEBKPDIR=/DB_BACKUP/${ORADB}/export

# Password Encrytion
export EncDecDIR=${HOME}/EncryptDecrypt
cd ${EncDecDIR}
export R3ACEUser=SYS
export R3ACEPW=`/usr/java8_64/bin/java -jar $EncDecDIR/PasswordDecryptor.jar <INPUT_PASSWORD> | awk '{print $3}'`


############## Start Time
STARTTIME(){
printf "\n\n"
export TIMESTAMP=$(date +"%A | %B %d, %Y | %T")
echo "--------------------------------------------------------------------------"
echo "Start Time: " ${TIMESTAMP}
echo "--------------------------------------------------------------------------"
printf "\n\n"
}
##############

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
find "${LogDIR}" -type f -name "${JobName}*" -mtime +60 -exec ls -ltr {} \; 2>/dev/null 
find "${LogDIR}" -type f -name "${JobName}*" -mtime +60 -exec rm -f {} \; 2>/dev/null 
}
##############

STARTTIME | tee -a ${LogFile} 

${ORACLE_HOME}/bin/sqlplus -S "${R3ACEUser}"/"${R3ACEPW}"@${DBNAME} as sysdba <<EOF > ${checkpartition}
@${ScriptDIR}/partition_checker.sql
EOF

export err_ctr_part=0
export err_ctr_part=`grep -c -i "ORA-|CPY-|SP2-|Warning:" ${checkpartition}`

if [[ $err_ctr_part -ne 0 ]]
then
	cat ${checkpartition} >> ${LogFile}
	
	printf "\n\nERROR: ${JobName} encountered an error! \n\n"
	grep -i "ORA-|CPY-|SP2-|Warning:" ${LogFile}
	printf "\n\nSend logfile to DBA, located at ${LogFile}.\n"

	ENDTIME | tee -a ${LogFile}

	exit 1
	
else
	cat ${checkpartition} >> ${LogFile}
	
	printf "\n\nDeleting Old Partitions.....\n\n" s| tee -a ${LogFile}
	sh ${ScriptDIR}/drop_partition.sh >> ${LogFile}
	
	export err_ctr_drop=0
	export err_ctr_drop=`grep -c -i "ORA-|CPY-|SP2-|Warning:" ${LogFile}`

	if [[ $err_ctr_drop -ne 0 ]]
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
	
fi

