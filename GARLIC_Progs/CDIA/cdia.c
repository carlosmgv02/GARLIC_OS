/*------------------------------------------------------------------------------

    "CDIA.C": programa de prueba para el sistema operativo GARLIC 1.0;

    Intenta convertir número de días en un rango de 0 a 10^(arg+2) a
    años, meses y días

    author: carlos.martinezg@estudiants.urv.cat
------------------------------------------------------------------------------*/

#include <GARLIC_API.h>
int _start(int arg)
{

    unsigned int max_rango = 1;    // Rango máximo para los números aleatorios
    unsigned int numero_aleatorio; // Para almacenar el número aleatorio
    int dias, anos, meses;         // Para almacenar el desglose de días
    // Validar y establecer el rango del argumento
    arg = (arg < 0) ? 0 : (arg > 3) ? 3
                                    : arg;
    long long trial = 9223372036854775806LL;
    GARLIC_printf("-Prueba int: %d %d\n", 123, 543);
    GARLIC_printf("-Prueba long: %L buuuuum\n", &trial);
    GARLIC_printf("-- Programa CDIA - PID (%d) --\n", GARLIC_pid());
    // Calcular el rango máximo
    for (int i = 0; i < arg + 2; ++i)
    {
        max_rango *= 10;
    }

    // Bucle de 20 iteraciones para generar y convertir números aleatorios
    /*for (int i = 1; i <= 20; ++i)
    {
        numero_aleatorio = GARLIC_random();

        // Ajustar el número aleatorio al rango máximo
        while (numero_aleatorio > max_rango)
        {
            numero_aleatorio >>= 1;
        }

        // Calcular años, meses y días
        anos = numero_aleatorio / 365;
        meses = (numero_aleatorio % 365) / 30;
        dias = (numero_aleatorio % 365) % 30;

        // Imprimir el resultado en dos partes para ajustarse al límite del búfer
        GARLIC_printf("%d- ", i);
        GARLIC_printf("%d days are %d years,\n", numero_aleatorio, anos);
        GARLIC_printf("\t\t%d months & %d days\n", meses, dias);
    }*/

    return 0;
}