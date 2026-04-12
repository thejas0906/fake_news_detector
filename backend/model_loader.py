import spacy
import gensim.downloader as api
import pickle
wv=None
nlp=None 
clf=None
def loader():
    global wv,nlp,clf
    wv = api.load('word2vec-google-news-300')
    nlp = spacy.load("en_core_web_lg") 
    model_path = "backend\Models\XGBClassifier_model.pkl"
    with open(model_path, 'rb') as file:
        loaded_model = pickle.load(file)
        clf = loaded_model
    return wv,nlp,clf
