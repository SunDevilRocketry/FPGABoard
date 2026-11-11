#include "UART.h"
#include <stdint.h>

void UART_putchar(char c) {
    if (c == '\n')
        UART_putchar('\r');
    *uart_buf = c;
}

void UART_print(const char *p) {
    while (*p)
        UART_putchar(*p++);
}

uint32_t UART_getchar(uint32_t timeout) {
    int32_t c = -1;
    uint32_t time = 0;

    while (c == -1) {
        time++;
        if (time > timeout) break;
        c = *uart_buf;
    }

    return c;
}

uint32_t UART_getBaudScale() {
    return *uart_div;
}

void UART_setBaudScale(uint32_t scale) {
    *uart_div = scale;
}