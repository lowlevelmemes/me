; Enters REAL HOLY MODE 32

cli

mov eax, cr0
or al, 1
mov cr0, eax

push dword 0x08
push dword KERNEL_SEGMENT*0x10+pm32
a32 o32 retf
pm32:
bits 32
mov ax, 0x10
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

mov eax, cr0
and al, 0xfe
mov cr0, eax

jmp KERNEL_SEGMENT:rm32
rm32:
mov ax, KERNEL_SEGMENT
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
mov esp, 0xfff0

; now in real mode 32
