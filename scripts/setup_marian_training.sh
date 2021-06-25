#!/bin/bash -v

# suffix of source language files
SRC=fi

# suffix of target language files
TRG=sv

MARIAN=../../build

# if we are in WSL, we need to add '.exe' to the tool names
if [ -e "/bin/wslpath" ]
then
    EXT=.exe
fi

MARIAN_TRAIN=$MARIAN/marian$EXT
MARIAN_VOCAB=$MARIAN/marian-vocab$EXT

if [ ! -e $MARIAN_TRAIN ]
then
    echo "marian is not installed in $MARIAN, you need to compile the toolkit first"
    exit 1
fi

if [ ! -e ../tools/moses-scripts ] || [ ! -e ../tools/subword-nmt ] || [ ! -e ../tools/sacreBLEU ]
then
    echo "missing tools in ../tools, you need to download them first"
    exit 1
fi

if [ ! -e "data/corpus.$SRC" ]
then
    ./scripts/download-files.sh
fi

mkdir -p model

# preprocess data
if [ ! -e "data/corpus.bpe.$SRC" ]
then
	bash ./scripts/preprocess-data.sh
fi

# create common vocabulary
if [ ! -e "model/vocab.$SRC$TRG.yml" ]
then
    cat data/corpus.bpe.$SRC data/corpus.bpe.$TRG | $MARIAN_VOCAB --max-size 65000 > model/vocab.$SRC$TRG.yml
fi
