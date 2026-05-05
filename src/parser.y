%{
/*
 * Parser + AST + Semantic Analysis + IR Generation for SimpleImp DSL
 * Student: MUKESH T | Reg: RA2311026050205
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ─────────────────────────────
   AST Node Types
───────────────────────────── */
typedef enum {
    NODE_NUM, NODE_VAR, NODE_ASSIGN, NODE_BINOP,
    NODE_IF, NODE_WHILE, NODE_PRINT, NODE_BLOCK,
    NODE_DECL, NODE_RETURN, NODE_PROGRAM
} NodeType;

typedef struct ASTNode {
    NodeType type;
    int       ival;
    char     *sval;
    char      op;
    char      relop[3];
    struct ASTNode *left, *right, *cond, *then_branch, *else_branch, *body;
    struct ASTNode **stmts;
    int        stmt_count;
} ASTNode;

/* ─────────────────────────────
   Symbol Table
───────────────────────────── */
#define MAX_SYMBOLS 256
typedef struct { char name[64]; int declared; } Symbol;
Symbol sym_table[MAX_SYMBOLS];
int sym_count = 0;

void sym_declare(const char *name) {
    for (int i = 0; i < sym_count; i++)
        if (strcmp(sym_table[i].name, name) == 0) { sym_table[i].declared = 1; return; }
    strncpy(sym_table[sym_count].name, name, 63);
    sym_table[sym_count++].declared = 1;
}

int sym_lookup(const char *name) {
    for (int i = 0; i < sym_count; i++)
        if (strcmp(sym_table[i].name, name) == 0) return 1;
    return 0;
}

/* ─────────────────────────────
   IR Generation
───────────────────────────── */
int temp_count = 0, label_count = 0;
char* new_temp()  { char *t = malloc(16); sprintf(t, "t%d", temp_count++); return t; }
char* new_label() { char *l = malloc(16); sprintf(l, "L%d", label_count++); return l; }

FILE *ir_out;

char* gen_ir(ASTNode *node);

char* gen_ir(ASTNode *node) {
    if (!node) return NULL;
    switch (node->type) {
        case NODE_NUM: {
            char *t = new_temp();
            fprintf(ir_out, "  %s = %d\n", t, node->ival);
            return t;
        }
        case NODE_VAR:
            return strdup(node->sval);
        case NODE_BINOP: {
            char *l = gen_ir(node->left);
            char *r = gen_ir(node->right);
            char *t = new_temp();
            fprintf(ir_out, "  %s = %s %c %s\n", t, l, node->op, r);
            return t;
        }
        case NODE_ASSIGN: {
            char *val = gen_ir(node->right);
            fprintf(ir_out, "  %s = %s\n", node->sval, val);
            return node->sval;
        }
        case NODE_DECL: {
            fprintf(ir_out, "  decl %s\n", node->sval);
            return NULL;
        }
        case NODE_IF: {
            char *cond = gen_ir(node->cond);
            char *lelse = new_label();
            char *lend  = new_label();
            fprintf(ir_out, "  if_false %s goto %s\n", cond, lelse);
            gen_ir(node->then_branch);
            fprintf(ir_out, "  goto %s\n", lend);
            fprintf(ir_out, "%s:\n", lelse);
            if (node->else_branch) gen_ir(node->else_branch);
            fprintf(ir_out, "%s:\n", lend);
            return NULL;
        }
        case NODE_WHILE: {
            char *lstart = new_label();
            char *lend   = new_label();
            fprintf(ir_out, "%s:\n", lstart);
            char *cond = gen_ir(node->cond);
            fprintf(ir_out, "  if_false %s goto %s\n", cond, lend);
            gen_ir(node->body);
            fprintf(ir_out, "  goto %s\n", lstart);
            fprintf(ir_out, "%s:\n", lend);
            return NULL;
        }
        case NODE_PRINT: {
            char *val = gen_ir(node->left);
            fprintf(ir_out, "  print %s\n", val);
            return NULL;
        }
        case NODE_RETURN: {
            char *val = gen_ir(node->left);
            fprintf(ir_out, "  return %s\n", val);
            return NULL;
        }
        case NODE_BLOCK:
        case NODE_PROGRAM:
            for (int i = 0; i < node->stmt_count; i++)
                gen_ir(node->stmts[i]);
            return NULL;
        default: return NULL;
    }
}

/* ─────────────────────────────
   Semantic Analysis
───────────────────────────── */
int sem_errors = 0;

void semantic_check(ASTNode *node) {
    if (!node) return;
    switch (node->type) {
        case NODE_VAR:
            if (!sym_lookup(node->sval)) {
                fprintf(stderr, "[Semantic Error] Undeclared variable '%s'\n", node->sval);
                sem_errors++;
            }
            break;
        case NODE_DECL:
            sym_declare(node->sval);
            break;
        case NODE_ASSIGN:
            if (!sym_lookup(node->sval)) {
                fprintf(stderr, "[Semantic Error] Assignment to undeclared variable '%s'\n", node->sval);
                sem_errors++;
            }
            semantic_check(node->right);
            break;
        case NODE_BINOP:
            semantic_check(node->left);
            semantic_check(node->right);
            break;
        case NODE_IF:
            semantic_check(node->cond);
            semantic_check(node->then_branch);
            semantic_check(node->else_branch);
            break;
        case NODE_WHILE:
            semantic_check(node->cond);
            semantic_check(node->body);
            break;
        case NODE_PRINT:
        case NODE_RETURN:
            semantic_check(node->left);
            break;
        case NODE_BLOCK:
        case NODE_PROGRAM:
            for (int i = 0; i < node->stmt_count; i++)
                semantic_check(node->stmts[i]);
            break;
        default: break;
    }
}

/* ─────────────────────────────
   AST Helpers
───────────────────────────── */
ASTNode* make_node(NodeType t) {
    ASTNode *n = calloc(1, sizeof(ASTNode));
    n->type = t;
    return n;
}

ASTNode* make_num(int v)       { ASTNode *n=make_node(NODE_NUM);  n->ival=v; return n; }
ASTNode* make_var(char *s)     { ASTNode *n=make_node(NODE_VAR);  n->sval=s; return n; }
ASTNode* make_decl(char *s)    { ASTNode *n=make_node(NODE_DECL); n->sval=s; return n; }

ASTNode* make_assign(char *s, ASTNode *val) {
    ASTNode *n=make_node(NODE_ASSIGN); n->sval=s; n->right=val; return n;
}
ASTNode* make_binop(char op, ASTNode *l, ASTNode *r) {
    ASTNode *n=make_node(NODE_BINOP); n->op=op; n->left=l; n->right=r; return n;
}
ASTNode* make_if(ASTNode *c, ASTNode *t, ASTNode *e) {
    ASTNode *n=make_node(NODE_IF); n->cond=c; n->then_branch=t; n->else_branch=e; return n;
}
ASTNode* make_while(ASTNode *c, ASTNode *b) {
    ASTNode *n=make_node(NODE_WHILE); n->cond=c; n->body=b; return n;
}
ASTNode* make_print(ASTNode *v)  { ASTNode *n=make_node(NODE_PRINT);  n->left=v; return n; }
ASTNode* make_return(ASTNode *v) { ASTNode *n=make_node(NODE_RETURN); n->left=v; return n; }

ASTNode* make_block(ASTNode **stmts, int cnt) {
    ASTNode *n=make_node(NODE_BLOCK);
    n->stmts=stmts; n->stmt_count=cnt; return n;
}

ASTNode* append_stmt(ASTNode *block, ASTNode *stmt) {
    if (!block) {
        ASTNode **arr = malloc(sizeof(ASTNode*));
        arr[0] = stmt;
        return make_block(arr, 1);
    }
    block->stmts = realloc(block->stmts, sizeof(ASTNode*) * (block->stmt_count+1));
    block->stmts[block->stmt_count++] = stmt;
    return block;
}

/* ─────────────────────────────
   Print AST
───────────────────────────── */
void print_ast(ASTNode *node, int depth) {
    if (!node) return;
    for (int i=0;i<depth;i++) printf("  ");
    switch (node->type) {
        case NODE_NUM:    printf("NUM(%d)\n", node->ival); break;
        case NODE_VAR:    printf("VAR(%s)\n", node->sval); break;
        case NODE_DECL:   printf("DECL(%s)\n", node->sval); break;
        case NODE_ASSIGN: printf("ASSIGN(%s)\n", node->sval);
                          print_ast(node->right, depth+1); break;
        case NODE_BINOP:  printf("BINOP(%c)\n", node->op);
                          print_ast(node->left, depth+1);
                          print_ast(node->right, depth+1); break;
        case NODE_IF:     printf("IF\n");
                          print_ast(node->cond, depth+1);
                          print_ast(node->then_branch, depth+1);
                          print_ast(node->else_branch, depth+1); break;
        case NODE_WHILE:  printf("WHILE\n");
                          print_ast(node->cond, depth+1);
                          print_ast(node->body, depth+1); break;
        case NODE_PRINT:  printf("PRINT\n"); print_ast(node->left, depth+1); break;
        case NODE_RETURN: printf("RETURN\n"); print_ast(node->left, depth+1); break;
        case NODE_BLOCK:
        case NODE_PROGRAM:printf("BLOCK(%d stmts)\n", node->stmt_count);
                          for(int i=0;i<node->stmt_count;i++) print_ast(node->stmts[i], depth+1);
                          break;
    }
}

extern int yylex();
extern int line_num;
void yyerror(const char *msg) {
    fprintf(stderr, "[Parse Error] %s at line %d\n", msg, line_num);
}

ASTNode *root;
%}

