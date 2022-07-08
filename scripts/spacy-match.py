#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Feed spacy-match.py your JSON and get tweets which match the input patterns.
Optionally add Spacy custom patterns (to, eg. add exclusions)

Example usage:
spacy-match.py tweets.jsonl --patterns matchwords.jsonl --excludes excludes.jsonl > matched_tweets.jsonl
- 
"""
from __future__ import print_function

import sys
import json
import fileinput
import argparse

import spacy
from spacy.matcher import Matcher
import json

nlp = spacy.load("en_core_web_sm")
matcher = Matcher(nlp.vocab, validate=True)
excluder = Matcher(nlp.vocab, validate=True)


def text(t):
    return (t.get('full_text') or t.get('extended_tweet', {}).get('full_text') or t['text']).replace('\n', ' ')


def load_spacy_patterns(filepath):
    data = filepath.readlines()
    data = [json.loads(item) for item in data]
    data = [item['pattern'] for item in data]
    return data


def main(files, patternsfile, excludesfile=None):
    patterns = load_spacy_patterns(patternsfile)
    matcher.add('MATCHIDENT', patterns)
    
    if excludesfile:
        excludes = load_spacy_patterns(excludesfile)
        excluder.add('EXCLUDERULES', excludes)
    
    lines = fileinput.input(files)
    for line in lines:
        tweet = json.loads(line)
        doc = nlp(text(tweet))
        matches = matcher(doc)
        if matches:
            if excludesfile:
                excl = excluder(doc)
                # If the exclude patterns match, the doc is rejected.
                if not excl:
                    print(json.dumps(tweet))
            else:
                print(json.dumps(tweet))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="filter tweets by Spacy match pattern file")
    parser.add_argument('files',
                        metavar='FILES', nargs='*', default=['-'], type=argparse.FileType('r'),
                        help='files to read, if empty, stdin is used')
    parser.add_argument('-p', '--patterns', dest='patternsfile', type=argparse.FileType('r'),
                        help='Path to the patterns jsonl file', required=True)
    parser.add_argument('-e', '--excludes', dest='excludesfile', type=argparse.FileType('r'),
                        help='Path to the excludes/additional Spacy patterns jsonl file', required=False)
    args = parser.parse_args()
    
    main(args.files, args.patternsfile, args.excludesfile)