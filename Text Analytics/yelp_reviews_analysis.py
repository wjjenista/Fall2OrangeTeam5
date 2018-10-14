# -*- coding: utf-8 -*-
"""
Created on Sun Oct 14 07:52:05 2018

@author: Melissa Sandahl
"""

import pandas as pd

#Import yelp reviews, already filtered for Charlotte restaurant
# reviews containing "park" in the review text
reviews = pd.read_csv('yelp_nc_parking_reviews.csv')

# Look at first few rows, check names of the columns
reviews.head()
reviews.dtypes.index

#Add a column of the word count for each review
reviews['word_count'] = reviews['text'].apply(lambda x: len(str(x).split(" ")))
reviews[['text','word_count']].head()

#Add a column of the character count for each review, note this includes spaces
reviews['char_count'] = reviews['text'].str.len() 
reviews[['text','char_count']].head()

#Calculate the average length of a word in the review, add as a column
def avg_word(sentence):
  words = sentence.split()
  return (sum(len(word) for word in words)/len(words))

reviews['avg_word'] = reviews['text'].apply(lambda x: avg_word(x))
reviews[['text','avg_word']].head()


#Count number of stop words, add as a column
import nltk as nltk
#nltk.download('stopwords')
stop = nltk.corpus.stopwords.words( 'english' )

reviews['stopwords'] = reviews['text'].apply(lambda x: len([x for x in x.split() if x in stop]))
reviews[['text','stopwords']].head()

#Calculate number of words in all uppercase
reviews['upper'] = reviews['text'].apply(lambda x: len([x for x in x.split() if x.isupper()]))
reviews[['text','upper']].head()


#Processing Steps#####################################

#Convert to all lowercase
reviews['text'] = reviews['text'].apply(lambda x: " ".join(x.lower() for x in x.split()))
reviews['text'].head()


#Remove punctuation
reviews['text'] = reviews['text'].str.replace('[^\w\s]','')
reviews['text'].head()

#Remove stopwords
reviews['text'] = reviews['text'].apply(lambda x: " ".join(x for x in x.split() if x not in stop))
reviews['text'].head()

#Look for most frequent words
freq = pd.Series(' '.join(reviews['text']).split()).value_counts()[:10]
freq

#Correct spelling using Textblob
# This took too long
from textblob import TextBlob
#reviews['text'].apply(lambda x: str(TextBlob(x).correct()))

#Tokenize into a separate column called token
#nltk.download('punkt')
reviews['token']=reviews['text'].apply(nltk.word_tokenize)
reviews['token'].head()

#Stemming
from nltk.stem import PorterStemmer
st = PorterStemmer()
reviews['token']=reviews['token'].apply(lambda x : [st.stem(y) for y in x])
reviews['token'].head()

#export to csv
reviews.to_csv('yelp_reviews_stemmed.csv')

#if starting from stemmed csv file
#reviews = pd.read_csv('yelp_reviews_stemmed.csv')


#TF-IDF with sci-kit learn
from sklearn.feature_extraction.text import TfidfVectorizer
v = TfidfVectorizer()
tf_idf = v.fit_transform(reviews['text'])
# what to do with the TF-IDF matrix???

#Sentiment analysis using TextBlob
reviews['sentiment'] = reviews['text'].apply(lambda x: TextBlob(x).sentiment[0] )
reviews[['text','sentiment']].head()

#export to csv
reviews.to_csv('yelp_reviews_sentiment.csv')

#Plot sentiment vs star rating
reviews.boxplot('sentiment', by='stars')
