@;==============================================================================
@;
@;	"garlic_itcm_mem.s":	código de rutinas de soporte a la carga de
@;							programas en memoria (version 1.0)
@;
@;==============================================================================

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
		mov r8, r0			@; muevo el buffer (primer parámetro) a r8
		mov r9, r1			@; muevo el inicio de segmento a r9
		mov r10, r2			@; muevo el destino de la memoria a r10
		add r11, #4			@; desplazamos offset hasta sh_type (tabla_secciones)
							@; sirve para saber el tipo de reubicador
	
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
		
	.Laddr11:
		add r11, #8			@; volvemos a poner el puntero en sh_type
		b .LBuclesecciones
		
	.LFin:
	
	
	pop {r0-r12,pc}


.end

