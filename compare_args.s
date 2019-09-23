#CHECKS IF FIRST TWO COMMAND LINE ARGUMENTS ARE THE SAME
.text
    format: .asciz "%s\n"
    str: .asciz "xd"
    int_output: .string "Num of args: %d\n"
    str_output: .string "%s\n"
    not_equal_string: .asciz "Arguments are not equal"
    equal_string: .asciz "Arguments are equal"

.global main
.data
    arg1: .quad 0
    arg2: .quad 0
main:
    push %rbp
    movq %rsp, %rbp

    #copy adress of the first one to the variable
	movq	%rsi, %rax
    addq    $8, %rax
	movq	(%rax), %rax
	movq	%rax, (arg1)
    #copy adress of the second one to the variable
    movq	%rsi, %rax
    addq    $16, %rax
    movq	(%rax), %rax
	movq	%rax, (arg2)

    movq (arg1), %rdi 
    movq (arg2), %rsi

loop:
    movb (%rdi), %r8b
    movb (%rsi), %r9b
    call check_null
    cmpb %r8b, %r9b
    jne not_equal
    addq $1, %rdi
    addq $1, %rsi
    jmp loop
  
    
equal:
    movq $0, %rax
    movq $str_output, %rdi
    movq $equal_string, %rsi
    call printf
    movq %rbp, %rsp
    pop %rbp
    movq $60, %rax
    movq $0, %rdi
    syscall



not_equal:
    movq $0, %rax
    movq $str_output, %rdi
    movq $not_equal_string, %rsi
    call printf
    movq %rbp, %rsp
    pop %rbp
    movq $60, %rax
    movq $0, %rdi
    syscall


check_null:
    cmpb $0, %r8b
    je check_null_second_also
    jne check_null_second_only


check_null_second_only:
    cmpb $0, %r9b
    je not_equal
    ret

check_null_second_also:
    cmpb $0, %r9b
    je equal
    jne not_equal
