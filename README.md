# SimpleImp DSL Compiler
### Compiler Design – Design Assessment

| Field | Details |
|-------|---------|
| **Student** | MUKESH T |
| **Reg No** | RA2311026050205 |
| **Subject** | Compiler Design |
| **Assessment** | Design Assessment + HoT Skill Assessment |

---

## About the Language

**SimpleImp** is a simple imperative Domain-Specific Language (DSL) supporting:
- Integer variable declarations (`int x;`)
- Assignments (`x = 10;`)
- Arithmetic expressions (`+`, `-`, `*`, `/`)
- Relational operators (`==`, `!=`, `<`, `>`, `<=`, `>=`)
- `if / else` branching
- `while` loops
- `print` and `return` statements

---

## Compiler Pipeline

```
Source File (.simp)
        │
        ▼
┌─────────────────────┐
│  Phase 1: Lexer     │  Tokenizes source → keyword, identifier, number, operator
│  (PLY lex / Flex)   │
└────────┬────────────┘
         ▼
┌─────────────────────┐
│  Phase 2: Parser    │  LALR(1) grammar → validates syntax
│  (PLY yacc / Bison) │
└────────┬────────────┘
         ▼
┌─────────────────────┐
│  Phase 3: AST       │  Builds Abstract Syntax Tree from parse result
│  Construction       │
└────────┬────────────┘
         ▼
┌─────────────────────┐
│  Phase 4: Semantic  │  Symbol table, undeclared variable detection
│  Analysis           │
└────────┬────────────┘
         ▼
┌─────────────────────┐
│  Phase 5: IR Gen    │  Outputs 3-address intermediate code → output/program.ir
│  (3-Address Code)   │
└─────────────────────┘
```

---

## Repository Structure

```
compiler_Design/
├── src/
│   ├── compiler.py       ← Main Python compiler (all 5 phases)
│   ├── lexer.l           ← Flex/Lex source (C version)
│   ├── parser.y          ← YACC/Bison grammar with AST + IR (C version)
│   └── parsetab.py       ← PLY auto-generated parse table
├── test/
│   ├── sample.simp       ← Test: factorial of 5 using while loop
│   └── test2.simp        ← Test: accumulation + if/else + return
├── output/
│   └── program.ir        ← Generated 3-address IR code
├── docs/
│   ├── RA2311026050205_MUKESH_T_Report.docx       ← Design Assessment report
│   └── RA2311026050205_MUKESH_T_Explanation.docx  ← HoT explanation document
├── RA2311026050205_MUKESH_T_HoT.c  ← HoT Problem 10: Stack Growth Risk (C)
├── Makefile
└── README.md
```

---

## Tools Used

| Tool | Purpose |
|------|---------|
| Python 3 | Compiler implementation |
| PLY (Python Lex-Yacc) | Lexer + Parser equivalent to Flex/Bison |
| Flex / Lex | C-version lexer source (`src/lexer.l`) |
| YACC / Bison | C-version parser source (`src/parser.y`) |
| GCC | C compilation |

---

## How to Run

### Python Version
```bash
# Install PLY
pip install ply

# Run on sample input
python3 src/compiler.py test/sample.simp

# Run on second test
python3 src/compiler.py test/test2.simp
```

### C Version (Flex + Bison)
```bash
make        # build compiler binary
make run    # compile and run on sample.simp
make clean  # remove generated files
```

---

## Sample Input (`test/sample.simp`)
```
int n;
int result;
int i;

n = 5;
result = 1;
i = 1;

while (i <= n) begin
    result = result * i;
    i = i + 1;
end

print(result);
```

## Sample IR Output (`output/program.ir`)
```
  decl n
  decl result
  decl i
  t0 = 5
  n = t0
  t1 = 1
  result = t1
  t2 = 1
  i = t2
L0:
  t3 = i <= n
  if_false t3 goto L1
  t4 = result * i
  result = t4
  t5 = 1
  t6 = i + t5
  i = t6
  goto L0
L1:
  print result
```

---

## HoT Assessment – Problem 10

**File:** `RA2311026050205_MUKESH_T_HoT.c`

Implements **Stack Growth Risk Analysis** in C:
- Computes `Estimated_Stack_Frame_Size = (local_vars × 4) + (call_depth × 8) + 16`
- Sets flag `Is_Stack_Overflow_Risk = 1` if frame size exceeds **512 bytes**

```bash
gcc -o hot RA2311026050205_MUKESH_T_HoT.c
./hot
```

---

*Submitted for Compiler Design – Assessment | May 2026*
