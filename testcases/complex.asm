
complex.elf:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <loop-0xc>:
    addi t0, zero, 0     # loop variable
   0:	00000293          	li	t0,0
    addi t1, zero, 10   # loop upper bound
   4:	00a00313          	li	t1,10
    addi t2, zero, 0     # sum
   8:	00000393          	li	t2,0

0000000c <loop>:
loop:
    addi t0, t0, 1
   c:	00128293          	addi	t0,t0,1
    add t2, t0, t2
  10:	007283b3          	add	t2,t0,t2
    beq t0, t1, next # i == 100?
  14:	00628463          	beq	t0,t1,1c <next>
    beq zero, zero, loop
  18:	fe000ae3          	beqz	zero,c <loop>

0000001c <next>:

next:   
    # store result
    lui t0, 0x80000  # base ram address
  1c:	800002b7          	lui	t0,0x80000
    sw t2, 0x100(t0)
  20:	1072a023          	sw	t2,256(t0) # 80000100 <__global_pointer$+0x7fffe870>

    lui t0, 0x10000  # serial address
  24:	100002b7          	lui	t0,0x10000

00000028 <.TESTW1>:
.TESTW1:
    lb t1, 5(t0)
  28:	00528303          	lb	t1,5(t0) # 10000005 <__global_pointer$+0xfffe775>
    andi t1, t1, 0x20
  2c:	02037313          	andi	t1,t1,32
    beq t1, zero, .TESTW1 
  30:	fe030ce3          	beqz	t1,28 <.TESTW1>
    # do not write when serial is in used

    addi a0, zero, 'd'
  34:	06400513          	li	a0,100
    sb a0, 0(t0)
  38:	00a28023          	sb	a0,0(t0)

0000003c <.TESTW2>:

.TESTW2:
    lb t1, 5(t0)
  3c:	00528303          	lb	t1,5(t0)
    andi t1, t1, 0x20
  40:	02037313          	andi	t1,t1,32
    beq t1, zero, .TESTW2
  44:	fe030ce3          	beqz	t1,3c <.TESTW2>

    addi a0, zero, 'o'
  48:	06f00513          	li	a0,111
    sb a0, 0(t0)
  4c:	00a28023          	sb	a0,0(t0)

00000050 <.TESTW3>:

.TESTW3:
    lb t1, 5(t0)
  50:	00528303          	lb	t1,5(t0)
    andi t1, t1, 0x20
  54:	02037313          	andi	t1,t1,32
    beq t1, zero, .TESTW3
  58:	fe030ce3          	beqz	t1,50 <.TESTW3>

    addi a0, zero, 'n'
  5c:	06e00513          	li	a0,110
    sb a0, 0(t0)
  60:	00a28023          	sb	a0,0(t0)

00000064 <.TESTW4>:

.TESTW4:
    lb t1, 5(t0)
  64:	00528303          	lb	t1,5(t0)
    andi t1, t1, 0x20
  68:	02037313          	andi	t1,t1,32
    beq t1, zero, .TESTW4
  6c:	fe030ce3          	beqz	t1,64 <.TESTW4>

    addi a0, zero, 'e'
  70:	06500513          	li	a0,101
    sb a0, 0(t0)
  74:	00a28023          	sb	a0,0(t0)

00000078 <.TESTW5>:

.TESTW5:
    lb t1, 5(t0)
  78:	00528303          	lb	t1,5(t0)
    andi t1, t1, 0x20
  7c:	02037313          	andi	t1,t1,32
    beq t1, zero, .TESTW5
  80:	fe030ce3          	beqz	t1,78 <.TESTW5>

    addi a0, zero, '!'
  84:	02100513          	li	a0,33
    sb a0, 0(t0)
  88:	00a28023          	sb	a0,0(t0)

0000008c <end>:

end:
  8c:	00000063          	beqz	zero,8c <end>
