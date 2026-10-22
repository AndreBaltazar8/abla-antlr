grammar Config;
import Common;

file : (section | entry)* EOF ;
section : '[' name ']' entry* ;
entry : name '=' value ';'? ;
value : literal | list | name ;
item : value ;

ID : [a-zA-Z_] [a-zA-Z_0-9]* ;
INT : [0-9]+ ;
STRING : '\'' (~['\r\n] | '\'\'')* '\'' ;
WS : [ \t\r\n]+ -> skip ;
