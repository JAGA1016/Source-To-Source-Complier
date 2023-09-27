#include <stdlib.h>
#include <string.h>
#include "definitions.h"
#include "declarations.h"
#include "utils.h"
#include "parsetree.h"


// Syntax tree printing on terminal
void printAST(struct Node *T) {
	int count=0;
	if(!T) return;
	switch (T->type) {
		case 'b': printf("BOOL "); break;
		case 'i':
			printf("NUM ");
			break;
		case 'x':
			printf("STRING ");
			break;
		case 'v':
			if (T->value==0) {
				if(!(T->t1)) { printf("VAR "); }
				else { printf("ARR VAR "); printAST(T->t1); }
			}
			else if (T->value==2) { printf("VARREF"); }
			else {
				if(!(T->t1)) { printf("VARADDR"); }
				else { printf("ARRADDR VAR "); printAST(T->t1); }
			}
			break;
		case 'm':
			printf("UMINUS ");
			printAST(T->t1);
			break;
		case 'a':
			switch (T->value) {
				case '+':
					printf("ADD ");
					break;
				case '-':
					printf("SUB ");
					break;
				case '*':
					printf("MUL ");
					break;
				case '/':
					printf("DIV ");
					break;
				case '%':
					printf("MOD ");
					break;
			}
			printAST(T->t1);
			printAST(T->t2);
			break;
		case 'r':
			switch (T->value) {
				case '>':
					printf("GREATER ");
					break;
				case '<':
					printf("LESS ");
					break;
				case '=':
					printf("EQ ");
					break;
				case 'g':
					printf("GEQ ");
					break;
				case 'l':
					printf("LEQ ");
					break;
			}
			printAST(T->t1);
			printAST(T->t2);
			break;
		case 'l':
			switch(T->value) {
				case 'a':
					printf("AND ");
					printAST(T->t1);
					printAST(T->t2);
					break;
				case 'o':
					printf("OR ");
					printAST(T->t1);
					printAST(T->t2);
					break;
				case 'n':
					printf("NOT ");
					printAST(T->t1);
					break;
			}
			break;
		case 'R':
			printf("FUNCALL ");
			if(!(T->t1)) { printf("VAR "); }
			else { printf("ARRREF VAR "); printAST(T->t1); }
			break;
		case 'W':
			printf("FUNCALL ");
			printAST(T->t1);
			break;
		case 'A':
			printf("ASSIGN ");
			if(T->value==1) { printf("VARREF "); printAST(T->t2); }
			else {
				if(!(T->t1)) { printf("VAR "); printAST(T->t2); }
				else { printf("ARRREF VAR "); printAST(T->t1); printAST(T->t2); }
			}
			break;
		case 'S':
			if (T->t2) { printAST(T->t1); printAST(T->t2); printf("\n"); }
			else { printAST(T->t1); printf("\n"); }
			break;
		case 'C':
			printf("IF ");
			printAST(T->t1);
			printf("\n");
			printAST(T->t2);
			if (T->t3) {
				printf("ELSE\n");
				printAST(T->t3);
			}
			printf("ENDIF");
			break;
		case 'L':
			printf("WHILE ");
			printAST(T->t1);
			printf("\n");
			printAST(T->t2);
			printf("ENDWHILE");
			break;
		case 'F':
			printf("FUNCALL ARG ");
			if(!(T->t1)) printf("NONE");
			else printAST(T->t1); return;
			break;
		case 'P':
			printAST(T->t1);
			struct Node* param = T->t2;
			int i=1;
			while (param) {
				if (i==10) {return;}
				param = param->t2;
				i = i+1;
			}
			if (T->t2) {
			printf(", ");
			printAST(T->t2);
			}
			break;
	}
}


