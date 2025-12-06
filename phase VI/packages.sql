-- ============================================
-- PHASE VI: PACKAGE (Specification + Body)
-- ============================================

-- Package Specification
CREATE OR REPLACE PACKAGE nutrition_pkg
IS
    -- Type definitions
    TYPE farmer_stats_rec IS RECORD (
        farmer_id NUMBER,
        name VARCHAR2(100),
        total_batches NUMBER,
        approved_batches NUMBER,
        approval_rate NUMBER,
        performance_rating VARCHAR2(20)
    );
    
    TYPE farmer_stats_tab IS TABLE OF farmer_stats_rec;
    
    -- Constants
    MIN_NITROGEN CONSTANT NUMBER := 2.5;
    MIN_PHOSPHORUS CONSTANT NUMBER := 0.3;
    MIN_POTASSIUM CONSTANT NUMBER := 1.8;
    
    -- Procedures
    PROCEDURE register_new_farmer(
        p_name IN VARCHAR2,
        p_location IN VARCHAR2,
        p_email IN VARCHAR2,
        p_farmer_id OUT NUMBER
    );
    
    PROCEDURE process_lab_sample(
        p_sample_id IN NUMBER,
        p_tech_id IN NUMBER,
        p_results_json IN CLOB
    );
    
    PROCEDURE generate_certificate(
        p_batch_id IN NUMBER,
        p_inspector_id IN NUMBER,
        p_cert_number OUT VARCHAR2
    );
    
    -- Functions
    FUNCTION calculate_soil_health(
        p_sample_id IN NUMBER
    ) RETURN VARCHAR2;
    
    FUNCTION get_farmer_performance(
        p_farmer_id IN NUMBER
    ) RETURN farmer_stats_rec;
    
    FUNCTION validate_certification_criteria(
        p_batch_id IN NUMBER
    ) RETURN BOOLEAN;
    
    -- Cursor-based procedure
    PROCEDURE generate_performance_report(
        p_report OUT SYS_REFCURSOR
    );
    
    -- Exception declarations
    invalid_nutrient_data EXCEPTION;
    farmer_not_found EXCEPTION;
    batch_not_ready EXCEPTION;
    
    -- Error codes
    PRAGMA EXCEPTION_INIT(invalid_nutrient_data, -20050);
    PRAGMA EXCEPTION_INIT(farmer_not_found, -20051);
    PRAGMA EXCEPTION_INIT(batch_not_ready, -20052);
    
END nutrition_pkg;
/

