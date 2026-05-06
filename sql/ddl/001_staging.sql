CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

CREATE TABLE IF NOT EXISTS bronze.hospital_general_info_raw (
    payload JSONB,
    source_file_name TEXT,
    ingest_timestamp_utc TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.ipps_raw (
    payload JSONB,
    source_file_name TEXT,
    ingest_timestamp_utc TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.hcahps_raw (
    payload JSONB,
    source_file_name TEXT,
    ingest_timestamp_utc TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.provider_utilization_raw (
    payload JSONB,
    source_file_name TEXT,
    ingest_timestamp_utc TIMESTAMP
);
