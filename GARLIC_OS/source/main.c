/*------------------------------------------------------------------------------

	"main.c" : fase 1 / programador P

	Programa de prueba de creación y multiplexación de procesos en GARLIC 1.0,
	pero sin cargar procesos en memoria ni utilizar llamadas a _gg_escribir().

------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdio.h>

#include <garlic_system.h>	// definición de funciones y variables de sistema

#include <GARLIC_API.h>		// inclusión del API para simular un proceso
int hola(int);				// función que simula la ejecución del proceso
int proces_amb_nice(int);

extern int * punixTime;		// puntero a zona de memoria con el tiempo real


/* Inicializaciones generales del sistema Garlic */
//------------------------------------------------------------------------------
void inicializarSistema() {
//------------------------------------------------------------------------------

	consoleDemoInit();		// inicializar consola, sólo para esta simulación
	
	_gd_seed = *punixTime;	// inicializar semilla para números aleatorios con
	_gd_seed <<= 16;		// el valor de tiempo real UNIX, desplazado 16 bits
	
	irqInitHandler(_gp_IntrMain);	// instalar rutina principal interrupciones
	irqSet(IRQ_VBLANK, _gp_rsiVBL);	// instalar RSI de vertical Blank
	irqEnable(IRQ_VBLANK);			// activar interrupciones de vertical Blank
	REG_IME = IME_ENABLE;			// activar las interrupciones en general
	
	_gd_pcbs[0].keyName = 0x4C524147;	// "GARL"
	_gd_pcbs[0].maxQuantum = 1;
	_gd_pcbs[0].quantumRemaining = 1;
	_gd_totalQuantum += 1;
	_gd_quantumCounter += 1;
}


//------------------------------------------------------------------------------
int main(int argc, char **argv) {
//------------------------------------------------------------------------------
	
	inicializarSistema();
	
	printf("********************************");
	printf("*                              *");
	printf("* Sistema Operativo GARLIC 1.0 *");
	printf("*                              *");
	printf("********************************");
	printf("*** Inicio fase 1_P\n");
	
	_gp_crearProc(hola, 7, "HOLA", 2);
	_gp_crearProc(proces_amb_nice, 14, "nice", 2);

	while (1)
	{
		_gp_WaitForVBlank();
	}							// parar el procesador en un bucle infinito
	return 0;
}


/* Proceso de prueba, con llamadas a las funciones del API del sistema Garlic */
//------------------------------------------------------------------------------
int hola(int arg) {
//------------------------------------------------------------------------------
	unsigned int i, j, iter;
	
	if (arg < 0) arg = 0;			// limitar valor máximo y 
	else if (arg > 3) arg = 3;		// valor mínimo del argumento	
	j = 1;							// j = cálculo de 10 elevado a arg
	for (i = 0; i < arg; i++)
		j *= 10;
						// cálculo aleatorio del número de iteraciones 'iter'
	GARLIC_divmod(GARLIC_random(), j, &i, &iter);
	iter++;							// asegurar que hay al menos una iteración
	_gp_WaitForVBlank();
	for (i = 0; i < iter; i++) {		// escribir mensajes
		_gp_WaitForVBlank();
		GARLIC_printf("(%d)\t%d: Hello world!\n", GARLIC_pid(), i);
	}
	return 0;
}

int proces_amb_nice(int arg) {
	_ga_nice(0);
	_gp_WaitForVBlank();
	for (int i = 0; i < 1000; i++) {
		_gp_WaitForVBlank();
		GARLIC_printf("(%d)\t%d: Nice!\n", GARLIC_pid(), i);
	}
	return 0;
}
