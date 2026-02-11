from models import User,News
from fastapi import FastAPI
app=FastAPI()
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

    
