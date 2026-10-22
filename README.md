# Abla ANTLR

An ANTLR 4 runtime for Abla. Grammars load from the `.interp` files the ANTLR
tool writes next to its generated code, so no Java is needed at build or run
time. A parse behaves exactly as the antlr4 4.9 JavaScript runtime does with
the tool's generated parser: the same tokens, the same parse tree, the same
syntax error messages at the same positions, and the same error recovery.

```abla
import "abla/io"
import "abla/fs"
import "src/antlr.ab"

fun main: int {
    val antlr = antlrLoad(path("ExprLexer.interp").readText(), path("ExprParser.interp").readText())
    if (antlr.error.size > 0) {
        println(antlr.error)
        return 1
    }
    val result = antlr.parse("1 + 2 * (3", "expr")
    println(antlrTreeText(result.tree, antlr.ruleNames()))
    for (e in result.errors) println("line ${e.line}:${e.column} ${e.message}")
    result.errors.size
}
```

## API

`antlrLoad(lexerInterp, parserInterp)` takes the text of the two `.interp`
files (a combined grammar's tool output has both) and returns an `Antlr`.
`error` is empty when both loaded. The `Antlr` keeps the prediction caches
(the DFAs), so one instance should parse many inputs, as a generated parser's
static caches do.

`antlr.parse(source, startRule)` lexes and parses `source` from the named
rule and returns an `AntlrResult`:

| Field | Contents |
|---|---|
| `tree` | the root `AntlrNode` |
| `tokens` | every token the lexer produced, hidden channels and `EOF` included |
| `errors` | the parser's syntax errors, `AntlrError(line, column, message)` |
| `lexerErrors` | token recognition errors; the lexer skips the character, as with the default listener |

`AntlrNode` is a rule node or a token node:

| Field | Rule node | Token node |
|---|---|---|
| `kind` | `nodeRule` | `nodeToken`, or `nodeError` for a token consumed or conjured during error recovery |
| `ruleIndex` | index into `antlr.ruleNames()` | -1 |
| `alt` | the alternative taken, numbered as in the grammar (below) | 0 |
| `token` | `null` | an `AntlrToken` |
| `children` | rule and token nodes in order | empty |
| `startToken`, `stopToken` | token indexes the rule spans (`stopToken` -1 when it matched nothing) | the token's index |

`AntlrToken` has `type`, `text`, `line`, `column`, `channel`, `tokenIndex`,
and `start`/`stop` (UTF-16 code unit offsets, as JavaScript counts them). A
token conjured by error recovery has `tokenIndex` -1 and text like
`<missing ';'>`.

`alt` is the grammar's alternative number. For a rule with several
alternatives it is the one chosen (1-based). In a left-recursive rule it is
the original alternative of the context, whether the context comes from a
primary alternative or an operator alternative, so `expr` labelled
alternatives can be told apart directly (the first alternative is 1). A rule
that failed before choosing has 0.

`antlrTreeText(node, ruleNames)` is `toStringTree(ruleNames)`.

## Scope

- Lexers: modes, `skip`, `more`, `type`, `channel`, `pushMode`/`popMode`.
  Custom actions and semantic predicates in lexer rules have no code to run
  in interpreter mode: actions do nothing and predicates are true.
- Parsers: ALL(\*) prediction (SLL with the DFA cache, then full-context LL),
  left-recursive rules with precedence predicates, the generated code's
  LL(1) switches and `sync` points, and `DefaultErrorStrategy`. User
  semantic predicates (`{...}?`) are true; embedded actions do nothing.
- The serialized ATN is the version 3 format of ANTLR 4.9 (with or without
  the Unicode SMP sets). ANTLR 4.10 and later write a different format.

## How it matches the generated parser

Generated parser code and `ParserInterpreter` don't report errors the same way:
the generated code answers LL(1) decisions with a `switch` on the next token,
syncs at fixed places and numbers its states from the grammar. This runtime
compiles the parser ATN into the operations the code generator would have
emitted for it (using the tool's own LL(1) analysis), and interprets those.
The ATN simulators are ports of the JavaScript runtime's, quirks included:
for example, its context merge never collapses a one-element array to a
singleton, and `precedenceFilterSuppressed` can be undefined, which is not
equal to false.

## Verify

```sh
make check
```

`make conformance` compares this runtime with a generated JavaScript parser on
a set of inputs: `tools/oracle.mjs` dumps tokens, the tree and the syntax
errors from the generated parser under bun, and `build/parse-dump` dumps the
same from this runtime. `make fuzz` mutates the inputs first, to exercise
error recovery.

```sh
make conformance LEXER=MyLexer.interp PARSER=MyParser.interp \
    LEXER_JS=MyLexer.js PARSER_JS=MyParser.js RULE=program INPUTS="tests/*.txt"
```

## License

MIT
