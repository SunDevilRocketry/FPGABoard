//if not def def
#ifndef BMP581_H
#define BMP581_H

//includes
#include "main.h"
#include "stm32g474xx.h"
#include "stm32g4xx_hal_spi.h"
#include <stdint.h>



//deivce regs
#define BARO_REG_CHIP_ID       (0x01)
#define BARO_REG_STATUS        (0x28)
#define BARO_REG_INT_STATUS    (0x27)
#define BARO_REG_CMD           (0x7E)
#define BARO_REG_OSR_CONFIG    (0x36)
#define BARO_REG_ODR_CONFIG    (0x37)
#define BARO_REG_EFFECTIVE_OSR (0x38)
#define BARO_REG_DATA_START    (0x1D)



//device params
#define BARO_CHIP_ID (0x50)
#define BARO_CMD_RESET (0xB6)



//macros and constants
typedef struct _BARO_DATA{
    SPI_HandleTypeDef *SPI_HANDLE;
    GPIO_TypeDef *NSS_LET;
    uint16_t NSS_PIN;
} BARO_DATA;



//external facing function protorypes
HAL_StatusTypeDef baro_Init(BARO_DATA baro);

uint8_t baro_ChipID(BARO_DATA baro);

HAL_StatusTypeDef baro_Temp_Pres_LowRes (BARO_DATA baro);

HAL_StatusTypeDef baro_NormalPWR (BARO_DATA baro, uint8_t *data);

HAL_StatusTypeDef baro_ReadData(BARO_DATA baro, float *temp, float *pres);

float baro_PresToAlt(float pres, float pres0);

float baro_CalibPres0(float pres_normal, float alt_known);

#endif