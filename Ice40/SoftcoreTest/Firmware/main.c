#include <stdint.h>

int main(void){
    volatile uint32_t *leds = (volatile uint32_t *)0x30000000;
    volatile uint32_t *ram0  = (volatile uint32_t *)0x10000000;
    volatile uint32_t *ram1  = (volatile uint32_t *)0x10010000;
    
    uint32_t n = 0x01234000;
    
    while (1) { 
        n++; 
        *ram0 = n;
        *ram1 = ~n;
        *leds = *ram0;
        *leds = *ram1;
    }
}