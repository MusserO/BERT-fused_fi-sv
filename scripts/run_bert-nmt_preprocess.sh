#!/bin/bash
#SBATCH --job-name=bert-nmt_preprocess
#SBATCH --account=<project_id>
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu 4000
#SBATCH --time=08:00:00

datapath="/scratch/<project_id>/marian/examples/fi-sv_transformer/data"

module load pytorch/1.6

cd /scratch/<project_id>/bert-nmt/
srun python3 preprocess.py --source-lang fi --target-lang sv --fp16 --workers 8 \
  --trainpref "${datapath}/corpus.bpe" --validpref "${datapath}/valid.bpe" --testpref "${datapath}/tatoeba_test.bpe","${datapath}/fiskmo_test.bpe" \
  --destdir /scratch/<project_id>/bertnmt_data/ --joined-dictionary --bert-model-name /scratch/<project_id>/bert-base-finnish-uncased-v1
