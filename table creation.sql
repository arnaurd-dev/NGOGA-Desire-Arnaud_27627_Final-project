-- ============================================
-- PHASE V: Table Creation Script
-- Nutritional Analysis System
-- Student: Ngoga, ID: 27627
-- ============================================

SET SERVEROUTPUT ON
PROMPT Creating tables for Nutritional Analysis System...

-- 1. FARMER TABLE
PROMPT Creating FARMER table...
CREATE TABLE farmer (
    farmer_id          NUMBER(10)     CONSTRAINT farmer_pk PRIMARY KEY,
    name               VARCHAR2(100)  CONSTRAINT farmer_name_nn NOT NULL,
    location           VARCHAR2(200)  CONSTRAINT farmer_loc_nn NOT NULL,
    contact_email      VARCHAR2(100)  CONSTRAINT farmer_email_nn NOT NULL,
    contact_phone      VARCHAR2(20),
    registration_date  DATE           DEFAULT SYSDATE,
    soil_type          VARCHAR2(50)   CONSTRAINT farmer_soil_ck 
                                      CHECK (soil_type IN ('CLAY', 'LOAM', 'SANDY', 'VOLCANIC')),
    farm_size_hectares NUMBER(6,2),
    CONSTRAINT farmer_email_uq UNIQUE (contact_email),
    CONSTRAINT farmer_phone_uq UNIQUE (contact_phone)
) TABLESPACE nutrition_data;

-- 2. CROP_BATCH TABLE
PROMPT Creating CROP_BATCH table...
CREATE TABLE crop_batch (
    batch_id          NUMBER(10)     CONSTRAINT crop_batch_pk PRIMARY KEY,
    farmer_id         NUMBER(10)     CONSTRAINT crop_batch_farmer_fk 
                                     REFERENCES farmer(farmer_id) ON DELETE CASCADE,
    crop_type         VARCHAR2(50)   CONSTRAINT crop_type_nn NOT NULL
                                     CHECK (crop_type IN ('MAIZE', 'BEANS', 'POTATOES', 'RICE', 'COFFEE', 'WHEAT', 'SORGHUM')),
    variety           VARCHAR2(50),
    planting_date     DATE           CONSTRAINT planting_date_nn NOT NULL,
    expected_harvest  DATE,
    actual_harvest    DATE,
    field_location    VARCHAR2(200),
    expected_yield_kg NUMBER(8,2)    CHECK (expected_yield_kg > 0),
    status            VARCHAR2(20)   DEFAULT 'PLANTED'
                                     CHECK (status IN ('PLANTED', 'GROWING', 'HARVESTED', 'SAMPLED', 'TESTED', 'CERTIFIED', 'REJECTED')),
    notes             VARCHAR2(500),
    CONSTRAINT harvest_date_ck CHECK (actual_harvest IS NULL OR actual_harvest >= planting_date)
) TABLESPACE nutrition_data;

-- 3. SOIL_SAMPLE TABLE
PROMPT Creating SOIL_SAMPLE table...
CREATE TABLE soil_sample (
    sample_id        NUMBER(10)     CONSTRAINT soil_sample_pk PRIMARY KEY,
    batch_id         NUMBER(10)     CONSTRAINT soil_sample_batch_fk 
                                   REFERENCES crop_batch(batch_id) ON DELETE CASCADE,
    sample_type      VARCHAR2(20)   DEFAULT 'SOIL'
                                   CHECK (sample_type IN ('SOIL', 'LEAF', 'STEM', 'ROOT', 'FRUIT')),
    collection_date  DATE           DEFAULT SYSDATE,
    collected_by     VARCHAR2(100)  CONSTRAINT collected_by_nn NOT NULL,
    collection_time  TIMESTAMP,
    sample_weight_g  NUMBER(6,2)    CHECK (sample_weight_g BETWEEN 100 AND 1000),
    storage_temp_c   NUMBER(4,1),
    ph_level         NUMBER(3,1)    CHECK (ph_level BETWEEN 0.0 AND 14.0),
    moisture_percent NUMBER(5,2)    CHECK (moisture_percent BETWEEN 0 AND 100),
    lab_receipt_date DATE,
    sample_status    VARCHAR2(20)   DEFAULT 'COLLECTED'
                                   CHECK (sample_status IN ('COLLECTED', 'IN_TRANSIT', 'RECEIVED', 'TESTING', 'TESTED')),
    CONSTRAINT sample_date_ck CHECK (collection_date <= lab_receipt_date OR lab_receipt_date IS NULL)
) TABLESPACE nutrition_data;

