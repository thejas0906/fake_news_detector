
from backend.models import User,News,Token,TokenData
from fastapi import FastAPI,Depends,HTTPException,status,APIRouter
from backend.database import session,engine,get_db
from typing import Annotated
import backend.models_db as models_db
from sqlalchemy.orm import Session
from dotenv import load_dotenv,dotenv_values
from pwdlib import PasswordHash
from fastapi.security import OAuth2PasswordBearer,OAuth2PasswordRequestForm
from fastapi_swagger_dark import install
import fastapi_swagger_dark as fsd
import jwt
import os,uuid
from jwt.exceptions import InvalidTokenError
from datetime import datetime, timedelta, timezone
from backend.functions.auth_functions import get_current_user,authenticate,create_access_token,oauth2_scheme,password_hash
load_dotenv() # laoding the env details from .env
app = FastAPI(docs_url=None)
router = APIRouter()
fsd.install(router)
app.include_router(router)


models_db.Base.metadata.create_all(bind=engine) #used to create all the tables in the db if it does not exist 


users=[User(name='Thejas',email='kickgunther4@gmail.com',password='fastapi09#'),User(name='sakthi',email='sakthi@gmail.com',password='sak0909')]


@app.post("/create_user/")
def create_user(user:User,db:Session=Depends(get_db)):
    l=0
    if user:
        if len(user.password)>3 and len(user.password)<30 :
            l=1
            u=n=s=0
            for i in user.password:
                if i.isupper():
                    u=1
                if i in '!@#&$*^':
                    s=1
                if i.isnumeric():
                    n=1
            if u==0:
                return 'shld contain a uppercase'
            if s==0:
                return 'shld contain !,@,#,&,$,*,^ any of the special characters'
            if n==0:
                return 'shld contain atleast one digit'
        else:
            return 'length to be within 3 and 20 '
        
        if l+u+s+n==4:
                users.append(user)
                user.password=password_hash.hash(user.password)
                db_user=models_db.User(**user.model_dump())
                db.add(db_user)
                db.commit()
                db.refresh(db_user)
                return user
        else:
            raise HTTPException(status_code=404,detail='User Not Added')



@app.post('/token')
def login_for_access_token(form_data: Annotated[OAuth2PasswordRequestForm,Depends()],db:Session=Depends(get_db)) ->Token:

    auth_user=authenticate(form_data.username,form_data.password,db)
    
    if not auth_user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail='Incorrect Password or Username',headers={"WWW-Authenticate": "Bearer"},)
    access_token_expires=timedelta(minutes=int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES")))
    access_token=create_access_token(data={"sub":str(auth_user.user_id)},expires_delta=access_token_expires)
    return Token(access_token=access_token, token_type="bearer")




@app.get('/get-token/')
def get_token_status(token:Annotated[str,Depends(oauth2_scheme)]):
    return {'token':token}
@app.get('/users/me')
def get_all_users(current_user:Annotated[str,Depends(get_current_user)]):
    return current_user
    
