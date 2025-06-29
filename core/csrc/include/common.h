#ifndef COMMON_H
#define COMMON_H
#include <config.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <readline/readline.h>
#include <readline/history.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vnpc.h"
#include "Vnpc___024root.h"
#include "Vnpc__Dpi.h"

#define ANSI_BOLD          "\x1b[1m"
#define ANSI_DIM           "\x1b[2m"
#define ANSI_ITALLIC       "\x1b[3m"
#define ANSI_UNDERLINE     "\x1b[4m"
#define ANSI_DASHED        "\x1b[9m"
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_BG_RED        "\x1b[41m"
#define ANSI_BG_GREEN      "\x1b[42m"
#define ANSI_BG_YELLOW     "\x1b[43m"
#define ANSI_BG_BLUE       "\x1b[44m"
#define ANSI_BG_MAGENTA    "\x1b[45m"
#define ANSI_BG_CYAN       "\x1b[46m"
#define ANSI_COLOR_RESET   "\x1b[0m"

#define FMT_WORD "0x%08x"
#define ANSI_FMT(fmt, color) ANSI_BOLD color fmt ANSI_COLOR_RESET

#define BITMASK(bits) ((1ull << (bits)) - 1)
#define BITS(x, hi, lo) (((x) >> (lo)) & BITMASK((hi) - (lo) + 1)) // similar to x[hi:lo] in verilog
#define SEXT(x, len) ((uint64_t)((int64_t)((x) << (64 - (len))) >> (64 - (len))))
#define SSEXT(x, len) ((int64_t)((x) << (64 - (len))) >> (64 - (len)))

typedef uint32_t vaddr_t;
typedef uint32_t paddr_t;
typedef uint32_t word_t;

void display_error_msg();

#define ARRLEN(A) (sizeof(A) / sizeof(A[0]))

#define Assert(cond, format, ...) \
  do { \
    if (!(cond)) { \
      fprintf(stderr, ANSI_BOLD ANSI_COLOR_RED format ANSI_COLOR_RESET, ## __VA_ARGS__); \
      display_error_msg(); \
      assert(0); \
    } \
  } while (0)

#define Log(format, ...) \
  do { \
    printf(ANSI_COLOR_BLUE format "\n" ANSI_COLOR_RESET, ## __VA_ARGS__); \
  } while (0)

#define panic(format, ...) \
  do { \
    Assert(0, format, __VA_ARGS__); \
  } while (0)

#endif