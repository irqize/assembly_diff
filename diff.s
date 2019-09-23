.text
    file_name: .asciz "text2"
    int_output_format: .string "File size %d \n"
    string_output_format: .string "\n%s\n"
    true_string: .asciz "true"
    false_string: .asciz "false"
    number_text: .asciz "2"
.lcomm fd, 1
.lcomm file_buffer, 1024
.lcomm number, 1
.data
    len: .quad 0

#linux syscalls
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
    
    movq %rax, (len)
    movq $0, %rax
    movq $int_output_format, %rdi
    movq (len), %rsi
    call printf
    

    movq $sys_close, %rax
    movq $fd, %rdi
    syscall 

    movq $sys_write, %rax
    movq $1, %rdi
    movq $file_buffer, %rsi
    lea 1(%rsi), %rsi
    movq $1, %rdx
    syscall

    mov (%rsi), %al #move thing we compare to 1byte register
    cmpb %al, (number_text)
    je print_true
    jne print_false
    
    movq %rbp, %rsp
    popq %rbp
end:
    movq $sys_exit, %rax
    movq $0, %rdi
    syscall




loop_lines:

    ret

loop_single_line:

    ret
    
print_true:
    pushq %rbp
    movq %rsp, %rbp
    movq $0, %rax
    movq $string_output_format, %rdi
    movq $true_string, %rsi
    call printf
    movq %rbp, %rsp
    popq %rbp
    ret

print_false:
    pushq %rbp
    movq %rsp, %rbp
    movq $0, %rax
    movq $string_output_format, %rdi
    movq $false_string, %rsi
    call printf
    movq %rbp, %rsp
    popq %rbp
    ret
