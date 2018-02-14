org 0x7C00						; BIOS loads us here (0000:7C00)
bits 16							; 16-bit real mode code

jmp short code_start			; Jump to the start of the code

times 64-($-$$) db 0x00			; Pad some space for the echidnaFS header

; Start of main bootloader code

code_start:

cli
jmp 0x0000:initialise_cs		; Initialise CS to 0x0000 with a long jump
initialise_cs:
xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
mov sp, 0x7BF0
sti

mov byte [drive_number], dl		; Save boot drive in memory

mov si, LoadingMsg				; Print loading message using simple print (BIOS)
call simple_print

; ****************** Load stage 2 ******************

mov si, Stage2Msg				; Print loading stage 2 message
call simple_print

mov ax, 1						; Start from LBA sector 1
mov ebx, 0x7E00					; Load to offset 0x7E00
mov cx, 7						; Load 7 sectors
call read_sectors

jc err							; Catch any error

mov si, DoneMsg
call simple_print				; Display done message

jmp 0x7E00						; Jump to stage 2

err:
mov si, ErrMsg
call simple_print

halt:
hlt
jmp halt

;Data

LoadingMsg		db 0x0D, 0x0A, 'Loading me...', 0x0D, 0x0A, 0x0A, 0x00
Stage2Msg		db 'Loading Stage 2...', 0x00
ErrMsg			db 0x0D, 0x0A, 'Error, system halted.', 0x00
DoneMsg			db '  DONE', 0x0D, 0x0A, 0x00

;Includes

%include 'bootloader/includes/simple_print.inc'
%include 'bootloader/includes/disk.inc'

drive_number				db 0x00				; Drive number

times 510-($-$$)			db 0x00				; Fill rest with 0x00
bios_signature				dw 0xAA55			; BIOS signature

; ************************* STAGE 2 ************************

; ***** A20 *****

mov si, A20Msg					; Display A20 message
call simple_print

call enable_a20					; Enable the A20 address line to access the full memory
jc err							; If it fails, print an error and halt

mov si, DoneMsg
call simple_print				; Display done message

; ***** Unreal Mode *****

mov si, UnrealMsg				; Display unreal message
call simple_print

lgdt [GDT]						; Load the GDT

%include 'bootloader/includes/enter_unreal.inc'		; Enter Unreal Mode

mov si, DoneMsg
call simple_print				; Display done message

; ***** Kernel *****

; Load the kernel to 0x100000 (1 MiB)

mov si, KernelMsg				; Show loading kernel message
call simple_print

mov esi, kernel_name
mov ebx, 0x100000				; Load to offset 0x100000
call load_file

jc err							; Catch any error

mov si, DoneMsg
call simple_print				; Display done message

; *** Setup registers ***

cli
mov ax, 0xffff
mov ds, ax
mov es, ax
mov ss, ax
mov fs, ax
mov gs, ax
mov esp, 0xfff0
sti

jmp 0xffff:0x0010

;Data

kernel_name		db 'me.bin', 0x00
A20Msg			db 'Enabling A20 line...', 0x00
UnrealMsg		db 'Entering Unreal Mode...', 0x00
KernelMsg		db 'Loading kernel...', 0x00

;Includes

%include 'bootloader/includes/echfs.inc'
%include 'bootloader/includes/disk2.inc'
%include 'bootloader/includes/a20_enabler.inc'
%include 'bootloader/includes/gdt.inc'

times 4096-($-$$)			db 0x00				; Padding
