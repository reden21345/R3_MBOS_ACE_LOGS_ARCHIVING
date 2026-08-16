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
#	2. BackupDIR	--> NFS Datapump Backup Directory
#	3. R3MBACEPW		--> SYS user password
#	4. PARALLEL		--> Datapump parallelism
#	5. TABLES		-->	Tables to export


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
export DBNAME=MBACEDV
export ORADB=`echo ${DBNAME} | tr [:upper:] [:lower:]`

# TABLES
export ENTRY_TABLE=ACE_INTERFACE_LOG_ENTRY
export EXIT_TABLE=ACE_INTERFACE_LOG_EXIT

# Date and Time
export DATE=`date '+%Y%m%d'`
export TIME=`date '+%H%M%S'`

# Directories
export mbaceArch="R3_MBOS_ACE_ARCH_JOB"
export mbaceJob="MBACECIBX_EXPORT"
export JobName="R3_DAILY_${mbaceJob}"
export ScriptDIR=${HOME}/${mbaceArch}/${JobName}
export TempDIR=${ScriptDIR}/tmp
export ParFileDir=${ScriptDIR}/parfiles
export BackupDIR=/DB_BACKUP/${ORADB}/export

# Temporary Files
export expdpTempLog=${TempDIR}/expdp_mbace.tmp 
export tempParfile=${TempDIR}/parfile.tmp
export mbaceDump=${BackupDIR}/mbace_dumpfile.txt

# Password Encrytion
export EncDecDIR=${HOME}/EncryptDecrypt
cd ${EncDecDIR}
export R3MBACEUser=SYS
export R3MBACEPW=`/usr/java8_64/jre/bin/java -jar $EncDecDIR/PasswordDecryptor.jar <INPUT_PASSWORD> | awk '{print $3}'`


# Get Patition Names
export R3MBACESchema=MBACECIBX
export MBACETables=${TempDIR}/mbace_tables.txt
${ORACLE_HOME}/bin/sqlplus -S /nolog <<  EOF > ${MBACETables}
CONNECT "${R3MBACEUser}"/${R3MBACEPW}@${DBNAME} as sysdba
SET LINES 300 PAGES 5 FEEDBACK OFF HEADING OFF
SELECT  
	LISTAGG(TABLE_DATA,',')
		WITHIN GROUP (
			ORDER BY TABLE_DATA
		) AS "TABLE_DATA" 
FROM (
	SELECT 
		TABLE_OWNER
		, TABLE_NAME
		, PARTITION_NAME
		, TABLE_OWNER || '.' || TABLE_NAME || ':' || PARTITION_NAME AS "TABLE_DATA"
		, TO_DATE(SUBSTR(HIGH_VALUE, 11, 10), 'YYYY-MM-DD') AS "HIGH_VALUE"
	FROM (
		SELECT TBL.*
		FROM (
			SELECT 
				DBMS_XMLGEN.GETXMLTYPE(
					'SELECT 
						TABLE_OWNER
						, TABLE_NAME
						, PARTITION_NAME
						, HIGH_VALUE 
					FROM DBA_TAB_PARTITIONS 
					WHERE TABLE_OWNER = ''${R3MBACESchema}'' 
					AND TABLE_NAME IN (
					''${ENTRY_TABLE}'',
					''${EXIT_TABLE}''
					) AS XML_DATA 
			FROM DUAL),
		XMLTABLE('/ROWSET/ROW'
			PASSING XML_DATA
			COLUMNS 
				TABLE_OWNER VARCHAR2(128) PATH 'TABLE_OWNER'
				, TABLE_NAME VARCHAR2(128) PATH 'TABLE_NAME'
				, PARTITION_NAME VARCHAR2(128) PATH 'PARTITION_NAME'
				, HIGH_VALUE VARCHAR2(4000) PATH 'HIGH_VALUE'
		) TBL
	)
)
WHERE HIGH_VALUE = TRUNC(SYSDATE);
PROMPT
EOF


# Extract
cd ${ScriptDIR}

export dtpmptbls=`cat ${MBACETables} | grep .`
export dtpmpjobname="EXPDP_${JobName}_${DATE}_${TIME}"
export PARFILE=${ParFileDir}/${dtpmpjobname}.par

cat <<EOF >  ${PARFILE}
USERID=\"${R3MBACEUser}/${R3MBACEPW}@${DBNAME} as sysdba\"
DIRECTORY=DATABASE_BACKUP_DIR
DUMPFILE=${dtpmpjobname}_%U.dmp
LOGFILE=${dtpmpjobname}.log
TABLES=${dtpmptbls}
PARALLEL=4
METRICS=YES
LOGTIME=ALL
FILESIZE=5G
ENCRYPTION_PASSWORD=Welcome123
EOF

# Mask SYS Password
cat ${PARFILE} | sed 's/\(.*\/\).*\(@.*\)/\1********\2/' > ${tempParfile}

expdp parfile=${PARFILE}  > ${expdpTempLog} 2>&1

cat ${BackupDIR}/${dtpmpjobname}.log
cat ${PARFILE} | egrep "DUMPFILE|TABLES" > ${mbaceDump}
chmod 777 ${mbaceDump}

cp -p ${tempParfile} ${PARFILE} 
cp -p ${PARFILE}  ${BackupDIR}

