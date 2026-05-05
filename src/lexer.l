%{
/*
 * Lexer for SimpleImp DSL
 * Student: MUKESH T | Reg: RA2311026050205
 * Tokens: keywords, identifiers, numbers, operators, delimiters
 */
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_num = 1;
%}

%%

[ \t\r]+            { /* skip whitespace */ }
\n                  { line_num++; }
"//".*              { /* skip single-line comments */ }

"int"               { return INT; }
"if"                { return IF; }
"else"              { return ELSE; }
"while"             { return WHILE; }
"print"             { return PRINT; }
"return"            { return RETURN; }
"begin"             { return BEGIN_TOK; }
"end"               { return END_TOK; }

[0-9]+              { yylval.ival = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* {
                        yylval.sval = strdup(yytext);
                        return IDENTIFIER;
                    }

"=="                { return EQ; }
"!="                { return NEQ; }
"<="                { return LEQ; }
">="                { return GEQ; }
"<"                 { return LT; }
">"                 { return GT; }
"="                 { return ASSIGN; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return MUL; }
"/"                 { return DIV; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }
";"                 { return SEMICOLON; }

.                   {
                        fprintf(stderr, "[Lexer Error] Unknown character '%s' at line %d\n", yytext, line_num);
                    }

%%

int yywrap() { return 1; }
