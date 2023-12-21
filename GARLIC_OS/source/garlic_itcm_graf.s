@;==============================================================================
@;
@;	"garlic_itcm_graf.s":	código de rutinas de soporte a la gestión de
@;							ventanas gráficas (versión 1.0)
@;
@;==============================================================================

NVENT	= 4					@; número de ventanas totales
PPART	= 2					@; número de ventanas horizontales o verticales
							@; (particiones de pantalla)
L2_PPART = 1				@; log base 2 de PPART

VCOLS	= 32				@; columnas y filas de cualquier ventana
VFILS	= 24
PCOLS	= VCOLS * PPART		@; número de columnas totales (en pantalla)
PFILS	= VFILS * PPART		@; número de filas totales (en pantalla)

WBUFS_LEN = 36				@; longitud de cada buffer de ventana (32+4)

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
		mov r3, #PPART @; r3 = PPART -> número de particiones
		mov r4, #VFILS @; r4 = VFILS -> número de filas/ventana
		mov r5, #PPART @; r5 = PPART -> número de particiones
		add r5, #-1 @; r5 = PPART - 1 -> queremos trabajar con índices de 0 a PPART - 1
		and r5, r0, r5 @; r5 = v & (PPART - 1) -> índice de la partición
		lsr r6, r0, #L2_PPART @; r6 = v / L2_PPART
		mul r7, r4, r6 @; r7 = VFILS * (v / L2_PPART) -> calculamos el desplazamiento de la ventana

		mla r7, r3, r7, r5 @; 
		mla r7, r3, r1, r7 @; 
		mov r8, #VCOLS @; r8 = VCOLS -> número de columnas/ventana
		mov r8, r8, lsl #1 @; r8 = VCOLS * 2 -> número de bytes/ventana
		mul r7, r8, r7 @; r7 = VCOLS * 2 * (VFILS * (v / L2_PPART) + (v & (PPART - 1)) + f)

		ldr r9, =ptrMap2
		ldr r9, [r9] @; r9 = ptrMap2 -> puntero a la tabla de mapeo de ventanas
		add r9, r7 @; dirección base del fondo 2 + desplazamiento de la ventana

		ldr r3, =_gd_wbfs
		mov r4, #WBUFS_LEN @; r4 = WBUFS_LEN -> longitud de cada buffer de ventana
		mul r4, r0, r4 @; r4 = WBUFS_LEN * v -> desplazamiento del buffer de la ventana
		add r4, r3
		add r4, #4 @; accedemos al campo "pChars"
		mov r0, #0 @; r0 = 0 -> 
		mov r1, #0 @; r1 = 0 -> 

	.LSigCar:
		cmp r0, r2 @; if (r0 >= r2) goto .LEnd
		beq .LEnd
		ldrb r5 , [r4, r0] @; r5 = pChars[r0]
		sub r5, #32 @; Convertimos el código ASCII a índice de la tabla de mapeo
		mov r6, r1
		add r6, r9
		strh r5, [r6] @; pFondo2[r1] = r6

		add r1, #2 @; r1 += 2
		add r0, #1 @; r0 += 1
		b .LSigCar
	.LEnd:
	pop {r0-r9,pc}


	.global _gg_desplazar
	@; Rutina para desplazar una posición hacia arriba todas las filas de la
	@; ventana (v), y borrar el contenido de la última fila
	@;Parámetros:
	@;	R0: ventana a desplazar (int v)
