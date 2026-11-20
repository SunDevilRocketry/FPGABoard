#include "TIMER.h"
#include <stdint.h>

uint64_t get_count() {
    freeze();
    uint64_t ret = ((uint64_t) *timer_counth) << 32 | *timer_countl;
    unfreeze();
    return ret;
}

uint64_t get_elapsed(uint64_t stamp) {
    return get_count() - stamp;
}

void freeze() {
    *timer_enable = 0;
}

void unfreeze() {
    *timer_enable = 1;
}

uint32_t reset() {
    freeze();
    *timer_reset = 1;
    *timer_reset = 0;
    if (get_count() == 0) {
        unfreeze();
        return 1;
    }
    unfreeze();
    return 0;
}