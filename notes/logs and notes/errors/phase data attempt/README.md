### These old Phase scripts

These old phase scripts were written in 2020 and run to collect data about the deletion frequencies of the corpus alpha. Unfortunately, these do not gather accurate information due to the way twitter responds with HTTP status codes.

Please see the corpus alpha Makefile target's `deleted-reasons` and `deleted-tweets` for the most accurate method of collecting the phase data.

*Marty Steer, 2021-09*



### Jq command line utility bug
*2020-11-03, MS*

I have discovered that the command line utility 'jq' does not handle large integers very well, so when extracting the .id from the twitter json it truncates the number! I've been using .id in the makefile to extract values into CSV and text files. This is a known jq problem:

- https://github.com/stedolan/jq/issues/217
- https://github.com/stedolan/jq/issues/143

And the issue actually persists in this Programming Historian article. Unfortunately the example used in the article seems to avoid this semantic problem because the example tweet id's already end in zeros so the probelm does not become apparent!

- https://programminghistorian.org/en/lessons/json-and-jq#one-to-many-relationships-tweet-hashtags

Fortunately twitter provide the .id_str value in their JSONL, so I need to update the makefile to use this value.

I have also tested if it is possible to convert the id_str to just an integer, but this still fails. See these command line examples to show what the jq tonumber function does to long integers:

(base) ➜  echo "1256295422961868811" | jq tonumber
1256295422961868800

(base) ➜  echo "1111111111111111111" | jq tonumber
1111111111111111200

Look in the screengrabs folder for some visualisations which contain these errors.