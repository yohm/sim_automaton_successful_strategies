#!/bin/bash
set -eux

make_figs() {
  cnt=0
  mkdir -p $2
  cat $1 | while read line
  do
    cnt=`expr $cnt + 1`
    ruby simplify_transition_graph.rb $line | dot -T png -o $2/$cnt.png
  done
}

make_figs results/n3m2_PS2_distinguishable fig_PS2_dis
make_figs results/n3m2_PS2 fig_PS2
make_figs results/n3m3_FSS fig_FS2

