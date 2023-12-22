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
	.ascii	"-Prueba int: %d %d\012\000"
	.align	2
.LC1:
	.ascii	"-Prueba long: %L buuuuum\012\000"
	.align	2
.LC2:
	.ascii	"-- Programa CDIA - PID (%d) --\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #28
	str	r0, [sp, #4]
	mov	r3, #1
	str	r3, [sp, #20]
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
	mvn	r2, #1
	mvn	r3, #-2147483648
	strd	r2, [sp, #8]
	ldr	r2, .L7
	mov	r1, #123
	ldr	r0, .L7+4
	bl	GARLIC_printf
	add	r3, sp, #8
	mov	r1, r3
	ldr	r0, .L7+8
	bl	GARLIC_printf
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L7+12
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [sp, #16]
	b	.L4
.L5:
	ldr	r2, [sp, #20]
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	str	r3, [sp, #20]
	ldr	r3, [sp, #16]
	add	r3, r3, #1
	str	r3, [sp, #16]
.L4:
	ldr	r3, [sp, #4]
	add	r2, r3, #2
	ldr	r3, [sp, #16]
	cmp	r2, r3
	bgt	.L5
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #28
	@ sp needed
	ldr	pc, [sp], #4
.L8:
	.align	2
.L7:
	.word	543
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
