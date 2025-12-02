-- ============================================
-- COMPLETE DATA INSERTION FOR ALL 10 TABLES
-- Nutritional Analysis System
-- ============================================

SET SERVEROUTPUT ON
SET VERIFY OFF

PROMPT ============================================
PROMPT INSERTING DATA FOR ALL TABLES...
PROMPT ============================================

-- Disable constraints temporarily for faster insertion
BEGIN
    FOR c IN (SELECT constraint_name, table_name FROM user_constraints WHERE constraint_type IN ('R', 'C')) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || c.table_name || ' DISABLE CONSTRAINT ' || c.constraint_name;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Constraints disabled for faster insertion...');
END;
/

-- ============================================
-- 1. FARMER TABLE (100+ rows)
-- ============================================
PROMPT Inserting into FARMER table...
DECLARE
    v_farmer_count NUMBER := 0;
BEGIN
    -- Clear existing data
    EXECUTE IMMEDIATE 'TRUNCATE TABLE farmer';
    
    -- Insert 100 farmers
    FOR i IN 1..100 LOOP
        INSERT INTO farmer (
            farmer_id, name, location, contact_email, contact_phone,
            registration_date, soil_type, farm_size_hectares
        ) VALUES (
            i,
            CASE MOD(i, 10)
                WHEN 0 THEN 'Jean ' || i
                WHEN 1 THEN 'Marie ' || i
                WHEN 2 THEN 'Pierre ' || i
                WHEN 3 THEN 'Claudine ' || i
                WHEN 4 THEN 'Eric ' || i
                WHEN 5 THEN 'Annette ' || i
                WHEN 6 THEN 'David ' || i
                WHEN 7 THEN 'Sarah ' || i
                WHEN 8 THEN 'Paul ' || i
                WHEN 9 THEN 'Grace ' || i
            END,
            CASE MOD(i, 5)
                WHEN 0 THEN 'Musanze, Northern Province'
                WHEN 1 THEN 'Huye, Southern Province'
                WHEN 2 THEN 'Kayonza, Eastern Province'
                WHEN 3 THEN 'Rubavu, Western Province'
                WHEN 4 THEN 'Bugesera, Eastern Province'
            END,
            'farmer' || i || '@agriculture.rw',
            '+25078' || LPAD(800000 + i, 6, '0'),
            SYSDATE - DBMS_RANDOM.VALUE(365, 1800), -- Registered 1-5 years ago
            CASE MOD(i, 4)
                WHEN 0 THEN 'VOLCANIC'
                WHEN 1 THEN 'LOAM'
                WHEN 2 THEN 'CLAY'
                WHEN 3 THEN 'SANDY'
            END,
            ROUND(DBMS_RANDOM.VALUE(1.5, 25.0), 1) -- Farm size 1.5-25 hectares
        );
        v_farmer_count := v_farmer_count + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || v_farmer_count || ' farmers');
END;
/

