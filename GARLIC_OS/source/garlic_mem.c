/*------------------------------------------------------------------------------

	"garlic_mem.c" : fase 1 / programador M

	Funciones de carga de un fichero ejecutable en formato ELF, para GARLIC 1.0

------------------------------------------------------------------------------*/
#include <nds.h>
#include <filesystem.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <garlic_system.h> // definici�n de funciones y variables de sistema

#define END_MEM 0x01008000 // direccion final de memoria para programas
#define EI_NIDENT 16

typedef unsigned int Elf32_Addr;   // direcci�n de memoria
typedef unsigned short Elf32_Half; // medio entero sin signo
typedef unsigned int Elf32_Off;	   // desplazamiento dentro del fichero sin signo
typedef signed int Elf32_Sword;	   // entero con signo
typedef unsigned int Elf32_Word;   // entero sin signo

typedef struct
{ // Estructura de la cebecera ELF
	unsigned char e_ident[EI_NIDENT];
	Elf32_Half e_type;
	Elf32_Half e_machine;
	Elf32_Word e_version;
	Elf32_Addr e_entry;
	Elf32_Off e_phoff;
	Elf32_Off e_shoff;
	Elf32_Word e_flags;
	Elf32_Half e_ehsize;
	Elf32_Half e_phentsize;
	Elf32_Half e_phnum;
	Elf32_Half e_shentsize;
	Elf32_Half e_shnum;
	Elf32_Half e_shstrndx;
} Elf32_Ehdr;

typedef struct
{ // Estructura para cada entrada de la tabla de segmentos
	Elf32_Word p_type;
	Elf32_Off p_offset;
	Elf32_Addr p_vaddr;
	Elf32_Addr p_paddr;
	Elf32_Word p_filesz;
	Elf32_Word p_memsz;
	Elf32_Word p_flags;
	Elf32_Word p_align;
} Elf32_Phdr;

/* _gm_initFS: inicializa el sistema de ficheros, devolviendo un valor booleano
					para indiciar si dicha inicializaci�n ha tenido �xito; */
int _gm_initFS()
{
	num_programas_guardados = 0;
	// RESERVAR MEMORIA ARRAYS DE NOMBRES
	for (int z = 0; z < 15; z++)
	{
		// reservamos espacio para el buffer d�nde va a apuntar cada puntero
		programas_guardados[z].nombre = malloc(sizeof(char) * 4);
	}
	return nitroFSInit(NULL);
}

/* _gm_cargarPrograma: busca un fichero de nombre "(keyName).elf" dentro del
					directorio "/Programas/" del sistema de ficheros, y
					carga los segmentos de programa a partir de una posici�n de
					memoria libre, efectuando la reubicaci�n de las referencias
					a los s�mbolos del programa, seg�n el desplazamiento del
					c�digo en la memoria destino;
	Par�metros:
		keyName ->	vector de 4 caracteres con el nombre en clave del programa
	Resultado:
		!= 0	->	direcci�n de inicio del programa (intFunc)
		== 0	->	no se ha podido cargar el programa
*/
intFunc _gm_cargarPrograma(char *keyName)
{
	for (int i = 0; i < num_programas_guardados; i++)
	{
		if (strcmp(programas_guardados[i].nombre, keyName) == 0)
		{
			return programas_guardados[i].entry;
		}
	}

	// Construir path del fichero
	char path[19];
	sprintf(path, "/Programas/%s.elf", keyName);

	// Abrimos el fichero
	FILE *pFile = fopen(path, "rb");
	if (pFile == NULL)
		return ((intFunc)0);

	// Obtenemos tama�o del archivo
	fseek(pFile, 0, SEEK_END); // Movemos el cursor al final
	long lSize = ftell(pFile); // Guardamos el tama�o del archivo
	fseek(pFile, 0, SEEK_SET); // Restauramos el cursor a la posici�n inicial

	// Reservamos memoria para contener el fichero completo
	char *buffer = (char *)malloc(sizeof(char) * (lSize + 1));
	if (buffer == NULL)
	{
		fclose(pFile);
		return ((intFunc)0);
	}

	// Copiar el fichero en el buffer
	size_t readed_bytes = fread(buffer, sizeof(char), lSize, pFile);
	if (readed_bytes != lSize)
	{
		fclose(pFile);
		free(buffer);
		return ((intFunc)0);
	}

	// Cargamos la cabecera del fichero ELF
	fseek(pFile, 0, SEEK_SET);
	Elf32_Ehdr head;
	fread(&head, 1, sizeof(Elf32_Ehdr), pFile);
	if (head.e_phnum == 0)
	{
		fclose(pFile);
		free(buffer);
		return ((intFunc)0);
	}

	// Cargamos tabla de segmentos
	fseek(pFile, head.e_phoff, SEEK_SET);
	Elf32_Phdr segments_table_entry;
	fread(&segments_table_entry, 1, sizeof(Elf32_Phdr), pFile);

	int dirprog;
	for (int i = 0; i < head.e_phnum; i++)
	{
		if (segments_table_entry.p_type != 1)
		{
			fseek(pFile, head.e_phoff + i * sizeof(Elf32_Phdr), SEEK_SET);
			fread(&segments_table_entry, 1, sizeof(Elf32_Phdr), pFile);
			continue;
		}

		// Comprobar que no nos hemos quedado sin memoria para el segmento
		if (_gm_first_mem_pos + segments_table_entry.p_memsz > END_MEM)
		{
			fclose(pFile);
			free(buffer);
			return ((intFunc)0);
		}

		// Cargamos en memoria el segmento
		_gs_copiaMem(
			(const void *)&buffer[segments_table_entry.p_offset],
			(void *)_gm_first_mem_pos,
			segments_table_entry.p_memsz);

		// Hacemos la reubicaci�n
		_gm_reubicar(
			buffer,
			segments_table_entry.p_paddr,
			(unsigned int *)_gm_first_mem_pos);

		// Para que en el siguiente programa, el gm_first_mem_pos sea multiplo de 4
		unsigned int size_prog = segments_table_entry.p_memsz;
		int valor = size_prog % 4;
		if (valor != 0)
		{
			size_prog = size_prog + (4 - valor);
		}
		unsigned int new_gm_first_mem_pos = _gm_first_mem_pos + size_prog;

		// Generamos direcci�n inicial del programa en memoria
		dirprog = _gm_first_mem_pos + head.e_entry - segments_table_entry.p_paddr;
		_gm_first_mem_pos = new_gm_first_mem_pos;

		// Cerramos el fichero y liberamos el buffer de memoria
		fclose(pFile);
		free(buffer);

		// A�adimos programa cargado a la tabla de programas cargados
		programas_guardados[num_programas_guardados].entry = (intFunc)dirprog;

		for (int j = 0; j < 4; j++)
		{
			programas_guardados[num_programas_guardados].nombre[j] = keyName[j];
		}

		num_programas_guardados++;

		return ((intFunc)dirprog);
	}
	return ((intFunc)0);
}
