// Reference dump from a generated ANTLR JavaScript parser (antlr4 4.9.x runtime).
// usage: bun tools/oracle.mjs <Lexer.js> <Parser.js> <startRule> <out-dir> <input files...>
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { basename, resolve, join } from 'node:path';

const [lexerPath, parserPath, startRule, outDir, ...inputs] = process.argv.slice(2);
const Lexer = (await import(resolve(lexerPath))).default;
const Parser = (await import(resolve(parserPath))).default;
const antlr4 = (await import(Bun.resolveSync('antlr4', resolve(lexerPath)))).default;

const esc = (s) => s.replace(/\\/g, '\\\\').replace(/\n/g, '\\n').replace(/\r/g, '\\r').replace(/\t/g, '\\t');

class Collector extends antlr4.error.ErrorListener {
  constructor(out) { super(); this.out = out; }
  syntaxError(recognizer, offendingSymbol, line, column, msg) { this.out.push(`${line}:${column} ${esc(msg)}`); }
}

export function dump(src) {
  const lexerErrors = [], errors = [];
  const lexer = new Lexer(new antlr4.InputStream(src));
  lexer.removeErrorListeners();
  lexer.addErrorListener(new Collector(lexerErrors));
  const tokens = new antlr4.CommonTokenStream(lexer);
  const parser = new Parser(tokens);
  parser.buildParseTrees = true;
  parser.removeErrorListeners();
  parser.addErrorListener(new Collector(errors));
  const tree = parser[startRule]();
  tokens.fill();
  const lines = ['#tokens'];
  for (const t of tokens.tokens) lines.push(`${t.type} ${t.channel} ${t.line}:${t.column} ${t.start} ${t.stop} ${esc(t.text)}`);
  lines.push('#tree', tree.toStringTree(parser.ruleNames), '#errors', ...errors, '#lexer', ...lexerErrors);
  return lines.join('\n') + '\n';
}

mkdirSync(outDir, { recursive: true });
const t0 = performance.now();
for (const f of inputs) writeFileSync(join(outDir, basename(f) + '.out'), dump(readFileSync(f, 'utf8')));
console.error(`${inputs.length} files in ${(performance.now() - t0).toFixed(0)} ms`);
