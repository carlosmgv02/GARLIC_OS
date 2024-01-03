/*------------------------------------------------------------------------------

    "garlic_system.h" : definiciones de las variables globales, funciones y
                        rutinas del sistema operativo GARLIC (versi�n 2.0)

    Analista-programador: santiago.romani@urv.cat
    Programador P: javier.bertomeu@estudiants.urv.cat
    Programador M: genis.martinez@estudiants.urv.cat
    Programador G: carlos.martinezg@estudiants.urv.cat
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

extern int _gd_sincMain; // Sincronismos con programa principal:
                         // bit 0 = 1 indica si se ha acabado de calcular el
                         // 				el uso de la CPU,
                         // bits 1-15 = 1 indica si el proceso del z�calo
                         //				correspondiente ha terminado.

extern int _gd_seed; // Semilla para generaci�n de n�meros aleatorios
                     // (tiene que ser diferente de cero)

extern int _gd_nReady; // N�mero de procesos en cola de READY (de 0 a 15)

extern char _gd_qReady[16]; // Cola de READY (procesos preparados) : vector
                            // ordenado con _gd_nReady entradas, conteniendo
                            // los identificadores (0-15) de los z�calos de los
                            // procesos (m�x. 15 procesos + sistema operativo)

extern int _gd_nDelay; // N�mero de procesos en cola de DELAY (de 0 a 15)

extern int _gd_qDelay[16]; // Cola de DELAY (procesos retardados) : vector
                           // con _gd_nDelay entradas, conteniendo los
                           // identificadores de los z�calos (8 bits altos)
                           // m�s el n�mero de tics restantes (16 bits bajos)
                           // para desbloquear el proceso

typedef struct            // Estructura del bloque de control de un proceso
{                         // (PCB: Process Control Block)
    int PID;              //	identificador del proceso (Process IDentifier)
    int PC;               //	contador de programa (Program Counter)
    int SP;               //	puntero al top de pila (Stack Pointer)
    int Status;           //	estado del procesador (CPSR)
    int keyName;          //	nombre en clave del proceso (cuatro chars)
    int workTicks;        //	contador de ciclos de trabajo (24 bits bajos)
    int maxQuantum;       //  Quantum asignado al proceso
    int quantumRemaining; //	Quantum restante del proceso
                          //		8 bits altos: uso de CPU (%)
} PACKED garlicPCB;

extern garlicPCB _gd_pcbs[16]; // vector con los PCBs de los procesos activos

typedef struct        // Estructura del buffer de una ventana
{                     // (WBUF: Window BUFfer)
    int pControl;     //	control de escritura en ventana
                      //		4 bits altos: código de color actual (0-3)
                      //		12 bits medios: número de línea (0-23)
                      //		16 bits bajos: caracteres pendientes (0-32)
    short pChars[32]; //	vector de 32 caracteres pendientes de escritura
                      //		16 bits por entrada, indicando número de
                      //		baldosa correspondiente al caracter+color
} PACKED garlicWBUF;
typedef int Q12;

extern garlicWBUF _gd_wbfs[16]; // vector con los buffers de 16 ventanas

extern int _gd_stacks[15 * 128]; // vector con las pilas de los procesos activos

extern int _gd_quantumCounter; // Contador de quantum
extern int _gd_totalQuantum;   // Suma de todos los quantum pariales

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
                incluyendo el proceso en RUN, los procesos en READY y
                los procesos bloqueados */
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

/* _gp_retardarProc:	retarda la ejecuci�n del proceso actual durante el
                n�mero de segundos que se especifica por par�metro,
                coloc�ndolo en el vector de DELAY;
    Par�metros:
        nsec ->	n�mero de segundos (max. 600); si se especifica 0, el proceso
                solo se desbanca y el retardo ser� el tiempo que tarde en ser
                restaurado (depende del n�mero de procesos activos del sistema)
    ATENCI�N:
                �el proceso del sistema operativo (PIDz = 0) NO podr� utilizar
                esta funci�n, para evitar que el procesador se pueda quedar sin
                procesos a ejecutar!
*/
extern int _gp_retardarProc(int nsec);

/* _gp_matarProc:	elimina un proceso de las colas de READY o DELAY, seg�n
                donde se encuentre, libera memoria y borra el PID de la
                estructura _gd_pcbs[zocalo] correspondiente al z�calo que se
                pasa por par�metro;
    ATENCI�N:	Esta funci�n solo la llamar� el sistema operativo, por lo tanto,
                no ser� necesario realizar comprobaciones del par�metro; por
                otro lado, el proceso del sistema operativo (zocalo = 0) �NO se
                tendr� que destruir a s� mismo!
*/
extern int _gp_matarProc(int zocalo);

