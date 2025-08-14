#include <device.h>
#include <cpu.h>

extern int sim_time;
extern uint8_t skip_difftest;
void skip_ref()
{
    skip_difftest = 1;
}

bool in_mmio(paddr_t addr) {
    bool ret = (addr == UART_TX) || 
               (addr == UART_STATUS) ||
               (addr >= RTC_ADDR && addr < RTC_ADDR + 0x8);
    // if(ret) printf(FMT_WORD " is mmio address\n", addr);
    // else printf(FMT_WORD " is not mmio address\n", addr);
    return ret;
}

extern int sim_time;

uint32_t mmio_read(paddr_t addr)
{
    // printf("MMIO read from " FMT_WORD "\n", addr);
    // prevent repeat read

    skip_ref();
    uint32_t ret = 0;
    if (addr == UART_RX || addr == UART_STATUS)
    {
        ret = uart_read(addr);
    } 
    else if (addr >= RTC_ADDR && addr < RTC_ADDR + 0x8)
    {
        uint32_t offset = addr - RTC_ADDR;
        Assert(offset == 0 || offset == 4, "RTC offset cannot be %d\n", offset);
        if (offset == 0)
        {
            // low 32 bits of time
            ret = get_time();
        }
        else
        {
            // high 32 bits of time
            ret = get_time() >> 32;
        }
    }

#ifdef CONFIG_DTRACE
    static int last_raddr, last_ret;
    CPU_reg _this = get_cpu_state();
    if (_this.pc == addr)
    {
        return ret;
    }
    if (last_raddr != addr || last_ret != ret)
    {
        printf(ANSI_BOLD ANSI_COLOR_CYAN "DTRACE" ANSI_COLOR_RESET "(NPC) " FMT_WORD ":read from " FMT_WORD ", get " FMT_WORD "\n", _this.pc, addr, ret);
        last_raddr = addr;
        last_ret = ret;
    }
#endif

    return ret;
}

void mmio_write(paddr_t addr, uint32_t data)
{
    skip_ref();
    // prevent repeat write
    static int last_simtime;
    if (sim_time - last_simtime < 3)
    {
        return;
    }
    last_simtime = sim_time;

#ifdef CONFIG_DTRACE
    CPU_reg _this = get_cpu_state();
    printf(ANSI_BOLD ANSI_COLOR_CYAN "DTRACE" ANSI_COLOR_RESET "(NPC) " FMT_WORD ":write " FMT_WORD " to " FMT_WORD "\n", _this.pc, data, addr);
#endif

    if (addr == UART_TX || addr == UART_STATUS)
    {
        uart_write(addr, data);
    }
    else if (addr >= RTC_ADDR && addr < RTC_ADDR + 0x8)
    {
        return;
    }
    else
    {
        Assert(0, "MMIO write to unknown address: " FMT_WORD, addr);
    }
}
