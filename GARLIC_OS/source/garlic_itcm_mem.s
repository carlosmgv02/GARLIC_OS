﻿@;==============================================================================
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
	push {r1-r12,lr}
		ldr r8, =_gm_zocMem 	@; accede al vector
		mov r9, r0				@;recoloco los parametros
		mov r10, r1
		mov r11, r2
		mov r0, r1		 		@;preparo para hacer división de cuantas franjas necesito 
		mov r1, #32
		ldr r2, =quo
		ldr r3, =res
		bl _ga_divmod
		ldr r0, [r2]			@; franjas a reservar
		ldr r1, [r3]
		mov r4, #0				@;contador de franjas a 0
		mov r5, #0				@; contador de franjas seguidas correctas a 0
		cmp r1, #0
		beq .Lnohayresto		@; si hay rest ( no se llena una franja entera, pero si parte, tenemos que añadir 1 a r0)
		add r0, #1
		
	.Lnohayresto:
		cmp r5, r0				@; compara si ya tengo suficientes libres seguidos
		beq .Lsuficientes		
		ldr r12, =NUM_FRANJAS	@; r12 = numero maximo de franjas
		cmp r4, r12				@; compara que se haya llegado al maximo de franjas, en ese caso no hay espacio suficiente para el proceso
		beq .Lnoespacio
		ldrb r2, [r8, r4]		@; r2 = base de matriz de zocalos + indice 
		cmp r2, #0				@; comprobar si está libre la franja
		beq .Llibre
		bne .Lnolibre
		
	.Llibre:					@; si la franja está libre, se añade al indice y al numero de franjas libres
		add r5, #1
		add r4, #1
		b .Lnohayresto
		
	.Lnolibre:					@; si se encuentra que una franja no está libre, se añade uno al indice y se resetea el contador de libres seguidas
		mov r5, #0	
		add r4, #1
		b .Lnohayresto
		
	.Lsuficientes:				@; cuando hay suficientes franjas libres para un proceso
		sub r4, r5				
		mov r10, r4				@; r10 es la base de las franjas a asignar al proceso
		mov r6, #0				@; contador de franjas reservadas
		mov r1, #32				
		ldr r7, =INI_MEM_PROC	@; r7 =carga la base de la memoria
		mla r0, r4, r1, r7		@; calcula la direccion inicial de la memoria reservada 
		
	.Lsuficientes2:
		cmp	r6, r5
		beq .Lreservado			@; se compara que se han reservado ya todas las franjas
		strb r9, [r8, r4]		@; reservar franja y despues añadir contadores
		add r4, #1
		add r6, #1
		b .Lsuficientes2
		
	.Lnoespacio:
		mov r0, #0
		b .Lfin					@; si no se reserva espacio, la dirección inicial es 0 
		
	.Lreservado:
		push {r0-r3}			@; actualizar de r0 a r3 para pintar franjas
		mov r0, r9				@; r0 = numero zocalo que reserva la memoria
		mov r3, r11				@; r3 = tipo de segmento a reservar 
		mov r1, r10				@; r1 = base de las franjas a reservar 
		mov r2, r5				@; r2 = numero de franjas a pintar 
		bl _gm_pintarFranjas	
		pop {r0-r3}
		
	pop {r1-r12,pc}


	.global _gm_liberarMem
	@; Rutina para liberar todas las franjas de memoria asignadas al proceso
	@; del zócalo indicado por parámetro; también se encargará de invocar a la
	@; rutina _gm_pintarFranjas(), para actualizar la representación gráfica
	@; de la ocupación de la memoria de procesos.
	@;Parámetros:
	@;	R0: el número de zócalo que libera la memoria
