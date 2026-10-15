#include "BMP581.h"
#include "stm32g4xx_hal.h"
#include "stm32g4xx_hal_def.h"
#include "stm32g4xx_hal_gpio.h"
#include "stm32g4xx_hal_spi.h"
#include <stdint.h>
#include <stdbool.h>
#include <stdint.h>
#include <math.h>



//internal guts
#define READ  (0x80)
#define WRITE (0x00)

static uint8_t dummyrx = 0x00;
static uint8_t dummytx = 0xFF;



//internal functions
HAL_StatusTypeDef SPI_HELPER(BARO_DATA baro, uint8_t readwrite, uint8_t address, uint16_t sizetransmit, uint8_t *buf){
    uint8_t txbuf[sizetransmit+1];
    uint8_t rxbuf[sizetransmit+1];

    txbuf[0] = address | readwrite;
    rxbuf[0] = dummyrx;
    for (int i = 1; i < sizetransmit+1; i++){
        if (readwrite == WRITE) {txbuf[i] = buf[i-1];}
        if (readwrite == READ) {txbuf[i] = dummytx;}
        rxbuf[i] = dummyrx;
    }
    HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_RESET);
    HAL_StatusTypeDef success = HAL_SPI_TransmitReceive(baro.SPI_HANDLE, txbuf, rxbuf, sizetransmit+1, HAL_MAX_DELAY);
    HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_SET);

    if (success == HAL_OK){
        if (readwrite == READ) {
            for (int i = 1; i < sizetransmit+1; i++){
                buf[i-1] = rxbuf[i];
            }
        }
    }
    return success;
}



//external functions
HAL_StatusTypeDef baro_Init(BARO_DATA baro) {
    uint8_t rxbuf[] = {0x00, 0x00};
    uint8_t txbuf[] = {(0x80 | BARO_REG_CMD), BARO_CMD_RESET};
    for (int i = 0; i < 2; i++) {
        //reset the dude
        //twice because the first one confirms SPI mode (see datasheet)
        HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_RESET);
        HAL_SPI_TransmitReceive(baro.SPI_HANDLE, txbuf, rxbuf, 2, HAL_MAX_DELAY);
        HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_SET);
        //give time to update
        HAL_Delay(10);
    }


    txbuf[0] = (0x80 | BARO_REG_CHIP_ID);
    HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_RESET);
    HAL_StatusTypeDef success = HAL_SPI_TransmitReceive(baro.SPI_HANDLE, txbuf, rxbuf, 2, HAL_MAX_DELAY);
    HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_SET);

    if (success != HAL_OK) {return success;}
    //if the rxbuf is the chip id, carry on
    if (rxbuf[1] != BARO_CHIP_ID) {return HAL_ERROR;}

    txbuf[0] = (0x80 | BARO_REG_STATUS);
    HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_RESET);
    success = HAL_SPI_TransmitReceive(baro.SPI_HANDLE, txbuf, rxbuf, 2, HAL_MAX_DELAY);
    HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_SET);
    
    if (success != HAL_OK) {return success;}
    //check bit 1 and 0 are 1 and 0 respectively, meaning nvm ready = 1 and nvm_error = 0
    if ((rxbuf[1] & 0x02) == 0x02) {return HAL_ERROR;}

    txbuf[0] = (0x80 | BARO_REG_INT_STATUS);
    HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_RESET);
    success = HAL_SPI_TransmitReceive(baro.SPI_HANDLE, txbuf, rxbuf, 2, HAL_MAX_DELAY);
    HAL_GPIO_WritePin(baro.NSS_LET, baro.NSS_PIN, GPIO_PIN_SET);

    if (success != HAL_OK) {return success;}
    //if int status doesnt equal ready status
    //so normally you would check here, but the BMP581 sucks! This check is (mostly) broken! ignore it!
    /*
    if (rxbuf[1] != 0x10) {return HAL_ERROR;}
    */

    return HAL_OK;
}

uint8_t baro_ChipID(BARO_DATA baro){
    uint8_t address[] = {dummyrx};
    SPI_HELPER(baro, READ, BARO_REG_CHIP_ID, 1, address);
    return address[0];
};

HAL_StatusTypeDef baro_Temp_Pres_LowRes (BARO_DATA baro) {
    uint8_t rx[] = {dummyrx};
    uint8_t settings[] = {0b01000000};
    //bit 6: 1 = pressure enable
    //bits 5-3: 0 = lowest temp oversampling
    //bits 2-0: 0 = lowest pressure oversampling
    HAL_StatusTypeDef success = SPI_HELPER(baro, WRITE, BARO_REG_OSR_CONFIG, 1, settings);
    if (success != HAL_OK) {return success;}

    success = SPI_HELPER(baro, READ, BARO_REG_OSR_CONFIG, 1, rx);
    if (success != HAL_OK) {return success;}

    if (rx[0] == 0b01000000) {return HAL_OK;}
    else {return HAL_ERROR;}
}

HAL_StatusTypeDef baro_NormalPWR (BARO_DATA baro, uint8_t *data) {
    uint8_t rx[] = {dummyrx};
    uint8_t settings[] = {0b00000001};
    //bit 1-0: 01 = normal mode
    //bits 6-2: 0 = highest refresh rate (240Hz)
    //bits 7 : 0 = disable deep standby
    HAL_StatusTypeDef success = SPI_HELPER(baro, WRITE, BARO_REG_ODR_CONFIG, 1, settings);
    if (success != HAL_OK) {return success;}

    success = SPI_HELPER(baro, READ, BARO_REG_EFFECTIVE_OSR, 1, rx);
    if (success != HAL_OK) {return success;}

    if ((rx[0] & 0x80) == 0x80) {
        *data = rx[0];
        return HAL_OK;
    }
    else {return HAL_ERROR;}
}

HAL_StatusTypeDef baro_ReadData(BARO_DATA baro, float *temp, float *pres) {
    uint8_t readdata[6] = {0};
    HAL_StatusTypeDef success = SPI_HELPER(baro, READ, BARO_REG_DATA_START, 6, readdata);
    if (success != HAL_OK) {return success;}
    uint32_t pres_raw = (readdata[5] << 16) | (readdata[4] << 8) | readdata[3];
    uint32_t temp_raw = (readdata[2] << 16) | (readdata[1] << 8) | readdata[0];

    int32_t t_signed = (int32_t)(temp_raw << 8) >>8;

    *temp = t_signed / 65536.0f;
    *pres = pres_raw / 64.0f;
    return HAL_OK;
}

float baro_PresToAlt(float pres, float pres0){
    if (pres0 == 0) {pres0 = 101325.0f;}
    return 44330.0f * (1.0f - powf(pres / pres0, 0.1903f));
}

float baro_CalibPres0(float pres_normal, float alt_known) {
    return (pres_normal / powf(1 - alt_known/44330.0f, 5.255f));
}


