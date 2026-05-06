CREATE OR REPLACE VIEW gold.vw_executive_kpis AS
SELECT
    h.state,
    DATE_TRUNC('month', f.service_date) AS month_start,
    SUM(f.paid_amount) AS net_patient_revenue,
    CASE WHEN SUM(f.total_charge_amount) = 0 THEN 0
         ELSE SUM(f.denied_amount) / SUM(f.total_charge_amount) END AS denial_rate,
    AVG(o.alos) AS avg_alos,
    AVG(o.readmission_rate_30d) AS avg_readmission_rate_30d,
    AVG(o.bed_occupancy_pct) AS avg_bed_occupancy_pct,
    AVG(o.operating_margin_pct) AS avg_operating_margin_pct
FROM gold.fact_revenue_cycle f
JOIN gold.dim_hospital h ON h.hospital_sk = f.hospital_sk
LEFT JOIN gold.fact_outcomes_quality o
    ON o.hospital_sk = f.hospital_sk
   AND DATE_TRUNC('month', o.measure_date) = DATE_TRUNC('month', f.service_date)
GROUP BY 1,2;

CREATE OR REPLACE VIEW gold.vw_clinical_ops AS
SELECT
    h.hospital_name,
    h.state,
    f.service_date,
    d.drg_code,
    d.drg_description,
    p.payer_category,
    f.discharge_count,
    o.alos,
    o.readmission_rate_30d,
    o.hcahps_score
FROM gold.fact_revenue_cycle f
JOIN gold.dim_hospital h ON h.hospital_sk = f.hospital_sk
JOIN gold.dim_drg d ON d.drg_sk = f.drg_sk
JOIN gold.dim_payer p ON p.payer_sk = f.payer_sk
LEFT JOIN gold.fact_outcomes_quality o
    ON o.hospital_sk = f.hospital_sk
   AND o.measure_date = f.service_date;
