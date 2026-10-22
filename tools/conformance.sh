#!/bin/sh
# Compares the Abla runtime with a generated JavaScript parser on a set of inputs.
# usage: tools/conformance.sh <Lexer.interp> <Parser.interp> <Lexer.js> <Parser.js> <start-rule> <work-dir> <inputs...>
set -e
lexer=$1; parser=$2; lexerJs=$3; parserJs=$4; rule=$5; work=$6; shift 6
here=$(cd "$(dirname "$0")/.." && pwd)
rm -rf "$work"; mkdir -p "$work"
bun "$here/tools/oracle.mjs" "$lexerJs" "$parserJs" "$rule" "$work/oracle" "$@"
for f in "$@"; do cat "$work/oracle/$(basename "$f").out"; done > "$work/expected.txt"
"$here/build/parse-dump" "$lexer" "$parser" "$rule" "$@" > "$work/actual.txt"
if cmp -s "$work/expected.txt" "$work/actual.txt"; then
  echo "conformance: $# inputs identical"
  exit 0
fi
fails=0
mkdir -p "$work/actual"
for f in "$@"; do
  b=$(basename "$f")
  "$here/build/parse-dump" "$lexer" "$parser" "$rule" "$f" > "$work/actual/$b.out"
  cmp -s "$work/actual/$b.out" "$work/oracle/$b.out" || { echo "differs: $b"; fails=$((fails+1)); }
done
echo "conformance: $fails of $# inputs differ (see $work)"
exit 1
