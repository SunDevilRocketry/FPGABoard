lui  x1, 0x80000
addi x2, x0, 0
loop: 
    addi x2, x2, 1
    sw   x2, 0(x1)
    j    loop
