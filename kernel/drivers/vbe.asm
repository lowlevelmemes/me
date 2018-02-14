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
    .reserved1  times 206 db 0
