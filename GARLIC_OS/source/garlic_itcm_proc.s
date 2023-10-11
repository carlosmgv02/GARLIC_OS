@;==============================================================================
@;
@;	"garlic_itcm_proc.s":	c�digo de las funciones de control de procesos (1.0)
@;						(ver "garlic_system.h" para descripci�n de funciones)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2
	
	.global _gp_WaitForVBlank
	@; rutina para pausar el procesador mientras no se produzca una interrupci�n
	@; de retrazado vertical (VBL); es un sustituto de la "swi #5", que evita
	@; la necesidad de cambiar a modo supervisor en los procesos GARLIC
_gp_WaitForVBlank:
	push {r0-r1, lr}
	ldr r0, =__irq_flags
.Lwait_espera:
	mcr p15, 0, lr, c7, c0, 4	@; HALT (suspender hasta nueva interrupci�n)
	ldr r1, [r0]			@; R1 = [__irq_flags]
	tst r1, #1				@; comprobar flag IRQ_VBL
	beq .Lwait_espera		@; repetir bucle mientras no exista IRQ_VBL
	bic r1, #1
	str r1, [r0]			@; poner a cero el flag IRQ_VBL
	pop {r0-r1, pc}


	.global _gp_IntrMain
	@; Manejador principal de interrupciones del sistema Garlic
