.text   #predefined strings
    line: .asciz "\n---\n"
    file1: .asciz "< "
    file2: .asciz "> "
    newline2: .asciz "\n\n"
    string_output: .asciz "%s"
    string_output_nl: .asciz "%s\n"



#reserved space for file descriptor
.lcomm fd, 1
.lcomm file1_name_address, 8
.lcomm file2_name_address, 8
#reserved space for files contents
.lcomm file1_buffer, 1024
.lcomm file2_buffer, 1024

.lcomm current_character_address_file1, 8
.lcomm current_character_address_file2, 8

.lcomm length_line_file1, 8
.lcomm length_line_file2, 8

.lcomm current_line_address_file1, 8
.lcomm current_line_address_file2, 8



.data
    start_of_current_line_file1: .quad 0
    start_of_current_line_file2: .quad 0
    current_possition_file1: .quad 0
    current_possition_file2: .quad 0
    address_file1: .quad 0
    address_file2: .quad 0




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

    #copy address of the first one to the variable
	movq	%rsi, %rax
    addq    $8, %rax  #first argument is actually the second one because the first one is executable name
	movq	(%rax), %rax
	movq	%rax, (file1_name_address)
    #copy address of the second one to the variable
    movq	%rsi, %rax
    addq    $16, %rax
    movq	(%rax), %rax
	movq	%rax, (file2_name_address)

    #open and save to memory first file
    movq $sys_open, %rax
    movq (file1_name_address), %rdi
    movq $0, %rsi
    movq $0777, %rdx
    syscall 

    movq %rax, (fd)

    movq $sys_read, %rax
    movq (fd), %rdi
    movq $file1_buffer, %rsi
    movq $1024, %rdx
    syscall 
    
    movq $sys_close, %rax
    movq $fd, %rdi
    syscall 
    ####################################
    

    #open and save to memory second file
    movq $sys_open, %rax
    movq (file2_name_address), %rdi
    movq $0, %rsi
    movq $0777, %rdx
    syscall 

    movq %rax, (fd)

    movq $sys_read, %rax
    movq (fd), %rdi
    movq $file2_buffer, %rsi
    movq $1024, %rdx
    syscall 
    
    movq $sys_close, %rax
    movq $fd, %rdi
    syscall 
    ####################################

    movq $file1_buffer, %r13 #r13 registry will store address to currently compared char of file1
    movq $file2_buffer, %r14 #r14 registry will store address to currently compared char of file2
    movq $file1_buffer, (current_character_address_file1)
    movq $file2_buffer, (current_character_address_file2)


    movq $1, %r8 #r8 registry will be storing current length of line1
    movq $1, %r9 #r9 registry will be storing current length of line2
    movq $1, (length_line_file1)
    movq $1, (length_line_file2)

    movq $file1_buffer, %r11 #r11 registry will be storing position of current line starting in file1
    movq $file2_buffer, %r12 #r12 registry will be storing position of current line starting in file1
    movq $file1_buffer, (current_line_address_file1)
    movq $file2_buffer, (current_line_address_file2)

    

loop:
    jmp compare_line
after_compare_line:
    
    movq %rbp, %rsp
    popq %rbp
end:
    movq $sys_exit, %rax
    movq $0, %rdi
    syscall




compare_line:
    jmp check_eof
after_check_eof:
    jmp check_nl
after_check_no_nl:
    #call print_diff #debug purposes
    movb (%r13), %al
    movb (%r14), %bl

    incq %r13
    incq %r14

    incq %r8
    incq %r9

    cmpb  %al,  %bl
    je compare_line


    call go_to_end_of_line_file1
    call go_to_end_of_line_file2

    
after_check_nl:
    decq %r8
    decq %r9
    call print_diff

    #start new line
    movq $1, %r8
    movq $1, %r9
    movq %r13, %r11
    movq %r14, %r12

    jmp compare_line

check_eof:
    cmpb $0, (%r13)
    je check_eof_file2_also
    jne check_eof_file2_only
check_eof_file2_only:
    cmpb $0, (%r14)
    jne after_check_eof
    je print_eof
