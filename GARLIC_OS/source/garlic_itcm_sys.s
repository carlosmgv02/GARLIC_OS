@;==============================================================================
@;
@;	"garlic_itcm_sys.s":	código de las rutinas de soporte al sistema.
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2

	.global _gs_num2str_dec
	@; _gs_num2str_dec: permite convertir un número natural de 32 bits a su
	@;					representación en decimal, dentro de un string acabado
	@;					en cero ('\0');
	@;Parámetros
	@; R0: char * numstr,
	@; R1: unsigned int length,
	@; R2: unsigned int num
	@;Resultado
	@; R0: 0 si no hay problema, !=0 si el número no cabe en el string
_gs_num2str_dec:
	push {r1-r8, lr}
	cmp r1, #1
	bhi .Ln1s_cont1			@; verificar si hay espacio para centinela + 1 dígito
	mov r0, #-1
	b .Ln1s_fin				@; retornar con código de error en R0
.Ln1s_cont1:
	mov r6, r0				@; R6 = puntero a string de resultado
	mov r7, r1				@; R7 = índice carácter (inicialmente es la longitud del string)
	mov r8, r2				@; R8 = número a transcribir
	mov r3, #0
	sub r7, #1
	strb r3, [r6, r7]		@; guardar final de string (0) en última posición
.Ln1s_while:	
	cmp r7, #0				@; repetir mientras quede espacio en el string
	beq .Ln1s_cont2
	sub sp, #8				@; reservar espacio en la pila para resultados
	mov r0, r8				@; pasar numerador por valor
	mov r1, #10				@; pasar denominador por valor
	mov r2, sp				@; pasar dirección para albergar el cociente
	add r3, sp, #4			@; pasar dirección para albergar el resto
	bl _ga_divmod
	pop {r4-r5}				@; R4 = cociente, R5 = resto
	add r5, #48				@; añadir base de códigos ASCII para dígitos numéricos
	sub r7, #1
	strb r5, [r6, r7]		@; almacenar código ASCII en vector
	mov r8, r4				@; actualizar valor del número a convertir
	cmp r8, #0				@; repetir mientras el número sea diferente de 0
	bne .Ln1s_while
.Ln1s_pad:
	cmp r7, #0				@; bucle para llenar de espacios en blanco la
	beq .Ln1s_cont2			@; parte restante del inicio del string
	mov r3, #' '
	sub r7, #1
	strb r3, [r6, r7]		@; almacenar código ASCII ' ' en vector
	b .Ln1s_pad
.Ln1s_cont2:
	mov r0, r8				@; esto indicará si el numero se ha podido codificar
.Ln1s_fin:					@; completamente en el string (si R0 = 0)
	pop {r1-r8, pc}


.global _gs_num2str_dec64
    @; _gs_num2str_dec64: convierte un número de 64 bits a su representación en decimal en un string
    @;Parámetros
    @; R0: char * numstr,
    @; R1: unsigned int length,
    @; R2: unsigned long long * num (puntero al número de 64 bits)
    @;Resultado
    @; R0: 0 si no hay problema, !=0 si el número no cabe en el string
_gs_num2str_dec64:
    push {r1-r8, lr}
    cmp r1, #1
    bhi .L64s_cont1
    mov r0, #-1
    b .L64s_fin

.L64s_cont1:
    mov r6, r0             @; R6 = puntero a string de resultado
    mov r7, r1             @; R7 = longitud del string
    ldrd r8, r9, [r2]      @; R8:R9 = número de 64 bits a transcribir (se carga desde la dirección de memoria)
    mov r3, #0
    sub r7, #1
    strb r3, [r6, r7]      @; guardar final de string (0) en última posición

.L64s_while:
    cmp r7, #0            @; Verificar si hay espacio en el buffer.
    beq .L64s_cont2       @; Si no hay espacio, vamos a la siguiente parte.

    sub sp, sp, #16       @; Reservar espacio en la pila para los resultados de la división.
    mov r0, sp            @; Dirección para el numerador (long long).
    add r1, sp, #8        @; Dirección para el denominador (unsigned int).
    add r2, sp, #12       @; Dirección para el cociente (long long).
    add r3, sp, #20       @; Dirección para el resto (unsigned int).

    strd r8, r9, [r0]     @; Almacenamos el numerador en la pila.
    ldr r4, =10
    str r4, [r1]          @; Almacenamos el denominador en la pila.
    bl _ga_divmodL        @; Llamamos a la función que realiza la división.
    ldrd r8, r9, [r2]     @; Cargamos el cociente en r8:r9.
    ldr r6, [r3]          @; Cargamos el resto en r6.

    add r6, r6, #48       @; Convertir el resto a un dígito ASCII.
    sub r7, r7, #1        @; Decrementar el contador del buffer.
    strb r6, [r6, r7]     @; Almacenar el dígito ASCII en el string.

    orrs r10, r8, r9      @; Verificar si el cociente es cero.
    bne .L64s_while       @; Si no es cero, repetimos el bucle.

    add sp, sp, #16       @; Limpiar la pila.
    b .L64s_cont2         @; Continuar con el siguiente bloque de código.


