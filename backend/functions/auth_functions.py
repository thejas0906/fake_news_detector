from typing import Annotated
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
SECRET_KEY=os.getenv("SECRET_KEY")
ALGORITHM=os.getenv("ALGORITHM")
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
    user=get_user_by_email(email,db)
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
    