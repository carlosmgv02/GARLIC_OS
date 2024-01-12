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
