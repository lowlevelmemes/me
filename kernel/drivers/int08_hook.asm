int08_hook:
    pusha
    push ds
    push KERNEL_SEGMENT
    pop ds
    mov si, .msg
    ;call simple_print
    mov al, 0x20    ; acknowledge interrupt to PIC0
    out 0x20, al
    pop ds
    popa
    iret

.msg db "PIT interrupt.", 0x0d, 0x0a, 0
