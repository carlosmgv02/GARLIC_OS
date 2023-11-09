/*------------------------------------------------------------------------------

	"garlic_system.h" : definiciones de las variables globales, funciones y
						rutinas del sistema operativo GARLIC (versi�n 1.0)

	Analista-programador: santiago.romani@urv.cat
	Programador P: xxx.xxx@estudiants.urv.cat
	Programador M: genis.martinez@estudiants.urv.cat
	Programador G: zzz.zzz@estudiants.urv.cat
	Programador T: uuu.uuu@estudiants.urv.cat

------------------------------------------------------------------------------*/
#ifndef _GARLIC_SYSTEM_h
#define _GARLIC_SYSTEM_h

//------------------------------------------------------------------------------
//	Variables globales del sistema (garlic_dtcm.s)
//------------------------------------------------------------------------------

extern int _gd_pidz; // Identificador de proceso (PID) + z�calo
					 // (PID en 28 bits altos, z�calo en 4 bits bajos,
					 // cero si se trata del propio sistema operativo)

extern int _gd_pidCount; // Contador de PIDs: se incrementa cada vez que
						 // se crea un nuevo proceso (max. 2^28)

extern int _gd_tickCount; // Contador de tics: se incrementa cada IRQ_VBL, y
						  // permite contabilizar el paso del tiempo

extern int _gd_seed; // Semilla para generaci�n de n�meros aleatorios
					 // (tiene que ser diferente de cero)

extern int _gd_nReady; // N�mero de procesos en cola de READY (de 0 a 15)

extern char _gd_qReady[16]; // Cola de READY (procesos preparados) : vector
							// ordenado con _gd_nReady entradas, conteniendo
							// los identificadores (0-15) de los z�calos de los
							// procesos (m�x. 15 procesos + sistema operativo)


typedef struct				// Estructura del bloque de control de un proceso
{							// (PCB: Process Control Block)
	int PID;				//	identificador del proceso (Process IDentifier)
	int PC;					//	contador de programa (Program Counter)
	int SP;					//	puntero al top de pila (Stack Pointer)
	int Status;				//	estado del procesador (CPSR)
	int keyName;			//	nombre en clave del proceso (cuatro chars)
	int workTicks;			//	contador de ciclos de trabajo (24 bits bajos)
	int maxQuantum;			//  Quantum asignado al proceso
	int quantumRemaining;	//	Quantum restante del proceso
							//		8 bits altos: uso de CPU (%)
} PACKED garlicPCB;

extern garlicPCB _gd_pcbs[16]; // vector con los PCBs de los procesos activos

typedef struct		 // Estructura del buffer de una ventana
{					 // (WBUF: Window BUFfer)
	int pControl;	 //	control de escritura en ventana
					 //		16 bits altos: n�mero de l�nea (0-23)
					 //		16 bits bajos: caracteres pendientes (0-32)
	char pChars[32]; //	vector de 32 caracteres pendientes de escritura
					 //		indicando el c�digo ASCII de cada posici�n
} PACKED garlicWBUF;

extern garlicWBUF _gd_wbfs[4]; // vector con los buffers de 4 ventanas

extern int _gd_stacks[15 * 128]; // vector con las pilas de los procesos activos

extern int _gd_totalQuantum;	// Suma de todos los quantum pariales

extern int _gd_quantumCounter;	// Contador de quantum


//------------------------------------------------------------------------------
//	Rutinas de gesti�n de procesos (garlic_itcm_proc.s)
//------------------------------------------------------------------------------

/* intFunc:		nuevo tipo de dato para representar puntero a funci�n que
				devuelve un int, concretamente, el puntero a la funci�n de
				inicio de los procesos cargados en memoria */
typedef int (*intFunc)(int);

/* _gp_WaitForVBlank:	sustituto de swiWaitForVBlank para procesos de Garlic */
extern void _gp_WaitForVBlank();

/* _gp_IntrMain:	manejador principal de interrupciones del sistema Garlic */
extern void _gp_IntrMain();

/* _gp_rsiVBL:	manejador de interrupciones VBL (Vertical BLank) de Garlic */
extern void _gp_rsiVBL();

/* _gp_numProc:	devuelve el n�mero de procesos cargados en el sistema,
				incluyendo el proceso en RUN y los procesos en READY */
extern int _gp_numProc();

/* _gp_crearProc:	prepara un proceso para ser ejecutado, creando su entorno
				de ejecuci�n y coloc�ndolo en la cola de READY;
	Par�metros:
		funcion	->	direcci�n de memoria de entrada al c�digo del proceso
		zocalo	->	identificador del z�calo (0 - 15)
		nombre	->	nombre en clave del programa (4 caracteres ASCII)
		arg		->	argumento del programa
	Resultado:	0 si no hay problema, >0 si no se puede crear el proceso
*/
extern int _gp_crearProc(intFunc funcion, int zocalo, char *nombre, int arg);

//------------------------------------------------------------------------------
//	Funciones de gesti�n de memoria (garlic_mem.c)
//------------------------------------------------------------------------------

/* _gm_initFS: inicializa el sistema de ficheros, devolviendo un valor booleano
					para indiciar si dicha inicializaci�n ha tenido �xito;
*/
extern int _gm_initFS();

/* _gm_cargarPrograma: busca un fichero de nombre "(keyName).elf" dentro del
					directorio "/Programas/" del sistema de ficheros, y
					carga los segmentos de programa a partir de una posici�n de
					memoria libre, efectuando la reubicaci�n de las referencias
					a los s�mbolos del programa, seg�n el desplazamiento del
					c�digo en la memoria destino;
	Par�metros:
		keyName ->	vector de 4 caracteres con el nombre en clave del programa
	Resultado:
		!= 0	->	direcci�n de inicio del programa (intFunc)
		== 0	->	no se ha podido cargar el programa
*/
extern intFunc _gm_cargarPrograma(char *keyName);

