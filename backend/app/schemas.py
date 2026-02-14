from pydantic import BaseModel
from datetime import datetime


class EntryCreate(BaseModel):
    text: str
    
class EntryOut(BaseModel):
    id: int
    text: str
    mood: str
    created_at: datetime
    
    class Config: 
        from_attributes = True