#ifndef CPU_H
#define CPU_H

#include <common.h>

enum CPU_state {
    END,
    ABORT,
    QUIT,
    RUNNING,
    STOP,
};

typedef struct {
    uint32_t gpr[32];
    uint32_t pc;
} CPU_reg;

void cpu_init(const char* Vcd_file);
void cpu_deinit();
void single_cycle();
void stop(int code, uint32_t pc);
void reset(int n);
void cpu_exec(uint64_t n);
void reg_display();
uint32_t reg_str2val(const char *s);
void Cget_reg(int addr, int* reg_data);
void Cget_pc_inst(uint32_t* pc, uint32_t* inst);
CPU_reg get_cpu_state();

#endif