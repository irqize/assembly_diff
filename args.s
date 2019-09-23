#PRINTS FIRST TWO COMMAND LINE ARGUMENTS
.text
    format: .asciz "%s\n"
    str: .asciz "xd"
    int_output: .string "Num of args: %d\n"
    str_output: .string "%s\n"
.global main
.data
    arg1: .quad 0
    arg2: .quad 0
main:
    push %rbp
    movq %rsp, %rbp

    push %rsi

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
   
    #print the first one
    movq $0, %rax
    movq $str_output, %rdi
    movq (arg1), %rsi
    call printf

    #print the second one
    movq $0, %rax
    movq $str_output, %rdi
    movq (arg2), %rsi
    call printf


    movq %rbp, %rsp
    pop %rbp
end:
    movq $60, %rax
    movq $0, %rdi
    syscall
