import os
import joblib
from typing import Optional, Dict, Any

MODEL_PATH = os.path.join("models", "mood_model.joblib")

_model = None


def load_model():
    global _model
    if _model is not None:
        return _model

    if os.path.exists(MODEL_PATH):
        _model = joblib.load(MODEL_PATH)
        return _model

    return None


def predict_mood(text: str) -> str:
    model = load_model()
    if model is None:
        return "neutral"
    pred = model.predict([text])[0]
    return str(pred)


def predict_with_proba(text: str) -> Dict[str, Any]:
    """
    Returns:
      {
        "label": "...",
        "confidence": 0.xx,
        "probs": {"negative":0.xx, "neutral":0.xx, "positive":0.xx}
      }
    """
    model = load_model()
    if model is None:
        return {
            "label": "neutral",
            "confidence": 0.0,
            "probs": {"neutral": 1.0},
        }

    # Pipeline: model.classes_ is on the classifier step
    clf = model.named_steps.get("clf")
    if clf is None or not hasattr(model, "predict_proba"):
        label = str(model.predict([text])[0])
        return {"label": label, "confidence": 0.0, "probs": {label: 1.0}}

    probs = model.predict_proba([text])[0]  # array
    classes = clf.classes_  # numpy array of class labels

    probs_dict = {str(c): float(p) for c, p in zip(classes, probs)}
    label = max(probs_dict, key=probs_dict.get)
    confidence = float(probs_dict[label])

    return {
        "label": label,
        "confidence": confidence,
        "probs": probs_dict,
    }