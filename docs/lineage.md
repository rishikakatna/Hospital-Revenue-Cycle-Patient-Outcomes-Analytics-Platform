# Data Lineage

## Source to KPI Mapping
- CMS Hospital General Information -> `dim_hospital` -> state and facility benchmark filtering
- CMS IPPS DRG data -> `dim_drg`, `fact_revenue_cycle` -> CMI, DRG margin, payer reimbursement analysis
- CMS Hospital Compare/HCAHPS -> `fact_outcomes_quality` -> patient experience and quality metrics
- CMS Provider Utilization -> `fact_revenue_cycle` and forecasting feature sets

## Business Metric Lineage
- Net Patient Revenue = SUM(`fact_revenue_cycle.paid_amount`)
- Denial Rate = SUM(`denied_amount`) / SUM(`total_charge_amount`)
- Readmission 30D = AVG(`fact_outcomes_quality.readmission_rate_30d`)
- ALOS = AVG(`fact_outcomes_quality.alos`)
