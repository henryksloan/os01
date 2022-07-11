bits 16
start: jmp boot

msg db "Welcome to My Operating System!", 0ah, 0dh, 0h

gdt_start:
    ; Null descriptor
    dd 0x0 ; 4 byte
    dd 0x0 ; 4 byte

; GDT for code segment. base = 0x00000000, length = 0xfffff
; for flags, refer to os-dev.pdf document, page 36
gdt_code:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 10011010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

; GDT for data segment. base and length identical to code segment
gdt_data:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0

gdt_user_code:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 11111010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

gdt_user_data:
    dw 0xffff
    dw 0x0
    db 0x0
    db 11110010b
    db 11001111b
    db 0x0

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; size (16 bit), always one less of its true size
    dd gdt_start ; address (32 bit)

boot:
    cli
    cld

    xor bh, bh
    xor bl, bl
    call moveCursor

    mov ax, cs
    mov ds, ax
    mov si, msg
    call writeString

    call loadKernel
    jmp jumpProtected

    hlt

jumpProtected:
   ; enable A20 bit
   mov ax, 0x2401
   int 0x15
   ; mov eax, [gdt_descriptor]
   ; lgdt [eax]
   lgdt [gdt_descriptor]
   mov eax, cr0
   or al, 1       ; set PE (Protection Enable) bit in CR0 (Control Register 0)
   mov cr0, eax
   ; jmp 0x08:0x518 ; [500h + 0x18]
   jmp 08h:protMain ; [500h + 0x18]

; Read the kernel starting at sector 2, then jump to it
loadKernel:
    ; Set buffer as 0x50:00 (= 0x500)
    mov ax, 50h
    mov es, ax
    xor bx, bx

    mov al, 17
    mov ch, 0 ; track 0
    mov cl, 2 ; first sector to read (2)
    mov dh, 0 ; head 0
    mov dl, 0 ; drive 0

    ; Read from floppy disk to buffer
    mov ah, 0x02
    int 0x13
    ret

; Move cursor to position (row, col) given by (bh, bl)
moveCursor:
    mov ah, 02h
    mov dh, bh
    mov ch, bh
    mov dl, bl
    xor bh, bh
    int 10h
    mov bh, ch
    ret

; Write the ASCII value in al at the cursor
writeChar:
    mov ah, 0ah
    xor bh, bh
    mov cx, 1
    int 10h
    ret

; Write the null-terminated string from ds:si at the cursor
writeString:
    ; Store initial cursor position in (row, col) = (bh, bl)
    mov ah, 03h
    xor bh, bh
    int 10h
    mov bh, dh
    mov bl, dl

    loop:
    mov al, BYTE [ds:si]
    cmp al, 00h
    je return
    cmp al, 0ah
    je newline
    jmp checkCarriage
    newline:
    add bh, 1
    jmp continue
    checkCarriage:
    cmp al, 0dh
    je carriage
    jmp write
    carriage:
    xor bl, bl
    jmp continue
    write:
    call writeChar
    add bl, 1
    continue:
    call moveCursor
    add si, 1
    jmp loop

    return:
    ret

bits 32
protMain:
    mov ax, 0x10      ; 0x10 is the offset in the GDT to our data segment
    mov ds, ax        ; Load all data segment selectors
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebx, 0xb8000
    mov al, 'X'
    or eax, 0x0100
    mov word [ebx], ax
    jmp [500h + 0x18]
    hlt

times 510 - ($-$$) db 0
dw 0xAA55
