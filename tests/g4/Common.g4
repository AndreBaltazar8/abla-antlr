parser grammar Common;

name : ID ('.' ID)* ;
literal : INT | STRING | 'true' | 'false' ;
list : '[' (item (',' item)*)? ']' ;
item : literal | name ;
