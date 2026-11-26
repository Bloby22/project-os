BITS 64
DEFAULT REL

GLOBAL syscall_entry
EXTERN syscall_dispatch
EXTERN syscall_stack_top

SECTION .bss
ALIGN 8
user_rsp: resq 1

SECTION .text

syscall_entry:
    ; SYSCALL masks interrupts but retains the user stack pointer.
    mov [user_rsp], rsp
    mov rsp, [syscall_stack_top]

    push 0x1b
    push qword [user_rsp]
    push r11
    push 0x23
    push rcx
    push 0
    push 0

    push rax
    push rbx
    push rcx
    push rdx
    push rbp
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    cld
    mov rdi, rsp
    call syscall_dispatch

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

SECTION .note.GNU-stack noalloc noexec nowrite progbits
