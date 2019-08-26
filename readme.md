# simplifying the transition graph of a strategy

## Prerequisites

- ruby
- graphviz (`dot` command)

## Usage

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
