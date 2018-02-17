org 0x0010      ; loaded at ffff:0010 (hma)
bits 16

; Include defines
%include "kernel/defines.asm"

; BIOS routines relying functions here
call detect_mem
call vbe_init

; Enter REAL FUCKING MODE 32
%include "kernel/rm32.asm"

; Call initialisation routines
call init_pic
call init_ivt
call init_pit

pushad
call _init_graphics
popad

; enable interrupts
sti

halt:
    hlt
    jmp halt

; enable scheduler
mov byte [sched_status], 1

jmp $       ; halt

; Null-terminated strings we print.
stub db 0x0a, 'me', 0x0a, 0

memmsg db "Bytes of memory detected: ", 0x00

generic_program:
.begin:
incbin "generic_program.bin"
.end:
.size equ .end - .begin

; Include dependencies here

%include "kernel/drivers/keyboard.asm"
%include "kernel/drivers/pic.asm"
%include "kernel/gdt.asm"
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
%include "kernel/drivers/graphics.c.asm"
