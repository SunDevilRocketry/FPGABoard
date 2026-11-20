#ifndef TIMER_H
#define TIMER_H

#include <cstdint>
#include <stdint.h>

static volatile uint32_t *const timer_enable = (volatile uint32_t *)0x30002000;
static volatile uint32_t *const timer_reset = (volatile uint32_t *)0x30002100;
static volatile uint32_t *const timer_countl = (volatile uint32_t *)0x30002200;
static volatile uint32_t *const timer_counth = (volatile uint32_t *)0x30002300;

uint64_t get_count();

uint64_t get_elapsed(uint64_t stamp);

void freeze();

void unfreeze();

uint32_t reset();

#endif