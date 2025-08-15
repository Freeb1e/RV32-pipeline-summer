#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    switch (c->mcause)
    {
    case 11:
      ev.event = EVENT_YIELD;
      break;
    default:
      ev.event = EVENT_ERROR;
      break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  Context *c = (Context *)(kstack.end - sizeof(Context));
  memset(c, 0, sizeof(Context));

  c->mstatus = 0x00001800;
  c->mepc = (uintptr_t)entry;
  c->gpr[10] = (uint32_t) arg;

  return c;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, 11; ecall");
#else
  asm volatile(
      "auipc t0, 0;"     // 获取当前PC到t0
      "addi t0, t0, 32;" // t0 = PC + 24 (跳过这段代码到返回点)
      "csrw mepc, t0;"   // 将返回地址保存到mepc
      "li t1, 11;"       // 设置异常号11
      "csrw mcause, t1;" // 写入mcause寄存器
      "csrr t2, mtvec;"  // 从mtvec读取异常入口地址
      "nop;"             // TODO: 硬件处理CSR的RAW冒险
      "nop;"
      "jr t2" // 跳转到异常处理入口
      :
      :
      : "t0", "t1", "t2");
  // asm volatile("li a7, 11; ecall");
#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
