from __future__ import annotations

import pandas as pd
from statsmodels.tsa.arima.model import ARIMA

from etl.utils.config import SETTINGS


def main() -> None:
    source = SETTINGS.gold_dir / "patient_volume_timeseries.parquet"
    if not source.exists():
        raise FileNotFoundError("Missing patient_volume_timeseries.parquet in gold directory.")

    df = pd.read_parquet(source)
    if not {"date", "patient_volume"}.issubset(df.columns):
        raise ValueError("Input must include date and patient_volume columns.")

    ts = (
        df.assign(date=pd.to_datetime(df["date"]))
        .sort_values("date")
        .set_index("date")["patient_volume"]
        .asfreq("MS")
        .ffill()
    )

    model = ARIMA(ts, order=(1, 1, 1))
    result = model.fit()
    forecast = result.forecast(steps=12)
    output = forecast.reset_index()
    output.columns = ["forecast_month", "forecast_patient_volume"]

    out_path = SETTINGS.gold_dir / "patient_volume_forecast.parquet"
    output.to_parquet(out_path, index=False)
    print(f"Saved 12-month forecast: {out_path}")


if __name__ == "__main__":
    main()
