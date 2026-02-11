from sqlalchemy import Column,Integer,Float,String,Boolean,DateTime,UUID
from database import Base
class News_db(Base):
    __tablename__='News_data'
    user_id =Column(UUID,foreign_key=True,index=True) #change the datatype of this column to random UUID datatype
    news_text=Column(String)
    prediction=Column(String)
    confidence_value=Column(Float)
    Timestamp=Column(DateTime)
class User_db(Base):
    user_id=Column(UUID,primary_key=True,index=True)
    name=Column(String)
    password=Column(String)
    email=Column(String)
    
