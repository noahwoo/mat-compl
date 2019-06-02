#!/bin/bash

round=$1
root=examples/cora-ml-filter
jarroot=/home/jianmin/jars

for i in {0..10} 
do
  lmda=`echo "$i*0.1" | bc`
  echo "++training lambda=$lmda"
  hadoop dfs -rmr $root/lnk-rnd$round-lmda/segment
  hadoop jar $jarroot/ssplsa-nlmda.jar segment -conf ./conf/ssplsa.cora-ml.xml -Dsegment.lambda=$lmda $root/input-lnk $root/lnk-rnd$round-lmda
  hadoop dfs -rmr $root/lnk-rnd$round-lmda/lmda-$i/model
  hadoop jar $jarroot/ssplsa-nlmda.jar train -conf ./conf/ssplsa.cora-ml.xml $root/lnk-rnd$round-lmda/segment $root/lnk-rnd$round-lmda/lmda-$i
  hadoop jar $jarroot/ssplsa-nlmda.jar view -conf ./conf/ssplsa.cora-ml.xml $root/lnk-rnd$round-lmda/lmda-$i/model 0 5 100 >& cora-ml.lnk.lmda-rnd$round-$i.view
done
