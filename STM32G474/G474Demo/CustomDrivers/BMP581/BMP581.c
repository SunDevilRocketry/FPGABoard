#include "BMP581.h"
#include "stm32g4xx_hal_def.h"
#include "stm32g4xx_hal_spi.h"
#include <stdint.h>

//internal guts
#define READ = (0x00)
#define WRITE = (0x80)

static uint8_t dummybuf = 0x00;

//internal functions
/*
bool SPI_READ(SPI_HandleTypeDef *hspi, uint8_t readwrite, uint8_t address, uint16_t sizeread, uint8_t[] writebuf){
    uint8_t txbuf[sizeread+1];
    uint8_t rxbuf[sizeread+1];

    txbuf[0] = address | readwrite;
    rxbuf[0] = dummybuf;
    for (int i = 1; i < sizeread+1; i++){
        txbuf[i] = dummybuf;
        rxbuf[i] = dummybuf;
    }

    HAL_SPI_TransmitReceive(*hspi, txbuf, rxbuf, sizeread, HAL_MAX_DELAY);

    for (int i = 1; i < sizeread+1; i++){
        writebuf[i] = rxbuf[i];
    }
}
    */

//external function
void BMP581_Init(SPI_HandleTypeDef *hspi);

uint8_t Baro_ChipID(SPI_HandleTypeDef *hspi){
    uint8_t txbuf[2] = {0x00, 0x00};
    uint8_t rxbuf[2];
    txbuf[0] = 0x80 | 0x01;
    HAL_SPI_TransmitReceive(hspi, txbuf, rxbuf, 2, HAL_MAX_DELAY);
    return rxbuf[1];
}


