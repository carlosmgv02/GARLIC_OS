﻿@;==============================================================================
@;
@;	"garlic_itcm_mem.s":	cÃ³digo de rutinas de soporte a la carga de
@;							programas en memoria (version 1.0)
@;
@;==============================================================================

NUM_FRANJAS = 768
INI_MEM_PROC = 0x01002000

.section .dtcm,"wa",%progbits
	.align 2

	.global _gm_zocMem
_gm_zocMem:	.space NUM_FRANJAS			@; vector de ocupaciÃ³n de franjas mem.


.section .itcm,"ax",%progbits

	.arm
	.align 2


	.global _gm_reubicar
	@; rutina para interpretar los 'relocs' de un fichero ELF y ajustar las
	@; direcciones de memoria correspondientes a las referencias de tipo
	@; R_ARM_ABS32, restando la direcciÃ³n de inicio de segmento y sumando
	@; la direcciÃ³n de destino en la memoria;
	@;ParÃ¡metros:
	@; R0: direcciÃ³n inicial del buffer de fichero (char *fileBuf)
	@; R1: direcciÃ³n de inicio de segmento (unsigned int pAddr)
	@; R2: direcciÃ³n de destino en la memoria (unsigned int *dest)
	@;Resultado:
	@; cambio de las direcciones de memoria que se tienen que ajustar
