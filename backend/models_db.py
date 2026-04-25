from backend.database import Base
from sqlalchemy import Integer,String,UUID,Float,Column,ForeignKey,text,DateTime,Boolean,DateTime
from datetime import datetime
class User(Base):
    __tablename__='Users'
    user_id=Column(UUID,primary_key=True,index=True,server_default=text("gen_random_uuid()"))
    name=Column(String)
    email=Column(String,unique=True)
    password=Column(String)
class News(Base):
    __tablename__='News'
    news_id=Column(UUID,primary_key=True,index=True,server_default=text("gen_random_uuid()"))
    user_id=Column(UUID,ForeignKey('Users.user_id',ondelete='CASCADE',onupdate='CASCADE'))
    #user=relationship('User')
    news_text=Column(String)
    prediction=Column(String)
    confidence_value=Column(Float)
    timestamp=Column(DateTime)

class PasswordResetOTP(Base):
    __tablename__ = "password_reset_otps"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, nullable=False, index=True)
    otp = Column(String(6), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    is_used = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

