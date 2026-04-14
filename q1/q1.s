# .global makes a symbol visible to the linker
.global make_node
.global insert
.global get
.global getAtMost


# function 1: make_node 
# to do: 
# 1. malloc to get 24 bytes of heap memory (4 + 4 + 8 + 8) -> val at offset 0 -> null at offset 8 -> null at offset 16 -> return pointer

make_node:
    addi sp, sp, -16    # space for return address (malloc overwites ra) and value (a0 overwritten)
    sd ra, 8(sp)        # saved ra at sp+8
    sd a0, 0(sp)        # saved a0 at sp+0

    # calling malloc
    li a0, 24   # argument to malloc
    call malloc # a0 = pointer to fresh mem

    # restoring val
    ld   t0, 0(sp)        # t0 = og val
    ld   ra, 8(sp)        # restore return address
    addi sp, sp, 16

    sw   t0, 0(a0)        # Node->val = val (val put into the address a0 poinyts to)
    sd   zero, 8(a0)      # Node->left = NULL
    sd   zero, 16(a0)     # Node->right = NULL

    ret                   # a0 returned




# function 2: insert
# arguments: a0->root, a1->val
# ret val: a0->root

insert:
    # ra, saving whatever values were previously in s0, s1
    addi sp, sp, -24
    sd   ra, 16(sp)
    sd   s0, 8(sp)
    sd   s1, 0(sp)

    # adding root and val to s0, s1 because we're ab to overwrite a0, a1
    mv s0, a0
    mv s1, a1

    # if root isnt null:
    bne  s0, zero, insert_notnull

    # base case: if root == null : create node
    mv   a0, s1     # a0 is argument for makenode -> set a0 = val(s0)
    call make_node  # a0 = new node
    j    insert_done        

insert_notnull:
    # loading root->val to compare
    lw   t0, 0(s0)        # t0 = root->val  (lw bc type(val)=int)

    # if val<root : go left
    bge  s1, t0, insert_not_left    # if val >= root->val, skip left branch
    ld   a0, 8(s0)      # a0 = root->left
    mv   a1, s1         # a1 = val
    call insert         # a0 = insert(root->left, val)
    sd   a0, 8(s0)      # root->left = result
    mv   a0, s0         # return value = original root
    j    insert_done

insert_not_left:
    # if val > root->val: go right
    ble  s1, t0, insert_equal      # if val <= root->val it must be equal

    ld   a0, 16(s0)     # a0 = root->right
    mv   a1, s1         # a1 = val
    call insert         # a0 = insert(root->right, val)
    sd   a0, 16(s0)     # root->right = result
    mv   a0, s0         # return value = original root
    j    insert_done

insert_equal:
    # if val == root->val:  just return root
    mv   a0, s0

insert_done:
    # restoring everything and returning
    ld   ra, 16(sp)
    ld   s0, 8(sp)
    ld   s1, 0(sp)
    addi sp, sp, 24
    ret



# function 3: get
# arguments: a0(root), a1(val)
# ret val: a0->pointer to node with val, or NULL
# to do:
    # 1. if current == NULL: return NULL
    # 2. if current->val == val: return current
    # 3. if val < current->val: go left
    # 4. if val > current->val: go right

get:
get_loop:
    # if current == NULL, value not found, return NULL (a0 is already 0)
    beq  a0, zero, get_done

    lw   t0, 0(a0)          # t0 = current->val
    beq  a1, t0, get_done   # val == current->val -> found it, return a0

    blt  a1, t0, get_go_left    # val < current->val -> go left

    ld   a0, 16(a0)             # val > current->val -> go right, a0 = current->right
    j    get_loop

get_go_left:
    ld   a0, 8(a0)      # a0 = current->left
    j    get_loop

get_done:
    ret     # a0 = NULL or node that we found


# function 4: getAtMost
# arguments: a0->val (upper bound), a1->root
# ret val: a0->greatest value in tree <= val, or -1
# no prologue needed: no calls, no s registers used
# to do:
# 1. keep a "best so far" initialized to -1
# 2. if current->val == val: perfect match, return immediately
# 3. if current->val < val: valid candidate, update best, go right (something bigger might still be <= val)
# 4. if current->val > val: too big, go left
getAtMost:
    li   t1, -1                 # t1 = best answer so far
    mv   t2, a1                 # t2 = current node (starting at root)
    mv   t3, a0                 # t3 = upper bound val (save before a0 gets used as return)
getAtMost_loop:
    beq  t2, zero, getAtMost_done   # fell off tree -> return best
    lw   t0, 0(t2)                  # t0 = current->val
    beq  t0, t3, getAtMost_exact    # current->val == val -> perfect match
    bge  t0, t3, getAtMost_toolarge # current->val > val -> too big, go left
    # current->val < val -> valid candidate
    mv   t1, t0                 # best = current->val
    ld   t2, 16(t2)             # go right (might find something bigger but still <= val)
    j    getAtMost_loop
getAtMost_toolarge:
    ld   t2, 8(t2)              # go left
    j    getAtMost_loop
getAtMost_exact:
    mv   t1, t0                 # best = current->val (exact match, can't do better)
getAtMost_done:
    mv   a0, t1                 # return best
    ret

#######################################################################################################