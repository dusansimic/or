; multi-segment executable file template.

data segment
    ; add your data here!
    niz dw 100 dup(?)
    nizobrn dw 100 dup(?)
    ; trenutni broj
    strn db "        "
    n dw 0
    ; size niza
    strs db "        "
    s dw 0
    poruka0 db "Unesite broj elemenata niza: $"
    poruka1 db "Unesite broj: $"
    poruka2 db "Obrnuti niz: $"
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
    ; napisati koliko je prostora rezervisano za unos (al - 1 karaktera)
    mov ax, [bp+14]
    mov byte [bx], al
    ; podesavanje kodova za interrupt (ucitavanje stringa)
    mov ah, 0ah
    int 21h
    ; upisivanje povratne vrednosti u si
    mov si, dx
    ; upisivanje broja ucitanih karaktera u cl (koristi se u petlji)
    mov cl, [si+1]
    mov ch, 0
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

stoi proc
    push ax
    push bx
    push cx
    push dx
    push si
    ; ucitavanje stringa
    mov bp, sp
    mov bx, [bp+14]
    ; int koji se racuna
    mov ax, 0
    mov cx, 0
    ; konstanta za pomeraj mesta u intu
    mov si, 10
petlj_stoi:
    ; upisivanje cifre iz stringa u cl
    mov cl, [bx]
    ; provera da li je kraj stringa
    cmp cl, '$'
    je kraj_stoi
    ; pomeriti cifre za jedno mesto u levo
    mul si
    ; pretvaranje ascii koda u cifru
    sub cx, 48
    ; dodavanje poslednje cifre na int
    add ax, cx
    ; TODO: nisam siguran sta ovo radi
    inc bx
    jmp petlj_stoi
kraj_stoi:
    ; upisivanje int-a na datu adresu
    mov bx, [bp+12]
    mov [bx], ax
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret 4
stoi endp

itos proc
    push ax
    push bx
    push cx
    push dx
    push si
    ; ucitavanje adrese stringa
    mov bp, sp
    mov ax, [bp+14]
    ; ubacivanje $ na stack
    ; kada se budu citale cifre (char) sa stack-a
    ; poslednja vrednost ce biti $ i to ce nam biti
    ; znak da je string procitan sa stacka
    mov dl, '$'
    push dx
    mov si, 10
petlj_itos:
    ; ostatak pri deljenu se upisuje u dx
    mov dx, 0
    div si
    ; pretvaranje u karakter broja
    add dx, 48
    push dx
    ; da li je int nula (ako jeste onda je konverzija gotova)
    cmp ax, 0
    jne petlj_itos
    
    ; ucitavnaje adrese stringa
    mov bx, [bp+12]
petlja_itos:
    ; skidanje cifre (char) sa stack-a i upisivanje u string
    pop dx
    mov [bx], dl
    inc bx
    ; ako je poslednji upisani karakter $ onda je string gotov
    cmp dl, '$'
    jne petlja_itos
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret 4
itos endp

obrni proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov bp, sp    
    ; ucitavanje adrese destinacionog niza
    1mov di, [bp+14]
    ; ispravljanje adrese za destinacioni niz
    ; TODO: ne znam zasto ovo mora da se uradi
    ; iz nekog razloga postavi sve jedenici na gornje bitove
    sub di, 0xFF00
    ; ucitavanje adrese izvornog niza
    mov si, [bp+16]
    ; ucitavanje duzine i kraja niza
    mov ax, [bp+18]
    mov dl, 2
    mul dl
    sub ax, 2
    add di, ax
    
    ; racunanje brojaca (celobrojna polovina duzine)
    mov cx, [bp+18]
obrn:
    ; obrni "simetricne" elemente niza
    mov ax, [si]
    mov [di], ax
    add si, 2
    sub di, 2
    loop obrn

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret 4
obrni endp

start:
; set segment registers:
    mov ax, data
    mov ds, ax
    mov es, ax

    ; add your code here
    wstr poruka0
    push 3
    push offset strs
    call rstr
    
    push offset strs
    push offset s
    call stoi
    
    mov cx, s
    mov si, 0
    
ucit:
    call novi_red
    wstr poruka1
    ; unos sledeceg broja
    push 6
    push offset strn ; pushovanje adrese promenljive
    call rstr
    
    ; konverzija iz stringa u int
    push offset strn
    push offset n
    call stoi
    
    mov ax, n
    mov niz[si], ax
    add si, 2
    loop ucit
    
    push s
    push offset niz
    push offset nizobrn
    call obrni
    
    call novi_red
    wstr poruka2
    call novi_red
    
    mov cx, s
    mov si, 0
ispi:
    mov ax, nizobrn[si]
    push ax
    push offset strn
    call itos
    wstr strn
    wchr ' '
    add si, 2
    loop ispi
    
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
