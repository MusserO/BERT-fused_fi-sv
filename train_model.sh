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
MARIAN_DECODER=$MARIAN/marian-decoder$EXT

# set chosen gpus
GPUS=0
if [ $# -ne 0 ]
then
    GPUS=$@
fi
echo Using GPUs: $GPUS

mkdir -p temp
$MARIAN_TRAIN \
	--model model/model.npz --type transformer \
	--train-sets data/corpus.bpe.$SRC data/corpus.bpe.$TRG \
	--max-length 100 \
	--vocabs model/vocab.$SRC$TRG.yml model/vocab.$SRC$TRG.yml \
	--mini-batch-fit -w 10000 --maxi-batch 1000 \
	--early-stopping 10 --cost-type=ce-mean-words \
	--valid-freq 5000 --save-freq 5000 --disp-freq 500 \
	--valid-metrics ce-mean-words perplexity translation \
	--valid-sets data/valid.bpe.$SRC data/valid.bpe.$TRG \
	--valid-script-path "bash ./scripts/validate.sh" \
	--valid-translation-output data/valid.bpe.$SRC.output --quiet-translation \
	--valid-mini-batch 64 \
	--beam-size 12 --normalize 0.6 \
	--log model/train.log --valid-log model/valid.log \
	--tempdir temp \
	--enc-depth 6 --dec-depth 6 \
	--transformer-heads 8 \
	--transformer-postprocess-emb d \
	--transformer-postprocess dan \
	--transformer-dropout 0.1 --label-smoothing 0.1 \
	--learn-rate 0.0003 --lr-warmup 16000 --lr-decay-inv-sqrt 16000 --lr-report \
	--optimizer-params 0.9 0.98 1e-09 --clip-norm 5 \
	--tied-embeddings-all \
	--devices $GPUS --sync-sgd --seed 1111 \
	--exponential-smoothing

# find best model on dev set
ITER=`cat model/valid.log | grep translation | sort -rg -k12,12 -t' ' | cut -f8 -d' ' | head -n1`

# translate test sets
for prefix in tatoeba_test fiskmo_test
do
    cat data/$prefix.bpe.$SRC \
        | $MARIAN_DECODER -c model/model.npz.decoder.yml -m model/model.iter$ITER.npz -d $GPUS -b 12 -n -w 6000 \
        | sed 's/\@\@ //g' \
        | ../tools/moses-scripts/scripts/recaser/detruecase.perl \
        | ../tools/moses-scripts/scripts/tokenizer/detokenizer.perl -l $TRG \
        > data/$prefix.$TRG.output
done