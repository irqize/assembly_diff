#CHECKS IF FIRST TWO COMMAND LINE ARGUMENTS ARE THE SAME
.text
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
    addq    $8, %rax  #first argument is actually the second one because the first one is executable name
	movq	(%rax), %rax
	movq	%rax, (arg1)
    #copy adress of the second one to the variable
    movq	%rsi, %rax
    addq    $16, %rax
    movq	(%rax), %rax
	movq	%rax, (arg2)

    #copy adresses of first chars to rdi/rsi
    movq (arg1), %rdi 
    movq (arg2), %rsi

loop:
    #copy first chars to r8b/r9b (one byte r8 and r9 registers)
    movb (%rdi), %r8b
    movb (%rsi), %r9b
    #check if any of the string hasnt already ended
    jmp check_null
loop_cnt:
    #check if characters are the same
    cmpb %r8b, %r9b
    jne not_equal
    #go to next char
    addq $1, %rdi
    addq $1, %rsi
    #compare chars once again
    jmp loop
  
    
equal:
    #print equals message
    movq $0, %rax
    movq $str_output, %rdi
    movq $equal_string, %rsi
    call printf
    #restore old stack
    movq %rbp, %rsp
    pop %rbp
    #return 0
    movq $60, %rax
    movq $0, %rdi
    syscall



not_equal:
    #print not equals message
    movq $0, %rax
    movq $str_output, %rdi
    movq $not_equal_string, %rsi
    call printf
    #restore old stack
    movq %rbp, %rsp
    pop %rbp
    #return 0
    movq $60, %rax
    movq $0, %rdi
    syscall


check_null:
    cmpb $0, %r8b #check if first string already ended
    je check_null_second_also
    jne check_null_second_only


check_null_second_only:
    cmpb $0, %r9b #check if second string already ended
    je not_equal
    jmp loop_cnt #if both didnt end continue loop

check_null_second_also:
    cmpb $0, %r9b  #check if second string already ended
    je equal
    jne not_equal
