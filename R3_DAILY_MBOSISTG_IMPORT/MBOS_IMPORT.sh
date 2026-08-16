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
#	2. MBOSBKPDIR	--> NFS Datapump Backup Directory (Source)
#	3. BackupDIR	--> NFS Datapump Backup Directory (Target)
#	4. R3MBOSPW		--> SYS user password
# 	5. PARALLEL		--> Datapump parallelism


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
export ORADB=`echo ${DBNAME} | tr [:upper:] [:lower:] | sed 's/.$//'`

# Date and Time
export DATE=`date '+%Y%m%d'`
export TIME=`date '+%H%M%S'`

# Directories
export mbosArch="R3_MBOS_ARCH_JOB"
export mbosJob="MBOS_IMPORT"
export JobName="R3_DAILY_${mbosJob}"
export ScriptDIR=${HOME}/${mbosArch}/${JobName}
export ParFileDir=${ScriptDIR}/parfiles
export TempDIR=${ScriptDIR}/tmp
export BackupDIR=/DB_BACKUP/${ORADB}/export
# export MBOSBKPDIR=/DB_BACKUP/${ORADB}/export



export ScriptDIR=${HOME}/${mbosArch}/${JobName}
export TempDIR=${ScriptDIR}/tmp
export ParFileDir=${ScriptDIR}/parfiles
export BackupDIR=/DB_BACKUP/${ORADB}/export

# Temporary Files
export impdpTempLog=${TempDIR}/impdp_mbos_offline.tmp 
export tempParfile=${TempDIR}/parfile.tmp
export mbosDump="${BackupDIR}/mbos_dumpfile.txt"

# Password Encrytion
export EncDecDIR=${HOME}/EncryptDecrypt
cd ${EncDecDIR}
export R3MBOSUser=SYS
export R3MBOSPW=`/usr/java8_64/bin/java -jar $EncDecDIR/PasswordDecryptor.jar yKsbXwpFj45bwekTW+6uLMlwsj0pN4wr | awk '{print $3}'`


# Load
cd ${ScriptDIR}
export R3MBOSOnlineSchema=MBOSIUSR
export R3MBOSOfflineSchema=MBOSIUSR_OFFLINE
export dmpfile=`cat ${mbosDump} | grep DUMPFILE | grep .`
export dmptbl=`cat ${mbosDump} | grep TABLES | grep .`
export dtpmpjobname="IMPDP_${JobName}_${DATE}_${TIME}"
export PARFILE=${ParFileDir}/${dtpmpjobname}.par

# Remap Table
# export remaptbl=$(echo "${dmptbl}" | sed 's/^TABLES=//' | tr ',' '\n' | while IFS= read -r entry; do
#     [ -z "$entry" ] && continue
#     schema_table=$(echo "$entry" | cut -d: -f1)
#     partition=$(echo "$entry" | cut -d: -f2)
#     table_name=$(echo "$schema_table" | awk -F. '{print $NF}')
#     if [ -n "$partition" ] && [ "$partition" != "$schema_table" ]; then
#         echo "REMAP_TABLE=${schema_table}:${partition}:${table_name}_OFFLINE"
#     else
#         echo "REMAP_TABLE=${schema_table}:${table_name}_OFFLINE"
#     fi
# done)


cat <<EOF >  ${PARFILE}
USERID=\"${R3MBOSUser}/${R3MBOSPW}@${DBNAME} as sysdba\"
DIRECTORY=DATABASE_BACKUP_DIR
${dmpfile}
LOGFILE=${dtpmpjobname}.log
${dmptbl}
LOGTIME=ALL
PARALLEL=4
METRICS=YES
ENCRYPTION_PASSWORD=Welcome123
CONTENT=DATA_ONLY
TABLE_EXISTS_ACTION=APPEND
REMAP_SCHEMA=${R3MBOSOnlineSchema}:${R3MBOSOfflineSchema}
REMAP_TABLESPACE=${R3MBOSOnlineSchema}:${R3MBOSOfflineSchema}_OFFLINE
EOF

# Mask SYS Password
cat ${PARFILE} | sed 's/\(.*\/\).*\(@.*\)/\1********\2/' > ${tempParfile}

impdp parfile=${PARFILE} > ${impdpTempLog} 2>&1

cat ${BackupDIR}/${dtpmpjobname}.log

cp -p ${tempParfile} ${PARFILE} 
cp -p ${PARFILE}  ${BackupDIR}
mv ${BackupDIR}/${dtpmpjobname}.log ${BackupDIR}


