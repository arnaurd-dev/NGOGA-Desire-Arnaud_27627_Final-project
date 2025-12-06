-- ============================================
-- PHASE VI: PROCEDURES (5 Procedures)
-- ============================================

SET SERVEROUTPUT ON

-- Procedure 1: Add new farmer with validation
CREATE OR REPLACE PROCEDURE add_new_farmer (
    p_name           IN VARCHAR2,
    p_location       IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_phone          IN VARCHAR2,
    p_soil_type      IN VARCHAR2 DEFAULT 'LOAM',
    p_farm_size      IN NUMBER,
    p_farmer_id      OUT NUMBER
)
IS
    v_email_count NUMBER;
    v_phone_count NUMBER;
    v_new_id NUMBER;
BEGIN
    -- Input validation
    IF p_name IS NULL OR p_location IS NULL OR p_email IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Name, location, and email are required');
    END IF;
    
    IF p_farm_size <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Farm size must be positive');
    END IF;
    
    -- Check for duplicate email
    SELECT COUNT(*) INTO v_email_count
    FROM farmer
    WHERE contact_email = p_email;
    
    IF v_email_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Email already exists: ' || p_email);
    END IF;
    
    -- Check for duplicate phone (if provided)
    IF p_phone IS NOT NULL THEN
        SELECT COUNT(*) INTO v_phone_count
        FROM farmer
        WHERE contact_phone = p_phone;
        
        IF v_phone_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Phone number already exists: ' || p_phone);
        END IF;
    END IF;
    
    -- Generate new farmer ID
    SELECT NVL(MAX(farmer_id), 0) + 1 INTO v_new_id FROM farmer;
    
    -- Insert new farmer
    INSERT INTO farmer (
        farmer_id, name, location, contact_email, 
        contact_phone, soil_type, farm_size_hectares
    ) VALUES (
        v_new_id, p_name, p_location, p_email,
        p_phone, p_soil_type, p_farm_size
    );
    
    COMMIT;
    p_farmer_id := v_new_id;
    
    DBMS_OUTPUT.PUT_LINE('Farmer added successfully. ID: ' || v_new_id);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20005, 'Duplicate value error');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error adding farmer: ' || SQLERRM);
        RAISE;
END add_new_farmer;
/

-- Procedure 2: Submit soil sample for testing
CREATE OR REPLACE PROCEDURE submit_soil_sample (
    p_batch_id        IN NUMBER,
    p_sample_type     IN VARCHAR2 DEFAULT 'SOIL',
    p_collected_by    IN VARCHAR2,
    p_sample_weight   IN NUMBER,
    p_ph_level        IN NUMBER,
    p_sample_id       OUT NUMBER
)
IS
    v_batch_exists NUMBER;
    v_new_sample_id NUMBER;
    v_batch_status VARCHAR2(20);
BEGIN
    -- Check if batch exists and is valid
    SELECT COUNT(*), status INTO v_batch_exists, v_batch_status
    FROM crop_batch
    WHERE batch_id = p_batch_id;
    
    IF v_batch_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Batch ID ' || p_batch_id || ' does not exist');
    END IF;
    
    IF v_batch_status NOT IN ('PLANTED', 'GROWING', 'HARVESTED') THEN
        RAISE_APPLICATION_ERROR(-20011, 'Batch status must be PLANTED, GROWING, or HARVESTED. Current: ' || v_batch_status);
    END IF;
    
    -- Validate input
    IF p_sample_weight NOT BETWEEN 100 AND 1000 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Sample weight must be between 100g and 1000g');
    END IF;
    
    IF p_ph_level NOT BETWEEN 0 AND 14 THEN
        RAISE_APPLICATION_ERROR(-20013, 'pH level must be between 0 and 14');
    END IF;
    
    -- Generate new sample ID
    SELECT NVL(MAX(sample_id), 0) + 1 INTO v_new_sample_id FROM soil_sample;
    
    -- Insert sample
    INSERT INTO soil_sample (
        sample_id, batch_id, sample_type, collection_date,
        collected_by, sample_weight_g, ph_level, sample_status
    ) VALUES (
        v_new_sample_id, p_batch_id, p_sample_type, SYSDATE,
        p_collected_by, p_sample_weight, p_ph_level, 'COLLECTED'
    );
    
    -- Update batch status
    UPDATE crop_batch
    SET status = 'SAMPLED'
    WHERE batch_id = p_batch_id;
    
    COMMIT;
    p_sample_id := v_new_sample_id;
    
    DBMS_OUTPUT.PUT_LINE('Soil sample submitted. Sample ID: ' || v_new_sample_id);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error submitting sample: ' || SQLERRM);
        RAISE;
END submit_soil_sample;
/

-- Procedure 3: Record nutrient analysis results
CREATE OR REPLACE PROCEDURE record_nutrient_analysis (
    p_sample_id       IN NUMBER,
    p_tech_id         IN NUMBER,
    p_nitrogen        IN NUMBER,
    p_phosphorus      IN NUMBER,
    p_potassium       IN NUMBER,
    p_ph_level        IN NUMBER,
    p_is_abnormal     IN CHAR DEFAULT 'N',
    p_analysis_id     OUT NUMBER
)
IS
    v_sample_exists NUMBER;
    v_tech_exists NUMBER;
    v_new_analysis_id NUMBER;
    v_abnormality_reason VARCHAR2(200);
