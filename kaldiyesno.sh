#!/bin/bash
#script for kaldi yesno tutorial
#intended to be run within kaldi_yesno directory

mkdir -p data/train_yesno
mkdir -p data/test_yesno
./data_prep.py
utils/utt2spk_to_spk2utt.pl data/train_yesno/utt2spk > data/train_yesno/spk2utt
utils/utt2spk_to_spk2utt.pl data/test_yesno/utt2spk > data/test_yesno/spk2utt
utils/fix_data_dir.sh data/train_yesno/
utils/fix_data_dir.sh data/test_yesno/
mkdir dict
echo -e "K\nEH\nL\nOW\nN" > dict/phones.txt  
echo -e "YES K EH N\nNO L OW" > dict/lexicon.txt 
echo "SIL" > dict/silence_phones.txt
echo "SIL" > dict/optional_silence.txt
mv dict/phones.txt dict/nonsilence_phones.txt
cp dict/lexicon.txt dict/lexicon_words.txt
echo "<SIL> SIL" >> dict/lexicon.txt 
utils/prepare_lang.sh --position-dependent-phones false dict "<SIL>" dict/tmp data/lang
lm/prepare_lm.sh
steps/make_mfcc.sh --nj 1 data/train_yesno exp/make_mfcc/train_yesno 
steps/compute_cmvn_stats.sh data/train_yesno exp/make_mfcc/train_yesno
steps/train_mono.sh --nj 1 --cmd utils/run.pl data/train_yesno data/lang exp/mono
../kaldi/src/fstbin/fstcopy 'ark:gunzip -c ../kaldi-yesno-tutorial/exp/mono/fsts.1.gz|' ark,t:- | head -n 20
steps/make_mfcc.sh --nj 1 data/test_yesno exp/make_mfcc/test_yesno 
steps/compute_cmvn_stats.sh data/test_yesno exp/make_mfcc/test_yesno
utils/mkgraph.sh --mono data/lang_test_tg exp/mono exp/mono/graph_tgpr
steps/decode.sh --nj 1 exp/mono/graph_tgpr data/test_yesno exp/mono/decode_test_yesno
steps/get_ctm.sh data/test_yesno exp/mono/graph_tgpr exp/mono/decode_test_yesno