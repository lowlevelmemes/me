org 0x0010      ; loaded at ffff:0010 (hma)
bits 16

; Include defines
%include "kernel/defines.asm"

; Call initialisation routines
cli
call detect_mem
mov si, memmsg
call simple_print
mov edi, dword [memory_size]
call hex_print
call init_ivt
call init_pit
;call check_cpuid
;call enable_sse
;call vbe_init
sti

; Print "me" to the screen.
mov si, stub
call simple_print

pusha
call _cmain
popa

; test launch a userland program
mov esi, filename
call start_task
mov esi, filename
call start_task
mov esi, filename
call start_task
mov esi, filename
call start_task
mov esi, filename
call start_task

; enable scheduler
mov byte [sched_status], 1

jmp $       ; halt

; Null-terminated strings we print.
stub db 0x0a, 'me', 0x0a, 0

memmsg db "Bytes of memory detected: ", 0x00

filename db "generic_program.bin", 0

; Include dependencies here

%include "cc/system.c.asm"
%include "kernel/tasking.asm"
%include "kernel/alloc.asm"
%include "kernel/drivers/ivt.asm"
%include "kernel/drivers/pit.asm"
%include "kernel/drivers/simple_io.asm"
%include "kernel/drivers/int80_hook.asm"
%include "kernel/drivers/disk.asm"
%include "kernel/drivers/echfs.asm"
%include "kernel/syscalls/syscalls.asm"
%include "kernel/drivers/vbe.asm"
;%include "kernel/init.asm"
%include "kernel/ctest.c.asm"
