-- Average Length of Stay (ALOS) by DRG and payer
SELECT
    d.drg_code,
    p.payer_category,
    AVG(o.alos) AS avg_alos
FROM gold.fact_revenue_cycle f
JOIN gold.dim_drg d ON d.drg_sk = f.drg_sk
JOIN gold.dim_payer p ON p.payer_sk = f.payer_sk
JOIN gold.fact_outcomes_quality o ON o.hospital_sk = f.hospital_sk
GROUP BY 1,2
ORDER BY 3 DESC;

-- Readmission penalties by selected conditions
SELECT
    d.drg_description,
    AVG(o.readmission_rate_30d) AS avg_readmission_rate_30d,
    SUM(f.denied_amount) AS total_denied_amount
FROM gold.fact_revenue_cycle f
JOIN gold.dim_drg d ON d.drg_sk = f.drg_sk
JOIN gold.fact_outcomes_quality o ON o.hospital_sk = f.hospital_sk
WHERE d.drg_description ILIKE ANY (ARRAY['%Heart Failure%','%Pneumonia%','%COPD%'])
GROUP BY 1
ORDER BY 2 DESC;

-- Payer mix and reimbursement ratio
SELECT
    p.payer_category,
    SUM(f.paid_amount) AS total_paid,
    SUM(f.total_charge_amount) AS total_charged,
    CASE WHEN SUM(f.total_charge_amount) = 0 THEN 0
         ELSE SUM(f.paid_amount)/SUM(f.total_charge_amount) END AS reimbursement_ratio
FROM gold.fact_revenue_cycle f
JOIN gold.dim_payer p ON p.payer_sk = f.payer_sk
GROUP BY 1
ORDER BY 2 DESC;

-- Denial root causes
SELECT
    COALESCE(f.denial_reason, 'Unknown') AS denial_reason,
    COUNT(*) AS claim_rows,
    SUM(f.denied_amount) AS denied_value
FROM gold.fact_revenue_cycle f
WHERE f.denied_amount > 0
GROUP BY 1
ORDER BY 3 DESC;
