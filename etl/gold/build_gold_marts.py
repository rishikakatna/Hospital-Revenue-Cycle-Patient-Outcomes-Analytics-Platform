from __future__ import annotations

from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine

from etl.utils.config import SETTINGS


def load_silver(name: str) -> pd.DataFrame:
    path = SETTINGS.silver_dir / f"{name}_silver.parquet"
    if not path.exists():
        return pd.DataFrame()
    return pd.read_parquet(path)


def build_hospital_performance_mart() -> pd.DataFrame:
    ipps = load_silver("ipps")
    hcahps = load_silver("hcahps")
    hospitals = load_silver("hospital_general_info")

    if ipps.empty or hospitals.empty:
        return pd.DataFrame()

    key = "provider_id" if "provider_id" in ipps.columns else None
    if not key:
        return pd.DataFrame()

    rev = (
        ipps.groupby(key, as_index=False)
        .agg(
            total_discharges=("total_discharges", "sum")
            if "total_discharges" in ipps.columns
            else (key, "count"),
            avg_total_payments=("average_total_payments", "mean")
            if "average_total_payments" in ipps.columns
            else (key, "count"),
        )
        .rename(columns={key: "provider_id"})
    )

    mart = hospitals.merge(rev, on="provider_id", how="left")
    if not hcahps.empty and "provider_id" in hcahps.columns:
        hcahps_agg = hcahps.groupby("provider_id", as_index=False).size()
        hcahps_agg = hcahps_agg.rename(columns={"size": "hcahps_record_count"})
        mart = mart.merge(hcahps_agg, on="provider_id", how="left")

    mart["total_discharges"] = mart["total_discharges"].fillna(0)
    mart["avg_total_payments"] = mart["avg_total_payments"].fillna(0)
    mart["hcahps_record_count"] = mart["hcahps_record_count"].fillna(0)
    return mart


def persist_outputs(df: pd.DataFrame) -> None:
    if df.empty:
        print("No gold marts generated.")
        return
    SETTINGS.gold_dir.mkdir(parents=True, exist_ok=True)
    parquet_path = SETTINGS.gold_dir / "hospital_performance_mart.parquet"
    df.to_parquet(parquet_path, index=False)
    print(f"Gold parquet written: {parquet_path}")

    try:
        engine = create_engine(SETTINGS.sqlalchemy_url)
        df.to_sql(
            "gold_hospital_performance_mart",
            con=engine,
            if_exists="replace",
            index=False,
        )
        print("Gold mart loaded to PostgreSQL: gold_hospital_performance_mart")
    except Exception as exc:
        print(f"Skipping PostgreSQL load; unable to connect/write: {exc}")


def main() -> None:
    mart = build_hospital_performance_mart()
    persist_outputs(mart)


if __name__ == "__main__":
    main()
