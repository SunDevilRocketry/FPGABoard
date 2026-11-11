.section .text.start
.global _start
_start:
    li sp, 0x400
    call boot
    j hang

hang:
    j hang
