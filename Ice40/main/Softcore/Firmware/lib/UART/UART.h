#ifndef UART_H
#define UART_H

#include <stdint.h>

static volatile uint32_t *const uart_div = (volatile uint32_t *)0x30001000;
static volatile uint32_t *const uart_buf = (volatile uint32_t *)0x30001100;
static volatile uint32_t *const uart_ctl = (volatile uint32_t *)0x30001200;  // bit 0: UART takes flash pins 14/15

void UART_putchar(char c);

void UART_print(const char *p);

uint32_t UART_getchar(uint32_t timeout);

uint32_t UART_getBaudScale();

void UART_setBaudScale(uint32_t scale);

#endif 