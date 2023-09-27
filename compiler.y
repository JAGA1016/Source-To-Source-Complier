%{
#include <stdio.h>
#include <stdlib.h>
#include "generator.h"

void yyerror(const char *str)
{
	fprintf(stderr,"Error at Line %d: %s\n", LineCount, str);
	exit(0);
}


%}

%union
{
	int number;
	struct Symbol *Symbol;
	struct Node *node;
}

%token <number> NUMBER;
%token <number> MAIN READ WRITE COMMA BREAK RETURN EXIT START;
%token <number> IF THEN ELSE ENDIF;
%token <number> WHILE DO ENDWHILE;
%token <number> DECL ENDDECL INTEGER BOOLEAN;
%token <number> AND OR NOT;
%token <number> BOOL;
%token <Symbol> ID DX;


%type <number> SetType FunctionType;
%type <node> exp stringExp slist statement Variable FunctionCall ActualParameters;
%type <Symbol> GlobalDeclarations NewScope InitNewScope StaticScope InitializeStaticScope StackScope InitializeStackScope;

%nonassoc UMINUS

%left NOT AND OR
%right EQ
%left '<' '>' GE LE
%left '+' '-'
%left '*' '/' '%'

%start Program
%%

Program: { fprintf(fp, "#include<stdio.h>\n#include<stdbool.h>\n"); } GlobalDeclarations FunctionDefinitions MainFunction


GlobalDeclarations:	StaticScope { GlobalScope = $1; }
FunctionDefinitions:	FunctionDefinitions Function
						| ;
MainFunction:	INTEGER MAIN { printf("FUN INT MAIN\n"); fprintf(fp, "int main(){\n"); } '{' StaticScope START slist RETURN exp BREAK EXIT '}' 
							{ 
								printAST($7);
								printf("RETURN ");
								printAST($9);
								printf("ENDMAIN\n");
								GenC_Code($7);
								fprintf(fp, "return ");
								GenC_Code($9);
								fprintf(fp, ";\n}");
								exit(0);
							}

StaticScope: InitializeStaticScope Declarations { $$ = $1; }
StackScope: InitializeStackScope Declarations
			{
				$1->parent = Arg;
				$$ = $1;
			}

InitializeStaticScope:	{ $$ = NewScope('S'); }
InitializeStackScope:	{ $$ = NewScope('R'); }


Function:	FunctionType ID { fprintf(fp, "%s(", $2->Name); } '(' FormalParameters ')' { printf("\n"); fprintf(fp, "){\n"); } '{' StackScope START slist RETURN exp BREAK EXIT EndScope '}'
				{
					$2->Type = $1;
					InstallFunction($2, $9);
					printAST($11);
					printf("RETURN ");
					printAST($13);
					printf("\nENDFUN\n");
					GenC_Code($11);
					fprintf(fp, "return ");
					GenC_Code($13);
					fprintf(fp, ";\n}\n");
				}

FunctionType:	INTEGER		{ $$ = 1; printf("FUNDECL INT VAR PARAM "); fprintf(fp, "int "); }
				|	BOOLEAN	{ $$ = 0; printf("FUNDECL BOOL VAR PARAM "); fprintf(fp, "bool "); }


FormalParameters:	InitializeNewParameterList FormalParameterTypeList;

InitializeNewParameterList:	{ NewParameterList(); }

FormalParameterTypeList:	COMMA INTEGER TypeInt FormalParameterList { printf(", "); fprintf(fp, ", "); }
				|	COMMA BOOLEAN TypeBool FormalParameterList { printf(", "); fprintf(fp, ", "); }
				|	INTEGER TypeInt FormalParameterList
				|	BOOLEAN TypeBool FormalParameterList
				|   ;

FormalParameterList:	FormalParameterList COMMA ID { AddParam($3, 0); if(DeclType==1) {printf(", INT VAR"); fprintf(fp, ", int %s", $3->Name);} else {printf(", BOOL VAR"); fprintf(fp, ", bool %s", $3->Name);} }
				|   FormalParameterList COMMA '*' ID { AddParam($4, 1); if(DeclType==1) {printf(", INT VARREF"); fprintf(fp, ", int *%s", $4->Name);} else {printf(", BOOL VARREF"); fprintf(fp, ", bool *%s", $4->Name);} }
				|   ID { AddParam($1, 0); if(DeclType==1) {printf("INT VAR"); fprintf(fp, "int %s", $1->Name);} else {printf("BOOL VAR"); fprintf(fp, "bool %s", $1->Name);} }
				|	'*' ID { AddParam($2, 1); if(DeclType==1) {printf("INT VARREF"); fprintf(fp, "int *%s", $2->Name);} else {printf("BOOL VARREF"); fprintf(fp, "bool *%s", $2->Name);} }

Arguements:	InitializeNewArguementList	ArguementSet ;

InitializeNewArguementList:	{ NewArguementList(); }

