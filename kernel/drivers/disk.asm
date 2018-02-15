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

    push BIOS_DISK_BUF_SEG
    pop ds

.loop:
    call .read_sector_to_buf				; Read sector

    jc .done								; If carry exit with flag

    mov edi, ebx
    xor esi, esi

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
    pop ecx								; Restore GPRs
    pop ebx
    pop eax
    ret									; Exit routine

.read_sector_to_buf:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ds

    push KERNEL_SEGMENT
    pop ds

    mov dword [.lba_address_low], eax

    xor esi, esi
    mov si, .da_struct
    mov ah, 0x42

    clc										; Clear carry for int 0x13 because some BIOSes may not clear it on success

    int 0x13								; Call int 0x13

    pop ds
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
    .target_segment     dw  BIOS_DISK_BUF_SEG
    .lba_address_low    dd  0
    .lba_address_high   dd  0

; Buffer and buffer status data.
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
    push es
    push KERNEL_SEGMENT
    pop es
    mov ebx, disk_buffer
    mov ecx, 1
    call read_sectors
    pop es
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
    
    push ebx
    push eax
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
    
    push ebx
    push eax
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
