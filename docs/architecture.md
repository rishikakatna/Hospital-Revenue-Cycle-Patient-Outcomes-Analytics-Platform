# Architecture Overview

## Medallion Pipeline
1. Bronze: raw CMS extracts ingested from public datasets.
2. Silver: cleaned and standardized source tables.
3. Gold: business-ready marts, star schema, and KPI views for BI and modeling.

## End-to-End Flow
- Python ETL ingests CSV files from CMS data portals into parquet.
- Silver transformations normalize identifiers, data types, and missing data handling.
- Gold marts combine finance, quality, and utilization domains.
- PostgreSQL hosts analytical tables and views consumed by Power BI/Tableau.
- Scikit-learn models score readmission risk and denial probability.

## Deployment Options
- AWS: S3 (bronze/silver/gold files), RDS PostgreSQL, MWAA for orchestration.
- Azure: ADLS Gen2, Azure Database for PostgreSQL, Data Factory/Databricks.
