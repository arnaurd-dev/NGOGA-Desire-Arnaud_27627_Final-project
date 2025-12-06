-- ============================================
-- TRIGGER 1: Prevent INSERT on restricted periods
-- ============================================
CREATE OR REPLACE TRIGGER trg_prevent_insert_nutrient
BEFORE INSERT ON nutrient_analysis
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_log_id NUMBER;
BEGIN
    -- Check if current time is restricted
    v_restricted := is_restricted_period(SYSDATE);
    
    IF v_restricted THEN
        -- Log the denied attempt
        v_log_id := log_audit_entry(
            USER,
            'INSERT',
            'NUTRIENT_ANALYSIS',
            :NEW.analysis_id,
            'DENIED',
            'INSERT not allowed on weekdays or holidays'
        );
        
        -- Raise application error
        RAISE_APPLICATION_ERROR(
            -20001,
            'INSERT into NUTRIENT_ANALYSIS is not allowed on weekdays (Monday-Friday) or public holidays. ' ||
            'Please try on weekends (Saturday-Sunday, non-holidays). ' ||
            'Audit Log ID: ' || v_log_id
        );
    ELSE
        -- Log successful attempt (allowed on weekends)
        v_log_id := log_audit_entry(
            USER,
            'INSERT',
            'NUTRIENT_ANALYSIS',
            :NEW.analysis_id,
            'ALLOWED'
        );
        
        DBMS_OUTPUT.PUT_LINE('INSERT allowed (weekend/non-holiday). Audit Log ID: ' || v_log_id);
    END IF;
END trg_prevent_insert_nutrient;
/








-- ============================================
-- TRIGGER 2: Prevent UPDATE on restricted periods
-- ============================================
CREATE OR REPLACE TRIGGER trg_prevent_update_nutrient
BEFORE UPDATE ON nutrient_analysis
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_log_id NUMBER;
BEGIN
    -- Check if current time is restricted
    v_restricted := is_restricted_period(SYSDATE);
    
    IF v_restricted THEN
        -- Log the denied attempt
        v_log_id := log_audit_entry(
            USER,
            'UPDATE',
            'NUTRIENT_ANALYSIS',
            :OLD.analysis_id,
            'DENIED',
            'UPDATE not allowed on weekdays or holidays'
        );
        
        -- Raise application error
        RAISE_APPLICATION_ERROR(
            -20002,
            'UPDATE on NUTRIENT_ANALYSIS is not allowed on weekdays (Monday-Friday) or public holidays. ' ||
            'Please try on weekends (Saturday-Sunday, non-holidays). ' ||
            'Audit Log ID: ' || v_log_id
        );
    ELSE
        -- Log successful attempt
        v_log_id := log_audit_entry(
            USER,
            'UPDATE',
            'NUTRIENT_ANALYSIS',
            :OLD.analysis_id,
            'ALLOWED'
        );
        
        DBMS_OUTPUT.PUT_LINE('UPDATE allowed (weekend/non-holiday). Audit Log ID: ' || v_log_id);
    END IF;
END trg_prevent_update_nutrient;
/







-- ============================================
-- TRIGGER 3: Prevent DELETE on restricted periods
-- ============================================
CREATE OR REPLACE TRIGGER trg_prevent_delete_nutrient
BEFORE DELETE ON nutrient_analysis
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_log_id NUMBER;
BEGIN
    -- Check if current time is restricted
    v_restricted := is_restricted_period(SYSDATE);
    
    IF v_restricted THEN
        -- Log the denied attempt
        v_log_id := log_audit_entry(
            USER,
            'DELETE',
            'NUTRIENT_ANALYSIS',
            :OLD.analysis_id,
            'DENIED',
            'DELETE not allowed on weekdays or holidays'
        );
        
        -- Raise application error
        RAISE_APPLICATION_ERROR(
            -20003,
            'DELETE from NUTRIENT_ANALYSIS is not allowed on weekdays (Monday-Friday) or public holidays. ' ||
            'Please try on weekends (Saturday-Sunday, non-holidays). ' ||
            'Audit Log ID: ' || v_log_id
        );
    ELSE
        -- Log successful attempt
        v_log_id := log_audit_entry(
            USER,
            'DELETE',
            'NUTRIENT_ANALYSIS',
            :OLD.analysis_id,
            'ALLOWED'
        );
        
        DBMS_OUTPUT.PUT_LINE('DELETE allowed (weekend/non-holiday). Audit Log ID: ' || v_log_id);
    END IF;
END trg_prevent_delete_nutrient;
/






