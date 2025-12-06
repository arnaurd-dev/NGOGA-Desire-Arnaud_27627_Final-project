-- ============================================
-- PHASE VI: CURSORS AND WINDOW FUNCTIONS
-- ============================================

-- Example 1: Explicit Cursor for processing multiple farmers
CREATE OR REPLACE PROCEDURE update_farmer_status_batch
IS
    CURSOR farmer_cursor IS
        SELECT f.farmer_id, f.name,
               COUNT(cb.batch_id) as total_batches,
               SUM(CASE WHEN c.cert_status = 'APPROVED' THEN 1 ELSE 0 END) as approved_batches
        FROM farmer f
        LEFT JOIN crop_batch cb ON f.farmer_id = cb.farmer_id
        LEFT JOIN certification c ON cb.batch_id = c.batch_id
        GROUP BY f.farmer_id, f.name;
    
    v_farmer_rec farmer_cursor%ROWTYPE;
    v_performance VARCHAR2(20);
    v_processed_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting batch update of farmer status...');
    
    OPEN farmer_cursor;
    
    LOOP
        FETCH farmer_cursor INTO v_farmer_rec;
        EXIT WHEN farmer_cursor%NOTFOUND;
        
        -- Calculate performance
        IF v_farmer_rec.total_batches = 0 THEN
            v_performance := 'INACTIVE';
        ELSIF v_farmer_rec.approved_batches = 0 THEN
            v_performance := 'NEEDS_TRAINING';
        ELSIF (v_farmer_rec.approved_batches / v_farmer_rec.total_batches) >= 0.8 THEN
            v_performance := 'HIGH_PERFORMER';
        ELSE
            v_performance := 'ACTIVE';
        END IF;
        
        -- Could update a farmer status field here
        DBMS_OUTPUT.PUT_LINE('Farmer: ' || v_farmer_rec.name || 
                            ' | Batches: ' || v_farmer_rec.total_batches || 
                            ' | Approved: ' || v_farmer_rec.approved_batches ||
                            ' | Performance: ' || v_performance);
        
        v_processed_count := v_processed_count + 1;
        
        -- Commit every 10 records
        IF MOD(v_processed_count, 10) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    
    CLOSE farmer_cursor;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Batch update complete. Processed ' || v_processed_count || ' farmers.');
EXCEPTION
    WHEN OTHERS THEN
        IF farmer_cursor%ISOPEN THEN
            CLOSE farmer_cursor;
        END IF;
        ROLLBACK;
        RAISE;
END update_farmer_status_batch;
/

-- Example 2: Bulk operations with FORALL
CREATE OR REPLACE PROCEDURE update_nutrient_thresholds
IS
    TYPE nutrient_ids_t IS TABLE OF nutrient_analysis.analysis_id%TYPE;
    TYPE nutrient_values_t IS TABLE OF nutrient_analysis.nitrogen_level%TYPE;
    
    v_analysis_ids nutrient_ids_t;
    v_nitrogen_levels nutrient_values_t;
    v_update_count NUMBER := 0;
BEGIN
    -- Collect analyses with low nitrogen
    SELECT analysis_id, nitrogen_level
    BULK COLLECT INTO v_analysis_ids, v_nitrogen_levels
    FROM nutrient_analysis
    WHERE nitrogen_level < 2.0
    AND is_abnormal = 'N';
    
    -- Update using FORALL (bulk operation)
    FORALL i IN 1..v_analysis_ids.COUNT
        UPDATE nutrient_analysis
        SET is_abnormal = 'Y',
            abnormality_reason = 'Nitrogen deficiency (<2.0%)',
            analysis_status = 'VERIFIED'
        WHERE analysis_id = v_analysis_ids(i);
    
    v_update_count := SQL%ROWCOUNT;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Updated ' || v_update_count || ' records with nitrogen deficiency.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in bulk update: ' || SQLERRM);
        RAISE;
END update_nutrient_thresholds;
/

