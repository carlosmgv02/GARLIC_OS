	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"PRM1.c"
	.text
	.align	2
	.global	swap
	.syntax unified
	.arm
	.fpu softvfp
	.type	swap, %function
swap:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	sub	sp, sp, #16
	str	r0, [sp, #4]
	str	r1, [sp]
	ldr	r3, [sp, #4]
	ldrb	r3, [r3]
	strb	r3, [sp, #15]
	ldr	r3, [sp]
	ldrb	r2, [r3]	@ zero_extendqisi2
	ldr	r3, [sp, #4]
	strb	r2, [r3]
	ldr	r3, [sp]
	ldrb	r2, [sp, #15]
	strb	r2, [r3]
	nop
	add	sp, sp, #16
	@ sp needed
	bx	lr
	.size	swap, .-swap
	.section	.rodata
	.align	2
.LC0:
	.ascii	"%s\012\000"
	.text
	.align	2
	.global	permute
	.syntax unified
	.arm
	.fpu softvfp
	.type	permute, %function
permute:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #28
	str	r0, [sp, #12]
	str	r1, [sp, #8]
	str	r2, [sp, #4]
	ldr	r2, [sp, #8]
	ldr	r3, [sp, #4]
	cmp	r2, r3
	bne	.L3
	ldr	r1, [sp, #12]
	ldr	r0, .L8
	bl	GARLIC_printf
	b	.L7
.L3:
	ldr	r3, [sp, #8]
	str	r3, [sp, #20]
	b	.L5
.L6:
	ldr	r3, [sp, #8]
	ldr	r2, [sp, #12]
	add	r0, r2, r3
	ldr	r3, [sp, #20]
	ldr	r2, [sp, #12]
	add	r3, r2, r3
	mov	r1, r3
	bl	swap
	ldr	r3, [sp, #8]
	add	r3, r3, #1
	ldr	r2, [sp, #4]
	mov	r1, r3
	ldr	r0, [sp, #12]
	bl	permute
	ldr	r3, [sp, #8]
	ldr	r2, [sp, #12]
	add	r0, r2, r3
	ldr	r3, [sp, #20]
	ldr	r2, [sp, #12]
	add	r3, r2, r3
	mov	r1, r3
	bl	swap
	ldr	r3, [sp, #20]
	add	r3, r3, #1
	str	r3, [sp, #20]
.L5:
	ldr	r2, [sp, #20]
	ldr	r3, [sp, #4]
	cmp	r2, r3
	ble	.L6
.L7:
	nop
	add	sp, sp, #28
	@ sp needed
	ldr	pc, [sp], #4
.L9:
	.align	2
.L8:
	.word	.LC0
	.size	permute, .-permute
	.section	.rodata
	.align	2
.LC1:
	.ascii	"ABCDEF\000"
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
	ldr	r2, .L12
	add	r3, sp, #12
	ldm	r2, {r0, r1}
	str	r0, [r3]
	add	r3, r3, #4
	strh	r1, [r3]	@ movhi
	add	r3, r3, #2
	lsr	r2, r1, #16
	strb	r2, [r3]
	ldr	r3, [sp, #4]
	add	r3, r3, #3
	str	r3, [sp, #20]
	ldr	r3, [sp, #20]
	sub	r2, r3, #1
	add	r3, sp, #12
	mov	r1, #0
	mov	r0, r3
	bl	permute
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #28
	@ sp needed
	ldr	pc, [sp], #4
.L13:
	.align	2
.L12:
	.word	.LC1
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
