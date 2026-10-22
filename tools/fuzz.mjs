// Writes mutated copies of input files, to compare error recovery against the oracle.
// usage: bun tools/fuzz.mjs <Parser.interp> <seed> <count> <out-dir> <inputs...>
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

const [parserInterp, seedText, countText, outDir, ...inputs] = process.argv.slice(2);
let seed = Number(seedText) >>> 0;
const rand = (n) => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed % n; };
const interp = readFileSync(parserInterp, 'utf8');
const literals = interp.split('token symbolic names:')[0].split('\n').filter((l) => l.startsWith("'")).map((l) => l.slice(1, -1));
const junk = ['@', '$', '`', '\\', '"', "'", '#', '\n', ' ', 'é', '\u{1F600}', '0x', '1e', '.', '..', ';;', '{', '}', '(', ')', '[', ']', 'x', '_a1'];
const sources = inputs.map((f) => readFileSync(f, 'utf8'));

function mutate(text) {
  const n = 1 + rand(3);
  for (let i = 0; i < n; i++) {
    const at = rand(text.length + 1);
    switch (rand(7)) {
      case 0: text = text.slice(0, at) + text.slice(at + 1 + rand(12)); break;
      case 1: text = text.slice(0, at) + literals[rand(literals.length)] + text.slice(at); break;
      case 2: text = text.slice(0, at) + ' ' + literals[rand(literals.length)] + ' ' + text.slice(at); break;
      case 3: text = text.slice(0, at) + junk[rand(junk.length)] + text.slice(at); break;
      case 4: { const len = rand(40); text = text.slice(0, at) + text.slice(at, at + len) + text.slice(at); break; }
      case 5: text = text.slice(0, at); break;
      default: { const b = rand(text.length + 1); const [x, y] = at < b ? [at, b] : [b, at]; text = text.slice(0, x) + text.slice(y, y + rand(20)) + text.slice(x); }
    }
  }
  return text;
}

mkdirSync(outDir, { recursive: true });
const count = Number(countText);
for (let i = 0; i < count; i++) {
  const src = sources[rand(sources.length)];
  writeFileSync(join(outDir, `fuzz${String(i).padStart(5, '0')}.txt`), mutate(src));
}
