%{
#include <stdio.h>
#include <string.h>
#include "definitions.h"
#include "y.tab.h"
extern int LineCount;
%}

%%
[0-9]+	{ yylval.number = atoi(yytext); return NUMBER; }
;		{ return BREAK; }
"decl"	{ return DECL; }
"enddecl"	{ return ENDDECL; }
"main()" { return MAIN; }
"integer"	{ return INTEGER; }
"boolean"	{ return BOOLEAN; }
"read"	{ return READ; }
"write"	{ return WRITE; }
"return" { return RETURN; }
"begin" { return START; }
"end"	{ return EXIT; }
"if"	{ return IF; }
"then"	{ return THEN; }
"else"	{ return ELSE; }
"endif"	{ return ENDIF; }
"while"	{ return WHILE; }
"do"	{ return DO; }
"endwhile"	{ return ENDWHILE; }
"AND"	{ return AND; }
"OR"	{ return OR; }
"NOT"	{ return NOT; }
"TRUE"	{ yylval.number = 1; return BOOL; }
"FALSE"	{ yylval.number = 0; return BOOL; }
[ \t]+ ;
"\n" { ++LineCount; }
[+\-*/%()=<>] { return (int)yytext[0]; }
[\[\]]	{ return (int)yytext[0]; }
[\{\}]	{ return (int)yytext[0]; }
"&"  { return (int)yytext[0]; }
">=" { return GE; }
"<=" { return LE; }
"=="	{ return EQ; }
","	{	return COMMA; }
[a-zA-Z][a-zA-Z0-9]*	{ struct Symbol *p = malloc(sizeof(struct Symbol)); p->Name = strdup(yytext); yylval.Symbol = p; return ID; }
[\"][a-zA-Z0-9+\-*/%()=<>\[\]\{\}&,!:;.|\\n\\t ]+[\"] { struct Symbol *p = malloc(sizeof(struct Symbol)); p->Name = strdup(yytext); yylval.Symbol = p; return DX;  }
%%