# Database Configuration - Phase IV

## PDB Details
- **PDB Name:** mon_27627_ngoga_NutritionCropDB
- **Admin User:** arnaud
- **Password:** Ngoga

## Tablespaces
1. **nutrition_data** - 100M, AUTOEXTEND ON (Data storage)
2. **nutrition_idx** - 50M, AUTOEXTEND ON (Index storage)
3. **nutrition_temp** - 50M (Temporary operations)

## Application Users
1. **farmer_user** - For farmers submitting samples
2. **lab_user** - For lab technicians entering results
3. **inspector_user** - For quality inspectors
4. **report_user** - Read-only for BI reports

## Configuration Parameters
- SGA_TARGET: 500M
- PGA_AGGREGATE_TARGET: 200M
- Archive Logging: ENABLED
- Autoextend: ENABLED for all datafiles
