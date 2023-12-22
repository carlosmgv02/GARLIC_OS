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
	// GARLIC_printf("* Sistema Operativo GARLIC 1.0 *");
	GARLIC_printf("*                              *");
	GARLIC_printf("********************************");
	// GARLIC_printf("*** Inicio fase 1_M\n");

	GARLIC_printf("\n\n\n*** Carga de programa CDIA.elf\n");
	start = _gm_cargarPrograma("CDIA");
	if (start)
	{
		// GARLIC_printf("*** Direccion de arranque :\n\t\t%d\n", (int)start);
		_gp_crearProc(start, 6, "CDIA", 3);
	}
	else
		GARLIC_printf("*** Programa \"CDIA\" NO cargado\n");
	/*
	GARLIC_printf("*** Carga de programa HOLA.elf\n");
	start = _gm_cargarPrograma("HOLA");
	if (start)
	{
		GARLIC_printf("*** Direccion de arranque :\n\t\t%d\n", (int)start);
		_gp_crearProc(start, 5, "HOLA", 2);
	}
	else
		GARLIC_printf("*** Programa \"HOLA\" NO cargado\n");

	GARLIC_printf("\n\n\n*** Carga de programa PRM1.elf\n");
	start = _gm_cargarPrograma("PRM1");
	if (start)
	{
		GARLIC_printf("*** Direccion de arranque :\n\t\t%d\n", (int)start);
		_gp_crearProc(start, 7, "PRM1", 2);
	}
	else
		GARLIC_printf("*** Programa \"PRM1\" NO cargado\n");
*/
	while (1)
	{
		_gp_WaitForVBlank();
	}
	return 0;
}