BEGIN
    -- Validate sample exists
    SELECT COUNT(*) INTO v_sample_exists
    FROM soil_sample
    WHERE sample_id = p_sample_id
    AND sample_status = 'TESTED';
    
    IF v_sample_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Sample not found or not ready for analysis');
    END IF;
    
    -- Validate technician exists and is active
    SELECT COUNT(*) INTO v_tech_exists
    FROM lab_technician
    WHERE tech_id = p_tech_id
    AND is_active = 'Y';
    
    IF v_tech_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20021, 'Technician not found or inactive');
    END IF;
    
    -- Validate nutrient ranges
    IF p_nitrogen NOT BETWEEN 0 AND 100 OR
       p_phosphorus NOT BETWEEN 0 AND 100 OR
       p_potassium NOT BETWEEN 0 AND 100 THEN
        RAISE_APPLICATION_ERROR(-20022, 'Nutrient levels must be between 0 and 100%');
    END IF;
    
    IF p_ph_level NOT BETWEEN 0 AND 14 THEN
        RAISE_APPLICATION_ERROR(-20023, 'pH level must be between 0 and 14');
    END IF;
    
    -- Determine abnormality reason
    IF p_is_abnormal = 'Y' THEN
        IF p_nitrogen < 2.0 THEN
            v_abnormality_reason := 'Nitrogen deficiency (<2.0%)';
        ELSIF p_ph_level < 5.5 OR p_ph_level > 7.5 THEN
            v_abnormality_reason := 'pH out of optimal range (5.5-7.5)';
        ELSE
            v_abnormality_reason := 'Other quality issue detected';
        END IF;
    END IF;
    
    -- Generate new analysis ID
    SELECT NVL(MAX(analysis_id), 0) + 1 INTO v_new_analysis_id FROM nutrient_analysis;
    
    -- Insert analysis
    INSERT INTO nutrient_analysis (
        analysis_id, sample_id, tech_id, analysis_date,
        nitrogen_level, phosphorus_level, potassium_level,
        ph_level, is_abnormal, abnormality_reason, analysis_status
    ) VALUES (
        v_new_analysis_id, p_sample_id, p_tech_id, SYSDATE,
        p_nitrogen, p_phosphorus, p_potassium,
        p_ph_level, p_is_abnormal, v_abnormality_reason, 'COMPLETED'
    );
    
    COMMIT;
    p_analysis_id := v_new_analysis_id;
    
    DBMS_OUTPUT.PUT_LINE('Nutrient analysis recorded. Analysis ID: ' || v_new_analysis_id);
    IF p_is_abnormal = 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('Warning: Abnormal result - ' || v_abnormality_reason);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error recording analysis: ' || SQLERRM);
        RAISE;
END record_nutrient_analysis;
/

-- Procedure 4: Process certification decision
CREATE OR REPLACE PROCEDURE process_certification (
    p_batch_id        IN NUMBER,
    p_inspector_id    IN NUMBER,
    p_decision        IN VARCHAR2,  -- 'APPROVED' or 'REJECTED'
    p_rejection_reason IN VARCHAR2 DEFAULT NULL,
    p_cert_id         OUT NUMBER
)
IS
    v_batch_exists NUMBER;
    v_inspector_exists NUMBER;
    v_analysis_exists NUMBER;
    v_analysis_id NUMBER;
    v_new_cert_id NUMBER;
    v_cert_number VARCHAR2(50);
    v_overall_score NUMBER;
