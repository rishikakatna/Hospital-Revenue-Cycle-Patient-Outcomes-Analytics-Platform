from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path

import pandas as pd
import requests

from etl.utils.config import SETTINGS

DATASETS = {
    "hospital_general_info": "CMS_HOSPITAL_GENERAL_INFO_URL",
    "ipps": "CMS_IPPS_URL",
    "hcahps": "CMS_HCAHPS_URL",
    "provider_utilization": "CMS_PROVIDER_UTILIZATION_URL",
}


def download_csv(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    response = requests.get(url, timeout=120)
    response.raise_for_status()
    destination.write_bytes(response.content)


def stamp_and_save(dataset_name: str, csv_path: Path) -> Path:
    df = pd.read_csv(csv_path, low_memory=False)
    df["source_dataset"] = dataset_name
    df["ingest_timestamp_utc"] = datetime.utcnow().isoformat()
    output_path = SETTINGS.bronze_dir / f"{dataset_name}.parquet"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(output_path, index=False)
    return output_path


def main(offline: bool) -> None:
    for dataset, env_key in DATASETS.items():
        csv_path = SETTINGS.bronze_dir / f"{dataset}.csv"
        url = __import__("os").getenv(env_key, "")
        if not offline:
            if not url:
                raise ValueError(f"Missing URL for {dataset}. Set {env_key}.")
            download_csv(url, csv_path)
        if not csv_path.exists():
            print(f"Skipping {dataset}: no local CSV at {csv_path}")
            continue
        out = stamp_and_save(dataset, csv_path)
        print(f"Bronze written: {out}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest CMS datasets to bronze.")
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Use locally downloaded CSV files in bronze directory.",
    )
    args = parser.parse_args()
    main(offline=args.offline)
