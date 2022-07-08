#!/bin/bash


echo "filename, texts, noretweets, engtweets, oldscruff, newscruff"

for f in *.gz
do

numlines=`cat ~/Data/rona-rumours/data/alpha/build/texts/${f%.gz} | wc -l`
norewteets=`gzcat ~/Data/rona-rumours/data/alpha/build/noretweets/${f%} | wc -l`
engtweets=`gzcat ~/Data/rona-rumours/data/alpha/build/noretweets-en/${f%} | wc -l`

oldscruff=`gzcat ${f%} | wc -l`
newscruff=`gzcat ~/Data/rona-rumours/build/noscruff/${f%} | wc -l`

echo ${f}, "$numlines", "$norewteets", "$engtweets", "$oldscruff", "$newscruff"

done
