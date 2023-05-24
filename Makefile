mython:		lex.yy.c mython.tab.c mython.tab.h hash_table.c hash_table.h stack.c stack.h
	gcc -o mython mython.tab.c lex.yy.c -ly -ll hash_table.c stack.c

lex.yy.c:	mython.l
	flex mython.l

mython.tab.c:	mython.y
	bison -vd mython.y

clean:
	rm -rf mython.tab.* lex.yy.* mython.output mython
