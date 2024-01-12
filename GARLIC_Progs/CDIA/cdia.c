#include <GARLIC_API.h>

int calcularAnosBisiestos(int anos)
{
    return anos / 4 - anos / 100 + anos / 400;
}

int _start(int arg)
{
    unsigned int max_rango = 1;
    unsigned int numero_aleatorio;
    int dias, anos, meses;
    long long trial = 9223372036854775806LL;
    long long diasLong;

    // Validar y establecer el rango del argumento
    arg = (arg < 0) ? 0 : (arg > 3) ? 3
                                    : arg;

    // Calcular el rango máximo
    for (int i = 0; i < arg + 2; ++i)
    {
        max_rango *= 10;
    }

    // Bucle de 20 iteraciones para generar y convertir números aleatorios
    for (int i = 1; i <= 20; ++i)
    {
        numero_aleatorio = GARLIC_random();

        // Ajustar el número aleatorio al rango máximo
        while (numero_aleatorio > max_rango)
        {
            numero_aleatorio >>= 1;
        }

        // Calcular años, meses y días
        anos = numero_aleatorio / 365;
        dias = numero_aleatorio % 365;

        // Ajustar por años bisiestos
        int anosBisiestos = calcularAnosBisiestos(anos);
        if (dias >= anosBisiestos)
        {
            dias -= anosBisiestos;
        }
        else
        {
            anos--;
            dias = 365 - (anosBisiestos - dias);
        }

        meses = dias / 30;
        dias %= 30;
        diasLong = (long long)dias; // Conversión a long para prueba

        // Imprimir el resultado
        GARLIC_printf("%d- ", i);
        GARLIC_printf("%d days are %d years,\n", numero_aleatorio, anos);
        GARLIC_printf("\t\t%d months and %L days\n", meses, &diasLong);
    }
    GARLIC_printf("\n********************************\n");
    GARLIC_printf("-Prueba long (L): %L\n", &trial);
    GARLIC_printf("-Prueba long (l): %l\n", &trial);

    return 0;
}
