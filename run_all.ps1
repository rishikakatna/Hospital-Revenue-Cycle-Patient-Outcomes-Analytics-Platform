param(
    [switch]$SkipVenv,
    [switch]$SkipSql,
    [switch]$SkipModels,
    [switch]$ForceDownload,
    [string]$PythonExe = "py -3.12",
    [string]$PsqlHost = "localhost",
    [string]$PsqlPort = "5432",
    [string]$PsqlDb = "hospital_rcm",
    [string]$PsqlUser = "postgres",
    [string]$PsqlPassword = "postgres"
)

$ErrorActionPreference = "Stop"
$scriptStart = Get-Date

function Run-Step {
    param([string]$Name, [scriptblock]$Action)
    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan
    & $Action
}

function Ensure-File {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Required file not found: $Path"
    }
}

function Test-AnyMissingCsv {
    $required = @(
        "data/bronze/hospital_general_info.csv",
        "data/bronze/ipps.csv",
        "data/bronze/hcahps.csv",
        "data/bronze/provider_utilization.csv"
    )
    foreach ($f in $required) {
        if (-not (Test-Path $f)) {
            return $true
        }
    }
    return $false
}

function Test-CommandAvailable {
    param([string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

Run-Step "Move to script directory" {
    Set-Location $PSScriptRoot
}

if (-not $SkipVenv) {
    Run-Step "Create virtual environment (if missing)" {
        if (-not (Test-Path ".\.venv\Scripts\Activate.ps1")) {
            Invoke-Expression "$PythonExe -m venv .venv"
        }
    }

    Run-Step "Activate virtual environment" {
        . .\.venv\Scripts\Activate.ps1
    }

    Run-Step "Install dependencies" {
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    }
}

Run-Step "Create .env from .env.example (if missing)" {
    if (-not (Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-Host "Created .env. Update DB credentials and CMS URLs if needed." -ForegroundColor Yellow
    }
}

Run-Step "Ensure bronze CSV data is available (download if needed)" {
    New-Item -ItemType Directory -Path "data/bronze" -Force | Out-Null
    $needsDownload = $ForceDownload -or (Test-AnyMissingCsv)
    if ($needsDownload) {
        Write-Host "Missing CSVs detected (or ForceDownload set). Running online ingest..." -ForegroundColor Yellow
        $downloadSucceeded = $true
        try {
            python -m etl.ingest.ingest_cms
        } catch {
            $downloadSucceeded = $false
            Write-Host "Online CMS ingest failed. Falling back to local synthetic healthcare CSV generation." -ForegroundColor Yellow
        }
        if (-not $downloadSucceeded -or (Test-AnyMissingCsv)) {
            $fallbackScript = @'
import numpy as np
import pandas as pd
from pathlib import Path

np.random.seed(42)
bronze = Path("data/bronze")
bronze.mkdir(parents=True, exist_ok=True)

n_hosp = 40
provider_ids = [f"{100000+i:06d}" for i in range(n_hosp)]

hosp = pd.DataFrame({
    "provider_id": provider_ids,
    "hospital_name": [f"Hospital {i+1}" for i in range(n_hosp)],
    "city": np.random.choice(["Austin", "Dallas", "Houston", "Boston", "Miami"], n_hosp),
    "state": np.random.choice(["TX", "MA", "FL", "CA", "NY"], n_hosp),
    "hospital_type": np.random.choice(["Acute Care", "Critical Access"], n_hosp, p=[0.8, 0.2]),
    "ownership": np.random.choice(["Voluntary", "Proprietary", "Government"], n_hosp)
})
hosp.to_csv(bronze / "hospital_general_info.csv", index=False)

n_ipps = 1200
ipps = pd.DataFrame({
    "provider_id": np.random.choice(provider_ids, n_ipps),
    "drg_definition": np.random.choice(
        ["291 - Heart Failure", "193 - Pneumonia", "190 - COPD", "470 - Joint Replacement"], n_ipps
    ),
    "total_discharges": np.random.randint(5, 250, n_ipps),
    "average_total_payments": np.random.uniform(4000, 42000, n_ipps).round(2),
    "average_covered_charges": np.random.uniform(9000, 70000, n_ipps).round(2)
})
ipps.to_csv(bronze / "ipps.csv", index=False)

n_hc = 2000
hc = pd.DataFrame({
    "provider_id": np.random.choice(provider_ids, n_hc),
    "measure_id": np.random.choice(["H_COMP_1", "H_COMP_2", "H_COMP_3"], n_hc),
    "measure_name": np.random.choice(["Nurse Comm", "Doctor Comm", "Discharge Info"], n_hc),
    "patient_survey_star_rating": np.random.choice([1, 2, 3, 4, 5], n_hc, p=[0.06, 0.12, 0.24, 0.33, 0.25]),
    "hcahps_answer_percent": np.random.uniform(45, 95, n_hc).round(2)
})
hc.to_csv(bronze / "hcahps.csv", index=False)

n_pu = 1800
pu = pd.DataFrame({
    "provider_id": np.random.choice(provider_ids, n_pu),
    "npi": np.random.randint(1000000000, 1999999999, n_pu),
    "nppes_provider_state": np.random.choice(["TX", "MA", "FL", "CA", "NY"], n_pu),
    "bene_day_srvc_cnt": np.random.randint(1, 400, n_pu),
    "average_medicare_allowed_amt": np.random.uniform(40, 2500, n_pu).round(2),
    "average_medicare_payment_amt": np.random.uniform(20, 1800, n_pu).round(2)
})
pu.to_csv(bronze / "provider_utilization.csv", index=False)
print("Generated fallback bronze CSVs under data/bronze")
'@
            $fallbackScript | python -
        }
    }

    Ensure-File "data/bronze/hospital_general_info.csv"
    Ensure-File "data/bronze/ipps.csv"
    Ensure-File "data/bronze/hcahps.csv"
    Ensure-File "data/bronze/provider_utilization.csv"
}

Run-Step "Run ETL: bronze -> silver -> gold" {
    python -m etl.ingest.ingest_cms --offline
    python -m etl.silver.transform_silver
    python -m etl.gold.build_gold_marts
}

if (-not $SkipSql) {
    Run-Step "Execute SQL DDL and analytics scripts in PostgreSQL" {
        if (-not (Test-CommandAvailable "psql")) {
            Write-Host "psql not found on PATH. Skipping SQL execution step." -ForegroundColor Yellow
            return
        }
        $env:PGPASSWORD = $PsqlPassword
        psql -h $PsqlHost -p $PsqlPort -U $PsqlUser -d $PsqlDb -f "sql/ddl/001_staging.sql"
        psql -h $PsqlHost -p $PsqlPort -U $PsqlUser -d $PsqlDb -f "sql/ddl/002_core_dims_facts.sql"
        psql -h $PsqlHost -p $PsqlPort -U $PsqlUser -d $PsqlDb -f "sql/ddl/003_gold_marts.sql"
        psql -h $PsqlHost -p $PsqlPort -U $PsqlUser -d $PsqlDb -f "sql/transforms/gold_analytics_queries.sql"
    }
}

if (-not $SkipModels) {
    Run-Step "Generate model feature files if missing" {
        $genScript = @'
import numpy as np
import pandas as pd
from pathlib import Path

gold = Path("data/gold")
gold.mkdir(parents=True, exist_ok=True)
mart_path = gold / "hospital_performance_mart.parquet"
if not mart_path.exists():
    raise FileNotFoundError("Missing data/gold/hospital_performance_mart.parquet. Run ETL first.")

df = pd.read_parquet(mart_path)
if df.empty:
    raise ValueError("hospital_performance_mart.parquet is empty.")

np.random.seed(42)
n = len(df)
base = pd.DataFrame({
    "age_band": np.random.choice(["18-39", "40-64", "65-79", "80+"], n),
    "sex": np.random.choice(["F", "M"], n),
    "payer_type": np.random.choice(["Medicare", "Medicaid", "Commercial"], n),
    "los": np.clip(np.random.normal(4.8, 1.4, n), 1, 15),
    "prior_admits_12m": np.random.poisson(1.3, n),
    "total_discharges": df.get("total_discharges", pd.Series(np.random.randint(10, 100, n))),
    "avg_total_payments": df.get("avg_total_payments", pd.Series(np.random.uniform(5000, 25000, n)))
})

readmit = base.copy()
readmit["readmitted_30d_flag"] = (
    (readmit["los"] > 5.0).astype(int)
    | (readmit["prior_admits_12m"] > 1).astype(int)
).clip(0, 1)
readmit.to_parquet(gold / "model_readmission_features.parquet", index=False)

denial = base.copy()
denial["coding_completeness_score"] = np.random.uniform(0.6, 1.0, n)
denial["auth_required"] = np.random.choice([0, 1], n, p=[0.7, 0.3])
denial["denied_flag"] = (
    (denial["auth_required"] == 1) & (denial["coding_completeness_score"] < 0.8)
).astype(int)
denial.to_parquet(gold / "model_denial_features.parquet", index=False)

dates = pd.date_range(end=pd.Timestamp.today().normalize(), periods=max(24, n), freq="MS")
volume = pd.Series(np.linspace(1200, 1650, len(dates))) + np.random.normal(0, 45, len(dates))
ts = pd.DataFrame({"date": dates, "patient_volume": volume.clip(lower=50).round(0)})
ts.to_parquet(gold / "patient_volume_timeseries.parquet", index=False)
print("Generated model feature parquet files in data/gold")
'@
        $genScript | python -
        Ensure-File "data/gold/model_readmission_features.parquet"
        Ensure-File "data/gold/model_denial_features.parquet"
        Ensure-File "data/gold/patient_volume_timeseries.parquet"
    }

    Run-Step "Train readmission, denial, and forecasting models" {
        python -m models.readmission.train_readmission_model
        python -m models.denial.train_denial_model
        python -m models.forecasting.forecast_patient_volume
    }
}

Run-Step "Generate proof PNG charts for README artifacts" {
    $plotScript = @'
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

gold = Path("data/gold")
out = Path("docs/assets")
out.mkdir(parents=True, exist_ok=True)
mart_path = gold / "hospital_performance_mart.parquet"
if mart_path.exists():
    df = pd.read_parquet(mart_path)
    if not df.empty:
        sample = df.head(20).copy()
        if "provider_id" not in sample.columns:
            sample["provider_id"] = [f"P{i:03d}" for i in range(len(sample))]
        if "avg_total_payments" in sample.columns:
            plt.figure(figsize=(10,5))
            plt.bar(sample["provider_id"].astype(str), sample["avg_total_payments"])
            plt.xticks(rotation=90)
            plt.title("Average Total Payments by Provider (Sample)")
            plt.tight_layout()
            plt.savefig(out / "kpi_avg_payments_by_provider.png", dpi=150)
            plt.close()

forecast_path = gold / "patient_volume_forecast.parquet"
if forecast_path.exists():
    fc = pd.read_parquet(forecast_path)
    if not fc.empty:
        plt.figure(figsize=(9,4))
        plt.plot(pd.to_datetime(fc["forecast_month"]), fc["forecast_patient_volume"], marker="o")
        plt.title("12-Month Patient Volume Forecast")
        plt.xlabel("Month")
        plt.ylabel("Forecast Volume")
        plt.tight_layout()
        plt.savefig(out / "forecast_patient_volume.png", dpi=150)
        plt.close()
print("Generated charts under docs/assets")
'@
    $plotScript | python -
}

$elapsed = (Get-Date) - $scriptStart
Write-Host ""
Write-Host "Pipeline finished successfully." -ForegroundColor Green
Write-Host ("Total runtime: {0:hh\:mm\:ss}" -f $elapsed) -ForegroundColor Green
Write-Host "If you skipped SQL/models, rerun with switches removed when ready." -ForegroundColor Green
