#!/bin/bash
#SBATCH --job-name=<job_name>
#SBATCH --account=<project_id>
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --mem=64G
#SBATCH --time=72:00:00
#SBATCH --gres=gpu:v100:4

#Marian-NMT:
cd /scratch/<project_id>/marian/examples/fi-sv_transformer/
srun bash train_model.sh 0 1 2 3

#BERT-NMT:
#cd /scratch/<project_id>/
#srun bash bert-nmt_train.sh