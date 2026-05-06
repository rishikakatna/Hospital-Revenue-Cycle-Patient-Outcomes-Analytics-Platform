from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from etl.utils.config import SETTINGS


def normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = (
        df.columns.str.strip().str.lower().str.replace(" ", "_").str.replace("-", "_")
    )
    return df


def clean_common(df: pd.DataFrame) -> pd.DataFrame:
    df = normalize_columns(df)
    for col in df.select_dtypes(include=["object"]).columns:
        df[col] = df[col].astype(str).str.strip()
        df[col] = df[col].replace({"nan": np.nan, "": np.nan})
        df[col] = df[col].fillna("Unknown")
    for col in df.select_dtypes(include=["number"]).columns:
        df[col] = df[col].fillna(df[col].median())
    return df


def process_file(parquet_path: Path) -> None:
    dataset_name = parquet_path.stem
    df = pd.read_parquet(parquet_path)
    df = clean_common(df)
    if "provider_id" in df.columns:
        df["provider_id"] = df["provider_id"].astype(str).str.zfill(6)
    output = SETTINGS.silver_dir / f"{dataset_name}_silver.parquet"
    output.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(output, index=False)
    print(f"Silver written: {output}")


def main() -> None:
    files = list(SETTINGS.bronze_dir.glob("*.parquet"))
    if not files:
        print("No bronze parquet files found.")
        return
    for parquet_file in files:
        process_file(parquet_file)


if __name__ == "__main__":
    main()
