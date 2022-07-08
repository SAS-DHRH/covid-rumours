#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Feed spacy-docbin-textcat.py a spacy docbin file and get only the documents which match 
the input label threshold.

Example usage:
spacy-docbin-textcat.py --input tweets.docbin --output outweets.docbin --label CONSPIRACY --threshold 0.75

Requires user data and preclassified docbins (i.e. rona rumours docbins)
"""
from __future__ import print_function

import os
import fileinput
import argparse
import spacy
from spacy.tokens import DocBin


def main(infile, outfile, label, threshold):            
    nlp = spacy.blank("en") # load a model
    
    indocbin = DocBin().from_disk(infile)
    outdocbin = DocBin(store_user_data=True)  # init the bin (NB: preserve user data!) 

    for doc in indocbin.get_docs(nlp.vocab):
        # Assume TWEETSCRUFF at 0.75
        if (doc.cats['TWEETSCRUFF'] > 0.75) & (doc.cats[label] >= threshold):
            outdocbin.add(doc)

    # Now, save the results
    os.makedirs(os.path.dirname(outfile), exist_ok=True)
    outdocbin.to_disk(outfile)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Filter a Spacy docbin by the label and threshold, outputting another docbin")
    parser.add_argument('-i', '--infile', metavar='INFILE', required=True, help='File to read. Must be Spacy Docbin (.spacy)')
    parser.add_argument('-o', '--outfile', metavar='OUTFILE', required=True, help='Output docbin')
    parser.add_argument('-l', '--label', dest='label', type=str, required=True, help='Label/cat to threshold match')
    parser.add_argument('-t', '--threshold', dest='threshold', type=float, required=False, default='0.75',
                        help='Threshold for category match (default 0.75)')
    args = parser.parse_args()
    
    
    main(infile=args.infile, outfile=args.outfile, label=args.label, threshold=args.threshold)