%union {
    int   ival;
    char *sval;
    struct ASTNode *node;
}

%token <ival> NUMBER
%token <sval> IDENTIFIER
%token INT IF ELSE WHILE PRINT RETURN BEGIN_TOK END_TOK
%token EQ NEQ LEQ GEQ LT GT ASSIGN
%token PLUS MINUS MUL DIV LPAREN RPAREN SEMICOLON

%type <node> program stmts stmt expr rel_expr block

%left PLUS MINUS
%left MUL DIV
%nonassoc LT GT LEQ GEQ EQ NEQ

%%

program:
    stmts   { root = $1; }
;

stmts:
    stmts stmt  { $$ = append_stmt($1, $2); }
  | stmt        { $$ = append_stmt(NULL, $1); }
;

stmt:
    INT IDENTIFIER SEMICOLON                    { sym_declare($2); $$ = make_decl($2); }
  | IDENTIFIER ASSIGN expr SEMICOLON           { $$ = make_assign($1, $3); }
  | IF LPAREN rel_expr RPAREN block            { $$ = make_if($3, $5, NULL); }
  | IF LPAREN rel_expr RPAREN block ELSE block { $$ = make_if($3, $5, $7); }
  | WHILE LPAREN rel_expr RPAREN block         { $$ = make_while($3, $5); }
  | PRINT LPAREN expr RPAREN SEMICOLON         { $$ = make_print($3); }
  | RETURN expr SEMICOLON                      { $$ = make_return($2); }
