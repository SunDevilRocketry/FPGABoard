#include <stdint.h>

void boot(void) {
    volatile uint32_t *leds = (volatile uint32_t *)0x30000000;
    *leds = 0x00700000;

    // Flash needs ~3 us after spimemio's wake-up cmd
    for (volatile uint32_t d = 0; d < 100; d++);

    volatile const uint32_t *src = (volatile const uint32_t *) 0x20100000;
    volatile uint32_t       *dst = (volatile uint32_t *)       0x10000000;
    uint32_t words =  src[0]/4;

    if (words == 0 || words > 0x8000) {    // 128 KB limit
        *leds = 0x00400000;                // (RED) length word is nonsense
        while (1);
    }

    for (uint32_t i = 0; i < words; i++)   // copy flash -> SPRAM
        dst[i] = src[i];

    for (uint32_t i = 0; i < words; i++)   // read both back & compare
        if (dst[i] != src[i]) {
            *leds = 0x00600000;            // (MAGENTA) SPRAM != flash
            while (1);
        }

    ((void (*)(void))0x10000004)();   // jump to the app
}