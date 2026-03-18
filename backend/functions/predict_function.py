from sqlalchemy.orm import Session
from fastapi import Depends
from backend.database import get_db
import backend.models_db as models_db
from backend.models import Prediction_Request,News



def news_store(news:News,db:Session):
    db_news=models_db.News(**news.model_dump())
    db.add(db_news)
    db.commit()
    db.refresh(db_news)
    return news
