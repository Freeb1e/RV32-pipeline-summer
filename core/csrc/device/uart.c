#include <device.h>

// 状态寄存器位定义
#define UART_STATUS_TX_READY (1 << 0) // 发送缓冲区准备好
#define UART_STATUS_RX_READY (1 << 4) // 接收缓冲区有数据

// 简单的接收缓冲区
static uint8_t rx_buffer[256];
static int rx_head = 0;
static int rx_tail = 0;
static int rx_count = 0;
// UART读取函数
uint32_t uart_read(paddr_t addr)
{
    uint32_t result = 0;
    static const char *p = "help\ndate\nversion\nfree\nps\npwd\nls\nmemtrace\nmemcheck\nutest_list\n";

    switch (addr - UART_BASE)
    {
    case 0: // TX/RX寄存器
        return (*p != '\0' ? *(p++) : -1);
        break;

    case 1:
        result = 0x11;
        break;

    default:
        panic("[UART] Invalid read address: 0x%08x\n", addr);
        break;
    }

    return result; // 8位数据扩展为32位，高位补0
}

// UART写入函数
void uart_write(paddr_t addr, uint32_t data)
{
    uint8_t byte_data = data & 0xFF; // 只使用低8位

    switch (addr - UART_BASE)
    {
    case 0:
        putchar(byte_data);
        fflush(stdout);
        break;

    case 1:
        panic("[UART] Status register is not writable");
        break;

    default:
        printf("[UART] Invalid write address: 0x%08x, data: 0x%08x\n", addr, data);
        break;
    }
}