-- 4. LAB_TECHNICIAN TABLE
PROMPT Creating LAB_TECHNICIAN table...
CREATE TABLE lab_technician (
    tech_id            NUMBER(10)     CONSTRAINT lab_tech_pk PRIMARY KEY,
    name               VARCHAR2(100)  CONSTRAINT tech_name_nn NOT NULL,
    lab_location       VARCHAR2(100)  CONSTRAINT lab_loc_nn NOT NULL,
    specialization     VARCHAR2(50)   CHECK (specialization IN ('SOIL', 'PLANT', 'MICROBIOLOGY', 'CHEMISTRY')),
    certification_level VARCHAR2(20)  DEFAULT 'JUNIOR'
                                     CHECK (certification_level IN ('JUNIOR', 'SENIOR', 'EXPERT')),
    hire_date          DATE           DEFAULT SYSDATE,
    email              VARCHAR2(100)  CONSTRAINT tech_email_uq UNIQUE,
    phone              VARCHAR2(20),
    is_active          CHAR(1)        DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
) TABLESPACE nutrition_data;

-- 5. NUTRIENT_ANALYSIS TABLE (CRITICAL FOR PHASE VII)
PROMPT Creating NUTRIENT_ANALYSIS table...
CREATE TABLE nutrient_analysis (
    analysis_id       NUMBER(10)     CONSTRAINT nutrient_analysis_pk PRIMARY KEY,
    sample_id         NUMBER(10)     CONSTRAINT nutrient_sample_fk 
                                    REFERENCES soil_sample(sample_id) ON DELETE CASCADE,
    tech_id           NUMBER(10)     CONSTRAINT nutrient_tech_fk 
                                    REFERENCES lab_technician(tech_id),
    analysis_date     DATE           DEFAULT SYSDATE,
    analysis_time     TIMESTAMP,
    
    -- Macronutrients (%)
    nitrogen_level    NUMBER(5,2)    CHECK (nitrogen_level BETWEEN 0 AND 100),
    phosphorus_level  NUMBER(5,2)    CHECK (phosphorus_level BETWEEN 0 AND 100),
    potassium_level   NUMBER(5,2)    CHECK (potassium_level BETWEEN 0 AND 100),
    
    -- Micronutrients (ppm)
    calcium_ppm       NUMBER(6,2),
    magnesium_ppm     NUMBER(6,2),
    sulfur_ppm        NUMBER(6,2),
    zinc_ppm          NUMBER(6,2),
    iron_ppm          NUMBER(6,2),
    
    -- Other measurements
    organic_matter    NUMBER(5,2)    CHECK (organic_matter BETWEEN 0 AND 100),
    salinity_ec       NUMBER(6,2),  -- Electrical conductivity
    
    -- Quality flags
    is_abnormal       CHAR(1)        DEFAULT 'N' CHECK (is_abnormal IN ('Y', 'N')),
    abnormality_reason VARCHAR2(200),
    analysis_status   VARCHAR2(20)   DEFAULT 'PENDING'
                                    CHECK (analysis_status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'VERIFIED')),
    
    -- Audit fields
    created_by        VARCHAR2(50),
    verified_by       VARCHAR2(50),
    verification_date DATE,
    
    CONSTRAINT analysis_date_ck CHECK (analysis_date >= (SELECT collection_date FROM soil_sample WHERE sample_id = nutrient_analysis.sample_id))
) TABLESPACE nutrition_data;

-- 6. QUALITY_INSPECTOR TABLE
PROMPT Creating QUALITY_INSPECTOR table...
CREATE TABLE quality_inspector (
    inspector_id       NUMBER(10)     CONSTRAINT inspector_pk PRIMARY KEY,
    name               VARCHAR2(100)  CONSTRAINT inspector_name_nn NOT NULL,
    department         VARCHAR2(50)   DEFAULT 'QUALITY_ASSURANCE',
    authorization_level VARCHAR2(20)  DEFAULT 'LEVEL1'
                                     CHECK (authorization_level IN ('LEVEL1', 'LEVEL2', 'LEVEL3')),
    hire_date          DATE           DEFAULT SYSDATE,
    email              VARCHAR2(100)  CONSTRAINT inspector_email_uq UNIQUE,
    phone              VARCHAR2(20),
    region_assigned    VARCHAR2(100),
    is_active          CHAR(1)        DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
) TABLESPACE nutrition_data;