ArguementSet: COMMA INTEGER TypeInt ArguementList { printf(", "); fprintf(fp, ", "); }
				|	COMMA BOOLEAN TypeBool ArguementList { printf(", "); fprintf(fp, ", "); }
				|	INTEGER TypeInt ArguementList
				|	BOOLEAN TypeBool ArguementList
				|   ;

ArguementList:	ArguementList COMMA ID { InstallArguement($3, 0); if(DeclType==1) {printf(", INT VAR"); fprintf(fp, ", int %s", $3->Name);} else {printf(", BOOL VAR"); fprintf(fp, ", bool %s", $3->Name);} }
				|   ArguementList COMMA '*' ID { InstallArguement($4, 1); if(DeclType==1) {printf(", INT VARREF"); fprintf(fp, ", int *%s", $4->Name);} else {printf(", BOOL VARREF"); fprintf(fp, ", bool *%s", $4->Name);} }
				|   ID { InstallArguement($1, 0); if(DeclType==1) {printf("INT VAR"); fprintf(fp, "int %s", $1->Name);} else {printf("BOOL VAR"); fprintf(fp, "bool %s", $1->Name);} }
				|	'*' ID { InstallArguement($2, 1); if(DeclType==1) {printf("INT VARREF"); fprintf(fp, "int *%s", $2->Name);} else {printf("BOOL VARREF"); fprintf(fp, "bool *%s", $2->Name);} }


NewScope:	InitNewScope Declarations { $$ = $1; }

InitNewScope:	{ $$ = NewScope(TopScope->Type); }

EndScope:	{
				if (TopScope->Type == 'R' && TopScope->parent->Type != 'A') TopScope->parent->Size += TopScope->Size;
				TopScope = TopScope->parent;
			}


Declarations:	DECL { printf("DECL\n"); } DeclarationBody ENDDECL { printf("ENDDECL\n"); }
				|	;

DeclarationBody:	DeclarationBody INTEGER { printf("INT "); fprintf(fp, "int "); } TypeInt DEFLIST BREAK { printf("\n"); fprintf(fp, ";\n"); }
					|	DeclarationBody BOOLEAN { printf("BOOL "); fprintf(fp, "bool "); } TypeBool DEFLIST BREAK { printf("\n"); fprintf(fp, ";\n"); }
					|	INTEGER { printf("INT "); fprintf(fp, "int "); } TypeInt DEFLIST BREAK { printf("\n"); fprintf(fp, ";\n"); }
					|	BOOLEAN { printf("BOOL "); fprintf(fp, "bool "); } TypeBool DEFLIST BREAK { printf("\n"); fprintf(fp, ";\n"); }

TypeInt:	{ DeclType = 1; }
TypeBool:	{ DeclType = 0; }

DEFLIST:	DEFLIST COMMA ID { InstallVariable($3, 1); printf(", VAR"); fprintf(fp, ", %s", $3->Name); }
			|	ID SetType { printf("FUN PARAM "); fprintf(fp, "%s(", $1->Name); } '(' Arguements ')'
				{
					$1->Type = $2;
					DeclareFunction($1, Arg);
					TopScope = TopScope->parent;
					DeclType = $2;
					fprintf(fp, ")");
				}
			|	ID { InstallVariable($1, 1); printf("VAR"); fprintf(fp, "%s", $1->Name); }
			|	DEFLIST COMMA ID '[' NUMBER ']' { InstallVariable($3, $5); printf(", ARR VAR NUM"); fprintf(fp, ", %s[%d]", $3->Name, $5); }
			|	ID '[' NUMBER ']' { InstallVariable($1, $3); printf("ARR VAR NUM"); fprintf(fp, "%s[%d]", $1->Name, $3); }
			|	DEFLIST COMMA ID SetType { printf(", FUN PARAM "); fprintf(fp, ", %s(", $3->Name); } '(' Arguements ')'
				{
					$3->Type = $4;
					DeclareFunction($3, Arg);
					TopScope = TopScope->parent;
					DeclType = $4;
					fprintf(fp, ")");
				}
SetType:	{	$$ = DeclType; }


slist:	slist statement BREAK { $$ = MakeNode(0, 'S', $1, $2, 0, 0, 0); }
		|	statement BREAK { $$ = MakeNode(0, 'S', $1, 0, 0, 0, 0); }

