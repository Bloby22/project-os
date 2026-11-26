BITS 64
DEFAULT REL

GLOBAL context_switch
GLOBAL context_restore
GLOBAL context_bootstrap

EXTERN cpu_stop

%define CTX_RSP   0
%define CTX_RBX   8
%define CTX_RBP   16
%define CTX_R12   24
%define CTX_R13   32
%define CTX_R14   40
%define CTX_R15   48
%define CTX_RIP   56
%define CTX_TYPE  64

%define CONTEXT_COOPERATIVE 0
%define CONTEXT_INTERRUPT   1

SECTION .text

context_switch:
    mov [rdi + CTX_RSP], rsp
    mov [rdi + CTX_RBX], rbx
    mov [rdi + CTX_RBP], rbp
    mov [rdi + CTX_R12], r12
    mov [rdi + CTX_R13], r13
    mov [rdi + CTX_R14], r14
    mov [rdi + CTX_R15], r15

    lea rax, [rel .resume]
    mov [rdi + CTX_RIP], rax

    mov qword [rdi + CTX_TYPE], CONTEXT_COOPERATIVE

    mov rdi, rsi

    jmp context_restore

.resume:
    ret

context_restore:
    cli

    cmp qword [rdi + CTX_TYPE], CONTEXT_INTERRUPT
    je context_restore_interrupt

    cmp qword [rdi + CTX_TYPE], CONTEXT_COOPERATIVE
    jne context_invalid

    mov rsp, [rdi + CTX_RSP]

    mov rbx, [rdi + CTX_RBX]
    mov rbp, [rdi + CTX_RBP]
    mov r12, [rdi + CTX_R12]
    mov r13, [rdi + CTX_R13]
    mov r14, [rdi + CTX_R14]
    mov r15, [rdi + CTX_R15]

    mov rax, [rdi + CTX_RIP]

    jmp rax

context_restore_interrupt:
    mov rsp, [rdi + CTX_RSP]

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8

    pop rdi
    pop rsi
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    pop rax

    add rsp, 16

    iretq

context_bootstrap:
    xor ebp, ebp

    cld

    mov rdi, r13

    call r12

    call r14

    call cpu_stop

    ud2

context_invalid:
    cli

    ud2

SECTION .note.GNU-stack noalloc noexec nowrite progbits
