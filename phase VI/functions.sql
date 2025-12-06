-- ============================================
-- PHASE VI: FUNCTIONS (5 Functions)
-- ============================================

-- Function 1: Calculate crop yield efficiency
CREATE OR REPLACE FUNCTION calculate_yield_efficiency (
    p_batch_id IN NUMBER
) RETURN NUMBER
IS
    v_expected_yield NUMBER;
    v_actual_yield NUMBER;
    v_efficiency NUMBER;
BEGIN
    -- Get expected yield
    SELECT expected_yield_kg INTO v_expected_yield
    FROM crop_batch
    WHERE batch_id = p_batch_id;
    
    -- For simplicity, assume actual yield is 80-120% of expected
    -- In real system, this would come from harvest data
    v_actual_yield := v_expected_yield * DBMS_RANDOM.VALUE(0.8, 1.2);
    
    -- Calculate efficiency percentage
    v_efficiency := ROUND((v_actual_yield / v_expected_yield) * 100, 2);
    
    RETURN v_efficiency;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN -1;  -- Error indicator
END calculate_yield_efficiency;
/

-- Function 2: Validate nutrient levels against standards
CREATE OR REPLACE FUNCTION validate_nutrients (
    p_nitrogen IN NUMBER,
    p_phosphorus IN NUMBER,
    p_potassium IN NUMBER
) RETURN VARCHAR2
IS
    v_status VARCHAR2(50);
BEGIN
    IF p_nitrogen IS NULL OR p_phosphorus IS NULL OR p_potassium IS NULL THEN
        RETURN 'INCOMPLETE_DATA';
    END IF;
    
    -- Rwanda agricultural standards (example values)
    IF p_nitrogen >= 2.5 AND p_phosphorus >= 0.3 AND p_potassium >= 1.8 THEN
        v_status := 'OPTIMAL';
    ELSIF p_nitrogen >= 1.8 AND p_phosphorus >= 0.2 AND p_potassium >= 1.2 THEN
        v_status := 'ADEQUATE';
    ELSIF p_nitrogen < 1.0 OR p_phosphorus < 0.1 OR p_potassium < 0.8 THEN
        v_status := 'CRITICAL_DEFICIENCY';
    ELSE
        v_status := 'DEFICIENT';
    END IF;
    
    RETURN v_status;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'VALIDATION_ERROR';
END validate_nutrients;
/

-- Function 3: Get farmer performance rating
CREATE OR REPLACE FUNCTION get_farmer_rating (
    p_farmer_id IN NUMBER
) RETURN VARCHAR2
IS
    v_total_batches NUMBER;
    v_approved_batches NUMBER;
    v_avg_score NUMBER;
    v_rating VARCHAR2(20);
BEGIN
    -- Count total batches
    SELECT COUNT(*) INTO v_total_batches
    FROM crop_batch
    WHERE farmer_id = p_farmer_id;
    
    IF v_total_batches = 0 THEN
        RETURN 'NO_DATA';
    END IF;
    
    -- Count approved certifications
    SELECT COUNT(DISTINCT cb.batch_id) INTO v_approved_batches
    FROM crop_batch cb
    JOIN certification c ON cb.batch_id = c.batch_id
    WHERE cb.farmer_id = p_farmer_id
    AND c.cert_status = 'APPROVED';
    
    -- Calculate average score
    SELECT ROUND(AVG(c.overall_score), 2) INTO v_avg_score
    FROM crop_batch cb
    JOIN certification c ON cb.batch_id = c.batch_id
    WHERE cb.farmer_id = p_farmer_id
    AND c.cert_status = 'APPROVED';
    
    -- Determine rating
    IF v_approved_batches = 0 THEN
        v_rating := 'NEEDS_IMPROVEMENT';
    ELSIF (v_approved_batches / v_total_batches) >= 0.9 AND v_avg_score >= 8.5 THEN
        v_rating := 'EXCELLENT';
    ELSIF (v_approved_batches / v_total_batches) >= 0.7 AND v_avg_score >= 7.0 THEN
        v_rating := 'GOOD';
    ELSIF (v_approved_batches / v_total_batches) >= 0.5 THEN
        v_rating := 'FAIR';
    ELSE
        v_rating := 'POOR';
    END IF;
    
    RETURN v_rating;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'RATING_ERROR';
END get_farmer_rating;
/

-- Function 4: Calculate days to certification
CREATE OR REPLACE FUNCTION calculate_certification_time (
    p_batch_id IN NUMBER
) RETURN NUMBER
IS
    v_planting_date DATE;
    v_certification_date DATE;
    v_days_to_cert NUMBER;
BEGIN
    -- Get planting date
    SELECT planting_date INTO v_planting_date
    FROM crop_batch
    WHERE batch_id = p_batch_id;
    
    -- Get certification date
    SELECT MIN(decision_date) INTO v_certification_date
    FROM certification
    WHERE batch_id = p_batch_id
    AND cert_status = 'APPROVED';
    
    IF v_certification_date IS NULL THEN
        RETURN NULL;  -- Not certified yet
    END IF;
    
    -- Calculate days
    v_days_to_cert := v_certification_date - v_planting_date;
    
    RETURN v_days_to_cert;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN -1;
END calculate_certification_time;
/

-- Function 5: Generate next certificate number
CREATE OR REPLACE FUNCTION generate_certificate_number 
RETURN VARCHAR2
IS
    v_next_number NUMBER;
    v_cert_number VARCHAR2(50);
BEGIN
    -- Get next sequence value
    SELECT certification_seq.NEXTVAL INTO v_next_number FROM dual;
    
    -- Format: CERT-YYYYMM-XXXXX
    v_cert_number := 'CERT-' || 
                    TO_CHAR(SYSDATE, 'YYYYMM') || '-' || 
                    LPAD(v_next_number, 5, '0');
    
    RETURN v_cert_number;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'CERT-ERROR-' || TO_CHAR(SYSDATE, 'YYYYMMDD');
END generate_certificate_number;
/

PROMPT ✓ 5 Functions created successfully