_gg_desplazar:
	push {r0-r7, lr}
		and r1, r0, #L2_PPART @; Obtenemos el índice de la partición
		lsr r2, r0, #L2_PPART @; Obtenemos el índice de la ventana
		mov r3, #VFILS @; r3 = VFILS -> número de filas/ventana
		mul r3, r2, r3 @; r3 = VFILS * (v & (PPART - 1)) = desplazamiento de la ventana
		mov r4, #VCOLS @; r4 = VCOLS -> número de columnas/ventana
		mov r4, r4, lsl #1 @; r4 = VCOLS * 2 -> número de bytes/ventana
		mov r5, #PPART @; r5 = PPART -> número de particiones
		mla r3, r5, r3, r1 @; r3 = VCOLS * 2 * (VFILS * (v & (PPART - 1)) + (v / L2_PPART))

		mul r3, r4, r3 @; r3 = VCOLS * 2 * (VFILS * (v & (PPART - 1)) + (v / L2_PPART))
		mov r4, #PCOLS @; r4 = PCOLS -> número de columnas/pantalla
		mov r4, r4, lsl #1 @; r4 = PCOLS * 2 -> número de bytes/pantalla
		add r7, r3, r4 @; r3 = VCOLS * 2 * (VFILS * (v & (PPART - 1)) + (v / L2_PPART)) + PCOLS * 2
		ldr r4, =ptrMap2
		ldr r4, [r4] @; r3 = ptrMap2 -> puntero a la tabla de mapeo de ventanas

		add r5, r4, r7 @; r5 = ptrMap2 + VCOLS * 2 * (VFILS * (v & (PPART - 1)) + (v / L2_PPART)) + PCOLS * 2
		add r6, r4, r3 @; r6 = ptrMap2 + VCOLS * 2 * (VFILS * (v & (PPART - 1)) + (v / L2_PPART)) + PCOLS * 2 + VCOLS * 2 * (VFILS - 1)

		mov r7, #PCOLS
		mov r7, r7, lsl #1 @; r7 = PCOLS * 2 -> número de bytes/pantalla
		mov r0, #1

	.Lscroll:
		cmp r0, #VFILS @; if (r0 >= VFILS) goto .Lend
		beq .Lend
		mov r1, #0
		add r5, r7
		add r6, r7
	.Lcopy:
		cmp r1, #VCOLS*2
		addeq r0, #1
		beq .Lscroll

		ldrh r2, [r5, r1]
		mov r3, #VFILS
		sub r3, #1
		cmp r0, r3

		moveq r2, #0
		strh r2, [r6, r1]
		add r1, #2
		b .Lcopy
	
	.Lend:

	pop {r0-r7, pc}
.global _gg_escribirLineaTabla
	@; escribe los campos bÃ¡sicos de una linea de la tabla correspondiente al
	@; zÃ³calo indicado por parÃ¡metro con el color especificado; los campos
	@; son: nÃºmero de zÃ³calo, PID, keyName y direcciÃ³n inicial
	@;ParÃ¡metros:
	@;	R0 (z)		->	nÃºmero de zÃ³calo
	@;	R1 (color)	->	nÃºmero de color (de 0 a 3)
_gg_escribirLineaTabla:
	push {lr}


	pop {pc}


	.global _gg_escribirCar
	@; escribe un carÃ¡cter (baldosa) en la posiciÃ³n de la ventana indicada,
	@; con un color concreto;
	@;ParÃ¡metros:
	@;	R0 (vx)		->	coordenada x de ventana (0..31)
	@;	R1 (vy)		->	coordenada y de ventana (0..23)
	@;	R2 (car)	->	cÃ³digo del carÃ cter, como nÃºmero de baldosa (0..127)
	@;	R3 (color)	->	nÃºmero de color del texto (de 0 a 3)
	@; pila (vent)	->	nÃºmero de ventana (de 0 a 15)
_gg_escribirCar:
	push {lr}
	

	pop {pc}


	.global _gg_escribirMat
	@; escribe una matriz de 8x8 carÃ¡cteres a partir de una posiciÃ³n de la
	@; ventana indicada, con un color concreto;
	@;ParÃ¡metros:
	@;	R0 (vx)		->	coordenada x inicial de ventana (0..31)
	@;	R1 (vy)		->	coordenada y inicial de ventana (0..23)
	@;	R2 (m)		->	puntero a matriz 8x8 de cÃ³digos ASCII (direcciÃ³n)
	@;	R3 (color)	->	nÃºmero de color del texto (de 0 a 3)
	@; pila	(vent)	->	nÃºmero de ventana (de 0 a 15)
_gg_escribirMat:
	push {lr}
	

	pop {pc}



	.global _gg_rsiTIMER2
	@; Rutina de Servicio de InterrupciÃ³n (RSI) para actualizar la representa-
	@; ciÃ³n del PC actual.
_gg_rsiTIMER2:
	push {lr}


	pop {pc}

.end

