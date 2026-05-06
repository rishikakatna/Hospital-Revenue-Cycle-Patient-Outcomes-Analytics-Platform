from __future__ import annotations

from pathlib import Path

import joblib
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder

from etl.utils.config import SETTINGS


def main() -> None:
    source = SETTINGS.gold_dir / "model_denial_features.parquet"
    if not source.exists():
        raise FileNotFoundError("Missing model_denial_features.parquet in gold directory.")

    df = pd.read_parquet(source)
    target_col = "denied_flag"
    if target_col not in df.columns:
        raise ValueError(f"Target column {target_col} not found.")

    X = df.drop(columns=[target_col])
    y = df[target_col]

    categorical = X.select_dtypes(include=["object", "category"]).columns.tolist()
    numeric = [c for c in X.columns if c not in categorical]

    preprocessor = ColumnTransformer(
        transformers=[
            ("num", SimpleImputer(strategy="median"), numeric),
            (
                "cat",
                Pipeline(
                    steps=[
                        ("imputer", SimpleImputer(strategy="most_frequent")),
                        ("ohe", OneHotEncoder(handle_unknown="ignore")),
                    ]
                ),
                categorical,
            ),
        ]
    )

    model = LogisticRegression(max_iter=1000, class_weight="balanced")
    clf = Pipeline(steps=[("prep", preprocessor), ("model", model)])

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    clf.fit(X_train, y_train)
    probs = clf.predict_proba(X_test)[:, 1]
    preds = clf.predict(X_test)

    print("Denial Model ROC-AUC:", roc_auc_score(y_test, probs))
    print(classification_report(y_test, preds))

    output = Path("models/denial/denial_model.joblib")
    output.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(clf, output)
    print(f"Saved model to {output}")


if __name__ == "__main__":
    main()
