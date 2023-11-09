/*------------------------------------------------------------------------------

	"main.c" : fase 1 / programador M

	Programa de prueba de carga de un fichero ejecutable en formato ELF,
	pero sin multiplexaci�n de procesos ni utilizar llamadas a _gg_escribir().
------------------------------------------------------------------------------*/
#include <nds.h>

#include <garlic_system.h> // definici�n de funciones y variables de sistema

extern int *punixTime; // puntero a zona de memoria con el tiempo real

/* Inicializaciones generales del sistema Garlic */
//------------------------------------------------------------------------------
void inicializarSistema()
{
	_gg_iniGrafA();
	for (int v; v < 4; v++)
	{
		_gd_wbfs[v].pControl = 0;
	}

	_gd_seed = *punixTime; // inicializar semilla para n�meros aleatorios con
	_gd_seed <<= 16;	   // el valor de tiempo real UNIX, desplazado 16 bits

	if (!_gm_initFS())
	{
		GARLIC_printf("ERROR: �no se puede inicializar el sistema de ficheros!");
		exit(0);
	}

	irqInitHandler(_gp_IntrMain);	// instalar rutina principal interrupciones
	irqSet(IRQ_VBLANK, _gp_rsiVBL); // instalar RSI de vertical Blank
	irqEnable(IRQ_VBLANK);			// activar interrupciones de vertical Blank
	REG_IME = IME_ENABLE;			// activar las interrupciones en general

	_gd_pcbs[0].keyName = 0x4C524147; // "GARL"
	_gd_pcbs[0].maxQuantum = 1;
	_gd_pcbs[0].quantumRemaining = 1;
	_gd_totalQuantum += 1;
	_gd_quantumCounter += 1;
}

//------------------------------------------------------------------------------
int main(int argc, char **argv)
{
	//------------------------------------------------------------------------------
	intFunc start;
	inicializarSistema();

	GARLIC_printf("********************************");
	GARLIC_printf("*                              *");
	GARLIC_printf("* Sistema Operativo GARLIC 1.0 *");
	GARLIC_printf("*                              *");
	GARLIC_printf("********************************");
	GARLIC_printf("*** Inicio fase 1_M\n");

	GARLIC_printf("*** Carga de programa HOLA.elf\n");
	start = _gm_cargarPrograma("HOLA");
	if (start)
	{
		GARLIC_printf("*** Direccion de arranque :\n\t\t%d\n", (int)start);
		_gp_crearProc(start, 4, "HOLA", 2);
	}
	else
		GARLIC_printf("*** Programa \"HOLA\" NO cargado\n");

	GARLIC_printf("\n\n\n*** Carga de programa PRNT.elf\n");
	start = _gm_cargarPrograma("PRNT");
	if (start)
	{
		GARLIC_printf("*** Direccion de arranque :\n\t\t%d\n", (int)start);
		_gp_crearProc(start, 5, "PRNT", 3);
	}
	else
		GARLIC_printf("*** Programa \"PRNT\" NO cargado\n");

	GARLIC_printf("\n\n\n*** Carga de programa PRM1.elf\n");
	start = _gm_cargarPrograma("PRM1");
	if (start)
	{
		GARLIC_printf("*** Direccion de arranque :\n\t\t%d\n", (int)start);
		_gp_crearProc(start, 6, "PRM1", 2);
	}
	else
		GARLIC_printf("*** Programa \"PRM1\" NO cargado\n");

	GARLIC_printf("*** Final fase 1_M\n");

	while (1)
	{
		_gp_WaitForVBlank();
	}
	return 0;
}

/* Proceso de prueba */
//------------------------------------------------------------------------------
int hola(int arg)
{
	//------------------------------------------------------------------------------
	unsigned int i, j, iter;

	if (arg < 0)
		arg = 0; // limitar valor máximo y
	else if (arg > 3)
		arg = 3; // valor mínimo del argumento

	// esccribir mensaje inicial
	GARLIC_printf("-- Programa HOLA  -  PID (%d) --\n", GARLIC_pid());

	j = 1; // j = cálculo de 10 elevado a arg
	for (i = 0; i < arg; i++)
		j *= 10;
	// cálculo aleatorio del número de iteraciones 'iter'
	GARLIC_divmod(GARLIC_random(), j, &i, &iter);
	iter++; // asegurar que hay al menos una iteración

	for (i = 0; i < iter; i++) // escribir mensajes
		GARLIC_printf("(%d)\t%d: Hello world!\n", GARLIC_pid(), i);

	return 0;
}
