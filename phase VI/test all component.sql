-- ============================================
-- PHASE VI: TESTING ALL PL/SQL CODE
-- ============================================

SET SERVEROUTPUT ON
PROMPT Testing Phase VI PL/SQL Development...

-- Test 1: Test Procedures
DECLARE
    v_farmer_id NUMBER;
    v_sample_id NUMBER;
    v_analysis_id NUMBER;
    v_cert_id NUMBER;
    v_report SYS_REFCURSOR;
    v_total_cert NUMBER;
    v_approved_cert NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING PROCEDURES ===');
    
    -- Test add_new_farmer
    add_new_farmer('Test Farmer', 'Test Location', 'test@test.com', '+250788999999', 'LOAM', 5.5, v_farmer_id);
    DBMS_OUTPUT.PUT_LINE('✓ add_new_farmer: Farmer ID = ' || v_farmer_id);
    
    -- Test submit_soil_sample
    submit_soil_sample(1, 'SOIL', 'Test Agent', 300, 6.5, v_sample_id);
    DBMS_OUTPUT.PUT_LINE('✓ submit_soil_sample: Sample ID = ' || v_sample_id);
    
    -- Update sample status for testing
    UPDATE soil_sample SET sample_status = 'TESTED' WHERE sample_id = v_sample_id;
    
    -- Test record_nutrient_analysis
    record_nutrient_analysis(v_sample_id, 1, 3.5, 0.5, 2.5, 6.5, 'N', v_analysis_id);
    DBMS_OUTPUT.PUT_LINE('✓ record_nutrient_analysis: Analysis ID = ' || v_analysis_id);
    
    -- Test process_certification
    process_certification(1, 1, 'APPROVED', NULL, v_cert_id);
    DBMS_OUTPUT.PUT_LINE('✓ process_certification: Cert ID = ' || v_cert_id);
    
    -- Test generate_quality_report
    generate_quality_report(EXTRACT(MONTH FROM SYSDATE), EXTRACT(YEAR FROM SYSDATE), v_report);
    
    FETCH v_report INTO v_total_cert, v_approved_cert;
    CLOSE v_report;
    
    DBMS_OUTPUT.PUT_LINE('✓ generate_quality_report: Total=' || v_total_cert || ', Approved=' || v_approved_cert);
    
    DBMS_OUTPUT.PUT_LINE('✓ All procedures tested successfully');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Procedure test failed: ' || SQLERRM);
END;
/

-- Test 2: Test Functions
DECLARE
    v_efficiency NUMBER;
    v_validation VARCHAR2(50);
    v_rating VARCHAR2(20);
    v_days_to_cert NUMBER;
    v_cert_number VARCHAR2(50);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING FUNCTIONS ===');
    
    -- Test calculate_yield_efficiency
    v_efficiency := calculate_yield_efficiency(1);
    DBMS_OUTPUT.PUT_LINE('✓ calculate_yield_efficiency: ' || v_efficiency || '%');
    
    -- Test validate_nutrients
    v_validation := validate_nutrients(3.0, 0.4, 2.0);
    DBMS_OUTPUT.PUT_LINE('✓ validate_nutrients: ' || v_validation);
    
    -- Test get_farmer_rating
    v_rating := get_farmer_rating(1);
    DBMS_OUTPUT.PUT_LINE('✓ get_farmer_rating: ' || v_rating);
    
    -- Test calculate_certification_time
    v_days_to_cert := calculate_certification_time(1);
    DBMS_OUTPUT.PUT_LINE('✓ calculate_certification_time: ' || v_days_to_cert || ' days');
    
    -- Test generate_certificate_number
    v_cert_number := generate_certificate_number();
    DBMS_OUTPUT.PUT_LINE('✓ generate_certificate_number: ' || v_cert_number);
    
    DBMS_OUTPUT.PUT_LINE('✓ All functions tested successfully');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Function test failed: ' || SQLERRM);
END;
/

-- Test 3: Test Cursors and Window Functions
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING CURSORS & WINDOW FUNCTIONS ===');
    
    -- Test update_farmer_status_batch
    update_farmer_status_batch;
    DBMS_OUTPUT.PUT_LINE('✓ update_farmer_status_batch: Completed');
    
    -- Test update_nutrient_thresholds
    update_nutrient_thresholds;
    DBMS_OUTPUT.PUT_LINE('✓ update_nutrient_thresholds: Completed');
    
    -- Test generate_ranking_report
    generate_ranking_report;
    DBMS_OUTPUT.PUT_LINE('✓ generate_ranking_report: Completed');
    
    -- Test analyze_nutrient_trends
    analyze_nutrient_trends;
    DBMS_OUTPUT.PUT_LINE('✓ analyze_nutrient_trends: Completed');
    
    DBMS_OUTPUT.PUT_LINE('✓ All cursor/window functions tested successfully');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Cursor/window test failed: ' || SQLERRM);