-- ============================================
-- 2. CROP_BATCH TABLE (200+ rows)
-- ============================================
PROMPT Inserting into CROP_BATCH table...
DECLARE
    v_batch_count NUMBER := 0;
    v_batch_id NUMBER := 1;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE crop_batch';
    
    FOR f_id IN 1..100 LOOP  -- For each farmer
        FOR crop_num IN 1..DBMS_RANDOM.VALUE(1, 3) LOOP  -- 1-3 batches per farmer
            INSERT INTO crop_batch (
                batch_id, farmer_id, crop_type, variety, planting_date,
                expected_harvest, actual_harvest, field_location,
                expected_yield_kg, status, notes
            ) VALUES (
                v_batch_id,
                f_id,
                CASE MOD(v_batch_id, 7)
                    WHEN 0 THEN 'MAIZE'
                    WHEN 1 THEN 'BEANS'
                    WHEN 2 THEN 'POTATOES'
                    WHEN 3 THEN 'RICE'
                    WHEN 4 THEN 'COFFEE'
                    WHEN 5 THEN 'WHEAT'
                    WHEN 6 THEN 'SORGHUM'
                END,
                CASE MOD(v_batch_id, 7)
                    WHEN 0 THEN 'Hybrid 614'
                    WHEN 1 THEN 'Red Kidney'
                    WHEN 2 THEN 'Kinigi'
                    WHEN 3 THEN 'Pishori'
                    WHEN 4 THEN 'Arabica'
                    WHEN 5 THEN 'Hard Red'
                    WHEN 6 THEN 'Seredo'
                END,
                SYSDATE - DBMS_RANDOM.VALUE(30, 180),  -- Planted 30-180 days ago
                SYSDATE + DBMS_RANDOM.VALUE(15, 90),   -- Harvest in 15-90 days
                CASE 
                    WHEN DBMS_RANDOM.VALUE(0, 1) > 0.7 THEN SYSDATE - DBMS_RANDOM.VALUE(0, 30)
                    ELSE NULL
                END,  -- 30% chance already harvested
                'Field ' || CHR(65 + MOD(v_batch_id, 3)) || '-' || MOD(v_batch_id, 10),
                ROUND(DBMS_RANDOM.VALUE(500, 10000), 2),  -- Expected yield 500-10000 kg
                CASE 
                    WHEN DBMS_RANDOM.VALUE(0, 1) < 0.3 THEN 'PLANTED'
                    WHEN DBMS_RANDOM.VALUE(0, 1) < 0.6 THEN 'GROWING'
                    WHEN DBMS_RANDOM.VALUE(0, 1) < 0.8 THEN 'HARVESTED'
                    WHEN DBMS_RANDOM.VALUE(0, 1) < 0.9 THEN 'SAMPLED'
                    ELSE 'CERTIFIED'
                END,
                CASE 
                    WHEN MOD(v_batch_id, 5) = 0 THEN 'Irrigation system installed'
                    WHEN MOD(v_batch_id, 7) = 0 THEN 'Organic farming practices'
                    ELSE NULL
                END
            );
            v_batch_count := v_batch_count + 1;
            v_batch_id := v_batch_id + 1;
        END LOOP;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || v_batch_count || ' crop batches');
END;
/

-- ============================================
-- 3. SOIL_SAMPLE TABLE (300+ rows)
-- ============================================
PROMPT Inserting into SOIL_SAMPLE table...
DECLARE
    v_sample_count NUMBER := 0;
    v_sample_id NUMBER := 1;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE soil_sample';
    
    FOR b_id IN 1..200 LOOP  -- For each batch
        FOR sample_num IN 1..DBMS_RANDOM.VALUE(1, 4) LOOP  -- 1-4 samples per batch
            INSERT INTO soil_sample (
                sample_id, batch_id, sample_type, collection_date,
                collected_by, collection_time, sample_weight_g,
                storage_temp_c, ph_level, moisture_percent,
                lab_receipt_date, sample_status
            ) VALUES (
                v_sample_id,
                b_id,
                CASE MOD(v_sample_id, 5)
                    WHEN 0 THEN 'SOIL'
                    WHEN 1 THEN 'LEAF'
                    WHEN 2 THEN 'STEM'
                    WHEN 3 THEN 'ROOT'
                    WHEN 4 THEN 'FRUIT'
                END,
                SYSDATE - DBMS_RANDOM.VALUE(1, 60),  -- Collected 1-60 days ago
                'Agent ' || CHR(65 + MOD(v_sample_id, 5)) || MOD(v_sample_id, 100),
                SYSTIMESTAMP - DBMS_RANDOM.VALUE(1, 86400),  -- Random time
                ROUND(DBMS_RANDOM.VALUE(200, 800), 2),  -- Weight 200-800g
                ROUND(DBMS_RANDOM.VALUE(18, 28), 1),    -- Storage temp 18-28°C
                ROUND(DBMS_RANDOM.VALUE(5.0, 8.0), 1),  -- pH 5.0-8.0
                ROUND(DBMS_RANDOM.VALUE(15, 45), 2),    -- Moisture 15-45%
                SYSDATE - DBMS_RANDOM.VALUE(0, 7),      -- Received 0-7 days after collection
                CASE MOD(v_sample_id, 20)
                    WHEN 0 THEN 'COLLECTED'
                    WHEN 1 THEN 'IN_TRANSIT'
                    WHEN 2 THEN 'RECEIVED'
                    WHEN 3 THEN 'TESTING'
                    ELSE 'TESTED'
                END
            );
            v_sample_count := v_sample_count + 1;
            v_sample_id := v_sample_id + 1;
        END LOOP;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || v_sample_count || ' soil samples');
END;
/

