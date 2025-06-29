#include <dlfcn.h>

#include <cpu.h>
#include <memory.h>
#include <common.h>

#define DIFFTEST_TO_REF 1
#define DIFFTEST_TO_DUT 0

extern CPU_state state;
extern int halt_ret;
extern uint32_t halt_pc;
static bool skip_ref = false;

void display_error_msg();

void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

#ifdef CONFIG_DIFFTEST

void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  printf("ref_so_file:%s\n",ref_so_file);
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (void (*)(paddr_t, void *, size_t, bool))dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void (*)(void *, bool))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint64_t))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void (*)(uint64_t))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = (void (*)(int))dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_COLOR_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off by deannotationize the #undef sentence in config.h.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  CPU_reg this_ = get_cpu_state();
  ref_difftest_regcpy(&this_, DIFFTEST_TO_REF);
}

void difftest_skip_ref(){
  skip_ref = true;
}

bool difftest_checkregs(CPU_reg *ref_r, vaddr_t pc) {
  CPU_reg this_r = get_cpu_state();
  bool flag = true;
  if (this_r.pc != ref_r->pc) {
    flag = false;
    Log("PC mismatch: ref.pc = " FMT_WORD ", pc = " FMT_WORD, ref_r->pc, this_r.pc);
  }
  for (int i = 0; i < 32; i ++) {
    if (this_r.gpr[i] != ref_r->gpr[i]) {
      flag = false;
      Log("reg[%d] mismatch: ref = " FMT_WORD ", dut = " FMT_WORD, i, ref_r->gpr[i], this_r.gpr[i]);
    }
  }
  return flag;
}

void display_ref_dut_regs(CPU_reg *ref_r){
  CPU_reg this_r = get_cpu_state();
  for (int i = 0; i < 32; i ++) {
    Log("reg[%d]: ref = " FMT_WORD ", dut = " FMT_WORD, i, ref_r->gpr[i], this_r.gpr[i]);
  }
  Log("PC: ref = " FMT_WORD ", dut = " FMT_WORD, ref_r->pc, this_r.pc);
}

static void checkregs(CPU_reg *ref, vaddr_t pc) {
  //display_ref_dut_regs(ref);
  if (!difftest_checkregs(ref, pc)) {
    state = ABORT;
    halt_pc = pc;
    display_ref_dut_regs(ref);
    display_error_msg();
  }
}

void difftest_step(vaddr_t pc) {
  CPU_reg ref_r;

  if (skip_ref) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    CPU_reg this_ = get_cpu_state();
    ref_difftest_regcpy(&this_, DIFFTEST_TO_REF);
    skip_ref = false;
    return;
  }

  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

  checkregs(&ref_r, pc);
}
#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
#endif