BEGIN
    -- Validate batch exists and has analysis
    SELECT COUNT(*) INTO v_batch_exists
    FROM crop_batch cb
    WHERE cb.batch_id = p_batch_id
    AND cb.status IN ('SAMPLED', 'TESTED');
    
    IF v_batch_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Batch not found or not ready for certification');
    END IF;
    
    -- Validate inspector exists and is active
    SELECT COUNT(*) INTO v_inspector_exists
    FROM quality_inspector
    WHERE inspector_id = p_inspector_id
    AND is_active = 'Y'
    AND authorization_level IN ('LEVEL2', 'LEVEL3');
    
    IF v_inspector_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20031, 'Inspector not found or not authorized for certification');
    END IF;
    
    -- Get analysis ID for this batch
    BEGIN
        SELECT na.analysis_id INTO v_analysis_id
        FROM crop_batch cb
        JOIN soil_sample ss ON cb.batch_id = ss.batch_id
        JOIN nutrient_analysis na ON ss.sample_id = na.sample_id
        WHERE cb.batch_id = p_batch_id
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20032, 'No nutrient analysis found for batch');
    END;
    
    -- Validate decision
    IF p_decision NOT IN ('APPROVED', 'REJECTED') THEN
        RAISE_APPLICATION_ERROR(-20033, 'Decision must be APPROVED or REJECTED');
    END IF;
    
    IF p_decision = 'REJECTED' AND p_rejection_reason IS NULL THEN
        RAISE_APPLICATION_ERROR(-20034, 'Rejection reason required for REJECTED decisions');
    END IF;
    
    -- Generate certification ID and number
    SELECT NVL(MAX(cert_id), 0) + 1 INTO v_new_cert_id FROM certification;
    v_cert_number := 'CERT-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || LPAD(v_new_cert_id, 5, '0');
    
    -- Calculate overall score (simplified)
    IF p_decision = 'APPROVED' THEN
        v_overall_score := ROUND(DBMS_RANDOM.VALUE(7.0, 9.5), 1);
    ELSE
        v_overall_score := ROUND(DBMS_RANDOM.VALUE(3.0, 6.5), 1);
    END IF;
    
    -- Insert certification
    INSERT INTO certification (
        cert_id, batch_id, inspector_id, analysis_id,
        decision_date, cert_status, rejection_reason,
        appearance_score, texture_score, nutrient_score, overall_score,
        valid_until, cert_number, issued_by
    ) VALUES (
        v_new_cert_id, p_batch_id, p_inspector_id, v_analysis_id,
        SYSDATE, p_decision, p_rejection_reason,
        TRUNC(DBMS_RANDOM.VALUE(6, 11)),  -- Appearance 6-10
        TRUNC(DBMS_RANDOM.VALUE(6, 11)),  -- Texture 6-10
        TRUNC(DBMS_RANDOM.VALUE(6, 11)),  -- Nutrient 6-10
        v_overall_score,
        CASE WHEN p_decision = 'APPROVED' THEN SYSDATE + 180 ELSE NULL END,
        v_cert_number,
        'Rwanda Standards Board'
    );
    
    -- Update batch status
    UPDATE crop_batch
    SET status = p_decision
    WHERE batch_id = p_batch_id;
    
    COMMIT;
    p_cert_id := v_new_cert_id;
    
    DBMS_OUTPUT.PUT_LINE('Certification processed. Certificate: ' || v_cert_number);
    DBMS_OUTPUT.PUT_LINE('Decision: ' || p_decision || ', Overall Score: ' || v_overall_score);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error processing certification: ' || SQLERRM);
        RAISE;
END process_certification;
/

-- Procedure 5: Generate monthly quality report
CREATE OR REPLACE PROCEDURE generate_quality_report (
    p_month IN NUMBER,
    p_year  IN NUMBER,
    p_report OUT SYS_REFCURSOR
)
IS
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    -- Validate month/year
    IF p_month NOT BETWEEN 1 AND 12 THEN
        RAISE_APPLICATION_ERROR(-20040, 'Month must be between 1 and 12');
    END IF;
    
    IF p_year < 2020 OR p_year > 2030 THEN
        RAISE_APPLICATION_ERROR(-20041, 'Year must be between 2020 and 2030');
    END IF;
    
    -- Calculate date range
    v_start_date := TO_DATE('01-' || p_month || '-' || p_year, 'DD-MM-YYYY');
    v_end_date := ADD_MONTHS(v_start_date, 1);
    
    -- Open cursor with comprehensive report
    OPEN p_report FOR
        SELECT 
            -- Summary statistics
            (SELECT COUNT(*) FROM certification 
             WHERE decision_date >= v_start_date 
             AND decision_date < v_end_date) as total_certifications,
            
            (SELECT COUNT(*) FROM certification 
             WHERE decision_date >= v_start_date 
             AND decision_date < v_end_date
             AND cert_status = 'APPROVED') as approved_certifications,
            
            (SELECT COUNT(*) FROM certification 
             WHERE decision_date >= v_start_date 
             AND decision_date < v_end_date
             AND cert_status = 'REJECTED') as rejected_certifications,
            
            (SELECT ROUND(AVG(overall_score), 2) FROM certification 
             WHERE decision_date >= v_start_date 
             AND decision_date < v_end_date) as avg_quality_score,
            
            -- Nutrient analysis summary
            (SELECT COUNT(*) FROM nutrient_analysis 
             WHERE analysis_date >= v_start_date 
             AND analysis_date < v_end_date) as total_analyses,
            
            (SELECT COUNT(*) FROM nutrient_analysis 
             WHERE analysis_date >= v_start_date 
             AND analysis_date < v_end_date
             AND is_abnormal = 'Y') as abnormal_analyses,
            
            -- Crop type breakdown
            (SELECT LISTAGG(crop_type || ' (' || cnt || ')', ', ') WITHIN GROUP (ORDER BY cnt DESC)
             FROM (SELECT crop_type, COUNT(*) as cnt
                   FROM crop_batch
                   WHERE planting_date >= v_start_date 
                   AND planting_date < v_end_date
                   GROUP BY crop_type
                   ORDER BY COUNT(*) DESC)) as crop_distribution;
    
    DBMS_OUTPUT.PUT_LINE('Monthly quality report generated for ' || 
                         TO_CHAR(v_start_date, 'Month YYYY'));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error generating report: ' || SQLERRM);
        RAISE;
END generate_quality_report;
/

PROMPT ✓ 5 Procedures created successfully