// C code generation
void GenC_Code(struct Node *T) {
	if(!T) return;
	switch (T->type) {
		case 'b': fprintf(fp, "%d",  T->value); break;
		case 'i':
			fprintf(fp, "%d", T->value);
			break;
		case 'x':
			fprintf(fp, "%s", T->g->Name);
			break;
		case 'v':
			if (T->value==0) {
				if(!(T->t1)) { fprintf(fp, "%s", T->g->Name); }
				else { fprintf(fp, "%s[", T->g->Name); GenC_Code(T->t1);fprintf(fp, "]"); }
			}
			else if (T->value==2) { fprintf(fp, "*%s", T->g->Name); }
			else {
				if(!(T->t1)) { fprintf(fp, "&%s", T->g->Name); }
				else { fprintf(fp, "&%s[", T->g->Name); GenC_Code(T->t1);fprintf(fp, "]"); }
			}
			break;
		case 'm':
			fprintf(fp, "-");
			GenC_Code(T->t1);
			break;
		case 'a':
			GenC_Code(T->t1);
			switch (T->value) {
				case '+':
					fprintf(fp, " + ");
					break;
				case '-':
					fprintf(fp, " - ");
					break;
				case '*':
					fprintf(fp, " * ");
					break;
				case '/':
					fprintf(fp, " / ");
					break;
				case '%':
					fprintf(fp, " %% ");
					break;
			}
			GenC_Code(T->t2);
			break;
		case 'r':
			GenC_Code(T->t1);
			switch (T->value) {
				case '>':
					fprintf(fp, " > ");
					break;
				case '<':
					fprintf(fp, " < ");
					break;
				case '=':
					fprintf(fp, " == ");
					break;
				case 'g':
					fprintf(fp, " >= ");
					break;
				case 'l':
					fprintf(fp, " <= ");
					break;
			}
			GenC_Code(T->t2);
			break;
		case 'l':
			switch(T->value) {
				case 'a':
					GenC_Code(T->t1);
					fprintf(fp, " && ");
					GenC_Code(T->t2);
					break;
				case 'o':
					GenC_Code(T->t1);
					fprintf(fp, " || ");
					GenC_Code(T->t2);
					break;
				case 'n':
					fprintf(fp, " !(");
					GenC_Code(T->t1);
					fprintf(fp, ")");
					break;
			}
			break;
		case 'R':
			fprintf(fp, "scanf(\"%%d\", &");
			if(!(T->t1)) { fprintf(fp, "%s);", T->g->Name); }
			else { fprintf(fp, "%s[", T->g->Name); GenC_Code(T->t1); fprintf(fp, "]);"); }
			break;
		case 'W':
			switch(T->value) {
				case 'i':
					fprintf(fp, "printf(\"%%d\\n\", ");
					GenC_Code(T->t1);
					fprintf(fp, ");");
					break;
				case 'x':
					fprintf(fp, "printf(");
					GenC_Code(T->t1);
					fprintf(fp, ");");
					break;
			}
			break;
		case 'A':
			if(T->value==1) { fprintf(fp, "*%s = ", T->g->Name); GenC_Code(T->t2); fprintf(fp, ";"); }
			else {
				if(!(T->t1)) { fprintf(fp, "%s = ", T->g->Name); GenC_Code(T->t2); fprintf(fp, ";"); }
				else { fprintf(fp, "%s[", T->g->Name); GenC_Code(T->t1); fprintf(fp, "] = "); GenC_Code(T->t2); fprintf(fp, ";"); }
			}
			break;
		case 'S':
			if (T->t2) { GenC_Code(T->t1); GenC_Code(T->t2); fprintf(fp, "\n"); }
			else { GenC_Code(T->t1); fprintf(fp, "\n"); }
			break;
		case 'C':
			fprintf(fp, "if(");
			GenC_Code(T->t1);
			fprintf(fp, "){\n");
			GenC_Code(T->t2);
			fprintf(fp, "}");
			if (T->t3) {
				fprintf(fp, "\nelse{\n");
				GenC_Code(T->t3);
				fprintf(fp, "}");
			}
			break;
		case 'L':
			fprintf(fp, "while(");
			GenC_Code(T->t1);
			fprintf(fp, "){\n");
			GenC_Code(T->t2);
			fprintf(fp, "}");
			break;
		case 'F':
			fprintf(fp, "%s(", T->h->Name);
			if(T->t1) GenC_Code(T->t1);
			fprintf(fp, ")");
			if (T->value == 1) fprintf(fp, ";");
			break;
		case 'P':
			GenC_Code(T->t1);
			struct Node* param = T->t2;
			int i=1;
			while (param) {
				if (i==10) {return;}
				param = param->t2;
				i = i+1;
			}
			if (T->t2) {
			fprintf(fp, ", ");
			GenC_Code(T->t2);
			}
			break;
	}
}
