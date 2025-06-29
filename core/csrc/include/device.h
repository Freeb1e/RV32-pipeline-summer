#ifndef __DEVICE_H__
#define __DEVICE_H__

#include <common.h>

bool in_mmio(paddr_t addr);
uint32_t mmio_read(paddr_t addr);
void mmio_write(paddr_t addr, uint32_t data);

// timer
uint64_t get_time();


// ----------------------------------------------------------------------------------------
// MMIO Config
// ----------------------------------------------------------------------------------------
#define MMIO_BASE 0xa0000000

#define SERIAL_PORT     (MMIO_BASE + 0x00003f8)
#define KBD_ADDR        (MMIO_BASE + 0x0000060)
#define RTC_ADDR        (MMIO_BASE + 0x0000048)
#define VGACTL_ADDR     (MMIO_BASE + 0x0000100)
#define AUDIO_ADDR      (MMIO_BASE + 0x0000200)
#define DISK_ADDR       (MMIO_BASE + 0x0000300)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)
#define AUDIO_SBUF_ADDR (MMIO_BASE   + 0x1200000)

#endif