; Sets the PIT's channel 0 to the frequency specified in "kernel/defines.asm"

init_pit:
    push ax

    mov al, 0x36
    out 0x43, al

    mov ax, 1193182 / PIT_FREQUENCY
    out 0x40, al
    mov al, ah
    out 0x40, al

    pop ax
    ret
