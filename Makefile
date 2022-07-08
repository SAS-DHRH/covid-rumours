################################################
# COVID Rumors in Historical Context
# School of Advanced Study, University of London
# Marty Steer and Kunika Kono, 2022
################################################
# Using gnu makefiles helps with reproducibility
# of the data pipeline.
#
# `Make` this datapackage to build local source
# data into a variety of more useful datasets
# which can be used downstream.
#
# For multithreaded data processing use:
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
# Variables
# Source data and build data directories (in and out)
BIN_DIR = ./bin
DATA_DIR = ./data
BUILD_DIR = ./build
MODEL_DIR = ./models
SCRIPT_DIR = ./scripts
DASHBOARD_DIR = ./dashboards
DASHBOARD_DATA = $(DASHBOARD_DIR)/data

SOURCE_DATA_DIR = $(DATA_DIR)/covid-rumours-data/noretweets-en
SOURCE_JSONL = $(wildcard $(SOURCE_DATA_DIR)/*.jsonl.gz)
C_STEM = rona-rumours-corpus-

TWEETSCRUFF_MODEL = $(MODEL_DIR)/tweetscruff-classifier/model-best
TWEETSCRUFF_LABEL = TWEETSCRUFF

CONSPIRACY_MODEL = $(MODEL_DIR)/conspiracy-classifier/model-best
CONSPIRACY_TRANSFORMER_MODEL = $(MODEL_DIR)/conspiracy-classifier/model-trf
CONSPIRACY_LABEL = CONSPIRACY
CONSPIRACY_THRESHOLD = 0.75

CURES_MODEL = $(MODEL_DIR)/cures-classifier/model-best
CURES_TRANSFORMER_MODEL = $(MODEL_DIR)/cures-classifier/model-trf
CURES_LABEL = CURES
CURES_THRESHOLD = 0.75

ORIGINS_MODEL = $(MODEL_DIR)/origins-classifier/model-best
ORIGINS_TRANSFORMER_MODEL = $(MODEL_DIR)/origins-classifier/model-trf
ORIGINS_LABEL = ORIGINS
ORIGINS_THRESHOLD = 0.75

VACCINES_MODEL = $(MODEL_DIR)/vaccines-classifier/model-best
VACCINES_TRANSFORMER_MODEL = $(MODEL_DIR)/vaccines-classifier/model-trf
VACCINES_LABEL = VACCINES
VACCINES_THRESHOLD = 0.75

ALL_LABEL = ALL

# ---
all: 
	$(MAKE) $(MAKEFLAGS) classify-tweets
	$(MAKE) $(MAKEFLAGS) docbin-filter-all docbin-to-texts docbin-ngrams

# 	$(MAKE) -j 2 lfdmm-topic-models
# 	$(MAKE) $(MAKEFLAGS) lfdmm-topic-topWords
# 	$(MAKE) -j 2 gpupdmm-topic-models
# 	$(MAKE) $(MAKEFLAGS) gpupdmm-topic-topWords


# ---
# classify-tweets
# convert tweets into docbins and run them through the classifiers
# Requires the models to be built 'cd ./models && make all'
DOCBINS_DIR = docbins
SPACY_DOCBINS = $(patsubst $(SOURCE_DATA_DIR)/%.jsonl.gz, \
							$(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy, \
							$(SOURCE_JSONL))
SPACY_TRANSFORMER_DOCBINS = $(patsubst $(SOURCE_DATA_DIR)/%.jsonl.gz, \
							$(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)-trf/%.spacy, \
							$(SOURCE_JSONL))

classify-tweets: $(SPACY_DOCBINS)
$(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/$(C_STEM)%.spacy: $(SOURCE_DATA_DIR)/$(C_STEM)%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $^ --outfile $@ --model $(TWEETSCRUFF_MODEL)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $@ --overwrite --model $(CONSPIRACY_MODEL)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $@ --overwrite --model $(CURES_MODEL)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $@ --overwrite --model $(ORIGINS_MODEL)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $@ --overwrite --model $(VACCINES_MODEL)

classify-tweets-trf: $(SPACY_TRANSFORMER_DOCBINS)
$(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)-trf/$(C_STEM)%.spacy: $(SOURCE_DATA_DIR)/$(C_STEM)%.jsonl.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $^ --outfile $@ --model $(TWEETSCRUFF_MODEL)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $@ --overwrite --model $(CONSPIRACY_TRANSFORMER_MODEL)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $@ --overwrite --model $(CURES_TRANSFORMER_MODEL)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $@ --overwrite --model $(ORIGINS_TRANSFORMER_MODEL)
	python $(SCRIPT_DIR)/spacy-docbinify.py --infile $@ --overwrite --model $(VACCINES_TRANSFORMER_MODEL)


# ---
# docbin-filter-all
# Filter docbins according to category threshold
CONSPIRACY_DOCBINS = $(patsubst $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy, $(BUILD_DIR)/$(CONSPIRACY_LABEL)/$(DOCBINS_DIR)/%.spacy, $(SPACY_DOCBINS))
CURES_DOCBINS = $(patsubst $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy, $(BUILD_DIR)/$(CURES_LABEL)/$(DOCBINS_DIR)/%.spacy, $(SPACY_DOCBINS))
ORIGINS_DOCBINS = $(patsubst $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy, $(BUILD_DIR)/$(ORIGINS_LABEL)/$(DOCBINS_DIR)/%.spacy, $(SPACY_DOCBINS))
VACCINES_DOCBINS = $(patsubst $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy, $(BUILD_DIR)/$(VACCINES_LABEL)/$(DOCBINS_DIR)/%.spacy, $(SPACY_DOCBINS))

docbin-filter-all:
	$(MAKE) $(MAKEFLAGS) docbin-filter-conspiracy
	$(MAKE) $(MAKEFLAGS) docbin-filter-cures
	$(MAKE) $(MAKEFLAGS) docbin-filter-origins
	$(MAKE) $(MAKEFLAGS) docbin-filter-vaccines

docbin-filter-conspiracy: $(CONSPIRACY_DOCBINS)
$(BUILD_DIR)/$(CONSPIRACY_LABEL)/$(DOCBINS_DIR)/%.spacy: $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy
	python $(SCRIPT_DIR)/spacy-docbin-textcat.py --infile $^ --outfile $@ --label $(CONSPIRACY_LABEL) --threshold $(CONSPIRACY_THRESHOLD)

docbin-filter-cures: $(CURES_DOCBINS)
$(BUILD_DIR)/$(CURES_LABEL)/$(DOCBINS_DIR)/%.spacy: $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy
	python $(SCRIPT_DIR)/spacy-docbin-textcat.py --infile $^ --outfile $@ --label $(CURES_LABEL) --threshold $(CURES_THRESHOLD)

docbin-filter-origins: $(ORIGINS_DOCBINS)
$(BUILD_DIR)/$(ORIGINS_LABEL)/$(DOCBINS_DIR)/%.spacy: $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy
	python $(SCRIPT_DIR)/spacy-docbin-textcat.py --infile $^ --outfile $@ --label $(ORIGINS_LABEL) --threshold $(ORIGINS_THRESHOLD)

docbin-filter-vaccines: $(VACCINES_DOCBINS)
$(BUILD_DIR)/$(VACCINES_LABEL)/$(DOCBINS_DIR)/%.spacy: $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy
	python $(SCRIPT_DIR)/spacy-docbin-textcat.py --infile $^ --outfile $@ --label $(VACCINES_LABEL) --threshold $(VACCINES_THRESHOLD)


# ---
# Generate texts from the various docbins corpus directories
# These can be downloaded from the dashbaord and used in antconc/Lancsbox applications.
TEXTS_DIR = texts
CONSPIRACY_TEXTS = $(patsubst $(BUILD_DIR)/$(CONSPIRACY_LABEL)/$(DOCBINS_DIR)/%.spacy, $(BUILD_DIR)/$(CONSPIRACY_LABEL)/$(TEXTS_DIR)/%.txt.gz, $(CONSPIRACY_DOCBINS))
CURES_TEXTS = $(patsubst $(BUILD_DIR)/$(CURES_LABEL)/$(DOCBINS_DIR)/%.spacy, $(BUILD_DIR)/$(CURES_LABEL)/$(TEXTS_DIR)/%.txt.gz, $(CURES_DOCBINS))
ORIGINS_TEXTS = $(patsubst $(BUILD_DIR)/$(ORIGINS_LABEL)/$(DOCBINS_DIR)/%.spacy, $(BUILD_DIR)/$(ORIGINS_LABEL)/$(TEXTS_DIR)/%.txt.gz, $(ORIGINS_DOCBINS))
VACCINES_TEXTS = $(patsubst $(BUILD_DIR)/$(VACCINES_LABEL)/$(DOCBINS_DIR)/%.spacy, $(BUILD_DIR)/$(VACCINES_LABEL)/$(TEXTS_DIR)/%.txt.gz, $(VACCINES_DOCBINS))
ALL_TEXTS = $(patsubst $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR)/%.spacy, $(BUILD_DIR)/$(ALL_LABEL)/$(TEXTS_DIR)/%.txt.gz, $(SPACY_DOCBINS))

docbin-to-texts:
	$(MAKE) $(MAKEFLAGS) docbin-to-texts-conspiracy
	$(MAKE) $(MAKEFLAGS) docbin-to-texts-cures
	$(MAKE) $(MAKEFLAGS) docbin-to-texts-origins
	$(MAKE) $(MAKEFLAGS) docbin-to-texts-vaccines
	$(MAKE) $(MAKEFLAGS) docbin-to-texts-all

docbin-to-texts-conspiracy: $(CONSPIRACY_TEXTS)
$(BUILD_DIR)/$(CONSPIRACY_LABEL)/$(TEXTS_DIR)/%.txt.gz: $(BUILD_DIR)/$(CONSPIRACY_LABEL)/$(DOCBINS_DIR)/%.spacy
	[[ -d $(@D) ]] || mkdir -p $(@D)
	python $(SCRIPT_DIR)/spacy-docbin-get-text.py --input $^ | pigz > $@

docbin-to-texts-cures: $(CURES_TEXTS)
$(BUILD_DIR)/$(CURES_LABEL)/$(TEXTS_DIR)/%.txt.gz: $(BUILD_DIR)/$(CURES_LABEL)/$(DOCBINS_DIR)/%.spacy
	[[ -d $(@D) ]] || mkdir -p $(@D)
	python $(SCRIPT_DIR)/spacy-docbin-get-text.py --input $^ | pigz > $@

docbin-to-texts-origins: $(ORIGINS_TEXTS)
$(BUILD_DIR)/$(ORIGINS_LABEL)/$(TEXTS_DIR)/%.txt.gz: $(BUILD_DIR)/$(ORIGINS_LABEL)/$(DOCBINS_DIR)/%.spacy
	[[ -d $(@D) ]] || mkdir -p $(@D)
	python $(SCRIPT_DIR)/spacy-docbin-get-text.py --input $^ | pigz > $@

docbin-to-texts-vaccines: $(VACCINES_TEXTS)
$(BUILD_DIR)/$(VACCINES_LABEL)/$(TEXTS_DIR)/%.txt.gz: $(BUILD_DIR)/$(VACCINES_LABEL)/$(DOCBINS_DIR)/%.spacy
	[[ -d $(@D) ]] || mkdir -p $(@D)
	python $(SCRIPT_DIR)/spacy-docbin-get-text.py --input $^ | pigz > $@

docbin-to-texts-all: $(ALL_TEXTS)
$(BUILD_DIR)/$(ALL_LABEL)/$(TEXTS_DIR)/%.txt.gz: $(BUILD_DIR)/$(DOCBINS_DIR)/%.spacy
	[[ -d $(@D) ]] || mkdir -p $(@D)
	python $(SCRIPT_DIR)/spacy-docbin-get-text.py --input $^ | pigz > $@


# ---
# docbin-ngrams
# Generate ngrams from the various docbins corpus directories
# store in the DASHBOARD_DATA directory.
docbin-ngrams:
	$(MAKE) $(MAKEFLAGS) docbin-ngrams-all
	$(MAKE) $(MAKEFLAGS) docbin-ngrams-conspiracy
	$(MAKE) $(MAKEFLAGS) docbin-ngrams-cures
	$(MAKE) $(MAKEFLAGS) docbin-ngrams-origins
	$(MAKE) $(MAKEFLAGS) docbin-ngrams-vaccines

docbin-ngrams-all: $(DASHBOARD_DATA)/$(ALL_LABEL)/unigrams.csv.gz
$(DASHBOARD_DATA)/$(ALL_LABEL)/unigrams.csv.gz:
	python $(SCRIPT_DIR)/spacy-docbin-make-ngrams.py \
		--inputdir $(BUILD_DIR)/$(ALL_LABEL)/$(DOCBINS_DIR) \
		--outputdir $(DASHBOARD_DATA)/$(ALL_LABEL)

docbin-ngrams-conspiracy: $(DASHBOARD_DATA)/$(CONSPIRACY_LABEL)/unigrams.csv.gz
$(DASHBOARD_DATA)/$(CONSPIRACY_LABEL)/unigrams.csv.gz:
	python $(SCRIPT_DIR)/spacy-docbin-make-ngrams.py \
		--inputdir $(BUILD_DIR)/$(CONSPIRACY_LABEL)/$(DOCBINS_DIR) \
		--outputdir $(DASHBOARD_DATA)/$(CONSPIRACY_LABEL)

docbin-ngrams-cures: $(DASHBOARD_DATA)/$(CURES_LABEL)/unigrams.csv.gz
$(DASHBOARD_DATA)/$(CURES_LABEL)/unigrams.csv.gz:
	python $(SCRIPT_DIR)/spacy-docbin-make-ngrams.py \
		--inputdir $(BUILD_DIR)/$(CURES_LABEL)/$(DOCBINS_DIR) \
		--outputdir $(DASHBOARD_DATA)/$(CURES_LABEL)

docbin-ngrams-origins: $(DASHBOARD_DATA)/$(ORIGINS_LABEL)/unigrams.csv.gz
$(DASHBOARD_DATA)/$(ORIGINS_LABEL)/unigrams.csv.gz:
	python $(SCRIPT_DIR)/spacy-docbin-make-ngrams.py \
		--inputdir $(BUILD_DIR)/$(ORIGINS_LABEL)/$(DOCBINS_DIR) \
		--outputdir $(DASHBOARD_DATA)/$(ORIGINS_LABEL)

docbin-ngrams-vaccines: $(DASHBOARD_DATA)/$(VACCINES_LABEL)/unigrams.csv.gz
$(DASHBOARD_DATA)/$(VACCINES_LABEL)/unigrams.csv.gz:
	python $(SCRIPT_DIR)/spacy-docbin-make-ngrams.py \
		--inputdir $(BUILD_DIR)/$(VACCINES_LABEL)/$(DOCBINS_DIR) \
		--outputdir $(DASHBOARD_DATA)/$(VACCINES_LABEL)


# ---
# topic modelling
# Generate topic models for each day in the English corpus
# @see https://github.com/qiang2100/STTM
# (java needs more heap space: -Xmx2048m)
TOPICS_DIR = topics
TOPIC_ALGORITHM_1 = GPU_PDMM
TOPIC_ALGORITHM_2 = LFDMM
NUM_TOPICS = 10

ALL_TOPICS_GPUPDMM = $(patsubst $(BUILD_DIR)/$(ALL_LABEL)/$(TEXTS_DIR)/%.txt.gz, $(BUILD_DIR)/$(ALL_LABEL)/$(TOPICS_DIR)/$(TOPIC_ALGORITHM_1)/results/%.topWords, $(ALL_TEXTS))
ALL_TOPICS_LFDMM = $(patsubst $(BUILD_DIR)/$(ALL_LABEL)/$(TEXTS_DIR)/%.txt.gz, $(BUILD_DIR)/$(ALL_LABEL)/$(TOPICS_DIR)/$(TOPIC_ALGORITHM_2)/results/%.topWords, $(ALL_TEXTS))

# (force use of 6 threads only)
topic-models-all: STTM glovevectors
	$(MAKE)  -j 6 topic-models-all-gpupdmm
	$(MAKE)  -j 6 topic-models-all-lfdmm


# GPU-PDMM algorithm
topic-models-all-gpupdmm: $(BUILD_DIR)/$(ALL_LABEL)/$(TOPICS_DIR)/$(TOPIC_ALGORITHM_1)-topWords.txt
$(BUILD_DIR)/$(ALL_LABEL)/$(TOPICS_DIR)/$(TOPIC_ALGORITHM_1)-topWords.txt: $(ALL_TOPICS_GPUPDMM)
	cat $^ | sort > $@
	tr -s '[[:punct:][:space:]]' '\n' < $@ | sort | uniq -c | sort -nr > $(@:.txt=.unigrams-freq.txt)
	cut -d' ' -f1-3 < $@ | sort | uniq -c | sort -nr > $(@:.txt=.trigrams-freq.txt)

$(BUILD_DIR)/$(ALL_LABEL)/$(TOPICS_DIR)/$(TOPIC_ALGORITHM_1)/results/%.topWords: $(BUILD_DIR)/$(ALL_LABEL)/$(TEXTS_DIR)/%.txt.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	$(eval TMPFILE= $(shell mktemp))
	trap 'rm -f "$(TMPFILE)"' EXIT

	gzcat $^ > $(TMPFILE); \
	cd $(@D)/..; \
	java -Xmx8192m -jar ../../../../$(BIN_DIR)/STTM/jar/STTM.jar \
		-model $(TOPIC_ALGORITHM_1) \
		-corpus $(TMPFILE) \
		-ntopics $(NUM_TOPICS) \
		-niters 128 \
		-vectors ../../../../$(BIN_DIR)/glove.twitter.27B.25d.txt \
		-name $(@F:.topWords=); \
	rm $(TMPFILE)


# LFDMM algorithm
topic-models-all-lfdmm: $(BUILD_DIR)/$(ALL_LABEL)/$(TOPICS_DIR)/$(TOPIC_ALGORITHM_2)-topWords.txt
$(BUILD_DIR)/$(ALL_LABEL)/$(TOPICS_DIR)/$(TOPIC_ALGORITHM_2)-topWords.txt: $(ALL_TOPICS_LFDMM)
	cat $^ | sort > $@
	tr -s '[[:punct:][:space:]]' '\n' < $@ | sort | uniq -c | sort -nr > $(@:.txt=.unigrams-freq.txt)
	cut -d' ' -f1-3 < $@ | sort | uniq -c | sort -nr > $(@:.txt=.trigrams-freq.txt)

topic-models-all-lfdmm: $(ALL_TOPICS_LFDMM)
$(BUILD_DIR)/$(ALL_LABEL)/$(TOPICS_DIR)/$(TOPIC_ALGORITHM_2)/results/%.topWords: $(BUILD_DIR)/$(ALL_LABEL)/$(TEXTS_DIR)/%.txt.gz
	[[ -d $(@D) ]] || mkdir -p $(@D)
	$(eval TMPFILE= $(shell mktemp))
	trap 'rm -f "$(TMPFILE)"' EXIT

	gzcat $^ > $(TMPFILE); \
	cd $(@D)/..; \
	java -Xmx8192m -jar ../../../../$(BIN_DIR)/STTM/jar/STTM.jar \
		-model $(TOPIC_ALGORITHM_2) \
		-corpus $(TMPFILE) \
		-ntopics $(NUM_TOPICS) \
		-niters 128 \
		-vectors ../../../../$(BIN_DIR)/glove.twitter.27B.25d.txt \
		-name $(@F:.topWords=); \
	rm $(TMPFILE)


# ---
# coast-samples
# David's sample tweet requests, 2021-11-26
# The 'votersarewatching' tweets were not present in the sample days,
# so the whole corpus was searched insted.
COAST_SAMPLE_DIR = $(BUILD_DIR)/coast-samples
GREP_CMD = grep -Ei
coast-samples:
	[[ -d $(COAST_SAMPLE_DIR) ]] || mkdir $(COAST_SAMPLE_DIR)
	gzcat $(BUILD_DIR)/ALL/texts/*2020-09-15*.gz | $(GREP_CMD) 'climate' > $(COAST_SAMPLE_DIR)/climate-2020-09-15-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2021-08-10*.gz | $(GREP_CMD) 'climate' > $(COAST_SAMPLE_DIR)/climate-2021-08-10-rona.txt

	gzcat $(BUILD_DIR)/ALL/texts/*2020-10-02*.gz | $(GREP_CMD) 'hoax' > $(COAST_SAMPLE_DIR)/hoax-2020-10-02-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-04-2[456]*.gz | $(GREP_CMD) 'depopulation' > $(COAST_SAMPLE_DIR)/depopulation-2020-2[456]-04-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2021-03-23*.gz | $(GREP_CMD) 'agenda21' > $(COAST_SAMPLE_DIR)/agenda21-2021-03-23-rona.txt
	
	gzcat $(BUILD_DIR)/ALL/texts/*2020-04-[29-31]*.gz | $(GREP_CMD) 'plandemic' > $(COAST_SAMPLE_DIR)/plandemic-2020-[29-31]-04-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-05-01*.gz | $(GREP_CMD) 'plandemic' > $(COAST_SAMPLE_DIR)/plandemic-2020-05-01-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-05-08*.gz | $(GREP_CMD) 'plandemic' > $(COAST_SAMPLE_DIR)/plandemic-2020-05-08-rona.txt

	gzcat $(BUILD_DIR)/ALL/texts/*2020-04-16*.gz | $(GREP_CMD) 'filmyourhospital' > $(COAST_SAMPLE_DIR)/filmyourhospital-2020-04-16-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-05-04*.gz | $(GREP_CMD) 'filmyourhospital' > $(COAST_SAMPLE_DIR)/filmyourhospital-2020-05-04-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-06-07*.gz | $(GREP_CMD) 'filmyourhospital' > $(COAST_SAMPLE_DIR)/filmyourhospital-2020-06-07-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-07-05*.gz | $(GREP_CMD) 'filmyourhospital' > $(COAST_SAMPLE_DIR)/filmyourhospital-2020-07-05-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-07-15*.gz | $(GREP_CMD) 'filmyourhospital' > $(COAST_SAMPLE_DIR)/filmyourhospital-2020-07-15-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-08-03*.gz | $(GREP_CMD) 'filmyourhospital' > $(COAST_SAMPLE_DIR)/filmyourhospital-2020-08-03-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-09-03*.gz | $(GREP_CMD) 'filmyourhospital' > $(COAST_SAMPLE_DIR)/filmyourhospital-2020-09-03-rona.txt

	gzcat $(BUILD_DIR)/ALL/texts/*2020-04-[12]4*.gz | $(GREP_CMD) '5gkills' > $(COAST_SAMPLE_DIR)/5gkills-2020-04-[12]4-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-06-13*.gz | $(GREP_CMD) '5gkills' > $(COAST_SAMPLE_DIR)/5gkills-2020-06-13-rona.txt

	gzcat $(BUILD_DIR)/ALL/texts/*2020-04-28*.gz | $(GREP_CMD) 'covidiot' > $(COAST_SAMPLE_DIR)/covidiot-2020-04-28-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-05-04*.gz | $(GREP_CMD) 'covidiot' > $(COAST_SAMPLE_DIR)/covidiot-2020-05-04-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2020-10-0[56]*.gz | $(GREP_CMD) 'covidiot' > $(COAST_SAMPLE_DIR)/covidiot-2020-10-0[56]-rona.txt
	gzcat $(BUILD_DIR)/ALL/texts/*2021-03-03*.gz | $(GREP_CMD) 'covidiot' > $(COAST_SAMPLE_DIR)/covidiot-2021-03-03-rona.txt

	gzcat $(BUILD_DIR)/ALL/texts/*.gz | $(GREP_CMD) 'votersarewatching' > $(COAST_SAMPLE_DIR)/votersarewatching-all-rona.txt


# ---
# @requirements: based on macos
# also needs java and jupyter - install those yourself!
.PHONY: twarc jq csvkit STTM spacy glovevectors
requirements: twarc jq csvkit STTM spacy glovevectors

twarc: $(BIN_DIR)/twarc 
./bin/twarc:
	git clone https://github.com/DocNow/twarc.git $(BIN_DIR)/twarc

STTM: $(BIN_DIR)/STTM 
./bin/STTM:
	git clone https://github.com/qiang2100/STTM.git $(BIN_DIR)/STTM

glovevectors: $(BIN_DIR)/glove.twitter.27B.25d.txt $(BIN_DIR)/glove.6B.100d.txt
$(BIN_DIR)/glove.twitter.27B.25d.txt:
	wget -c -O $(BIN_DIR)/glove.twitter.27B.zip http://nlp.stanford.edu/data/glove.twitter.27B.zip
	unzip $(BIN_DIR)/glove.twitter.27B.zip glove.twitter.27B.25d.txt -d $(BIN_DIR)
$(BIN_DIR)/glove.6B.100d.txt:
	wget -c -O $(BIN_DIR)/glove.6B.zip http://nlp.stanford.edu/data/glove.6B.zip
	unzip $(BIN_DIR)/glove.6B.zip glove.6B.100d.txt -d $(BIN_DIR)

jq: /opt/homebrew/bin/jq
/opt/homebrew/bin/jq:
	brew install jq

csvkit: /opt/homebrew/bin/csvcut
/opt/homebrew/bin/csvcut:
	brew install csvkit

spacy: /opt/homebrew/anaconda3/bin/spacy
/opt/homebrew/anaconda3/bin/spacy:
	pip install -U pip setuptools wheel
	pip install -U spacy
	python -m spacy download en_core_web_sm


# ---
.PHONY: clean
clean:
	@echo "Removing directories..."
	rm -rf $(BIN_DIR)
