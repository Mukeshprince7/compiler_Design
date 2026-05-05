/*
 * ============================================================
 *  HoT Skill Assessment - Problem 10
 *  Runtime Storage - Stack Growth Risk Analysis
 *
 *  Student  : MUKESH T
 *  Reg No   : RA2311026050205
 *  Tool     : C (with arrays/structures)
 * ============================================================
 *
 *  Problem Statement:
 *  Activation records store information about local variables
 *  and call depth for each function. Raw size values do not
 *  directly indicate potential runtime failures.
 *
 *  Task:
 *  Compute Estimated_Stack_Frame_Size per function and create
 *  a flag Is_Stack_Overflow_Risk if limits are exceeded.
 *
 *  Feature Engineering:
 *  Estimated_Stack_Frame_Size = local_vars * 4 (bytes each)
 *                             + call_depth * 8 (return addr + frame ptr)
 *                             + 16 (fixed overhead per frame)
 *
 *  Threshold: Stack frame size > 512 bytes → Is_Stack_Overflow_Risk = 1
 * ============================================================
 */

#include <stdio.h>
#include <string.h>

/* ── Threshold Definition ─────────────────────────── */
#define STACK_RISK_THRESHOLD   512   /* bytes */
#define LOCAL_VAR_SIZE         4     /* bytes per local variable */
#define CALL_DEPTH_OVERHEAD    8     /* bytes per depth level (ret addr + frame ptr) */
#define FIXED_FRAME_OVERHEAD   16    /* bytes fixed overhead (saved registers etc.) */
#define MAX_FUNCTIONS          10

/* ── Activation Record Structure ─────────────────── */
typedef struct {
    char func_name[32];           /* Function name                          */
    int  local_vars;              /* Number of local variables              */
    int  call_depth;              /* Nesting/call depth from main           */
    int  estimated_frame_size;    /* DERIVED: computed stack frame size     */
    int  is_stack_overflow_risk;  /* FLAG: 1 if risk detected, 0 otherwise  */
} ActivationRecord;

/* ── Feature Computation ─────────────────────────── */
void compute_features(ActivationRecord *records, int n) {
    for (int i = 0; i < n; i++) {
        /* Estimated_Stack_Frame_Size formula:
           = (local_vars * 4) + (call_depth * 8) + 16
        */
        records[i].estimated_frame_size =
            (records[i].local_vars  * LOCAL_VAR_SIZE)
          + (records[i].call_depth  * CALL_DEPTH_OVERHEAD)
          + FIXED_FRAME_OVERHEAD;

        /* Flag: Is_Stack_Overflow_Risk */
        records[i].is_stack_overflow_risk =
            (records[i].estimated_frame_size > STACK_RISK_THRESHOLD) ? 1 : 0;
    }
}

/* ── Display Results ─────────────────────────────── */
void display_results(ActivationRecord *records, int n) {
    printf("\n");
    printf("================================================================\n");
    printf("  HoT Assessment | Problem 10: Stack Growth Risk Analysis\n");
    printf("  Student : MUKESH T  |  Reg No : RA2311026050205\n");
    printf("================================================================\n\n");

    printf("  THRESHOLD : %d bytes → triggers Is_Stack_Overflow_Risk = 1\n\n",
           STACK_RISK_THRESHOLD);

    /* Table header */
    printf("  %-15s %10s %10s %18s %18s\n",
           "Function", "LocalVars", "CallDepth",
           "FrameSize(bytes)", "OverflowRisk");
    printf("  %-15s %10s %10s %18s %18s\n",
           "---------------", "---------", "---------",
           "----------------", "------------");

    int risk_count = 0;

    for (int i = 0; i < n; i++) {
        printf("  %-15s %10d %10d %18d %18s\n",
               records[i].func_name,
               records[i].local_vars,
               records[i].call_depth,
               records[i].estimated_frame_size,
               records[i].is_stack_overflow_risk ? "YES [RISK]" : "NO  [SAFE]");

        if (records[i].is_stack_overflow_risk) risk_count++;
    }

    printf("\n");
    printf("  -------------------------------------------------------\n");
    printf("  Total Functions Analyzed : %d\n", n);
    printf("  Functions at Risk        : %d\n", risk_count);
    printf("  Functions Safe           : %d\n", n - risk_count);
    printf("  -------------------------------------------------------\n");

    /* Detail report for risky functions */
    if (risk_count > 0) {
        printf("\n  [!] RISK DETAIL REPORT:\n");
        for (int i = 0; i < n; i++) {
            if (records[i].is_stack_overflow_risk) {
                printf("\n  Function  : %s\n", records[i].func_name);
                printf("  LocalVars : %d  → %d bytes\n",
                       records[i].local_vars,
                       records[i].local_vars * LOCAL_VAR_SIZE);
                printf("  CallDepth : %d  → %d bytes\n",
                       records[i].call_depth,
                       records[i].call_depth * CALL_DEPTH_OVERHEAD);
                printf("  Overhead  : %d bytes (fixed)\n", FIXED_FRAME_OVERHEAD);
                printf("  TOTAL     : %d bytes  [EXCEEDS THRESHOLD of %d]\n",
                       records[i].estimated_frame_size,
                       STACK_RISK_THRESHOLD);
            }
        }
    }

    printf("\n================================================================\n");
    printf("  Formula Used:\n");
    printf("  Estimated_Stack_Frame_Size = (local_vars x 4)\n");
    printf("                             + (call_depth x 8)\n");
    printf("                             + 16 (fixed overhead)\n");
    printf("  Is_Stack_Overflow_Risk = 1 if frame_size > %d bytes\n",
           STACK_RISK_THRESHOLD);
    printf("================================================================\n\n");
}

/* ── Main ─────────────────────────────────────────── */
int main() {
    /*
     * Sample Activation Record Data
     * Represents 8 functions with varying local vars and call depths
     */
    ActivationRecord records[MAX_FUNCTIONS] = {
        /* func_name,     local_vars, call_depth */
        { "main",              3,         0 },
        { "init_system",       5,         1 },
        { "parse_input",      12,         2 },
        { "validate_data",    20,         3 },
        { "process_block",   110,         5 },   /* large local vars */
        { "recursive_sort",    8,        65 },   /* deep call depth  */
        { "compute_matrix",  120,        10 },   /* both high */
        { "log_output",        2,         2 },
    };

    int n = 8;

    /* Phase 1: Feature Computation */
    compute_features(records, n);

    /* Phase 2: Display with flags */
    display_results(records, n);

    return 0;
}
