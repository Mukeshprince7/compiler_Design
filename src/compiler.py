#!/usr/bin/env python3
"""
SimpleImp DSL Compiler
Student  : MUKESH T
Reg No   : RA2311026050205
Language : Python (PLY - equivalent to Lex/YACC)
Phases   : Lexical Analysis → Parsing → AST → Semantic Analysis → IR Generation
"""

import ply.lex as lex
import ply.yacc as yacc
import sys, os

# ══════════════════════════════════════════════════════
#  PHASE 1 — LEXICAL ANALYSIS (equivalent to Lex/Flex)
# ══════════════════════════════════════════════════════

reserved = {
    'int': 'INT', 'if': 'IF', 'else': 'ELSE',
    'while': 'WHILE', 'print': 'PRINT',
    'return': 'RETURN', 'begin': 'BEGIN_TOK', 'end': 'END_TOK'
}

tokens = [
    'NUMBER', 'IDENTIFIER',
    'EQ', 'NEQ', 'LEQ', 'GEQ', 'LT', 'GT', 'ASSIGN',
    'PLUS', 'MINUS', 'MUL', 'DIV',
    'LPAREN', 'RPAREN', 'SEMICOLON'
] + list(reserved.values())

t_EQ        = r'=='
t_NEQ       = r'!='
t_LEQ       = r'<='
t_GEQ       = r'>='
t_LT        = r'<'
t_GT        = r'>'
t_ASSIGN    = r'='
t_PLUS      = r'\+'
t_MINUS     = r'-'
t_MUL       = r'\*'
t_DIV       = r'/'
t_LPAREN    = r'\('
t_RPAREN    = r'\)'
t_SEMICOLON = r';'
t_ignore    = ' \t\r'

def t_COMMENT(t):
    r'//.*'
    pass

def t_newline(t):
    r'\n+'
    t.lexer.lineno += len(t.value)

def t_NUMBER(t):
    r'\d+'
    t.value = int(t.value)
    return t

def t_IDENTIFIER(t):
    r'[a-zA-Z_][a-zA-Z0-9_]*'
    t.type = reserved.get(t.value, 'IDENTIFIER')
    return t

def t_error(t):
    print(f"  [Lexer Error] Unknown character '{t.value[0]}' at line {t.lexer.lineno}")
    t.lexer.skip(1)

lexer = lex.lex()

# Capture all tokens for display
def tokenize_for_display(source):
    lexer.input(source)
    lexer.lineno = 1
    token_list = []
    for tok in lexer:
        token_list.append(tok)
    return token_list

# ══════════════════════════════════════════════════════
#  PHASE 2 — AST NODE DEFINITIONS
# ══════════════════════════════════════════════════════

class ASTNode:
    pass

class NumNode(ASTNode):
    def __init__(self, val): self.val = val
    def __repr__(self): return f"NUM({self.val})"

class VarNode(ASTNode):
    def __init__(self, name): self.name = name
    def __repr__(self): return f"VAR({self.name})"

class DeclNode(ASTNode):
    def __init__(self, name): self.name = name
    def __repr__(self): return f"DECL({self.name})"

class AssignNode(ASTNode):
    def __init__(self, name, expr): self.name = name; self.expr = expr
    def __repr__(self): return f"ASSIGN({self.name}, {self.expr})"

class BinOpNode(ASTNode):
    def __init__(self, op, left, right): self.op=op; self.left=left; self.right=right
    def __repr__(self): return f"BINOP({self.op}, {self.left}, {self.right})"

class IfNode(ASTNode):
    def __init__(self, cond, then_b, else_b): self.cond=cond; self.then_b=then_b; self.else_b=else_b
    def __repr__(self): return f"IF({self.cond})"

class WhileNode(ASTNode):
    def __init__(self, cond, body): self.cond=cond; self.body=body
    def __repr__(self): return f"WHILE({self.cond})"

class PrintNode(ASTNode):
    def __init__(self, expr): self.expr = expr
    def __repr__(self): return f"PRINT({self.expr})"

