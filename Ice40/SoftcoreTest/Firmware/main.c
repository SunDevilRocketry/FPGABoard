#include <stdint.h>

int main(void){
    volatile uint32_t *leds = (uint32_t *)0x30000000;
    uint32_t n = 0;
    while (1) { 
        n++; *leds = n; 
    }
}