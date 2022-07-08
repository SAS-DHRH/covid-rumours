#
# NB:
# THIS NEEDS FIXING AFTER THE REFACTOR!
# 2021-10-18, MS
#
################################################
# COVID Rumor Tweet model makefile
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
BIN_DIR = ../bin
DATA_DIR = ../data
BUILD_DIR = ../build
MODEL_DIR = ../models
SCRIPT_DIR = ../scripts
DASHBOARD_DATA = ../dashboards/data/build

SOURCE_DATA_DIR = $(DATA_DIR)/covid-rumours-data/noretweets-en
SOURCE_JSONL = $(wildcard $(SOURCE_DATA_DIR)/*.jsonl.gz)
C_STEM = rona-rumours-corpus-


# ---
.PHONY: train-all train-noscruff train-conspiracy train-cures train-origins train-vaccines
train-all:
	$(MAKE) $(MAKEFLAGS) pretrain
	$(MAKE) $(MAKEFLAGS) train-noscruff
	$(MAKE) $(MAKEFLAGS) train-conspiracy train-cures train-origins train-vaccines


# ---
# pretrain
# use the spacy config system to pretrain word vectors from the corpus
# and save in pretrain directory
pretrain:
	python -m spacy pretrain $(MODEL_DIR)/pretraining.cfg $(MODEL_DIR)/pretrain --gpu-id 0


# ---
# Tweetscruff classifier
TWEETSCRUFF_MODEL = $(MODEL_DIR)/tweetscruff-classifier
TWEETSCRUFF_MODEL_STATS = $(TWEETSCRUFF_MODEL)/tweetscruff-classifier.stats
TWEETSCRUFF_ANNOTATIONS = $(DATA_DIR)/annotations/annotask0-tweetscruff/tweetscruff-annotations.jsonl
TWEETSCRUFF_PRODIGY_DB = annotask0_tweetscruff
TWEETSCRUFF_BASE_MODEL = en_core_web_lg
TWEETSCRUFF_LABEL = TWEETSCRUFF

train-noscruff: $(TWEETSCRUFF_ANNOTATIONS)
	[[ -d $(TWEETSCRUFF_MODEL) ]] || mkdir -p $(TWEETSCRUFF_MODEL)
	@echo >> $(TWEETSCRUFF_MODEL_STATS)
	@echo 'Training.......' >> $(TWEETSCRUFF_MODEL_STATS)
	@date >> $(TWEETSCRUFF_MODEL_STATS)
	@echo >> $(TWEETSCRUFF_MODEL_STATS)

	prodigy drop $(TWEETSCRUFF_PRODIGY_DB) | true
	prodigy db-in $(TWEETSCRUFF_PRODIGY_DB) $(TWEETSCRUFF_ANNOTATIONS)
	prodigy train $(TWEETSCRUFF_MODEL) \
					--textcat-multilabel $(TWEETSCRUFF_PRODIGY_DB) \
					--base-model $(TWEETSCRUFF_BASE_MODEL) \
		>> $(TWEETSCRUFF_MODEL_STATS)


# ---
# Conspiracy classifier
CONSPIRACY_MODEL = $(MODEL_DIR)/conspiracy-classifier
CONSPIRACY_MODEL_STATS = $(CONSPIRACY_MODEL)/conspiracy-classifier.stats
CONSPIRACY_ANNOTATIONS = $(DATA_DIR)/annotations/annotask1-conspiracy/annotask1-conspiracy-reviewed-annotations.jsonl
CONSPIRACY_PRODIGY_DB = annotask1_conspiracy
CONSPIRACY_BASE_MODEL = en_core_web_lg
CONSPIRACY_LABEL = CONSPIRACY

train-conspiracy: $(CONSPIRACY_ANNOTATIONS)
	[[ -d $(CONSPIRACY_MODEL) ]] || mkdir -p $(CONSPIRACY_MODEL)
	@echo >> $(CONSPIRACY_MODEL_STATS)
	@echo 'Training.......' >> $(CONSPIRACY_MODEL_STATS)
	@date >> $(CONSPIRACY_MODEL_STATS)
	@echo >> $(CONSPIRACY_MODEL_STATS)

	prodigy drop $(CONSPIRACY_PRODIGY_DB) | true
	prodigy db-in $(CONSPIRACY_PRODIGY_DB) $(CONSPIRACY_ANNOTATIONS)
	prodigy train $(CONSPIRACY_MODEL) \
					--textcat-multilabel $(CONSPIRACY_PRODIGY_DB) \
					--base-model $(CONSPIRACY_BASE_MODEL) \
		>> $(CONSPIRACY_MODEL_STATS)


# ---
# Cures classifier
CURES_MODEL = $(MODEL_DIR)/cures-classifier
CURES_MODEL_STATS = $(CURES_MODEL)/cures-classifier.stats
CURES_ANNOTATIONS = $(DATA_DIR)/annotations/annotask2-cures/cures-task2-reviewed-annotations.jsonl
CURES_PRODIGY_DB = annotask2_cures
CURES_BASE_MODEL = en_core_web_lg
CURES_LABEL = CURES

train-cures: $(CURES_ANNOTATIONS)
	[[ -d $(CURES_MODEL) ]] || mkdir -p $(CURES_MODEL)
	@echo >> $(CURES_MODEL_STATS)
	@echo 'Training.......' >> $(CURES_MODEL_STATS)
	@date >> $(CURES_MODEL_STATS)
	@echo >> $(CURES_MODEL_STATS)

	prodigy drop $(CURES_PRODIGY_DB) | true
	prodigy db-in $(CURES_PRODIGY_DB) $(CURES_ANNOTATIONS)
	prodigy train $(CURES_MODEL) \
					--textcat-multilabel $(CURES_PRODIGY_DB) \
					--base-model $(CURES_BASE_MODEL) \
		>> $(CURES_MODEL_STATS)


# ---
# Origins classifier
ORIGINS_MODEL = $(MODEL_DIR)/origins-classifier
ORIGINS_MODEL_STATS = $(ORIGINS_MODEL)/origins-classifier.stats
ORIGINS_ANNOTATIONS = $(DATA_DIR)/annotations/annotask3-origins/origins-task3-reviewed-annotations.jsonl
ORIGINS_PRODIGY_DB = annotask3_origins
ORIGINS_BASE_MODEL = en_core_web_lg
ORIGINS_LABEL = ORIGINS

train-origins: $(ORIGINS_ANNOTATIONS)
	[[ -d $(ORIGINS_MODEL) ]] || mkdir -p $(ORIGINS_MODEL)
	@echo >> $(ORIGINS_MODEL_STATS)
	@echo 'Training.......' >> $(ORIGINS_MODEL_STATS)
	@date >> $(ORIGINS_MODEL_STATS)
	@echo >> $(ORIGINS_MODEL_STATS)

	prodigy drop $(ORIGINS_PRODIGY_DB) | true
	prodigy db-in $(ORIGINS_PRODIGY_DB) $(ORIGINS_ANNOTATIONS)
	prodigy train $(ORIGINS_MODEL) \
					--textcat-multilabel $(ORIGINS_PRODIGY_DB) \
					--base-model $(ORIGINS_BASE_MODEL) \
		>> $(ORIGINS_MODEL_STATS)


# ---
# Vaccines classifier
VACCINES_MODEL = $(MODEL_DIR)/vaccines-classifier
VACCINES_MODEL_STATS = $(VACCINES_MODEL)/vaccines-classifier.stats
VACCINES_ANNOTATIONS = $(DATA_DIR)/annotations/annotask4-vaccines/vaccines-task4-reviewed-annotations.jsonl
VACCINES_PRODIGY_DB = annotask4_vaccines
VACCINES_BASE_MODEL = en_core_web_lg
VACCINES_LABEL = VACCINES

train-vaccines: $(VACCINES_ANNOTATIONS)
	[[ -d $(VACCINES_MODEL) ]] || mkdir -p $(VACCINES_MODEL)
	@echo >> $(VACCINES_MODEL_STATS)
	@echo 'Training.......' >> $(VACCINES_MODEL_STATS)
	@date >> $(VACCINES_MODEL_STATS)
	@echo >> $(VACCINES_MODEL_STATS)

	prodigy drop $(VACCINES_PRODIGY_DB) | true
	prodigy db-in $(VACCINES_PRODIGY_DB) $(VACCINES_ANNOTATIONS)
	prodigy train $(VACCINES_MODEL) \
					--textcat-multilabel $(VACCINES_PRODIGY_DB) \
					--base-model $(VACCINES_BASE_MODEL) \
		>> $(VACCINES_MODEL_STATS)


