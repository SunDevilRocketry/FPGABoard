#include <stdint.h>

int main(void){
    volatile uint32_t *leds = (volatile uint32_t *)0x30000000;
    volatile uint32_t *ram0  = (volatile uint32_t *)0x10018000;
    volatile uint32_t *ram1  = (volatile uint32_t *)0x10010000;
    volatile const uint32_t *flash = (volatile const uint32_t *)0x20100000;
    
    uint32_t n = 0x01234000;
    
    *leds = *flash;

    while (1) { 
        n++; 
        *ram0 = n;
        *ram1 = ~n;
        *leds = *ram0;
    }
}