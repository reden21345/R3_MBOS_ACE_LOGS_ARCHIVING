prompt
prompt =============================
prompt          POST_CHECK
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
WHERE table_name IN ('MB_AUDIT_OFFLINE','MB_DAILY_SYNC_LOGS_OFFLINE','API_LOG_OFFLINE')
AND partitioned = 'NO' AND index_type <> 'LOB' AND status <> 'VALID' and owner = 'MBOSIUSR_OFFLINE';



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
WHERE table_name IN ('MB_AUDIT_OFFLINE','MB_DAILY_SYNC_LOGS_OFFLINE','API_LOG_OFFLINE')
AND partitioned = 'YES' AND index_type <> 'LOB' AND status <> 'USABLE' and owner = 'MBOSIUSR_OFFLINE');

