// spi__pkg.sv
//
// Central parameter definitions for the SPI formatter project.
// Three SPI reader peripherals feed one QSPI writer.
//
// WHY THIS EXISTS:
// Each SPI peripheral may have a different native read width (and possibly
// a different SCLK divide ratio / read latency). Keeping these values here,
// instead of hardcoded in the formatter/testbench, means:
//   1. Retargeting to real hardware = editing this file only.
//   2. The asymmetry between peripherals (if any) is visible in one place,
//      instead of being an implicit assumption buried in the FSM.
//
// TODO: Replace placeholder values below once real peripheral datasheets /
// specs are known. Right now all three are assumed 8-bit, matching the
// spimaster module we already have, but that is an assumption, not a fact.

package spi_params_pkg;

    // ------------------------------------------------------------------
    // Per-peripheral read width (bits delivered per `dataready` pulse)
    // ------------------------------------------------------------------
    parameter int SPI0_WIDTH = 8;   // e.g. sensor A -- CONFIRM
    parameter int SPI1_WIDTH = 8;   // e.g. sensor B -- CONFIRM
    parameter int SPI2_WIDTH = 8;   // e.g. sensor C -- CONFIRM

    // ------------------------------------------------------------------
    // Per-peripheral SCLK divide ratio (matches spimaster's `clkscale`)
    // Different clkscale -> different read duration -> ports won't
    // terminate at the same time even if widths match. Keep visible here
    // rather than assuming they're equal.
    // ------------------------------------------------------------------
    parameter int SPI0_CLKSCALE = 4;  // CONFIRM
    parameter int SPI1_CLKSCALE = 4;  // CONFIRM
    parameter int SPI2_CLKSCALE = 4;  // CONFIRM

endpackage : spi_params_pkg