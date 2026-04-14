.globl main
.section .data
fmt_space:   .string "%ld "   # format string for all but the last element
fmt_newline: .string "%ld\n"  # format string for the last element

.section .text
main:
    addi sp, sp, -80
    sd ra,  72(sp)
    sd s0,  64(sp)
    sd s1,  56(sp)
    sd s2,  48(sp)
    sd s3,  40(sp)
    sd s4,  32(sp)
    sd s5,  24(sp)
    sd s6,  16(sp)
    sd s7,   8(sp)
    sd s8,   0(sp)

    mv s0, a1           # s0 = argv (array of string pointers)
    mv s1, a0           # s1 = argc (includes the program name)
    addi s2, s1, -1     # s2 = n = number of actual array elements

    # allocate memory for the input array (n longs)
    slli a0, s2, 3
    jal ra, malloc
    mv s3, a0           # s3 = base address of arr[]

    # allocate memory for the result array (n longs)
    slli a0, s2, 3
    jal ra, malloc
    mv s4, a0           # s4 = base address of result[]

    # allocate memory for the monotonic stack (holds at most n indices)
    slli a0, s2, 3
    jal ra, malloc
    mv s7, a0           # s7 = base address of stack[]

    li s8, 1            # s8 = i = 1 (skip argv[0] which is the program name)

# parse: convert each argv string to a long and store in arr[]
parse_loop:
    bge s8, s1, parse_done      # exit when all arguments are consumed
    slli t1, s8, 3
    add  t2, s0, t1             # t2 = &argv[i]
    ld   a0, 0(t2)              # a0 = argv[i] (pointer to string)
    jal  ra, atoi               # convert string → integer; result in a0
    addi t3, s8, -1             # zero-based index into arr[]
    slli t3, t3, 3
    add  t3, s3, t3             # t3 = &arr[i-1]
    sd   a0, 0(t3)              # arr[i-1] = parsed value
    addi s8, s8, 1
    j    parse_loop
parse_done:

    li t0, 0                    # t0 = i = 0

# initialising result[] to -1
initialise_loop:
    bge  t0, s2, initialise_done
    slli t1, t0, 3
    add  t1, s4, t1             # t1 = &result[i]
    li   t2, -1
    sd   t2, 0(t1)              # result[i] = -1
    addi t0, t0, 1
    j    initialise_loop
initialise_done:

    li   s5, 0                  # s5 = stack size (empty)
    addi t0, s2, -1             # t0 = i = n-1

# main loop: monotonic stack to find next-greater-element position
# to do:
# 1. for each index i (right to left), pop all entries whose arr[top] <= arr[i]
# 2. if stack is non-empty, stack.top() is the NGE index
# 3. push i onto the stack
nge_loop:
    blt t0, zero, nge_done

    # pop while stack is non-empty AND arr[stack.top()] <= arr[i]
pop_loop:
    beq  s5, zero, pop_done     # stack empty → stop popping
    addi t1, s5, -1             # index of top element
    slli t1, t1, 3
    add  t1, s7, t1             # t1 = &stack[top]
    ld   t2, 0(t1)              # t2 = stack[top]  (an index into arr[])
    slli t3, t2, 3
    add  t3, s3, t3
    ld   t3, 0(t3)              # t3 = arr[stack[top]]
    slli t4, t0, 3
    add  t4, s3, t4
    ld   t4, 0(t4)              # t4 = arr[i]
    bgt  t3, t4, pop_done       # arr[stack[top]] > arr[i] → this is a candidate; stop
    addi s5, s5, -1             # pop: arr[stack[top]] <= arr[i]
    j    pop_loop
pop_done:

    # if the stack still has an entry, its top is the position of the NGE for i
    beq  s5, zero, push         # stack empty → result[i] stays -1
    addi t1, s5, -1             # peek at top without popping
    slli t1, t1, 3
    add  t1, s7, t1
    ld   t2, 0(t1)              # t2 = stack[top]
    slli t3, t0, 3
    add  t3, s4, t3             # t3 = &result[i]
    sd   t2, 0(t3)              # result[i] = position of next greater element

push:
    slli t1, s5, 3
    add  t1, s7, t1             # t1 = &stack[s5]
    sd   t0, 0(t1)              # push current index i
    addi s5, s5, 1              # increment stack size
    addi t0, t0, -1             # move to previous element
    j    nge_loop

nge_done:

    li s6, 0                    # s6 = i = 0

print_loop:
    bge  s6, s2, print_done
    slli t0, s6, 3
    add  t0, s4, t0
    ld   a1, 0(t0)              # a1 = result[i]
    addi t1, s6, 1
    bge  t1, s2, print_last     # last element gets a newline instead of a space
    la   a0, fmt_space
    jal  ra, printf
    j    print_next

print_last:
    la   a0, fmt_newline
    jal  ra, printf

print_next:
    addi s6, s6, 1
    j    print_loop

print_done:
    ld ra,  72(sp)
    ld s0,  64(sp)
    ld s1,  56(sp)
    ld s2,  48(sp)
    ld s3,  40(sp)
    ld s4,  32(sp)
    ld s5,  24(sp)
    ld s6,  16(sp)
    ld s7,   8(sp)
    ld s8,   0(sp)
    addi sp, sp, 80
    li   a0, 0
    ret
    