#include <stdint.h>

void boot(void) {
    volatile const uint32_t *src = (volatile const uint32_t *) 0x20100000;
    volatile uint32_t       *dst = (volatile uint32_t *)       0x10000000;
    uint32_t words =  src[0]/4;

    for (uint32_t i = 0; i < words; i++)
        dst[i] = src[i];

    ((void (*)(void))0x10000004)();   // jump to the app
}