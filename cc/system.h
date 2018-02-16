#define DRF_O_8(VARNAME, VAL)        \
    drf_addr = VARNAME;     \
    drf_val8 = VAL;         \
    asm("push ax"); \
    asm("push ebx"); \
    asm("mov al, byte [_drf_val8]");    \
    asm("mov ebx, dword [_drf_addr]");    \
    asm("mov byte [ebx], al"); \
    asm("pop ebx"); \
    asm("pop ax");

#define DRF_O_16(VARNAME, VAL)        \
    drf_addr = VARNAME;     \
    drf_val16 = VAL;         \
    asm("push ax"); \
    asm("push ebx"); \
    asm("mov ax, word [_drf_val16]");    \
    asm("mov ebx, dword [_drf_addr]");    \
    asm("mov word [ebx], ax"); \
    asm("pop ebx"); \
    asm("pop ax");

#define DRF_O_32(VARNAME, VAL)        \
    drf_addr = VARNAME;     \
    drf_val32 = VAL;         \
    asm("push eax"); \
    asm("push ebx"); \
    asm("mov eax, dword [_drf_val32]");    \
    asm("mov ebx, dword [_drf_addr]");    \
    asm("mov dword [ebx], eax"); \
    asm("pop ebx"); \
    asm("pop eax");

#define DRF_I_8(VARNAME, VAL)        \
    drf_addr = VARNAME;     \
    asm("push ax"); \
    asm("push ebx"); \
    asm("mov ebx, dword [_drf_addr]");    \
    asm("mov al, byte [ebx]"); \
    asm("mov byte [_drf_val8], al");    \
    asm("pop ebx"); \
    asm("pop ax"); \
    VAL = drf_val8;

#define DRF_I_16(VARNAME, VAL)        \
    drf_addr = VARNAME;     \
    asm("push ax"); \
    asm("push ebx"); \
    asm("mov ebx, dword [_drf_addr]");    \
    asm("mov ax, word [ebx]"); \
    asm("mov word [_drf_val16], ax");    \
    asm("pop ebx"); \
    asm("pop ax"); \
    VAL = drf_val16;

#define DRF_I_32(VARNAME, VAL)        \
    drf_addr = VARNAME;     \
    asm("push eax"); \
    asm("push ebx"); \
    asm("mov ebx, dword [_drf_addr]");    \
    asm("mov eax, dword [ebx]"); \
    asm("mov dword [_drf_val32], eax");    \
    asm("pop ebx"); \
    asm("pop eax"); \
    VAL = drf_val32;

extern char drf_val8;
extern int drf_val16;
extern long drf_val32;
extern long drf_addr;
