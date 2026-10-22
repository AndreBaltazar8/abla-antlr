// Prints a deserialized ATN in the format of tests/atn_dump.ab.
import { readFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
const [interpPath, runtimeFrom] = process.argv.slice(2);
const runtimeIndex = Bun.resolveSync('antlr4', resolve(runtimeFrom));
const antlr4 = (await import(runtimeIndex)).default;
const { Transition: T } = await import(join(dirname(runtimeIndex), 'atn/Transition.js'));
const text = readFileSync(interpPath, 'utf8');
const nums = text.slice(text.indexOf('atn:')).match(/\d+/g).map(Number);
const atn = new antlr4.atn.ATNDeserializer().deserialize(String.fromCharCode(...nums));
console.log(`type ${atn.grammarType} max ${atn.maxTokenType} states ${atn.states.length} decisions ${atn.decisionToState.length}`);
for (const s of atn.states) {
  const d = s.decision === undefined ? -1 : s.decision;
  const end = s.endState ? s.endState.stateNumber : -1;
  const lb = s.loopBackState ? s.loopBackState.stateNumber : -1;
  let line = `${s.stateNumber} ${s.stateType} ${s.ruleIndex} d${d} e${s.epsilonOnlyTransitions ? 1 : 0} end${end} lb${lb} pd${s.isPrecedenceDecision ? 1 : 0}:`;
  for (const t of s.transitions) {
    const k = t.serializationType;
    let a = 0, b = 0, f = -1, r = -1;
    if (k === T.RANGE) { a = t.start; b = t.stop; }
    else if (k === T.RULE) { a = t.ruleIndex; b = t.precedence; f = t.followState.stateNumber; }
    else if (k === T.PREDICATE) { a = t.ruleIndex; b = t.predIndex; }
    else if (k === T.PRECEDENCE) { a = t.precedence; }
    else if (k === T.ATOM) { a = t.label_; }
    else if (k === T.ACTION) { a = t.ruleIndex; b = t.actionIndex; }
    else if (k === T.SET || k === T.NOT_SET) { a = -9; }
    else if (k === T.EPSILON) { r = t.outermostPrecedenceReturn === undefined ? -1 : t.outermostPrecedenceReturn; }
    line += ` [${k} ${t.target.stateNumber} ${a} ${b} ${f} ${r}]`;
  }
  console.log(line);
}
