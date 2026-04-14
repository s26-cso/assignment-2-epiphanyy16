.globl main

.section .data
filename: .string "input.txt"
reading_mode: .string "r"
yes: .string "Yes\n"
no: .string "No\n"

.section .text
main:
    add sp, sp, -48 #create space on stack
    sd ra, 40(sp)
    sd s0, 32(sp)
    sd s1, 24(sp)
    sd s2, 16(sp)
    sd s3, 8(sp)
    sd s4, 0(sp) #saved return address and saved registers to be used on stack

    la a0, filename
    la a1, reading_mode #load address of filename to a0 and address of reading mode to a1 as arguments for fopen
    call fopen
    mv s0, a0 # move filepointer to s0 to save it for future use
 
    li a1, 0
    li a2, 2 
    call fseek #seeks end of file

    mv a0, s0
    call ftell # gives current cursor pos 
    add s1, a0, -1 # right ptr = file size - 1
    li s2, 0 #left ptr

    # checking if the last character is a \n
    blt s1, zero, printyes # empty file 
    mv a0, s0
    mv a1, s1
    li a2, 0
    call fseek
    
    mv a0, s0
    call fgetc
    li t0, 10 # ascii for newline '\n'
    bne a0, t0, loop # if !\n move to main loop else decrement right ptr
    add s1, s1, -1

loop:
    bge s2, s1, printyes # if left ptr >= right ptr then the input is a palindrome
    mv a0, s0
    mv a1, s2
    li a2, 0
    call fseek #fseek(fp, left, 0)

    mv a0, s0
    call fgetc
    mv s3, a0 #store left character in s3

    mv a0, s0
    mv a1, s1
    li a2, 0
    call fseek #set cursor to right ptr

    mv a0, s0
    call fgetc 
    mv s4, a0 #store right character in s4
    
    bne s3, s4, printno
    
    add s2, s2, 1 #increment leftptr
    add s1, s1, -1 #decrement rightptr
    j loop

printyes:
    la a0, yes
    call printf
    j cleanup

printno:
    la a0, no
    call printf

cleanup:
    mv a0, s0
    call fclose

done:
    ld ra, 40(sp)
    ld s0, 32(sp)
    ld s1, 24(sp)
    ld s2, 16(sp)
    ld s3, 8(sp)
    ld s4, 0(sp)
    add sp, sp, 48 #restore stack
    
    li a0, 0
    ret
    