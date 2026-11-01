ENTRY(_start)

MEMORY {
    SPRAM (rwx) : ORIGIN = 0x10000000, LENGTH = 128K
}

SECTIONS {
    .text   : { *(.text.header) *(.text.start) *(.text*) } > SPRAM
    .rodata : { *(.rodata*) *(.srodata*) } > SPRAM
    .data   : { *(.data*) *(.sdata*) } > SPRAM
    . = ALIGN(4);
    _image_end = .;
    .bss    : { _bss_start = .; *(.sbss*) *(.bss*) *(COMMON) . = ALIGN(4); _bss_end = .; } > SPRAM
}

_image_size = _image_end - ORIGIN(SPRAM);