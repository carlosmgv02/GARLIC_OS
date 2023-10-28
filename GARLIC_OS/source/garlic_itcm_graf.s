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
	push {lr}
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
	pop {pc}


	.global _gg_desplazar
	@; Rutina para desplazar una posición hacia arriba todas las filas de la
	@; ventana (v), y borrar el contenido de la última fila
	@;Parámetros:
	@;	R0: ventana a desplazar (int v)
_gg_desplazar:
	push {lr}


	pop {pc}


.end

