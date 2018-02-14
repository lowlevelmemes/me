read_sectors:

; ********************************************
;     Reads multiple LBA addressed sectors
; ********************************************

; IN:
; EAX = LBA starting sector
; DL = Drive number
; ES = Buffer segment
; EBX = Buffer offset
; CX = Sectors count

; OUT:
; Carry if error

push eax									; Save GPRs
push ebx
push ecx
push edx
push esi
push edi
push ds

push KERNEL_SEGMENT
pop ds

.loop:

push es
push ebx

mov bx, BIOS_DISK_BUF_SEG							; Load in a temp buffer
mov es, bx
xor bx, bx

call .read_sector						; Read sector

pop ebx
pop es

jc .done								; If carry exit with flag

mov edi, ebx
xor esi, esi

push BIOS_DISK_BUF_SEG
pop ds

push ecx
mov ecx, 512
a32 o32 rep movsb
pop ecx

inc eax									; Increment sector
add ebx, 512							; Add 512 to the buffer

loop .loop								; Loop!

.done:
pop ds
pop edi
pop esi
pop edx
pop ecx									; Restore GPRs
pop ebx
pop eax
ret										; Exit routine

.read_sector:

; IN:
; EAX = LBA sector to load
; DL = Drive number
; ES = Buffer segment
; BX = Buffer offset

; OUT:
; Carry if error

push eax
push ebx
push ecx
push edx
push esi
push edi

push es
pop word [.target_segment]
mov word [.target_offset], bx
mov dword [.lba_address_low], eax

xor esi, esi
mov si, .da_struct
mov ah, 0x42

clc										; Clear carry for int 0x13 because some BIOSes may not clear it on success

int 0x13								; Call int 0x13

pop edi
pop esi
pop edx
pop ecx
pop ebx
pop eax
ret										; Exit routine

align 4
.da_struct:
    .packet_size        db  16
    .unused             db  0
    .count              dw  1
    .target_offset      dw  0
    .target_segment     dw  0
    .lba_address_low    dd  0
    .lba_address_high   dd  0






disk_buffer times 512 db 0
disk_buffer_status db 0
sector_in_buffer dd 0

disk_read_byte:
    ; EAX = byte address
    ; DL = drive
    ; returns AL = byte (trashes EAX)
    
    push ebx
    push ecx
    push edx
    push ds
    push KERNEL_SEGMENT
    pop ds
    
    push edx
    mov ebx, 512
    xor edx, edx
    div ebx
    mov dword [.offset], edx
    pop edx
    
    cmp dword [sector_in_buffer], eax
    je .dont_load
    .load:
    mov dword [sector_in_buffer], eax
    mov byte [disk_buffer_status], 1
    mov ebx, disk_buffer
    mov ecx, 1
    call read_sectors
    .dont_load:
    cmp byte [disk_buffer_status], 0
    je .load
    
    mov ebx, disk_buffer
    add ebx, dword [.offset]
    xor eax, eax
    mov al, byte [ebx]
    
    pop ds
    pop edx
    pop ecx
    pop ebx
    ret   
    
    .offset dd 0

disk_read_word:
    ; EAX = word address
    ; DL = drive
    ; returns AX = word (trashes EAX)
    
    push eax
    push ebx
    inc eax
    call disk_read_byte
    shl eax, 8
    mov ebx, eax
    pop eax
    call disk_read_byte
    add ebx, eax
    mov eax, ebx
    pop ebx
    ret

disk_read_dword:
    ; EAX = dword address
    ; DL = drive
    ; returns EAX = dword (trashes EAX)
    
    push eax
    push ebx
    add eax, 2
    call disk_read_word
    shl eax, 16
    mov ebx, eax
    pop eax
    call disk_read_word
    add ebx, eax
    mov eax, ebx
    pop ebx
    ret

disk_cmp_strings:
    ; EAX = string address
    ; DS:ESI = string to compare
    ; DL = drive
    ; returns carry if equal
    
    push eax
    push esi
    
    clc
    .loop:
        push eax
        call disk_read_byte
        mov ah, al
        a32 o32 lodsb
        cmp ah, al
        jne .notequ
        test al, al
        jz .equ
        pop eax
        inc eax
        jmp .loop
    
    .notequ:
        clc
        jmp .done
    
    .equ:
        stc

    .done:
        pop eax
        pop esi
        pop eax
        ret
