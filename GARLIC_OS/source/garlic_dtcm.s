@;==============================================================================
@;
@;	"garlic_dtcm.s":	zona de datos b�sicos del sistema GARLIC 1.0
@;						(ver "garlic_system.h" para descripci�n de variables)
@;
@;==============================================================================

.section .dtcm,"wa",%progbits

	.align 2

	.global _gd_pidz			@; Identificador de proceso + z�calo actual
_gd_pidz:	.word 0

	.global _gd_pidCount		@; Contador global de PIDs
_gd_pidCount:	.word 0

	.global _gd_tickCount		@; Contador global de tics
_gd_tickCount:	.word 0

	.global _gd_seed			@; Semilla para generaci�n de n�meros aleatorios
_gd_seed:	.word 0xFFFFFFFF

	.global _gd_nReady			@; N�mero de procesos en la cola de READY
_gd_nReady:	.word 0

	.global _gd_qReady			@; Cola de READY (procesos preparados)
_gd_qReady:	.space 16

	.global _gd_pcbs			@; Vector de PCBs de los procesos activos
_gd_pcbs:	.space 16 * 8 * 4	@; Añadimos posición de número de quantum de cada proceso y los quantum restantes

	.global _gd_wbfs			@; Vector de WBUFs de las ventanas disponibles
_gd_wbfs:	.space 4 * (4 + 32)

	.global _gd_stacks			@; Vector de pilas de los procesos activos
_gd_stacks:	.space 15 * 128 * 4

.end

