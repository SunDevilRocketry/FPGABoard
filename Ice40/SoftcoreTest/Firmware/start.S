.section .text.start
.global _start
_start:
    li sp, 0x10010000
    call main
    j hang

hang:
    j hang
