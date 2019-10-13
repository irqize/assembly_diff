.text   # predefined strings
    line: .asciz "\n---\n"
    file1: .asciz "\n< "
    file2: .asciz "> "
    newline2: .asciz "\n"
    string_output: .asciz "%s"
    string_output_nl: .asciz "%s\n"



# reserved space for file descriptor
.lcomm fd, 1
.lcomm file1_name_address, 8
.lcomm file2_name_address, 8
# reserved space for files contents
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




# linux syscalls
.equ sys_read, 0
.equ sys_write, 1
.equ sys_open, 2
.equ sys_close, 3
.equ sys_exit, 60

.global main
main:
######################## INPUT PART START ########################
    pushq %rbp      # CREATE NEW STACK FRAME
    movq %rsp, %rbp # CREATE NEW STACK FRAME

    # copy address of the first one to the variable
	movq	%rsi, %rax
    addq    $8, %rax  # first argument is actually the second one because the first one is executable name
	movq	(%rax), %rax
	movq	%rax, (file1_name_address) # save firsts's argument address to a variable
    # copy address of the second one to the variable
    movq	%rsi, %rax
    addq    $16, %rax # address of the second argument
    movq	(%rax), %rax
	movq	%rax, (file2_name_address) # save second's argument address to a variable

    # open and save to memory first file
    movq $sys_open, %rax
    movq (file1_name_address), %rdi # address of first file
    movq $0, %rsi # open mode : read only
    syscall 

    movq %rax, (fd) # save file descriptor to memory

    movq $sys_read, %rax # read file from file descriptor and save it to the memory
    movq (fd), %rdi
    movq $file1_buffer, %rsi # file1_buffer is where we will store our file
    movq $1024, %rdx # we set max. file size to 1KB
    syscall 
    
    movq $sys_close, %rax # close the file
    movq $fd, %rdi
    syscall 
    ####################################
     
    # open and save to memory second file
    movq $sys_open, %rax
    movq (file2_name_address), %rdi # file adress to second argument
    movq $0, %rsi # open mode : read only
    syscall 

    movq %rax, (fd) # save file descriptor to memory

    movq $sys_read, %rax # read file from file descriptor and save it to the memory
    movq (fd), %rdi
    movq $file2_buffer, %rsi # file2_buffer is where we will store our file
    movq $1024, %rdx # we set max. file size to 1KB
    syscall 
    
    movq $sys_close, %rax # close the file
    movq $fd, %rdi
    syscall 
    ####################################
######################## INPUT PART END ########################

    # we need to use both registers and memory, because we need to make calculations on these address and in meanwhile they will be used to print stuff
    movq $file1_buffer, %r13 # r13 registry will store address to currently compared char of file1
    movq $file2_buffer, %r14 # r14 registry will store address to currently compared char of file2
    movq $file1_buffer, (current_character_address_file1)
    movq $file2_buffer, (current_character_address_file2)


    movq $1, %r8 # r8 registry will be storing current length of line1
    movq $1, %r9 # r9 registry will be storing current length of line2
    movq $1, (length_line_file1)
    movq $1, (length_line_file2)

    movq $file1_buffer, %r11 # r11 registry will be storing position of current line starting in file1
    movq $file2_buffer, %r12 # r12 registry will be storing position of current line starting in file1
    movq $file1_buffer, (current_line_address_file1)
    movq $file2_buffer, (current_line_address_file2)



    jmp compare_files # jump to our main loop
after_compare_files:
    
    movq %rbp, %rsp #
    popq %rbp       # RESTORE OLD STACK FRAME
end:
    movq $sys_exit, %rax # CALL SYSTEM EXIT
    movq $0, %rdi
    syscall



######################## MAIN LOOP START ########################
compare_files:
    jmp check_eof # check if one of the files has already ended
after_check_no_eof:
    jmp check_nl # check if one of the files goes into new line
after_check_no_nl:
    movb (%r13), %al # copy one character to the one byte register 
    movb (%r14), %bl # copy one character to the one byte register

    incq %r13 # go to the next character
    incq %r14 # go to the next character

    incq %r8 # increase line length
    incq %r9 # increase line length

    cmpb  %al, %bl # compare two charachters 
    je compare_files # if equal then iterate the loop -> compare next character

    # characters not equal -> iterate to end of the lines in both files
    call go_to_end_of_line_file1
    call go_to_end_of_line_file2
after_check_nl: # we continue here if there is new line in one of the files
    decq %r8 # decrease the line length so we dont print unnecessary \n
    decq %r9 # decrease the line length so we dont print unnecessary \n
    call print_diff # print the different lines

    # start new line, restore the registers
    movq $1, %r8
    movq $1, %r9
    movq %r13, %r11
    movq %r14, %r12

    jmp compare_files # if the differences handled, let's go to the next one, next loop iteration
######################## MAIN LOOP END ########################


######################## SPECIAL EVENT CHECKERS START ########################
check_eof:
    cmpb $0, (%r13) # check if current character of file1 is null
    je check_eof_file2_also
    jne check_eof_file2_only
check_eof_file2_only:
    cmpb $0, (%r14) # check if current character of file2 is null
    jne after_check_no_eof # both files didn't end
    je print_eof # only second file ended -> print the differences
check_eof_file2_also:
    cmpb $0, (%r14) # check if current character of file2 is null
    je end # if both of the files ended -> end the program
    jne print_eof # only first file ended -> print the differences


check_nl:
    cmpb $10, (%r13) # check if current character of file1 is \n
    je check_nl_file2_also
    jne check_nl_file2_only
check_nl_file2_only:
    cmpb $10, (%r14) # check if current character of file2 is \n
    jne after_check_no_nl
    call go_to_end_of_line_file1
    incq %r14 # align strings to the first character after \n
    jmp after_check_nl
check_nl_file2_also:
    cmpb $10, (%r14) # check if current character of file2 is \n
    je both_nl
    call go_to_end_of_line_file2
    incq %r13 # align strings to the first character after \n
    jmp after_check_nl
both_nl: # both lines ended, just go to the next one
    incq %r13
    incq %r14
    movq $1, %r8 
    movq $1, %r9
    movq %r13, %r11
    movq %r14, %r12
    jmp compare_files
######################## SPECIAL EVENT CHECKERS END ########################


######################## PRINTERS START ########################
# print differences in case that one file ended before the second one
print_eof:
    # save current state from registers to variables
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


# print differences in case there is \n  before there is in the second one
print_diff:
    # save current state from registers to variables
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
    movq $3, %rdx
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
    # restore current state from variables to registers
    movq (length_line_file1), %r8
    movq (length_line_file2), %r9
    movq (current_line_address_file1), %r11
    movq (current_line_address_file2), %r12
    movq (current_character_address_file1), %r13
    movq (current_character_address_file2), %r14
    ret
######################## PRINTERS END ########################

######################## ITERATORS START ########################
go_to_end_of_line_file1: # iterate over the current line of the first file to the next one
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





go_to_end_of_line_file2: # iterate over the current line of the second file to the next one
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
######################## ITERATORS END ########################