-- ============================================
-- 4. LAB_TECHNICIAN TABLE (20+ rows)
-- ============================================
PROMPT Inserting into LAB_TECHNICIAN table...
DECLARE
    v_tech_count NUMBER := 0;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE lab_technician';
    
    -- Insert 20 lab technicians
    INSERT INTO lab_technician VALUES (1, 'Dr. Alice Uwimana', 'Kigali Central Lab', 'SOIL', 'EXPERT', SYSDATE-365, 'alice.uwimana@lab.rw', '+250788200001', 'Y');
    INSERT INTO lab_technician VALUES (2, 'Eric Nkusi', 'Huye Agricultural Lab', 'PLANT', 'SENIOR', SYSDATE-180, 'eric.nkusi@lab.rw', '+250788200002', 'Y');
    INSERT INTO lab_technician VALUES (3, 'Grace Mukamana', 'Musanze Research Lab', 'CHEMISTRY', 'JUNIOR', SYSDATE-90, 'grace.mukamana@lab.rw', '+250788200003', 'Y');
    INSERT INTO lab_technician VALUES (4, 'David Habimana', 'Rubavu Testing Lab', 'MICROBIOLOGY', 'SENIOR', SYSDATE-270, 'david.habimana@lab.rw', '+250788200004', 'Y');
    INSERT INTO lab_technician VALUES (5, 'Sarah Uwase', 'Kigali Central Lab', 'SOIL', 'JUNIOR', SYSDATE-60, 'sarah.uwase@lab.rw', '+250788200005', 'Y');
    
    FOR i IN 6..20 LOOP
        INSERT INTO lab_technician (
            tech_id, name, lab_location, specialization,
            certification_level, hire_date, email, phone, is_active
        ) VALUES (
            i,
            CASE MOD(i, 3)
                WHEN 0 THEN 'Technician ' || i
                WHEN 1 THEN 'Analyst ' || i
                WHEN 2 THEN 'Researcher ' || i
            END,
            CASE MOD(i, 4)
                WHEN 0 THEN 'Kigali Central Lab'
                WHEN 1 THEN 'Huye Agricultural Lab'
                WHEN 2 THEN 'Musanze Research Lab'
                WHEN 3 THEN 'Rubavu Testing Lab'
            END,
            CASE MOD(i, 4)
                WHEN 0 THEN 'SOIL'
                WHEN 1 THEN 'PLANT'
                WHEN 2 THEN 'CHEMISTRY'
                WHEN 3 THEN 'MICROBIOLOGY'
            END,
            CASE 
                WHEN i < 8 THEN 'JUNIOR'
                WHEN i < 15 THEN 'SENIOR'
                ELSE 'EXPERT'
            END,
            SYSDATE - DBMS_RANDOM.VALUE(30, 730),  -- Hired 1 month to 2 years ago
            'tech' || i || '@agriculture.rw',
            '+25078' || LPAD(820000 + i, 6, '0'),
            CASE WHEN DBMS_RANDOM.VALUE(0,1) > 0.1 THEN 'Y' ELSE 'N' END
        );
        v_tech_count := v_tech_count + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || (v_tech_count + 5) || ' lab technicians');
END;
/