statement:	WRITE exp { $$ = MakeNode('i', 'W', $2, 0, 0, 0, 0); }
			|	WRITE '(' stringExp ')' { $$ = MakeNode('x', 'W', $3, 0, 0, 0, 0); }
			|	READ '(' ID ')' { $$ = MakeNode(0, 'R', 0, 0, 0, $3, 0); }
			|	READ '(' ID '[' exp ']' ')' { $$ = MakeNode(0, 'R', $5, 0, 0, $3, 0); }
			|	READ ID { $$ = MakeNode(0, 'R', 0, 0, 0, $2, 0); }
			|	READ ID '[' exp ']' { $$ = MakeNode(0, 'R', $4, 0, 0, $2, 0); }
			|	ID '=' exp { $$ = MakeNode(0, 'A', 0, $3, 0, $1, 0); }
			|	ID '[' exp ']' '=' exp { $$ = MakeNode(0, 'A', $3, $6, 0, $1, 0); }
			|	'*' ID '=' exp { $$ = MakeNode(1, 'A', 0, $4, 0, $2, 0); }
			|	IF exp THEN NewScope slist EndScope ENDIF { $$ = MakeNode(0, 'C', $2, $5, 0, $4, 0); }
			|	IF exp THEN NewScope slist EndScope ELSE NewScope slist EndScope ENDIF { $$ = MakeNode(0, 'C', $2, $5, $9, $4, $8); }
			|	WHILE exp DO NewScope slist EndScope ENDWHILE { $$ = MakeNode(0, 'L', $2, $5, 0, $4, 0); }
			|	ID '(' ')' { $$ = MakeNode(1, 'F', 0, 0, 0, 0, $1); }
			|	ID '(' ActualParameters ')' { $$ = MakeNode(1, 'F', $3, 0, 0, 0, $1); }

ActualParameters:	ActualParameters COMMA exp
					{
						struct Node *F = MakeNode(0, 'P', $3, 0, 0, 0, 0);
						$1->t2->t3 = F;
						$1->t2 = F;
						$$ = $1;
					}
					|	exp
						{
							$$ = MakeNode(1, 'P', $1, 0, 0, 0, 0);
							$$->t2 = $$;
						}

exp:	NUMBER	{ $$ = MakeNode($1, 'i', 0, 0, 0, 0, 0); }
		|	'-' exp %prec UMINUS { $$ = MakeNode(0, 'm', $2, 0, 0, 0, 0); }
		|	FunctionCall { $$ = $1; }
		|	Variable { $$ = $1; }
		|	exp '+' exp	{ $$ = MakeNode('+', 'a', $1, $3, 0, 0, 0); }
		|	exp '-' exp	{ $$ = MakeNode('-', 'a', $1, $3, 0, 0, 0); }
		|	exp '*' exp	{ $$ = MakeNode('*', 'a', $1, $3, 0, 0, 0); }
		|	exp '/' exp	{ $$ = MakeNode('/', 'a', $1, $3, 0, 0, 0); }
		|	exp '%' exp	{ $$ = MakeNode('%', 'a', $1, $3, 0, 0, 0); }
		|	exp '>' exp	{ $$ = MakeNode('>', 'r', $1, $3, 0, 0, 0); }
		|	exp '<' exp	{ $$ = MakeNode('<', 'r', $1, $3, 0, 0, 0); }
		|	exp GE exp	{ $$ = MakeNode('g', 'r', $1, $3, 0, 0, 0); }
		|	exp LE exp	{ $$ = MakeNode('l', 'r', $1, $3, 0, 0, 0); }
		|	exp EQ exp { $$ = MakeNode('=', 'r', $1, $3, 0, 0, 0); }
		|	exp AND exp	{ $$ = MakeNode('a', 'l', $1, $3, 0, 0, 0); }
		|	exp OR exp	{ $$ = MakeNode('o', 'l', $1, $3, 0, 0, 0); }
		|	NOT exp	{ $$ = MakeNode('n', 'l', $2, 0, 0, 0, 0); }
		|	'(' exp ')' { $$ = $2; }
		|	BOOL	{ $$ = MakeNode($1, 'b', 0, 0, 0, 0, 0); }

stringExp: DX { $$ = MakeNode(3, 'x', 0, 0, 0, $1, 0); }

Variable:	ID	{ $$ = MakeNode(0, 'v', 0, 0, 0, $1, 0); }
			|	ID '[' exp ']' { $$ = MakeNode(0, 'v', $3, 0, 0, $1, 0); }
			|	'&' ID	{ $$ = MakeNode(1, 'v', 0, 0, 0, $2, 0); }
			|	'&' ID '[' exp ']' { $$ = MakeNode(1, 'v', $4, 0, 0, $2, 0); }
			|	'*' ID	{ $$ = MakeNode(2, 'v', 0, 0, 0, $2, 0); }

FunctionCall:	ID '(' ')' { $$ = MakeNode(0, 'F', 0, 0, 0, 0, $1); }
				|	ID '(' ActualParameters ')' { $$ = MakeNode(0, 'F', $3, 0, 0, 0, $1); }


%%

int yywrap()
{
	return 1;
}

int main (int argc, char *argv[])
{
	remove("output.c");
	fp = fopen("output.c", "w");
	extern FILE * yyin;
	yyin = fopen(argv[1],"r");
	if (yyin) yyparse();
	else {
		yyparse();
	}
	fclose(fp);
	exit(0);
}