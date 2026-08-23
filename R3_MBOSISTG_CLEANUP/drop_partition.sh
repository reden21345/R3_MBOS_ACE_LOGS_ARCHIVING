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
#	2. R3MBOSPW		--> SYS user password


# Environment Variables
export HOME=/home/controlm
#export ORACLE_HOME=${HOME}/oracle/client/19.0.0
#export TNS_ADMIN=${ORACLE_HOME}/network/admin
export DBNAME=MBOSIDV
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
export ScriptDIR=${HOME}/TaskController/${mbosAceArch}/${JobName}
export TempDIR=${ScriptDIR}/tmp
export RBLD_INDX_DIR=${ScriptDIR}/REBUILD_INDEX

# Password Encrytion
export EncDecDIR=${HOME}/EncryptDecrypt
cd ${EncDecDIR}
export R3MBOSUser=SYS
export R3MBOSPW=`/usr/java8_64/bin/java -jar $EncDecDIR/PasswordDecryptor.jar 4as1KKc1yhlkVentEPqK0NYgFuWv3gyx | awk '{print $3}'`

# Pre-Check
${ORACLE_HOME}/bin/sqlplus -S "${R3MBOSUser}"/"${R3MBOSPW}"@${DBNAME} as sysdba <<EOF
@${ScriptDIR}/validate_partition.sql
EXIT
EOF
	
# Delete Partition
${ORACLE_HOME}/bin/sqlplus -S "${R3MBOSUser}"/"${R3MBOSPW}"@${DBNAME} as sysdba <<EOF
@${ScriptDIR}/drop_partition.sql
EXIT
EOF

# Post-Check
${ORACLE_HOME}/bin/sqlplus -S "${R3MBOSUser}"/"${R3MBOSPW}"@${DBNAME} as sysdba <<EOF
@${ScriptDIR}/validate_partition.sql
EXIT
EOF

# Rebuild Indexes
cd ${RBLD_INDX_DIR}
${ORACLE_HOME}/bin/sqlplus -S "${R3MBOSUser}"/"${R3MBOSPW}"@${DBNAME} as sysdba <<EOF
SET TIMING ON LINES 1000 PAGES 1000 COLSEP |
@pre_check_index.sql
SPOOL OFF;
EXIT
EOF

cd ${RBLD_INDX_DIR}
${ORACLE_HOME}/bin/sqlplus -S "${R3MBOSUser}"/"${R3MBOSPW}"@${DBNAME} as sysdba <<EOF
SET TIMING ON LINES 1000 PAGES 1000 COLSEP |
@rebuild_index.sql
EXIT
EOF

cd ${RBLD_INDX_DIR}
${ORACLE_HOME}/bin/sqlplus -S "${R3MBOSUser}"/"${R3MBOSPW}"@${DBNAME} as sysdba <<EOF
SET TIMING ON LINES 1000 PAGES 1000 COLSEP |
@post_check_index.sql
EXIT
EOF

