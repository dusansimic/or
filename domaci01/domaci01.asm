data    segment
        broj1   dw      14
        broj2   dw      3
ends

code    segment
        assume cs:code, ds:data

; Startni deo i ucitavanje brojeva u registre
start:  mov dx, data
        mov ds, dx

        mov ax, broj1
        mov bx, broj2

        ; Sabiranje dva broja
        add ax, bx

        ; Ucitavanje jedinice u si registar u slucaju da je
        ; broj paran
        mov si, 1

        ; Provera da li je broj paran. Ukoliko je paran
        ; Zero flag ce biti podignut i time se zavrsava
        ; program sa narednim jump-om. Ukoliko je broj
        ; neparan, zero flag ce biti spusten i
        ; preskocice se jump.
        test ax, 0001h
        jz kraj

        ; Ako je broj neparan onda ucitati nulu u si
        ; registar.
        mov si, 0

kraj:   jmp kraj

ends

end start
