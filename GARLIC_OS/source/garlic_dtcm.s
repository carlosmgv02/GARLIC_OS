@;==============================================================================
@;
@;	"garlic_dtcm.s":	zona de datos bï¿½sicos del sistema GARLIC 2.0
@;						(ver "garlic_system.h" para descripciï¿½n de variables)
@;
@;==============================================================================

.section .dtcm,"wa",%progbits

	.align 2

	.global _gd_pidz			@; Identificador de proceso + zï¿½calo actual
_gd_pidz:	.word 0

	.global _gd_pidCount		@; Contador global de PIDs
_gd_pidCount:	.word 0

	.global _gd_tickCount		@; Contador global de tics
_gd_tickCount:	.word 0

	.global _gd_sincMain		@; Sincronismos con programa principal
_gd_sincMain:	.word 0

	.global _gd_seed			@; Semilla para generaciï¿½n de nï¿½meros aleatorios
_gd_seed:	.word 0xFFFFFFFF

	.global _gd_nReady			@; Nï¿½mero de procesos en la cola de READY
_gd_nReady:	.word 0

	.global _gd_qReady			@; Cola de READY (procesos preparados)
_gd_qReady:	.space 16

	.global _gd_pcbs			@; Vector de PCBs de los procesos activos
_gd_pcbs:	.space 16 * 8 * 4	@; AÃ±adimos posiciÃ³n de nÃºmero de quantum de cada proceso y los quantum restantes



	.global _gd_stacks			@; Vector de pilas de los procesos activos
_gd_stacks:	.space 15 * 128 * 4
	
	.global _gd_totalQuantum	@; Suma de todos los quantum parciales
_gd_totalQuantum: .word 0

	.global _gd_quantumCounter  @; Contador total de quantums
_gd_quantumCounter: .word 0
	
	@; VARIABLES GLOBALES PROGM
	
	.global _gm_first_mem_pos	@; Primera posiciÃ¯Â¿Â½n libre de la memoria
_gm_first_mem_pos: .word 0x01002000	

	.global quo
quo:	.space 4

	.global res
res:    .space 4	

	.global programas_guardados
programas_guardados:    .space (4 + 4) * 15	

	.global num_programas_guardados
num_programas_guardados:	.space 4


	.global _gd_nDelay			@; Nï¿½mero de procesos en la cola de DELAY
_gd_nDelay:	.word 0

	.global _gd_qDelay			@; Cola de DELAY (procesos retardados)
_gd_qDelay:	.space 16 * 4


	.global _gd_wbfs			@; Vector de WBUFs de las ventanas disponibles
_gd_wbfs:	.space 16 * (4 + 64)



.end