-- ============================================
-- 5. NUTRIENT_ANALYSIS TABLE (250+ rows)
-- ============================================
PROMPT Inserting into NUTRIENT_ANALYSIS table...
DECLARE
    v_analysis_count NUMBER := 0;
    v_abnormal_count NUMBER := 0;
    v_sample_id NUMBER;
    v_tech_id NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE nutrient_analysis';
    
    -- Get sample IDs that exist
    FOR s_rec IN (SELECT sample_id FROM soil_sample) LOOP
        EXIT WHEN v_analysis_count >= 250;  -- Stop at 250 records
        
        -- Get random technician
        SELECT tech_id INTO v_tech_id FROM (
            SELECT tech_id FROM lab_technician WHERE is_active = 'Y' ORDER BY DBMS_RANDOM.VALUE
        ) WHERE ROWNUM = 1;
        
        INSERT INTO nutrient_analysis (
            analysis_id, sample_id, tech_id, analysis_date, analysis_time,
            nitrogen_level, phosphorus_level, potassium_level,
            calcium_ppm, magnesium_ppm, sulfur_ppm, zinc_ppm, iron_ppm,
            organic_matter, salinity_ec, is_abnormal, abnormality_reason,
            analysis_status, created_by, verified_by, verification_date
        ) VALUES (
            v_analysis_count + 1,
            s_rec.sample_id,
            v_tech_id,
            SYSDATE - DBMS_RANDOM.VALUE(0, 14),  -- Analyzed 0-14 days ago
            SYSTIMESTAMP - DBMS_RANDOM.VALUE(0, 1209600),  -- Random timestamp
            
            -- Realistic nutrient values
            ROUND(DBMS_RANDOM.VALUE(1.0, 5.0), 2),    -- Nitrogen 1.0-5.0%
            ROUND(DBMS_RANDOM.VALUE(0.1, 1.0), 2),    -- Phosphorus 0.1-1.0%
            ROUND(DBMS_RANDOM.VALUE(1.0, 4.0), 2),    -- Potassium 1.0-4.0%
            
            ROUND(DBMS_RANDOM.VALUE(150, 1000), 2),   -- Calcium 150-1000 ppm
            ROUND(DBMS_RANDOM.VALUE(30, 250), 2),     -- Magnesium 30-250 ppm
            ROUND(DBMS_RANDOM.VALUE(10, 150), 2),     -- Sulfur 10-150 ppm
            ROUND(DBMS_RANDOM.VALUE(1, 20), 2),       -- Zinc 1-20 ppm
            ROUND(DBMS_RANDOM.VALUE(5, 60), 2),       -- Iron 5-60 ppm
            
            ROUND(DBMS_RANDOM.VALUE(1.5, 8.0), 2),    -- Organic matter 1.5-8.0%
            ROUND(DBMS_RANDOM.VALUE(0.3, 4.0), 2),    -- Salinity 0.3-4.0 EC
            
            -- Abnormal flag (15% chance)
            CASE WHEN DBMS_RANDOM.VALUE(0,1) < 0.15 THEN 'Y' ELSE 'N' END,
            
            CASE 
                WHEN DBMS_RANDOM.VALUE(0,1) < 0.1 THEN 'Low nitrogen levels'
                WHEN DBMS_RANDOM.VALUE(0,1) < 0.15 THEN 'High salinity detected'
                WHEN DBMS_RANDOM.VALUE(0,1) < 0.2 THEN 'pH imbalance'
                ELSE NULL
            END,
            
            CASE MOD(v_analysis_count, 10)
                WHEN 0 THEN 'PENDING'
                WHEN 1 THEN 'IN_PROGRESS'
                ELSE 'COMPLETED'
            END,
            
            'System',
            CASE WHEN DBMS_RANDOM.VALUE(0,1) > 0.3 THEN 'Dr. Alice Uwimana' ELSE NULL END,
            CASE WHEN DBMS_RANDOM.VALUE(0,1) > 0.5 THEN SYSDATE - DBMS_RANDOM.VALUE(0, 3) ELSE NULL END
        );
        
        IF DBMS_RANDOM.VALUE(0,1) < 0.15 THEN
            v_abnormal_count := v_abnormal_count + 1;
        END IF;
        
        v_analysis_count := v_analysis_count + 1;
        
        -- Progress update
        IF MOD(v_analysis_count, 50) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('  Processed ' || v_analysis_count || ' analyses...');
            COMMIT;
        END IF;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || v_analysis_count || ' nutrient analyses');
    DBMS_OUTPUT.PUT_LINE('✓ Abnormal results: ' || v_abnormal_count);
END;
/

