#include "str.h"

int str_len(const char *str, size_t max_length)
{
    size_t length = 0;

    while (length < max_length && str[length] != '\0') 
    {
        length++;
    }

    return length;
}