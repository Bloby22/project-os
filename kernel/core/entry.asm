BITS 64
DEFAULT REL

GLOBAL _start
EXTERN kernel_main

SECTION .bss
ALIGN 16

stack_bottom:
    RESB 65536
stack_top:

SECTION .text

_start:
    ; Disable interrupts
    cli

    ; Clear direction flag
    cld

    ; Initialize kernel stack
    lea rsp, [rel stack_top]
    and rsp, -16

    ; Clear frame pointer
    xor rbp, rbp

    ; Start the kernel
    call kernel_main

.halt:
    cli
    hlt
    jmp .halt
