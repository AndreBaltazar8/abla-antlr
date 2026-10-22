#!/bin/sh
# g4_check.sh G4_INTERP OUT: compiles the grammars in tests/g4 and compares
# the .interp files with the ANTLR 4.9.3 tool's, in tests/g4/expected.
set -e
bin=$1
out=$2
rm -rf "$out"
mkdir -p "$out"
for n in Calc Markup Config QueryLexer QueryParser; do
    "$bin" tests/g4 "$n" "$out"
done
status=0
for f in tests/g4/expected/*.interp; do
    if ! cmp -s "$f" "$out/$(basename "$f")"; then
        echo "differs: $(basename "$f")"
        status=1
    fi
done
[ $status = 0 ] && echo "g4 grammars compile as the ANTLR tool does"
exit $status