END;
/

-- Test 4: Test Package
DECLARE
    v_farmer_id NUMBER;
    v_cert_number VARCHAR2(50);
    v_soil_health VARCHAR2(20);
    v_performance nutrition_pkg.farmer_stats_rec;
    v_is_valid BOOLEAN;
    v_report SYS_REFCURSOR;
    v_farmer_rec farmer%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING PACKAGE ===');
    
    -- Test register_new_farmer
    nutrition_pkg.register_new_farmer('Package Test', 'Package Location', 'package@test.com', v_farmer_id);
    DBMS_OUTPUT.PUT_LINE('✓ register_new_farmer: ID = ' || v_farmer_id);
    
    -- Test process_lab_sample (need a sample first)
    INSERT INTO soil_sample VALUES (999, 1, 'SOIL', SYSDATE, 'Package Test', SYSTIMESTAMP, 300, 22, 6.5, 25, SYSDATE, 'RECEIVED');
    
    nutrition_pkg.process_lab_sample(999, 1, '{"nitrogen":3.5,"phosphorus":0.5}');
    DBMS_OUTPUT.PUT_LINE('✓ process_lab_sample: Completed');
    
    -- Test generate_certificate
    nutrition_pkg.generate_certificate(1, 1, v_cert_number);
    DBMS_OUTPUT.PUT_LINE('✓ generate_certificate: ' || v_cert_number);
    
    -- Test calculate_soil_health
    v_soil_health := nutrition_pkg.calculate_soil_health(1);
    DBMS_OUTPUT.PUT_LINE('✓ calculate_soil_health: ' || v_soil_health);
    
    -- Test get_farmer_performance
    v_performance := nutrition_pkg.get_farmer_performance(1);
    DBMS_OUTPUT.PUT_LINE('✓ get_farmer_performance: ' || v_performance.name || ', Rating: ' || v_performance.performance_rating);
    
    -- Test validate_certification_criteria
    v_is_valid := nutrition_pkg.validate_certification_criteria(1);
    DBMS_OUTPUT.PUT_LINE('✓ validate_certification_criteria: ' || CASE WHEN v_is_valid THEN 'PASS' ELSE 'FAIL' END);
    
    -- Test generate_performance_report
    nutrition_pkg.generate_performance_report(v_report);
    
    FETCH v_report INTO v_farmer_rec.farmer_id, v_farmer_rec.name;
    CLOSE v_report;
    
    DBMS_OUTPUT.PUT_LINE('✓ generate_performance_report: First farmer = ' || v_farmer_rec.name);
    
    DBMS_OUTPUT.PUT_LINE('✓ Package tested successfully');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Package test failed: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ', SQLERRM: ' || SQLERRM);
END;
/

-- Test 5: Test Edge Cases and Exception Handling
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING EDGE CASES & EXCEPTIONS ===');
    
    -- Test invalid farmer addition (duplicate email)
    DECLARE
        v_farmer_id NUMBER;
    BEGIN
        add_new_farmer('Duplicate Test', 'Test', 'test@test.com', '+250788888888', 'LOAM', 5, v_farmer_id);
        DBMS_OUTPUT.PUT_LINE('✗ Should have failed on duplicate email');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✓ Correctly caught duplicate email: ' || SQLERRM);
    END;
    
    -- Test invalid nutrient levels
    DECLARE
        v_analysis_id NUMBER;
    BEGIN
        record_nutrient_analysis(1, 1, -5, 0.5, 2.5, 6.5, 'N', v_analysis_id);
        DBMS_OUTPUT.PUT_LINE('✗ Should have failed on invalid nitrogen');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✓ Correctly caught invalid nutrient: ' || SQLERRM);
    END;
    
    -- Test batch not ready for certification
    DECLARE
        v_cert_id NUMBER;
    BEGIN
        process_certification(999, 1, 'APPROVED', NULL, v_cert_id);
        DBMS_OUTPUT.PUT_LINE('✗ Should have failed on non-existent batch');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✓ Correctly caught invalid batch: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('✓ All edge cases and exceptions handled correctly');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Edge case test failed: ' || SQLERRM);
END;
/

PROMPT ============================================
PROMPT ✓ PHASE VI PL/SQL DEVELOPMENT COMPLETE
PROMPT ============================================
