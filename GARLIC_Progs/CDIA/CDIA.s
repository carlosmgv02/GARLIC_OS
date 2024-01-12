	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"CDIA.c"
	.text
	.align	2
	.global	calcularAnosBisiestos
	.syntax unified
	.arm
	.fpu softvfp
	.type	calcularAnosBisiestos, %function
calcularAnosBisiestos:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	sub	sp, sp, #8
	str	r0, [sp, #4]
	ldr	r3, [sp, #4]
	add	r2, r3, #3
	cmp	r3, #0
	movlt	r3, r2
	movge	r3, r3
	asr	r3, r3, #2
	mov	r1, r3
	ldr	r3, [sp, #4]
	ldr	r2, .L3
	smull	r0, r2, r3, r2
	asr	r2, r2, #5
	asr	r3, r3, #31
	sub	r3, r3, r2
	add	r2, r1, r3
	ldr	r3, [sp, #4]
	ldr	r1, .L3
	smull	r0, r1, r3, r1
	asr	r1, r1, #7
	asr	r3, r3, #31
	sub	r3, r1, r3
	add	r3, r2, r3
	mov	r0, r3
	add	sp, sp, #8
	@ sp needed
	bx	lr
.L4:
	.align	2
.L3:
	.word	1374389535
	.size	calcularAnosBisiestos, .-calcularAnosBisiestos
	.section	.rodata
	.align	2
.LC0:
	.ascii	"%d- \000"
	.align	2
.LC1:
	.ascii	"%d days are %d years,\012\000"
	.align	2
.LC2:
	.ascii	"\011\011%d months and %L days\012\000"
	.align	2
.LC3:
	.ascii	"\012********************************\012\000"
	.align	2
.LC4:
	.ascii	"-Prueba long (L): %L\012\000"
	.align	2
.LC5:
	.ascii	"-Prueba long (l): %l\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 56
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #60
	str	r0, [sp, #4]
	mov	r3, #1
	str	r3, [sp, #52]
	mvn	r2, #1
	mvn	r3, #-2147483648
	strd	r2, [sp, #16]
	ldr	r3, [sp, #4]
	cmp	r3, #0
	blt	.L6
	ldr	r3, [sp, #4]
	cmp	r3, #3
	movlt	r3, r3
	movge	r3, #3
	b	.L7
.L6:
	mov	r3, #0
.L7:
	str	r3, [sp, #4]
	mov	r3, #0
	str	r3, [sp, #36]
	b	.L8
.L9:
	ldr	r2, [sp, #52]
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	str	r3, [sp, #52]
	ldr	r3, [sp, #36]
	add	r3, r3, #1
	str	r3, [sp, #36]
.L8:
	ldr	r3, [sp, #4]
	add	r2, r3, #2
	ldr	r3, [sp, #36]
	cmp	r2, r3
	bgt	.L9
	mov	r3, #1
	str	r3, [sp, #32]
	b	.L10
.L15:
	bl	GARLIC_random
	mov	r3, r0
	str	r3, [sp, #48]
	b	.L11
.L12:
	ldr	r3, [sp, #48]
	lsr	r3, r3, #1
	str	r3, [sp, #48]
.L11:
	ldr	r2, [sp, #48]
	ldr	r3, [sp, #52]
	cmp	r2, r3
	bhi	.L12
	ldr	r2, [sp, #48]
	ldr	r3, .L17
	umull	r1, r3, r2, r3
	sub	r2, r2, r3
	lsr	r2, r2, #1
	add	r3, r3, r2
	lsr	r3, r3, #8
	str	r3, [sp, #40]
	ldr	r1, [sp, #48]
	ldr	r3, .L17
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
	str	r2, [sp, #44]
	ldr	r0, [sp, #40]
	bl	calcularAnosBisiestos
	str	r0, [sp, #28]
	ldr	r2, [sp, #44]
	ldr	r3, [sp, #28]
	cmp	r2, r3
	blt	.L13
	ldr	r2, [sp, #44]
	ldr	r3, [sp, #28]
	sub	r3, r2, r3
	str	r3, [sp, #44]
	b	.L14
.L13:
	ldr	r3, [sp, #40]
	sub	r3, r3, #1
	str	r3, [sp, #40]
	ldr	r2, [sp, #28]
	ldr	r3, [sp, #44]
	sub	r3, r2, r3
	rsb	r3, r3, #364
	add	r3, r3, #1
	str	r3, [sp, #44]
.L14:
	ldr	r3, [sp, #44]
	ldr	r2, .L17+4
	smull	r1, r2, r3, r2
	add	r2, r2, r3
	asr	r2, r2, #4
	asr	r3, r3, #31
	sub	r3, r2, r3
	str	r3, [sp, #24]
	ldr	r2, [sp, #44]
	ldr	r3, .L17+4
	smull	r1, r3, r2, r3
	add	r3, r3, r2
	asr	r1, r3, #4
	asr	r3, r2, #31
	sub	r1, r1, r3
	mov	r3, r1
	lsl	r3, r3, #4
	sub	r3, r3, r1
	lsl	r3, r3, #1
	sub	r3, r2, r3
	str	r3, [sp, #44]
	ldr	r3, [sp, #44]
	mov	r2, r3
	asr	r3, r2, #31
	strd	r2, [sp, #8]
	ldr	r1, [sp, #32]
	ldr	r0, .L17+8
	bl	GARLIC_printf
	ldr	r2, [sp, #40]
	ldr	r1, [sp, #48]
	ldr	r0, .L17+12
	bl	GARLIC_printf
	add	r3, sp, #8
	mov	r2, r3
	ldr	r1, [sp, #24]
	ldr	r0, .L17+16
	bl	GARLIC_printf
	ldr	r3, [sp, #32]
	add	r3, r3, #1
	str	r3, [sp, #32]
.L10:
	ldr	r3, [sp, #32]
	cmp	r3, #20
	ble	.L15
	ldr	r0, .L17+20
	bl	GARLIC_printf
	add	r3, sp, #16
	mov	r1, r3
	ldr	r0, .L17+24
	bl	GARLIC_printf
	add	r3, sp, #16
	mov	r1, r3
	ldr	r0, .L17+28
	bl	GARLIC_printf
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #60
	@ sp needed
	ldr	pc, [sp], #4
.L18:
	.align	2
.L17:
	.word	1729753953
	.word	-2004318071
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	.LC5
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
