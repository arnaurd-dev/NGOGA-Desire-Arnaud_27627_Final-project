-- ============================================
-- TEST SCRIPT 3: Test Compound Trigger
-- ============================================
SET SERVEROUTPUT ON
DECLARE
    v_batch_size NUMBER := 3;
    v_start_id NUMBER;
    v_success_count NUMBER := 0;
    v_error_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('TESTING COMPOUND TRIGGER');
    DBMS_OUTPUT.PUT_LINE('============================================');
    
    -- Get starting ID
    SELECT NVL(MAX(analysis_id), 0) + 1 INTO v_start_id 
    FROM nutrient_analysis;
    
    DBMS_OUTPUT.PUT_LINE('Testing batch operations...');
    DBMS_OUTPUT.PUT_LINE('Current date: ' || TO_CHAR(SYSDATE, 'Day, DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Restricted period: ' || 
        CASE WHEN is_restricted_period(SYSDATE) THEN 'YES' ELSE 'NO' END);
    
    -- Try batch INSERT (should all succeed or all fail based on restrictions)
    BEGIN
        FOR i IN 1..v_batch_size LOOP
            INSERT INTO nutrient_analysis (
                analysis_id, sample_id, tech_id, analysis_date,
                nitrogen_level, analysis_status
            ) VALUES (
                v_start_id + i - 1, 
                1 + MOD(i, 5),  -- Different sample IDs
                1 + MOD(i, 3),  -- Different tech IDs
                SYSDATE,
                2.5 + (i * 0.5),
                'COMPLETED'
            );
        END LOOP;
        
        COMMIT;
        v_success_count := v_batch_size;
        DBMS_OUTPUT.PUT_LINE('✓ Batch INSERT completed: ' || v_batch_size || ' records');
        
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_batch_size;
            DBMS_OUTPUT.PUT_LINE('✗ Batch INSERT blocked: ' || SQLERRM);
            ROLLBACK;
    END;
    
    -- Test UPDATE multiple records
    IF v_success_count > 0 THEN
        BEGIN
            UPDATE nutrient_analysis
            SET nitrogen_level = nitrogen_level + 0.1
            WHERE analysis_id BETWEEN v_start_id AND v_start_id + v_batch_size - 1;
            
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('✓ Batch UPDATE completed');
            
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('✗ Batch UPDATE blocked: ' || SQLERRM);
                ROLLBACK;
        END;
    END IF;
    
    -- Check audit log for batch operations
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Batch Audit Summary:');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
    
    FOR audit_summary IN (
        SELECT action_type, status, COUNT(*) as record_count,
               MIN(attempt_date) as first_attempt,
               MAX(attempt_date) as last_attempt
        FROM audit_log
        WHERE attempt_date >= SYSTIMESTAMP - INTERVAL '5' MINUTE
        AND table_name = 'NUTRIENT_ANALYSIS'
        GROUP BY action_type, status
        ORDER BY action_type, status
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            audit_summary.action_type || ' | ' ||
            audit_summary.status || ' | ' ||
            'Count: ' || audit_summary.record_count || ' | ' ||
            'Time: ' || TO_CHAR(audit_summary.first_attempt, 'HH24:MI:SS') || 
            ' to ' || TO_CHAR(audit_summary.last_attempt, 'HH24:MI:SS')
        );
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
    DBMS_OUTPUT.PUT_LINE('Compound trigger test completed.');
    
END;
/












-- ============================================
-- FINAL TEST REPORT
-- ============================================
SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('PHASE VII - FINAL TEST REPORT');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Test Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Check 1: Verify triggers exist
    DBMS_OUTPUT.PUT_LINE('CHECK 1: TRIGGERS EXIST');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));
    
    FOR trig_rec IN (
        SELECT trigger_name, trigger_type, table_name, status
        FROM user_triggers
        WHERE table_name = 'NUTRIENT_ANALYSIS'
        ORDER BY trigger_name
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(trig_rec.trigger_name, 30) ||
            RPAD(trig_rec.trigger_type, 15) ||
            CASE WHEN trig_rec.status = 'ENABLED' THEN '✓ ENABLED' ELSE '✗ DISABLED' END
        );
    END LOOP;
    
    -- Check 2: Verify functions exist
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CHECK 2: FUNCTIONS EXIST');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));
    
    FOR func_rec IN (
        SELECT object_name, status
        FROM user_objects
        WHERE object_type = 'FUNCTION'
        AND object_name LIKE 'IS_%' OR object_name LIKE 'LOG_%'
        ORDER BY object_name
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(func_rec.object_name, 35) ||
            CASE WHEN func_rec.status = 'VALID' THEN '✓ VALID' ELSE '✗ INVALID' END
        );
    END LOOP;
    
    -- Check 3: Holiday table has data
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CHECK 3: HOLIDAY DATA');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));
    
    DECLARE
        v_holiday_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_holiday_count FROM holiday;
        DBMS_OUTPUT.PUT_LINE('Holidays in table: ' || v_holiday_count);
        
        IF v_holiday_count >= 5 THEN
            DBMS_OUTPUT.PUT_LINE('✓ Holiday table populated');
        ELSE
            DBMS_OUTPUT.PUT_LINE('✗ Holiday table needs more data');
        END IF;
    END;
    
    -- Check 4: Audit log functionality
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CHECK 4: AUDIT LOG FUNCTIONALITY');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));
    
    DECLARE
        v_audit_count NUMBER;
        v_test_log_id NUMBER;
    BEGIN
        -- Test audit logging
        v_test_log_id := log_audit_entry(
            'TEST_USER',
            'TEST',
            'TEST_TABLE',
            999,
            'TEST',
            'Test audit entry'
        );
        
        SELECT COUNT(*) INTO v_audit_count FROM audit_log;
        
        DBMS_OUTPUT.PUT_LINE('Total audit records: ' || v_audit_count);
        DBMS_OUTPUT.PUT_LINE('Last test log ID: ' || v_test_log_id);
        
        IF v_test_log_id > 0 THEN
            DBMS_OUTPUT.PUT_LINE('✓ Audit logging working');
        ELSE
            DBMS_OUTPUT.PUT_LINE('✗ Audit logging failed');
        END IF;
    END;
    
    -- Check 5: Business rule test summary
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CHECK 5: BUSINESS RULE SUMMARY');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));
    
    DECLARE
        v_is_weekday BOOLEAN;
        v_is_holiday BOOLEAN;
        v_is_restricted BOOLEAN;
    BEGIN
        v_is_weekday := is_weekday_date(SYSDATE);
        v_is_holiday := is_holiday_date(SYSDATE);
        v_is_restricted := is_restricted_period(SYSDATE);
        
        DBMS_OUTPUT.PUT_LINE('Current Date: ' || TO_CHAR(SYSDATE, 'Day, DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Is Weekday: ' || CASE WHEN v_is_weekday THEN 'Yes' ELSE 'No' END);
        DBMS_OUTPUT.PUT_LINE('Is Holiday: ' || CASE WHEN v_is_holiday THEN 'Yes' ELSE 'No' END);
        DBMS_OUTPUT.PUT_LINE('Is Restricted: ' || CASE WHEN v_is_restricted THEN 'Yes' ELSE 'No' END);
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('BUSINESS RULE:');
        DBMS_OUTPUT.PUT_LINE('Lab technicians CANNOT INSERT/UPDATE/DELETE on:');
        DBMS_OUTPUT.PUT_LINE('1. Weekdays (Monday-Friday)');
        DBMS_OUTPUT.PUT_LINE('2. Public holidays');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Current status: ' || 
            CASE WHEN v_is_restricted THEN 
                '✗ OPERATIONS RESTRICTED' 
            ELSE 
                '✓ OPERATIONS ALLOWED (weekend/non-holiday)' 
            END
        );
    END;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('PHASE VII IMPLEMENTATION COMPLETE');
    DBMS_OUTPUT.PUT_LINE('============================================');
    
END;
/
