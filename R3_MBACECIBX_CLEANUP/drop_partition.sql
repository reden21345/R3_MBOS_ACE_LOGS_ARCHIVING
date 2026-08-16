SET SERVEROUTPUT ON PAGES 1000 LINES 1000 FEEDBACK OFF
DECLARE
    v_cutoff_date 			DATE := SYSDATE - 30;
    v_partition_name 		VARCHAR2(255);
    v_high_value 			VARCHAR2(4000);
    v_high_value_date 		DATE;
    v_date_str 				VARCHAR2(20);
	v_owner_name        	VARCHAR2(30) := 'MBACECIBX' ;
    v_table_name 			VARCHAR2(255);
    v_tables 				SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('ACE_INTERFACE_LOG_ENTRY','ACE_INTERFACE_LOG_EXIT');
    v_partitions_dropped  	NUMBER := 0;  

BEGIN
    -- Loop each table
    FOR i IN 1..v_tables.COUNT 
	
	LOOP
        v_table_name := v_tables(i);
 
        -- retrieve partitions and their high values
        FOR rec 
			IN (SELECT PARTITION_NAME, HIGH_VALUE
                FROM DBA_TAB_PARTITIONS
                WHERE TABLE_NAME = v_table_name
                AND TABLE_OWNER = v_owner_name
                AND PARTITION_NAME != 'TXMIN') 
		LOOP

            -- get partition boundary value
            v_high_value := rec.HIGH_VALUE;
 
            -- collect date part from the HIGH_VALUE string
            -- if the date part is enclosed within single quotes and starts after TO_DATE('
            v_date_str := REGEXP_SUBSTR(v_high_value, '''(.*?)''', 1, 1, NULL, 1);
 
            -- convert date string to a DATE type

            BEGIN
                v_high_value_date := TO_DATE(v_date_str, 'YYYY-MM-DD HH24:MI:SS');
            EXCEPTION
                WHEN OTHERS THEN
			-- skip partition and output error message if conversion is failed
                    DBMS_OUTPUT.PUT_LINE('Skipping partition: ' || rec.PARTITION_NAME || ' of table ' || v_table_name || ' due to conversion error. Extracted value: ' || v_date_str);
                    CONTINUE;
            END;

            -- Check if the partition is older than desired date
            IF v_high_value_date < v_cutoff_date 
			THEN
                v_partition_name := rec.PARTITION_NAME;
                v_partitions_dropped := v_partitions_dropped + 1; 
                -- Drop the partition
				
                BEGIN
				
					EXECUTE IMMEDIATE ('ALTER TABLE ' || v_owner_name || '.' || v_table_name || ' DROP PARTITION '|| v_partition_name || ' UPDATE GLOBAL INDEXES');					
					DBMS_OUTPUT.PUT_LINE('Dropped partition: ' || v_partition_name || ' from table ' || v_owner_name || '.' || v_table_name);
					
				EXCEPTION WHEN OTHERS THEN
					IF SQLCODE <> 0
					THEN
						DBMS_OUTPUT.PUT_LINE('Failed to drop partition: ' || v_partition_name || ' from table ' || v_owner_name || '.' || v_table_name || '. Error: ' || SQLERRM);
						RAISE; 
					END IF;
				RETURN;
				END;
            END IF;
        END LOOP;
    END LOOP;


    	-- Final check and message
    IF v_partitions_dropped = 0 THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'INFO: No partitions to be dropped.' || CHR(10) || CHR(10));
    ELSE
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Total partitions dropped: ' || v_partitions_dropped || CHR(10) || CHR(10));
    END IF;

	EXCEPTION WHEN OTHERS THEN
        -- General error handling for the entire block
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/
 
 