.text
    msg: .asciz "xd\n"

.equ sys_read, 0
.equ sys_write, 1
.equ sys_open, 2
.equ sys_close, 3
.equ sys_exit, 60

.global main
main:
    push %rbp
    movq %rsp, %rbx

    movq $sys_write, %rax
    movq $1, %rdi
    movq $msg, %rsi
    movq $4, %rdx
    syscall

    movq %rbp, %rsp
    pop %rbx
end:
    movq $sys_exit, %rax
    movq $0, %rdi
    syscall
