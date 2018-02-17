_set_pic0_mask:
    push eax
    mov eax, dword [esp+8]
    out 0x21, al
    pop eax
    ret

_set_pic1_mask:
    push eax
    mov eax, dword [esp+8]
    out 0xa1, al
    pop eax
    ret

init_pic:
    ; we only care about IRQs 0 and 1 TBQH
    push dword 0b11111111
    call _set_pic1_mask
    add esp, 4
    push dword 0b11111100
    call _set_pic0_mask
    add esp, 4
    ret

