.DEFAULT_GOAL := all

# Tools
CC      := clang
AS      := nasm
QEMU    := qemu-system-x86_64
XORRISO := D:/MSYS64/usr/bin/xorriso.exe
LIMINE  := limine/limine-tool-windows-x86/limine.exe

# Directories
BUILD    := build
KERNEL   := kernel
ISO_ROOT := iso_root

# Output files
ELF := $(BUILD)/kernel.elf
ISO := $(BUILD)/os.iso

# Compiler flags
CFLAGS := --target=x86_64-unknown-none-elf \
          -std=gnu11 \
          -ffreestanding \
          -fno-stack-protector \
          -fno-pic \
          -fno-pie \
          -mno-red-zone \
          -mcmodel=kernel \
          -mgeneral-regs-only \
          -I$(KERNEL)/include \
          -Wall \
          -Wextra \
          -MMD \
          -MP

# Assembler flags
ASFLAGS := -f elf64

# Linker flags
LDFLAGS := --target=x86_64-unknown-none-elf \
           -fuse-ld=lld \
           -nostdlib \
           -static \
           -Wl,-T,$(KERNEL)/linker.ld

# Recursive source discovery
rwildcard = $(foreach d,$(wildcard $(1)*),\
            $(call rwildcard,$d/,$2)\
            $(filter $(subst *,%,$2),$d))

C_SOURCES := $(call rwildcard,$(KERNEL)/,*.c)
ASM_SOURCES := $(call rwildcard,$(KERNEL)/,*.asm)

# Object files
C_OBJECTS := $(patsubst %.c,$(BUILD)/%.o,$(C_SOURCES))
ASM_OBJECTS := $(patsubst %.asm,$(BUILD)/%.asm.o,$(ASM_SOURCES))

OBJECTS := $(ASM_OBJECTS) $(C_OBJECTS)
DEPS := $(C_OBJECTS:.o=.d)

# Build targets
.PHONY: all kernel iso run debug clean

all: $(ISO)

kernel: $(ELF)

iso: $(ISO)

# Compile C sources
$(BUILD)/%.o: %.c
	powershell -NoProfile -Command "New-Item -ItemType Directory -Force '$(@D)' | Out-Null"
	$(CC) $(CFLAGS) -c $< -o $@

# Compile Assembly sources
$(BUILD)/%.o: %.asm
	powershell -NoProfile -Command "New-Item -ItemType Directory -Force '$(@D)' | Out-Null"
	$(AS) $(ASFLAGS) $< -o $@

# Link kernel
$(ELF): $(OBJECTS) $(KERNEL)/linker.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS)

# Bootable ISO
$(ISO): $(ELF) boot/limine.conf
	powershell -NoProfile -Command "New-Item -ItemType Directory -Force '$(ISO_ROOT)/boot', '$(ISO_ROOT)/EFI/BOOT' | Out-Null"

	powershell -NoProfile -Command "Copy-Item '$(ELF)' '$(ISO_ROOT)/boot/kernel.elf' -Force"
	powershell -NoProfile -Command "Copy-Item 'boot/limine.conf' '$(ISO_ROOT)/boot/limine.conf' -Force"

	powershell -NoProfile -Command "Copy-Item 'limine/limine-bios.sys' '$(ISO_ROOT)/boot/' -Force"
	powershell -NoProfile -Command "Copy-Item 'limine/limine-bios-cd.bin' '$(ISO_ROOT)/boot/' -Force"
	powershell -NoProfile -Command "Copy-Item 'limine/limine-uefi-cd.bin' '$(ISO_ROOT)/boot/' -Force"
	powershell -NoProfile -Command "Copy-Item 'limine/BOOTX64.EFI' '$(ISO_ROOT)/EFI/BOOT/' -Force"

	$(XORRISO) -as mkisofs \
		-b boot/limine-bios-cd.bin \
		-no-emul-boot \
		-boot-load-size 4 \
		-boot-info-table \
		--efi-boot boot/limine-uefi-cd.bin \
		-efi-boot-part \
		--efi-boot-image \
		--protective-msdos-label \
		$(ISO_ROOT) \
		-o $(ISO)

	$(LIMINE) bios-install $(ISO)

# QEMU
run: $(ISO)
	$(QEMU) -cdrom $(ISO) -m 512M -boot d

debug: $(ISO)
	$(QEMU) -cdrom $(ISO) -m 512M -boot d \
		-no-reboot \
		-no-shutdown \
		-d int,cpu_reset \
		-D $(BUILD)/qemu.log

# Clean
clean:
	powershell -NoProfile -Command "Remove-Item -Recurse -Force '$(BUILD)', '$(ISO_ROOT)' -ErrorAction SilentlyContinue"

# Header dependencies
-include $(DEPS)