class ReturnNode(ASTNode):
    def __init__(self, expr): self.expr = expr
    def __repr__(self): return f"RETURN({self.expr})"

class BlockNode(ASTNode):
    def __init__(self, stmts): self.stmts = stmts
    def __repr__(self): return f"BLOCK({len(self.stmts)} stmts)"

# ══════════════════════════════════════════════════════
#  PHASE 3 — PARSING (equivalent to YACC/Bison)
# ══════════════════════════════════════════════════════

precedence = (
    ('left', 'PLUS', 'MINUS'),
    ('left', 'MUL', 'DIV'),
    ('nonassoc', 'LT', 'GT', 'LEQ', 'GEQ', 'EQ', 'NEQ'),
)

def p_program(p):
    '''program : stmts'''
    p[0] = BlockNode(p[1])

def p_stmts(p):
    '''stmts : stmts stmt
             | stmt'''
    if len(p) == 3: p[0] = p[1] + [p[2]]
    else:           p[0] = [p[1]]

def p_stmt_decl(p):
    '''stmt : INT IDENTIFIER SEMICOLON'''
    p[0] = DeclNode(p[2])

def p_stmt_assign(p):
    '''stmt : IDENTIFIER ASSIGN expr SEMICOLON'''
    p[0] = AssignNode(p[1], p[3])

def p_stmt_if(p):
    '''stmt : IF LPAREN rel_expr RPAREN block'''
    p[0] = IfNode(p[3], p[5], None)

def p_stmt_if_else(p):
    '''stmt : IF LPAREN rel_expr RPAREN block ELSE block'''
    p[0] = IfNode(p[3], p[5], p[7])

def p_stmt_while(p):
    '''stmt : WHILE LPAREN rel_expr RPAREN block'''
    p[0] = WhileNode(p[3], p[5])

def p_stmt_print(p):
    '''stmt : PRINT LPAREN expr RPAREN SEMICOLON'''
    p[0] = PrintNode(p[3])

def p_stmt_return(p):
    '''stmt : RETURN expr SEMICOLON'''
    p[0] = ReturnNode(p[2])

def p_block(p):
    '''block : BEGIN_TOK stmts END_TOK
             | stmt'''
    if len(p) == 4: p[0] = BlockNode(p[2])
    else:           p[0] = BlockNode([p[1]])

def p_rel_expr(p):
    '''rel_expr : expr EQ  expr
                | expr NEQ expr
                | expr LT  expr
                | expr GT  expr
                | expr LEQ expr
                | expr GEQ expr'''
    p[0] = BinOpNode(p[2], p[1], p[3])

def p_expr_binop(p):
    '''expr : expr PLUS  expr
            | expr MINUS expr
            | expr MUL   expr
            | expr DIV   expr'''
    p[0] = BinOpNode(p[2], p[1], p[3])

def p_expr_paren(p):
    '''expr : LPAREN expr RPAREN'''
    p[0] = p[2]

def p_expr_num(p):
    '''expr : NUMBER'''
    p[0] = NumNode(p[1])

def p_expr_var(p):
    '''expr : IDENTIFIER'''
    p[0] = VarNode(p[1])

def p_error(p):
    if p: print(f"  [Parse Error] Unexpected token '{p.value}' at line {p.lineno}")
    else: print("  [Parse Error] Unexpected end of input")

parser = yacc.yacc()

# ══════════════════════════════════════════════════════
#  PHASE 4 — SEMANTIC ANALYSIS
# ══════════════════════════════════════════════════════

