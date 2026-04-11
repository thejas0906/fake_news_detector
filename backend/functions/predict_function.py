from sqlalchemy.orm import Session
from fastapi import Depends
from backend.database import get_db
import backend.models_db as models_db
from backend.models import Prediction_Request,News
import pickle
import spacy
import gensim.downloader as api
import numpy as np


def news_store(news:News,db:Session):
    db_news=models_db.News(**news.model_dump())
    db.add(db_news)
    db.commit()
    db.refresh(db_news)
    return news

def predict():
   

    wv = api.load('word2vec-google-news-300')
    nlp = spacy.load("en_core_web_lg") 

    """**Testing it with a news**"""

    model_path = "backend.Models/XGBClassifier_model.pkl"
    with open(model_path, 'rb') as file:
        loaded_model = pickle.load(file)

        clf = loaded_model


    def preprocess_and_vectorize(text):
        doc = nlp(text)

        filtered_tokens = [
            token.lemma_
            for token in doc
            if not token.is_stop and not token.is_punct
        ]

        if len(filtered_tokens) == 0:
            return np.zeros(wv.vector_size)

        return wv.get_mean_vector(filtered_tokens)


    def predict_news(text):
        vector = preprocess_and_vectorize(text)
        vector = vector.reshape(1, -1)

        prediction = clf.predict(vector)[0]

        return "Real" if prediction == 1 else "Fake"



    news_article = input("Enter news: ")
    result = predict_news(news_article)
    print(f"The news article is {result}.")