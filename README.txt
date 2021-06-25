----------------------------------------------------------------------------------
Instructions for training Finnish-Swedish NMT models using CSC Puhti-supercomputer
----------------------------------------------------------------------------------

---------------------
Using CSC environment
---------------------

- Create CSC user and project and apply for Puhti access:
https://docs.csc.fi/support/tutorials/puhti_quick/

- Connect to Puhti
ssh <csc_username>@puhti.csc.fi

- Start and interactive session
sinteractive --account <project_id> --time 10:00:00 --mem 16000
- Interrupting the session
exit

- Starting training
sbatch /scratch/<project_id/run_puhti.sh
- Check situation
squeue -l -u $USER
- Follow latest
tail -f $(ls -Art slurm* | tail -n 1)
- Check outcome using e.g. vim
vim slurm-<job_id>.out
- Cancelling
scancel <job-id>

----------------------------------------------------------------------
Instructions for training Finnish-Swedish Marian-NMT Transformer model
----------------------------------------------------------------------

- Setup Marian-NMT by running commands from marian-setup.sh 
	- Replace <project_id> with your project id, e.g. project_2001234
	- If there are errors, google and install missing requirements

- Create folders for own models, e.g.
mkdir marian/examples/fi-sv_transformer/
mkdir marian/examples/fi-sv_transformer/scripts

- Move train_model.sh to folder fi-sv_transformer e.g. using scp
- and files download-files.sh, preprocess-data.sh, translate.sh, and validate.sh to folder fi-sv_transformer/scripts

cd /scratch/<project_id>/marian/examples/fi-sv_transformer/
- Run commands from setup_marian_training.sh

- Implement necessary changes to run_puhti.sh move it to e.g. folder /scratch/<project_id/
	- Check first using gputest and max time 00:10:00 that everything works
- Train model
sbatch /scratch/<project_id/run_puhti.sh

- Test the trained model
cd /scratch/<project_id>/marian/examples/fi-sv_transformer/
- Save test sentences to file named e.g. testi
- Run translate.sh:
sh scripts/translate.sh testi
- Read translations from file testi.output

---------------------------------------------------------------------------
Instructions for training Fairseq Transformer and BERT-NMT models
---------------------------------------------------------------------------

- Install Fairseq and BERT-NMT by running commands from bert-nmt_setup.sh 
	- Do changes that are described in the comments

- Follow the Marian-NMT instructions to get data to folder /scratch/<project_id>/marian/examples/fi-sv_transformer/data
	- Or you can run the commands from setup_marian_training.sh to get the data

- Implement necessary changes run_bert-nmt_preprocess.sh move it to e.g. folder /scratch/<project_id/
- Do preprosessing
sbatch /scratch/<project_id/run_bert-nmt_preprocess.sh

- Move bert-nmt_train.sh to folder /scratch/<project_id/


- Implement necessary changes to run_puhti.sh move it to e.g. folder /scratch/<project_id/
	- Check first using gputest and max time 00:10:00 that everything works
- Train model
sbatch /scratch/<project_id/run_puhti.sh

- Tests for Fairseq model
fairseq-generate \
    /scratch/<project_id>/bertnmt_data/ \
    --path /scratch/<project_id>/bertnmt_data/fairseq_fi_sv/checkpoint_best.pt \
    --batch-size 128 --beam 12 --fp16 --gen-subset test1 --scoring sacrebleu --source-lang fi --target-lang sv --remove-bpe > fairseq-generate_output.txt
- Read results from fairseq-generate_output.txt

- When the Fairseq model has been trained, implement necessary changes to bert-nmt_train.sh
	- Comment the fairseq part and uncomment the bert-nmt part

- Train BERT-NMT model
sbatch /scratch/<project_id/run_puhti.sh

- Tests for BERT-NMT model
module load pytorch/1.6
INSTALL_PATH=/projappl/<project_id>/site-packages/
export PYTHONPATH="${PYTHONPATH}:$INSTALL_PATH"
python3 /scratch/<project_id>/bert-nmt/generate.py /scratch/<project_id>/bertnmt_data/ --path /scratch/<project_id>/bertnmt_data/bert-nmt_fi_sv/checkpoint_best.pt -s fi -t sv \
	--batch-size 128 --beam 12 --fp16 --gen-subset test1 --scoring sacrebleu --remove-bpe --bert-model-name /scratch/<project_id>/bert-base-finnish-uncased-v1 > bert-nmt_generate_output.txt
- Read results from bert-nmt_generate_output.txt	
