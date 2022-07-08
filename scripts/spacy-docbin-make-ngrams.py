#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Feed spacy-docbin-make-ngrams.py a directory of spacy docbins, and it will generate unigrams and
bigrams CSV files.

Example usage:
spacy-docbin-make-ngrams.py --inputdir ./build/docbins --outputdir ./build
"""
from __future__ import print_function

import os, glob, html, re

import fileinput
import argparse
import spacy
import spacymoji
from spacy.tokens import DocBin
from nltk import ngrams
import pandas as pd
import numpy as np

from tqdm import tqdm


def cleanTweet(txt):
    '''
    The third cleantweet function in our project.
    This version:
        - allows 2 letter words
        - URL's, and punctuation are removed
        - @user mentions are removed
        - whitespace is deduplicated
        - Hash # is removed as prefx and ignored because oftentimes this is used in the middle of sentences.
     
    The NLP tokeniser has also been customised with a few common patterns which appear in our corpus.
    '''
    # Replace ampersand '&amp;' and other encoded chars
    tweet = html.unescape(txt)

    # @src: the perfect URL regex: https://www.urlregex.com/
    tweet = re.sub(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+', '', tweet, flags=re.MULTILINE)

    # Remove @user mentions
    tweet = re.sub(r'[@]\w+[^\b\s]', '', tweet, flags=re.MULTILINE)

    # Remove various punctuations and empty space
    tweet = re.sub(r'[#!,«‹›»<>~•@£$%^&)“"”`‘\'\’\/\+\-\:\ー\+\(\)\=\*\?]', '', tweet, flags=re.MULTILINE) # various chars
    tweet = re.sub(r'\.+\s', ' ', tweet, flags=re.MULTILINE) # end of sentence full stop
    tweet = re.sub(r'(.)\.(.)', r'\1\2', tweet, flags=re.MULTILINE) # remove full stop inbetween characters
    tweet = re.sub(r'[\r\n]+?', ' ', tweet, flags=re.MULTILINE) # remove newlines
    tweet = re.sub(r'^ +| +$| +', ' ', tweet, flags=re.MULTILINE) # remove remaining duplicate space chars
    
    doc = nlp(tweet)
    tweet = (' '.join([token.text for token in doc 
                       if (len(token.text) > 1 and len(token.text) < 20)
                       and token.is_stop == False and token.is_punct == False]).lower())
    
    return tweet


def pmi(dff, x, y):
    '''
    Calculate the Pointwise Mutual Information measure of the dataframe.
    If you have a frequency table already, it's necessary to deaggregate your data before using this function.
    @see https://stackoverflow.com/a/67714452
    @see https://stackoverflow.com/a/35852752
    '''
    df = dff.copy()
    df['f_x'] = df.groupby(x)[x].transform('count')
    df['f_y'] = df.groupby(y)[y].transform('count')
    df['f_xy'] = df.groupby([x, y])[x].transform('count')
    df['pmi'] = np.log(len(df.index) * df['f_xy'] / (df['f_x'] * df['f_y']) )
    df = df.drop_duplicates()
    return df



def main(inputdir, outputdir, trim, model: str, clean: bool = True):
    # List of special case words. English only.
    # Add lower case variations and add Spacy tokenizer special cases.
    if model != 'ja_core_news_sm':
        specialcases = ['5G', 'blood-letting']
        specialcases += ([w.lower() for w in specialcases if w.lower() not in specialcases])
        specialcases = {w: [{'ORTH': w}] for w in specialcases}
        for key, val in specialcases.items():
            nlp.tokenizer.add_special_case(key, val)
        
    # ======
    # Generate unigrams and bigrams lists for a list of strings
    unigramsdfs = []
    bigramsdfs = []
    
    # Check output dir exists
    os.makedirs(outputdir, exist_ok=True)

    for filename in tqdm(sorted(glob.glob(os.path.join(inputdir, '*.spacy'))), position=0, desc='docbins', leave=False):
        date = os.path.basename(filename).split('.')[0][-10:]  # get date from filename. It's always there!
        unigrams = []
        bigrams= []
        indocbin = DocBin().from_disk(filename)
        
        for doc in tqdm(list(indocbin.get_docs(nlp.vocab)), position=1, desc='docs   ', leave=False):
            if clean:
                words = cleanTweet(doc.text).split(' ')
            else:
                words = doc.text.split(' ')

            unigrams.extend(words)
            bigrams.extend(ngrams(words, 2))
        
        
        udf = pd.DataFrame.from_dict({'date': date, 'word': unigrams})
        udf = udf.value_counts(['date', 'word']).reset_index(name='frequency')
        unigramsdfs.append(udf)

        bdf = pd.DataFrame.from_dict({'date': date, 'words': bigrams})
        bdf = bdf.value_counts(['date', 'words']).reset_index(name='frequency')
        bigramsdfs.append(bdf)


    # Unigrams
    df = pd.concat(unigramsdfs, ignore_index=True)
    df = df.set_index('date').sort_index()
    df = df[df.frequency > trim]
    df.to_csv(os.path.join(outputdir, 'unigrams.csv.gz'), compression='gzip')
    
    # Bigrams - prepare dataframe, split words into x,y columns and re-duplicate rows
    df = pd.concat(bigramsdfs, ignore_index=True)
    df['x'] = df['words'].str[0]
    df['y'] = df['words'].str[1]
    del df['words']
    df = pd.DataFrame(np.repeat(df.values, df.frequency.astype(int),axis=0), columns=df.columns)
    del df['frequency']
    df = df.set_index('date').sort_index()
    
    # Calculate PMI metrics for bigrams across entire timeseries and save
    df = pmi(df, 'x', 'y')
    df = df[df.f_xy > trim]
    df.to_csv(os.path.join(outputdir, 'bigrams.csv.gz'), compression='gzip')
    
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Filter a Spacy docbin by the label and threshold, outputting another docbin")
    parser.add_argument('-i', '--inputdir', metavar='INFILE', required=True, help='File to read. Must be Spacy Docbin (.spacy)')
    parser.add_argument('-o', '--outputdir', metavar='OUTFILE', required=True, help='Output docbin')
    parser.add_argument('-n', '--trim', metavar='trim', required=False, default=4, type=int, help='Trim ngrams greater than N (default: 4)')
    parser.add_argument('-c', '--clean', dest='clean', action='store_true', help='Preprocess and return cleaned text')
    parser.add_argument('-nc', '--no-clean', dest='clean', action='store_false', help='Return raw text')
    parser.set_defaults(clean=True)
    parser.add_argument('-m', '--model', dest='model', type=str,
                    default='en_core_web_sm', required=False,
                    help='Path to the Spacy model file (defaults to "en_core_web_sm")')
    args = parser.parse_args()
    
    nlp = spacy.load(args.model)  # scope the nlp for the whole script
    nlp.add_pipe("emoji", first=True)  # treat emoji as full word/tokens
    
    main(inputdir=args.inputdir, outputdir=args.outputdir, trim=args.trim, model=args.model, clean=args.clean)