org 0x0000
bits 16

mov ax, 0x20            ; print string
mov di, msg
int 0x80

jmp $                   ; wait

msg db "program launched", 0x0a, 0