_gm_liberarMem:
	push {r0-r12,lr}
		ldr r1, =_gm_zocMem			@; r1 se accede a la memoria que indica que proceso ocupa cada zocalo
		mov r2, #0 					@; r2 y r10 se colocan los contadores a 0
		mov r10, #0

	.Lbucle:
		ldr r5, =NUM_FRANJAS		@; r5 guarda el máximo de franjas que hay
		cmp r2, r5					@; se compara que r2 no haya llegado al maximo, si llega se acaba el liberar memoria
		beq .Lfin
		ldrb r3, [r1, r2]			@; r3 = matriz de zocalo + indice
		cmp r3, r0					@; compara si es del proceso a liberar
		beq .Leliminar1				@; si es, se elimina
		add r2, #1					@; si se aumenta el indice
		b .Lbucle
		
	.Leliminar1:
		mov r9, r2					@; indice inicial de las franjas, para pasarlo al printarfranjas
		
	.Leliminar:
		add r10, #1					@; r10=r10+1 para contar cuantas franjas se han de borrar
		mov r4, #0					@; r4 = 0 para indicar que ya no hay proceso en esa franja
		strb r4, [r1, r2]			@; se guarda el 0 en la franja
		add r2, #1					@; se añade 1 al indice para cargar la siguiente posición
		ldrb r3, [r1, r2]			
		cmp r3, r0
		beq .Leliminar				@; se compara que la siguiente franja sea también del proceso y sigue iterando
		@;add r2, #1					
		bne .Lquitarfranjas			@; sino, se va a pintar las franjas para liberar memoria
		
	.Lquitarfranjas:
		push {r0-r3}
		mov r0, r4					@; para llamar a printar franjas, se indican los parámetros necesarios
		mov r1, r9
		mov r2, r10
		mov r3, #0					@; aunque hayan segmentos de datos y/o código no importa, los tratamos como código todo porque es solo borrar
		bl _gm_pintarFranjas
		pop {r0-r3}
		b .Lbucle
		
	.Lfin:

	pop {r0-r12,pc}


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
	push {r0-,lr}
		mov r4, #0x06200000
		add r5, r4, #0x00004000
		add r6, r5, #0x8000			@;r6 = base de baldosas para gestion de memoria	 
		ldr r4, =_gs_colZoc
		add r9, r4, r0				
		ldrb r10, [r9]				@;r10 = seleccion del color
		mov r11, #0					@;contar en que columna estamos de las 8 de cada baldosa
		push {r0-r3}
		mov r0, r1
		mov r1, #8
		ldr r2, =quo
		ldr r3, =res
		bl _ga_divmod
		ldr r8, [r2]
		ldr r5, [r3]
		pop {r0-r3}					@; r8 = para definir que baldosa y r5 la columna en esa baldosa
		add r11, r5
		mov r7, #64					
		mul r8, r7					@; r8 *64 porque cada baldosa son 64 bytes
		add r8, r5					@; r8+r5 para posicionarme en la columna correcta (NO HABRIA QUE MULTIPLICAR R5 POR 8?)
		mov r5, #0					@; r5 =0 contador 
	.Lbuclesico:
		cmp r11, #8
		beq .Lnuevabaldosa			@; si hemos acabado la baldosa, siguiente
		mov r7, r8
		add r7, #16					@; r7=r8+16 para ponernos en las casillas a printear 
		mov r12, #0					@; r12 = 0 para comprobar el byte que se printea
	.Lbuclesico2:
		cmp r12, #4					@; si ya se han printeado los 4 de la columna, siguiente columna 
		beq .Lfuerabuclesico2
		cmp r3, #0
		bne .Ldatos					@; r3 nos permite diferenciar entre si printeamos datos (salto) o codigo (se queda aqui). Al final es el mismo fundamento con diferente colores.
		ldrh r0, [r6, r7]			@; carga el halfword en r0
		mov r4, r10					@; r4=r10
		cmp r11, #1					@; compara si estas en la columna 1,3,5 o 7 de la baldosa para mover el color para insertarlo en la parte alta del halfword
		moveq r4, r10, lsl #8 	
		cmp r11, #3
		moveq r4, r10, lsl #8
		cmp r11, #5
		moveq r4, r10, lsl #8 
		cmp r11, #7
		moveq r4, r10, lsl #8
		add r0, r4					@; añade el color al halfword de r0
		cmp r10, #0					@; compara si el color es negro (está liberando memoria)
		andeq r0, r4				@; si está liberando memoria le hace una AND al halfword a insertar para borrar la memoria en pantalla
		strh r0, [r6, r7]			@; guarda r0 en la pantalla
		add r7, #8					@; r7 = r7+8 para continuar en la columna
		add r12, #1					@; r12 = r12+1 indicando que añade una columna
		b .Lbuclesico2

	pop {r0-,pc}


	.global _gm_rsiTIMER1
	@; Rutina de Servicio de Interrupción (RSI) para actualizar la representa-
	@; ción de la pila y el estado de los procesos activos.
_gm_rsiTIMER1:
	push {r0-,lr}
		ldr r0, =_gd_pcbs			@; r0= vector de pcbs 
		mov r2, #512				@; r2 contador de 512 bits para cada pcb
		mov r3, #0					@; r3 = contador de pcbs
		mov r4, #32					@; r4 = bytes que ocupan los pcbs
		ldr r1, =_gd_stacks			@; r1 = vector de las pilas (cada pila 512 bits)
		
	@; parte de las pilas
	@; parte del SO
		mla r6, r4, r3, r0
		add r6, #8
		ldr r12, [r6]
		cmp r12, #0 
		beq .Lnext
		mov r5, #0
		ldr r11, =#0x0B003D00
		sub r11, #4
		b .Lbuclersi2
	@; parte de procesos no SO
	.Lbuclersi1:
		cmp r3, #4					@; solo tenemos 4 zocalos 
		beq .Lfinrsi1				@; compara que se hayan mirado todos los procesos 
		mul r7, r3, r2				
		sub r7, #4					@; contador se coloca en la primera posición de la pila
		add r11, r1, r7				@; r11 = vector de pilas + indice
		mla r6, r4, r3, r0			@; r6 = r0 base de pcbs + (r4  * r3 (segun el proceso a tratar)) (para llegar al pcb del proceso actual)
		ldr r12, [r6]				@; r12 = dirección a PID del proceso
		cmp r12, #0					@; compara que el PID sea 0 (el SO se trata por separado y si no hay proceso asignado, estará el PID en 0)
		beq .Lnext
		add r6, #8					@; añade 8 para que r12 sea el SP del proceso (TOP de la pila)
		ldr r12, [r6]
		mov r5, #0
	.Lbuclersi2:
		cmp r11, r12				@; compara que se llegue desde el TOP de la pila hasta el inicio
		beq .Lsal
		add r12, #4
		add r5, #4					@; r5 acumula la diferencia de entre el TOP y el inicio de la pila
		b .Lbuclersi2

	pop {r0-,pc}

.end

