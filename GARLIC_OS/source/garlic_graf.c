/*------------------------------------------------------------------------------

	"garlic_graf.c" : fase 1 / programador G

	Funciones de gestión de las ventanas de texto (gráficas), para GARLIC 1.0

------------------------------------------------------------------------------*/
#include <nds.h>

#include <garlic_system.h> // definición de funciones y variables de sistema
#include <garlic_font.h>   // definición gráfica de caracteres

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

/* _gg_generarMarco: dibuja el marco de la ventana que se indica por parámetro*/
void _gg_generarMarco(int v)
{
	int ind = (v / PPART) * VCOLS * PPART * VFILS + VCOLS * (v % PPART);
	// Arriba a la izquierda
	ptrMap3[ind] = 103;
	// Arriba a la derecha
	ptrMap3[ind + (VCOLS - 1)] = 102;
	// Abajo a la izquierda
	ptrMap3[ind + (VFILS - 1) * PCOLS] = 100;
	// Abajo a la derecha
	ptrMap3[ind + (VFILS - 1) * PCOLS + (VCOLS - 1)] = 101;

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

		if (i < VCOLS - 1)
		{
			// En medio de arriba
			ptrMap3[ind + i] = 99;
			// En medio de abajo
			ptrMap3[(ind + i) + (VFILS - 1) * PCOLS] = 97;
		}
	}
}

/* _gg_iniGraf: inicializa el procesador gráfico A para GARLIC 1.0 */
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
					  string resultante, pero identifica los códigos de formato
					  precedidos por '%' e inserta la representación ASCII de
					  los valores indicados por parámetro.
	Parámetros:
		formato	->	string con códigos de formato (ver descripción _gg_escribir);
		val1, val2	->	valores a transcribir, sean número de código ASCII (%c),
					un número natural (%d, %x) o un puntero a string (%s);
		resultado	->	mensaje resultante.
	Observación:
		Se supone que el string resultante tiene reservado espacio de memoria
		suficiente para albergar todo el mensaje, incluyendo los caracteres
		literales del formato y la transcripción a código ASCII de los valores.
*/
void _gg_procesarFormato(char *formato, unsigned int val1, unsigned int val2, char *resultado)
{
	char used1 = 0, used2 = 0; // Variables para rastrear el uso de val1 y val2
	int counter = 0, aux = 0;  // Contador para el resultado y auxiliar para otras operaciones
	char numStr[11];		   // Buffer para la conversión de números a cadena
	char *temp;				   // Puntero temporal para cadenas
	unsigned int val = 0;	   // Variable para guardar el valor actual (val1 o val2)

	long long *longPtr; // Pointer to long long for dereferencing
	char longStr[26];	// Buffer for long long number conversion

	for (int i = 0; formato[i] != '\0'; i++)
	{
		// Si encontramos un '%'
		if (formato[i] == '%')
		{
			i++; // Saltamos el '%'

			// Si hay otro '%', añadimos un '%' al resultado
			if (formato[i] == '%')
			{
				appendChar(resultado, &counter, '%');
				continue;
			}

			// Comprobamos si val1 o val2 ya se han usado
			if (!used1 || !used2)
			{

				val = (!used1) ? val1 : val2;

				if (!used1)
					used1 = 1;
				else if (!used2)
					used2 = 1;
			}
			else
			{
				// Si ambos valores se han utilizado y encontramos otro indicador de formato, se considera un error
				appendChar(resultado, &counter, '%');
				appendChar(resultado, &counter, formato[i]);
				continue;
			}

			aux = 0;

			switch (formato[i])
			{
			case 'l':
				longStr[0] = '\0';
				longPtr = (long long *)val;
				_gs_num2str_dec64(longStr, sizeof(longStr), longPtr);
				while (longStr[aux] == ' ')
					aux++;
				appendStrFromIndex(resultado, &counter, longStr, aux);
				break;

			case 'L':
				longStr[0] = '\0';
				longPtr = (long long *)val;
				_gs_num2str_dec64(longStr, sizeof(longStr), longPtr);
				// Eliminamos espacios en blanco iniciales
				aux = 0;
				while (longStr[aux] == ' ')
					aux++;

				addThousandsSeparator(longStr, aux, resultado, &counter);
				break;
			case 'x':
				numStr[0] = '\0';
				_gs_num2str_hex(numStr, sizeof(numStr), val); // Dereference the pointer to get the int value

				appendStrFromIndex(resultado, &counter, numStr, aux);
				break;

			case 'c':
				appendChar(resultado, &counter, val); // Dereference the pointer to get the char value
				break;

			case 's':
				temp = (char *)val; // Dereference the pointer to get the string pointer
				if (temp != NULL)
				{
					appendStr(resultado, &counter, temp);
				}
				break;

			case 'd':
				numStr[0] = '\0';
				if ((int)val < 0)
				{
					appendChar(resultado, &counter, '-');
					_gs_num2str_dec(numStr, 11, -(int)val); // Dereference the pointer to get the int value
				}
				else
				{
					_gs_num2str_dec(numStr, 11, (int)val); // Dereference the pointer to get the int value
				}

				while (numStr[aux] == ' ')
					aux++;
				appendStrFromIndex(resultado, &counter, numStr, aux);
				break;

			default:
				appendChar(resultado, &counter, '%');
				appendChar(resultado, &counter, formato[i]);
				if (val == val1)
					used1 = 0;
				else
					used2 = 0;
				break;
			}
		}
		else
		{
			// Añadimos el carácter tal cual al resultado
			appendChar(resultado, &counter, formato[i]);
		}
	}
	// Añadimos el terminador de cadena al resultado
	resultado[counter] = '\0';
}

