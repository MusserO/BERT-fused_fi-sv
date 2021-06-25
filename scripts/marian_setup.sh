#!/bin/bash

cd /scratch/<project_id>/
git clone https://github.com/marian-nmt/marian

module load cmake
module load gcc/7.4.0
module load cuda/9.2.88
 
mkdir marian/build
cd marian/build
cmake ..
make -j4