-- 7. CERTIFICATION TABLE
PROMPT Creating CERTIFICATION table...
CREATE TABLE certification (
    cert_id           NUMBER(10)     CONSTRAINT certification_pk PRIMARY KEY,
    batch_id          NUMBER(10)     CONSTRAINT cert_batch_fk REFERENCES crop_batch(batch_id),
    inspector_id      NUMBER(10)     CONSTRAINT cert_inspector_fk REFERENCES quality_inspector(inspector_id),
    analysis_id       NUMBER(10)     CONSTRAINT cert_analysis_fk REFERENCES nutrient_analysis(analysis_id),
    
    decision_date     DATE           DEFAULT SYSDATE,
    cert_status       VARCHAR2(20)   CONSTRAINT cert_status_nn NOT NULL
                                    CHECK (cert_status IN ('APPROVED', 'REJECTED', 'PENDING', 'CONDITIONAL')),
    rejection_reason  VARCHAR2(500),
    
    -- Quality ratings (1-10 scale)
    appearance_score  NUMBER(2)      CHECK (appearance_score BETWEEN 1 AND 10),
    texture_score     NUMBER(2)      CHECK (texture_score BETWEEN 1 AND 10),
    nutrient_score    NUMBER(2)      CHECK (nutrient_score BETWEEN 1 AND 10),
    overall_score     NUMBER(3,1)    CHECK (overall_score BETWEEN 1 AND 10),
    
    valid_until       DATE,
    cert_number       VARCHAR2(50)   CONSTRAINT cert_number_uq UNIQUE,
    issued_by         VARCHAR2(100),
    
    CONSTRAINT cert_dates_ck CHECK (decision_date <= valid_until OR valid_until IS NULL),
    CONSTRAINT one_cert_per_batch UNIQUE (batch_id)
) TABLESPACE nutrition_data;

-- 8. DISTRIBUTION_RECORD TABLE
PROMPT Creating DISTRIBUTION_RECORD table...
CREATE TABLE distribution_record (
    dist_id           NUMBER(10)     CONSTRAINT distribution_pk PRIMARY KEY,
    batch_id          NUMBER(10)     CONSTRAINT dist_batch_fk REFERENCES crop_batch(batch_id),
    from_location     VARCHAR2(200)  CONSTRAINT from_loc_nn NOT NULL,
    to_location       VARCHAR2(200)  CONSTRAINT to_loc_nn NOT NULL,
    transporter       VARCHAR2(100),
    transport_date    DATE           DEFAULT SYSDATE,
    expected_delivery DATE,
    actual_delivery   DATE,
    qr_code           VARCHAR2(100)  CONSTRAINT qr_code_uq UNIQUE,
    tracking_number   VARCHAR2(50),
    temperature_c     NUMBER(4,1),
    humidity_percent  NUMBER(5,2),
    status            VARCHAR2(20)   DEFAULT 'SCHEDULED'
                                    CHECK (status IN ('SCHEDULED', 'IN_TRANSIT', 'DELIVERED', 'DELAYED', 'CANCELLED')),
    notes             VARCHAR2(500),
    
    CONSTRAINT delivery_dates_ck CHECK (
        transport_date <= expected_delivery AND 
        (actual_delivery IS NULL OR actual_delivery >= transport_date)
    )
) TABLESPACE nutrition_data;

-- 9. HOLIDAY TABLE (For Phase VII restriction)
PROMPT Creating HOLIDAY table...
CREATE TABLE holiday (
    holiday_id        NUMBER(10)     CONSTRAINT holiday_pk PRIMARY KEY,
    holiday_date      DATE           CONSTRAINT holiday_date_nn NOT NULL,
    holiday_name      VARCHAR2(100)  CONSTRAINT holiday_name_nn NOT NULL,
    description       VARCHAR2(200),
    country           VARCHAR2(50)   DEFAULT 'RWANDA',
    is_recurring      CHAR(1)        DEFAULT 'Y' CHECK (is_recurring IN ('Y', 'N')),
    year_applicable   NUMBER(4),
    CONSTRAINT holiday_date_uq UNIQUE (holiday_date, country)
) TABLESPACE nutrition_data;

-- 10. AUDIT_LOG TABLE (For Phase VII auditing)
PROMPT Creating AUDIT_LOG table...
CREATE TABLE audit_log (
    log_id            NUMBER(10)     CONSTRAINT audit_log_pk PRIMARY KEY,
    user_id           VARCHAR2(50)   CONSTRAINT audit_user_nn NOT NULL,
    action_type       VARCHAR2(20)   CONSTRAINT action_type_nn NOT NULL
                                    CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT')),
    table_name        VARCHAR2(50)   CONSTRAINT table_name_nn NOT NULL,
    record_id         NUMBER(10),
    old_value         CLOB,
    new_value         CLOB,
    attempt_date      TIMESTAMP      DEFAULT SYSTIMESTAMP,
    status            VARCHAR2(20)   DEFAULT 'ATTEMPTED'
                                    CHECK (status IN ('ATTEMPTED', 'SUCCESS', 'DENIED', 'ERROR')),
    error_message     VARCHAR2(500),
    ip_address        VARCHAR2(45),
    session_id        VARCHAR2(100),
    
    CONSTRAINT audit_record_ck CHECK (
        (action_type IN ('INSERT', 'UPDATE', 'DELETE') AND record_id IS NOT NULL) OR
        action_type = 'SELECT'
    )
) TABLESPACE nutrition_data;

PROMPT ============================================
PROMPT All 10 tables created successfully!
PROMPT ============================================