/* _gg_escribir: escribe una cadena de caracteres en la ventana indicada;
	Parámetros:
		formato	->	cadena de formato, terminada con centinela '\0';
					admite '\n' (salto de línea), '\t' (tabulador, 4 espacios)
					y códigos entre 32 y 159 (los 32 últimos son caracteres
					gráficos), además de códigos de formato %c, %d, %x y %s
					(max. 2 códigos por cadena)
		val1	->	valor a sustituir en primer código de formato, si existe
		val2	->	valor a sustituir en segundo código de formato, si existe
					- los valores pueden ser un código ASCII (%c), un valor
					  natural de 32 bits (%d, %x) o un puntero a string (%s)
		ventana	->	número de ventana (de 0 a 3)
*/
void _gg_escribir(char *formato, unsigned int val1, unsigned int val2, int ventana)
{
	// puntero de control de la ventana
	int pControl = _gd_wbfs[ventana].pControl;
	int ind = 0;
	// string resultante
	char result[3 * VCOLS + 1];
	char nChar, currentRow;

	// procesar el formato
	_gg_procesarFormato(formato, val1, val2, result);
	// número de caracteres
	nChar = pControl & 0x0000FFFF;
	// fila actual
	currentRow = pControl >> 16;
	// hacer mientras no lleguemos al final del string que identificamos mediante el centinela '\0'
	while (result[ind] != '\0')
	{
		// comprobar si es un salto de línea
		if (result[ind] == '\n' || nChar >= VCOLS)
		{
			// esperar a que termine el barrido vertical
			swiWaitForVBlank();
			if (currentRow == VFILS)
			{
				// desplazar la ventana
				_gg_desplazar(ventana);
				currentRow -= 1;
			}
			_gg_escribirLinea(ventana, currentRow, nChar);
			nChar = 0;
			currentRow += 1;
		}
		// en caso de que sea en la misma fila
		else
		{
			// trataremos las tabulaciones insertando 4 espacios
			// Si el caracter es una tabulación
			if (result[ind] == '\t')
			{
				// Insertamos 4 espacios para tratar la tabulación
				for (int i = 0; i < (4 - (nChar % 4)); i++)
				{
					// Agregamos un espacio en blanco en la posición actual
					_gd_wbfs[ventana].pChars[nChar] = ' ';
					// Incrementamos el contador de caracteres
					nChar += 1;
				}
			}
			// Si no es una tabulación, escribimos el caracter que sea
			else
			{
				// Agregamos el caracter en la posición actual
				_gd_wbfs[ventana].pChars[nChar] = result[ind];
				// Incrementamos el contador de caracteres
				nChar += 1;
			}
		}
		(nChar != VCOLS) ? ind += 1 : ind;
		int aux = currentRow << 16;
		// ponemos los caracteres restantes en los 16 bits bajos
		aux += nChar;
		// actualizamos el controlador de escritura por ventana
		_gd_wbfs[ventana].pControl = aux;
		//_gd_wbfs[ventana].pControl = (currentRow << 16) | nChar; // TODO revisar que funcione correctamente cuando estén las otras funciones acabadas
	}
}
