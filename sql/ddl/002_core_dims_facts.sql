CREATE TABLE IF NOT EXISTS gold.dim_hospital (
    hospital_sk BIGSERIAL PRIMARY KEY,
    provider_id TEXT UNIQUE,
    hospital_name TEXT,
    city TEXT,
    state TEXT,
    hospital_type TEXT,
    ownership TEXT
);

CREATE TABLE IF NOT EXISTS gold.dim_payer (
    payer_sk BIGSERIAL PRIMARY KEY,
    payer_category TEXT UNIQUE
);

CREATE TABLE IF NOT EXISTS gold.dim_drg (
    drg_sk BIGSERIAL PRIMARY KEY,
    drg_code TEXT UNIQUE,
    drg_description TEXT
);

CREATE TABLE IF NOT EXISTS gold.fact_revenue_cycle (
    fact_sk BIGSERIAL PRIMARY KEY,
    service_date DATE,
    hospital_sk BIGINT REFERENCES gold.dim_hospital(hospital_sk),
    payer_sk BIGINT REFERENCES gold.dim_payer(payer_sk),
    drg_sk BIGINT REFERENCES gold.dim_drg(drg_sk),
    discharge_count NUMERIC(18,2),
    total_charge_amount NUMERIC(18,2),
    allowed_amount NUMERIC(18,2),
    paid_amount NUMERIC(18,2),
    denied_amount NUMERIC(18,2),
    denial_reason TEXT
);

CREATE TABLE IF NOT EXISTS gold.fact_outcomes_quality (
    fact_sk BIGSERIAL PRIMARY KEY,
    measure_date DATE,
    hospital_sk BIGINT REFERENCES gold.dim_hospital(hospital_sk),
    alos NUMERIC(10,2),
    readmission_rate_30d NUMERIC(10,4),
    hcahps_score NUMERIC(10,2),
    hac_rate NUMERIC(10,4),
    vbp_score NUMERIC(10,2),
    bed_occupancy_pct NUMERIC(10,2),
    operating_margin_pct NUMERIC(10,2)
);
