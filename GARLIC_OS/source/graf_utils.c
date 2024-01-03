#include <nds.h>

#include <garlic_system.h>
void addThousandsSeparator(const char *longStr, int aux, char *resultado, int *counter)
{
    char formattedNumber[30];
    int formattedCounter = 0;
    int numberLength = strlen(longStr + aux);
    int dotPosition = numberLength % 3 == 0 ? 3 : numberLength % 3;

    for (int j = aux; longStr[j] != '\0'; ++j)
    {
        if (j != aux && (j - aux) == dotPosition)
        {
            appendChar(formattedNumber, &formattedCounter, '.');
            dotPosition += 3;
        }
        appendChar(formattedNumber, &formattedCounter, longStr[j]);
    }
    formattedNumber[formattedCounter] = '\0'; // Aseguramos que la cadena esté terminada
    appendStr(resultado, counter, formattedNumber);
}

void appendStrFromIndex(char *resultado, int *counter, char *str, int startIndex)
{
    for (int i = startIndex; str[i] != '\0'; i++)
    {
        appendChar(resultado, counter, str[i]);
    }
}

void appendChar(char *resultado, int *counter, char c)
{
    resultado[*counter] = c;
    (*counter)++;
}

void appendStr(char *resultado, int *counter, char *str)
{
    for (int i = 0; str[i] != '\0'; i++)
    {
        appendChar(resultado, counter, str[i]);
    }
}

void Q12ToFormattedString(Q12 number, char *result, unsigned int length, bool separate)
{
    char parteEnteraStr[20]; // Buffer para la parte entera
    char parteDecimalStr[6]; // Buffer para la parte decimal, incluyendo el punto

    int counter = 0; // Contador para la posición actual en la cadena de destino

    // Comprueba si el número es negativo
    int isNegative = number < 0;

    // Extraemos la parte entera y decimal
    int parteEntera = number >> 12;    // Obtener la parte entera
    int parteDecimal = number & 0xFFF; // Obtener la parte decimal

    if (isNegative)
    {
        // Si el número es negativo, convierte las partes a su valor absoluto
        parteEntera = -parteEntera;
        if (parteDecimal != 0)
        {
            parteEntera -= 1;                   // Ajustar la parte entera si la parte decimal no es cero
            parteDecimal = 4096 - parteDecimal; // Calcular la parte decimal complementaria
        }
    }

    // Convertir la parte entera y decimal a cadena
    _gs_num2str_dec(parteEnteraStr, sizeof(parteEnteraStr), parteEntera);
    int decimalMultiplier = 1000; // Para 3 dígitos decimales
    double parteDecimalTemp = (double)parteDecimal * decimalMultiplier / 4096;
    parteDecimal = (int)(parteDecimalTemp + 0.5); // Redondea al entero más cercano
    _gs_num2str_dec(parteDecimalStr, sizeof(parteDecimalStr), parteDecimal);

    // Eliminar espacios en blanco iniciales de parteEnteraStr
    char *parteEnteraStrTrimmed = parteEnteraStr;
    while (*parteEnteraStrTrimmed == ' ')
    {
        parteEnteraStrTrimmed++;
    }
    // Construir la cadena final
    if (isNegative)
    {
        appendChar(result, &counter, '-'); // Añade el signo negativo
    }
    if (separate)
        addThousandsSeparator(parteEnteraStrTrimmed, 0, result, &counter);
    else
        appendStr(result, &counter, parteEnteraStrTrimmed); // Añade la parte entera
    // Eliminar espacios en blanco iniciales de parteDecimalStr
    char *parteDecimalStrTrimmed = parteDecimalStr;
    while (*parteDecimalStrTrimmed == ' ')
    {
        parteDecimalStrTrimmed++;
    }

    appendChar(result, &counter, ',');                   // Añade el punto decimal
    appendStr(result, &counter, parteDecimalStrTrimmed); // Añade la parte decimal

    result[counter] = '\0'; // Asegurar que la cadena esté terminada
}
