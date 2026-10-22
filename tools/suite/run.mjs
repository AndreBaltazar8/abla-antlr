// run.mjs TESTS_JSONL WORK_DIR RUNNER [FILTER]
// Runs ANTLR's runtime testsuite (extracted with Extract.java and rendered
// with Abla.test.stg) against the Abla runtime and compares each test's
// stdout and stderr with the testsuite's expected output and errors.
import { readFileSync, writeFileSync, mkdirSync, rmSync } from "fs";
import { spawnSync } from "child_process";
const [jsonl, work, runner, filter] = process.argv.slice(2);
const tests = readFileSync(jsonl, "utf8").trim().split("\n").map(JSON.parse);
let pass = 0, fail = 0, skipped = 0;
const failures = [];
const byGroup = {};
for (const t of tests) {
  const id = t.group + "/" + t.name;
  if (filter && !id.includes(filter)) continue;
  if (t.ignoredForNode) { skipped++; continue; }
  const dir = `${work}/${t.group}/${t.name}`;
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(dir, { recursive: true });
  writeFileSync(`${dir}/${t.grammarName}.g4`, t.rendered);
  for (const s of t.slaves || []) writeFileSync(`${dir}/${s.name}.g4`, s.rendered);
  writeFileSync(`${dir}/input`, t.input ?? "");
  const r = spawnSync(runner, [dir, t.grammarName, t.type, t.startRule ?? "", t.showDFA ? "1" : "0", t.showDiagnosticErrors ? "1" : "0"], { encoding: "utf8", timeout: 60000 });
  // as the testsuite's StreamVacuum reads them: line by line, each line ended by \n
  const lines = s => s.length === 0 ? "" : s.split(/\r\n|\r|\n/).slice(0, s.match(/(\r\n|\r|\n)$/) ? -1 : undefined).map(l => l + "\n").join("");
  const out = lines(r.stdout ?? ""), err = lines(r.stderr ?? "");
  const wantOut = t.output ?? "", wantErr = t.errors ?? "";
  const ok = r.status === 0 && out === wantOut && err === wantErr;
  const g = (byGroup[t.group] ??= { pass: 0, fail: 0 });
  if (ok) { pass++; g.pass++; }
  else {
    fail++; g.fail++;
    failures.push({ id, status: r.status, signal: r.signal, out, wantOut, err, wantErr });
  }
  writeFileSync(`${dir}/result.json`, JSON.stringify({ ok, status: r.status, out, wantOut, err, wantErr }, null, 1));
}
for (const f of failures) {
  console.log(`FAIL ${f.id} (exit ${f.status}${f.signal ? " " + f.signal : ""})`);
  if (f.out !== f.wantOut) console.log("  stdout want " + JSON.stringify(f.wantOut).slice(0, 300) + "\n         got  " + JSON.stringify(f.out).slice(0, 300));
  if (f.err !== f.wantErr) console.log("  stderr want " + JSON.stringify(f.wantErr).slice(0, 300) + "\n         got  " + JSON.stringify(f.err).slice(0, 300));
}
for (const [g, c] of Object.entries(byGroup)) console.log(`${g}: ${c.pass}/${c.pass + c.fail}`);
console.log(`passed ${pass} of ${pass + fail}` + (skipped ? ` (${skipped} not run: ignored for the JavaScript target too)` : ""));
process.exit(fail ? 1 : 0);
