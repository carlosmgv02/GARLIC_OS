@;==============================================================================
@;
@;	"garlic_itcm_proc.s":	código de las funciones de control de procesos (1.0)
@;						(ver "garlic_system.h" para descripción de funciones)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2
	
	.global _gp_WaitForVBlank
	@; rutina para pausar el procesador mientras no se produzca una interrupción
	@; de retrazado vertical (VBL); es un sustituto de la "swi #5", que evita
	@; la necesidad de cambiar a modo supervisor en los procesos GARLIC
_gp_WaitForVBlank:
	push {r0-r1, lr}
	ldr r0, =__irq_flags
.Lwait_espera:
	mcr p15, 0, lr, c7, c0, 4	@; HALT (suspender hasta nueva interrupción)
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
	ldr	r2, [r12, #0x08]	@; R2 = REG_IE (máscara de bits con int. permitidas)
	ldr	r1, [r12, #0x0C]	@; R1 = REG_IF (máscara de bits con int. activas)
	and r1, r1, r2			@; filtrar int. activas con int. permitidas
	ldr	r2, =irqTable
.Lintr_find:				@; buscar manejadores de interrupciones específicos
	ldr r0, [r2, #4]		@; R0 = máscara de int. del manejador indexado
	cmp	r0, #0				@; si máscara = cero, fin de vector de manejadores
	beq	.Lintr_setflags		@; (abandonar bucle de búsqueda de manejador)
	ands r0, r0, r1			@; determinar si el manejador indexado atiende a una
	beq	.Lintr_cont1		@; de las interrupciones activas
	ldr	r3, [r2]			@; R3 = dirección de salto del manejador indexado
	cmp	r3, #0
	beq	.Lintr_ret			@; abandonar si dirección = 0
	mov r2, lr				@; guardar dirección de retorno
	blx	r3					@; invocar el manejador indexado
	mov lr, r2				@; recuperar dirección de retorno
	b .Lintr_ret			@; salir del bucle de búsqueda
.Lintr_cont1:	
	add	r2, r2, #8			@; pasar al siguiente índice del vector de
	b	.Lintr_find			@; manejadores de interrupciones específicas
.Lintr_ret:
	mov r1, r0				@; indica qué interrupción se ha servido
.Lintr_setflags:
	str	r1, [r12, #0x0C]	@; REG_IF = R1 (comunica interrupción servida)
	ldr	r0, =__irq_flags	@; R0 = dirección flags IRQ para gestión IntrWait
	ldr	r3, [r0]
	orr	r3, r3, r1			@; activar el flag correspondiente a la interrupción
	str	r3, [r0]			@; servida (todas si no se ha encontrado el maneja-
							@; dor correspondiente)
	mov	pc,lr				@; retornar al gestor de la excepción IRQ de la BIOS


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
    @; restaurar el próximo proceso en la cola de Ready
    bl _gp_restaurarProc
    
.LnoReadyProcess:
	pop {r4-r7, pc}


	@; Rutina para salvar el estado del proceso interrumpido en la entrada
	@; correspondiente del vector _gd_pcbs
	@;Parámetros
	@; R4: dirección _gd_nReady
	@; R5: número de procesos en READY
	@; R6: dirección _gd_pidz
	@;Resultado
	@; R5: nuevo número de procesos en READY (+1)
_gp_salvarProc:
	push {r8-r11, lr}
	
	@;1. guardar el número de zócalo del proceso a desbancar en la última
	@;posición de la cola de Ready
	ldr r9, [r6]
	and r9, r9, #0xf	@;num zocalo
	ldr r10, =_gd_qReady
	mov r11, #15
	strb r9, [r10, r8]
	
	@;2. guardar el valor del R15 del proceso a desbancar en el campo PC del
	@;elemento _gd_pcbs[z], donde z es el número de zócalo del proceso a
	@;desbancar,
	ldr r8, =_gd_pcbs
	lsl r9, r9, #6
	add r8, r9
	str r15, [r8, #4]
	
	@;3. guardar el CPSR del proceso a desbancar en el campo Status del
	mrs r11, SPSR
	str r11, [r8, #12]
	
	@;4. Cambiar al modo de ejecución del proceso interrumpido
    mrs r8, CPSR
    bic r8, r8, #0x1F
    orr r8, r8, #0x1F
    msr CPSR, r0
	
	push {r0-r12, lr}

	pop {r8-r11, pc}


	@; Rutina para restaurar el estado del siguiente proceso en la cola de READY
	@;Parámetros
	@; R4: dirección _gd_nReady
	@; R5: número de procesos en READY
	@; R6: dirección _gd_pidz
_gp_restaurarProc:
	push {r8-r11, lr}


	pop {r8-r11, pc}


	.global _gp_numProc
	@;Resultado
	@; R0: número de procesos total
_gp_numProc:
    push {r4-r6, lr}        
    
    ldr r4, =_gd_pcbs         @; Cargar la dirección de inicio de _gd_pcbs en r4
    mov r0, #0                @; Contador procesos
    mov r5, #16               @; Configurar r5 para contar 16 procesos

bucle:
    ldr r6, [r4], #4          @; Cargar el PID del PCB en r6 y avanzar r4
    cmp r6, #0                @; Verificar si el PID es 0 (proceso no válido)
    beq siguiente             @; Si es 0, saltar a la siguiente iteración
    add r0, r0, #1            @; Incrementar el contador de procesos

siguiente:
    subs r5, r5, #1           @; Decrementar el contador de 16 procesos
    bne bucle                 @; Si no hemos revisado todos los PCBs, repetir

    pop {r4-r6, pc}


	.global _gp_crearProc
	@; prepara un proceso para ser ejecutado, creando su entorno de ejecución y
	@; colocándolo en la cola de READY
	@;Parámetros
	@; R0: intFunc funcion,
	@; R1: int zocalo,
	@; R2: char *nombre
	@; R3: int arg
	@;Resultado
	@; R0: 0 si no hay problema, >0 si no se puede crear el proceso
	
_gp_crearProc:
    push {r4-r12, lr}               @ Guardar registros y lr en la pila

    @ Rechazar la llamada si el zócalo es 0 o si el zócalo ya está ocupado
    cmp r1, #0                      @ Comparar zócalo con 0
    beq error                       @ Si zócalo es 0, ir a error
    ldr r4, =_gd_pcbs               @ Cargar la dirección de inicio de _gd_pcbs en r4
    ldr r5, [r4, r1, lsl #4]        @ Cargar el PID del zócalo en r5
    cmp r5, #0                      @ Comparar PID con 0
    bne error                       @ Si PID no es 0, ir a error

    @ Obtener un PID para el nuevo proceso
    ldr r4, =_gd_pidCount           @ Cargar la dirección de _gd_pidCount en r4
    ldr r5, [r4]                    @ Cargar el valor de _gd_pidCount en r5
    add r5, r5, #1                  @ Incrementar _gd_pidCount
    str r5, [r4]                    @ Guardar el nuevo valor en _gd_pidCount

    @ Guardar PID, dirección de la rutina inicial y nombre en clave en el PCB
    ldr r4, =_gd_pcbs               @ Cargar la dirección de inicio de _gd_pcbs en r4
    add r4, r4, r1, lsl #4          @ Calcular la dirección de _gd_pcbs[z]
    str r5, [r4]                    @ Guardar el PID en el PCB
    add r0, r0, #4                  @ Sumar 4 a la dirección de la rutina
    str r0, [r4, #4]                @ Guardarla en el campo PC del PCB
    str r2, [r4, #16]               @ Guardar el nombre en clave en el campo keyName

    @ Calcular la dirección base de la pila del proceso y guardar valores iniciales
    ldr r5, =_gd_stacks             @ Cargar la dirección de inicio de _gd_stacks en r5
	mov r6, #128                    @ Copiar el valor del zócalo en r6
    mul r6, r1, r6                @ Calcular el desplazamiento para el zócalo específico
    add r5, r5, r6, lsl #2          @ Calcular la dirección base de la pila
    mov r6, #0                      @ Limpiar r6 para usarlo para inicializar la pila
    mov r7, #13                     @ Establecer r7 para 13 registros
init_pila:
    str r3, [r5], #4                @ Guardar el valor del argumento (r3) en R0 en la pila
    mov r6, #0                      @ Limpiar r6 para usarlo para inicializar la pila
    mov r7, #12                     @ Establecer r7 para 12 registros (R1-R12)
init_registros:
    cmp r7, #0                      @ Verificar si hemos inicializado todos los registros
    beq fin_init_registros          @ Si es así, salir del bucle
    str r6, [r5], #4                @ Guardar 0 en la pila y aumentar la dirección de la pila
    subs r7, r7, #1                 @ Decrementar el contador de registros
    b init_registros                @ Repetir
fin_init_registros:
    ldr r6, =_gp_terminarProc       @ Cargar la dirección de _gp_terminarProc en r6
    str r6, [r5], #4                @ Guardar la dirección de retorno en R14 en la pila

    @ Guardar el valor actual del registro SP y el valor inicial del registro CPSR en el PCB
    str r5, [r4, #8]               @ Guardar el valor de SP en el PCB
    mov r6, #0x1F                   @ Establecer el valor inicial de CPSR para el modo sistema
    str r6, [r4, #12]               @ Guardar el valor de CPSR en el PCB

    @ Inicializar otros campos del PCB
    mov r6, #0                      @ Limpiar r6 para usarlo para inicializar otros campos
    str r6, [r4, #20]               @ Inicializar el contador de tics de trabajo workTicks

    @ Guardar el número de zócalo en la cola de Ready e incrementar _gd_nReady
    ldr r4, =_gd_nReady             @ Cargar la dirección de _gd_nReady en r4
    ldrb r5, [r4]                   @ Cargar el valor de _gd_nReady en r5
    ldr r6, =_gd_qReady             @ Cargar la dirección de inicio de _gd_qReady en r6
    add r6, r6, r5                  @ Calcular la dirección de la última posición en _gd_qReady
    strb r1, [r6]                   @ Guardar el número de zócalo en _gd_qReady
    add r5, r5, #1                  @ Incrementar _gd_nReady
    strb r5, [r4]                   @ Guardar el nuevo valor en _gd_nReady

    @ Finalizar con éxito
    mov r0, #0                      @ Establecer r0 a 0 para indicar éxito
    pop {r4-r12, pc}                @ Restaurar registros y volver

error:
    mov r0, #1                      @ Devolver un error (podrías querer usar un valor diferente para indicar un error)
    pop {r4-r12, pc}                @ Restaurar registros y volver



	@; Rutina para terminar un proceso de usuario:
	@; pone a 0 el campo PID del PCB del zócalo actual, para indicar que esa
	@; entrada del vector _gd_pcbs está libre; también pone a 0 el PID de la
	@; variable _gd_pidz (sin modificar el número de zócalo), para que el código
	@; de multiplexación de procesos no salve el estado del proceso terminado.
_gp_terminarProc:
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + zócalo
	and r1, r1, #0xf		@; R1 = zócalo del proceso desbancado
	str r1, [r0]			@; guardar zócalo con PID = 0, para no salvar estado			
	ldr r2, =_gd_pcbs
	mov r10, #24
	mul r11, r1, r10
	add r2, r11				@; R2 = dirección base _gd_pcbs[zocalo]
	mov r3, #0
	str r3, [r2]			@; pone a 0 el campo PID del PCB del proceso
.LterminarProc_inf:
	bl _gp_WaitForVBlank	@; pausar procesador
	b .LterminarProc_inf	@; hasta asegurar el cambio de contexto
	
.end

