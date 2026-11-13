.section .text.header
.word _image_size

.section .text.start
.global _start
_start:
    li sp, 0x10020000

    la t0, _bss_start
    la t1, _bss_end
1:  bgeu t0, t1, 2f
    sw zero, 0(t0)
    addi t0, t0, 4
    j 1b
2:
    call main
hang:
    j hang