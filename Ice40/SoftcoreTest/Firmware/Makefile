PREFIXES := riscv64-unknown-elf- riscv-none-elf- riscv64-elf-
CROSS ?= $(firstword $(foreach p,$(PREFIXES),$(if $(shell command -v $(p)gcc 2>/dev/null),$(p))))

ifeq ($(CROSS),)
$(error No RISC-V toolchain found. Tried: $(PREFIXES))
endif

CC      = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy
CFLAGS  = -march=rv32ic -mabi=ilp32 -O1 -ffreestanding -nostdlib

all: firmware.hex

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin

firmware.elf: start.S main.c sections.ld
	$(CC) $(CFLAGS) -T sections.ld start.S main.c -o firmware.elf

firmware.hex: firmware.bin
	xxd -e -g 4 -c 4 firmware.bin | awk '{print $$2}' > firmware.hex

clean:
	rm -f *.o *.elf *.bin