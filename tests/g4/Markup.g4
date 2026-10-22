lexer grammar Markup;

channels { WHITESPACE, COMMENTS }

tokens { TEXT }

COMMENT : '<!--' .*? '-->' -> channel(COMMENTS) ;
OPEN : '<' -> pushMode(TAG) ;
ENTITY : '&' [a-z]+ ';' | '&#' [0-9]+ ';' | '&#x' [0-9a-fA-F]+ ';' ;
WORD : [\p{L}\p{Nd}]+ -> type(TEXT) ;
SPACE : [ \t\r\n]+ -> channel(WHITESPACE) ;
SYMBOL : ~[<&\p{L}\p{Nd} \t\r\n]+ -> type(TEXT) ;

mode TAG;
CLOSE : '>' -> popMode ;
SLASH_CLOSE : '/>' -> popMode ;
SLASH : '/' ;
EQUALS : '=' ;
NAME : [\p{Alpha}_:] [\p{Alpha}\p{Digit}_:.\-]* ;
QUOTE : '"' -> more, pushMode(VALUE) ;
TAG_SPACE : [ \t\r\n]+ -> skip ;

mode VALUE;
VALUE_END : '"' -> popMode ;
VALUE_CHAR : ~["<&]+ -> more ;
VALUE_ENTITY : '&' [a-z]+ ';' -> more ;
