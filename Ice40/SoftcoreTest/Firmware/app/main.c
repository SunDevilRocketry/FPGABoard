#include <stdint.h>
#include "UART.h"

int main(void){
    volatile uint32_t *leds = (volatile uint32_t *)0x30000000;
    volatile uint32_t *ram0  = (volatile uint32_t *)0x10018000;
    volatile uint32_t *ram1  = (volatile uint32_t *)0x10010000;
    volatile const uint32_t *flash = (volatile const uint32_t *)0x20100000;

    uint32_t n = 0x01234000;
    UART_setBaudScale(10);
    UART_getBaudScale();
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