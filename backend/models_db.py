from backend.database import Base
from sqlalchemy import Integer,String,UUID,Float,Column,ForeignKey,text
class User(Base):
    __tablename__='Users'
    user_id=Column(UUID,primary_key=True,index=True,server_default=text("gen_random_uuid()"))
    name=Column(String)
    email=Column(String,unique=True)
    password=Column(String)
class News(Base):
    __tablename__='News'
    news_id=Column(UUID,primary_key=True,index=True)
    user_id=Column(UUID,ForeignKey('Users.user_id'))
    #user=relationship('User')
    news_text=Column(String)
    prediction=Column(String)
    Confidence_value=Column(Float)
    Timestamp=Column(String)

