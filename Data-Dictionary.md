

## **4. Complete Data Dictionary**

| Table | Column | Data Type | Constraints | Purpose |
|-------|--------|-----------|-------------|---------|
| **FARMER** | FARMER_ID | NUMBER(10) | PK, NOT NULL | Unique farmer identifier |
| | NAME | VARCHAR2(100) | NOT NULL | Farmer's full name |
| | LOCATION | VARCHAR2(200) | NOT NULL | Farm location |
| | CONTACT | VARCHAR2(50) | NOT NULL | Phone/email |
| | REGISTRATION_DATE | DATE | DEFAULT SYSDATE | System registration date |
| | SOIL_TYPE | VARCHAR2(50) | | Type of soil on farm |
| **CROP_BATCH** | BATCH_ID | NUMBER(10) | PK, NOT NULL | Unique batch identifier |
| | FARMER_ID | NUMBER(10) | FK → FARMER | Farmer who owns batch |
| | CROP_TYPE | VARCHAR2(50) | NOT NULL | Wheat, Corn, Rice, etc. |
| | PLANTING_DATE | DATE | NOT NULL | Date planted |
| | HARVEST_DATE | DATE | | Expected harvest date |
| | EXPECTED_YIELD | NUMBER(8,2) | CHECK >0 | Expected yield in kg |
| | STATUS | VARCHAR2(20) | DEFAULT 'ACTIVE' | ACTIVE, HARVESTED, CERTIFIED |
| **SOIL_SAMPLE** | SAMPLE_ID | NUMBER(10) | PK, NOT NULL | Unique sample identifier |
| | BATCH_ID | NUMBER(10) | FK → CROP_BATCH | Batch sample taken from |
| | COLLECTION_DATE | DATE | DEFAULT SYSDATE | Date collected |
| | COLLECTED_BY | VARCHAR2(100) | | Person who collected |
| | SAMPLE_TYPE | VARCHAR2(30) | | SOIL, LEAF, STEM, etc. |
| **NUTRIENT_ANALYSIS** | ANALYSIS_ID | NUMBER(10) | PK, NOT NULL | Unique analysis ID |
| | SAMPLE_ID | NUMBER(10) | FK → SOIL_SAMPLE | Sample analyzed |
| | LAB_TECH_ID | NUMBER(10) | FK → LAB_TECHNICIAN | Technician who performed |
| | ANALYSIS_DATE | DATE | DEFAULT SYSDATE | Date of analysis |
| | NITROGEN_LEVEL | NUMBER(5,2) | CHECK BETWEEN 0-100 | Nitrogen percentage |
| | PHOSPHORUS_LEVEL | NUMBER(5,2) | CHECK BETWEEN 0-100 | Phosphorus percentage |
| | POTASSIUM_LEVEL | NUMBER(5,2) | CHECK BETWEEN 0-100 | Potassium percentage |
| | PH_LEVEL | NUMBER(3,1) | CHECK BETWEEN 0-14 | Soil pH value |
| | OTHER_NUTRIENTS | CLOB | | JSON of micronutrients |
| | STATUS | VARCHAR2(20) | DEFAULT 'PENDING' | PENDING, COMPLETE, ABNORMAL |
| **LAB_TECHNICIAN** | TECH_ID | NUMBER(10) | PK, NOT NULL | Technician identifier |
| | NAME | VARCHAR2(100) | NOT NULL | Full name |
| | LAB_LOCATION | VARCHAR2(100) | | Lab location |
| | SPECIALIZATION | VARCHAR2(50) | | Crop specialization |
| | CERTIFICATION_LEVEL | VARCHAR2(20) | | JUNIOR, SENIOR, EXPERT |
| **QUALITY_INSPECTOR** | INSPECTOR_ID | NUMBER(10) | PK, NOT NULL | Inspector identifier |
| | NAME | VARCHAR2(100) | NOT NULL | Full name |
| | DEPARTMENT | VARCHAR2(50) | | QA Department |
| | AUTHORIZATION_LEVEL | VARCHAR2(20) | | LEVEL1, LEVEL2, LEVEL3 |
| | CONTACT | VARCHAR2(50) | | Phone/email |
| **CERTIFICATION** | CERT_ID | NUMBER(10) | PK, NOT NULL | Certification identifier |
| | BATCH_ID | NUMBER(10) | FK → CROP_BATCH | Batch being certified |
| | INSPECTOR_ID | NUMBER(10) | FK → QUALITY_INSPECTOR | Inspector making decision |
| | ANALYSIS_ID | NUMBER(10) | FK → NUTRIENT_ANALYSIS | Analysis being evaluated |
| | DECISION_DATE | DATE | DEFAULT SYSDATE | Date of decision |
| | CERT_STATUS | VARCHAR2(20) | NOT NULL | APPROVED, REJECTED, PENDING |
| | REJECTION_REASON | VARCHAR2(500) | | If rejected, why? |
| | VALID_UNTIL | DATE | | Certificate expiry date |
| **DISTRIBUTION_RECORD** | DIST_ID | NUMBER(10) | PK, NOT NULL | Distribution record ID |
| | BATCH_ID | NUMBER(10) | FK → CROP_BATCH | Batch being distributed |
| | FROM_LOCATION | VARCHAR2(200) | NOT NULL | Starting location |
| | TO_LOCATION | VARCHAR2(200) | NOT NULL | Destination |
| | TRANSPORT_DATE | DATE | DEFAULT SYSDATE | Date shipped |
| | DELIVERY_DATE | DATE | | Actual delivery date |
| | QR_CODE | VARCHAR2(100) | UNIQUE | Unique QR for tracking |
| | STATUS | VARCHAR2(20) | DEFAULT 'IN_TRANSIT' | Status of delivery |
| **HOLIDAY** | HOLIDAY_ID | NUMBER(10) | PK, NOT NULL | Holiday identifier |
| | HOLIDAY_DATE | DATE | NOT NULL, UNIQUE | Date of holiday |
| | DESCRIPTION | VARCHAR2(200) | | Holiday name/description |
| | COUNTRY | VARCHAR2(50) | DEFAULT 'RWANDA' | Country code |
| **AUDIT_LOG** | LOG_ID | NUMBER(10) | PK, NOT NULL | Audit log identifier |
| | USER_ID | VARCHAR2(50) | NOT NULL | Database user |
| | ACTION_TYPE | VARCHAR2(20) | NOT NULL | INSERT, UPDATE, DELETE |
| | TABLE_NAME | VARCHAR2(50) | NOT NULL | Table affected |
| | RECORD_ID | NUMBER(10) | | ID of affected record |
| | ATTEMPT_DATE | TIMESTAMP | DEFAULT SYSTIMESTAMP | When attempted |
| | STATUS | VARCHAR2(20) | NOT NULL | SUCCESS, DENIED, ERROR |
| | ERROR_MESSAGE | VARCHAR2(500) | | Error if any |

---

