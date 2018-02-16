#include <system.h>

char cputchar_char = 0;
void cputchar(char c) {

    if (c == '\n') {
        asm("pusha");
        asm("mov ah, 0x0e");
        asm("mov al, 0x0d");
        asm("int 0x10");
        asm("mov al, 0x0a");
        asm("int 0x10");
        asm("popa");
    } else {
        cputchar_char = c;
        asm("pusha");
        asm("mov al, byte [_cputchar_char]");
        asm("mov ah, 0x0e");
        asm("int 0x10");
        asm("popa");
    }

}

void cprint(char *str) {
    int i;

    for (i = 0; str[i]; i++)
        cputchar(str[i]);

    return;

}

void cmain(void) {

    cprint("hello, C world!\n");

    return;

}
