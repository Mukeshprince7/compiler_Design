# Makefile - SimpleImp DSL Compiler
# Student: MUKESH T | RA2311026050205

CC     = gcc
BISON  = bison
FLEX   = flex
CFLAGS = -Wall -g

all: compiler

compiler: src/parser.tab.c src/lex.yy.c
	$(CC) $(CFLAGS) -o compiler src/parser.tab.c src/lex.yy.c -lfl
	@echo "Build successful! Run: ./compiler test/sample.simp"

src/parser.tab.c src/parser.tab.h: src/parser.y
	$(BISON) -d -o src/parser.tab.c src/parser.y

src/lex.yy.c: src/lexer.l src/parser.tab.h
	$(FLEX) -o src/lex.yy.c src/lexer.l

run: compiler
	mkdir -p output
	./compiler test/sample.simp

clean:
	rm -f compiler src/parser.tab.c src/parser.tab.h src/lex.yy.c output/*.ir
