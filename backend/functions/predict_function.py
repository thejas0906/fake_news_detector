from sqlalchemy.orm import Session
from fastapi import Depends
from backend.database import get_db
import backend.models_db as models_db
from backend.models import Prediction_Request,News
import pickle
import spacy
import gensim.downloader as api
import numpy as np
import backend.model_loader as model_loader
import re
import unicodedata
def news_store(news:News,db:Session):
    db_news=models_db.News(**news.model_dump())
    db.add(db_news)
    db.commit()
    db.refresh(db_news)
    return news


#  IMAGE DETECTION PART - OCR loaded in model_loader.py


def extract_text_from_image(image_path: str) -> str:
    try:
        print("Running EasyOCR...")

        result = model_loader.ocr.readtext(image_path)

        print("OCR result:", result)

        if not result:
            print("No text detected")
            return ""

        # Extract only text
        texts = [item[1] for item in result]

        full_text = " ".join(texts)

        full_text = re.sub(r'\s+', ' ', full_text).strip()

        print("Final extracted text:", full_text)

        return full_text

    except Exception as e:
        print("OCR ERROR:", str(e))
        return ""



def preprocess_news(news: str):

    if not isinstance(news, str):
        return ""

    news = unicodedata.normalize("NFKC", news)
    news = news.lower()
    news = re.sub(r"[\n\r\t]+", " ", news)
    news = news.replace('"', ' ')
    news = re.sub(r"[^\w\s.,!?-]", " ", news)
    news = re.sub(r"\s+", " ", news)
    
    
    return news.strip()
def predict(news:str):
    """**Testing it with a news**"""
    def preprocess_and_vectorize(text):
        doc = model_loader.nlp(text)

        filtered_tokens = [
            token.lemma_
            for token in doc
            if not token.is_stop and not token.is_punct
        ]

        if len(filtered_tokens) == 0:
            return np.zeros(model_loader.wv.vector_size)

        return model_loader.wv.get_mean_vector(filtered_tokens)


    def predict_news(text):
        vector = preprocess_and_vectorize(text)
        vector = vector.reshape(1, -1)

        prediction = model_loader.clf.predict(vector)[0]

        return "Real" if prediction == 1 else "Fake"




    result = predict_news(news)
    return result