-- Example 3: Window Functions for analytics
CREATE OR REPLACE PROCEDURE generate_ranking_report
IS
    v_report SYS_REFCURSOR;
    v_farmer_id farmer.farmer_id%TYPE;
    v_farmer_name farmer.name%TYPE;
    v_total_batches NUMBER;
    v_approval_rate NUMBER;
    v_rank NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== FARMER RANKING REPORT ===');
    DBMS_OUTPUT.PUT_LINE(RPAD('Rank', 6) || RPAD('Farmer Name', 25) || 
                        RPAD('Total Batches', 15) || RPAD('Approval Rate', 15));
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
    
    OPEN v_report FOR
        SELECT 
            farmer_id,
            farmer_name,
            total_batches,
            approval_rate,
            RANK() OVER (ORDER BY approval_rate DESC, total_batches DESC) as farmer_rank
        FROM (
            SELECT 
                f.farmer_id,
                f.name as farmer_name,
                COUNT(cb.batch_id) as total_batches,
                ROUND(
                    NVL(
                        SUM(CASE WHEN c.cert_status = 'APPROVED' THEN 1 ELSE 0 END) /
                        NULLIF(COUNT(DISTINCT cb.batch_id), 0) * 100, 
                    0), 2
                ) as approval_rate
            FROM farmer f
            LEFT JOIN crop_batch cb ON f.farmer_id = cb.farmer_id
            LEFT JOIN certification c ON cb.batch_id = c.batch_id
            GROUP BY f.farmer_id, f.name
            HAVING COUNT(cb.batch_id) > 0
        );
    
    LOOP
        FETCH v_report INTO v_farmer_id, v_farmer_name, v_total_batches, v_approval_rate, v_rank;
        EXIT WHEN v_report%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_rank, 6) ||
            RPAD(v_farmer_name, 25) ||
            RPAD(v_total_batches, 15) ||
            RPAD(v_approval_rate || '%', 15)
        );
    END LOOP;
    
    CLOSE v_report;
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
END generate_ranking_report;
/

-- Example 4: Using LAG() for trend analysis
CREATE OR REPLACE PROCEDURE analyze_nutrient_trends
IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== NUTRIENT TREND ANALYSIS ===');
    DBMS_OUTPUT.PUT_LINE(RPAD('Crop Type', 15) || RPAD('Month', 10) || 
                        RPAD('Avg Nitrogen', 15) || RPAD('Prev Month', 15) || RPAD('Change %', 10));
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 65, '-'));
    
    FOR trend_rec IN (
        SELECT 
            crop_type,
            TO_CHAR(analysis_date, 'YYYY-MM') as analysis_month,
            ROUND(AVG(nitrogen_level), 2) as avg_nitrogen,
            ROUND(LAG(AVG(nitrogen_level), 1) OVER (
                PARTITION BY crop_type 
                ORDER BY TO_CHAR(analysis_date, 'YYYY-MM')
            ), 2) as prev_month_nitrogen,
            ROUND(
                ((AVG(nitrogen_level) - 
                  LAG(AVG(nitrogen_level), 1) OVER (
                    PARTITION BY crop_type 
                    ORDER BY TO_CHAR(analysis_date, 'YYYY-MM')
                  )) /
                 NULLIF(LAG(AVG(nitrogen_level), 1) OVER (
                    PARTITION BY crop_type 
                    ORDER BY TO_CHAR(analysis_date, 'YYYY-MM')
                 ), 0)) * 100, 
                2
            ) as percent_change
        FROM crop_batch cb
        JOIN soil_sample ss ON cb.batch_id = ss.batch_id
        JOIN nutrient_analysis na ON ss.sample_id = na.sample_id
        WHERE analysis_date >= ADD_MONTHS(SYSDATE, -6)
        GROUP BY crop_type, TO_CHAR(analysis_date, 'YYYY-MM')
        ORDER BY crop_type, analysis_month DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(trend_rec.crop_type, 15) ||
            RPAD(trend_rec.analysis_month, 10) ||
            RPAD(NVL(TO_CHAR(trend_rec.avg_nitrogen), 'N/A'), 15) ||
            RPAD(NVL(TO_CHAR(trend_rec.prev_month_nitrogen), 'N/A'), 15) ||
            RPAD(NVL(TO_CHAR(trend_rec.percent_change), 'N/A') || '%', 10)
        );
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 65, '-'));
END analyze_nutrient_trends;
/

PROMPT ✓ Cursors and Window Functions created successfully
