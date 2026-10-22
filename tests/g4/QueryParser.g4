parser grammar QueryParser;

options { tokenVocab = QueryLexer; }

query : SELECT columns FROM table (WHERE condition)? EOF ;
columns : STAR | column (COMMA column)* ;
column : IDENT (DOT IDENT)? ;
table : IDENT (DOT IDENT)? ;
condition
    : condition AND condition
    | condition OR condition
    | NOT condition
    | LPAREN condition RPAREN
    | operand (EQ | NEQ | LT | LE | GT | GE) operand
    ;
operand : column | NUMBER | TEXT ;
