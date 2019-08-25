#!/bin/bash
set -eux

cnt=0
while read line
do
  cnt=`expr $cnt + 1`
  ruby simplify_transition_graph.rb $line | dot -T png -o ,/$cnt.png
done