class SemanticAnalyzer:
    def __init__(self):
        self.sym_table = set()
        self.errors = []

    def check(self, node):
        if isinstance(node, DeclNode):
            self.sym_table.add(node.name)
        elif isinstance(node, VarNode):
            if node.name not in self.sym_table:
                self.errors.append(f"Undeclared variable '{node.name}'")
        elif isinstance(node, AssignNode):
            if node.name not in self.sym_table:
                self.errors.append(f"Assignment to undeclared variable '{node.name}'")
            self.check(node.expr)
        elif isinstance(node, BinOpNode):
            self.check(node.left); self.check(node.right)
        elif isinstance(node, IfNode):
            self.check(node.cond); self.check(node.then_b)
            if node.else_b: self.check(node.else_b)
        elif isinstance(node, WhileNode):
            self.check(node.cond); self.check(node.body)
        elif isinstance(node, (PrintNode, ReturnNode)):
            self.check(node.expr)
        elif isinstance(node, BlockNode):
            for s in node.stmts: self.check(s)

# ══════════════════════════════════════════════════════
#  PHASE 5 — IR GENERATION (3-Address Code)
# ══════════════════════════════════════════════════════

class IRGenerator:
    def __init__(self):
        self.code   = []
        self.temp_c = 0
        self.lab_c  = 0

    def new_temp(self):
        t = f"t{self.temp_c}"; self.temp_c += 1; return t

    def new_label(self):
        l = f"L{self.lab_c}"; self.lab_c += 1; return l

    def emit(self, instr):
        self.code.append(instr)

    def gen(self, node):
        if isinstance(node, NumNode):
            t = self.new_temp(); self.emit(f"  {t} = {node.val}"); return t
        elif isinstance(node, VarNode):
            return node.name
        elif isinstance(node, BinOpNode):
            l = self.gen(node.left); r = self.gen(node.right)
            t = self.new_temp(); self.emit(f"  {t} = {l} {node.op} {r}"); return t
        elif isinstance(node, DeclNode):
            self.emit(f"  decl {node.name}"); return None
        elif isinstance(node, AssignNode):
            val = self.gen(node.expr); self.emit(f"  {node.name} = {val}"); return node.name
        elif isinstance(node, IfNode):
            cond = self.gen(node.cond)
            lelse = self.new_label(); lend = self.new_label()
            self.emit(f"  if_false {cond} goto {lelse}")
            self.gen(node.then_b)
            self.emit(f"  goto {lend}")
            self.emit(f"{lelse}:")
            if node.else_b: self.gen(node.else_b)
            self.emit(f"{lend}:")
        elif isinstance(node, WhileNode):
            lstart = self.new_label(); lend = self.new_label()
            self.emit(f"{lstart}:")
            cond = self.gen(node.cond)
            self.emit(f"  if_false {cond} goto {lend}")
            self.gen(node.body)
            self.emit(f"  goto {lstart}")
            self.emit(f"{lend}:")
        elif isinstance(node, PrintNode):
            val = self.gen(node.expr); self.emit(f"  print {val}")
        elif isinstance(node, ReturnNode):
            val = self.gen(node.expr); self.emit(f"  return {val}")
        elif isinstance(node, BlockNode):
            for s in node.stmts: self.gen(s)

# ══════════════════════════════════════════════════════
#  PRETTY PRINT AST
# ══════════════════════════════════════════════════════

def print_ast(node, depth=0):
    pad = "  " * depth
    if isinstance(node, NumNode):   print(f"{pad}NUM({node.val})")
    elif isinstance(node, VarNode): print(f"{pad}VAR({node.name})")
    elif isinstance(node, DeclNode):print(f"{pad}DECL({node.name})")
    elif isinstance(node, AssignNode):
        print(f"{pad}ASSIGN({node.name})")
        print_ast(node.expr, depth+1)
    elif isinstance(node, BinOpNode):
        print(f"{pad}BINOP({node.op})")
        print_ast(node.left, depth+1)
        print_ast(node.right, depth+1)
    elif isinstance(node, IfNode):
        print(f"{pad}IF")
        print_ast(node.cond, depth+1)
        print(f"{pad}  THEN:"); print_ast(node.then_b, depth+2)
        if node.else_b:
            print(f"{pad}  ELSE:"); print_ast(node.else_b, depth+2)
    elif isinstance(node, WhileNode):
        print(f"{pad}WHILE")
        print(f"{pad}  COND:"); print_ast(node.cond, depth+2)
        print(f"{pad}  BODY:"); print_ast(node.body, depth+2)
    elif isinstance(node, PrintNode):
        print(f"{pad}PRINT"); print_ast(node.expr, depth+1)
    elif isinstance(node, ReturnNode):
        print(f"{pad}RETURN"); print_ast(node.expr, depth+1)
    elif isinstance(node, BlockNode):
        print(f"{pad}BLOCK ({len(node.stmts)} stmts)")
        for s in node.stmts: print_ast(s, depth+1)

