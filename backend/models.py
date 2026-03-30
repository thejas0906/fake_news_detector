from pydantic import *
from uuid import UUID,uuid4
from datetime import datetime
class User(BaseModel):
    
    name: str
    email:str
    password:str

class News(BaseModel):
    user_id: UUID
    news_text: str
    prediction:str
    confidence_value:float
    timestamp: datetime
class Token(BaseModel):
    access_token:str
    token_type:str
class TokenData(BaseModel):
    user_id: UUID | None = None
class Prediction_Request(BaseModel):
    input:str
