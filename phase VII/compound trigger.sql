-- ============================================
-- COMPOUND TRIGGER: For comprehensive auditing
-- Tracks: BEFORE/AFTER statements and rows
-- ============================================
CREATE OR REPLACE TRIGGER trg_nutrient_comprehensive
FOR INSERT OR UPDATE OR DELETE ON nutrient_analysis
COMPOUND TRIGGER

    -- Declaration section
    TYPE audit_rec IS RECORD (
        action_type VARCHAR2(10),
        analysis_id NUMBER,
        user_id VARCHAR2(50),
        attempt_time TIMESTAMP
    );
    
    TYPE audit_table IS TABLE OF audit_rec;
    v_audit_data audit_table := audit_table();
    
    v_statement_start TIMESTAMP;
    
    -- Before statement section
    BEFORE STATEMENT IS
    BEGIN
        v_statement_start := SYSTIMESTAMP;
        v_audit_data.DELETE; -- Clear collection
    END BEFORE STATEMENT;
    
    -- Before each row section
    BEFORE EACH ROW IS
        v_restricted BOOLEAN;
    BEGIN
        -- Check restriction for INSERT/UPDATE/DELETE
        v_restricted := is_restricted_period(SYSDATE);
        
        IF v_restricted THEN
            -- Store audit data for denied attempts
            v_audit_data.EXTEND;
            v_audit_data(v_audit_data.LAST).action_type := 
                CASE 
                    WHEN INSERTING THEN 'INSERT'
                    WHEN UPDATING THEN 'UPDATE'
                    WHEN DELETING THEN 'DELETE'
                END;
            v_audit_data(v_audit_data.LAST).analysis_id := 
                COALESCE(:NEW.analysis_id, :OLD.analysis_id);
            v_audit_data(v_audit_data.LAST).user_id := USER;
            v_audit_data(v_audit_data.LAST).attempt_time := SYSTIMESTAMP;
            
            -- Raise error
            RAISE_APPLICATION_ERROR(-20004,
                CASE 
                    WHEN INSERTING THEN 'INSERT'
                    WHEN UPDATING THEN 'UPDATE'
                    WHEN DELETING THEN 'DELETE'
                END || 
                ' operation on NUTRIENT_ANALYSIS not allowed on weekdays or holidays.'
            );
        END IF;
    END BEFORE EACH ROW;
    
    -- After each row section
    AFTER EACH ROW IS
    BEGIN
        -- For allowed operations (weekends/non-holidays), log success
        IF NOT is_restricted_period(SYSDATE) THEN
            log_audit_entry(
                USER,
                CASE 
                    WHEN INSERTING THEN 'INSERT'
                    WHEN UPDATING THEN 'UPDATE'
                    WHEN DELETING THEN 'DELETE'
                END,
                'NUTRIENT_ANALYSIS',
                COALESCE(:NEW.analysis_id, :OLD.analysis_id),
                'SUCCESS'
            );
        END IF;
    END AFTER EACH ROW;
    
    -- After statement section
    AFTER STATEMENT IS
        v_log_id NUMBER;
    BEGIN
        -- Log batch information about the statement
        IF v_audit_data.COUNT > 0 THEN
            FOR i IN 1..v_audit_data.COUNT LOOP
                log_audit_entry(
                    v_audit_data(i).user_id,
                    v_audit_data(i).action_type,
                    'NUTRIENT_ANALYSIS',
                    v_audit_data(i).analysis_id,
                    'DENIED',
                    'Batch restriction applied'
                );
            END LOOP;
            
            DBMS_OUTPUT.PUT_LINE('Statement blocked: ' || v_audit_data.COUNT || 
                               ' attempts denied due to restrictions.');
        END IF;
    END AFTER STATEMENT;
    
END trg_nutrient_comprehensive;
/
