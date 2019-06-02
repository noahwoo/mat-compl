#!/bin/bash

if [ $# -ne 5 ] 
then
  echo "usage: $0 cluster round id2feature id2id algo"
  exit 1
fi
cluster=$1
round=$2
id2feature=$3
id2id=$4
algo=$5
K=10

for i in {1..10} 
do
  lmda=`echo "$i*0.1" | bc`
  echo "++training lambda=$lmda"
  $cluster $id2feature $id2id $lmda $K $algo >& cora.lnk.lmda-rnd$round-$i.view
done
