#define DRFI_8(VARNAME, VAL)        \
    drf_addr = VARNAME;     \
    drf_val8 = VAL;         \
    asm("push ax"); \
    asm("push ebx"); \
    asm("mov al, byte [_drf_val8]");    \
    asm("mov ebx, dword [_drf_addr]");    \
    asm("mov byte [ebx], al"); \
    asm("pop ebx"); \
    asm("pop ax");
