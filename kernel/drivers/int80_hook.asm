; This will be the interrupt for syscalls
; For now, leave as a stub

int80_hook:
    pusha
    push ds
    push KERNEL_SEGMENT
    pop ds
    mov si, .msg
    call simple_print
    pop ds
    popa
    ret

.msg db "int 0x80 called.", 0x0d, 0x0a, 0
