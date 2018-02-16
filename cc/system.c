#include <system.h>

char drf_val8 = 0;
int drf_val16 = 0;
long drf_val32 = 0;
long drf_addr = 0;

/* support functions */
/* reference: https://github.com/lkundrak/dev86/blob/master/libc/bcc/bcc_long.c */

#asm

laddl:
laddul:
    add ax, [di]
    adc bx, [di+2]
    ret

lmull:
lmulul:
    mov cx, ax
    mul word [di+2]
    xchg ax, bx
    mul word [di]
    add bx, ax
    mov ax, word [di]
    mul cx
    add bx, dx
    ret

#endasm
