SET SERVEROUTPUT ON PAGES 1000 LINES 1000 FEEDBACK OFF
DECLARE
    v_cutoff_date       DATE := SYSDATE - 30;
    v_high_value        VARCHAR2(4000);
    v_high_value_date   DATE;
    v_date_str          VARCHAR2(20);
    v_table_name        VARCHAR2(255);
	v_owner_name		VARCHAR2(20) := 'MBOSIUSR_OFFLINE';
    v_tables            SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('MB_AUDIT_OFFLINE','MB_DAILY_SYNC_LOGS_OFFLINE','API_LOG_OFFLINE');
	v_partition_name    VARCHAR2(20);
	v_sql               VARCHAR2(1000);
	v_row_count         NUMBER;
    v_partitions_listed NUMBER := 0;

BEGIN

DBMS_OUTPUT.PUT_LINE(CHR(10) || CHR(10) || CHR(10) || CHR(10) || CHR(10) || 'Cutoff Date: ' || v_cutoff_date);

    -- Loop through each table in the list
    FOR i IN 1 .. v_tables.COUNT LOOP
        v_table_name := v_tables(i);
		
		DBMS_OUTPUT.PUT_LINE(CHR(10) || '------ List of Partitions to be deleted on ' || v_owner_name || '.' || v_table_name || ':');

        -- Loop through partitions of the table
        FOR rec IN (
            SELECT PARTITION_NAME, HIGH_VALUE
            FROM DBA_TAB_PARTITIONS
            WHERE TABLE_OWNER = v_owner_name 
            AND TABLE_NAME = v_table_name
            AND PARTITION_NAME != 'TXMIN'
            ORDER BY PARTITION_POSITION
			
        ) LOOP
            v_high_value := rec.HIGH_VALUE;
			v_partition_name := rec.PARTITION_NAME;

            -- Extract date literal between quotes
            v_date_str := REGEXP_SUBSTR(v_high_value, '''(.*?)''', 1, 1, NULL, 1);

            BEGIN
                v_high_value_date := TO_DATE(v_date_str, 'YYYY-MM-DD HH24:MI:SS');
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Skipping partition: ' || rec.PARTITION_NAME || ' (invalid date format: ' || v_date_str || ')');
                CONTINUE;
            END;

            -- Check if partition is older than cutoff
            IF v_high_value_date < v_cutoff_date THEN
			
				v_sql := 'SELECT COUNT(*) FROM ' || v_owner_name || '.' || v_table_name || ' PARTITION (' || v_partition_name || ')';
				EXECUTE IMMEDIATE v_sql INTO v_row_count;
			
                DBMS_OUTPUT.PUT_LINE('PARTITION NAME: ' || rec.PARTITION_NAME || ' | PARTITION DATE: ' || TO_DATE(v_high_value_date, 'DD-MON-YYYY') || ' | LOG DATE: ' || TO_DATE(v_high_value_date - 1, 'DD-MON-YYYY') || ' | ROW COUNT: ' || v_row_count);
				
                v_partitions_listed := v_partitions_listed + 1;
				
            END IF;
        END LOOP;
    END LOOP;

    IF v_partitions_listed = 0 THEN
		DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Partitions are within retention period.' || CHR(10) || CHR(10));
    ELSE
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Total partitions listed: ' || v_partitions_listed || CHR(10) || CHR(10));
    END IF;
	
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

