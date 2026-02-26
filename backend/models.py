from pydantic import *
from uuid import UUID,uuid4
class User(BaseModel):
    
    name: str
    email:str
    password:str

class News(BaseModel):
    user_id: UUID
    news_text: str
    prediction:str
    Confidence_value:float
    Timestamp: str
class Token(BaseModel):
    access_token:str
    token_type:str
class TokenData(BaseModel):
    user_id: UUID | None = None

