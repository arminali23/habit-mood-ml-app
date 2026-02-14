import os
import json
import joblib
import pandas as pd
import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    classification_report,
    accuracy_score,
    f1_score,
    confusion_matrix,
)


def main():
    data_path = os.path.join("data", "train.csv")
    if not os.path.exists(data_path):
        raise FileNotFoundError(f"Missing dataset: {data_path}")

    df = pd.read_csv(data_path)
    if "text" not in df.columns or "label" not in df.columns:
        raise ValueError("CSV must have columns: text,label")

    df["text"] = df["text"].astype(str).fillna("")
    df["label"] = df["label"].astype(str).fillna("neutral")

    # Stable class order for probs/metrics
    class_order = ["negative", "neutral", "positive"]
    existing = set(df["label"].unique().tolist())
    class_order = [c for c in class_order if c in existing] + [c for c in sorted(existing) if c not in class_order]

    X_train, X_test, y_train, y_test = train_test_split(
        df["text"],
        df["label"],
        test_size=0.2,
        random_state=42,
        stratify=df["label"] if df["label"].nunique() > 1 else None,
    )

    model = Pipeline(
        steps=[
            ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=1)),
            ("clf", LogisticRegression(max_iter=2000, multi_class="auto")),
        ]
    )

    model.fit(X_train, y_train)

    preds = model.predict(X_test)

    acc = float(accuracy_score(y_test, preds))
    f1_macro = float(f1_score(y_test, preds, average="macro"))
    labels_for_report = class_order
    report = classification_report(y_test, preds, labels=labels_for_report, output_dict=True, zero_division=0)

    cm = confusion_matrix(y_test, preds, labels=labels_for_report)
    cm_list = cm.astype(int).tolist()

    print(f"Accuracy: {acc:.4f}")
    print(f"F1-macro: {f1_macro:.4f}")
    print(classification_report(y_test, preds, labels=labels_for_report, zero_division=0))

    os.makedirs("models", exist_ok=True)

    model_path = os.path.join("models", "mood_model.joblib")
    joblib.dump(model, model_path)
    print(f"Saved: {model_path}")

    metrics = {
        "accuracy": acc,
        "f1_macro": f1_macro,
        "labels": labels_for_report,
        "confusion_matrix": cm_list,
        "classification_report": report,
        "num_train": int(len(X_train)),
        "num_test": int(len(X_test)),
    }

    metrics_path = os.path.join("models", "metrics.json")
    with open(metrics_path, "w", encoding="utf-8") as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)

    print(f"Saved: {metrics_path}")


if __name__ == "__main__":
    main()