org 0x0010      ; loaded at ffff:0010 (hma)

anchor:
    db 'STIVALE1 ANCHOR'
    db 32
    dq 0x100000
    dq 0
    dq 0
    dq stivale_hdr + 0xffff0

stivale_hdr:
    dq stack.top + 0xffff0
    dw 0
    dw 0
    dw 0
    dw 0
    dq _start + 0xffff0

stack:
    times 256 db 0
  .top:

IDT:
    dw 0x3ff
    dd 0

bits 32

_start:
    lidt [IDT + 0xffff0]

    lgdt [GDT + 0xffff0]
    jmp 0x18:.mode16 + 0xffff0
    bits 16
  .mode16:
    mov ax, 0x20
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov eax, cr0
    and al, 0xfe
    mov cr0, eax
    jmp 0xffff:.rmode
  .rmode:
    mov ax, 0xffff
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0xfff0

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
