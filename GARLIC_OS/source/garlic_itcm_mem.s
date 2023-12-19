@;==============================================================================
@;
@;	"garlic_itcm_mem.s":	código de rutinas de soporte a la carga de
@;							programas en memoria (version 1.0)
@;
@;==============================================================================

NUM_FRANJAS = 768
INI_MEM_PROC = 0x01002000

.section .dtcm,"wa",%progbits
	.align 2

	.global _gm_zocMem
_gm_zocMem:	.space NUM_FRANJAS			@; vector de ocupación de franjas mem.


.section .itcm,"ax",%progbits

	.arm
	.align 2


	.global _gm_reubicar
	@; rutina para interpretar los 'relocs' de un fichero ELF y ajustar las
	@; direcciones de memoria correspondientes a las referencias de tipo
	@; R_ARM_ABS32, restando la dirección de inicio de segmento y sumando
	@; la dirección de destino en la memoria;
	@;Parámetros:
	@; R0: dirección inicial del buffer de fichero (char *fileBuf)
	@; R1: dirección de inicio de segmento (unsigned int pAddr)
	@; R2: dirección de destino en la memoria (unsigned int *dest)
	@;Resultado:
	@; cambio de las direcciones de memoria que se tienen que ajustar
_gm_reubicar:
	push {r0-r12,lr}
		ldr r11, [r0, #32]	@; e_shoff (offset de la tabla de secciones)
		ldrh r5, [r0, #48]	@; e_shnum (
		ldr r4, [SP, #56]
		mov r8, r0			@; muevo el buffer (primer parámetro) a r8
		mov r9, r1			@; muevo el inicio de segmento a r9
		mov r10, r2			@; muevo el destino de la memoria a r10
		mov r6, r3
		add r11, #4			@; desplazamos offset hasta sh_type (tabla_secciones)
		cmp r6, #0xFFFFFFFF
		beq .LBuclesecciones
		b . LDosSegmentos
	
	.LBuclesecciones:
		cmp r5, #0			@; comparo el número de entradas con contador
		beq .LFin			@; si no hay entradas saltamos al final
		sub r5, #1			@; restamos 1 al número de entradas restantes
		ldr r0, [r8, r11]	@; cargamos en r0 el tipo de sección
		cmp r0, #9
		beq .LTipoSeleccion
		add r11, #40		@; vamos al sh_type de la siguiente sección
		b .LBuclesecciones
	
	.LTipoSeleccion:
		add r11, #12		@; contador para desplazarse hasta sh_offset
		ldr r7, [r8, r11]	@; guardamos en r7 el valor de sh_offset
		add r11, #4
		ldr r0, [r8, r11]	@; en r0 tenemos el size de la sección (serán todo reubicadores)
		add r11, #16
		ldr r1, [r8, r11]	@; tamaño de un reubicador	
		ldr r2, =quo		@; cargamos puntero a =quo
		ldr r3, =res		@; cargamos puntero a =res
		bl _ga_divmod	
		ldr r2, [r2]		@; cargamos en r2 donde divmod ha guardado el valor
		ldr r3, [r3]		@; cargamos en r3 donde divmod ha guardado el valor
	
	.LBucleReubicadores:
		cmp r2, #0			@; comparamos el número de reubicadores con 0
		beq .Laddr11
		sub r2, #1
		ldr r1, [r8, r7]	@; guardo en r1 el offset del primer reubicador
		add r7, #4
		ldr r0, [r8, r7]	@; los 8 bits bajos indican el tipo de reubicador
		and r0, #0xFF
		cmp r0, #2			@; comprobamos si el reubicador es de tipo R_ARM_ABS32
		beq .LReubicar
		b .Ladd
		
	.LReubicar:
		add r1, r10			@; dirección destino de memoria + offset
		sub r1, r9			@; resultado - direccion de inicio del segmento
		ldr r12, [r1]		@; obtenemos el contenido de la dirección
		add r12, r10		@; contenido + dirección destino de memoria
		sub r12, r9			@; resultado - dirección de inicio del segmento
		str r12, [r1]		@; guardamos el nuevo valor en la dirección reubicada
		b .Ladd
	
	.Ladd:
		add r7, #4			@; pasamos al siguiente reubicador
		b .LBucleReubicadores
	.Laddr11:
		add r11, #8			@; volvemos a poner el puntero en sh_type
		b .LBuclesecciones
		
	@; SI TENEMOS DOS SEGMENTOS
	@; CAMBIA LA REUBICACIÓN
	
	.LDosSegmentos:
		cmp r5, #0
		beq .LFin
		sub r5, #1
		ldr r0, [r8, r11]
		cmp r0, #9
		beq .LTipoSeleccionD
		add r11, #40
		b .LDosSegmentos
		
	.LTipoSeleccionD:
		add r11, #12
		ldr r7, [r8, r11]	@; valor del offset cargado en r7
		add r11, #4			
		ldr r0, [r8, r11]	@; en r0 tenemos el size de la sección (serán todo reubicadores)
		add r11, #16
		ldr r1, [r8, r11]	@; en r1 tenemos el tamaño de cada reubicador
		ldr r2, =quo
		ldr r3, =res
		bl _ga_divmod		@; en r2 tenemos el numero de reubicadores
		ldr r2, [r2]
		ldr r3, [r3]
		
	.LBucleReubicadoresD:
		cmp r2, #0
		beq .Laddr11D
		sub r2, #1
		ldr r1, [r8, r7]	@; guardo en r1 el valor del primer reubicador, el offset
		add r7, #4
		ldr r0, [r8, r7]	@; guardo en r0 el tipo de reubicador
		and r0, #0xFF
		cmp r0, #2
		beq .LreubicarD
		b .LaddD
		
	.LreubicarD:
		add r1, r10
		sub r1, r9			@; en r1 tengo la direccion de reubicación
		ldr r12, [r1]		@; obtengo el contenido de la dirección	
		cmp r12, r6
		bge .LSegundoSegmento
		add r12, r10		@; segmento de codigo. r12 = r12 + dirección destino en la memoria del código (r10)
		sub r12, r9			@; r12 = r12 - dirección de inicio de segmento de código (r9)
		str r12, [r1]
		b .LaddD
		
	.LSegundoSegmento:		@; si el segmento es de datos
		add r12, r4			@; r12 = r12 + dirección destino en la memoria de los datos (r4)
		sub r12, r6			@; r12 = r12 - dirección de inicio en el segmento de datos (r6)
		str r12, [r1]
		b .LaddD
		
	.LaddD:
		add r7,#4			@; para colocarse en el siguiente reubicador
		b .LBucleReubicadoresD
		
	.Laddr11D:
		add r11,#8			@; para colocarse en el siguiente segmento(?)
		b .LDosSegmentos
	.LFin:
	
	pop {r0-r12,pc}


	.global _gm_reservarMem
	@; Rutina para reservar un conjunto de franjas de memoria libres
	@; consecutivas que proporcionen un espacio suficiente para albergar
	@; el tamaño de un segmento de código o datos del proceso (según indique
	@; tipo_seg), asignado al número de zócalo que se pasa por parámetro;
	@; también se encargará de invocar a la rutina _gm_pintarFranjas(), para
	@; representar gráficamente la ocupación de la memoria de procesos;
	@; la rutina devuelve la primera dirección del espacio reservado; 
	@; en el caso de que no quede un espacio de memoria consecutivo del
	@; tamaño requerido, devuelve cero.
	@;Parámetros:
	@;	R0: el número de zócalo que reserva la memoria
	@;	R1: el tamaño en bytes que se quiere reservar
	@;	R2: el tipo de segmento reservado (0 -> código, 1 -> datos)
	@;Resultado:
	@;	R0: dirección inicial de memoria reservada (0 si no es posible)
_gm_reservarMem:
	push {lr}
	

	pop {pc}


	.global _gm_liberarMem
	@; Rutina para liberar todas las franjas de memoria asignadas al proceso
	@; del zócalo indicado por parámetro; también se encargará de invocar a la
	@; rutina _gm_pintarFranjas(), para actualizar la representación gráfica
	@; de la ocupación de la memoria de procesos.
	@;Parámetros:
	@;	R0: el número de zócalo que libera la memoria
_gm_liberarMem:
	push {lr}


	pop {pc}


	.global _gm_pintarFranjas
	@; Rutina para para pintar las franjas verticales correspondientes a un
	@; conjunto de franjas consecutivas de memoria asignadas a un segmento
	@; (de código o datos) del zócalo indicado por parámetro.
	@;Parámetros:
	@;	R0: el número de zócalo que reserva la memoria (0 para borrar)
	@;	R1: el índice inicial de las franjas
	@;	R2: el número de franjas a pintar
	@;	R3: el tipo de segmento reservado (0 -> código, 1 -> datos)
_gm_pintarFranjas:
	push {lr}


	pop {pc}


	.global _gm_rsiTIMER1
	@; Rutina de Servicio de Interrupción (RSI) para actualizar la representa-
	@; ción de la pila y el estado de los procesos activos.
_gm_rsiTIMER1:
	push {lr}


	pop {pc}

.end

