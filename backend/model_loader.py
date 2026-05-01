import spacy
import gensim.downloader as api
from gensim.models import KeyedVectors
import pickle
from paddleocr import PaddleOCR

wv=None
nlp=None 
clf=None
ocr=None
def loader():
    global wv,nlp,clf,ocr
    wv = KeyedVectors.load('word2vec-google-news-300.kv')
    nlp = spacy.load("en_core_web_lg") 
    model_path = "backend\Models\XGBClassifier_model.pkl"
    ocr = PaddleOCR(use_angle_cls=True, lang='en')
    with open(model_path, 'rb') as file:
        loaded_model = pickle.load(file)
        clf = loaded_model
    return wv,nlp,clf,ocr
