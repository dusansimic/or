code_seg    SEGMENT
        ASSUME cs:code_seg

; Startni deo i ucitavanje brojeva u registre 
start:  mov ax, 14
        mov bx, 3

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

code_seg    ENDS
END
