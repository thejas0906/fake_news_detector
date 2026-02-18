
from backend.models import User,News
from fastapi import FastAPI,Depends
from backend.database import session,engine
from typing import Annotated
import backend.models_db as models_db
from sqlalchemy.orm import Session
from fastapi import HTTPException
from pwdlib import PasswordHash
from fastapi.security import OAuth2PasswordBearer,OAuth2PasswordRequestForm

app=FastAPI()
models_db.Base.metadata.create_all(bind=engine)
SECRETE_KEY="c713a839cddfd699377579fb70b97a530b39a75da3906b3837d9bbe4cec19c12"
ALGORITHM="HS256"
ACCESS_TOKEN_EXPIRE_MINUTES=30
oauth2_scheme=OAuth2PasswordBearer(tokenUrl='token')
users=[User(name='Thejas',email='kickgunther4@gmail.com',password='fastapi09#'),User(name='sakthi',email='sakthi@gmail.com',password='sak0909')]

@app.post("/create_user/")
def create_user(user:User):
    l=0
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
        return user

def get_db():
    db=session()
    try:
        yield db
    finally:
        db.close()


        
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
                db_user=models_db.User(**user.model_dump())
                db.add(db_user)
                db.commit()
                db.refresh(db_user)
                return user
        else:
            raise HTTPException(status_code=404,detail='product not added')
    
def fake_decode_token(token):
    return User(name='Ragav',email='ragav123456@gmail.com',password='ragav@123')
def get_user(token:Annotated[str,Depends(oauth2_scheme)]):
    user=fake_decode_token(token)
    return user
# @app.get('/login/')
# def login(gmail:str,password:str,db:Session=Depends(get_db)):
#     auth_user=db.query(models_db.User).filter(models_db.User.user_id)




@app.get('/get-token/')
def get_token_status(token:Annotated[str,Depends(oauth2_scheme)]):
    return {'token':token}
@app.get('/get_all_users/')
def get_all_users(current_user:Annotated[str,Depends(get_user)]):
    return current_user
    