/* _gp_rsiTIMER0:	manejador de interrupciones del TIMER0 de la plataforma NDS,
                que refrescar� peri�dicamente la informaci�n de la tabla de
                procesos relativa al tanto por ciento de uso de la CPU */
extern void _gp_rsiTIMER0();

//------------------------------------------------------------------------------
//	Funciones de gesti�n de memoria (garlic_mem.c)
//------------------------------------------------------------------------------

/* _gm_initFS: inicializa el sistema de ficheros, devolviendo un valor booleano
                    para indiciar si dicha inicializaci�n ha tenido �xito;
*/
extern int _gm_initFS();

/* _gm_listaProgs: devuelve una lista con los nombres en clave de todos
                los programas que se encuentran en el directorio "Programas".
                Se considera que un fichero es un programa si su nombre tiene
                8 caracteres y termina con ".elf"; se devuelven solo los
                4 primeros caracteres del nombre del fichero (nombre en clave),
                que por convenio deben estar en may�sculas.
                El resultado es un vector de strings (paso por referencia) y
                el n�mero de programas detectados */
extern int _gm_listaProgs(char *progs[]);

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
// VARIABLES GLOBALES PROG M

extern int _gm_first_mem_pos;

extern int quo;
extern int res;

// VARIABLES FUNCIONALIDAD ADICIONAL

typedef struct
{
    char *nombre;  // 4 bytes
    intFunc entry; // 4 bytes (direcciï¿½n de memoria)
} Programa_Guardado;

extern Programa_Guardado programas_guardados[15];

extern unsigned int num_programas_guardados;
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
extern void addThousandsSeparator(const char *longStr, int aux, char *resultado, int *counter);
extern void Q12ToFormattedString(Q12 number, char *result, unsigned int length, bool separate);

/**
 * Añade una cadena a otra cadena.
 *
 * @param resultado  Puntero a la cadena de destino.
 * @param counter    Puntero a un entero que lleva la cuenta de la posición actual en la cadena de destino.
 * @param str        Puntero a la cadena fuente.
 */
extern void appendStr(char *resultado, int *counter, char *str);
/**
 * Añade un único carácter a otra cadena.
 *
 * @param resultado  Puntero a la cadena de destino.
 * @param counter    Puntero a un entero que lleva la cuenta de la posición actual en la cadena de destino.
 * @param c          Carácter a añadir.
 */
extern void appendChar(char *resultado, int *counter, char c);
/**
 * Añade una subcadena a partir de un índice dado a otra cadena.
 *
 * @param resultado   Puntero a la cadena de destino.
 * @param counter     Puntero a un entero que lleva la cuenta de la posición actual en la cadena de destino.
 * @param str         Puntero a la cadena fuente.
 * @param startIndex  El índice desde el cual empezar a añadir.
 */
extern void appendStrFromIndex(char *resultado, int *counter, char *str, int startIndex);
/* _gm_reservarMem: rutina para reservar un conjunto de franjas de memoria
                libres consecutivas que proporcionen un espacio suficiente para
                albergar el tama�o de un segmento de c�digo o datos del proceso
                (seg�n indique tipo_seg), asignado al n�mero de z�calo que se
                pasa por par�metro;
                la rutina devuelve la primera direcci�n del espacio reservado;
                en el caso de que no quede un espacio de memoria consecutivo del
                tama�o requerido, devuelve cero */
extern void *_gm_reservarMem(int z, int tam, unsigned char tipo_seg);

/* _gm_liberarMem: rutina para liberar todas las franjas de memoria asignadas
                al proceso del z�calo indicado por par�metro */
extern void _gm_liberarMem(int z);

/* _gm_pintarFranjas: rutina para pintar las l�neas verticales correspondientes
                a un conjunto de franjas consecutivas de memoria asignadas a un
                segmento (de c�digo o datos) del z�calo indicado por par�metro.
    Par�metros:
        zocalo		->	el z�calo que reserva la memoria (0 para borrar)
        index_ini	->	el �ndice inicial de las franjas
        num_franjas	->	el n�mero de franjas a pintar
        tipo_seg	->	el tipo de segmento reservado (0 -> c�digo, 1 -> datos)
*/
extern void _gm_pintarFranjas(unsigned char zocalo, unsigned short index_ini,
                              unsigned short num_franjas, unsigned char tipo_seg);

/* _gm_rsiTIMER1:	manejador de interrupciones del TIMER1 de la plataforma NDS,
                que refrescar� peri�dicamente la informaci�n de la tabla de
                procesos relativa al uso de la pila y el estado del proceso */