;

block:
    BEGIN_TOK stmts END_TOK  { $$ = $2; }
  | stmt                     { $$ = append_stmt(NULL, $1); }
;

rel_expr:
    expr EQ  expr { $$ = make_binop('=', $1, $3); }
  | expr NEQ expr { $$ = make_binop('!', $1, $3); }
  | expr LT  expr { $$ = make_binop('<', $1, $3); }
  | expr GT  expr { $$ = make_binop('>', $1, $3); }
  | expr LEQ expr { $$ = make_binop('L', $1, $3); }
  | expr GEQ expr { $$ = make_binop('G', $1, $3); }
;

expr:
    expr PLUS  expr  { $$ = make_binop('+', $1, $3); }
  | expr MINUS expr  { $$ = make_binop('-', $1, $3); }
  | expr MUL   expr  { $$ = make_binop('*', $1, $3); }
  | expr DIV   expr  { $$ = make_binop('/', $1, $3); }
  | LPAREN expr RPAREN { $$ = $2; }
  | NUMBER           { $$ = make_num($1); }
  | IDENTIFIER       { $$ = make_var($1); }
;

%%

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *f = fopen(argv[1], "r");
        if (!f) { fprintf(stderr, "Cannot open file: %s\n", argv[1]); return 1; }
        extern FILE *yyin;
        yyin = f;
    }

    printf("=== SimpleImp DSL Compiler ===\n");
    printf("Student: MUKESH T | Reg: RA2311026050205\n\n");

    yyparse();

    if (!root) { fprintf(stderr, "Parsing failed.\n"); return 1; }

    printf("[Phase 1] Lexical Analysis    : DONE\n");
    printf("[Phase 2] Parsing             : DONE\n\n");

    printf("[Phase 3] AST:\n");
    print_ast(root, 1);

    printf("\n[Phase 4] Semantic Analysis:\n");
    semantic_check(root);
    if (sem_errors == 0) printf("  No semantic errors found.\n");
    else printf("  %d semantic error(s) found.\n", sem_errors);

    printf("\n[Phase 5] Intermediate Code (3-Address Code):\n");
    ir_out = stdout;
    fprintf(ir_out, "--- IR Start ---\n");
    gen_ir(root);
    fprintf(ir_out, "--- IR End ---\n");

    /* Also write IR to file */
    ir_out = fopen("output/program.ir", "w");
    if (ir_out) {
        fprintf(ir_out, "; SimpleImp DSL - 3-Address IR\n");
        fprintf(ir_out, "; Student: MUKESH T | RA2311026050205\n\n");
        temp_count = 0; label_count = 0;
        gen_ir(root);
        fclose(ir_out);
        printf("\nIR also written to output/program.ir\n");
    }

    printf("\n=== Compilation Complete ===\n");
    return sem_errors ? 1 : 0;
}
