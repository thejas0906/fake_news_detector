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

def news_store(news:News,db:Session):
    db_news=models_db.News(**news.model_dump())
    db.add(db_news)
    db.commit()
    db.refresh(db_news)
    return news


#  IMAGE DETECTION PART - OCR loaded in model_loader.py


def extract_text_from_image(image_path: str) -> str:
    result = model_loader.ocr.ocr(image_path, cls=True)

    if not result or result[0] is None:
        return ""

    lines = []

    for line in result[0]:
        bbox = line[0]
        text = line[1][0]
        confidence = line[1][1]

        # Filter low-confidence text
        if confidence > 0.7:
            y_coord = bbox[0][1]
            lines.append((y_coord, text))

    # Sort top → bottom
    lines.sort(key=lambda x: x[0])          # sorted in ordr of pixels so as to maintain order of snetences

    full_text = " ".join([t for _, t in lines])           # joining into a single string sep.ted by space and leaving out the y-coordinate("_")
    full_text = re.sub(r'\s+', ' ', full_text).strip()          # removing extra spaces and newlines

    return full_text




import re
import unicodedata

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