import os
os.environ["FLAGS_use_mkldnn"] = "0"


import spacy
import gensim.downloader as api
from gensim.models import KeyedVectors
import pickle
import easyocr

wv=None
nlp=None 
clf=None
ocr=None
def loader():
    global wv,nlp,clf,ocr
    wv = KeyedVectors.load('word2vec-google-news-300.kv')
    nlp = spacy.load("en_core_web_lg") 
    model_path = "backend\Models\XGBClassifier_model.pkl"
    ocr=easyocr.Reader(['en'])
    with open(model_path, 'rb') as file:
        loaded_model = pickle.load(file)
        clf = loaded_model
    return wv,nlp,clf,ocr
