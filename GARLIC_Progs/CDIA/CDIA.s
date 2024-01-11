	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"CDIA.c"
	.section	.rodata
	.align	2
.LC0:
	.ascii	"-- Programa CDIA - PID (%d) --\012\000"
	.align	2
.LC1:
	.ascii	"%d- \000"
	.align	2
.LC2:
	.ascii	"%d days are %d years,\012\000"
	.align	2
.LC3:
	.ascii	"\011\011%d months & %d days\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 48
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #52
	str	r0, [sp, #4]
	mov	r3, #1
	str	r3, [sp, #44]
	ldr	r3, [sp, #4]
	cmp	r3, #0
	blt	.L2
	ldr	r3, [sp, #4]
	cmp	r3, #3
	movlt	r3, r3
	movge	r3, #3
	b	.L3
.L2:
	mov	r3, #0
.L3:
	str	r3, [sp, #4]
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L11
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [sp, #36]
	b	.L4
.L5:
	ldr	r2, [sp, #44]
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	str	r3, [sp, #44]
	ldr	r3, [sp, #36]
	add	r3, r3, #1
	str	r3, [sp, #36]
.L4:
	ldr	r3, [sp, #4]
	add	r2, r3, #2
	ldr	r3, [sp, #36]
	cmp	r2, r3
	bgt	.L5
	mov	r3, #1
	str	r3, [sp, #32]
	b	.L6
.L9:
	bl	GARLIC_random
	mov	r3, r0
	str	r3, [sp, #40]
	b	.L7
.L8:
	ldr	r3, [sp, #40]
	lsr	r3, r3, #1
	str	r3, [sp, #40]
.L7:
	ldr	r2, [sp, #40]
	ldr	r3, [sp, #44]
	cmp	r2, r3
	bhi	.L8
	ldr	r2, [sp, #40]
	ldr	r3, .L11+4
	umull	r1, r3, r2, r3
	sub	r2, r2, r3
	lsr	r2, r2, #1
	add	r3, r3, r2
	lsr	r3, r3, #8
	str	r3, [sp, #28]
	ldr	r1, [sp, #40]
	ldr	r3, .L11+4
	umull	r2, r3, r1, r3
	sub	r2, r1, r3
	lsr	r2, r2, #1
	add	r3, r3, r2
	lsr	r2, r3, #8
	mov	r3, r2
	lsl	r3, r3, #3
	add	r3, r3, r2
	lsl	r3, r3, #3
	add	r3, r3, r2
	lsl	r2, r3, #2
	add	r3, r3, r2
	sub	r2, r1, r3
	ldr	r3, .L11+8
	umull	r1, r3, r2, r3
	lsr	r3, r3, #4
	str	r3, [sp, #24]
	ldr	r1, [sp, #40]
	ldr	r3, .L11+4
	umull	r2, r3, r1, r3
	sub	r2, r1, r3
	lsr	r2, r2, #1
	add	r3, r3, r2
	lsr	r2, r3, #8
	mov	r3, r2
	lsl	r3, r3, #3
	add	r3, r3, r2
	lsl	r3, r3, #3
	add	r3, r3, r2
	lsl	r2, r3, #2
	add	r3, r3, r2
	sub	r2, r1, r3
	ldr	r3, .L11+8
	umull	r1, r3, r2, r3
	lsr	r1, r3, #4
	mov	r3, r1
	lsl	r3, r3, #4
	sub	r3, r3, r1
	lsl	r3, r3, #1
	sub	r1, r2, r3
	str	r1, [sp, #20]
	ldr	r1, [sp, #32]
	ldr	r0, .L11+12
	bl	GARLIC_printf
	ldr	r2, [sp, #28]
	ldr	r1, [sp, #40]
	ldr	r0, .L11+16
	bl	GARLIC_printf
	ldr	r2, [sp, #20]
	ldr	r1, [sp, #24]
	ldr	r0, .L11+20
	bl	GARLIC_printf
	ldr	r3, [sp, #32]
	add	r3, r3, #1
	str	r3, [sp, #32]
.L6:
	ldr	r3, [sp, #32]
	cmp	r3, #20
	ble	.L9
	mvn	r2, #0
	mvn	r3, #-2147483648
	strd	r2, [sp, #8]
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #52
	@ sp needed
	ldr	pc, [sp], #4
.L12:
	.align	2
.L11:
	.word	.LC0
	.word	1729753953
	.word	-2004318071
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
