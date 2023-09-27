all: compiler

lex.yy.c: compiler.l
	lex compiler.l

y.tab.c y.tab.h: compiler.y
	yacc -d compiler.y

compiler: definitions.h declarations.h utils.h parsetree.h y.tab.c y.tab.h lex.yy.c
	cc lex.yy.c y.tab.c -o compiler

clean:
	rm -rf lex.yy.c y.tab.* compiler y.tab.* output*

run :
	./compiler
exec : 
	gcc output.c -o output
runc : 
	./output

