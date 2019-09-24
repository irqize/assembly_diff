.text
    #printf formats
    printf_string_format_nl: .asciz "%s\n"
    printf_string_format: .asciz "%s"
    printf_int_format_nl: .asciz "%i\n"

    #predefined strings
    line: .asciz "---"
    file1: .asciz "< "
    file2: .asciz "> "


#reserved space for file descriptor
.lcomm fd, 1
.lcomm file1_name_adress, 8
.lcomm file2_name_adress, 8
#reserved space for files contents
.lcomm file1_buffer, 1024
.lcomm file2_buffer, 1024


.data
    start_of_current_line_file1: .quad 0
    start_of_current_line_file2: .quad 0
    current_possition_file1: .quad 0
    current_possition_file2: .quad 0



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

    #copy adress of the first one to the variable
	movq	%rsi, %rax
    addq    $8, %rax  #first argument is actually the second one because the first one is executable name
	movq	(%rax), %rax
	movq	%rax, (file1_name_adress)
    #copy adress of the second one to the variable
    movq	%rsi, %rax
    addq    $16, %rax
    movq	(%rax), %rax
	movq	%rax, (file2_name_adress)

    #open and save to memory first file
    movq $sys_open, %rax
    movq (file1_name_adress), %rdi
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
    movq (file2_name_adress), %rdi
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

    movq $0, %r8 #r8 registry will be storing position in file1
    movq $0, %r9 #r9 registry will be storing position in file2

    movq $0, %r11 #r11 registry will be storing position of current line starting in file1
    movq $0, %r12 #r12 registry will be storing position of current line starting in file1
    

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
    jmp check__nl
after_check_nl:
    movb (%r13), %al
    movb (%r14), %bl

    incq %r13
    incq %r14
    incq %r8
    incq %r9

    cmpb  %al,  %bl
    je compare_line
    jne print_diff_eof ##TO CHANGE

    call go_to_end_of_line_file1
    call go_to_end_of_line_file2

    jmp after_compare_line

check_eof:
    cmpb $0, (%r13)
    je check_eof_file2_also
    jne check_eof_file2_only
check_eof_file2_only:
    cmpb $0, (%r14)
    je print_diff_eof
    jne after_check_eof
check_eof_file2_also:
    cmpb $0, (%r14)
    je end
    jne print_diff_eof


check__nl:
    cmpb $10, (%r13)
    je check_eof_file2_also
    jne check_eof_file2_only
check_nl_file2_only:
    cmpb $10, (%r14)
    jne after_check_nl
    #call print_diff
    incq %r14
    incq %r9
    movq %r9, %r12
    call go_to_end_of_line_file1
    jmp compare_line
check_nl_file2_also:
    cmpb $10, (%r14)
    jne nl_only_file1
    incq %r13
    incq %r14
    incq %r8
    incq %r9
    movq %r8, %r11
    movq %r9, %r12
    jmp compare_line
nl_only_file1:
    #call print_diff
    incq %r13
    incq %r8
    movq %r8, %r11
    call go_to_end_of_line_file2
    jmp after_check_nl


print_diff:
    movq %r11, (current_possition_file1)
    movq %r12, (current_possition_file2)

    movq $printf_string_format, %rdi
    movq $file1, %rsi
    call printf
    movq $printf_string_format_nl, %rdi
    #movq %r13rsi, %
    movq $file1_buffer, %rsi
    movq (current_possition_file1), %r11
    addq %r11, %rsi
    call printf

    movq $printf_string_format_nl, %rdi
    movq $line, %rsi
    call printf

    movq $printf_string_format, %rdi
    movq $file2, %rsi
    call printf
    movq $printf_string_format_nl, %rdi
    movq $file2_buffer, %rsi
    movq (current_possition_file1), %r12
    addq %r12, %rsi
    call printf
    ret

print_diff_eof:
    movq %r11, (current_possition_file1)
    movq %r12, (current_possition_file2)

    movq $printf_string_format, %rdi
    movq $file1, %rsi
    call printf
    movq $printf_string_format_nl, %rdi
    #movq %r13rsi, %
    movq $file1_buffer, %rsi
    movq (current_possition_file1), %r11
    addq %r11, %rsi
    call printf

    movq $printf_string_format_nl, %rdi
    movq $line, %rsi
    call printf

    movq $printf_string_format, %rdi
    movq $file2, %rsi
    call printf
    movq $printf_string_format_nl, %rdi
    movq $file2_buffer, %rsi
    movq (current_possition_file1), %r12
    addq %r12, %rsi
    call printf
    jmp end

go_to_end_of_line_file1:
    incq %r13
    incq %r8
    cmpb $10, (%r13)
    jne go_to_end_of_line_file1
    incq %r13
    incq %r8
    movq %r8, %r11
    ret
go_to_end_of_line_file2:
    incq %r14
    incq %r9
    cmpb $10, (%r14)
    jne go_to_end_of_line_file2
    incq %r14
    incq %r9
    movq %r9, %r12
    ret


print_line_file1:
    #print > 
    movq $printf_string_format, %rdi
    movq $file1, %rsi
    call printf
    #print line
end_print_line_file1:
