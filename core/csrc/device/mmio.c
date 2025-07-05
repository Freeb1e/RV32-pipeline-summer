#include <device.h>

extern int sim_time;
void difftest_skip_ref();

bool in_mmio(paddr_t addr) {
    bool ret = (addr==SERIAL_PORT) ||
                (addr>=RTC_ADDR && addr<RTC_ADDR+0x8) ||
                (addr==SEG_ADDR) ||
                (addr==LED_ADDR) ||
                (addr==CNT_ADDR);
    // if(ret) printf(FMT_WORD " is mmio address\n", addr);
    // else printf(FMT_WORD " is not mmio address\n", addr);
    return ret;
}

void difftest_skip_ref();
extern int sim_time;

uint32_t seg_data = 0;
void write_seg_data(uint32_t data)
{
    seg_data = data;
    char digits[8];
    for (int i = 0; i < 8; i++)
    {
        digits[i] = (data >> (i * 4)) & 0xF;
    }
    printf("SEG display:" ANSI_FMT("%1d%1d %1d%1d %1d%1d %1d%1d", ANSI_COLOR_CYAN) "\n",
           digits[7], digits[6], digits[5], digits[4],
           digits[3], digits[2], digits[1], digits[0]);
}

uint32_t read_seg_data()
{
    return seg_data;
}

void write_led_data(uint32_t data)
{
    printf("LED display:\n");
    for (int i = 0; i < 4; i++)
    {
        for (int j = 0; j < 8; j++)
        {
            if (data >> (31-(i * 8 + j)) & 0x1)
            {
                printf(ANSI_COLOR_GREEN "●" ANSI_COLOR_RESET);
            }
            else
            {
                printf(ANSI_COLOR_RED "○" ANSI_COLOR_RESET);
            }
        }
        printf("\n");
    }
}

uint32_t counter = 1234;
void write_counter_data(uint32_t data)
{
    counter = data;
}

uint32_t read_counter_data()
{
    return counter;
}

uint32_t mmio_read(paddr_t addr)
{
    // printf("MMIO read from " FMT_WORD "\n", addr);
    // prevent repeat read
    static int last_simtime;
    if (sim_time - last_simtime < 3)
    {
        return 0;
    }
    last_simtime = sim_time;

#ifdef CONFIG_DIFFTEST
    difftest_skip_ref();
#endif

    if (addr == SERIAL_PORT)
    {
        return 0;
    }
    else if (addr >= RTC_ADDR && addr < RTC_ADDR + 0x8)
    {
        uint32_t offset = addr - RTC_ADDR;
        Assert(offset == 0 || offset == 4, "RTC offset cannot be %d\n", offset);

        uint32_t ret;
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
        return ret;
    }
    else if (addr == SEG_ADDR)
    {
        return read_seg_data();
    }
    else if (addr == LED_ADDR)
    {
        return 0xDEADBEEF; // return a dummy value for LED
    }
    else if (addr == CNT_ADDR)
    {
        return read_counter_data();
    }
    return 0;
}

void mmio_write(paddr_t addr, uint32_t data)
{
    // printf("MMIO write to " FMT_WORD ": " FMT_WORD "\n", addr, data);
    #ifdef CONFIG_DIFFTEST
    difftest_skip_ref();
    #endif
    // prevent repeat write
    static int last_simtime;
    if (sim_time - last_simtime < 3)
    {
        return;
    }
    last_simtime = sim_time;
    if (addr == SERIAL_PORT)
    {
        putchar((char)data);
    }
    else if (addr >= RTC_ADDR && addr < RTC_ADDR + 0x8)
    {
        return;
    }
    else if (addr == SEG_ADDR)
    {
        write_seg_data(data);
    }
    else if (addr == LED_ADDR)
    {
        write_led_data(data);
    }
    else if (addr == CNT_ADDR)
    {
        write_counter_data(data);
    }
    else
    {
        Assert(0, "MMIO write to unknown address: " FMT_WORD, addr);
    }
}
