/*------------------------------------------------------------------------------

	"garlic_graf.c" : fase 1 / programador G

	Funciones de gesti�n de las ventanas de texto (gr�ficas), para GARLIC 1.0

------------------------------------------------------------------------------*/
#include <nds.h>

#include <garlic_system.h>	// definici�n de funciones y variables de sistema
#include <garlic_font.h>	// definici�n gr�fica de caracteres



/* _gg_generarMarco: dibuja el marco de la ventana que se indica por par�metro*/
void _gg_generarMarco(int v)
{

}


/* _gg_iniGraf: inicializa el procesador gr�fico A para GARLIC 1.0 */
void _gg_iniGrafA()
{

}



/* _gg_procesarFormato: copia los caracteres del string de formato sobre el
					  string resultante, pero identifica los c�digos de formato
					  precedidos por '%' e inserta la representaci�n ASCII de
					  los valores indicados por par�metro.
	Par�metros:
		formato	->	string con c�digos de formato (ver descripci�n _gg_escribir);
		val1, val2	->	valores a transcribir, sean n�mero de c�digo ASCII (%c),
					un n�mero natural (%d, %x) o un puntero a string (%s);
		resultado	->	mensaje resultante.
	Observaci�n:
		Se supone que el string resultante tiene reservado espacio de memoria
		suficiente para albergar todo el mensaje, incluyendo los caracteres
		literales del formato y la transcripci�n a c�digo ASCII de los valores.
*/
void _gg_procesarFormato(char *formato, unsigned int val1, unsigned int val2,
																char *resultado)
{

}


/* _gg_escribir: escribe una cadena de caracteres en la ventana indicada;
	Par�metros:
		formato	->	cadena de formato, terminada con centinela '\0';
					admite '\n' (salto de l�nea), '\t' (tabulador, 4 espacios)
					y c�digos entre 32 y 159 (los 32 �ltimos son caracteres
					gr�ficos), adem�s de c�digos de formato %c, %d, %x y %s
					(max. 2 c�digos por cadena)
		val1	->	valor a sustituir en primer c�digo de formato, si existe
		val2	->	valor a sustituir en segundo c�digo de formato, si existe
					- los valores pueden ser un c�digo ASCII (%c), un valor
					  natural de 32 bits (%d, %x) o un puntero a string (%s)
		ventana	->	n�mero de ventana (de 0 a 3)
*/
void _gg_escribir(char *formato, unsigned int val1, unsigned int val2, int ventana)
{

}