-- Package Body
CREATE OR REPLACE PACKAGE BODY nutrition_pkg
IS
    -- Procedure 1: Register new farmer
    PROCEDURE register_new_farmer(
        p_name IN VARCHAR2,
        p_location IN VARCHAR2,
        p_email IN VARCHAR2,
        p_farmer_id OUT NUMBER
    ) IS
        v_new_id NUMBER;
        v_email_count NUMBER;
    BEGIN
        -- Validate inputs
        IF p_name IS NULL OR p_location IS NULL OR p_email IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Name, location, and email are required');
        END IF;
        
        -- Check for duplicate email
        SELECT COUNT(*) INTO v_email_count
        FROM farmer
        WHERE contact_email = p_email;
        
        IF v_email_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Email already registered: ' || p_email);
        END IF;
        
        -- Generate new ID
        SELECT NVL(MAX(farmer_id), 0) + 1 INTO v_new_id FROM farmer;
        
        -- Insert farmer
        INSERT INTO farmer (
            farmer_id, name, location, contact_email, registration_date
        ) VALUES (
            v_new_id, p_name, p_location, p_email, SYSDATE
        );
        
        COMMIT;
        p_farmer_id := v_new_id;
        
        DBMS_OUTPUT.PUT_LINE('Farmer registered successfully. ID: ' || v_new_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error registering farmer: ' || SQLERRM);
            RAISE;
    END register_new_farmer;
    
    -- Procedure 2: Process lab sample
    PROCEDURE process_lab_sample(
        p_sample_id IN NUMBER,
        p_tech_id IN NUMBER,
        p_results_json IN CLOB
    ) IS
        v_sample_exists NUMBER;
        v_tech_exists NUMBER;
        v_analysis_id NUMBER;
    BEGIN
        -- Validate sample exists
        SELECT COUNT(*) INTO v_sample_exists
        FROM soil_sample
        WHERE sample_id = p_sample_id;
        
        IF v_sample_exists = 0 THEN
            RAISE farmer_not_found;
        END IF;
        
        -- Validate technician exists
        SELECT COUNT(*) INTO v_tech_exists
        FROM lab_technician
        WHERE tech_id = p_tech_id AND is_active = 'Y';
        
        IF v_tech_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20053, 'Technician not found or inactive');
        END IF;
        
        -- Generate analysis ID
        SELECT NVL(MAX(analysis_id), 0) + 1 INTO v_analysis_id 
        FROM nutrient_analysis;
        
        -- Insert analysis (simplified - in real system would parse JSON)
        INSERT INTO nutrient_analysis (
            analysis_id, sample_id, tech_id, analysis_date,
            nitrogen_level, phosphorus_level, potassium_level,
            analysis_status
        ) VALUES (
            v_analysis_id, p_sample_id, p_tech_id, SYSDATE,
            3.5, 0.5, 2.5, 'COMPLETED'  -- Example values
        );
        
        -- Update sample status
        UPDATE soil_sample
        SET sample_status = 'TESTED'
        WHERE sample_id = p_sample_id;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Sample processed. Analysis ID: ' || v_analysis_id);
        
    EXCEPTION
        WHEN farmer_not_found THEN
            RAISE_APPLICATION_ERROR(-20051, 'Sample ID ' || p_sample_id || ' not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END process_lab_sample;
    
    -- Procedure 3: Generate certificate
    PROCEDURE generate_certificate(
        p_batch_id IN NUMBER,
        p_inspector_id IN NUMBER,
        p_cert_number OUT VARCHAR2
    ) IS
        v_batch_exists NUMBER;
        v_inspector_exists NUMBER;
        v_analysis_id NUMBER;
        v_cert_id NUMBER;
    BEGIN
        -- Validate batch
        SELECT COUNT(*) INTO v_batch_exists
        FROM crop_batch
        WHERE batch_id = p_batch_id
        AND status IN ('TESTED', 'SAMPLED');
        
        IF v_batch_exists = 0 THEN
            RAISE batch_not_ready;
        END IF;
        
        -- Validate inspector
        SELECT COUNT(*) INTO v_inspector_exists
        FROM quality_inspector
        WHERE inspector_id = p_inspector_id
        AND is_active = 'Y';
        
        IF v_inspector_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20054, 'Inspector not found or inactive');
        END IF;
        
        -- Get analysis for batch
        BEGIN
            SELECT na.analysis_id INTO v_analysis_id
            FROM crop_batch cb
            JOIN soil_sample ss ON cb.batch_id = ss.batch_id
            JOIN nutrient_analysis na ON ss.sample_id = na.sample_id
            WHERE cb.batch_id = p_batch_id
            AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20055, 'No analysis found for batch');
        END;
        
        -- Generate certificate
        v_cert_number := generate_certificate_number();
        
        SELECT NVL(MAX(cert_id), 0) + 1 INTO v_cert_id FROM certification;
        
        INSERT INTO certification (
            cert_id, batch_id, inspector_id, analysis_id,
            decision_date, cert_status, cert_number,
            overall_score, valid_until
        ) VALUES (
            v_cert_id, p_batch_id, p_inspector_id, v_analysis_id,
            SYSDATE, 'APPROVED', v_cert_number,
            8.5, SYSDATE + 180
        );
        
        -- Update batch status
        UPDATE crop_batch
        SET status = 'CERTIFIED'
        WHERE batch_id = p_batch_id;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Certificate generated: ' || v_cert_number);
        
    EXCEPTION
        WHEN batch_not_ready THEN
            RAISE_APPLICATION_ERROR(-20052, 'Batch not ready for certification');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END generate_certificate;
    
    -- Function 1: Calculate soil health
    FUNCTION calculate_soil_health(
        p_sample_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_nitrogen NUMBER;
        v_phosphorus NUMBER;
        v_potassium NUMBER;
        v_ph NUMBER;
        v_organic_matter NUMBER;
        v_health_score NUMBER;
        v_health_status VARCHAR2(20);
    BEGIN
        -- Get nutrient data
        SELECT nitrogen_level, phosphorus_level, potassium_level,
               ph_level, organic_matter
        INTO v_nitrogen, v_phosphorus, v_potassium, v_ph, v_organic_matter
        FROM nutrient_analysis
        WHERE sample_id = p_sample_id;
        
        -- Calculate health score (simplified formula)
        v_health_score := 
            (CASE WHEN v_nitrogen >= MIN_NITROGEN THEN 20 ELSE v_nitrogen/MIN_NITROGEN * 20 END) +
            (CASE WHEN v_phosphorus >= MIN_PHOSPHORUS THEN 20 ELSE v_phosphorus/MIN_PHOSPHORUS * 20 END) +
            (CASE WHEN v_potassium >= MIN_POTASSIUM THEN 20 ELSE v_potassium/MIN_POTASSIUM * 20 END) +
            (CASE WHEN v_ph BETWEEN 5.5 AND 7.5 THEN 20 
                  WHEN v_ph BETWEEN 5.0 AND 8.0 THEN 10 
                  ELSE 0 END) +
            (CASE WHEN v_organic_matter >= 3.0 THEN 20 ELSE v_organic_matter/3.0 * 20 END);
        
        -- Determine health status
        IF v_health_score >= 90 THEN
            v_health_status := 'EXCELLENT';
        ELSIF v_health_score >= 70 THEN
            v_health_status := 'GOOD';
        ELSIF v_health_score >= 50 THEN
            v_health_status := 'FAIR';
        ELSE
            v_health_status := 'POOR';
        END IF;
        
        RETURN v_health_status;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'NO_DATA';
        WHEN OTHERS THEN
            RETURN 'ERROR';
    END calculate_soil_health;
    
    -- Function 2: Get farmer performance
    FUNCTION get_farmer_performance(
        p_farmer_id IN NUMBER
    ) RETURN farmer_stats_rec
    IS
        v_stats farmer_stats_rec;
    BEGIN
        SELECT 
            f.farmer_id,
            f.name,
            COUNT(cb.batch_id) as total_batches,
            SUM(CASE WHEN c.cert_status = 'APPROVED' THEN 1 ELSE 0 END) as approved_batches,
            ROUND(
                NVL(
                    SUM(CASE WHEN c.cert_status = 'APPROVED' THEN 1 ELSE 0 END) /
                    NULLIF(COUNT(cb.batch_id), 0) * 100, 
                0), 2
            ) as approval_rate,
            get_farmer_rating(p_farmer_id) as performance_rating
        INTO v_stats
        FROM farmer f
        LEFT JOIN crop_batch cb ON f.farmer_id = cb.farmer_id
        LEFT JOIN certification c ON cb.batch_id = c.batch_id
        WHERE f.farmer_id = p_farmer_id
        GROUP BY f.farmer_id, f.name;
        
        RETURN v_stats;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_stats.farmer_id := p_farmer_id;
            v_stats.name := 'NOT_FOUND';
            v_stats.total_batches := 0;
            v_stats.approved_batches := 0;
            v_stats.approval_rate := 0;
            v_stats.performance_rating := 'NO_DATA';
            RETURN v_stats;
        WHEN OTHERS THEN
            RAISE;
    END get_farmer_performance;
    
    -- Function 3: Validate certification criteria
    FUNCTION validate_certification_criteria(
        p_batch_id IN NUMBER
    ) RETURN BOOLEAN
    IS
        v_nitrogen NUMBER;
        v_phosphorus NUMBER;
        v_potassium NUMBER;
        v_is_abnormal CHAR(1);
        v_passes BOOLEAN := TRUE;
    BEGIN
        -- Get nutrient data
        SELECT na.nitrogen_level, na.phosphorus_level, na.potassium_level, na.is_abnormal
        INTO v_nitrogen, v_phosphorus, v_potassium, v_is_abnormal
        FROM crop_batch cb
        JOIN soil_sample ss ON cb.batch_id = ss.batch_id
        JOIN nutrient_analysis na ON ss.sample_id = na.sample_id
        WHERE cb.batch_id = p_batch_id
        AND ROWNUM = 1;
        
        -- Check criteria
        IF v_is_abnormal = 'Y' THEN
            v_passes := FALSE;
            DBMS_OUTPUT.PUT_LINE('Failed: Abnormal nutrient reading');
        END IF;
        
        IF v_nitrogen < MIN_NITROGEN THEN
            v_passes := FALSE;
            DBMS_OUTPUT.PUT_LINE('Failed: Nitrogen below minimum (' || MIN_NITROGEN || '%)');
        END IF;
        
        IF v_phosphorus < MIN_PHOSPHORUS THEN
            v_passes := FALSE;
            DBMS_OUTPUT.PUT_LINE('Failed: Phosphorus below minimum (' || MIN_PHOSPHORUS || '%)');
        END IF;
        
        IF v_potassium < MIN_POTASSIUM THEN
            v_passes := FALSE;
            DBMS_OUTPUT.PUT_LINE('Failed: Potassium below minimum (' || MIN_POTASSIUM || '%)');
        END IF;
        
        RETURN v_passes;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN FALSE;
    END validate_certification_criteria;
    
    -- Procedure: Generate performance report
    PROCEDURE generate_performance_report(
        p_report OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_report FOR
            SELECT 
                f.farmer_id,
                f.name as farmer_name,
                COUNT(cb.batch_id) as total_batches,
                SUM(CASE WHEN c.cert_status = 'APPROVED' THEN 1 ELSE 0 END) as approved_batches,
                ROUND(
                    NVL(
                        SUM(CASE WHEN c.cert_status = 'APPROVED' THEN 1 ELSE 0 END) /
                        NULLIF(COUNT(cb.batch_id), 0) * 100, 
                    0), 2
                ) as approval_rate,
                RANK() OVER (ORDER BY 
                    NVL(
                        SUM(CASE WHEN c.cert_status = 'APPROVED' THEN 1 ELSE 0 END) /
                        NULLIF(COUNT(cb.batch_id), 0), 
                    0) DESC
                ) as performance_rank,
                ROUND(AVG(NVL(c.overall_score, 0)), 2) as avg_quality_score
            FROM farmer f
            LEFT JOIN crop_batch cb ON f.farmer_id = cb.farmer_id
            LEFT JOIN certification c ON cb.batch_id = c.batch_id
            GROUP BY f.farmer_id, f.name
            ORDER BY approval_rate DESC, total_batches DESC;
    END generate_performance_report;
    
END nutrition_pkg;
/

PROMPT ✓ Package created successfully
