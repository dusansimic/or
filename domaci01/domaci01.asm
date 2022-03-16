data_seg    SEGMENT
        broj1   dw  14
        broj2   dw  2  
data_seg    ENDS

code_seg    SEGMENT
        ASSUME cs:code_seg, ds:data_seg

; Startni deo i ucitavanje brojeva u registre 
start:  mov dx, offset data_seg
        mov ds, dx

        mov ax, broj1
        mov bx, broj2       

        ; Sabiranje dva broja
        add ax, bx
                
        ; Ucitavanje jedinice u si registar u slucaju da je
        ; broj paran
        mov si, 1
        
        ; Provera da li je broj paran. Ukoliko je paran
        ; Zero registar ce biti podignut i time se zavrsava
        ; program sa narednim jump-om. Ukoliko je broj
        ; neparan, zero registar ce biti spusten i
        ; preskocice se jump.
        test ax, 0001h
        jz kraj  
        
        ; Ako je broj neparan onda ucitati nulu u si
        ; registar.
        mov si, 0
        
kraj:   jmp kraj

code_seg    ENDS
END