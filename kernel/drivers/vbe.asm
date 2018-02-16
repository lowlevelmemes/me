bits 16

; The default W/H of the screen.
WIDTH equ 800
HEIGHT equ 600

align 32
vbe_width dw WIDTH
vbe_height dw HEIGHT

align 16
vbe_info:
    .signature      db "VBE2"
    .version        dw 0
    .oem            dd 0
    .caps           dd 0
    .modes          dd 0
    .memory         dw 0
    .soft_rev       dw 0
    .vendor         dd 0
    .prod_name      dd 0
    .prod_rev       dd 0
    .reserved       times 222 db 0
    .oem_data       times 256 db 0

align 16
vbe_mode_info:
    .attributes     dw 0
    .window_a       db 0
    .window_b       db 0
    .granularity    dw 0
    .window_size    dw 0
    .segment_a      dw 0
    .segment_b      dw 0
    .win_func_ptr   dd 0 
    .pitch          dw 0
    .width          dw 0
    .height         dw 0
    .w_char         db 0
    .y_char         db 0
    .planes         db 0
    .bpp            db 0
    .banks          db 0
    .memory_model   db 0
    .bank_size      db 0
    .image_pages    db 0
    .resv0          db 0
    
    .red_mask       db 0
    .red_pos        db 0
    .green_mask     db 0
    .green_pos      db 0
    .blue_mask      db 0 
    .blue_pos       db 0
    .resv_mask      db 0
    .resv_pos       db 0
    .dir_colour     db 0

    .framebuffer    dd 0
    .off_mem_off    dd 0
    .off_mem_size   dw 0
    .reserved1      times 206 db 0

align 16
vbe_edid:
    .padding        times 8 db 0
    .man_id         dw 0
    .edid_code      dw 0
    .serial_no      dd 0
    .week           db 0
    .year           db 0
    .version        db 0
    .revision       db 0
    .input          db 0
    .width_cm       db 0
    .height_cm      db 0
    .gamma          db 0
    .dpms_flags     db 0
    .chroma         times 10 db 0
    .timings1       db 0
    .timings2       db 0
    .r_timing       db 0
    .std_timing     times 8 dw 0
    .timing_desc1   times 18 db 0
    .timing_desc2   times 18 db 0
    .timing_desc3   times 18 db 0
    .timing_desc4   times 18 db 0
    .reserved       db 0
    .checksum       db 0

align 32
; Data structure that stores information about the current state of the screen.
_framebuffer    dd 0
_width          dd 0
_height         dd 0
_bpp            dd 0

; vbe_init - Perform the VBE initialisation.
vbe_init:
    pushad
    push ds
    push es

    push KERNEL_SEGMENT
    push KERNEL_SEGMENT
    pop ds
    pop es

    ; dump vga font
    mov di, _vga_font
    call dump_vga_font

    push es ; Save the Extra Segment Register - I've read that some BIOses will destroy ES.
    mov ax, 0x4f00
    mov di, vbe_info
    int 0x10
    pop es

    ; Check if VBE is available
    cmp ax, 0x4f
    jne .no_vbe

    cmp dword [vbe_info], "VESA"
    jne .no_vbe

    ; Check if we are using an older VBE standard
    cmp word [vbe_info.version], 0x200
    jl .old_vbe

    ; Read EDID to determine a suitable mode. wiki.osdev.org/EDID
    push es
    mov ax, 0x4f15
    mov bl, 1
    xor cx, cx
    xor dx, dx
    mov di, vbe_edid
    int 0x10
    pop es

    ; Succ?
    cmp ax, 0x4f
    jne .use_default ; Failed EDID.

    ; If the byte is zero, it means there is no specific mode. Use the default instead.
    cmp byte [vbe_edid.timing_desc1], 0x00
    je .use_default    

    ; Width. 
    mov ax, word [vbe_edid.timing_desc1+2]
    mov word [vbe_width], ax
    mov ax, word [vbe_edid.timing_desc1+4]
    and ax, 0xf0
    shl ax, 4
    or word [vbe_width], ax

    ; Height.
    mov ax, word [vbe_edid.timing_desc1+5]
    mov word [vbe_height], ax
    mov ax, word [vbe_edid.timing_desc1+7]
    and ax, 0xf0
    shl ax, 4
    or word [vbe_height], ax

    ; Check that the dimensions were calculated properly.
    cmp word [vbe_width], 0
    je .use_default

    cmp word [vbe_height], 0
    je .use_default

    ; Set a suitable mode.
    mov ax, word [vbe_width]
    mov bx, word [vbe_height]
    mov cl, 32 ; Use 32 bpp by default
    call vbe_set_mode
    jc .use_default
    jmp .out

