﻿@;==============================================================================
@;
@;	"garlic_itcm_graf.s":	código de rutinas de soporte a la gestión de
@;							ventanas gráficas (versión 1.0)
@;
@;==============================================================================


NVENT	= 16				@; número de ventanas totales
PPART	= 4					@; número de ventanas horizontales o verticales
							@; (particiones de pantalla)
L2_PPART = 2				@; log base 2 de PPART

VCOLS	= 32				@; columnas y filas de cualquier ventana
VFILS	= 24
PCOLS	= VCOLS * PPART		@; número de columnas totales (en pantalla)
PFILS	= VFILS * PPART		@; número de filas totales (en pantalla)

WBUFS_LEN = 68				@; longitud de cada buffer de ventana (64+4)

.section .itcm,"ax",%progbits

	.arm
	.align 2


	.global _gg_escribirLinea
	@; Rutina para escribir toda una linea de caracteres almacenada en el
	@; buffer de la ventana especificada;
	@;Parámetros:
	@;	R0: ventana a actualizar (int v)
	@;	R1: fila actual (int f)
	@;	R2: número de caracteres a escribir (int n)
_gg_escribirLinea:
	push {r0-r9,lr}
		mov r5, r0
		bl _gg_calcVertice
		mov r6, #PCOLS
		mov r6, r6, lsl #1
		mla r9, r6, r1, r0			@; r0 = ptrMap2 + 2 * PCOLS * f

		ldr r3, =_gd_wbfs
		mov r4, #WBUFS_LEN 			@; r4 = WBUFS_LEN -> longitud de cada buffer de ventana
		mul r4, r5, r4 				@; r4 = WBUFS_LEN * v -> desplazamiento del buffer de la ventana
		add r4, r3
		add r4, #4 					@; accedemos al campo "pChars"
		mov r0, #0 					@; r0 = 0 -> 
		mov r1, #0 					@; r1 = 0 -> 
		mov r2, r2, lsl #1			@;porque cada baldosa ocupa 2 bytes
	
	.LSigCar:
		cmp r0, r2 					@; if (r0 >= r2) goto .LEnd
		beq .LEnd
		ldrh r5 , [r4, r0] 			@; r5 = pChars[r0]

		strh r5, [r9, r1] 			@; pFondo2[r1] = r6

		add r1, #2 					@; r1 += 2
		add r0, #2 					@; r0 += 1
		b .LSigCar
	.LEnd:
	pop {r0-r9,pc}


	.global _gg_desplazar
	@; Rutina para desplazar una posición hacia arriba todas las filas de la
	@; ventana (v), y borrar el contenido de la última fila
	@;Parámetros:
	@;	R0: ventana a desplazar (int v)
_gg_desplazar:
	push {r0-r5,lr}
		bl _gg_calcVertice 			@; Calculate the memory address of the upper corner
		mov r1, r0
		mov r2, #VCOLS
		mov r2, r2, lsl #1 			@; R2 = VCOLS * 2
		mov r3, #PCOLS 				@; R3 = PCOLS
		mov r3, r3, lsl #1 			@; R3 = PCOLS * 2
		mov r4, #0 
		mov r5, #VFILS 				@; R5 = VFILS
	.Lscroll:
		cmp r4, r5 					@; if(r4 == r5)
		beq .Ladjust 				@; then jump to .Ladjust
		add r0, r1, r3 				@; R6 = PrimeraPosi + PCOLS * 2
		bl _gs_copiaMem 			@; Call this routine to "shift" a row
		add r4, #1 					@; r4++
		mov r1, r0
		b .Lscroll
	.Ladjust:
		sub r1, r3 					@; Handle the last row
		mov r3, #0 
		mov r5, #VCOLS 				@; R5 = VCOLS
		mov r4, #0 
	.Lcopy:
		cmp r4, r5 					@; if(r4 == r5)
		beq .Lend 					@; then jump to .Lend
		mov r2, #0 
		strh r2, [r1, r4] 			@; Clear the last row
		add r3, #1 					@; r3++
		add r4, #2 					@; r4+=2
	.Lend:
		
	pop {r0-r5,pc}

	.global _gg_calcVertice
	@; Rutina para calcular la dirección de memoria de la esquina superior, ya que lo tendremos que usar en varias funciones de las de abajo
	@; R0: ventana a actualizar (int v)
