; default argument order:
; edi, esi, edx, ecx
; return: eax
; segments should be:
;  CS = KERNEL_SEGMENT
;  DS = KERNEL_SEGMENT
;  *S = USER_SEGMENT
; but of course this is a real mode so this is not guaranteed haha lol

syscall_print_string:
    ; edi = local pointer to the string (user segment SHOULD be in ES)

    push esi
    push ds

    push es
    pop ds

    mov esi, edi
    call simple_print

    xor eax, eax        ; return 0
    pop ds
    pop esi
    ret
