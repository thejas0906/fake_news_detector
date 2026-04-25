from typing import Annotated,Optional
from backend.models import TokenData
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordBearer,OAuth2PasswordRequestForm
import jwt,os,uuid
from jwt.exceptions import InvalidTokenError
from datetime import datetime, timedelta, timezone
from pwdlib import PasswordHash
from fastapi import Depends,HTTPException,status
from backend.database import get_db
import backend.models_db as models_db
from backend.models_db import PasswordResetOTP
import random
import string
from backend.config import settings

#from passlib.context import CryptContext
SECRET_KEY=os.getenv("SECRET_KEY")
ALGORITHM=os.getenv("ALGORITHM")
PASSWORD_RESET_SECRET_KEY=os.getenv("PASSWORD_RESET_SECRET_KEY")
OTP_EXPIRY_MINUTES=os.getenv("OTP_EXPIRY_MINUTES")
#pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme=OAuth2PasswordBearer(tokenUrl='login')
password_hash=PasswordHash.recommended() #intitalizes the hashing algorithmns bcrypt and argon2
def get_current_user(token:Annotated[str,Depends(oauth2_scheme)],db:Session=Depends(get_db)):
    
    credential_exception=HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},)
    try:
        payload=jwt.decode(token,SECRET_KEY,algorithms=ALGORITHM)
        user_id=uuid.UUID(payload.get('sub'))
        if user_id is None:
            raise credential_exception
        token_data=TokenData(user_id=user_id)
    except  InvalidTokenError:
        raise credential_exception
    user=get_user_by_userid(token_data.user_id,db)
    if user is None:
        raise credential_exception
    return user
    
def verify_password(password:str,hashedpass:str):
    return password_hash.verify(password,hashedpass)
def get_user_by_userid(user_id:uuid.UUID,db:Session):
    return db.query(models_db.User).filter((models_db.User.user_id)==user_id).first()
def get_user_by_email(email:str,db:Session):
    return db.query(models_db.User).filter((models_db.User.email)==email).first()
def authenticate(email:str,password:str,db:Session):
    user=get_user_by_email(email.lower(),db)
    if not user:
        #verify_password(password,'dummy')   ### this part is done even if the password stuff is wrong it will take same time to return op
        return False
    if not verify_password(password,user.password):
        return False
    return user
#creates token for the user
def create_access_token(data:dict,expires_delta:timedelta|None=None):
    to_encode=data.copy()
    if expires_delta:
        expire=datetime.now(timezone.utc)+expires_delta
    else:
        expire=datetime.now(timezone.utc)+timedelta(minutes=15)
    to_encode.update({'exp': expire})
    encode_jwt=jwt.encode(to_encode,SECRET_KEY,algorithm=ALGORITHM)
    return encode_jwt


# def create_reset_password_token(email:str):
#     data={"sub":email,"exp":datetime.utcnow() + timedelta(minutes=10)}
#     token=jwt.encode(data,PASSWORD_RESET_SECRET_KEY,ALGORITHM)
#     return token

# def decode_reset_password_token(token: str):
#     try:
#         payload = jwt.decode(token, settings.FORGET_PASSWORD_SECRET_KEY,
#                    algorithms=[settings.ALGORITHM])
#         email: str = payload.get("sub")
#         return email
#     except JWTError:
#         return None 

def generate_otp(length: int = 6) -> str:
    return ''.join(random.choices(string.digits, k=length))

def create_otp_for_email(email: str, db: Session) -> str:
    """
    Invalidates any existing OTPs for this email,
    then creates a fresh one in the DB.
    """
    # Invalidate old OTPs for this email
    db.query(PasswordResetOTP).filter(
        PasswordResetOTP.email == email,
        PasswordResetOTP.is_used == False
    ).update({"is_used": True})
    db.commit()

    # Create new OTP
    otp = generate_otp()
    otp_record = PasswordResetOTP(
        email=email,
        otp=otp,
        expires_at=datetime.utcnow() + timedelta(minutes=int(settings.reset_token_expire_minutes)),
        is_used=False
    )
    db.add(otp_record)
    db.commit()
    return otp

def verify_otp_for_email(email: str, otp: str, db: Session) -> bool:
    """
    Checks if OTP is valid, not expired, and not already used.
    Marks it as used on success.
    """
    record = db.query(PasswordResetOTP).filter(
        PasswordResetOTP.email == email,
        PasswordResetOTP.otp == otp,
        PasswordResetOTP.is_used == False
    ).first()

    if not record:
        return False

    if datetime.utcnow() > record.expires_at:
        record.is_used = True  # Mark expired OTP as used
        db.commit()
        return False

    # Valid — mark as used (single use)
    record.is_used = True
    db.commit()
    return True
