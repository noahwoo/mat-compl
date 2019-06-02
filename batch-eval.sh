#!/bin/bash

if [ $# -ne 3 ]
then
  echo "usage: $0 evaluator pattern label"
  exit 1
fi

evaluator=$1
pattern=$2
label=$3

for i in {1..10}
do
  echo "eval $pattern-$i.view with $label"
  $evaluator $label $pattern-$i.view
done
