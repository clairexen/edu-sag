set -ex
rm -vf tb
iverilog -Wall -s top -o tb.top sag.v nrsag.v nrsag2.v top.v
vvp -N ./tb.top
iverilog -Wall -s top -o tb.param param.v
vvp -N ./tb.param
