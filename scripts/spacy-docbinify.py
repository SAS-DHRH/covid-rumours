#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Feed spacy-docbinify.py a JSONL (or DocBin) file and it will run the data
through the Spacy model you specify, and save the results into the output docbin file.

If the --overwrite argument is provided, this will overwrite and update the input file
after running the documents through the model (only valid if input is a DocBin)

Example usage:
spacy-docbinify.py --input tweets.jsonl --output tweets-docbin.spacy --model './my-custom-spacy-model'
spacy-docbinify.py --input tweets-docbin.spacy --overwrite --model './my-custom-spacy-model' 

"""
from __future__ import print_function

import sys, os, json, argparse, gzip
import spacy
from spacy.tokens import DocBin


def get_tweets_from_file(f):
    for line in f.readlines():
        yield json.loads(line)


def get_tweet_text(t):
    return (t.get('full_text') or t.get('extended_tweet', {}).get('full_text') or t['text']).replace('\n', ' ')


def main(infile, outfile = None, overwrite: bool = False, model: str = 'en_core_web_sm'):
    nlp = spacy.load(model)  # load the model
    doc_bin = DocBin(store_user_data=True)  # init the bin (NB: preserve user data!) 
    
    # Re-open infile if it's gzipped (argparse opens infile as text wrapper already)
    if (os.path.splitext(infile.name)[1] == '.gz'):
        infile = gzip.open(infile.name, mode='rt')
    
    
    # If infile is a .spacy docbin already, open it and pass Docs through the pipeline
    if (os.path.splitext(infile.name)[1] == '.spacy'):
        doc_bin = doc_bin.from_disk(infile.name)
        pipe_component = nlp.get_pipe(nlp.pipe_names[-1])  # get last pipeline component
        for doc in pipe_component.pipe(doc_bin.get_docs(nlp.vocab), batch_size=50):
            pass

    # else, load the json into docbin and run through the pipeline
    else:
        with infile:
            for t in get_tweets_from_file(infile):
                doc = nlp(get_tweet_text(t))
                doc.user_data['id_str'] = t['id_str']
                doc.user_data['created_at'] = t['created_at']
                doc_bin.add(doc)

    # Now, save the results
    if overwrite:
        infile.close()
        doc_bin.to_disk(infile.name)
    else:
        doc_bin.to_disk(outfile.name)
    
                   
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a Spacy DocBin from input files and run the documents through a Spacy model. This is useful for entity detection or classifying and saving the results to disk.")
    parser.add_argument('-i', '--infile', type=argparse.FileType('r'), metavar='INFILE', required=True,
                        help='File to read. Must be JSONL (.jsonl, or zipped jsonl.gz) or a Spacy DocBin (.spacy)')
    
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-o', '--outfile', type=argparse.FileType('w'), metavar='OUTFILE',required=False,
                        help='Output files. If empty, you need to use --overwrite')
    group.add_argument('--overwrite', action='store_true', dest='overwrite',
                        help='Overwrite input file (only works if input file is already a Spacy DocBin)')
    
    parser.add_argument('-m', '--model', dest='model', type=str,
                        default='en_core_web_sm', required=False,
                        help='Path to the Spacy model file (defaults to "en_core_web_sm")')
    args = parser.parse_args()
    
    # If overwrite is used, check infile is a spacy DocBin
    if (args.overwrite and os.path.splitext(args.infile.name)[1] != '.spacy'):
        parser.error(message='You can only --overwrite an input file which is a .spacy docbin')
    
    main(args.infile, outfile=args.outfile, overwrite=args.overwrite, model=args.model)