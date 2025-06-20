# bootloader for SoS
.option norvc
.section .data

.section .text.init
.global _start
_start:
    # Any hardware threads (hart) that are not bootstrapping
    # need to wait for an IPI
    csrr    t0, mhartid
    bnez    t0, 3f
    # SATP should be zero, but let's make sure
    csrw    satp, zero
.option push

.option norelax
    la      gp, _global_pointer
.option pop
    # The BSS section is expected to be zero
    la      a0, _bss_start
    la      a1, _bss_end
    bgeu    a0, a1, 2f
1:
    sd      zero, (a0)
    addi    a0, a0, 8
    bltu    a0, a1, 1b
2:

3:
    wfi
    j   3b
# Control registers, set the stack, mstatus, mepc,
# and mtvec to return to the main function.
# li        t5, 0xffff;
# csrw  medeleg, t5
# csrw  mideleg, t5
la      sp, _stack
# We use mret here so that the mstatus register
# is properly updated.
li      t0, (0b11 << 11) | (1 << 7) | (1 << 3)
csrw    mstatus, t0
la      t1, kmain
csrw    mepc, t1
la      t2, asm_trap_vector
csrw    mvtec, t2
li      t2, asm_trap_vector
csrw    mtvec, t2
li      t3, (1 << 3) | (1 << 7) | (1 << 11)
csrw    mie, t3
la      ra, 4f
mret
4:
    wfi
    j   4b