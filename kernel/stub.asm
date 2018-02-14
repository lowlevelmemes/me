org 0x0010      ; loaded at ffff:0010 (hma)
bits 16

; Include defines
%include "kernel/defines.asm"

; Call initialisation routines
cli
call init_ivt
call init_pit
sti

; Print "me" to the screen.
mov si, stub
call simple_print

; Print a prompt. The code:
; 1: Prints a DOS-style prompt,
; 2: Reads from the keyboard,
; 3: Does it all again.
prompt_loop:
    mov si, prompt
    call simple_print
    mov di, buf
    mov cx, 64
    call simple_input
    int 0x80            ; test int 0x80
    mov si, buf
    call simple_print
    jmp prompt_loop


halt:
    hlt
    jmp halt

; Null-terminated strings we print.
stub db 'me', 0x0d, 0x0a, 0
prompt db 0x0d, 0x0a, 'C:\>', 0
; Buffer of 0's, 64 in length.
buf times 64 db 0


; Include dependencies here

%include "kernel/drivers/ivt.asm"
%include "kernel/drivers/pit.asm"
%include "kernel/drivers/simple_io.asm"
%include "kernel/drivers/int80_hook.asm"
%include "kernel/drivers/int08_hook.asm"
