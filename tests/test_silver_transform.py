import pandas as pd

from etl.silver.transform_silver import clean_common


def test_clean_common_fills_missing_values():
    df = pd.DataFrame(
        {
            "Provider ID": ["12345", None],
            "Numeric Col": [1.0, None],
            "Text Col": ["x", None],
        }
    )
    out = clean_common(df)
    assert out["text_col"].iloc[1] == "Unknown"
    assert out["numeric_col"].isna().sum() == 0