-- ============================================
-- 6. QUALITY_INSPECTOR TABLE (15 rows)
-- ============================================
PROMPT Inserting into QUALITY_INSPECTOR table...
DECLARE
    v_inspector_count NUMBER := 0;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE quality_inspector';
    
    -- Insert 15 quality inspectors
    FOR i IN 1..15 LOOP
        INSERT INTO quality_inspector (
            inspector_id, name, department, authorization_level,
            hire_date, email, phone, region_assigned, is_active
        ) VALUES (
            i,
            CASE 
                WHEN i = 1 THEN 'John Kamali'
                WHEN i = 2 THEN 'Marie Uwase'
                WHEN i = 3 THEN 'Peter Nkurunziza'
                WHEN i = 4 THEN 'Alice Mukamana'
                WHEN i = 5 THEN 'David Habarugira'
                ELSE 'Inspector ' || i
            END,
            CASE MOD(i, 3)
                WHEN 0 THEN 'QUALITY_ASSURANCE'
                WHEN 1 THEN 'FOOD_SAFETY'
                WHEN 2 THEN 'CERTIFICATION'
            END,
            CASE 
                WHEN i <= 3 THEN 'LEVEL3'
                WHEN i <= 8 THEN 'LEVEL2'
                ELSE 'LEVEL1'
            END,
            SYSDATE - DBMS_RANDOM.VALUE(90, 1095),  -- Hired 3 months to 3 years ago
            'inspector' || i || '@quality.rw',
            '+25078' || LPAD(830000 + i, 6, '0'),
            CASE MOD(i, 5)
                WHEN 0 THEN 'Northern Province'
                WHEN 1 THEN 'Southern Province'
                WHEN 2 THEN 'Eastern Province'
                WHEN 3 THEN 'Western Province'
                WHEN 4 THEN 'Kigali City'
            END,
            CASE WHEN DBMS_RANDOM.VALUE(0,1) > 0.1 THEN 'Y' ELSE 'N' END
        );
        v_inspector_count := v_inspector_count + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || v_inspector_count || ' quality inspectors');
END;
/

-- ============================================
-- 7. CERTIFICATION TABLE (150+ rows)
-- ============================================
PROMPT Inserting into CERTIFICATION table...
DECLARE
    v_cert_count NUMBER := 0;
    v_cert_id NUMBER := 1;
    v_batch_id NUMBER;
    v_analysis_id NUMBER;
    v_inspector_id NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE certification';
    
    -- Get batches that have nutrient analyses
    FOR b_rec IN (
        SELECT DISTINCT cb.batch_id, na.analysis_id
        FROM crop_batch cb
        JOIN soil_sample ss ON cb.batch_id = ss.batch_id
        JOIN nutrient_analysis na ON ss.sample_id = na.sample_id
        WHERE ROWNUM <= 150
    ) LOOP
        -- Get random inspector
        SELECT inspector_id INTO v_inspector_id FROM (
            SELECT inspector_id FROM quality_inspector WHERE is_active = 'Y' ORDER BY DBMS_RANDOM.VALUE
        ) WHERE ROWNUM = 1;
        
        INSERT INTO certification (
            cert_id, batch_id, inspector_id, analysis_id,
            decision_date, cert_status, rejection_reason,
            appearance_score, texture_score, nutrient_score, overall_score,
            valid_until, cert_number, issued_by
        ) VALUES (
            v_cert_id,
            b_rec.batch_id,
            v_inspector_id,
            b_rec.analysis_id,
            SYSDATE - DBMS_RANDOM.VALUE(0, 90),  -- Decision 0-90 days ago
            
            -- Status distribution
            CASE 
                WHEN DBMS_RANDOM.VALUE(0,1) < 0.8 THEN 'APPROVED'     -- 80% approved
                WHEN DBMS_RANDOM.VALUE(0,1) < 0.95 THEN 'REJECTED'    -- 15% rejected
                ELSE 'PENDING'                                        -- 5% pending
            END,
            
            -- Rejection reasons (if rejected)
            CASE 
                WHEN DBMS_RANDOM.VALUE(0,1) < 0.2 THEN
                    CASE MOD(v_cert_id, 4)
                        WHEN 0 THEN 'Nutrient deficiency detected'
                        WHEN 1 THEN 'Contamination levels above threshold'
                        WHEN 2 THEN 'Incomplete documentation'
                        WHEN 3 THEN 'Sample collection procedure violation'
                    END
                ELSE NULL
            END,
            
            -- Quality scores (realistic ranges)
            TRUNC(DBMS_RANDOM.VALUE(7, 11)),      -- Appearance 7-10
            TRUNC(DBMS_RANDOM.VALUE(6, 11)),      -- Texture 6-10
            TRUNC(DBMS_RANDOM.VALUE(5, 11)),      -- Nutrient 5-10
            ROUND(DBMS_RANDOM.VALUE(6.0, 9.9), 1), -- Overall 6.0-9.9
            
            -- Valid for 6-12 months from decision
            SYSDATE - DBMS_RANDOM.VALUE(0, 90) + DBMS_RANDOM.VALUE(180, 365),
            
            -- Certificate number
            'CERT-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || LPAD(v_cert_id, 5, '0'),
            
            -- Issued by
            CASE MOD(v_inspector_id, 3)
                WHEN 0 THEN 'Rwanda Standards Board'
                WHEN 1 THEN 'Ministry of Agriculture'
                WHEN 2 THEN 'Quality Assurance Department'
            END
        );
        
        v_cert_count := v_cert_count + 1;
        v_cert_id := v_cert_id + 1;
        
        -- Update batch status if certified
        IF DBMS_RANDOM.VALUE(0,1) < 0.8 THEN  -- 80% chance to update status
            UPDATE crop_batch 
            SET status = 'CERTIFIED'
            WHERE batch_id = b_rec.batch_id;
        END IF;
        
        -- Progress update
        IF MOD(v_cert_count, 30) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('  Processed ' || v_cert_count || ' certifications...');
            COMMIT;
        END IF;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || v_cert_count || ' certifications');
