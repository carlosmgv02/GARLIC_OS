/*------------------------------------------------------------------------------

	"GARLIC_API.h" : cabeceras de funciones del API (Application Program
					Interface) del sistema operativo GARLIC 1.0 (código fuente
					disponible en "GARLIC_API.s")

------------------------------------------------------------------------------*/
#ifndef _GARLIC_API_h_
#define _GARLIC_API_h_

/* GARLIC_pid: devuelve el identificador del proceso actual */
extern int GARLIC_pid();

/* GARLIC_random: devuelve un número aleatorio de 32 bits */
extern int GARLIC_random();

/* GARLIC_divmod: calcula la división num / den (numerador / denominador),
	almacenando el cociente y el resto en las posiciones de memoria indica-
	das por *quo y *mod, respectivamente (pasa resultados por referencia);
	la función devuelve 0 si la división es correcta, o diferente de 0
	si hay algún problema (división por cero).
	ATENCIÓN: sólo procesa números naturales de 32 bits SIN signo. */
extern int GARLIC_divmod(unsigned int num, unsigned int den,
						 unsigned int *quo, unsigned int *mod);

/* GARLIC_divmodL: calcula la división num / den (numerador / denominador),
	almacenando el cociente y el resto en las posiciones de memoria indica-
	das por *quo y *mod, respectivamente; los parámetros y los resultados
	se pasan por referencia; el numerador y el cociente son de tipo
	long long (64 bits), mientras que el denominador y el resto son de tipo
	unsigned int (32 bits sin signo).
	la función devuelve 0 si la división es correcta, o diferente de 0
	si hay algún problema (división por cero). */
extern int GARLIC_divmodL(long long *num, unsigned int *den,
						  long long *quo, unsigned int *mod);

/* GARLIC_printf: escribe un string en la ventana del proceso actual,
	utilizando el string de formato 'format' que se pasa como primer
	parámetro, insertando los valores que se pasan en los siguientes
	parámetros (hasta 2) en la posición y forma (tipo) que se especifique
	con los marcadores incrustados en el string de formato:
		%c	: inserta un carácter (según código ASCII)
		%d	: inserta un natural (32 bits) en formato decimal
		%x	: inserta un natural (32 bits) en formato hexadecimal
		%s	: inserta un string
		%%	: inserta un carácter '%' literal
	Además, también procesa los metacaracteres '\t' (tabulador) y '\n'
	(salto de línea). */
extern void GARLIC_printf(char *format, ...);

#endif // _GARLIC_API_h_
