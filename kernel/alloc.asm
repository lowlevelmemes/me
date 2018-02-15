ext_heap_top  dd  DEFAULT_HEAP_BASE
memory_size   dd  0

detect_mem:
    pushad

    xor eax, eax
    xor ebx, ebx
    xor cx, cx
    xor dx, dx

    mov ax, 0xe801          ; BIOS function

    clc                     ; Clear carry

    int 0x15                ; Detect memory

    jc .err                 ; Catch errors
    cmp ah, 0x86
    je .err
    cmp ah, 0x80
    je .err

    test cx, cx             ; Is CX null?
    jz .use_ax_bx

    mov ax, cx
    mov bx, dx

.use_ax_bx:
    test bx, bx             ; If mem > 16M == 0, there is not enough memory. Abort.
    jz .err
    mov eax, 0x10000        ; Get memory in bytes, and save it
    mul ebx

    add eax, 0x1000000      ; Add lower memory size

    push ds                 ; Save
    push KERNEL_SEGMENT
    pop ds
    mov dword [memory_size], eax
    pop ds

    popad
    ret

.err:
    push KERNEL_SEGMENT
    pop ds
    mov si, .errmsg
    call simple_print
.halt:
    cli
    hlt
    jmp .halt

.errmsg db "Error detecting memory, or not enough memory.", 0x0a
        db "System halted.", 0x00


; Expand (or contract) the kernel heap by EDI bytes (signed)
; Returns (in EAX) a pointer to the old top of the heap (PHYSICAL)

sbrk:
    push ebx
    push ds
    push KERNEL_SEGMENT
    pop ds
    mov eax, dword [ext_heap_top]
    add dword [ext_heap_top], edi
    cmp dword [ext_heap_top], DEFAULT_HEAP_BASE
    jb .underflow
    mov ebx, dword [memory_size]
    cmp dword [ext_heap_top], ebx
    jae .overflow
.out:
    pop ds
    pop ebx
    ret

.underflow:
    mov dword [ext_heap_top], DEFAULT_HEAP_BASE
    jmp .out

.overflow:
    push KERNEL_SEGMENT
    pop ds
    mov si, .errmsg
    call simple_print
.halt:
    cli
    hlt
    jmp .halt

.errmsg db "FATAL: Kernel ran out of memory.", 0x0a
        db "System halted.", 0x00
