	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"POT2.c"
	.section	.rodata
	.align	2
.LC0:
	.ascii	"tamano lista %d \012\000"
	.align	2
.LC1:
	.ascii	"rango superior %d \012\000"
	.align	2
.LC2:
	.ascii	"num aleatorio %d \012\000"
	.align	2
.LC3:
	.ascii	"contador potencias %d \012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 40
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #44
	str	r0, [sp, #4]
	ldr	r3, [sp, #4]
	add	r3, r3, #4
	mov	r2, #1
	lsl	r3, r2, r3
	str	r3, [sp, #20]
	mov	r3, #1
	str	r3, [sp, #36]
	mov	r3, #0
	str	r3, [sp, #32]
	b	.L2
.L3:
	ldr	r3, [sp, #4]
	add	r2, r3, #2
	ldr	r3, [sp, #36]
	mul	r3, r2, r3
	str	r3, [sp, #36]
	ldr	r3, [sp, #32]
	add	r3, r3, #1
	str	r3, [sp, #32]
.L2:
	ldr	r3, [sp, #32]
	cmp	r3, #2
	ble	.L3
	mov	r3, #0
	str	r3, [sp, #28]
	ldr	r1, [sp, #36]
	ldr	r0, .L8
	bl	GARLIC_printf
	ldr	r1, [sp, #20]
	ldr	r0, .L8+4
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [sp, #24]
	b	.L4
.L6:
	bl	GARLIC_random
	mov	r3, r0
	str	r3, [sp, #16]
	add	r3, sp, #8
	add	r2, sp, #12
	ldr	r1, [sp, #20]
	ldr	r0, [sp, #16]
	bl	GARLIC_divmod
	ldr	r3, [sp, #8]
	str	r3, [sp, #16]
	ldr	r3, [sp, #16]
	cmp	r3, #0
	beq	.L5
	ldr	r3, [sp, #16]
	sub	r2, r3, #1
	ldr	r3, [sp, #16]
	and	r3, r3, r2
	cmp	r3, #0
	bne	.L5
	ldr	r1, [sp, #16]
	ldr	r0, .L8+8
	bl	GARLIC_printf
	ldr	r3, [sp, #28]
	add	r3, r3, #1
	str	r3, [sp, #28]
.L5:
	ldr	r3, [sp, #24]
	add	r3, r3, #1
	str	r3, [sp, #24]
.L4:
	ldr	r2, [sp, #24]
	ldr	r3, [sp, #36]
	cmp	r2, r3
	blt	.L6
	ldr	r1, [sp, #28]
	ldr	r0, .L8+12
	bl	GARLIC_printf
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #44
	@ sp needed
	ldr	pc, [sp], #4
.L9:
	.align	2
.L8:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
