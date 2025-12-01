
# **Assumptions and Constraints Document**
**Project:** Nutritional Analysis and Crop Quality Tracking System  
**Phase:** III - Logical Model Design  
**Date:** November 2025  

---

## **1. BUSINESS ASSUMPTIONS**

### **1.1 Operational Assumptions**
- **Batch Size:** Each crop batch represents a minimum of 0.5 hectares of cultivation
- **Sampling Frequency:** Farmers submit samples at least once per growth stage (germination, flowering, pre-harvest)
- **Testing Timeline:** Lab analysis completed within 48 hours of sample receipt
- **Certification Validity:** Quality certificates expire after 6 months from issue date
- **Distribution Window:** Certified batches must enter distribution within 7 days of certification

### **1.2 User Behavior Assumptions**
- Farmers have basic digital literacy for data entry
- Lab technicians are trained in proper sample handling procedures
- Quality inspectors follow standardized evaluation criteria
- All users have unique login credentials
- Business hours: Monday-Friday, 8:00 AM - 5:00 PM (local time)

### **1.3 Geographical Assumptions**
- Initial deployment in Rwanda (East Africa timezone: UTC+2)
- Support for major crops: Maize, Beans, Potatoes, Rice, Coffee
- Soil types: Clay, Loam, Sandy, Volcanic
- Seasonal variations: Two main growing seasons (Season A & B)

---

## **2. DATA CONSTRAINTS**

### **2.1 Data Type Constraints**
| Attribute | Constraint | Reason |
|-----------|------------|--------|
| NITROGEN_LEVEL | BETWEEN 0.00 AND 100.00 | Nutrient percentage cannot exceed 100% |
| PH_LEVEL | BETWEEN 0.0 AND 14.0 | pH scale range |
| EXPECTED_YIELD | > 0 | Yield must be positive |
| HARVEST_DATE | > PLANTING_DATE | Logical timeline |
| VALID_UNTIL | > DECISION_DATE | Certificate must expire after issue |

### **2.2 Business Rule Constraints**
1. **Batch Status Flow:**
   ```
   ACTIVE → SAMPLED → TESTED → CERTIFIED → DISTRIBUTED
         ↘ REJECTED ↗
   ```
   - No batch can skip stages
   - Once REJECTED, batch must restart from SAMPLED

2. **Certification Rules:**
   - Minimum nutrient thresholds for approval:
     - Nitrogen: ≥ 2.5%
     - Phosphorus: ≥ 0.3%
     - Potassium: ≥ 1.8%
   - pH must be between 5.5 and 7.5 for most crops
   - Inspector must be AUTHORIZATION_LEVEL ≥ 'LEVEL2' for final approval

3. **Temporal Constraints:**
   - Sample must be collected within 30 days of expected harvest
   - Analysis must occur within 7 days of sample collection
   - Decision must be made within 3 days of analysis completion

---

## **3. TECHNICAL ASSUMPTIONS**

### **3.1 Database Environment**
- **Database:** Oracle 19c Enterprise Edition or higher
- **Character Set:** AL32UTF8 (Unicode)
- **NLS Settings:** NLS_DATE_FORMAT = 'DD-MON-YYYY'
- **Tablespace:** 10GB initial, AUTOEXTEND ON
- **Archive Logging:** Enabled for recovery purposes

### **3.2 Performance Assumptions**
- **Concurrent Users:** Maximum 50 simultaneous connections
- **Transaction Volume:** ~1,000 DML operations per hour during peak
- **Data Growth:** 15% annually
- **Retention Policy:**
  - Active data: 3 years online
  - Historical data: Archived after 3 years
  - Audit logs: Purged after 2 years

### **3.3 Integration Assumptions**
- **External Systems:** None in Phase 1 (standalone system)
- **Data Import:** Manual CSV upload for initial data migration
- **Export Format:** PDF for certificates, CSV for reports
- **Mobile Access:** Responsive web interface, no native mobile app initially

---

## **4. SECURITY CONSTRAINTS**

### **4.1 User Roles & Privileges**
| Role | Tables Access | Operations Allowed |
|------|---------------|-------------------|
| FARMER_USER | CROP_BATCH, SOIL_SAMPLE | SELECT, INSERT (own data only) |
| LAB_USER | NUTRIENT_ANALYSIS, SOIL_SAMPLE | SELECT, INSERT, UPDATE |
| INSPECTOR_USER | CERTIFICATION, NUTRIENT_ANALYSIS | SELECT, INSERT, UPDATE |
| ADMIN_USER | ALL TABLES | ALL operations |
| READONLY_USER | ALL TABLES | SELECT only |

### **4.2 Data Protection Constraints**
- **PII Protection:** Farmer contact information encrypted at rest
- **Audit Trail:** All DML operations logged regardless of success/failure
- **Data Visibility:** Users can only see data within their jurisdiction
- **Backup Frequency:** Daily incremental, weekly full backups

