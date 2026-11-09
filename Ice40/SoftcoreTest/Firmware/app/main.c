#include <stdint.h>

int main(void){
    volatile uint32_t *leds = (volatile uint32_t *)0x30000000;
    volatile uint32_t *ram0  = (volatile uint32_t *)0x10018000;
    volatile uint32_t *ram1  = (volatile uint32_t *)0x10010000;
    volatile uint32_t *uart_div  = (volatile uint32_t *)0x30001000;
    volatile uint32_t *uart_buf  = (volatile uint32_t *)0x30001100;
    volatile const uint32_t *flash = (volatile const uint32_t *)0x20100000;
    
    uint32_t n = 0x01234000;
    
    *leds = *flash;

    void UART_putchar(char c) {
        if (c == '\n')
            UART_putchar('\r');
        *uart_buf = c;
    }

    void UART_print(const char *p) {
        while (*p)
            UART_putchar(*(p++));
    }

    char UART_getchar (uint32_t timeout) {
        int32_t c = -1;
        uint32_t time = 0;

        while (c == -1) {
            time++;
            if (time > timeout) break;
            c = *uart_buf;
        }

        return c;
    }

    while (1) { 
        n++; 
        *ram0 = n;
        *ram1 = ~n;
        *leds = *ram0;
        UART_print("h");
    }
}