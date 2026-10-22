#!/bin/sh
# usage: tools/compare.sh <dump-binary> <Lexer.interp> <Parser.interp> <rule> <oracle-dir> <out-dir> <inputs...>
bin=$1; lexer=$2; parser=$3; rule=$4; oracle=$5; out=$6; shift 6
mkdir -p "$out"
pass=0; fail=0
for f in "$@"; do
  b=$(basename "$f")
  "$bin" "$lexer" "$parser" "$rule" "$f" > "$out/$b.out" 2>&1
  if cmp -s "$out/$b.out" "$oracle/$b.out"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $b"; fi
done
echo "pass=$pass fail=$fail"