_gg_calcVertice:
	push {r1-r3,lr}
		mov r1, r0, lsr #L2_PPART		@;R1 = v/PPART
		mov r2, #PPART 					@; R2 = PPART
		add r2, #-1 
		and r2, r0, r2  				@; R2 = v%PPART
		
		mov r3, #VFILS
		mul r1, r3, r1					@; R1 = VFILS * (v/PPART)
		mov r3, #PPART
		mla r1, r3, r1, r2				@; R1 = PPART * VFILS * (v/PPART) + v%PPART
		mov r3, #VCOLS
		mov r3, r3, lsl #1				@; R3 = VCOLS * 2

		mul r1, r3, r1					@; R1 = 2 * VCOLS * (PPART * VFILS * (v/PPART) + v%PPART)
		
		ldr r0, =ptrMap2				@; R0 = &ptrMap2
		ldr r0, [r0]					@; R0 = ptrMap2
		add r0, r1						@; R0 = ptrMap2 + 2 * VCOLS * (PPART * VFILS * (v/PPART) + v%PPART)
		
	pop {r1-r3,pc}

	.global _gg_escribirLineaTabla
		@; escribe los campos básicos de una linea de la tabla correspondiente al
		@; zócalo indicado por parámetro con el color especificado; los campos
		@; son: número de zócalo, PID, keyName y dirección inicial
		@;Parámetros:
		@;	R0 (z)		->	número de zócalo
		@;	R1 (color)	->	número de color (de 0 a 3)
_gg_escribirLineaTabla:
	push {r0-r7, lr}
		mov r2, #0x06200000		@; R2 = 0x06200000
		add r2, #256			@; R2 = R2 + (32 * 4 * 2)
		add r3, r2, r0, lsl #6	@; R3 = R2 + (32 * 4 * 2) * z
		mov r3, #64				@; R3 = 32 * 2
		mla r3, r3, r0, r2		@; R3 = R2 + (32 * 4 * 2) * z

		mov r2, #104
		mov r4, #128
		mla r2, r4, r1, r2		@; R2 = 104 + 128 * color

		mov r4, #0
		@;.....................
		strh r2, [r3, r4]		@; pFondo2[0] = R2
		add r4, #6
		@;.....................
		strh r2, [r3, r4]		@; pFondo2[6] = R2
		add r4, #10
		@;.....................
		strh r2, [r3, r4]		@; pFondo2[16] = R2
		add r4, #10
		@;.....................

		mov r5, r4				@; R5 = R4
		add r5, r3				@; R5 = R3 + R4
		mov r6, r2				@; R6 = 104 + 128 * color (Backup)

		@;.....................
		add r4, #18
		strh r2, [r3, r4]		@; pFondo2[34] = R2
		@;.....................
		add r4, #6
		strh r2, [r3, r4]		@; pFondo2[40] = R2
		@;.....................
		add r4, #4
		strh r2, [r3, r4]		@; pFondo2[44] = R2
		@;.....................
		add r4, #8
		strh r2, [r3, r4]		@; pFondo2[52] = R2
		@;.....................

		ldr r2, =_gd_pcbs		@; R3 = &pcbs
		mov r3, #24
		mla r2, r3, r0, r2		@; R3 = &pcbs + 24 * z
		mov r4, r0				@; R4 = z (Backup)
		add r4, #4				@; R4 = z + 1 indice (4B/int)
		mov r3, r1
		
		mov r7, r2
		@;.....................
		ldr r0, = _gd_strZoc	@; R1 = &strZoc
		mov r1, #3
		mov r2, r4
		sub r2, #4
		bl _gs_num2str_dec		@; Convertimos el número a una string	
		@;.....................
		ldr r0, = _gd_strZoc	@; R1 = &strZoc
		mov r1, r4				@; R1 = z + 4
		mov r2, #1				@; R2 = Columna inicial
		bl _gs_escribirStringSub @; Escribimos la string en la ventana
		@;.....................
		mov r2, r7				@; R0 = &pcbs + 24 * z
		ldr r1, [r2]
		cmp r4, #4
		beq .Lescribir
		cmp r1, #0
		beq .Lfin

	.Lescribir:
		ldr r0, =_gd_strPid		@; R0 = &strPid
		mov r2, r1				@; R2 = PID
		mov r1, #4
		bl _gs_num2str_dec @convertir el número decimal a string
		ldr r0, =_gd_strPid
		mov r1, r4				@; R1 = Fila inicial
		mov r2, #5
		bl _gs_escribirStringSub
		
		mov r0, r7				@; R0 = &pcbs + 24 * z
		add r0, #16
		mov r2, #9
		bl _gs_escribirStringSub
		strh r6, [r5]
	.Lfin:
	pop {r0-r7,pc}


	.global _gg_escribirCar
	@; escribe un carácter (baldosa) en la posición de la ventana indicada,
	@; con un color concreto;
	@;Parámetros:
	@;	R0 (vx)		->	coordenada x de ventana (0..31)
	@;	R1 (vy)		->	coordenada y de ventana (0..23)
	@;	R2 (car)	->	código del caràcter, como número de baldosa (0..127)
	@;	R3 (color)	->	número de color del texto (de 0 a 3)
	@; pila (vent)	->	número de ventana (de 0 a 15)
