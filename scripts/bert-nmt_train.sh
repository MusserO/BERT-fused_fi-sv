#!/bin/bash

module purge

module load gcc/7.4.0
module load cuda/9.2.88
module load pytorch/1.6

src=fi
tgt=sv
DATAPATH="/scratch/<project_id>/bertnmt_data"
FAIRSEQ_SAVEDIR="/scratch/<project_id>/bertnmt_data/fairseq_${src}_${tgt}"
SAVEDIR="/scratch/<project_id>/bertnmt_data/bert-nmt_${src}_${tgt}"    
mkdir -p "$FAIRSEQ_SAVEDIR"
mkdir -p "$SAVEDIR"    

export CUDA_VISIBLE_DEVICES=0,1,2,3    
    
INSTALL_PATH=/projappl/<project_id>/site-packages/    
export PYTHONPATH="${PYTHONPATH}:$INSTALL_PATH"

#small fairseq a8f28ecb63ee01c33ea9f6986102136743d47ec2:
#fairseq-train "$DATAPATH" \
#    --arch transformer --optimizer adam --lr 0.0003 -s $src -t $tgt --label-smoothing 0.1 \
#    --dropout 0.1 --max-tokens 16000 --min-lr '1e-09' --lr-scheduler inverse_sqrt \
#    --criterion label_smoothed_cross_entropy --warmup-updates 16000 \
#    --validate-interval 1 --save-interval 1 --log-interval 500 --clip-norm 5 \
#    --adam-betas '(0.9,0.98)' --save-dir "$FAIRSEQ_SAVEDIR" --share-all-embeddings \
#    --distributed-world-size 4 --fp16 --seed 1111 | tee -a "$FAIRSEQ_SAVEDIR"/training.log

#large fairseq model, parameters mostly from https://github.com/pytorch/fairseq/blob/master/examples/scaling_nmt/README.md
#fairseq-train "$DATAPATH" \
#    --arch transformer_vaswani_wmt_en_de_big --share-all-embeddings \
#    --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
#    --lr 0.001 --lr-scheduler inverse_sqrt --warmup-updates 4000 --warmup-init-lr 1e-07 \
#    --dropout 0.3 --weight-decay 0.0 \
#    --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
#    --max-tokens 3584 \
#    --validate-interval 1 --save-interval 1 --log-interval 500 \
#    --fp16 --update-freq 32 -s $src -t $tgt --save-dir "$FAIRSEQ_SAVEDIR" \
#    --distributed-world-size 4 --seed 1111 | tee -a "$FAIRSEQ_SAVEDIR"/training.log
         
#train bert-nmt:
    
    
if [ ! -f "$SAVEDIR/checkpoint_nmt.pt" ]    
then    
    cp $FAIRSEQ_SAVEDIR/checkpoint_best.pt "$SAVEDIR/checkpoint_nmt.pt"    
fi    
if [ ! -f "$SAVEDIR/checkpoint_last.pt" ]    
then    
    warmup="--warmup-from-nmt --reset-lr-scheduler"    
else    
    warmup=""    
fi    

# small bert-nmt
#python3 /scratch/<project_id>/bert-nmt/train.py $DATAPATH \
#    --arch transformer --optimizer adam --lr 0.0005 -s $src -t $tgt --label-smoothing 0.1 \
#    --dropout 0.3 --max-tokens 16000 --min-lr '1e-09' --lr-scheduler inverse_sqrt --weight-decay 0.0001 \
#    --criterion label_smoothed_cross_entropy --max-update 150000 --warmup-updates 4000 --warmup-init-lr '1e-07' \
#    --adam-betas '(0.9,0.98)' --save-dir "$SAVEDIR" --share-all-embeddings $warmup \
#    --distributed-world-size 4 --fp16 \
#    --encoder-bert-dropout --encoder-bert-dropout-ratio 0.5 \
#    --bert-model-name /scratch/<project_id>/bert-base-finnish-uncased-v1 | tee -a "$SAVEDIR/training.log"

# large bert-nmt
python3 /scratch/<project_id>/bert-nmt/train.py $DATAPATH \
    --arch transformer_vaswani_wmt_en_de_big --optimizer adam --lr 0.0005 -s $src -t $tgt --label-smoothing 0.1 \
    --dropout 0.3 --max-tokens 3584 --min-lr '1e-09' --lr-scheduler inverse_sqrt --weight-decay 0.0001 \
    --criterion label_smoothed_cross_entropy --warmup-updates 4000 --warmup-init-lr '1e-07' \
    --adam-betas '(0.9,0.98)' --save-dir "$SAVEDIR" --share-all-embeddings $warmup \
    --distributed-world-size 4 --fp16 \
    --encoder-bert-dropout --encoder-bert-dropout-ratio 0.5 \
    --bert-model-name /scratch/<project_id>/bert-base-finnish-uncased-v1 | tee -a "$SAVEDIR/training.log"
