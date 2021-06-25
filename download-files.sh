#!/bin/bash -v

# suffix of source language files
SRC=fi

# suffix of target language files
TRG=sv

mkdir -p temp_corpus_data
cd temp_corpus_data

# get and extract training data from OPUS
for corpus in OPUS-OpenSubtitles/v2018 OPUS-MultiParaCrawl/v5 OPUS-DGT/v2019 OPUS-EUbookshop/v2 OPUS-Europarl/v8 OPUS-Finlex/v2018 OPUS-fiskmo/v2 OPUS-EMEA/v3 OPUS-GNOME/v1 OPUS-QED/v2.0a OPUS-JRC-Acquis/v3.0 OPUS-bible-uedin/v1 OPUS-infopankki/v1 OPUS-Ubuntu/v14.10 OPUS-KDE4/v2 OPUS-wikimedia/v20190628 OPUS-EUconst/v1 OPUS-TildeMODEL/v2018 OPUS-PHP/v1 OPUS-ELRC_416/v1 OPUS-ELRA-W0305/v1
do 
wget -nc https://object.pouta.csc.fi/$corpus/moses/fi-sv.txt.zip
unzip -n fi-sv.txt.zip
rm fi-sv.txt.zip
done


# create corpus files
mkdir -p ../data
cat *.fi > ../data/corpus.fi
cat *.sv > ../data/corpus.sv

# clean
rm *

# download Tatoeba data for validation and test sets
wget -nc https://object.pouta.csc.fi/OPUS-Tatoeba/v2020-05-31/moses/fi-sv.txt.zip
unzip -n fi-sv.txt.zip

# choose random 5000 sentences as validation and the remaining for test set
shuf --random-source=Tatoeba.fi-sv.fi Tatoeba.fi-sv.fi | split -a1 -d -l 5000 - output.fi
shuf --random-source=Tatoeba.fi-sv.fi Tatoeba.fi-sv.sv | split -a1 -d -l 5000 - output.sv

mv output.fi0 ../data/valid.fi
mv output.fi1 ../data/tatoeba_test.fi
mv output.sv0 ../data/valid.sv
mv output.sv1 ../data/tatoeba_test.sv

# get fiskmo test data as another test set
wget -nc https://version.helsinki.fi/Helsinki-NLP/fiskmo/-/raw/master/testset/fi-sv/fiskmo_testset.fi.txt
wget -nc https://version.helsinki.fi/Helsinki-NLP/fiskmo/-/raw/master/testset/fi-sv/fiskmo_testset.sv.txt
mv fiskmo_testset.fi.txt ../data/fiskmo_test.fi
mv fiskmo_testset.sv.txt ../data/fiskmo_test.sv

# clean
cd ..
rm -r temp_corpus_data