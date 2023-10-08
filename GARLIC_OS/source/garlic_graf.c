/*------------------------------------------------------------------------------

	"garlic_graf.c" : fase 1 / programador G

	Funciones de gesti�n de las ventanas de texto (gr�ficas), para GARLIC 1.0

------------------------------------------------------------------------------*/
#include <nds.h>

#include <garlic_system.h> // definici�n de funciones y variables de sistema
#include <garlic_font.h>   // definici�n gr�fica de caracteres

#define NVENT 4	 // número de ventanas totales
#define PPART 2	 // número de ventanas horizontales o verticales
				 // (particiones de pantalla)
#define VCOLS 32 // columnas y filas de cualquier ventana
#define VFILS 24
#define PCOLS VCOLS *PPART // número de columnas totales (en pantalla)
#define PFILS VFILS *PPART // número de filas totales (en pantalla)

int bg2, bg3;
u16 *ptrMap2;
u16 *ptrMap3;

/* _gg_generarMarco: dibuja el marco de la ventana que se indica por par�metro*/
void _gg_generarMarco(int v)
{
	int ind = (v / PPART) * VCOLS * PPART * VFILS + VCOLS * (v % PPART);
	// Arriba a la izquierda
	ptrMap3[ind] = 103;
	// Arriba a la derecha
	ptrMap3[ind + (VCOLS - 1)] = 102;
	// Abajo a la izquierda
	ptrMap3[ind + (VFILS - 1) * PCOLS] = 100;

	// Bucle para mostrar el resto de los caracteres del marco
	for (int i = 1; i < (VFILS - 1) || i < (VCOLS - 1); i++)
	{
		if (i < (VFILS - 1))
		{
			// En medio de la izquierda
			ptrMap3[(ind) + (i * PCOLS)] = 96;
			// En medio de la derecha
			ptrMap3[(ind) + (i * PCOLS) + (VCOLS - 1)] = 98;
		}
	}
}

/* _gg_iniGraf: inicializa el procesador gr�fico A para GARLIC 1.0 */
void _gg_iniGrafA()
{
	videoSetMode(MODE_5_2D);				 // Establecemos el procesador gráfico A en modo 5
	vramSetBankA(VRAM_A_MAIN_BG_0x06000000); // Establecemos la memoria de video A en el banco A
	lcdMainOnTop();							 // Establecemos la pantalla principal como pantalla superior

	// Inicializamos los fondos con extended rotation

	bg2 = bgInit(2, BgType_ExRotation, BgSize_ER_512x512, 0, 4);
	bg3 = bgInit(3, BgType_ExRotation, BgSize_ER_512x512, 8, 4);

	// Prioridad bg3 > bg2
	bgSetPriority(bg2, 1);
	bgSetPriority(bg3, 0);

	// Descomprimimos las letras de la fuente
	decompress(garlic_fontTiles, bgGetGfxPtr(bg3), LZ77Vram);

	// Copiamos la paleta de colores desde la paleta de la fuente
	dmaCopy(garlic_fontPal, BG_PALETTE, sizeof(garlic_fontPal));

	// Obtenemos los punteros a los mapas de los fondos
	ptrMap3 = bgGetMapPtr(bg3);
	ptrMap2 = bgGetMapPtr(bg2);

	for (int i = 0; i < NVENT; i++)
	{
		_gg_generarMarco(i);
	}

	// Escalamos el tamaño de los fondos al 50%
	bgSetScale(bg3, 0x200, 0x200);
	bgSetScale(bg2, 0x200, 0x200);

	// Actualizamos desplazamiento del fondo
	bgUpdate();
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
