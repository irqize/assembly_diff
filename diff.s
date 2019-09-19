.text
    file_name: .asciz "text"
.lcomm fd, 1
.lcomm file_buffer, 1024

.equ sys_read, 0
.equ sys_write, 1
.equ sys_open, 2
.equ sys_close, 3
.equ sys_exit, 60

.global main
main:
    pushq %rbp
    movq %rsp, %rbp

    movq $sys_open, %rax
    movq $file_name, %rdi
    movq $0, %rsi
    movq $0777, %rdx
    syscall 

    movq %rax, (fd)

    movq $sys_read, %rax
    movq (fd), %rdi
    movq $file_buffer, %rsi
    movq $1024, %rdx
    syscall 
  

    movq $sys_close, %rax
    movq $fd, %rdi
    syscall 

    movq $sys_write, %rax
    movq $1, %rdi
    movq $file_buffer, %rsi
    movq $1024, %rdx
    syscall


    
    movq %rbp, %rsp
    popq %rbp
end:
    movq $sys_exit, %rax
    movq $0, %rdi
    syscall
