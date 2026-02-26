from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from dotenv import load_dotenv,dotenv_values
import os
load_dotenv()
def get_db():
    db=session()
    try:
        yield db
    finally:
        db.close()
engine=create_engine(os.getenv("db_url"))
session=sessionmaker(autocommit=False,autoflush=False,bind=engine)
Base=declarative_base()