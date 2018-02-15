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

; test launch a userland program
mov esi, filename
call start_task

jmp $

; Null-terminated strings we print.
stub db 'me', 0x0d, 0x0a, 0
prompt db 0x0d, 0x0a, 'C:\>', 0
; Buffer of 0's, 64 in length.
buf times 64 db 0

filename db "generic_program.bin", 0

; Include dependencies here

%include "kernel/tasking.asm"
%include "kernel/drivers/ivt.asm"
%include "kernel/drivers/pit.asm"
%include "kernel/drivers/simple_io.asm"
%include "kernel/drivers/int80_hook.asm"
%include "kernel/drivers/int08_hook.asm"
%include "kernel/drivers/disk.asm"
%include "kernel/drivers/echfs.asm"
%include "kernel/syscalls/syscalls.asm"
