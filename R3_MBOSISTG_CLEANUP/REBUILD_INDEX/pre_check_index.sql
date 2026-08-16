prompt
prompt =============================
prompt          PRE_CHECK
prompt =============================
prompt



prompt
prompt ==== CHECK INDEX STATUS =====
prompt


col owner for a15
col index_name for a30
col table_space_name for a15
col status for a13

SELECT owner,index_name,tablespace_name,status 
FROM dba_indexes 
WHERE table_name IN ('ACE_INTERFACE_LOG_ENTRY','ACE_INTERFACE_LOG_EXIT')
AND partitioned = 'NO' AND index_type <> 'LOB' AND status <> 'VALID' and owner = 'MBOSISTG';



prompt
prompt ==== CHECK INDEX PARTITIONED =====
prompt


col index_owner for a13
col index_name for a30
col partition_name for a20
col tablespace_name for a15
col status for a15


SELECT index_owner,index_name,partition_name,tablespace_name,status 
FROM dba_ind_partitions WHERE index_name 
IN (SELECT index_name FROM dba_indexes 
WHERE table_name IN ('ACE_INTERFACE_LOG_ENTRY','ACE_INTERFACE_LOG_EXIT')
AND partitioned = 'YES' AND index_type <> 'LOB' AND status <> 'USABLE' and owner = 'MBOSISTG');


prompt
prompt ==== REBUILD INDEX =====
prompt


set echo off
set head off
set feedback off
set timing off
set trimspool on

--REBUILD INDEX
spool rebuild_index.sql
SELECT 'ALTER INDEX '||owner||'.'||index_name||' REBUILD ONLINE TABLESPACE '||tablespace_name||';' FROM dba_indexes WHERE table_name IN ('ACE_INTERFACE_LOG_ENTRY','ACE_INTERFACE_LOG_EXIT') and owner = 'MBOSISTG' AND partitioned = 'NO' AND index_type <> 'LOB' AND status <> 'VALID';



--REBUILD INDEX PARTITION
SELECT 'ALTER INDEX '||index_owner||'.'||index_name||' REBUILD PARTITION '||partition_name||' TABLESPACE '||tablespace_name||' ONLINE;' FROM dba_ind_partitions WHERE index_name IN (SELECT index_name FROM dba_indexes WHERE table_name IN ('ACE_INTERFACE_LOG_ENTRY','ACE_INTERFACE_LOG_EXIT') and index_owner = 'MBOSISTG' AND partitioned = 'YES' AND index_type <> 'LOB') and index_owner = 'MBOSISTG' AND status <> 'USABLE';