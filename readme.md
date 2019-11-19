# Minimization of deterministic finite automata for successful strategies

Code used for the manuscript [Y. Murase & S.K. Baek, (2019)](https://arxiv.org/abs/1910.02634).

## Prerequisites

- ruby
- graphviz (`dot` command)

## Converting the history-based representation to the minimized state-based representation

```shell
ruby simplify_transition_graph.rb [strategy]
```

Strategy must be given as a string of 'c' and 'd'.
If the length of the string is 16 (40 and 512), it is regarded as a n=2,m=2 (n=3,m=2 and n=3,m=3) strategy, respectively.

It prints the simplified transition graph in dot format to standard output.

Examples:

- `ruby simplify_transition_graph.rb cdcddcdccdcddcdc | dot -T png -o a.png`
- `ruby simplify_transition_graph.rb cddcdddcddcccdcddddddcccdddcccccddcddddd`
- `ruby simplify_transition_graph.rb cdddcdddddcddddddccdddcdddddddddcdddcdddddddddddddcdddcdddddddddccddcdddcdcdddcddcdddcddddddddddcdddcdddddcdddcddcdddcdddddddddddccdddcdcccddcddcccccdccddcdddcdddcdddcddcdddcddcdcccdccddcdddcdcdddcddddccdddcddcddccddddddddcdcdcdcdddddcdddcddcdcdcddddddddddcdddcdddddddddddddcdddcdddddddddcdddcdddddddddddddcdddcdddddddddcdddcdddddcdddcddccddcddddddddddcdddcdddddcdddcddcdddcddddddddddddcdddcddcdddcddcdcccdccddccddcdddcdddcddcdddcddcdcccdccddcdddcdcdddcdddddcdddcddcdddcddddddddddcdddcdddddcdddcddcdddcdddddddddd`

## Batch Run

To make figures for PS2 (256 strategies), non-distinguishable & partially efficient & defensible strategies (288 strategies), m=3 fully successful strategies (256 strategies), run the following script.

```
./make_figs.sh
```

## Inspect the recovery path in the state-based representation

To see how the state changes in the state-based representation for a given initial state,

```
ruby recovery_path.rb [strategy] [initial state]
```

Please specify the initial state in the history-based representation.
For instance,

```shell
ruby recovery_path.rb cddcdddcddcdddcddddddcccddddcccdddcddddd cccdcc
```

