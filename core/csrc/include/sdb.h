#ifndef __SDB_H__
#define __SDB_H__

#include <common.h>

word_t expr(char *e, bool *success);

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  struct watchpoint *prev;
  uint32_t val;
  char expr[128];
} WP;

/* watchpoint functions */
void init_wp_pool();
WP* new_wp();
void free_wp(WP* wp);
void delete_wp(uint32_t NO);
bool check_wp();
void print_wp();

/* trace functions */
void init_trace(const char* elf_file);
void ftrace(int rd, int rs, vaddr_t pc, vaddr_t dnpc);
void free_trace();

#endif