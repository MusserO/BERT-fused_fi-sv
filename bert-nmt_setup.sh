#!/bin/bash    
    
cd /scratch/<project_id>/    
    
git clone https://github.com/bert-nmt/bert-nmt    
    
module load pytorch/1.6    
    
git clone https://github.com/pytorch/fairseq    
cd fairseq    
git checkout a8f28ecb63ee01c33ea9f6986102136743d47ec2
    
INSTALL_PATH=/scratch/<project_id>/site-packages/
mkdir -p "$INSTALL_PATH"
pip install ./ --target="$INSTALL_PATH" --ignore-installed
export PYTHONPATH="${PYTHONPATH}:$INSTALL_PATH"

rm -r "${INSTALL_PATH}dataclasses*"
    
cd ..    
    
git clone https://github.com/NVIDIA/apex
cd apex
pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" \
  --global-option="--deprecated_fused_adam" --global-option="--xentropy" \
  --global-option="--fast_multihead_attn" ./
cd ..

pip install pyarrow
pip install subword-nmt
    
# download FinBert pytorch version    
mkdir -p bert-base-finnish-uncased-v1    
cd bert-base-finnish-uncased-v1    
wget https://s3.amazonaws.com/models.huggingface.co/bert/TurkuNLP/bert-base-finnish-uncased-v1/config.json    
wget https://cdn.huggingface.co/TurkuNLP/bert-base-finnish-uncased-v1/pytorch_model.bin    
wget https://cdn.huggingface.co/TurkuNLP/bert-base-finnish-uncased-v1/tf_model.h5    
wget https://cdn.huggingface.co/TurkuNLP/bert-base-finnish-uncased-v1/tokenizer.json    
wget https://cdn.huggingface.co/TurkuNLP/bert-base-finnish-uncased-v1/vocab.txt    
    
# preprocess data    
SRC=fi    
datapath="/scratch/<project_id>/marian/examples/fi-sv_transformer/data"    
mosesdecoder="/scratch/<project_id>/marian/examples/tools/moses-scripts"    
for sub in corpus.bpe valid.bpe tatoeba_test.bpe fiskmo_test.bpe    
do    
    sed -r 's/(@@ )|(@@ ?$)//g' "${datapath}/${sub}.${SRC}" > ${sub}.bert.${SRC}.tok    
    "${mosesdecoder}/scripts/tokenizer/detokenizer.perl" -l $SRC < ${sub}.bert.${SRC}.tok > "${datapath}/${sub}.bert.${SRC}"    
    rm ${sub}.bert.${SRC}.tok    
done    
    
sbatch /scratch/<project_id>/run_bert-nmt_preprocess.sh    
    
# change /scratch/<project_id>/fairseq/optim/adam.py lines 144-145 to avoid userwarning:    
	# from: exp_avg.mul_(beta1).add_(1 - beta1, grad)     
	#       exp_avg_sq.mul_(beta2).addcmul_(1 - beta2, grad, grad)    
	# to:   exp_avg.mul_(beta1).add_(grad, alpha=1 - beta1)    
	#       exp_avg_sq.mul_(beta2).addcmul_(grad, grad, value=1 - beta2)    
 # and line 159 from: p_data_fp32.add_(-group['weight_decay'] * group['lr'], p_data_fp32)    
 #               to:  p_data_fp32.add_(p_data_fp32, alpha=-group['weight_decay'] * group['lr'])    
 # and line 161 from: p_data_fp32.addcdiv_(-step_size, exp_avg, denom)    
 #               to:  p_data_fp32.addcdiv_(exp_avg, denom, value=-step_size)    
     
# replace /scratch/<project_id>/bert-nmt/fairseq_cli/train.py (only contains line "../train.py") with:
#import os
#os.system('python3 /scratch/<project_id>/bert-nmt/train.py')
	
# change fairseq/modules/multihead_attention.py line 132:
	# from: q *= self.scaling 
	#   to: q = q * self.scaling  

# add following code to /scratch/<project_id>/bert-nmt/fairseq/trainer.py line 491:    
# if sample["net_input"]["bert_input"].shape[1] > self.model.bert_encoder.config.max_position_embeddings:    
#     print("Invalid bert_input shape:{}".format(sample["net_input"]["bert_input"].shape))    
#     return None    
# to disregard too long inputs    
    
    
# /scratch/<project_id>/bert-nmt/fairseq/models/transformer.py lines 160 and 478:    
	# from: args.bert_out_dim = bertencoder.hidden_size    
	# to:   args.bert_out_dim = bertencoder.config.hidden_size    
    
# /scratch/<project_id>/bert-nmt/fairseq/models/fairseq_model.py, line 241:    
    # from: bert_encoder_padding_mask = bert_input.eq(self.berttokenizer.pad())    
    # to:   bert_encoder_padding_mask = bert_input.eq(self.berttokenizer.pad)    
    
# /scratch/<project_id>/bert-nmt/fairseq/models/fairseq_model.py", line 242:    
    # from: bert_encoder_out, _ =  self.bert_encoder(bert_input, output_all_encoded_layers=True, attention_mask= 1. - bert_encoder_padding_mask)    
	# to:   _, _, bert_encoder_out = self.bert_encoder(bert_input, output_hidden_states=True, attention_mask= ~bert_encoder_padding_mask)
    
# /scratch/<project_id>/bert-nmt/fairseq/search.py, line 83:
	# from: torch.div(self.indices_buf, vocab_size, out=self.beams_buf)
	# to:   self.beams_buf = self.indices_buf // vocab_size
	
# /scratch/<project_id>/bert-nmt/fairseq/sequence_generator.py, line 493-498:
# from:
#  active_mask = buffer('active_mask')
#  torch.add(
#     eos_mask.type_as(cand_offsets) * cand_size,
#     cand_offsets[:eos_mask.size(1)],
#     out=active_mask,
#  )
# to:
#  active_mask = torch.add(
#     eos_mask.type_as(cand_offsets) * cand_size,
#     cand_offsets[:eos_mask.size(1)],
#  ) 