_gg_escribirCar:
	push {r0-r5,lr}
		mov r4, r0					@; R4 = vx(Backup)
		ldr r0, [sp, #28] 			@; Cargamos el número de ventana que viene almacenado en la pila
		bl _gg_calcVertice 			@; Llamamos a rutina auxiliar que calcula el primer vértice de la ventana
		mov r5, #PCOLS
		mov r5, r5, lsl #1			@; R5 = PCOLS * 2 -> para saltar de fila
		mla r0, r5, r1, r0 			@; R0 = r0 + 2 * PCOLS * r1
		mov r5, #2
		mla r0, r5, r4, r0 			@; R0 = r0 + 2 * vx
		mov r4, #128				@; Para calcular el color
		mla r5, r4, r3, r2 			@; R5 = 128 * color + car
		strh r5, [r0] 				@; Escribimos el carácter en la posición de memoria
	pop {r0-r5,pc}


	.global _gg_escribirMat
	@; escribe una matriz de 8x8 carácteres a partir de una posición de la
	@; ventana indicada, con un color concreto;
	@;Parámetros:
	@;	R0 (vx)		->	coordenada x inicial de ventana (0..31)
	@;	R1 (vy)		->	coordenada y inicial de ventana (0..23)
	@;	R2 (m)		->	puntero a matriz 8x8 de códigos ASCII (dirección)
	@;	R3 (color)	->	número de color del texto (de 0 a 3)
	@; pila	(vent)	->	número de ventana (de 0 a 15)
_gg_escribirMat:
	push {r0-r7,lr}
		mov r4, r0
		ldr r0, [sp, #36] 		@; Cargamos el número de ventana que viene almacenado en la pila
		bl _gg_calcVertice 		@; Llamamos a rutina auxiliar que calcula el primer vértice de la ventana

		mov r5, #PCOLS			@; R5 = PCOLS
		mov r5, r5, lsl #1		@; R5 = PCOLS * 2 -> para saltar de fila
		mla r0, r1, r5, r0		@; R0 = r0 + 2 * PCOLS * vy
		mov r5, #2
		mla r0, r5, r4, r0		@; R0 = r0 + 2 * vx
		mov r6, #0
		mov r7, #0
	.Lvy:
		cmp r7, #8 				@;if (r7 >= 8) goto .LFin
		beq .Lfinalizar
		mov r4, #0
	.Lvx:
		cmp r4, #16				@;if (r4 >= 16) goto .Ladjust
		beq .Lajustar
		ldrb r5, [r2, r6]		@; R5 = m[r6]
		cmp r5, #32				@;if (r5 < 32) goto .LnonWriteable
		blo .Lnoescribir
		sub r5, #32				@; R5 = r5 - 32
		mov r1, #128			@; R1 = 128 -> para calcular el color
		mla r5, r1, r3, r5		@; R5 = 128 * color + r5
		strh r5, [r0, r4] 		@; pFondo2[r4] = r5
	.Lnoescribir:
		add r4, #2
		add r6, #1
		b .Lvx					@;goto .Lvx

	.Lajustar:
		add r0, #PCOLS*2
		add r7, #1
		b .Lvy
	.Lfinalizar:

	pop {r0-r7,pc}



	.global _gg_rsiTIMER2
	@; Rutina de Servicio de Interrupción (RSI) para actualizar la representa-
	@; ción del PC actual.
_gg_rsiTIMER2:
	push {r0-r4,lr}
		ldr r0, =_gd_strPc          @; Carga la dirección de la cadena que representa el PC.
		mov r1, #9                  @; Configura la longitud para la conversión hexadecimal.
		ldr r3, =_gd_pcbs           @; Carga la dirección de la estructura de control de procesos.
		add r3, #4                  @; Ajusta el puntero al campo relevante en PCB. Hay que saltar un int.

		ldr r2, [r3]                @; Carga el valor del PC del proceso actual.
		bl _gs_num2str_hex          @; Convierte el valor del PC a hexadecimal.
		ldr r0, =_gd_strPc          @; Recarga la dirección de la cadena del PC.
		mov r1, #4                  @; Configura la posición inicial de fila para la escritura.
		mov r2, #14                 @; Configura la posición inicial de columna para la escritura.

		bl _gs_escribirStringSub    @; Escribe la cadena del PC en la pantalla.

		mov r4, #5                  @; Inicializa el contador para iterar sobre los PCBs.
		add r3, #24                 @; Avanza al siguiente PCB.

	.Lloop:
		cmp r4, #20                 @; Comprueba si ya se procesaron todos los PCBs.
		beq .Lfinish                @; Si se procesaron todos, finaliza la rutina.

		sub r3, #4                  @; Ajusta el puntero para cargar el estado del proceso.
		ldr r2, [r3]                @; Carga el estado del proceso.
		add r3, #4                  @; Reajusta el puntero al campo del PC en el PCB.
		cmp r2, #0                  @; Comprueba si el proceso está activo.
		beq .LborrarZocalo          @; Si el proceso no está activo, borra su representación.

		ldr r0, =_gd_strPc          @; Carga la dirección de la cadena del PC.
		mov r1, #9                  @; Configura la longitud para la conversión hexadecimal.
		ldr r2, [r3]                @; Carga el valor del PC del proceso actual.

		bl _gs_num2str_hex          @; Convierte el valor del PC a hexadecimal.

		ldr r0, =_gd_strPc          @; Recarga la dirección de la cadena del PC.
		mov r1, r4                  @; Configura la posición de fila basada en el contador.
		mov r2, #14                 @; Configura la posición de columna para la escritura.

		bl _gs_escribirStringSub    @; Escribe la cadena del PC en la pantalla.
		.Lnext:
		add r4, #1                  @; Incrementa el contador para el próximo PCB.
		add r3, #24                 @; Avanza al siguiente PCB.

		b .Lloop                    @; Vuelve al inicio del bucle para procesar el siguiente PCB.
	.LborrarZocalo:
	
		
		mov r0, #0x06200000			@; cargar subfondo
		mov r1, #64
		mla r0, r1, r4, r0			
		
		mov r1, #0
		
		@; Borrar PID
		mov r2, #8
		str r1, [r0, r2]			
		add r2, #4
		str r1, [r0, r2]
		
		@; Borrar Prog
		add r2, #6
		strh r1, [r0, r2]
		add r2, #2
		str r1, [r0, r2]			
		add r2, #4
		strh r1, [r0, r2]
		
		@; Borrar PCactual
		add r2, #4
		str r1, [r0, r2]
		add r2, #4
		str r1, [r0, r2]			
		add r2, #4
		str r1, [r0, r2]
		add r2, #4
		str r1, [r0, r2]

		@; Borrar Pi
		add r2, #6
		strh r1, [r0, r2]			
		add r2, #2
		strh r1, [r0, r2]
		
		@; Borrar E
		add r2, #4
		strh r1, [r0, r2]			
		
		@; Borrar Uso
		add r2, #4
		str r1, [r0, r2]
		add r2, #4
		strh r1, [r0, r2]			
	
		b .Lnext

	.Lfinish:

	pop {r0-r4,pc}
.end

