@;==============================================================================
@;
@;	"garlic_itcm_proc.s":	c�digo de las funciones de control de procesos (2.0)
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
	ldr r4, =_gd_tickCount
	ldr r5, [r4]			@; R5 = _gd_tickcount
	add r5, #1
	str r5, [r4]			@; [_gd_tickCount] = R5+++

	@; Seccion quantum
	ldr r4, =_gd_pidz
	ldr r5, [r4]			@; R1 = valor actual de PID + z�calo
	and r5, r5, #0xf		@; R1 = z�calo del proceso desbancado
	ldr r6, =_gd_pcbs
	add r6, r6, r5, lsl #5
	ldr r7, [r6, #28]		@; Miramos campo quantumRemaining
	cmp r7, #0				@; Si no es cero restamos y salimos
	bne .LrestarQuantum
	ldr r5, =_gd_quantumCounter
	ldr r4, [r5]
	cmp r4, #0				@; Si el quantum es cero y el contador total de quantum es 0, salvamos el proceso y reseteamos quantum
	bne .Lcontinue
	
	mov r4, #0                  @; Inicializar el contador a 0
	mov r7, #0					@; contador de quantums total
	.Lbucle:
	cmp r4, #15                @ ;Comparar el contador con 15
	ldr r6, =_gd_pcbs          @; Cargar la dirección base de _gd_pcbs
	beq .LsetQuantum            @; Si es igual, saltar a .Lcontinue
	add r5, r6, r4, lsl #5     @; Calcular la dirección del registro actual una sola vez
	ldr r6, [r5, #24]          @; Cargar el valor desde el desplazamiento 24 del registro actual
	add	r7, r6				   @; Acumular quantum
	str r6, [r5, #28]           @; Guardar en el desplazamiento 28 del registro actual (desplazamiento 4 desde r5)
	add r4, #1                 @; Incrementar el contador
	b .Lbucle                  @; Volver al inicio del bucle
	

.LrestarQuantum:
	ldr r5, =_gd_quantumCounter
	ldr r4, [r5]
	sub r4, #1
	sub r7, #1
	str r7, [r6, #28]
	str r4, [r5]
	b .Lfin
	
.LsetQuantum:
	ldr r5, =_gd_quantumCounter
	str r7, [r5]
.Lcontinue:
	ldr r4, =_gd_nReady
	ldr r5, [r4]			@; R5 = [_gd_nReady]
	cmp r5, #0				@; Comprobamos si hay procesos en la cola READY
	beq .Lfin
	ldr r6, =_gd_pidz
	ldr r7, [r6]			@; R7 = [_gd_pidz]
	cmp r7, #0				@; si PID==0 i zocalo==0 => S.O.
	beq .LsalvarProc
	mov r7, r7, lsr #4		@; ignoramos los bits bajos del zocalo
	cmp r7, #0
	beq .LrestaurarProc		@; si el proceso termina no guardamos el contexto
.LsalvarProc:
	bl _gp_salvarProc
.LrestaurarProc:
	bl _gp_restaurarProc
.Lfin:
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

    @; Obtener el n�mero de z�calo del proceso a desbancar
    ldr r8, [r6]
    and r8, r8, #0xF  			@; Aislar el n�mero de z�calo

    @; Guardar el n�mero de z�calo del proceso a desbancar en la �ltima posici�n de la cola de Ready
    ldr r9, =_gd_qReady
	strb r8, [r9, r5]

    @; Guardar el valor del R15 del proceso a desbancar en el campo PC del elemento _gd_pcbs[z]
	ldr r11, =_gd_pcbs
	add r11, r11, r8, lsl #5    @; Sumar al puntero base para obtener la direcci�n del PCB  
    ldr r9, [r13, #60]   		@; El valor m�s bajo en la pila de interrupciones
	str r9, [r11, #4]  			@; Guardar PC

    @; Guardar el valor del CPSR del proceso a desbancar en el campo Status del elemento _gd_pcbs[z]
    mrs r8, SPSR
    str r8, [r11, #12] 			@; Guardar Status
	and r9, r8, #0x1F			@; recupera el mode del proc�s (System t�picament)
	mov r10, r13				@; Guardar el SP_irq

    @; Cambiar al modo de ejecuci�n del proceso interrumpido y apilar los valores de los registros en la pila de usuario
	mrs r8, CPSR
	bic r8, r8, #0x1F    		@; Limpiar los bits de modo (los 5 bits m�s bajos)
	orr r8, r9    				@; Establecer los bits de modo a Sistema (0b11111)
	msr CPSR, r8         		@; Escribir de nuevo el valor modificado al CPSR
	
    @; Apilar el valor de los registros R0-R12 + R14 del proceso a desbancar en su propia pila
	push {r14}
	
	ldr r8, [r10, #56]
	push {r8}
	
	ldr r8, [r10, #12]
	push {r8}
	
	ldr r8, [r10, #8]
	push {r8}
	
	ldr r8, [r10, #4]
	push {r8}
	
	ldr r8, [r10]
	push {r8}
	
	ldr r8, [r10, #32]
	push {r8}
	
	ldr r8, [r10, #28]
	push {r8}
	
	ldr r8, [r10, #24]
	push {r8}
	
	ldr r8, [r10, #20]
	push {r8}
	
	ldr r8, [r10, #52]
	push {r8}
	
	ldr r8, [r10, #48]
	push {r8}
	
	ldr r8, [r10, #44]
	push {r8}
	
	ldr r8, [r10, #40]
	push {r8}
	
    @; Guardar el valor del registro R13 del proceso a desbancar en el campo SP del elemento _gd_pcbs[z]
    str r13, [r11, #8]  			@; Guardar SP

    @; Volver al modo de ejecuci�n IRQ y retornar de _gp_salvarProc()
    mrs r9, CPSR         		@; Leer el valor actual del CPSR en r9
	bic r9, r9, #0x1F   		@; Limpiar los bits de modo (los 5 bits m�s bajos)
	orr r9, r9, #0x12   		@; Establecer los bits de modo a IRQ (0b10010)
	msr CPSR, r9        		@; Escribir de nuevo el valor modificado al CPSR
	add r5, #1					@; nReady++
	
    pop {r8-r11, pc}  			@; Retornar



	@; Rutina para restaurar el estado del siguiente proceso en la cola de READY
	@;Par�metros
	@; R4: direcci�n _gd_nReady
	@; R5: n�mero de procesos en READY
	@; R6: direcci�n _gd_pidz
_gp_restaurarProc:
    push {r8-r11, lr}

    @; Recuperar el n�mero de z�calo del proceso a restaurar de la primera posici�n de la cola de Ready
    ldr r8, =_gd_qReady
    ldrb r9, [r8]			@; r9 = num zocalo
    mov r10, #1

.Lcola:
	cmp r10, r5
	beq .LfinCola
	ldrb r11, [r8, r10]
	sub r10, #1
	strb r11, [r8, r10]		@; desplazamos el siguiente elemento de la cola a la izquierda
	add r10, #2				@; siguiente elemento
	b .Lcola

.LfinCola:

    @; Recuperar el valor del R15 anterior del proceso a restaurar y copiarlo en la posici�n correspondiente de pila del modo IRQ
    ldr r8, =_gd_pcbs
    add r10, r8, r9, lsl #5
	ldr r8, [r10] 			@; R8 = PID
	orr r8, r9, r8, lsl #4	@; Combinamos el PID con el número de zocalo
	str r8, [r6]

    ldr r8, [r10, #4]
    str r8, [sp, #60]

    @; Recuperar el CPSR del proceso a restaurar
    ldr r8, [r10, #12]
    msr SPSR, r8
	mov r11, sp

    @; Cambiar al modo de ejecuci�n del proceso a restaurar y desapilar los valores de los registros de la pila del modo IRQ
    mrs r9, CPSR
    bic r9, r9, #0x1F
	orr r9, #0x1F
	and r8, #0x1F
    orr r9, r8
    msr CPSR, r9

    @; Recuperar el valor del registro R13 del proceso a restaurar
    ldr sp, [r10, #8]
	
	@; Desapilar el valor de los registros R0-R12 + R14 de la pila del proceso a restaurar
	pop {r8}
	str r8, [r11, #40]
	
	pop {r8}
	str r8, [r11, #44]
	
	pop {r8}
	str r8, [r11, #48]
	
	pop {r8}
	str r8, [r11, #52]
	
	pop {r8}
	str r8, [r11, #20]
	
	pop {r8}
	str r8, [r11, #24]
	
	pop {r8}
	str r8, [r11, #28]
	
	pop {r8}
	str r8, [r11, #32]
	
	pop {r8}
	str r8, [r11]
	
	pop {r8}
	str r8, [r11, #4]
	
	pop {r8}
	str r8, [r11, #8]
	
	pop {r8}
	str r8, [r11, #12]
	
	pop {r8}
	str r8, [r11, #56]
	
	pop {r14}

    @; Volver al modo de ejecuci�n IRQ y retornar de _gp_restaurarProc()
    mrs r9, CPSR
    bic r9, r9, #0x1F
    orr r9, r9, #0x12
    msr CPSR, r9
	sub r5, #1				@; nReady--
	str r5, [r4]

	
    pop {r8-r11, pc}
	

	.global _gp_numProc
	@;Resultado
	@; R0: n�mero de procesos total
_gp_numProc:
	push {r1-r2, lr}
	mov r0, #1				@; contar siempre 1 proceso en RUN
	ldr r1, =_gd_nReady
	ldr r2, [r1]			@; R2 = n�mero de procesos en cola de READY
	add r0, r2				@; a�adir procesos en READY
	pop {r1-r2, pc}


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
    push {r4-r8, lr}               @; Guardar registros y lr en la pila

    @; Rechazar la llamada si el z�calo es 0 o si el z�calo ya est� ocupado
    cmp r1, #0                      @; Comparar z�calo con 0
	moveq r0, #1					@; Retornar codigo > 1 si da error
    beq .Lerror                     @; Si z�calo es 0, ir a error
    ldr r4, =_gd_pcbs               @; Cargar la direcci�n de inicio de _gd_pcbs en r4
	add r4, r4, r1, lsl #5			@; r4 dirrecion de memoria pid[z]
    ldr r5, [r4]       				@; Cargar el PID del z�calo en r5

	@; Parte quantum
	mov r6, #1 						@; Comenzamos con 3 de amabilidad
	str r6, [r4, #24]				@; Guardamos en el campo de maxquantum
	str r6, [r4, #28]				@; Guardamos en el campo quantumRemaining
	ldr r6, =_gd_totalQuantum
	ldr r7, [r6]
	add r7, #1						@; Sumamos al quantum total 1
	str r7, [r6]					
	ldr r6, =_gd_quantumCounter		@; Guardamos quantum total en quantum counter
	str r7, [r6]

    cmp r5, #0                      @; Comparar PID con 0
	movne r0, #1					@; Retornar codigo > 1 si da error
    bne .Lerror                       @; Si PID no es 0, ir a error

    @; Obtener un PID para el nuevo proceso
    ldr r6, =_gd_pidCount           @; Cargar la direcci�n de _gd_pidCount en r4
    ldr r7, [r6]                    @; Cargar el valor de _gd_pidCount en r5
    add r7, r7, #1                  @; Incrementar _gd_pidCount
    str r7, [r6]                    @; Guardar el nuevo valor en _gd_pidCount

    @; Guardar PID, direcci�n de la rutina inicial y nombre en clave en el PCB
    str r7, [r4]                    @; Guardar el PID en el PCB
    add r0, r0, #4                  @; Sumar 4 a la direcci�n de la rutina
    str r0, [r4, #4]                @; Guardarla en el campo PC del PCB
	ldr r6, [r2]                    @; Cargar el valor de keyname en r6
    str r6, [r4, #16]               @; Guardar el nombre en clave en el campo keyName

    @; Calcular la direcci�n base de la pila del proceso y guardar valores iniciales
    ldr r5, =_gd_stacks             @; Cargar la direcci�n de inicio de _gd_stacks en r5
	mov r6, #128                    @; Copiar el valor del z�calo en r6
    mul r6, r1, r6                  @; Calcular el desplazamiento para el z�calo espec�fico
    add r5, r5, r6, lsl #2          @; Calcular la direcci�n base de la pila
    mov r6, #0                      @; Limpiar r6 para usarlo para inicializar la pila
	ldr r7, =_gp_terminarProc       @; Cargar la direcci�n de _gp_terminarProc
	str r7, [r5, #-4] 				@; Establecer r7 para 13 registros
	mov r8, #-8
.Lpila:
    cmp r8, #-56	                @; Guardar el valor del argumento (r3) en R0 en la pila
	beq .LfinPila
    str r6, [r5, r8]				@; Guardar 0 en la pila
	sub r8, #4						@; Desplazamos una posición
	b .Lpila
.LfinPila:
	sub r5, #56						@; Poner el sp al top de la pila
	str r3, [r5]					@; Apilamos el argumento donde apuntar el sp
	str r5, [r4, #8]
    @; Guardar el valor actual del registro SP y el valor inicial del registro CPSR en el PCB
	mov r6, #0x1F
    str r6, [r4, #12]               @; Guardar el valor de CPSR en el PCB

    @; Inicializar otros campos del PCB
    mov r6, #0                      @; Limpiar r6 para usarlo para inicializar otros campos
    str r6, [r4, #20]               @; Inicializar el contador de tics de trabajo workTicks

    @; Guardar el n�mero de z�calo en la cola de Ready e incrementar _gd_nReady
    ldr r4, =_gd_nReady             @; Cargar la direcci�n de _gd_nReady en r4
    ldr r5, [r4]                    @; Cargar el valor de _gd_nReady en r5
    ldr r6, =_gd_qReady             @; Cargar la direcci�n de inicio de _gd_qReady en r6
	strb r1, [r6, r5]				@; Guardar zocalo en la cola (_gd_qReady + nReady)
	add r5, #1						@; nReady++
	str r5, [r4]

    @; Finalizar con �xito
    mov r0, #0                      @; Establecer r0 a 0 para indicar �xito
.Lerror:
    pop {r4-r8, pc}                	@; Restaurar registros y volver



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
	mov r10, #32
	mul r11, r1, r10
	add r2, r11				@; R2 = direcci�n base _gd_pcbs[zocalo]
	mov r3, #0
	str r3, [r2]			@; pone a 0 el campo PID del PCB del proceso
	str r3, [r2, #24]		@; pone a 0 el campo maxQuantum
	str r3, [r2, #28]		@; pone a 0 el campo quantumRemaining
	str r3, [r2, #20]		@; borrar porcentaje de USO de la CPU
	ldr r0, =_gd_sincMain
	ldr r2, [r0]			@; R2 = valor actual de la variable de sincronismo
	mov r3, #1
	mov r3, r3, lsl r1		@; R3 = m�scara con bit correspondiente al z�calo
	orr r2, r3
	str r2, [r0]			@; actualizar variable de sincronismo
	
.LterminarProc_inf:
	bl _gp_WaitForVBlank	@; pausar procesador
	b .LterminarProc_inf	@; hasta asegurar el cambio de contexto



	.global _gp_actualizarDelay
	@; Rutina para actualizar la cola de procesos retardados, 
	@; poniendo en cola de READY aquellos cuyo número de tics
	@; de retardo sea 0
_gp_actualizarDelay:
	push {lr}
	ldr r0, =_gd_nDelay
	ldr r1, =_gd_qDelay
	ldr r2, [r1]
.LforDelay:
	cmp r2, #0						@; Mientras nDelay > 0
	ble .LfinDelay
	sub r2, #1
	ldr r3, [r1, r2, lsl #2]		@; qDelay[actual * 4]
	sub r3, #1
	cmp r3, #0						@; Comprobamos si tics == 0
	beq .LponerReady
	str r3, [r1, r2, lsl #2]		@; Sino guardar en qDelay
	b .LforDelay
.LponerReady:						@; Si tics == 0
	ldr r4, =_gd_nReady				@; r4 = _gd_nReady
	ldr r5, =_gd_qReady				@; r5 = _gd_qReady
	ldr r6, [r4]					
	lsr r3, #24						@; Sacamos el num zocalo
	strb r3, [r5, r6]				@; Guardamos en qReady[nReady] zocalo
	add r6, #1						@; nReady++
	str r6, [r4]
	cmp r2, #0						@; Miramos si nDelay > 0 y repetimos el bucle de nuevo
	bhi .LforDelay
.LfinDelay:
	pop {pc}

	


	.global _gp_matarProc
	@; Rutina para destruir un proceso de usuario:
	@; borra el PID del PCB del z�calo referenciado por par�metro, para indicar
	@; que esa entrada del vector _gd_pcbs est� libre; elimina el �ndice de
	@; z�calo de la cola de READY o de la cola de DELAY, est� donde est�;
	@; Par�metros:
	@;	R0:	z�calo del proceso a matar (entre 1 y 15).
_gp_matarProc:
	push {lr} 


	pop {pc}

	
	.global _gp_retardarProc
	@; retarda la ejecuci�n de un proceso durante cierto n�mero de segundos,
	@; coloc�ndolo en la cola de DELAY
	@;Par�metros
	@; R0: int nsec
_gp_retardarProc:
	push {r1-r4, lr}
	mov r1, #60
	mul r0, r1					@; Calculamos ntics = segundos * 60
	ldr r1, =_gd_pidz
	ldr r2, [r1]				@; R2 = pid + zocalo
	orr r2, 0x80000000			@; bit mas alto de R2 a 1 para no poner proceso en RDY
	str r2, [r1]
	and r2, #0xf				@; R2 = zocalo
	orr r0, r2, lsl #24			@; R0 = 8 bits altos num zocalo + 16 bits bajos ntics
	ldr r4, =_gd_nDelay
	ldr r2, [r4]
	ldr r1, =_gd_qDelay
	str r0, [r1, r2, lsl #2]	@; _gd_qDelay[nDelay*4bytes] = R0 (zocalo + tics)
	add r2, #1					@; nDelay++
	str r2, [r4]
	bl _gp_WaitForVBlank
	pop {r1-r4, pc}




	.global _gp_inihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 0, para inhibir todas
	@; las IRQs y evitar as� posibles problemas debidos al cambio de contexto
_gp_inhibirIRQs:
	push {lr}


	pop {pc}


	.global _gp_desinihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 1, para desinhibir todas
	@; las IRQs
_gp_desinhibirIRQs:
	push {lr}


	pop {pc}


	.global _gp_rsiTIMER0
	@; Rutina de Servicio de Interrupci�n (RSI) para contabilizar los tics
	@; de trabajo de cada proceso: suma los tics de todos los procesos y calcula
	@; el porcentaje de uso de la CPU, que se guarda en los 8 bits altos de la
	@; entrada _gd_pcbs[z].workTicks de cada proceso (z) y, si el procesador
	@; gr�fico secundario est� correctamente configurado, se imprime en la
	@; columna correspondiente de la tabla de procesos.
_gp_rsiTIMER0:
	push {lr}

	
	pop {pc}
.end

