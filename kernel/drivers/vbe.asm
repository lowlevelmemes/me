bits 16

; Buffer can be a maximum of 16MiB in size.
VBE_BUFFER = 0x1000000 
VBE_PHYS_BUFFER = 0xD0000000
VBE_BACK_BUFFER = VBE_PHYS_BUFFER + VBE_PHYS_BUFFER

; The default W/H of the screen.
WIDTH = 800
HEIGHT = 600

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
    .attributes     dd 0
    .window_a       db 0
    .window_b       db 0
    .granularity    dd 0
    .window_size    dd 0
    .segment_a      dd 0
    .segment_b      dd 0
    .win_func_ptr   dw 0 
    .pitch          dd 0
    .width          dd 0
    .height         dd 0
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

    .framebuffer    dw 0
    .off_mem_off    dw 0
    .off_mem_size   dd 0
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
screen:
    .width          dd 0
    .height         dd 0
    .bpp            dd 0
    .bytes_per_pix  dd 0
    .bytes_per_l    dd 0
    .screen_size    dd 0
    .screen_size_dqwords dd 0
    .framebuffer    dd 0
    .x              dd 0
    .y              dd 0
    .x_max          dd 0
    .y_max          dd 0

; vbe_init - Perform the VBE initialisation.
vbe_init:
    push es ; Save the Extra Segment Register - I've read hat some BIOses will destroy ES.
    mov dword[vbe_info], "VBE2"
    mov ax, 0x4f00
    mov di, vbe_info
    int 0x10
    pop es

    ; Check if VBE is available
    cmp ax, 0x4f
    jne .no_vbe

    cmp dword[vbe_info], "VESA"
    jne .no_vbe

    ; Check if we are using an older VBE standard
    cmp [vbe_info.version], 0x200
    jl .old_vbe

    ; Read EDID to determine a suitable mode. wiki.osdev.org/EDID
    push es,
    mov ax, 0x4f01
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
    cmp byte[vbe_edid.timing_desc1], 0x00
    je .use_default    
    
    ; Width. 
    mov ax, byte[vbe_edid.timing_desc1+2]
    mov [vbe_width], ax
    mov ax, byte[vbe_edid.timing_desc1+4]
    and ax, 0xf0
    shl ax, 4
    or [vbe_width], ax

    ; Height.
    mov ax, byte[vbe_edid.timing_desc1+5]
    mov [vbe_height], ax
    mov ax, byte[vbe_edid.timing_desc1+7]
    and ax, 0xf0
    shl ax, 4
    or [vbe_height], ax

    ; Check that the dimensions were calculated properly.
    cmp [vbe_width], 0
    je .use_default
    
    cmp [vbe_height], 0
    je .use_default

    ; TODO: Set mode.

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
.use_default:
    mov vbe_width, WIDTH
    mov vbe_height, HEIGHT
.no_vbe_msg db 'VESA BIOS extensions unavailable, aborting...', 0x0d, 0x0a, 0
.old_vbe_msg db 'Error: We need VBE 2.0 or newer, aborting...', 0x0d, 0x0a, 0
.bad_mode_msg db 'Failed setting VBE mode, aborting...', 0x0d, 0x0a, 0
