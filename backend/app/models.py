from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from .db import Base

class Entry(Base):
    __tablename__ = "entries"
    
    id = Column(Integer, primary_key=True, index=True)
    text = Column(String, nullable=False)
    mood = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)