check_eof_file2_also:
    cmpb $0, (%r14)
    je end
    jne print_eof


check_nl:
    cmpb $10, (%r13)
    je check_nl_file2_also
    jne check_nl_file2_only
check_nl_file2_only:
    cmpb $10, (%r14)
    jne after_check_no_nl
    call go_to_end_of_line_file1
    incq %r14
    jmp after_check_nl
check_nl_file2_also:
    cmpb $10, (%r14)
    je both_nl
    call go_to_end_of_line_file2
    incq %r13
    jmp after_check_nl
both_nl:
    incq %r13
    incq %r14
    movq $1, %r8
    movq $1, %r9
    movq %r13, %r11
    movq %r14, %r12
    jmp compare_line



print_eof:
    #save current state from registers to variables
    movq %r11, (current_line_address_file1)
    movq %r12, (current_line_address_file2)

    movq %r8, (length_line_file1)
    movq %r9, (length_line_file2)

    movq %r13, (current_character_address_file1)
    movq %r14, (current_character_address_file2)
    # write "> "
    xor %rsi, %rsi
    movq $string_output, %rdi
    movq $file1, %rsi
    call printf
    # write file1
    movq (current_line_address_file1), %r11
    xor %rsi, %rsi
    movq $string_output, %rdi
    movq %r11, %rsi
    call printf
    # write "---"
    xor %rsi, %rsi
    movq $string_output, %rdi
    movq $line, %rsi
    call printf
    # write "< "
    xor %rsi, %rsi
    movq $string_output, %rdi
    movq $file2, %rsi
    call printf
    # write file2
    movq (current_line_address_file2), %r12
    xor %rsi, %rsi
    movq $string_output_nl, %rdi
    movq %r12, %rsi
    call printf
    jmp end
print_diff:
    #save current state from registers to variables
    movq %r11, (current_line_address_file1)
    movq %r12, (current_line_address_file2)

    movq %r8, (length_line_file1)
    movq %r9, (length_line_file2)

    movq %r13, (current_character_address_file1)
    movq %r14, (current_character_address_file2)
    # write "> "
    movq $sys_write, %rax
    movq $1, %rdi
    movq $file1, %rsi
    movq $2, %rdx
    syscall
    # write line1
    movq (length_line_file1), %r8
    movq (current_line_address_file1), %r11
    movq $sys_write, %rax
    movq $1, %rdi
    movq %r11, %rsi
    movq %r8, %rdx
    syscall
    # write "---"
    movq $sys_write, %rax
    movq $1, %rdi
    movq $line, %rsi
    movq $5, %rdx
    syscall
    # write "> "
    movq $sys_write, %rax
    movq $1, %rdi
    movq $file2, %rsi
    movq $2, %rdx
    syscall
    # write line2
    movq (length_line_file2), %r9
    movq (current_line_address_file2), %r12
    movq $sys_write, %rax
    movq $1, %rdi
    movq %r12, %rsi
    movq %r9, %rdx
    syscall
    # write 2newline
    movq $sys_write, %rax
    movq $1, %rdi
    movq $newline2, %rsi
    movq $2, %rdx
    syscall
    #restore current state from variables to registers
    movq (length_line_file1), %r8
    movq (length_line_file2), %r9
    movq (current_line_address_file1), %r11
    movq (current_line_address_file2), %r12
    movq (current_character_address_file1), %r13
    movq (current_character_address_file2), %r14
    ret


go_to_end_of_line_file1:
    cmpb $10, (%r13)
    je after_go_to_line1

    incq %r13
    incq %r8

    cmpb $10, (%r13)
    je after_go_to_line1

    cmpb $0, (%r13)
    jne go_to_end_of_line_file1
after_go_to_line1:
    incq %r13
    ret



go_to_end_of_line_file2:
    cmpb $10, (%r14)
    je after_go_to_line2

    incq %r14
    incq %r9

    cmpb $10, (%r14)
    je after_go_to_line2

    cmpb $0, (%r14)
    jne go_to_end_of_line_file2
after_go_to_line2:
    incq %r14
    ret
