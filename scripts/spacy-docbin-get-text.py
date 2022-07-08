#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Feed spacy-docbin-get-text.py a spacy docbin file (or directory) and it will output the texts
(optionally cleaned a bit).

Useful to extract cleaned text from a docbin corpus for topic modelling or ngram splitting (stuff like that).

Example usage:
spacy-docbin-get-text.py --input ./build/docbins > outputtextfromwholedirectory.txt
spacy-docbin-get-text.py --input ./build/docbins/myannotations.spacy --clean > cleanedtextfromsinglefile.txt
"""
from __future__ import print_function

import os, glob, html, re

import fileinput
import argparse
import spacy
from spacy.tokens import DocBin
from nltk import ngrams
import pandas as pd
import numpy as np


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


def main(fpath, model: str = 'en_core_web_sm', clean: bool = True):
    # List of special case words. English only.
    # Add lower case variations and add Spacy tokenizer special cases.
    if model != 'ja_core_news_sm':
        specialcases = ['5G', 'blood-letting']
        specialcases += ([w.lower() for w in specialcases if w.lower() not in specialcases])
        specialcases = {w: [{'ORTH': w}] for w in specialcases}
        for key, val in specialcases.items():
            nlp.tokenizer.add_special_case(key, val)
    
    # Convert @fpath to a list of files (even if it is a single file or a directory)
    inputfiles = []
    if os.path.isfile(fpath): 
        inputfiles.append(fpath)

    elif os.path.isdir(fpath):
        inputfiles = sorted(glob.glob(os.path.join(fpath, '*.spacy')))

    # Process all the inputfiles
    for filename in inputfiles:
        indocbin = DocBin().from_disk(filename)
        
        for doc in indocbin.get_docs(nlp.vocab):
            if clean:
                print(cleanTweet(doc.text))
            else:
                print(doc.text)
    
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract text from a Spacy docbin")
    parser.add_argument('-i', '--input', dest='input', required=True, help='Single file or directory of files. Must be Spacy Docbins (.spacy)')
    parser.add_argument('-c', '--clean', dest='clean', action='store_true', help='Preprocess and return cleaned text')
    parser.add_argument('-nc', '--no-clean', dest='clean', action='store_false', help='Return raw text')
    parser.set_defaults(clean=True)
    
    parser.add_argument('-m', '--model', dest='model', type=str,
                    default='en_core_web_sm', required=False,
                    help='Path to a Spacy model file (defaults to "en_core_web_sm")')
    args = parser.parse_args()


    nlp = spacy.load(args.model, disable=['tok2vec', 'ner', 'parser'])  # local global var
    main(fpath=args.input, model=args.model, clean=args.clean)
