#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include "soc.h"

#define soc_trap(code) asm volatile("mv a0, %0; ebreak" : : "r"(code))

extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER;

void putch(char ch)
{
  ioe_write(AM_UART_TX, &(AM_UART_TX_T){.data = ch});
}

void halt(int code)
{
  soc_trap(code);
  while (1)
    ;
}

void _trm_init()
{
  int ret = main(mainargs);
  halt(ret);
}
