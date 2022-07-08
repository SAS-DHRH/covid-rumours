################################################
# COVID Rumor vocab, samples & patterns makefile
################################################
# Marty Steer
# School of Advanced Study, University of London
# 2021-09
################################################
# Using gnu makefiles helps with reproducibility
# of the data and machine learning pipeline.
#
# For multithreaded data processing,
# use the make -j switch:
# $ make -j 8
#
# Use these rules to help debug source & target:
# 	@echo T-source		$^
# 	@echo T-target 		$@
# 	@echo T-replace		$(^:.csv=.txt)
# 	@echo T-file-within	$(@F)
# 	@echo T-target 		$@
# 	@echo
#
################################################

# Source data and build data directories (in and out)
DATA_DIR = ../data
BUILD_DIR = ../build
MODEL_DIR = ../models
SCRIPT_DIR = ../scripts

SOURCE_DATA_DIR = $(DATA_DIR)/covid-rumours-data/noretweets-en
SOURCE_JSONL = $(wildcard $(SOURCE_DATA_DIR)/*.jsonl.gz)
C_STEM = rona-rumours-corpus-


# ---
# Some sample searches/walls for iterating on the
# classifier model building.
SAMPLE_MONTHS := 2020-04 2020-05 2020-08 2020-11


# ---
# Patterns data refining pipeline
CONSP_REFINED = $(wildcard $(MODEL_DIR)/conspiracy-classifier/refined-data/*.jsonl.gz)
CONSP_SAMPLES = $(patsubst $(MODEL_DIR)/conspiracy-classifier/refined-data/%.jsonl.gz, \
							$(MODEL_DIR)/conspiracy-classifier/sample-data/%.jsonl.gz, $(CONSP_REFINED))
CONSP_WALLS = $(patsubst $(MODEL_DIR)/conspiracy-classifier/refined-data/%.jsonl.gz, \
							$(MODEL_DIR)/conspiracy-classifier/walls/%.html, $(CONSP_REFINED))
CONSP_PRODIGY = $(MODEL_DIR)/conspiracy-classifier/prodigy-data/conspiracy-data-sample.jsonl


# TODO: figure out how to map reduce this for the sample months and
# run the pipeline for all the searches/classifiers we want, to produce:
# 1) the jsonl;
# 2) and the html walls;
# 3) the training jsonl;
# 4) and then delete the full jsonl (for data privacy)
conspiracy-refined-data:
	for i in $(SAMPLE_MONTHS); do \
		echo "Searching month:" $$i; \
		gzcat $(BUILD_DIR)/noscruff/rona-rumours-corpus-ᾱ-$$i-*.jsonl.gz \
			| $(SCRIPT_DIR)/spacy-match.py \
				--patterns $(MODEL_DIR)/conspiracy-classifier/conspiracy-patterns.jsonl \
				--excludes $(MODEL_DIR)/exclude-patterns.jsonl \
			| pigz > $(MODEL_DIR)/conspiracy-classifier/refined-data/conspiracy-$$i.jsonl.gz; \
	done


# Get the number of lines and calculate the percentage needed to sample
# 1000 lines from each file of different lengths.
# Then use this number and awk to randomly sample approx 1000 lines.
# @see https://www.wolframalpha.com/input/?i=a+*+x%2F100+%3D+1000
# Then use the 1000 line samples to create HTML walls.
conspiracy-classifier-data: $(CONSP_SAMPLES) $(CONSP_WALLS) $(CONSP_PRODIGY)

$(MODEL_DIR)/conspiracy-classifier/sample-data/%.jsonl.gz: $(MODEL_DIR)/*/refined-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	percent=`awk 'END{print (100000 / NR)/100}' $^`; \
	awk -v p="$$percent" 'BEGIN {srand()} !/^$$/ { if (rand() <= p) print $$0}' $^ | pigz > $@

$(MODEL_DIR)/conspiracy-classifier/walls/%.html: $(MODEL_DIR)/*/sample-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | $(SCRIPT_DIR)/twarc-wall.py --title $(@F)  > $@

# TODO: make this able to generate multiple samples as a single JSONL file.
# It's easier to use on the server.
$(MODEL_DIR)/conspiracy-classifier/prodigy-data/conspiracy-data-sample.jsonl: $(CONSP_SAMPLES)
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | jq -c '{id: .id_str, text: (if .extended_tweet.full_text then .extended_tweet.full_text else (if .full_text then .full_text else .text end) end)}' > $@




################################################
# Cures classifier data refining pipeline
#
CURES_REFINED = $(wildcard $(MODEL_DIR)/cures-classifier/refined-data/*.jsonl.gz)
CURES_SAMPLES = $(patsubst $(MODEL_DIR)/cures-classifier/refined-data/%.jsonl.gz, \
							$(MODEL_DIR)/cures-classifier/sample-data/%.jsonl.gz, $(CURES_REFINED))
CURES_WALLS = $(patsubst $(MODEL_DIR)/cures-classifier/refined-data/%.jsonl.gz, \
							$(MODEL_DIR)/cures-classifier/walls/%.html, $(CURES_REFINED))
CURES_PRODIGY = $(MODEL_DIR)/cures-classifier/prodigy-data/cures-sample.jsonl

# refined data - uses patterns to extract sample tweets
cures-refined-data:
	[[ -d $(MODEL_DIR)/cures-classifier/refined-data ]] || mkdir -p $(MODEL_DIR)/cures-classifier/refined-data
	for i in $(SAMPLE_MONTHS); do \
		echo "Searching month:" $$i; \
		gzcat $(BUILD_DIR)/noscruff/rona-rumours-corpus-ᾱ-$$i-*.jsonl.gz \
			| $(SCRIPT_DIR)/spacy-match.py \
				--patterns $(MODEL_DIR)/cures-classifier/cures-patterns.jsonl \
				--excludes $(MODEL_DIR)/cures-classifier/exclude-patterns.jsonl \
			| pigz > $(MODEL_DIR)/cures-classifier/refined-data/cures-$$i.jsonl.gz; \
	done


# classifier data - subsamples refined data and extracts 1000 random tweets/file
cures-classifier-data: $(CURES_SAMPLES) $(CURES_WALLS) $(CURES_PRODIGY)

$(MODEL_DIR)/cures-classifier/sample-data/%.jsonl.gz: $(MODEL_DIR)/*/refined-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	percent=`gzcat $^ | awk 'END{print (100000 / NR)/100}'`; \
	gzcat $^ | awk -v p="$$percent" 'BEGIN {srand()} !/^$$/ { if (rand() <= p) print $$0}' | pigz > $@

# walls - converts classifier sample files to HTML walls
$(MODEL_DIR)/cures-classifier/walls/%.html: $(MODEL_DIR)/*/sample-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | $(SCRIPT_DIR)/twarc-wall.py --title $(@F)  > $@

# prodigy data - strips metadata from classifier JSONL for prodigy,
# so tid and text are the only fields left in the files.
$(MODEL_DIR)/cures-classifier/prodigy-data/cures-data-sample.jsonl: $(CURES_SAMPLES)
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | jq -c '{id: .id_str, text: (if .extended_tweet.full_text then .extended_tweet.full_text else (if .full_text then .full_text else .text end) end)}' > $@




################################################
# Origins classifier data refining pipeline
#
ORIGINS_DATA = $(wildcard $(MODEL_DIR)/origins-classifier/refined-data/*.jsonl.gz)
ORIGINS_SAMPLES = $(patsubst $(MODEL_DIR)/origins-classifier/refined-data/%.jsonl.gz, \
								$(MODEL_DIR)/origins-classifier/sample-data/%.jsonl.gz, $(ORIGINS_DATA))
ORIGINS_WALLS = $(patsubst $(MODEL_DIR)/origins-classifier/refined-data/%.jsonl.gz, \
								$(MODEL_DIR)/origins-classifier/walls/%.html, $(ORIGINS_DATA))
ORIGINS_PRODIGY = $(MODEL_DIR)/origins-classifier/prodigy-data/origins-data-sample.jsonl

origins-refined-data:
	for i in $(SAMPLE_MONTHS); do \
		echo "Searching month:" $$i; \
		gzcat $(BUILD_DIR)/noscruff/rona-rumours-corpus-ᾱ-$$i-*.jsonl.gz \
			| $(SCRIPT_DIR)/spacy-match.py \
				--patterns $(MODEL_DIR)/origins-classifier/origins-patterns.jsonl \
				--excludes $(MODEL_DIR)/exclude-patterns.jsonl \
			| pigz > $(MODEL_DIR)/origins-classifier/refined-data/origins-$$i.jsonl.gz; \
	done

origins-ET-refined-data:
	for i in $(SAMPLE_MONTHS); do \
		echo "Searching month:" $$i; \
		gzcat $(BUILD_DIR)/noscruff/rona-rumours-corpus-ᾱ-$$i-*.jsonl.gz \
			| $(SCRIPT_DIR)/spacy-match.py \
				--patterns $(MODEL_DIR)/origins-classifier/origins-ET-patterns.jsonl \
				--excludes $(MODEL_DIR)/exclude-patterns.jsonl \
			| pigz > $(MODEL_DIR)/origins-classifier/refined-data/origins-ET-$$i.jsonl.gz; \
	done


origins-classifier-data: $(ORIGINS_SAMPLES) $(ORIGINS_WALLS) $(ORIGINS_PRODIGY)
$(MODEL_DIR)/origins-classifier/sample-data/%.jsonl.gz: $(MODEL_DIR)/*/refined-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	percent=`gzcat $^ | awk 'END{print (100000 / NR)/100}'`; \
	gzcat $^ | awk -v p="$$percent" 'BEGIN {srand()} !/^$$/ { if (rand() <= p) print $$0}' | pigz > $@

$(MODEL_DIR)/origins-classifier/walls/%.html: $(MODEL_DIR)/*/sample-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | $(SCRIPT_DIR)/twarc-wall.py --title $(@F) > $@

$(MODEL_DIR)/origins-classifier/prodigy-data/origins-data-sample.jsonl: $(ORIGINS_SAMPLES)
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | jq -c '{id: .id_str, text: (if .extended_tweet.full_text then .extended_tweet.full_text else (if .full_text then .full_text else .text end) end)}' > $@




################################################
# Vaccines classifier data refining pipeline
#
VACCINES_DATA = $(wildcard $(MODEL_DIR)/vaccines-classifier/refined-data/*.jsonl.gz)
VACCINES_SAMPLES = $(patsubst $(MODEL_DIR)/vaccines-classifier/refined-data/%.jsonl.gz, \
								$(MODEL_DIR)/vaccines-classifier/sample-data/%.jsonl.gz, $(VACCINES_DATA))
VACCINES_WALLS = $(patsubst $(MODEL_DIR)/vaccines-classifier/refined-data/%.jsonl.gz, \
								$(MODEL_DIR)/vaccines-classifier/walls/%.html, $(VACCINES_DATA))
VACCINES_PRODIGY = $(MODEL_DIR)/vaccines-classifier/prodigy-data/vaccines-data-sample.jsonl


vaccines-refined-data:
	for i in $(SAMPLE_MONTHS); do \
		echo "Searching month:" $$i; \
		gzcat $(BUILD_DIR)/noscruff/rona-rumours-corpus-ᾱ-$$i-*.jsonl.gz \
			| $(SCRIPT_DIR)/spacy-match.py \
				--patterns $(MODEL_DIR)/vaccines-classifier/vaccines-patterns.jsonl \
				--excludes $(MODEL_DIR)/vaccines-classifier/exclude-patterns.jsonl \
			| pigz > $(MODEL_DIR)/vaccines-classifier/refined-data/vaccines-$$i.jsonl.gz; \
	done


vaccines-classifier-data: $(VACCINES_SAMPLES) $(VACCINES_WALLS) $(VACCINES_PRODIGY)
$(MODEL_DIR)/vaccines-classifier/sample-data/%.jsonl.gz: $(MODEL_DIR)/vaccines-classifier/refined-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	percent=`gzcat $^ | awk 'END{print (100000 / NR)/100}'`; \
	gzcat $^ | awk -v p="$$percent" 'BEGIN {srand()} !/^$$/ { if (rand() <= p) print $$0}' | pigz > $@

$(MODEL_DIR)/vaccines-classifier/walls/%.html: $(MODEL_DIR)/vaccines-classifier/sample-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | $(SCRIPT_DIR)/twarc-wall.py --title $(@F) > $@

$(MODEL_DIR)/vaccines-classifier/prodigy-data/vaccines-data-sample.jsonl: $(VACCINES_PRODIGY)
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | jq -c '{id: .id_str, text: (if .extended_tweet.full_text then .extended_tweet.full_text else (if .full_text then .full_text else .text end) end)}' > $@




################################################
# Grabbag searches data refining pipeline
#
GRABBAG_PATTERNS = $(wildcard $(MODEL_DIR)/grabbag/*-patterns.jsonl.gz)
GRABBAG_REFINED_DATA = $(patsubst $(MODEL_DIR)/grabbag/%-patterns.jsonl.gz, \
									$(MODEL_DIR)/grabbag/refined-data/%.jsonl.gz, $(GRABBAG_PATTERNS))

GRABBAG_DATA = $(wildcard $(MODEL_DIR)/grabbag/refined-data/*.jsonl.gz)
GRABBAG_SAMPLES = $(patsubst $(MODEL_DIR)/grabbag/refined-data/%.jsonl.gz, \
									$(MODEL_DIR)/grabbag/sample-data/%.jsonl.gz, $(GRABBAG_DATA))
GRABBAG_WALLS = $(patsubst $(MODEL_DIR)/grabbag/refined-data/%.jsonl.gz, \
									$(MODEL_DIR)/grabbag/walls/%.html, $(GRABBAG_DATA))
GRABBAG_PRODIGY = $(patsubst $(MODEL_DIR)/grabbag/refined-data/%.jsonl.gz, \
									$(MODEL_DIR)/grabbag/prodigy-data/%.jsonl.gz, $(GRABBAG_DATA))


# This refines data for all *-patterns.json files in the grabbag directory.
grabbag-refine-data: $(GRABBAG_REFINED_DATA)
$(MODEL_DIR)/grabbag/refined-data/%.jsonl.gz: $(MODEL_DIR)/grabbag/%-patterns.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	for i in $(SAMPLE_MONTHS); do \
		echo "Searching month:" $$i; \
		gzcat $(BUILD_DIR)/noscruff/rona-rumours-corpus-ᾱ-$$i-*.jsonl.gz \
			| $(SCRIPT_DIR)/spacy-match.py \
				--patterns $^ \
				--excludes $(MODEL_DIR)/exclude-patterns.jsonl \
			| pigz > $(@:.jsonl.gz=-$$i.jsonl.gz); \
	done

# This processes all the refined data into walls, and training samples
grabbag-data: $(GRABBAG_SAMPLES) $(GRABBAG_WALLS) $(GRABBAG_PRODIGY)
$(MODEL_DIR)/grabbag/sample-data/%.jsonl.gz: $(MODEL_DIR)/grabbag/refined-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	percent=`gzcat $^ | awk 'END{print (100000 / NR)/100}'`; \
	gzcat $^ | awk -v p="$$percent" 'BEGIN {srand()} !/^$$/ { if (rand() <= p) print $$0}' | pigz > $@

$(MODEL_DIR)/grabbag/walls/%.html: $(MODEL_DIR)/grabbag/sample-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | $(SCRIPT_DIR)/twarc-wall.py --title $(@F) > $@

$(MODEL_DIR)/grabbag/prodigy-data/%.jsonl.gz: $(MODEL_DIR)/grabbag/sample-data/%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	gzcat $^ | jq -c '{id: .id_str, text: (if .extended_tweet.full_text then .extended_tweet.full_text else (if .full_text then .full_text else .text end) end)}' | pigz > $@

