#!/bin/bash -v

# suffix of source language files
SRC=fi

# suffix of target language files
TRG=sv

# path to moses decoder: https://github.com/moses-smt/mosesdecoder
mosesdecoder=../tools/moses-scripts

# path to subword segmentation scripts: https://github.com/rsennrich/subword-nmt
subword_nmt=../tools/subword-nmt/subword_nmt

# tokenize
file=$1
cat $file \
	| $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $SRC \
	| $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $SRC > $file.tok
	
# apply truecaser (cleaned training corpus)
$mosesdecoder/scripts/recaser/truecase.perl -model model/tc.$SRC < $file.tok > $file.tc

# apply BPE
$subword_nmt/apply_bpe.py -c model/$SRC$TRG.bpe < $file.tc > $file.bpe


ITER=`cat model/valid.log | grep translation | sort -rg -k12,12 -t' ' | cut -f8 -d' ' | head -n1`
cat $file.bpe \
        | ../../build/marian-decoder -c model/model.npz.decoder.yml -m model/model.iter$ITER.npz --cpu-threads 1 -b 12 -n -w 6000 \
        | sed 's/\@\@ //g' \
        | ../tools/moses-scripts/scripts/recaser/detruecase.perl \
        | ../tools/moses-scripts/scripts/tokenizer/detokenizer.perl -l $TRG \
        > $file.output
		
rm $file.tok $file.tc $file.bpe