_gp_IntrMain:
	mov	r12, #0x4000000
	add	r12, r12, #0x208	@; R12 = base registros de control de interrupciones	
	ldr	r2, [r12, #0x08]	@; R2 = REG_IE (m�scara de bits con int. permitidas)
	ldr	r1, [r12, #0x0C]	@; R1 = REG_IF (m�scara de bits con int. activas)
	and r1, r1, r2			@; filtrar int. activas con int. permitidas
	ldr	r2, =irqTable
.Lintr_find:				@; buscar manejadores de interrupciones espec�ficos
	ldr r0, [r2, #4]		@; R0 = m�scara de int. del manejador indexado
	cmp	r0, #0				@; si m�scara = cero, fin de vector de manejadores
	beq	.Lintr_setflags		@; (abandonar bucle de b�squeda de manejador)
	ands r0, r0, r1			@; determinar si el manejador indexado atiende a una
	beq	.Lintr_cont1		@; de las interrupciones activas
	ldr	r3, [r2]			@; R3 = direcci�n de salto del manejador indexado
	cmp	r3, #0
	beq	.Lintr_ret			@; abandonar si direcci�n = 0
	mov r2, lr				@; guardar direcci�n de retorno
	blx	r3					@; invocar el manejador indexado
	mov lr, r2				@; recuperar direcci�n de retorno
	b .Lintr_ret			@; salir del bucle de b�squeda
.Lintr_cont1:	
	add	r2, r2, #8			@; pasar al siguiente �ndice del vector de
	b	.Lintr_find			@; manejadores de interrupciones espec�ficas
.Lintr_ret:
	mov r1, r0				@; indica qu� interrupci�n se ha servido
.Lintr_setflags:
	str	r1, [r12, #0x0C]	@; REG_IF = R1 (comunica interrupci�n servida)
	ldr	r0, =__irq_flags	@; R0 = direcci�n flags IRQ para gesti�n IntrWait
	ldr	r3, [r0]
	orr	r3, r3, r1			@; activar el flag correspondiente a la interrupci�n
	str	r3, [r0]			@; servida (todas si no se ha encontrado el maneja-
							@; dor correspondiente)
	mov	pc,lr				@; retornar al gestor de la excepci�n IRQ de la BIOS


	.global _gp_rsiVBL
	@; Manejador de interrupciones VBL (Vertical BLank) de Garlic:
	@; se encarga de actualizar los tics, intercambiar procesos, etc.
_gp_rsiVBL:
	push {r4-r7, lr}
	
    @; incrementa _gd_tickCount
    ldr r4, =_gd_tickCount
    ldr r5, [r4]
    add r5, r5, #1
    str r5, [r4]
    
    @; verificar si hay procesos en la cola de Ready
    ldr r4, =_gd_nReady
    ldr r5, [r4]
    cmp r5, #0
    beq .LnoReadyProcess  @; si no hay procesos en Ready, salta a .LnoReadyProcess
    
    @; verificar si el proceso actual es del sistema operativo o tiene PID 0
    ldr r6, =_gd_pidz
    ldr r7, [r6]
    cmp r7, #0
    beq .LprocessEnded    @; si el PID es 0, salta a .LprocessEnded
    
    @; guardar el contexto del proceso actual
    bl _gp_salvarProc
    
.LprocessEnded:
    @; restaurar el pr�ximo proceso en la cola de Ready
    bl _gp_restaurarProc
    
.LnoReadyProcess:
	pop {r4-r7, pc}


	@; Rutina para salvar el estado del proceso interrumpido en la entrada
	@; correspondiente del vector _gd_pcbs
	@;Par�metros
	@; R4: direcci�n _gd_nReady
	@; R5: n�mero de procesos en READY
	@; R6: direcci�n _gd_pidz
	@;Resultado
	@; R5: nuevo n�mero de procesos en READY (+1)
_gp_salvarProc:
	push {r8-r11, lr}
	
	@;1. guardar el n�mero de z�calo del proceso a desbancar en la �ltima
	@;posici�n de la cola de Ready
	ldr r9, [r6]
	and r9, r9, #0xf	@;num zocalo
	ldr r10, =_gd_qReady
	mov r11, #15
	strb r9, [r10, r8]
	
	@;2. guardar el valor del R15 del proceso a desbancar en el campo PC del
	@;elemento _gd_pcbs[z], donde z es el n�mero de z�calo del proceso a
	@;desbancar,
	ldr r8, =_gd_pcbs
	lsl r9, r9, #6
	add r8, r9
	str r15, [r8, #4]
	
	@;3. guardar el CPSR del proceso a desbancar en el campo Status del
	mrs r11, SPSR
	str r11, [r8, #12]
	
	@;4. Cambiar al modo de ejecuci�n del proceso interrumpido
    mrs r8, CPSR
    bic r8, r8, #0x1F
    orr r8, r8, #0x1F
    msr CPSR, r0
	
	push {r0-r12, lr}

	pop {r8-r11, pc}


	@; Rutina para restaurar el estado del siguiente proceso en la cola de READY
	@;Par�metros
	@; R4: direcci�n _gd_nReady
	@; R5: n�mero de procesos en READY
	@; R6: direcci�n _gd_pidz
_gp_restaurarProc:
	push {r8-r11, lr}


	pop {r8-r11, pc}


	.global _gp_numProc
	@;Resultado
	@; R0: n�mero de procesos total
_gp_numProc:
    push {r4-r6, lr}        
    
    ldr r4, =_gd_pcbs         @; Cargar la direcci�n de inicio de _gd_pcbs en r4
    mov r0, #0                @; Contador procesos
    mov r5, #16               @; Configurar r5 para contar 16 procesos

bucle:
    ldr r6, [r4], #4          @; Cargar el PID del PCB en r6 y avanzar r4
    cmp r6, #0                @; Verificar si el PID es 0 (proceso no v�lido)
    beq siguiente             @; Si es 0, saltar a la siguiente iteraci�n
    add r0, r0, #1            @; Incrementar el contador de procesos

siguiente:
    subs r5, r5, #1           @; Decrementar el contador de 16 procesos
    bne bucle                 @; Si no hemos revisado todos los PCBs, repetir

    pop {r4-r6, pc}


	.global _gp_crearProc
	@; prepara un proceso para ser ejecutado, creando su entorno de ejecuci�n y
	@; coloc�ndolo en la cola de READY
	@;Par�metros
	@; R0: intFunc funcion,
	@; R1: int zocalo,
	@; R2: char *nombre
	@; R3: int arg
	@;Resultado
	@; R0: 0 si no hay problema, >0 si no se puede crear el proceso
_gp_crearProc:
	push {lr}


	pop {pc}


	@; Rutina para terminar un proceso de usuario:
	@; pone a 0 el campo PID del PCB del z�calo actual, para indicar que esa
	@; entrada del vector _gd_pcbs est� libre; tambi�n pone a 0 el PID de la
	@; variable _gd_pidz (sin modificar el n�mero de z�calo), para que el c�digo
	@; de multiplexaci�n de procesos no salve el estado del proceso terminado.
_gp_terminarProc:
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + z�calo
	and r1, r1, #0xf		@; R1 = z�calo del proceso desbancado
	str r1, [r0]			@; guardar z�calo con PID = 0, para no salvar estado			
	ldr r2, =_gd_pcbs
	mov r10, #24
	mul r11, r1, r10
	add r2, r11				@; R2 = direcci�n base _gd_pcbs[zocalo]
	mov r3, #0
	str r3, [r2]			@; pone a 0 el campo PID del PCB del proceso
.LterminarProc_inf:
	bl _gp_WaitForVBlank	@; pausar procesador
	b .LterminarProc_inf	@; hasta asegurar el cambio de contexto
	
.end

