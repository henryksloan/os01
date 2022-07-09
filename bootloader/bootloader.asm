org 0x7c00
bits 16
start: jmp boot

msg db "Welcome to My Operating System!", 0ah, 0dh, 0h

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

    jmp readAndJumpKernel

    hlt

; Read the kernel starting at sector 2, then jump to it
readAndJumpKernel:
    ; Set buffer as 0x50:00 (= 0x500)
    mov ax, 0x50
    mov es, ax
    xor bx, bx

    mov al, 2 ; read 2 sectors
    mov ch, 0 ; track 0
    mov cl, 2 ; first sector to read (2)
    mov dh, 0 ; head 0
    mov dl, 0 ; drive 0

    ; Read from floppy disk to buffer
    mov ah, 0x02
    int 0x13
    jmp 0x50:0x0

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

times 510 - ($-$$) db 0
dw 0xAA55
