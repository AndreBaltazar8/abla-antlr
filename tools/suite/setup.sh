#!/bin/bash
# setup.sh WORK_DIR: fetches ANTLR 4.9.3's runtime testsuite and tool jar, builds
# the test descriptors and writes WORK_DIR/tests.jsonl rendered for Abla.
# Needs git, curl and a JDK (javac/java on PATH, or JAVA_HOME).
set -e
W=$(mkdir -p "$1" && cd "$1" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
JB=${JAVA_HOME:+$JAVA_HOME/bin/}
JAR=$W/antlr-4.9.3-complete.jar
SUM=afcd40946d3de4d81e28d7c88d467289e0587285d27adb172aecc5494a17df36
if [ ! -f "$JAR" ]; then curl -sfL -o "$JAR" https://www.antlr.org/download/antlr-4.9.3-complete.jar; fi
echo "$SUM  $JAR" | shasum -a 256 -c - >/dev/null
if [ ! -d "$W/antlr4" ]; then
    git clone -q --depth 1 --branch 4.9.3 --filter=blob:none --sparse https://github.com/antlr/antlr4.git "$W/antlr4"
    git -C "$W/antlr4" sparse-checkout set runtime-testsuite
fi
T=$W/antlr4/runtime-testsuite
B=$W/classes
rm -rf "$B"
mkdir -p "$B/proc" "$B/suite"
EXP=""
OPN=""
for p in main model tree util; do
    EXP="$EXP --add-exports=jdk.compiler/com.sun.tools.javac.$p=ALL-UNNAMED"
    OPN="$OPN -J--add-opens=jdk.compiler/com.sun.tools.javac.$p=ALL-UNNAMED"
done
${JB}javac $EXP -proc:none -d "$B/proc" "$T/annotations/src/org/antlr/v4/test/runtime/CommentHasStringValue.java" "$T/processors/src/org/antlr/v4/test/runtime/CommentHasStringValueProcessor.java"
cp -r "$T/processors/resources/META-INF" "$B/proc/"
(cd "$T/test/org/antlr/v4/test/runtime" && ${JB}javac $OPN $EXP -nowarn -cp "$JAR:$B/proc" -processorpath "$B/proc" -d "$B/suite" \
    RuntimeTestDescriptor.java BaseRuntimeTestDescriptor.java Base*TestDescriptor.java descriptors/*.java 2>&1 | grep -v '^Note:' || true)
${JB}javac -nowarn -cp "$JAR:$B/suite" -d "$B" "$HERE/Extract.java"
${JB}java -cp "$JAR:$B/suite:$B:$T/resources" Extract Abla "$HERE/Abla.test.stg" "$W/tests.jsonl"
wc -l < "$W/tests.jsonl" | tr -d ' ' | sed 's/$/ tests extracted/'
