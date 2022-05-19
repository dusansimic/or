; multi-segment executable file template.

data segment
    ; add your data here!
    str db "                             "
    strn db "       "
    n dw 0
    prompt0 db "Unesite string: $"
    prompt1 db "String jeste palindrom$"
    prompt2 db "String nije palindrom$"
    pkey db "press any key...$"
ends

stack segment
    dw   128  dup(0)
ends

wchr macro c
    push ax
    push dx
    mov ah, 02
    mov dl, c
    int 21h
    pop dx
    pop ax
endm

wstr macro s
    push ax
    push dx
    mov dx, offset s
    mov ah, 09
    int 21h
    pop dx
    pop ax
endm

kraj_programa macro
    mov ax, 4c02h
    int 21h
endm

code segment

novi_red proc
    ; skladistenje trenutnih stanja registara
    push ax
    push bx
    push cx
    push dx
    ; podesavanje kodova za interrupt
    mov ah, 03
    mov bh, 0
    int 10h
    ; prelazak na sledeci red
    inc dh
    ; pomeranje na pocetak reda
    mov dl, 0
    ; podesavanje kodova za interrupt
    mov ah, 02
    int 10h
    ; vracanje stanja registara sa pocetka
    pop dx
    pop cx
    pop bx
    pop ax
    ret
novi_red endp

; modifikovana procedura za citanje stringa koja vraca
; duzinu ucitanog stringa kao preostali element na stack-u
rstr proc
    ; skladistenje trenutnih stanja registara
    ; ukupno je zauzeto 10 bajtova
    push ax
    push bx
    push cx
    push dx
    push si
    ; ucitavanje adrese stringa
    mov bp, sp
    mov dx, [bp+12] ; adresa je na 12-tom bajtu steka
    mov bx, dx
    ; ucitavanje adrese broja karaktera
    mov ax, [bp+14]
    mov byte [bx], al
    ; podesavanje kodova za interrupt (ucitavanje stringa)
    mov ah, 0ah
    int 21h
    ; upisivanje povratne vrednosti u si
    mov si, dx
    ; upisivanje broja ucitanih karaktera u cl (koristi se u petlji)
    mov ch, 0
    mov cl, [si+1]
    ; upisivanje broja ucitanih karaktera u adresu za taj broj
    mov [bp+16], cx
    ; pomeranje ucitanih karaktera za dva mesta u levo
kopiraj:
    mov al, [si+2]
    mov [si], al
    inc si
    loop kopiraj
    ; upisivanje $ na kraj stringa
    mov [si], '$'
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret 4
rstr endp

;; stack: [rez] [i] [j]
palindrom proc
    push ax
    push bx
    push dx
    push si
    push di
    push bp

    ; ucitati indeks levog i desnog slova koje se poredi
    mov bp, sp
    mov si, [bp+16]
    mov di, [bp+14]
    ; provera da li su se indeksi dodirnuli
    cmp si, di
    jbe cmpr_pal
    jmp kraj_rek

cmpr_pal:
    ; ucitavanje levog i desnog slova
    mov al, [si]
    mov bl, [di]
    ; poredjenje slova (da li je palindrom do ovde)
    cmp al, bl
    ; ako su isti, nastavlja se rekurzija
    je cont_pal
    ; ako nisu, postaviti da je resenje false (0)
    mov [bp+18], 0
    ; prekid rekurzije
    jmp kraj_rek

cont_pal:
    ; povecianje i smanjivanje indeksa
    inc si
    dec di
    ; pushovanje parametara rekurzije na stack
    ; posto je za sada string palindrom, resenje je true
    push 1
    push si
    push di
    call palindrom
    ; kad se vraca iz rekurzije, indeksi su uklonjeni sa
    ; stack-a i sp pokazuje na resenje
    ; to resenje se skida sa stack-a i stavlja u resenje
    ; prethodne iteracije
    pop dx
    mov [bp+18], dx
    
kraj_rek:
    pop bp
    pop di
    pop si
    pop dx
    pop bx
    pop ax
    ; brisu se samo 2 elementa (4 bajta) sa stack-a jer su to
    ; indeksi a zelimo da sacuvamo resenje
    ret 4
palindrom endp

start:
; set segment registers:
    mov ax, data
    mov ds, ax
    mov es, ax

    ; add your code here
    
    wstr prompt0
    
    ; gura se duzina stringa kao parametar
    ; (bice dobijen automatski)
    push n
    push 100
    push offset str
    call rstr
    ; duzina niza je preostala na stack-u
    pop n
    
    call novi_red
    
    ; na pocetku je resenje true
    push 1
    ; pushvoanje adrese stringa (pocetak)
    push offset str
    ; racunanje kraja stringa
    lea dx, str
    add dx, n
    dec dx
    push dx
    call palindrom
    ; resenje je poslednje ostalo na stack-u
    pop dx
    cmp dx, 0
    jnz jeste_pal
    
    wstr prompt2
    jmp end_start
jeste_pal:
    wstr prompt1
end_start:
    
    call novi_red
            
    lea dx, pkey
    mov ah, 9
    int 21h        ; output string at ds:dx
    
    ; wait for any key....    
    mov ah, 1
    int 21h
    
    mov ax, 4c00h ; exit to operating system.
    int 21h    
ends

end start ; set entry point and stop the assembler.
