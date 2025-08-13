#ifndef __DEVICE_H__
#define __DEVICE_H__

#include <common.h>

bool in_mmio(paddr_t addr);
uint32_t mmio_read(paddr_t addr);
void mmio_write(paddr_t addr, uint32_t data);

// timer
uint64_t get_time();

// UART functions
uint32_t uart_read(paddr_t addr);
void uart_write(paddr_t addr, uint32_t data);


// ----------------------------------------------------------------------------------------
// MMIO Config
// ----------------------------------------------------------------------------------------

#define UART_BASE 0x10000000L
#define UART_TX (UART_BASE + 0)
#define UART_RX (UART_BASE + 0)
#define UART_STATUS (UART_BASE + 1)

#define CLINT_BASE 0x02000000L
#define RTC_ADDR (CLINT_BASE + 0x0000048)

// Additional peripheral addresses
#define SEG_ADDR 0x10001000L
#define LED_ADDR 0x10002000L
#define CNT_ADDR 0x10003000L

uint32_t mmio_read(paddr_t addr);
void mmio_write(paddr_t addr, uint32_t data);

#endif