extern void _gm_rsiTIMER1();

//------------------------------------------------------------------------------
//	Funciones de gesti�n de gr�ficos (garlic_graf.c)
//------------------------------------------------------------------------------

/* _gg_iniGraf: inicializa el procesador gr�fico A para GARLIC 2.0 */
extern void _gg_iniGrafA();

/* _gg_generarMarco: dibuja el marco de la ventana que se indica por parámetro,
                                                con el color correspondiente */
extern void _gg_generarMarco(int v, int color);

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

/* _gg_escribirCar: escribe un car�cter (baldosa) en la posici�n de la ventana
                indicada, con un color concreto;
    Par�metros:
        vx		->	coordenada x de ventana (0..31)
        vy		->	coordenada y de ventana (0..23)
        caracter->	c�digo del car�cter, como n�mero de baldosa (0..127)
        color	->	n�mero de color del texto (de 0 a 3)
        ventana	->	n�mero de ventana (de 0 a 15)
*/
extern void _gg_escribirCar(int vx, int vy, char c, int color, int ventana);

/* _gg_escribirMat: escribe una matriz de 8x8 car�cteres a partir de una
                posici�n de la ventana indicada, con un color concreto;
    Par�metros:
        vx		->	coordenada x inicial de ventana (0..31)
        vy		->	coordenada y inicial de ventana (0..23)
        m		->	matriz 8x8 de c�digos ASCII
        color	->	n�mero de color del texto (de 0 a 3)
        ventana	->	n�mero de ventana (de 0 a 15)
*/
extern void _gg_escribirMat(int vx, int vy, char m[][8], int color, int ventana);

/* _gg_escribirLineaTabla: escribe los campos b�sicos de una linea de la tabla
                de procesos, correspondiente al n�mero de z�calo que se pasa por
                par�metro con el color especificado; los campos a escribir son:
                    n�mero de z�calo, PID y nombre en clave del proceso (keyName)
*/
extern void _gg_escribirLineaTabla(int z, int color);

/* _gg_rsiTIMER2:	manejador de interrupciones del TIMER2 de la plataforma NDS,
                que refrescar� peri�dicamente la informaci�n de la tabla de
                procesos relativa a la direcci�n actual de ejecuci�n */
extern void _gg_rsiTIMER2();

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
        ATENCI�N:	s�lo procesa n�meros naturales de 32 bits SIN signo. */
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

/* _gs_borrarVentana: borra el contenido de la ventana que se pasa por par�metro,
                as� como el campo de control del buffer de ventana
                _gd_wbfs[ventana].pControl; la rutina puede operar en una
                configuraci�n de 4 o 16 ventanas, seg�n el par�metro de modo;
    Par�metros:
        ventana ->	n�mero de ventana
        modo 	->	(0 -> 4 ventanas, 1 -> 16 ventanas)
*/
extern void _gs_borrarVentana(int zocalo, int modo);

/* _gs_iniGrafB: inicializa el procesador gr�fico B para GARLIC 2.0 */
extern void _gs_iniGrafB();

/* _gs_escribirStringSub: escribe un string (terminado con centinela cero) a
                partir de la posici�n indicada por par�metros (fil, col), con el
                color especificado, en la pantalla secundaria */
extern void _gs_escribirStringSub(char *string, int fil, int col, int color);

/* _gs_dibujarTabla: dibujar la tabla de procesos */
extern void _gs_dibujarTabla();

//------------------------------------------------------------------------------
//	Rutinas de soporte a la interficie de usuario (garlic_itcm_ui.s)
//------------------------------------------------------------------------------
extern int _gi_za; // z�calo seleccionado actualmente

/* _gi_movimientoVentanas:	actualiza el desplazamiento y escalado de los
                fondos 2 y 3 del procesador gr�fico A, para efectuar los
                movimientos de las ventanas seg�n el comportamiento
                requerido de la interficie de usuario */
extern void _gi_movimientoVentanas();

/* _gi_redibujarZocalo: rutina para actualizar la tabla de z�calos en funci�n
                del z�calo actual (_gi_za) y del par�metro (seleccionar):
                    si seleccionar == 0, dibuja la l�nea de _gi_za seg�n el
                                            color asociado al estado del z�calo
                                            (blanco -> activo, salm�n -> libre);
                    sino, 				dibuja la l�nea en magenta
*/
extern void _gi_redibujarZocalo(int seleccionar);

/* _gi_controlInterfaz: rutina para gestionar la interfaz del usuario a partir
                del c�digo de tecla que se pasa por par�metro */
extern void _gi_controlInterfaz(int key);

#endif // _GARLIC_SYSTEM_h_
