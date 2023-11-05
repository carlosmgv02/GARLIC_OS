@;==============================================================================
@;
@;	"garlic_itcm_api.s":	código de las rutinas del API de GARLIC 1.0
@;							(ver "GARLIC_API.h" para descripción de las
@;							 funciones correspondientes)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2


	.global _ga_pid
	@;Resultado:
	@; R0 = identificador del proceso actual
_ga_pid:
	push {r1, lr}
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + zócalo
	mov r0, r1, lsr #0x4	@; R0 = PID del proceso actual
	pop {r1, pc}


	.global _ga_random
	@;Resultado:
	@; R0 = valor aleatorio de 32 bits
_ga_random:
	push {r1-r5, lr}
	ldr r0, =_gd_seed
	ldr r1, [r0]			@; R1 = valor de semilla de números aleatorios
	ldr r2, =0x0019660D
	ldr r3, =0x3C6EF35F
	umull r4, r5, r1, r2	@; R5:R4 = _gd_seed * 0x19660D
	add r4, r3				@; R4 += 0x3C6EF35F
	str r4, [r0]			@; guarda la nueva semilla (R4)
	mov r0, r5				@; devuelve por R0 el valor aleatorio (R5)
	pop {r1-r5, pc}


	.global _ga_divmod
	@;Parámetros
	@; R0: unsigned int num,
	@; R1: unsigned int den,
	@; R2: unsigned int * quo,
	@; R3: unsigned int * mod
	@;Resultado
	@; R0: 0 si no hay problema, !=0 si hay error en la división
_ga_divmod:
	push {r4-r7, lr}
	cmp r1, #0				@; verificar si se está intentando dividir por cero
	bne .Ldiv_ini
	mov r0, #1				@; código de error
	b .Ldiv_fin2
.Ldiv_ini:
	mov r4, #0				@; R4 es el cociente (q)
	mov r5, #0				@; R5 es el resto (r)
	mov r6, #31				@; R6 es índice del bucle (de 31 a 0)
	mov r7, #0xff000000
.Ldiv_for1:
	tst r0, r7				@; comprobar si hay bits activos en una zona de 8
	bne .Ldiv_for2			@; bits del numerador, para evitar el rastreo bit a bit
	mov r7, r7, lsr #8
	sub r6, #8				@; 8 bits menos a buscar
	cmp r7, #0
	bne .Ldiv_for1
	b .Ldiv_fin1			@; caso especial (numerador = 0 -> q=0 y r=0)
.Ldiv_for2:
	mov r7, r0, lsr r6		@; R7 es variable de trabajo j;
	and r7, #1				@; j = bit i-ésimo del numerador; 
	mov r5, r5, lsl #1		@; r = r << 1;
	orr r5, r7				@; r = r | j;
	mov r4, r4, lsl #1		@; q = q << 1;
	cmp r5, r1
	blo .Ldiv_cont			@; si (r >= divisor), activar bit en cociente
	sub r5, r1				@; r = r - divisor;
	orr r4, #1				@; q = q | 1;
 .Ldiv_cont:
	sub r6, #1				@; decrementar índice del bucle
	cmp r6, #0
	bge .Ldiv_for2			@; bucle for-2, mientras i >= 0
.Ldiv_fin1:
	str r4, [r2]
	str r5, [r3]			@; guardar resultados en memoria (por referencia)
	mov r0, #0				@; código de OK
.Ldiv_fin2:
	pop {r4-r7, pc}


	.global _ga_divmodL
	@;Parámetros
	@; R0: long long * num,
	@; R1: unsigned int * den,
	@; R2: long long * quo,
	@; R3: unsigned int * mod
	@;Resultado
	@; R0: 0 si no hay problema, !=0 si hay error en la división
_ga_divmodL:
	push {r4-r6, lr}
	ldr r4, [r1]			@; R4 = denominador
	cmp r4, #0				@; verificar si se está intentando dividir por cero
	bne .LdivL_ini
	mov r0, #1				@; código de error
	b .LdivL_fin
.LdivL_ini:
	ldrd r0, [r0]			@; R1:R0 = numerador
	mov r5, r2				@; R5 apunta a quo
	mov r6, r3				@; R6 apunta a mod
	mov r2, r4
	mov r3, #0				@; R3:R2 = denominador
	bl __aeabi_ldivmod
	strd r0, [r5]
	str r2, [r6]			@; guardar resultados en memoria (por referencia)			
	mov r0, #0				@; código de OK
.LdivL_fin:
	pop {r4-r6, pc}


	.global _ga_printf
	@;Parámetros
	@; R0: char * format,
	@; R1: unsigned int val1 (opcional),
	@; R2: unsigned int val2 (opcional)
_ga_printf:
	push {r4, lr}
	ldr r4, =_gd_pidz		@; R4 = dirección _gd_pidz
	ldr r3, [r4]
	and r3, #0x3			@; R3 = ventana de salida (zócalo actual MOD 4)
	bl _gp_WaitForVBlank
	push {r12}
	bl printf				@; llamada de prueba
	pop {r12}
	pop {r4, pc}
	
	.global _ga_nice
	@;Parámetros
	@; R0: unsigned char n
_ga_nice:
	push {r1-r4, lr}
	
	ldr r1, =_gd_pcbs		@; R1 = dirección _gd_pcbs
	ldr r2, =_gd_pidz		@; R2 = dirección _gd_pidz
	ldr r3, [r2]			@; R3 = [_gd_pidz]
	and r3, r3, #0xf		@; R3 = num zocalo
	add r1, r3, lsl #5		@; R1 = _gd_pcbs[z]
	mov r4, #4				@; Guardar 4 para restar luego 4 - r0
	sub r4, r0				@; Restar 4 - r0
	ldr r3, [r1, #24]		@; R3 = maxQuantum
	str r4, [r1, #24]		@; Guardar la resta en el campo maxQuantum
	str r4, [r1, #28]		@; Guardar la resta en el campo quantumRemaining
	
	ldr r1, =_gd_totalQuantum
	ldr r2, [r1]			@; Cargar totalQuantum
	sub r2, r3				@; Restar totalQuantum menos maxQuantum de antes
	add r2, r4				@; Añadir al resultado de la resta el quantum actual
	str r2, [r1]			@; Guardar totalQuantum
	
	pop {r1-r4, pc}


.end