_gm_reubicar:
	push {r0-r12,lr}
		ldr r11, [r0, #32]	@; e_shoff (offset de la tabla de secciones)
		ldrh r5, [r0, #48]	@; e_shnum (
		ldr r4, [SP, #56]
		mov r8, r0			@; muevo el buffer (primer parÃ¡metro) a r8
		mov r9, r1			@; muevo el inicio de segmento a r9
		mov r10, r2			@; muevo el destino de la memoria a r10
		mov r6, r3
		add r11, #4			@; desplazamos offset hasta sh_type (tabla_secciones)
		cmp r6, #0xFFFFFFFF
		beq .LBuclesecciones
		b .LDosSegmentos
	
	.LBuclesecciones:
		cmp r5, #0			@; comparo el nÃºmero de entradas con contador
		beq .LFin			@; si no hay entradas saltamos al final
		sub r5, #1			@; restamos 1 al nÃºmero de entradas restantes
		ldr r0, [r8, r11]	@; cargamos en r0 el tipo de secciÃ³n
		cmp r0, #9
		beq .LTipoSeleccion
		add r11, #40		@; vamos al sh_type de la siguiente secciÃ³n
		b .LBuclesecciones
	
	.LTipoSeleccion:
		add r11, #12		@; contador para desplazarse hasta sh_offset
		ldr r7, [r8, r11]	@; guardamos en r7 el valor de sh_offset
		add r11, #4
		ldr r0, [r8, r11]	@; en r0 tenemos el size de la secciÃ³n (serÃ¡n todo reubicadores)
		add r11, #16
		ldr r1, [r8, r11]	@; tamaÃ±o de un reubicador	
		ldr r2, =quo		@; cargamos puntero a =quo
		ldr r3, =res		@; cargamos puntero a =res
		bl _ga_divmod	
		ldr r2, [r2]		@; cargamos en r2 donde divmod ha guardado el valor
		ldr r3, [r3]		@; cargamos en r3 donde divmod ha guardado el valor
	
	.LBucleReubicadores:
		cmp r2, #0			@; comparamos el nÃºmero de reubicadores con 0
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
		add r1, r10			@; direcciÃ³n destino de memoria + offset
		sub r1, r9			@; resultado - direccion de inicio del segmento
		ldr r12, [r1]		@; obtenemos el contenido de la direcciÃ³n
		add r12, r10		@; contenido + direcciÃ³n destino de memoria
		sub r12, r9			@; resultado - direcciÃ³n de inicio del segmento
		str r12, [r1]		@; guardamos el nuevo valor en la direcciÃ³n reubicada
		b .Ladd
	
	.Ladd:
		add r7, #4			@; pasamos al siguiente reubicador
		b .LBucleReubicadores
	.Laddr11:
		add r11, #8			@; volvemos a poner el puntero en sh_type
		b .LBuclesecciones
		
	@; SI TENEMOS DOS SEGMENTOS
	@; CAMBIA LA REUBICACIÃ“N
	
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
		ldr r0, [r8, r11]	@; en r0 tenemos el size de la secciÃ³n (serÃ¡n todo reubicadores)
		add r11, #16
		ldr r1, [r8, r11]	@; en r1 tenemos el tamaÃ±o de cada reubicador
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
		sub r1, r9			@; en r1 tengo la direccion de reubicaciÃ³n
		ldr r12, [r1]		@; obtengo el contenido de la direcciÃ³n	
		cmp r12, r6
		bge .LSegundoSegmento
		add r12, r10		@; segmento de codigo. r12 = r12 + direcciÃ³n destino en la memoria del cÃ³digo (r10)
		sub r12, r9			@; r12 = r12 - direcciÃ³n de inicio de segmento de cÃ³digo (r9)
		str r12, [r1]
		b .LaddD
		
	.LSegundoSegmento:		@; si el segmento es de datos
		add r12, r4			@; r12 = r12 + direcciÃ³n destino en la memoria de los datos (r4)
		sub r12, r6			@; r12 = r12 - direcciÃ³n de inicio en el segmento de datos (r6)
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
	@; el tamaÃ±o de un segmento de cÃ³digo o datos del proceso (segÃºn indique
	@; tipo_seg), asignado al nÃºmero de zÃ³calo que se pasa por parÃ¡metro;
	@; tambiÃ©n se encargarÃ¡ de invocar a la rutina _gm_pintarFranjas(), para
	@; representar grÃ¡ficamente la ocupaciÃ³n de la memoria de procesos;
	@; la rutina devuelve la primera direcciÃ³n del espacio reservado; 
	@; en el caso de que no quede un espacio de memoria consecutivo del
	@; tamaÃ±o requerido, devuelve cero.
	@;ParÃ¡metros:
	@;	R0: el nÃºmero de zÃ³calo que reserva la memoria
	@;	R1: el tamaÃ±o en bytes que se quiere reservar
	@;	R2: el tipo de segmento reservado (0 -> cÃ³digo, 1 -> datos)
	@;Resultado:
	@;	R0: direcciÃ³n inicial de memoria reservada (0 si no es posible)
_gm_reservarMem:
	push {r1-r12,lr}
		ldr r8, =_gm_zocMem 	@; accede al vector
		mov r9, r0				@;recoloco los parametros
		mov r10, r1
		mov r11, r2
		mov r0, r1		 		@;preparo para hacer divisiÃ³n de cuantas franjas necesito 
		mov r1, #32
		ldr r2, =quo
		ldr r3, =res
		bl _ga_divmod
		ldr r0, [r2]			@; franjas a reservar
		ldr r1, [r3]
		mov r4, #0				@;contador de franjas a 0
		mov r5, #0				@; contador de franjas seguidas correctas a 0
		cmp r1, #0
		beq .Lnohayresto		@; si hay rest ( no se llena una franja entera, pero si parte, tenemos que aÃ±adir 1 a r0)
		add r0, #1
		
	.Lnohayresto:
		cmp r5, r0				@; compara si ya tengo suficientes libres seguidos
		beq .Lsuficientes		
		ldr r12, =NUM_FRANJAS	@; r12 = numero maximo de franjas
		cmp r4, r12				@; compara que se haya llegado al maximo de franjas, en ese caso no hay espacio suficiente para el proceso
		beq .Lnoespacio
		ldrb r2, [r8, r4]		@; r2 = base de matriz de zocalos + indice 
		cmp r2, #0				@; comprobar si estÃ¡ libre la franja
		beq .Llibre
		bne .Lnolibre
		
	.Llibre:					@; si la franja estÃ¡ libre, se aÃ±ade al indice y al numero de franjas libres
		add r5, #1
		add r4, #1
		b .Lnohayresto
		
	.Lnolibre:					@; si se encuentra que una franja no estÃ¡ libre, se aÃ±ade uno al indice y se resetea el contador de libres seguidas
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
		strb r9, [r8, r4]		@; reservar franja y despues aÃ±adir contadores
		add r4, #1
		add r6, #1
		b .Lsuficientes2
		
	.Lnoespacio:
		mov r0, #0
		b .Lfin					@; si no se reserva espacio, la direcciÃ³n inicial es 0 
		
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
	@; del zÃ³calo indicado por parÃ¡metro; tambiÃ©n se encargarÃ¡ de invocar a la
	@; rutina _gm_pintarFranjas(), para actualizar la representaciÃ³n grÃ¡fica
	@; de la ocupaciÃ³n de la memoria de procesos.
	@;ParÃ¡metros:
	@;	R0: el nÃºmero de zÃ³calo que libera la memoria
_gm_liberarMem:
	push {r0-r12,lr}
		ldr r1, =_gm_zocMem			@; r1 se accede a la memoria que indica que proceso ocupa cada zocalo
		mov r2, #0 					@; r2 y r10 se colocan los contadores a 0
		mov r10, #0

	.Lbucle:
		ldr r5, =NUM_FRANJAS		@; r5 guarda el mÃ¡ximo de franjas que hay
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
		add r2, #1					@; se aÃ±ade 1 al indice para cargar la siguiente posiciÃ³n
		ldrb r3, [r1, r2]			
		cmp r3, r0
		beq .Leliminar				@; se compara que la siguiente franja sea tambiÃ©n del proceso y sigue iterando
		@;add r2, #1					
		bne .Lquitarfranjas			@; sino, se va a pintar las franjas para liberar memoria
		
	.Lquitarfranjas:
		push {r0-r3}
		mov r0, r4					@; para llamar a printar franjas, se indican los parÃ¡metros necesarios
		mov r1, r9
		mov r2, r10
		mov r3, #0					@; aunque hayan segmentos de datos y/o cÃ³digo no importa, los tratamos como cÃ³digo todo porque es solo borrar
		bl _gm_pintarFranjas
		pop {r0-r3}
		b .Lbucle
		
	.Lfin:

	pop {r0-r12,pc}


	.global _gm_pintarFranjas
	@; Rutina para para pintar las franjas verticales correspondientes a un
	@; conjunto de franjas consecutivas de memoria asignadas a un segmento
	@; (de cÃ³digo o datos) del zÃ³calo indicado por parÃ¡metro.
	@;ParÃ¡metros:
	@;	R0: el nÃºmero de zÃ³calo que reserva la memoria (0 para borrar)
	@;	R1: el Ã­ndice inicial de las franjas
	@;	R2: el nÃºmero de franjas a pintar
	@;	R3: el tipo de segmento reservado (0 -> cÃ³digo, 1 -> datos)
_gm_pintarFranjas:
	push {r0-r12,lr}
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
		add r0, r4					@; aÃ±ade el color al halfword de r0
		cmp r10, #0					@; compara si el color es negro (estÃ¡ liberando memoria)
		andeq r0, r4				@; si estÃ¡ liberando memoria le hace una AND al halfword a insertar para borrar la memoria en pantalla
		strh r0, [r6, r7]			@; guarda r0 en la pantalla
		add r7, #8					@; r7 = r7+8 para continuar en la columna
		add r12, #1					@; r12 = r12+1 indicando que aÃ±ade una columna
		b .Lbuclesico2
	
	.Ldatos: 
		cmp r5, #0					@; contador de r5 para hacer el patron pixel de color y pixel negro
		bne .Luno
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
		add r0, r4					@; aÃ±ade el color al halfword de r0
		strh r0, [r6, r7]			@; guarda r0 en la pantalla
		add r7, #8					@; r7 = r7+8 para continuar en la columna
		add r12, #1					@; r12 = r12+1 indicando que aÃ±ade una columna
		mov r5, #1					@; se mueve el bit a r5 a 1 para que el siguiente pixel sea negro
		b .Lbuclesico2
		
	.Luno:
		add r7, #8					@; r7 = r7+8 para continuar en la columna
		add r12, #1					@; r12 = r12+1 indicando que aÃ±ade una columna
		mov r5, #0					@; se mueve el bit a r5 a 0 para que el siguiente pixel sea de color
		b .Lbuclesico2
		
	.Lfuerabuclesico2:
		add r8, #1					@; r8= r8+1 para la siguiente columna  
		add r11, #1					@; aÃ±ade una columna al contador
		sub r2, #1					@; se resta una a las columnas que se tienen que printear 
		cmp r5, #0
		beq .Lponauno
		mov r5, #0					@; cambia r5 para la sigiente columna 
		cmp r2, #0
		bne .Lbuclesico				@; si no se han acabado las columnas, se sigue, sino se acaba
		beq .Lfinpintar
		
	.Lponauno:
		mov r5, #1					@; cambia r5 para la sigiente columna
		cmp r2, #0
		bne .Lbuclesico
		beq .Lfinpintar				@; sino quedan mas columnas, se acaba
		
	.Lnuevabaldosa: 				@; para la siguiente columna se tiene que aÃ±adir los 56 bytes al r8
		add r8, #56						
		mov r11, #0					@; ademÃ¡s se mueve r11 que indica la columna, a 0 para la siguiente baldosa
		b .Lbuclesico
		
	.Lfinpintar:
	pop {r0-r12,pc}


	.global _gm_rsiTIMER1
	@; Rutina de Servicio de InterrupciÃ³n (RSI) para actualizar la representa-
	@; ciÃ³n de la pila y el estado de los procesos activos.
_gm_rsiTIMER1:
	push {r0-r12,lr}
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
		sub r7, #4					@; contador se coloca en la primera posiciÃ³n de la pila
		add r11, r1, r7				@; r11 = vector de pilas + indice
		mla r6, r4, r3, r0			@; r6 = r0 base de pcbs + (r4  * r3 (segun el proceso a tratar)) (para llegar al pcb del proceso actual)
		ldr r12, [r6]				@; r12 = direcciÃ³n a PID del proceso
		cmp r12, #0					@; compara que el PID sea 0 (el SO se trata por separado y si no hay proceso asignado, estarÃ¡ el PID en 0)
		beq .Lnext
		add r6, #8					@; aÃ±ade 8 para que r12 sea el SP del proceso (TOP de la pila)
		ldr r12, [r6]
		mov r5, #0
		
	.Lbuclersi2:
		cmp r11, r12				@; compara que se llegue desde el TOP de la pila hasta el inicio
		beq .Lsal
		add r12, #4
		add r5, #4					@; r5 acumula la diferencia de entre el TOP y el inicio de la pila
		b .Lbuclersi2

	.Lsal:
		mov r7, #0x06200000			@; r7 direcciÃ³n base del mapa de columnas y filas que se printea en la pantalla de abajo
		mov r6, #4					
		add r6, r3					@; r6 a partir de la fila 2, se coloca segÃºn el zocalo
		add r7, r6, lsl #6
		mov r9, #22					@; r9 en la columna 27 es donde se tiene que colocar la representaciÃ³n de la pila 
		add r7, r9, lsl #1
		mov r10, #119				@; la base de representacion de la pila 
	.Lbuclersi3:
		cmp r5, #0					@; compara que se tenga que acabar la representaciÃ³n de la pila
		ble .Lsal2
		add r10, #1					@; aÃ±ade 1 a r10 para aumentar la baldosa a printear (representa que estÃ¡ un poco mÃ¡s llena la pila)
		sub r5, #32					@; le resta 32 al contador de diferencia entre TOP e inicio de la pila
		cmp r10, #127				@; si se ha llegado al mÃ¡ximo que puede estar la pila llena, se va a la siguiente baldosa 
		beq .Lsal2
		b .Lbuclersi3
	.Lsal2:	
		add r7, #2				@; VALE 2 Y 3 PORQUE?
		strh r10, [r7]				@; se introduce la baldosa en el mapa
		mov r10, #119				@; se pone por defecto en 119 de nuevo la baldosa
	.Lbuclersi4:
		cmp r5, #0					@; compara que se acabe la representaciÃ³n de la pila 
		ble .Lsal3
		add r10, #1					@; se aÃ±ade uno a la baldosa a representar
		sub r5, #32
		cmp r10, #127				@; se compara que estÃ© llena la pila a representar 
		beq .Lsal3
		b .Lbuclersi4
	.Lsal3:
		add r7, #2				@; VALE 2 Y 1 PORQUE?
		strh r10, [r7]				@; guarda baldosa 
		add r3, #1					@; aÃ±ade 1 a la fila donde printear la pila
		b .Lbuclersi1
		
	.Lnext:
		add r3, #1					@; aÃ±ade 1 a la fila donde printear la pila
		b .Lbuclersi1
	.Lfinrsi1:
	
	@; parte de las letras
		ldr r0, =_gd_pidz
		ldr r0, [r0]
		and r0, #0xF
		mov r7, #0x06200000
		mov r6, #4
		add r6, r0
		add r7, r6, lsl #6
		mov r9, #26
		add r7, r9, lsl #1
		mov r0, #0x1
		mov r0, r0, lsl #7
		add r0, #50
		strh r0, [r7]
	@;.LrunningSO:
	
	.Lready:
		ldr r0, = _gd_nReady			@; numero de procesos de ready en r0
		ldr r0, [r0]
		mov r1, #0					@; contador de procesos que llevamos en r1
		mov r3, #0					@; r3 para actualizar indice de procesos en ready
	.LcontiReady:
		cmp r0, r1					@; compara que ya lleves todos
		beq .LfinReady
		ldr r2, = _gd_qReady			@; carga de cola de procesos en ready
		ldrb r4, [r2, r3]
		mov r7, #0x06200000
		mov r6, #4
		add r6, r4
		add r7, r6, lsl #6
		mov r9, #26
		add r7, r9, lsl #1
		mov r8, #57
		strh r8, [r7]
		add r3, #1
		add r1, #1 
		b .LcontiReady
	.LfinReady:	
	
	.Ldelay:
		ldr r0, = _gd_nDelay
		ldr r0, [r0]
		mov r1, #0 
		mov r3, #0
	.LcontiDelay:
		cmp r0, r1
		beq .LfinDelay
		ldr r2, = _gd_qDelay
		add r3, #3
		ldrb r4, [r2, r3]
		mov r7, #0x06200000
		mov r6, #4
		add r6, r4
		add r7, r6, lsl #6
		mov r9, #26
		add r7, r9, lsl #1
		mov r8, #34
		strh r8, [r7]
		add r3, #4
		add r1, #1
		b .LcontiDelay
	.LfinDelay:
	
	pop {r0-r12,pc}

.end