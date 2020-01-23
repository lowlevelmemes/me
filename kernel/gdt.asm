GDT:

dw .GDTEnd - .GDTStart - 1	; GDT size
dd KERNEL_SEGMENT*0x10+.GDTStart				; GDT start

.GDTStart:

; Null descriptor (required)

.NullDescriptor:

dw 0x0000			; Limit
dw 0x0000			; Base (low 16 bits)
db 0x00				; Base (mid 8 bits)
db 00000000b		; Access
db 00000000b		; Granularity
db 0x00				; Base (high 8 bits)

; Real mode 32

.Rm32Code:

dw 0xFFFF			; Limit
dw 0x0000			; Base (low 16 bits)
db 0x00				; Base (mid 8 bits)
db 10011010b		; Access
db 11001111b		; Granularity
db 0x00				; Base (high 8 bits)

.Rm32Data:

dw 0xFFFF			; Limit
dw 0x0000			; Base (low 16 bits)
db 0x00				; Base (mid 8 bits)
db 10010010b		; Access
db 11001111b		; Granularity
db 0x00				; Base (high 8 bits)

; Real mode 16

.Rm16Code:

dw 0xFFFF			; Limit
dw 0x0000			; Base (low 16 bits)
db 0x00				; Base (mid 8 bits)
db 10011010b		; Access
db 10001111b		; Granularity
db 0x00				; Base (high 8 bits)

.Rm16Data:

dw 0xFFFF			; Limit
dw 0x0000			; Base (low 16 bits)
db 0x00				; Base (mid 8 bits)
db 10010010b		; Access
db 10001111b		; Granularity
db 0x00				; Base (high 8 bits)

.GDTEnd:
