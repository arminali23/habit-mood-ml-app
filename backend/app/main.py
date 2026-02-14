from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from collections import Counter
from .db import Base, engine, get_db
from .models import Entry
from .schemas import EntryCreate, EntryOut
from .ml import load_model, predict_mood, predict_with_proba


app = FastAPI(title="Habit Mood App Backend")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup():
    Base.metadata.create_all(bind=engine)
    load_model()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict")
def predict(payload: EntryCreate):
    return predict_with_proba(payload.text)


@app.post("/entries", response_model=EntryOut)
def create_entry(payload: EntryCreate, db: Session = Depends(get_db)):
    mood = predict_mood(payload.text)
    entry = Entry(text=payload.text, mood=mood)
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@app.get("/entries", response_model=list[EntryOut])
def list_entries(db: Session = Depends(get_db)):
    return db.query(Entry).order_by(Entry.created_at.desc()).all()


@app.get("/stats")
def stats(days: int = 7, db: Session = Depends(get_db)):
    since = datetime.utcnow() - timedelta(days=days)

    rows = (
        db.query(Entry.mood)
        .filter(Entry.created_at >= since)
        .all()
    )

    moods = [r[0] for r in rows]
    counts = Counter(moods)

    return {
        "days": days,
        "positive": counts.get("positive", 0),
        "neutral": counts.get("neutral", 0),
        "negative": counts.get("negative", 0),
        "total": len(moods),
    }