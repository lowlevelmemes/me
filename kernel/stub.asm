org 0x0010      ; loaded at ffff:0010 (hma)

mov si, stub
call simple_print

prompt_loop:
    mov si, prompt
    call simple_print
    mov di, buf
    mov cx, 64
    call simple_input
    mov si, buf
    call simple_print
    jmp prompt_loop

halt:
    hlt
    jmp halt

stub db 'me', 0x0d, 0x0a, 0

prompt db 0x0d, 0x0a, 'C:\>', 0

buf times 64 db 0

simple_print:

; **************************************
;     Prints a string using the BIOS
; **************************************

; IN:
; DS:SI = points to a 0x00 terminated string

push ax						; Save registers
push si
mov ah, 0x0E				; int 0x10, function 0x0E (print character)
.loop:
	lodsb					; Load character from string
	test al, al				; Is is the 0x00 terminator?
	jz .done				; If it is, exit routine
	int 0x10				; Call BIOS
	jmp .loop				; Repeat!
.done:
	pop si					; Restore registers
	pop ax
	ret						; Exit routine

simple_input:

; ************************************
;     Gets a string using the BIOS
; ************************************

; IN:
; ES:DI = points to a buffer
; CX = max length

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
    mov ah, 0x0e
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
    stosb
popa
ret
