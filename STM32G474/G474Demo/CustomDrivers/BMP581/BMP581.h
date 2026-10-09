//if not def def
#ifndef BMP581_H
#define BMP581_H

//includes
#include "main.h"
#include "stm32g4xx_hal_spi.h"
#include <stdint.h>

//macros and constants


//external facing function protorypes

void BMP581_Init(SPI_HandleTypeDef *hspi);

uint8_t Baro_ChipID(SPI_HandleTypeDef *hspi);

#endif