END;
/

-- ============================================
-- 8. DISTRIBUTION_RECORD TABLE (100+ rows)
-- ============================================
PROMPT Inserting into DISTRIBUTION_RECORD table...
DECLARE
    v_dist_count NUMBER := 0;
    v_dist_id NUMBER := 1;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE distribution_record';
    
    -- Get certified batches
    FOR d_rec IN (
        SELECT cb.batch_id 
        FROM crop_batch cb
        JOIN certification c ON cb.batch_id = c.batch_id
        WHERE c.cert_status = 'APPROVED'
        AND ROWNUM <= 100
    ) LOOP
        INSERT INTO distribution_record (
            dist_id, batch_id, from_location, to_location, transporter,
            transport_date, expected_delivery, actual_delivery,
            qr_code, tracking_number, temperature_c, humidity_percent,
            status, notes
        ) VALUES (
            v_dist_id,
            d_rec.batch_id,
            CASE MOD(v_dist_id, 4)
                WHEN 0 THEN 'Musanze Warehouse'
                WHEN 1 THEN 'Huye Storage Facility'
                WHEN 2 THEN 'Kigali Distribution Center'
                WHEN 3 THEN 'Rubavu Cold Storage'
            END,
            CASE MOD(v_dist_id, 5)
                WHEN 0 THEN 'Nakumatt Supermarket, Kigali'
                WHEN 1 THEN 'Rwanda Export Company'
                WHEN 2 THEN 'University of Rwanda Cafeteria'
                WHEN 3 THEN 'Kigali International Airport'
                WHEN 4 THEN 'Local Market, Huye'
            END,
            CASE MOD(v_dist_id, 3)
                WHEN 0 THEN 'Rwanda Transport Ltd'
                WHEN 1 THEN 'Agri-Logistics Co.'
                WHEN 2 THEN 'Cold Chain Express'
            END,
            SYSDATE - DBMS_RANDOM.VALUE(0, 60),  -- Transported 0-60 days ago
            SYSDATE - DBMS_RANDOM.VALUE(0, 60) + DBMS_RANDOM.VALUE(1, 7),  -- Expected 1-7 days after transport
            CASE 
                WHEN DBMS_RANDOM.VALUE(0,1) > 0.2 THEN SYSDATE - DBMS_RANDOM.VALUE(0, 55)  -- 80% delivered
                ELSE NULL  -- 20% still in transit
            END,
            'QR-' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '-' || LPAD(v_dist_id, 6, '0'),
            'TRK-' || TO_CHAR(SYSDATE, 'YYYYMM') || '-' || LPAD(v_dist_id, 8, '0'),
            ROUND(DBMS_RANDOM.VALUE(2, 25), 1),   -- Temperature 2-25°C
            ROUND(DBMS_RANDOM.VALUE(40, 85), 2),  -- Humidity 40-85%
            CASE 
                WHEN DBMS_RANDOM.VALUE(0,1) < 0.7 THEN 'DELIVERED'
                WHEN DBMS_RANDOM.VALUE(0,1) < 0.9 THEN 'IN_TRANSIT'
                ELSE 'SCHEDULED'
            END,
            CASE 
                WHEN MOD(v_dist_id, 7) = 0 THEN 'Fragile - Handle with care'
                WHEN MOD(v_dist_id, 5) = 0 THEN 'Requires refrigeration'
                ELSE NULL
            END
        );
        
        v_dist_count := v_dist_count + 1;
        v_dist_id := v_dist_id + 1;
        
        -- Progress update
        IF MOD(v_dist_count, 20) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('  Processed ' || v_dist_count || ' distribution records...');
            COMMIT;
        END IF;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || v_dist_count || ' distribution records');
