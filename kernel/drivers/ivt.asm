; Define macros here, maybe we'll move them to a different file later

%macro int_hook 3
    mov word [%1 * 4], %3
    mov word [%1 * 4 + 2], %2
%endmacro

init_ivt:
    ; Hook the relevant interrupts

    cli
    push ds
    push 0
    pop ds

    ; All hooks should go here
    ;int_hook 0x08, KENREL_SEGMENT, int08_hook       ; PIT
    int_hook 0x80, KERNEL_SEGMENT, int80_hook       ; syscall interface

    pop ds
    sti

    ret
