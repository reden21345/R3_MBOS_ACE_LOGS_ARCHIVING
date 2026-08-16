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
export mbosAceArch="R3_MBOS_ACE_ARCH_JOB"
export mbosJob="MBOSISTG_IMPORT"
export JobName="R3_DAILY_${mbosJob}"
export ScriptDIR=${HOME}/${mbosAceArch}/${JobName}
export ParFileDir=${ScriptDIR}/parfiles
export TempDIR=${ScriptDIR}/tmp
export BackupDIR=/DB_BACKUP/${ORADB}/export
export ACEBKPDIR=/DB_BACKUP/mbacedv/export


# Temporary Files
export impdpTempLog=${TempDIR}/impdp_mbos_offline.tmp 
export tempParfile=${TempDIR}/parfile.tmp
export aceDump="${ACEBKPDIR}/mbace_tables.txt"

# Password Encrytion
export EncDecDIR=${HOME}/EncryptDecrypt
cd ${EncDecDIR}
export R3MBOSUser=SYS
export R3MBOSPW=`/usr/java8_64/bin/java -jar $EncDecDIR/PasswordDecryptor.jar yKsbXwpFj45bwekTW+6uLMlwsj0pN4wr | awk '{print $3}'`


# Load
cd ${ScriptDIR}
export R3MBACESchema=MBACECIBX
export R3MBOSSchema=MBOSISTG
export dmpfile=`cat ${aceDump} | grep DUMPFILE | grep .`
export dmptbl=`cat ${aceDump} | grep TABLES | grep .`
export dtpmpjobname="IMPDP_${JobName}_${DATE}_${TIME}"
export PARFILE=${ParFileDir}/${dtpmpjobname}.par


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
REMAP_SCHEMA=${R3MBACESchema}:${R3MBOSSchema}
REMAP_TABLESPACE=${R3MBACESchema}:${R3MBOSSchema}
EOF

# Mask SYS Password
cat ${PARFILE} | sed 's/\(.*\/\).*\(@.*\)/\1********\2/' > ${tempParfile}

impdp parfile=${PARFILE} > ${impdpTempLog} 2>&1

cat ${ACEBKPDIR}/${dtpmpjobname}.log

cp -p ${tempParfile} ${PARFILE} 
cp -p ${PARFILE}  ${BackupDIR}
mv ${ACEBKPDIR}/${dtpmpjobname}.log ${BackupDIR}