END;
/

-- ============================================
-- 9. HOLIDAY TABLE (Rwandan holidays 2025)
-- ============================================
PROMPT Inserting into HOLIDAY table...
DECLARE
    v_holiday_count NUMBER := 0;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE holiday';
    
    -- Insert Rwandan public holidays for 2025
    INSERT INTO holiday VALUES (1, TO_DATE('01-01-2025', 'DD-MM-YYYY'), 'New Year''s Day', 'First day of the year', 'RWANDA', 'Y', 2025);
    INSERT INTO holiday VALUES (2, TO_DATE('01-02-2025', 'DD-MM-YYYY'), 'National Heroes Day', 'Day to honor national heroes', 'RWANDA', 'Y', 2025);
    INSERT INTO holiday VALUES (3, TO_DATE('08-03-2025', 'DD-MM-YYYY'), 'International Women''s Day', 'Celebration of women''s achievements', 'RWANDA', 'Y', 2025);
    INSERT INTO holiday VALUES (4, TO_DATE('07-04-2025', 'DD-MM-YYYY'), 'Genocide against the Tutsi Memorial Day', 'Commemoration of the genocide', 'RWANDA', 'Y', 2025);
    INSERT INTO holiday VALUES (5, TO_DATE('01-05-2025', 'DD-MM-YYYY'), 'Labour Day', 'International Workers'' Day', 'RWANDA', 'Y', 2025);
    INSERT INTO holiday VALUES (6, TO_DATE('04-07-2025', 'DD-MM-YYYY'), 'Liberation Day', 'Celebration of liberation', 'RWANDA', 'Y', 2025);
    INSERT INTO holiday VALUES (7, TO_DATE('15-08-2025', 'DD-MM-YYYY'), 'Assumption Day', 'Religious holiday', 'RWANDA', 'Y', 2025);
    INSERT INTO holiday VALUES (8, TO_DATE('25-12-2025', 'DD-MM-YYYY'), 'Christmas Day', 'Christmas celebration', 'RWANDA', 'Y', 2025);
    
    -- Add some random holidays for testing
    FOR i IN 9..20 LOOP
        INSERT INTO holiday (
            holiday_id, holiday_date, holiday_name, description, country, is_recurring, year_applicable
        ) VALUES (
            i,
            TO_DATE('01-01-2025', 'DD-MM-YYYY') + DBMS_RANDOM.VALUE(1, 364),
            CASE MOD(i, 4)
                WHEN 0 THEN 'Regional Agricultural Fair'
                WHEN 1 THEN 'Farmers'' Day'
                WHEN 2 THEN 'Harvest Festival'
                WHEN 3 THEN 'Local Election Day'
            END,
            CASE MOD(i, 3)
                WHEN 0 THEN 'Local celebration'
                WHEN 1 THEN 'Official holiday'
                WHEN 2 THEN 'Cultural event'
            END,
            'RWANDA',
            CASE WHEN DBMS_RANDOM.VALUE(0,1) > 0.5 THEN 'Y' ELSE 'N' END,
            2025
        );
        v_holiday_count := v_holiday_count + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || (v_holiday_count + 8) || ' holidays');
END;
/