# ══════════════════════════════════════════════════════
#  MAIN DRIVER
# ══════════════════════════════════════════════════════

def main():
    src_file = sys.argv[1] if len(sys.argv) > 1 else "test/sample.simp"
    with open(src_file) as f:
        source = f.read()

    print("=" * 55)
    print("  SimpleImp DSL Compiler")
    print("  Student  : MUKESH T")
    print("  Reg No   : RA2311026050205")
    print("=" * 55)
    print(f"\nSource File: {src_file}\n")

    # ── Phase 1: Lex ──────────────────────────────────
    print("─" * 55)
    print("[Phase 1] LEXICAL ANALYSIS")
    print("─" * 55)
    tokens_found = tokenize_for_display(source)
    print(f"  {'TOKEN TYPE':<20} {'VALUE'}")
    print(f"  {'-'*19} {'-'*20}")
    for tok in tokens_found:
        print(f"  {tok.type:<20} {tok.value}")
    print(f"\n  Total tokens : {len(tokens_found)}")
    print("  Status       : DONE ✓\n")

    # ── Phase 2: Parse ────────────────────────────────
    print("─" * 55)
    print("[Phase 2] PARSING (Grammar Analysis)")
    print("─" * 55)
    lexer.lineno = 1
    ast = parser.parse(source, lexer=lexer)
    if ast is None:
        print("  Parsing FAILED."); return
    print("  Grammar validated successfully.")
    print("  Status : DONE ✓\n")

    # ── Phase 3: AST ──────────────────────────────────
    print("─" * 55)
    print("[Phase 3] ABSTRACT SYNTAX TREE (AST)")
    print("─" * 55)
    print_ast(ast)
    print("\n  Status : DONE ✓\n")

    # ── Phase 4: Semantic ─────────────────────────────
    print("─" * 55)
    print("[Phase 4] SEMANTIC ANALYSIS")
    print("─" * 55)
    sa = SemanticAnalyzer()
    sa.check(ast)
    print(f"  Symbol Table   : {sorted(sa.sym_table)}")
    if sa.errors:
        for e in sa.errors: print(f"  [ERROR] {e}")
    else:
        print("  No semantic errors found. ✓")
    print("  Status : DONE ✓\n")

    # ── Phase 5: IR ───────────────────────────────────
    print("─" * 55)
    print("[Phase 5] INTERMEDIATE CODE (3-Address Code)")
    print("─" * 55)
    irgen = IRGenerator()
    irgen.gen(ast)
    for line in irgen.code:
        print(line)

    # Write IR to file
    os.makedirs("output", exist_ok=True)
    ir_path = "output/program.ir"
    with open(ir_path, "w") as f:
        f.write("; SimpleImp DSL — 3-Address Intermediate Representation\n")
        f.write("; Student: MUKESH T | RA2311026050205\n\n")
        f.write(f"; Source: {src_file}\n\n")
        for line in irgen.code:
            f.write(line + "\n")
    print(f"\n  IR written to: {ir_path}")
    print("  Status : DONE ✓\n")

    print("=" * 55)
    print("  COMPILATION COMPLETE")
    print(f"  Temporaries used : {irgen.temp_c}")
    print(f"  Labels generated : {irgen.lab_c}")
    print(f"  Semantic errors  : {len(sa.errors)}")
    print("=" * 55)

if __name__ == "__main__":
    main()