### **4.3 Business Hour Restrictions (Phase VII)**
- **Restricted Actions:** INSERT, UPDATE, DELETE on NUTRIENT_ANALYSIS table
- **Restricted Periods:**
  1. Weekdays (Monday-Friday)
  2. Public holidays (Rwandan national holidays)
- **Allowed Periods:** Weekends (Saturday-Sunday, non-holidays)
- **Exempt Users:** ADMIN_USER (bypasses all restrictions)

---

## **5. SCALABILITY ASSUMPTIONS**

### **5.1 Growth Projections**
| Year | Farmers | Batches/Year | Samples/Year | Analyses/Year |
|------|---------|--------------|--------------|---------------|
| 1 | 1,000 | 10,000 | 30,000 | 30,000 |
| 2 | 1,500 | 18,000 | 54,000 | 54,000 |
| 3 | 2,250 | 27,000 | 81,000 | 81,000 |

### **5.2 Future Expansion Considerations**
- **Additional Crops:** Support for 20+ crop types by Year 3
- **Region Expansion:** Multi-country support (Uganda, Tanzania, Kenya)
- **IoT Integration:** Sensor data automatic ingestion
- **Mobile API:** REST API for third-party integrations

---

## **6. DATA QUALITY ASSUMPTIONS**

### **6.1 Data Validation Rules**
1. **Farmer Registration:**
   - Contact must include valid email OR phone number
   - Location must be geocodable (lat/long coordinates)

2. **Sample Collection:**
   - Sample weight: 200g minimum
   - Collection temperature: ≤ 30°C
   - Preservation method recorded

3. **Nutrient Analysis:**
   - Duplicate testing for abnormal results
   - Equipment calibration logged
   - Technician certification verified

### **6.2 Data Completeness Requirements**
- **Mandatory Fields:** 100% completion required
- **Optional Fields:** Can be null but tracked for compliance
- **Historical Data:** 3 years minimum for trend analysis
- **Real-time Data:** 95% availability target

---

## **7. COMPLIANCE CONSTRAINTS**

### **7.1 Regulatory Requirements**
- **Rwanda Standards Board (RSB):** Food safety standards
- **Ministry of Agriculture:** Crop quality guidelines
- **GDPR Equivalent:** Rwanda Data Protection Law
- **Export Requirements:** International phytosanitary standards

### **7.2 Reporting Obligations**
- **Monthly:** Certification statistics to Ministry of Agriculture
- **Quarterly:** Quality trends analysis
- **Annual:** Comprehensive audit report
- **On-demand:** Recall readiness reports

---

## **8. RISK ASSUMPTIONS**

### **8.1 Accepted Risks**
1. **Data Entry Errors:** Assumed 2% error rate, mitigated by validation rules
2. **System Downtime:** Maximum 4 hours/month during non-peak hours
3. **User Adoption:** 80% target adoption rate within 6 months
4. **Data Loss:** RPO = 24 hours, RTO = 4 hours

### **8.2 Mitigation Strategies**
- **Backup:** Daily backups with off-site storage
- **Training:** Comprehensive user training program
- **Monitoring:** 24/7 system monitoring with alerts
- **Support:** Helpdesk available during business hours

---

## **9. DEPENDENCIES**

### **9.1 External Dependencies**
- **Oracle Database License:** Valid and current
- **Network Infrastructure:** Stable internet connectivity
- **Power Supply:** Uninterrupted power supply (UPS) for servers
- **Hardware:** Server meets Oracle minimum requirements

### **9.2 Internal Dependencies**
- **Phase I:** Problem statement approved
- **Phase II:** Business process model completed
- **Phase III:** Logical design finalized before physical implementation
- **User Acceptance:** Key stakeholders identified and engaged

---

## **10. CHANGE MANAGEMENT ASSUMPTIONS**

### **10.1 Schema Evolution**
- **Backward Compatibility:** New versions must not break existing reports
- **Migration Path:** Data migration scripts for all schema changes
- **Version Control:** All DDL scripts in GitHub with semantic versioning
- **Testing:** Unit tests for all constraints and triggers

### **10.2 Deployment Windows**
- **Development:** Continuous integration
- **Testing:** Weekly deployments to test environment
- **Production:** Monthly deployments during maintenance windows (Sundays 2:00-4:00 AM)

---

## **SUMMARY OF KEY CONSTRAINTS**

1. **Temporal:** No nutrient analysis DML on weekdays/holidays
2. **Quality:** Minimum nutrient thresholds for certification
3. **Sequence:** Strict workflow order (plant→sample→test→certify→distribute)
4. **Security:** Role-based access control with audit logging
5. **Scalability:** Designed for 15% annual growth
6. **Compliance:** Meets Rwandan agricultural standards
7. **Recovery:** RPO 24h, RTO 4h with proper backups

---

**Document Status:** Approved for Phase III  
**Next Phase:** IV - Database Creation (Physical Implementation)  
**Prepared By:** NGOGA ARNAUD  
**Student ID:** 27627
**Date:** November 2025
