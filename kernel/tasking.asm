memory_top dd 0x500

task_table:
times 64 dd 0       ; array of processes SS:SP (64 processes max)

task_ptr dw 0
task_sel dw 0

sched_status    db  0

int08_hook:
    ; save task state in the task's stack
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    push ds
    push es
    push fs
    push gs

    push KERNEL_SEGMENT
    pop ds

    ; check if scheduling is disabled
    cmp byte [sched_status], 0
    je .reentry

.switch:
    ; switch tasks
    mov bx, word [task_sel]
    cmp bx, word [task_ptr]
    je .restart

    add word [task_sel], 4

    ; load task SS
    mov ax, word [task_table + bx]
    mov ss, ax
    ; load task SP
    mov sp, word [task_table + bx + 2]

.reentry:
    mov al, 0x20    ; acknowledge interrupt to PIC0
    out 0x20, al
    pop gs          ; restore task state
    pop fs
    pop es
    pop ds
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iret

.restart:
    mov word [task_sel], 0
    jmp .switch

; binary name in DS:ESI
; returns PID in EAX
start_task:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    push es
    push fs

    push KERNEL_SEGMENT
    pop fs

    push 0
    pop es
    mov ebx, dword [fs:memory_top]
    call load_file

    cli     ; disable ints while fucking with segments and stack

    add dword [fs:memory_top], ecx     ; decrease by file size
    add dword [fs:memory_top], 16       ; fix alignment
    and dword [fs:memory_top], 0xfffffff0
    add dword [fs:memory_top], 0x1000  ; 0x1000 for the stack

    shr ebx, 4      ; calculate the actual segment (SS)
    mov ax, bx
    mov bx, word [fs:task_ptr]
    add word [fs:task_ptr], 4
    mov word [fs:task_table + bx], ax    ; store task SS
    mov dx, ss
    mov word [fs:.kernel_ss], dx
    mov ss, ax
    add cx, 0xff0
    mov word [fs:.kernel_sp], sp
    mov sp, cx

    ; push iret values
    push 0x202
    push ax
    push 0          ; entry point

    ; push register states for the process
    push dword 0    ; eax
    push dword 0    ; ebx
    push dword 0    ; ecx
    push dword 0    ; edx
    push dword 0    ; esi
    push dword 0    ; edi
    push dword 0    ; ebp
    push ax         ; ds
    push ax         ; es
    push ax         ; fs
    push ax         ; gs

    mov word [fs:task_table + bx + 2], sp   ; store task SP

    ; restore kernel stack
    mov ax, word [fs:.kernel_ss]
    mov ss, ax
    mov sp, word [fs:.kernel_sp]

    ; return PID in EAX
    xor eax, eax
    mov ax, bx

    sti    ; restore interrupts

    pop fs
    pop es
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.kernel_ss  dw  0
.kernel_sp  dw  0
