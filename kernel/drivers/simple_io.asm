; Print a hex number in EDI
hex_print:
    pushad
    push ds

    push KERNEL_SEGMENT
    pop ds

    mov ah, 0x0e
    mov al, '0'
    int 0x10
    mov al, 'x'
    int 0x10

    push edi
    pop eax

    mov cx, 8
  .loop:
    push eax
    push cx
    dec cl
    shl cl, 2
    shr eax, cl
    and al, 0x0f
    xor bx, bx
    mov bl, al
    mov al, byte [.hex_tab + bx]
    mov ah, 0x0e
    int 0x10
    pop cx
    pop eax
    loop .loop

    pop ds
    popad
    ret

.hex_tab    db  "0123456789abcdef"


; Print a string using the BIOS.
; IN:
; DS:SI - Points to a string terminated by 0x00.
simple_print:
    push ax                 ; Save registers
    push si
    mov ah, 0x0e            ; int 0x10, function 0x0e (print character)
.loop:
    lodsb                   ; Load character from string
    test al, al             ; Is is the 0x00 terminator?
    jz .done                ; If it is, exit routine
    cmp al, 0x0a
    je .newline
    int 0x10                ; Call BIOS
    jmp .loop               ; Repeat!
.newline:
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    jmp .loop
.done:
    pop si                  ; Restore registers
    pop ax
    ret                     ; Exit routine

; Get a string using the BIOS.
; IN:
; ES:DI - points to a buffer.
; CX - maximum length.
simple_input:
    pusha
    mov si, di
    dec cx
.loop:
    xor ax, ax
    int 0x16
    cmp al, 0x08
    je .backspace
    cmp al, 0x0d
    je .enter
    test cx, cx
    jz .loop
    mov ah, 0x0e ; Print the character that was read.
    int 0x10
    stosb
    dec cx
    jmp .loop
.backspace:
    cmp si, di
    je .loop
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    dec di
    inc cx
    jmp .loop
.enter:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    xor al, al
    stosb ; Store 0 into ES:DI.
    popa
    ret
