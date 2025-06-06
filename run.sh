iverilog -s top -o tb sag.v top.v
vvp -N ./tb