.use_default:
    mov word [vbe_width], WIDTH
    mov word [vbe_height], HEIGHT
.set_mode:
    mov ax, word [vbe_width]
    mov bx, word [vbe_height]
    mov cl, 32
    call vbe_set_mode
    jc .bad_mode ; Can't use the default, abort
    jmp .out

.no_vbe:
    mov si, .no_vbe_msg
    call simple_print
    cli
    hlt
.old_vbe:
    mov si, .old_vbe_msg
    call simple_print
    cli
    hlt
.bad_mode:
    mov si, .bad_mode_msg
    call simple_print
    cli
    hlt
.out:
    pop es
    pop ds
    popad
    ret

.no_vbe_msg db 'VESA BIOS extensions unavailable, aborting...', 0x0a, 0
.old_vbe_msg db 'Error: We need VBE 2.0 or newer, aborting...', 0x0a, 0
.bad_mode_msg db 'Failed setting VBE mode, aborting...', 0x0a, 0

; reference: https://wiki.osdev.org/User:Omarrx024/VESA_Tutorial
; width -> AX
; height -> BX
; bpp -> CL
vbe_set_mode:
    pushad
    push ds
    push es
    push fs

    push KERNEL_SEGMENT
    push KERNEL_SEGMENT
    pop ds
    pop es

    ; Save arguments
    mov word [.width], ax
    mov word [.height], bx
    mov byte [.bpp], cl

    ; Get an array of available video modes.
    push es ; Save ES
    mov ax, 0x4f00
    mov di, vbe_info ; Return saved here.
    int 0x10
    pop es

    ; Check if success
    cmp ax, 0x4f
    jne .error

    ; Save video mode array into FS:SI
    ; Save offset
    mov ax, word [vbe_info.modes]
    mov word [.offset], ax
    mov si, ax
    ; Save segment
    mov ax, word [vbe_info.modes+2]
    mov fs, ax

.find_mode:
    mov dx, word [fs:si]

    ; gotta go fast
    not dx
    test dx, dx
    jz .error
    not dx

    ; save mode
    add si, 2
    mov word [.offset], si
    mov word [.mode], dx

    ; Return modeinfo
    push es
    mov ax, 0x4f01
    mov cx, dx ; current mode
    mov di, vbe_mode_info
    int 0x10
    pop es

    cmp ax, 0x4f
    jne .error

    ; Check if the data we have is correct.
    mov ax, word [.width]
    cmp ax, word [vbe_mode_info.width]
    jne .next_mode

    mov ax, word [.height]
    cmp ax, word [vbe_mode_info.height]
    jne .next_mode

    mov al, byte [.bpp]
    cmp al, byte [vbe_mode_info.bpp]
    jne .next_mode

    ; LFB supported?
    test byte [vbe_mode_info.attributes], 0x81
    jz .next_mode

    ; If we are here, the mode is correct. Time to set it!
	mov ax, word [.width]
	mov word [_width], ax
	mov ax, word [.height]
	mov word [_height], ax
	mov eax, dword [vbe_mode_info.framebuffer]
	mov dword [_framebuffer], eax

    ; Set mode
    push es
    mov ax, 0x4f02
    mov bx, word [.mode]
    ; Enable linear framebuffer.
    or bx, 0x4F00
    mov di, 0
    int 0x10
    pop es

    cmp ax, 0x4f
    jne .error

    clc
    jmp .out

.next_mode:
    mov si, word [.offset]
    jmp .find_mode

.error:
    stc

.out:
    pop fs
    pop es
    pop ds
    popad
    ret

.width dw 0
.height dw 0
.bpp db 0
.offset dw 0
.mode dw 0

_vga_font       times 4096 db 0
; Dump VGA font into ES:DI
dump_vga_font:
    pushad
    push ds

    push di
    push es

    xor bp, bp
    mov ax, 0x1130
    xor bx, bx
    mov bh, 6
    int 0x10

    mov si, bp
    push es
    pop ds
    pop es
    pop di

    mov cx, 4096
    rep movsb

    pop ds
    popad
    ret
