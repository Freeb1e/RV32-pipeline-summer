#include <am.h>
#include "soc.h"


void __am_uart_init()
{
}

void __am_uart_rx(AM_UART_RX_T *rx){
    while ((inb(UART_LSR) & 0x01) == 0)
        ;
    rx->data = inb(UART_RX);
}

void __am_uart_tx(AM_UART_TX_T *tx){
    while ((inb(UART_LSR) & 0x10) == 0);
    outb(UART_TX, tx->data);
}