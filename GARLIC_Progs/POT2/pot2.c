#include <GARLIC_API.h>

int _start(int arg)
{
    // Calculamos el límite superior para los números aleatorios.
    unsigned int rango_superior = 1 << (arg + 4);

    // Calculamos el tamaño de la lista como (arg + 2) al cubo.
    int tamano_lista = 1;
    for (int i = 0; i < 3; ++i)
    {
        tamano_lista *= (arg + 2);
    }

    // Contador para las potencias de dos.
    int contador_potencias = 0;
    unsigned int num_aleatorio;
    GARLIC_printf("tamano lista %d \n", tamano_lista);
    GARLIC_printf("rango superior %d \n", rango_superior);
    // Generamos y verificamos los números aleatorios.
    for (int i = 0; i < tamano_lista; ++i)
    {
        num_aleatorio = GARLIC_random();
        unsigned int cociente, resto;
        if (GARLIC_divmod(num_aleatorio, rango_superior, &cociente, &resto) != 0)
        {
            // Manejar el error de división por cero o lo que sea apropiado
        }
        num_aleatorio = resto;
        // Comprobamos si num_aleatorio es una potencia de dos.
        // Un número es potencia de dos si es distinto de cero y
        // el AND bit a bit de sí mismo y sí mismo menos uno es cero.
        if (num_aleatorio && !(num_aleatorio & (num_aleatorio - 1)))
        {
            GARLIC_printf("num aleatorio %d \n", num_aleatorio);
            contador_potencias++;
        }
    }
    GARLIC_printf("contador potencias %d \n", contador_potencias);
    return 0;
}
