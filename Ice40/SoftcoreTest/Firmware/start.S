.section .text.start
.global _start
_start:
    li sp, 0x400
    call main
    j hang

hang:
    j hang
