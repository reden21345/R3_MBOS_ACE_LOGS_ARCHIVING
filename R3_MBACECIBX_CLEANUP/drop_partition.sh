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
#	2. R3ACEPW		--> SYS user password


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
export ScriptDIR=${HOME}/${mbaceArch}/${JobName}
export TempDIR=${ScriptDIR}/tmp
export RBLD_INDX_DIR=${ScriptDIR}/REBUILD_INDEX

# Password Encrytion
export EncDecDIR=${HOME}/EncryptDecrypt
cd ${EncDecDIR}
export R3ACEUser=SYS
export R3ACEPW=`/usr/java8_64/bin/java -jar $EncDecDIR/PasswordDecryptor.jar <INPUT_PASSWORD> | awk '{print $3}'`

# Pre-Check
${ORACLE_HOME}/bin/sqlplus -S "${R3ACEUser}"/"${R3ACEPW}"@${DBNAME} as sysdba <<EOF
@${ScriptDIR}/validate_partition.sql
EXIT
EOF
	
# Delete Partition
${ORACLE_HOME}/bin/sqlplus -S "${R3ACEUser}"/"${R3ACEPW}"@${DBNAME} as sysdba <<EOF
@${ScriptDIR}/drop_partition.sql
EXIT
EOF

# Post-Check
${ORACLE_HOME}/bin/sqlplus -S "${R3ACEUser}"/"${R3ACEPW}"@${DBNAME} as sysdba <<EOF
@${ScriptDIR}/validate_partition.sql
EXIT
EOF

# Rebuild Indexes
cd ${RBLD_INDX_DIR}
${ORACLE_HOME}/bin/sqlplus -S "${R3ACEUser}"/"${R3ACEPW}"@${DBNAME} as sysdba <<EOF
SET TIMING ON LINES 1000 PAGES 1000 COLSEP |
@pre_check_index.sql
SPOOL OFF;
EXIT
EOF

cd ${RBLD_INDX_DIR}
${ORACLE_HOME}/bin/sqlplus -S "${R3ACEUser}"/"${R3ACEPW}"@${DBNAME} as sysdba <<EOF
SET TIMING ON LINES 1000 PAGES 1000 COLSEP |
@rebuild_index.sql
EXIT
EOF

cd ${RBLD_INDX_DIR}
${ORACLE_HOME}/bin/sqlplus -S "${R3ACEUser}"/"${R3ACEPW}"@${DBNAME} as sysdba <<EOF
SET TIMING ON LINES 1000 PAGES 1000 COLSEP |
@post_check_index.sql
EXIT
EOF