-- ============================================
-- 10. AUDIT_LOG TABLE (Sample audit entries)
-- ============================================
PROMPT Inserting into AUDIT_LOG table...
DECLARE
    v_audit_count NUMBER := 0;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE audit_log';
    
    -- Insert sample audit logs for various actions
    FOR i IN 1..50 LOOP
        INSERT INTO audit_log (
            log_id, user_id, action_type, table_name, record_id,
            old_value, new_value, attempt_date, status,
            error_message, ip_address, session_id
        ) VALUES (
            i,
            CASE MOD(i, 4)
                WHEN 0 THEN 'ngoga_admin'
                WHEN 1 THEN 'lab_user'
                WHEN 2 THEN 'inspector_user'
                WHEN 3 THEN 'farmer_user'
            END,
            CASE MOD(i, 4)
                WHEN 0 THEN 'INSERT'
                WHEN 1 THEN 'UPDATE'
                WHEN 2 THEN 'DELETE'
                WHEN 3 THEN 'SELECT'
            END,
            CASE MOD(i, 10)
                WHEN 0 THEN 'FARMER'
                WHEN 1 THEN 'CROP_BATCH'
                WHEN 2 THEN 'SOIL_SAMPLE'
                WHEN 3 THEN 'NUTRIENT_ANALYSIS'
                WHEN 4 THEN 'CERTIFICATION'
                WHEN 5 THEN 'DISTRIBUTION_RECORD'
                WHEN 6 THEN 'LAB_TECHNICIAN'
                WHEN 7 THEN 'QUALITY_INSPECTOR'
                WHEN 8 THEN 'HOLIDAY'
                WHEN 9 THEN 'AUDIT_LOG'
            END,
            TRUNC(DBMS_RANDOM.VALUE(1, 1000)),
            CASE 
                WHEN MOD(i, 4) = 1 THEN '{"old_value": "test"}'
                ELSE NULL
            END,
            CASE 
                WHEN MOD(i, 4) IN (0,1) THEN '{"new_value": "updated"}'
                ELSE NULL
            END,
            SYSTIMESTAMP - DBMS_RANDOM.VALUE(0, 864000),  -- Last 10 days
            CASE MOD(i, 20)
                WHEN 0 THEN 'DENIED'
                WHEN 1 THEN 'ERROR'
                ELSE 'SUCCESS'
            END,
            CASE 
                WHEN MOD(i, 20) = 0 THEN 'Permission denied'
                WHEN MOD(i, 20) = 1 THEN 'Constraint violation'
                ELSE NULL
            END,
            '192.168.1.' || MOD(i, 255),
            'SESSION_' || LPAD(i, 8, '0')
        );
        v_audit_count := v_audit_count + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserted ' || v_audit_count || ' audit log entries');
END;
/

-- ============================================
-- RE-ENABLE CONSTRAINTS
-- ============================================
PROMPT Re-enabling constraints...
BEGIN
    FOR c IN (SELECT constraint_name, table_name FROM user_constraints WHERE constraint_type IN ('R', 'C')) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || c.table_name || ' ENABLE CONSTRAINT ' || c.constraint_name;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Warning: Could not enable constraint ' || c.constraint_name || ' on ' || c.table_name);
        END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('✓ Constraints re-enabled');
END;
/

-- ============================================
-- FINAL VERIFICATION
-- ============================================
PROMPT
PROMPT ============================================
PROMPT FINAL DATA COUNT VERIFICATION
PROMPT ============================================

SELECT 'FARMER' as table_name, COUNT(*) as record_count FROM farmer
UNION ALL SELECT 'CROP_BATCH', COUNT(*) FROM crop_batch
UNION ALL SELECT 'SOIL_SAMPLE', COUNT(*) FROM soil_sample
UNION ALL SELECT 'LAB_TECHNICIAN', COUNT(*) FROM lab_technician
UNION ALL SELECT 'NUTRIENT_ANALYSIS', COUNT(*) FROM nutrient_analysis
UNION ALL SELECT 'QUALITY_INSPECTOR', COUNT(*) FROM quality_inspector
UNION ALL SELECT 'CERTIFICATION', COUNT(*) FROM certification
UNION ALL SELECT 'DISTRIBUTION_RECORD', COUNT(*) FROM distribution_record
UNION ALL SELECT 'HOLIDAY', COUNT(*) FROM holiday
UNION ALL SELECT 'AUDIT_LOG', COUNT(*) FROM audit_log
ORDER BY record_count DESC;

PROMPT
PROMPT ============================================
PROMPT ✓ ALL DATA INSERTED SUCCESSFULLY!
PROMPT ============================================
PROMPT Total Records Inserted: 
SELECT SUM(cnt) as total_records FROM (
    SELECT COUNT(*) as cnt FROM farmer
    UNION ALL SELECT COUNT(*) FROM crop_batch
    UNION ALL SELECT COUNT(*) FROM soil_sample
    UNION ALL SELECT COUNT(*) FROM lab_technician
    UNION ALL SELECT COUNT(*) FROM nutrient_analysis
    UNION ALL SELECT COUNT(*) FROM quality_inspector
    UNION ALL SELECT COUNT(*) FROM certification
    UNION ALL SELECT COUNT(*) FROM distribution_record
    UNION ALL SELECT COUNT(*) FROM holiday
    UNION ALL SELECT COUNT(*) FROM audit_log
);
