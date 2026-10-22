grammar Calc;

options { language = JavaScript; }

tokens { INDENT, DEDENT }

program : statement* EOF ;

statement
    : ID '=' expr ';'                 # assign
    | 'print' expr (',' expr)* ';'    # print
    | '{' statement* '}'              # block
    | {this.allowEmpty}? ';'          # empty
    ;

expr
    : <assoc=right> expr '^' expr                 # power
    | '-' expr                                    # negate
    | expr op=('*' | '/' | '%') expr              # mul
    | expr op=('+' | '-') expr                    # add
    | expr '?' expr ':' expr                      # ternary
    | expr '!'                                    # factorial
    | fn=ID '(' (args+=expr (',' args+=expr)*)? ')' # call
    | (INT | FLOAT)                               # number
    | ID                                          # name
    | '(' expr ')'                                # parens
    ;

ID : LETTER (LETTER | DIGIT | '_')* ;
INT : DIGIT+ ;
FLOAT : DIGIT+ '.' DIGIT* | '.' DIGIT+ ;
STRING : '"' (ESC | ~["\\\r\n])*? '"' ;
fragment ESC : '\\' [btnr"\\] | '\\u' HEX HEX HEX HEX ;
fragment HEX : [0-9a-fA-F] ;
fragment LETTER : [a-zA-Z] ;
fragment DIGIT : [0-9] ;
COMMENT : '/*' .*? '*/' -> channel(HIDDEN) ;
LINE_COMMENT : '//' ~[\r\n]* -> skip ;
WS : [ \t\r\n\u000C]+ -> skip ;
