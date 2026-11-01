#include <stdint.h>

int main(void){
    volatile uint32_t *leds = (volatile uint32_t *)0x30000000;
    volatile uint32_t *ram  = (volatile uint32_t *)0x10000000;
    
    uint32_t n = 0x0000000;
    
    while (1) { 
        n++; 
        *ram = n;
        *leds = *ram; 
    }
}