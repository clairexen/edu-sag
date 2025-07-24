#!/bin/bash
# (Hint: Run e.g. `python3 mermaid.py -d WoRlLeDh` to dump all intermediate
# values of the SAG core in a compact and easy-to-inspect format.)
set -ex
rm -vf tb
iverilog -Wall -s top -o tb.top sag.v opt.v nrsag.v nrsag2.v top.v
sleep 2; vvp -N ./tb.top
iverilog -Wall -s top -o tb.param param.v
sleep 2; vvp -N ./tb.param
