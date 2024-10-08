/*------------------------------------------------------------------------------

    "PRM1.c" : primer programa de prueba para el sistema operativo GARLIC 1.0;

    Genera permutaciones de (arg+3) elementos, con recursividad.

------------------------------------------------------------------------------*/

#include <garlic_API.h>

void swap(char *x, char *y)
{
    char temp;
    temp = *x;
    *x = *y;
    *y = temp;
}

void permute(char *a, int l, int r)
{
    int i;
    if (l == r)
        GARLIC_printf("%s\n", a);
    else
    {
        for (i = l; i <= r; i++)
        {
            swap((a + l), (a + i));
            permute(a, l + 1, r);
            swap((a + l), (a + i)); // backtrack
        }
    }
}

int _start(int arg)
{
    char str[] = "ABCDEF";
    int n = arg + 3;
    // GARLIC_printf("PRUEBA\n");
    permute(str, 0, n - 1);
    return 0;
}