//------------------------------------------------------------------------------
//	Rutinas de soporte a la gesti�n de memoria (garlic_itcm_mem.s)
//------------------------------------------------------------------------------

/* _gm_reubicar: rutina de soporte a _gm_cargarPrograma(), que interpreta los
					'relocs' de un fichero ELF, contenido en un buffer *fileBuf,
					y ajustar las direcciones de memoria correspondientes a las
					referencias de tipo R_ARM_ABS32, restando la direcci�n de
					inicio de segmento (pAddr) y sumando la direcci�n de destino
					en la memoria (*dest) */
extern void _gm_reubicar(char *fileBuf, unsigned int pAddr, unsigned int *dest);

//------------------------------------------------------------------------------
//	Variables globales de gesti�n de memoria (garlic_mem.c)
//------------------------------------------------------------------------------

// VARIABLES GLOBALES PROG M

extern int _gm_first_mem_pos;

extern int quo;
extern int res;

// VARIABLES FUNCIONALIDAD ADICIONAL

typedef struct
{
	char *nombre;  // 4 bytes
	intFunc entry; // 4 bytes (direcci�n de memoria)
} Programa_Guardado;

extern Programa_Guardado programas_guardados[15];

extern unsigned int num_programas_guardados;

//------------------------------------------------------------------------------
//	Funciones de gesti�n de gr�ficos (garlic_graf.c)
//------------------------------------------------------------------------------

/* _gg_iniGraf: inicializa el procesador gr�fico A para GARLIC 1.0 */
extern void _gg_iniGrafA();

/* _gg_generarMarco: dibuja el marco de la ventana que se indica por par�metro*/
extern void _gg_generarMarco(int v);

/* _gg_escribir: escribe una cadena de caracteres en la ventana indicada;
	Par�metros:
		formato	->	cadena de formato, terminada con centinela '\0';
					admite '\n' (salto de l�nea), '\t' (tabulador, 4 espacios)
					y c�digos entre 32 y 159 (los 32 �ltimos son caracteres
					gr�ficos), adem�s de marcas de format %c, %d, %h y %s (max.
					2 marcas por cadena)
		val1	->	valor a sustituir en la primera marca de formato, si existe
		val2	->	valor a sustituir en la segunda marca de formato, si existe
					- los valores pueden ser un c�digo ASCII (%c), un valor
					  natural de 32 bits (%d, %x) o un puntero a string (%s)
		ventana	->	n�mero de ventana (de 0 a 3)
*/
extern void _gg_escribir(char *formato, unsigned int val1, unsigned int val2,
						 int ventana);

//------------------------------------------------------------------------------
//	Rutinas de soporte a la gesti�n de gr�ficos (garlic_itcm_graf.s)
//------------------------------------------------------------------------------

/* _gg_escribirLinea: rutina de soporte a _gg_escribir(), para escribir sobre la
					fila (f) de la ventana (v) los caracters pendientes (n) del
					buffer de ventana correspondiente.
*/
extern void _gg_escribirLinea(int v, int f, int n);

/* desplazar: rutina de soporte a _gg_escribir(), para desplazar una posici�n
					hacia arriba todas las filas de la ventana (v), y borrar el
					contenido de la �ltima fila.
*/
extern void _gg_desplazar(int v);

//------------------------------------------------------------------------------
//	Rutinas de soporte al sistema (garlic_itcm_sys.s)
//------------------------------------------------------------------------------

/* _gs_num2str_dec: convierte el n�mero pasado por valor en el par�metro num
					a una representaci�n en c�digos ASCII de los d�gitos
					decimales correspondientes, escritos dentro del vector de
					caracteres numstr, que se pasa por referencia; el par�metro
					length indicar� la longitud del vector; la rutina coloca un
					caracter centinela (cero) en la �ltima posici�n del vector
					(numstr[length-1]) y, a partir de la pen�ltima posici�n,
					empieza a colocar los c�digos ASCII correspondientes a las
					unidades, decenas, centenas, etc.; en el caso que despu�s de
					trancribir todo el n�mero queden posiciones libres en el
					vector, la rutina rellenar� dichas posiciones con espacios
					en blanco, y devolver� un cero; en el caso que NO hayan
					suficientes posiciones para transcribir todo el n�mero, la
					funci�n abandonar� el proceso y devolver� un valor diferente
					de cero.
		ATENCI�N:	solo procesa n�meros naturales de 32 bits SIN signo. */
extern int _gs_num2str_dec(char *numstr, unsigned int length, unsigned int num);

/* _gs_num2str_hex:	convierte el par�metro num en una representaci�n en c�digos
					ASCII sobre el vector de caracteres numstr, en base 16
					(hexa), siguiendo las mismas reglas de gesti�n del espacio
					del string que _gs_num2str_dec, salvo que las posiciones de
					m�s peso vac�as se rellenar�n con ceros, no con espacios en
					blanco */
extern int _gs_num2str_hex(char *numstr, unsigned int length, unsigned int num);

/* _gs_copiaMem: copia un bloque de numBytes bytes, desde una posici�n de
				memoria inicial (*source) a partir de otra posici�n de memoria
				destino (*dest), teniendo en cuenta que ambas posiciones de
				memoria deben estar alineadas a word */
extern void _gs_copiaMem(const void *source, void *dest, unsigned int numBytes);

#endif // _GARLIC_SYSTEM_h
