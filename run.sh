set -ex
rm -vf tb
iverilog -s top -o tb sag.v nrsag.v nrsag2.v top.v
vvp -N ./tb
