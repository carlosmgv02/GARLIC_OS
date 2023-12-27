/*------------------------------------------------------------------------------

	"HOLA.c" : primer programa de prueba para el sistema operativo GARLIC 1.0;

	Imprime el t�pico mensaje "Hello world!" por una ventana de GARLIC, un
	n�mero aleatorio de veces, dentro de un rango entre 1 y 10 elevado al
	argumento ([0..3]), es decir, hasta 1, 10, 100 o 1000 iteraciones.

------------------------------------------------------------------------------*/

#include <GARLIC_API.h> /* definici�n de las funciones API de GARLIC */

int _start(int arg) /* funci�n de inicio : no se usa 'main' */
{
	unsigned int i, j, iter;

	if (arg < 0)
		arg = 0; // limitar valor m�ximo y
	else if (arg > 3)
		arg = 3; // valor m�nimo del argumento

	// esccribir mensaje inicial
	GARLIC_printf("-- Programa HOLA  -  PID (%d) --\n", GARLIC_pid());
	GARLIC_printf("Inici delay 4 segons\n");
	GARLIC_delay(4);
	GARLIC_printf("Final delay\n");

	j = 1; // j = c�lculo de 10 elevado a arg
	for (i = 0; i < arg; i++)
		j *= 10;
	// c�lculo aleatorio del n�mero de iteraciones 'iter'
	GARLIC_divmod(GARLIC_random(), j, &i, &iter);
	iter++; // asegurar que hay al menos una iteraci�n

	for (i = 0; i < iter; i++) // escribir mensajes
		GARLIC_printf("(%d)\t%d: Hello world!\n", GARLIC_pid(), i);

	return 0;
}
