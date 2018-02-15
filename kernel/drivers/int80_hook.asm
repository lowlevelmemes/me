
; syscall lookup table
slt:
    times 0x20  dw invalid
    dw    syscall_print_string
slt_max equ $-slt


; This will be the interrupt for syscalls
; For now, leave as a stub
int80_hook:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    push ds

    push KERNEL_SEGMENT
    pop ds
    add ax, ax      ; ax *= 2;
    cmp ax, slt_max
    jae .invalid
    mov bx, ax
    call [slt + bx] ; call syscall
.invalid_out:
    pop ds
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    iret
.invalid:
    mov eax, -1
    jmp .invalid_out

; Invalid syscall handler
invalid:
    mov eax, -1
    ret
