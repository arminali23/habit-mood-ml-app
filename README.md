# Habit Mood ML App

This is a simple self-practice project built to improve my skills in:

- FastAPI backend development
- Machine Learning model training & deployment
- Flutter frontend integration
- End-to-end ML inference pipeline

The application allows users to write short daily text entries and predicts the mood (positive/neutral/negative) using a trained ML model.

---

## Machine Learning

The ML pipeline includes:

- TF-IDF vectorization
- Logistic Regression classifier
- Train/test split evaluation
- Accuracy & F1-macro metrics
- Model persistence using `joblib`
- Inference through FastAPI

The model is trained via:

```bash
python train.py
```
Trained model and metrics are stored locally in:
```bash
backend/models/
```

## Backend (FastAPI) 
  •	POST /predict → returns mood + confidence + class probabilities
	•	POST /entries → saves entry with predicted mood
	•	GET /entries → returns all entries
	•	GET /stats → returns mood distribution (last N days)

  Run Backend
  ```bash
  cd backend
  source .venv/bin/activate
  uvicorn app.main:app --reload
  ```

## Frontend (Flutter)
	•	Sends text to backend
	•	Displays saved entries
	•	Shows basic mood statistics
    cd flutter_app
    flutter run -d chrome

## Tech Stack
•	Python
•	FastAPI
•	SQLAlchemy (SQLite)
•	scikit-learn
•	Flutter
•	HTTP API integration
