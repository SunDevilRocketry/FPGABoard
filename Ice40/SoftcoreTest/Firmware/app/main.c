#include <stdint.h>

static volatile uint32_t *const uart_div = (volatile uint32_t *)0x30001000; // I don't think this is needed.
static volatile uint32_t *const uart_buf = (volatile uint32_t *)0x30001100;

static void UART_putchar(char c) {
    if (c == '\n')
        UART_putchar('\r');
    *uart_buf = c;
}

static void UART_print(const char *p) {
    while (*p)
        UART_putchar(*p++);
}

static int UART_getchar(uint32_t timeout) {
    int32_t c = -1;
    uint32_t time = 0;

    while (c == -1) {
        time++;
        if (time > timeout) break;
        c = *uart_buf;
    }

    return c;
}

int main(void){
    volatile uint32_t *leds = (volatile uint32_t *)0x30000000;
    volatile uint32_t *ram0  = (volatile uint32_t *)0x10018000;
    volatile uint32_t *ram1  = (volatile uint32_t *)0x10010000;
    volatile const uint32_t *flash = (volatile const uint32_t *)0x20100000;

    uint32_t n = 0x01234000;

    *leds = *flash;
    UART_print("APP is APPING\n");

    while (1) {
        n++;
        *ram0 = n;
        *ram1 = ~n;
        *leds = *ram0;
        if ((n & 0xFFFFF) == 0)
            UART_print("h");
    }
}