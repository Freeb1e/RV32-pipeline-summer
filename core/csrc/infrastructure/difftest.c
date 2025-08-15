#include <dlfcn.h>

#include <cpu.h>
#include <memory.h>
#include <common.h>

#define DIFFTEST_TO_REF 1
#define DIFFTEST_TO_DUT 0

memdiff_t dut_memdiff;

extern CPU_state state;
extern int halt_ret;
extern uint32_t halt_pc;
static uint8_t skip_ref = 0;
#define SKIP_DELAY 1

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

  // ref_difftest_memlogcpy = (void (*)(memdiff_t *))dlsym(handle, "difftest_memlogcpy");
  // assert(ref_difftest_memlogcpy);

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
  skip_ref = skip_ref << 1;
  skip_ref = skip_ref | 1;
}

bool difftest_checkregs(CPU_reg *ref_r, vaddr_t pc) {
  CPU_reg this_r = get_cpu_state();
  bool flag = true;
  if (this_r.pc != ref_r->pc)
  {
    flag = false;
    Log("PC mismatch: ref.pc = " FMT_WORD ", pc = " FMT_WORD, ref_r->pc, this_r.pc);
  }
  for (int i = 0; i < 32; i++)
  {
    if (this_r.gpr[i] != ref_r->gpr[i])
    {
      flag = false;
      Log("reg[%d] mismatch: ref = " FMT_WORD ", dut = " FMT_WORD, i, ref_r->gpr[i], this_r.gpr[i]);
    }
  }
  if (this_r.mtvec != ref_r->mtvec)
  {
    flag = false;
    Log("mtvec mismatch: ref = " FMT_WORD ", dut = " FMT_WORD, ref_r->mtvec, this_r.mtvec);
  }
  if (this_r.mstatus != ref_r->mstatus)
  {
    flag = false;
    Log("mstatus mismatch: ref = " FMT_WORD ", dut = " FMT_WORD, ref_r->mstatus, this_r.mstatus);
  }
  if (this_r.mcause != ref_r->mcause)
  {
    flag = false;
    Log("mcause mismatch: ref = " FMT_WORD ", dut = " FMT_WORD, ref_r->mcause, this_r.mcause);
  }
  if (this_r.mepc != ref_r->mepc)
  {
    flag = false;
    Log("mepc mismatch: ref = " FMT_WORD ", dut = " FMT_WORD, ref_r->mepc, this_r.mepc);
  }
  return flag;
}

bool difftest_checkmem(memdiff_t *ref_memdiff) {
  // Compare the memory differences
  if (dut_memdiff.store_pc != ref_memdiff->store_pc ||
      dut_memdiff.store_data != ref_memdiff->store_data) {
    Log("Memory mismatch");
    return false;
  }
  return true;
}

void display_ref_dut_regs(CPU_reg *ref_r){
  CPU_reg this_r = get_cpu_state();

  // RISC-V register names for better readability
  const char *reg_names[32] = {
      "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
      "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
      "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
      "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};

  Log("=== Register Comparison (REF vs DUT) ===");

  // Display general purpose registers in groups of 4 for better readability
  for (int i = 0; i < 32; i += 2)
  {
    Log("x%-2d(%-3s): " FMT_WORD " | " FMT_WORD "  x%-2d(%-3s): " FMT_WORD " | " FMT_WORD,
        i, reg_names[i], ref_r->gpr[i], this_r.gpr[i],
        i + 1, reg_names[i + 1], ref_r->gpr[i + 1], this_r.gpr[i + 1]);
  }

  Log("=== Control and Status Registers ===");
  Log("PC     : " FMT_WORD " | " FMT_WORD, ref_r->pc, this_r.pc);
  Log("mtvec  : " FMT_WORD " | " FMT_WORD, ref_r->mtvec, this_r.mtvec);
  Log("mstatus: " FMT_WORD " | " FMT_WORD, ref_r->mstatus, this_r.mstatus);
  Log("mcause : " FMT_WORD " | " FMT_WORD, ref_r->mcause, this_r.mcause);
  Log("mepc   : " FMT_WORD " | " FMT_WORD, ref_r->mepc, this_r.mepc);
  Log("========================================");
}

void display_ref_dut_memlog(memdiff_t *ref_memdiff) {
  Log("store_pc: ref = " FMT_WORD ", dut = " FMT_WORD, ref_memdiff->store_pc, dut_memdiff.store_pc);
  Log("store_data: ref = " FMT_WORD ", dut = " FMT_WORD, ref_memdiff->store_data, dut_memdiff.store_data);
}

static void checkregs(CPU_reg *ref, vaddr_t pc) {
  //display_ref_dut_regs(ref);
  if ((!difftest_checkregs(ref, pc))) {
    state = ABORT;
    halt_pc = pc;
    display_ref_dut_regs(ref);
    display_error_msg();
  }
}

static void checkmem(memdiff_t *ref) {
  if (!difftest_checkmem(ref)) {
    state = ABORT;
    halt_pc = ref->store_pc; // Use store_pc as a reference point for the error
    Log("Memory mismatch detected at store_pc: " FMT_WORD, ref->store_pc);
    display_ref_dut_memlog(ref);
    display_error_msg();
  }
}

void difftest_step(vaddr_t pc) {
  CPU_reg ref_r;
  memdiff_t ref_memdiff;

  if (skip_ref & (1<<SKIP_DELAY)) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    CPU_reg this_ = get_cpu_state();
    ref_difftest_regcpy(&this_, DIFFTEST_TO_REF);
    return;
  }
  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
  // ref_difftest_memlogcpy(&ref_memdiff);

  checkregs(&ref_r, pc);
  // checkmem(&ref_memdiff);
}
#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
void difftest_skip_ref(){}
#endif