.L64s_cont2:
mov r0, r8             @; Esto indicará si el número se ha podido codificar
					   @; completamente en el string (si R0 = 0).

.L64s_fin:
    pop {r1-r8, pc}        @; Restauramos los registros y retornamos


	.global _gs_num2str_hex
	@; _gs_num2str_hex: permite convertir un número natural de 32 bits a su
	@;					representación en hexadecimal, dentro de un string
	@;					acabado en cero ('\0');
	@;Parámetros
	@; R0: char * numstr,
	@; R1: unsigned int length,
	@; R2: unsigned int num
	@;Resultado
	@; R0: 0 si no hay problema, !=0 si el número no cabe en el string
_gs_num2str_hex:
	push {r1-r4, lr}
	cmp r1, #1
	bhi .Ln2s_cont1			@; verificar si hay espacio para centinela + 1 dígito
	mov r0, #-1
	b .Ln2s_fin				@; retornar con código de error en R0
.Ln2s_cont1:
	mov r3, #0
	sub r1, #1
	strb r3, [r0, r1]		@; guardar final de string (0) en última posición
.Ln2s_while:	
	cmp r1, #0				@; repetir mientras quede espacio en el string
	beq .Ln2s_cont2
	and r4, r2, #0x0F		@; obtener el dígito hexa de menos peso
	cmp r4, #10				@; si dígito hexa menor que 10, saltar a tratamiento
	blo .Ln2s_dec			@; de dígitos decimales
	add r4, #7				@; ajuste para letras 'A'-'F' (65 - 10 - 48)
.Ln2s_dec:
	add r4, #48				@; añadir base de códigos ASCII para números
	sub r1, #1
	strb r4, [r0, r1]		@; almacenar código ASCII en vector
	mov r2, r2, lsr #4		@; actualizar valor del número a convertir
	cmp r2, #0				@; repetir mientras el número sea diferente de 0
	bne .Ln2s_while
.Ln2s_pad:
	cmp r1, #0				@; bucle para llenar de ceros la
	beq .Ln2s_cont2			@; parte restante del inicio del string
	mov r3, #'0'
	sub r1, #1
	strb r3, [r0, r1]		@; almacenar código ASCII '0' en vector
	b .Ln2s_pad
.Ln2s_cont2:
	mov r0, r2				@; esto indicará si el numero se ha podido codificar
.Ln2s_fin:					@; completamente en el string (si R0 = 0)
	pop {r1-r4, pc}



	.global _gs_copiaMem
	@; Rutina para copiar un bloque de memoria desde una dirección fuente a 
	@; otra dirección destino, el número de bytes indicado:
	@;Parámetros:
	@; R0: dirección fuente (debe ser múltiplo de 4)
	@; R1: dirección destino (debe ser múltiplo de 4)
	@; R2: número de bytes a copiar
_gs_copiaMem:
	push {r0-r12, lr}
	and r11, r2, #3				@; R11 = contador de bytes residuales
	mov r2, r2, lsr #2			@; convierte num. bytes en num. words
    and  r12, r2, #7     		@; R12 = contador de words residuales
    movs r2, r2, lsr #3  		@; R2 = contador de bloques de 8 words
    beq  .LcopMem_reswords
.LcopMem_bloques:				@; copiar bloques de 8 words
    ldmia r0!, {r3-r10}   
    stmia r1!, {r3-r10}
    subs  r2, #1
    bne   .LcopMem_bloques
.LcopMem_reswords:				@; copiar los words residuales (entre 0 y 7)
    subs  r12, #1
    ldrcs r3, [r0], #4
    strcs r3, [r1], #4
    bcs   .LcopMem_reswords
.LcopMem_resbytes:				@; copiar los bytes residuales (entre 0 y 3)
    cmp r11, #0
	beq .LcopMem_fin
    ldrb r3, [r0], #1
    strb r3, [r1], #1
	sub  r11, #1
    b .LcopMem_resbytes
.LcopMem_fin:
    pop {r0-r12, pc}

.end

