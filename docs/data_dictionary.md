# Data Dictionary (Core Gold Model)

## `gold.dim_hospital`
- `hospital_sk`: surrogate key
- `provider_id`: CMS provider identifier
- `hospital_name`, `city`, `state`
- `hospital_type`, `ownership`

## `gold.dim_payer`
- `payer_sk`: surrogate key
- `payer_category`: Medicare, Medicaid, Commercial, Self-pay

## `gold.dim_drg`
- `drg_sk`: surrogate key
- `drg_code`: MS-DRG code
- `drg_description`: DRG textual label

## `gold.fact_revenue_cycle`
- `service_date`
- `hospital_sk`, `payer_sk`, `drg_sk`
- `discharge_count`
- `total_charge_amount`
- `allowed_amount`
- `paid_amount` (net revenue input)
- `denied_amount`
- `denial_reason`

## `gold.fact_outcomes_quality`
- `measure_date`
- `hospital_sk`
- `alos`
- `readmission_rate_30d`
- `hcahps_score`
- `hac_rate`
- `vbp_score`
- `bed_occupancy_pct`
- `operating_margin_pct`
