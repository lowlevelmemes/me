
memory_top dd 0x500

task_table:
times 64 dd 0       ; array of processes SS:SP (64 processes max)

task_ptr dw 0

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

add dword [fs:memory_top], ecx     ; decrease by file size
add dword [fs:memory_top], 16       ; fix alignment
and dword [fs:memory_top], 0xfffffff0
add dword [fs:memory_top], 0x1000  ; 0x1000 for the stack

shr ebx, 4      ; calculate the actual segment (SS)
mov ax, bx
mov bx, word [fs:task_ptr]
inc word [fs:task_ptr]
mov word [fs:task_table + bx], ax    ; store task SS
add cx, 0xff0                   ; store task SP
mov word [fs:task_table + bx + 2], cx

; return PID in EAX
xor eax, eax
mov ax, bx

pop fs
pop es
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
ret
