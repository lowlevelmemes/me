int09_hook:
    pusha
    in al, 0x60     ; read from keyboard
    mov al, 0x20    ; acknowledge interrupt to PIC0
    out 0x20, al
    popa
    iretw
