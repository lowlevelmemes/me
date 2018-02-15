bits 16
check_cpuid:
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21

    push eax
    popfd
    
    pushfd
    pop eax
    
    push ecx
    popfd

    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov si, .no_cpuid_msg
    call simple_print
    cli
    hlt
.no_cpuid_msg db 'No CPUID available, aborting...', 0x0d, 0x0a, 0

enable_sse:
    mov eax, 0x1
    cpuid
    test edx, 1 << 25
    jz .no_sse

    mov eax, cr0
    and ax, 0xFFFB
    or ax, 0x2
    mov cr0, eax
    mov eax, cr4
    or ax, 3 << 9
    mov cr4, eax

    ret
.no_sse:
    mov si, .no_sse_msg
    call simple_print
    cli
    hlt
.no_sse_msg db 'No SSE, aborting...', 0x0d, 0x0a, 0
