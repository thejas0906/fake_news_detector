from pydantic import *
from uuid import UUID,uuid4
class User(BaseModel):
    user_id:UUID= Field(default_factory=uuid4)
    name: str
    email:str
    password:str

class News(BaseModel):
    user_id: UUID
    news_text: str
    prediction:str
    Confidence_value:float
    Timestamp: str

