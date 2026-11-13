PREFIXES := riscv64-unknown-elf- riscv-none-elf- riscv64-elf-
CROSS ?= $(firstword $(foreach p,$(PREFIXES),$(if $(shell command -v $(p)gcc 2>/dev/null),$(p))))

ifeq ($(CROSS),)
$(error No RISC-V toolchain found. Tried: $(PREFIXES))
endif

CC      = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy
CFLAGS  = -march=rv32ic -mabi=ilp32 -O1 -ffreestanding -nostdlib
INCLUDES = -Ilib/UART

all: firmware.hex ../flash_text.hex

# Bootloader (EBR image, baked into the bitstream)
firmware.elf: start.S boot.c sections.ld
	$(CC) $(CFLAGS) -T sections.ld start.S boot.c -o firmware.elf

# Padded manually [mem[i] = 32'h0]
firmware.bin: firmware.elf
	$(OBJCOPY) -O binary --pad-to 0x400 firmware.elf firmware.bin

firmware.hex: firmware.bin
	xxd -e -g 4 -c 4 firmware.bin | awk '{print $$2}' > firmware.hex

# App (Runs from SPRAM, loaded into the fake flash @ the 1 MB offset)
app/app.elf: app/start.S app/main.c app/app.ld lib/UART/UART.c
	$(CC) $(CFLAGS) $(INCLUDES) -T app/app.ld app/start.S app/main.c lib/UART/UART.c -o app/app.elf

app/app.bin: app/app.elf
	$(OBJCOPY) -O binary app/app.elf app/app.bin

../flash_text.hex: app/app.bin
	{ echo @100000; xxd -p -c 1 app/app.bin; } > ../flash_text.hex

clean:
	rm -f *.o *.elf *.bin app/*.elf app/*.bin