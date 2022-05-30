; multi-segment executable file template.

data segment
    pozX db ?
    pozY db ?
    sirina dw ?
    visina dw ? 
    adresa dw ?
    boja db ?
    
    p1x db ?
    p1y db ?
    p2x db ?
    p2y db ?
    
    p1xd db ?
    p1yd db ?
    p2xd db ?
    p2yd db ?
    
    pkey db "press any key...$"
ends

stack segment
    dw   128  dup(0)
ends

macro initgraph
     push ax
     mov ax, 0B800h
     mov es, ax
     mov pozX, 0
     mov pozY, 0
     mov sirina, 80
     mov visina, 25
     mov adresa, 0
     mov boja, 7
     pop ax
endm

macro initgame
    mov p1x, 26
    mov p1y, 12
    mov p2x, 53
    mov p2y, 12
    
    mov p1xd, 0
    mov p1yd, 0ffh
    mov p2xd, 0
    mov p2yd, 0ffh
endm

; makro za pretvaranje dekartovih koordinata u adresu
dtoa macro x y
    push ax
    push bx
    
    mov pozX, x
    mov pozY, y

    mov bx, sirina  ; ucitavanje umnoska za redove
    shl bx, 1       ; mnozenje sirine reda sa velicinom polja (2)
    mov ax, bx
    mov ah, pozY    ; ucitavanje y koordinate
    mul ah          ; mnozenje memorijske velicine reda sa brojem redova
    
    mov bh, 0
    mov bl, pozX    ; ucitavanje x koordinate
    shl bl, 1       ; mnozenje broja redova sa velicinom polja (2)
    add ax, bx      ; dodavanje kolone na redove
    mov adresa, ax
    
    pop bx
    pop ax                                             
endm

drawplayer macro c
    push ax
    push bx
    mov ah, c       ; boja igraca
    mov al, 0fh     ; znak igraca
    mov bx, adresa
    mov es:[bx], ax
    pop bx
    pop ax    
endm

drawtrail macro c
    push ax
    push bx
    mov ah, c
    mov al, 0dbh
    mov bx, adresa
    mov es:[bx], ax
    pop bx
    pop ax
endm

; Postavljanje tekuce pozicije na poziciju (x, y)               
macro move1 x y
    mov p1x, x
    mov p1y, y
endm

macro move2 x y
    mov p2x, x
    mov p2y, y
endm 

; Postavljanje tekuce boje
macro setColor b
     mov boja, b
endm
; Ispis stringa na ekran           
writeString macro str
    LOCAL petlja, kraj
    push ax
    push bx  
    push si
    mov si, 0
    mov ah, boja
    mov bx, adresa
petlja:
    mov al, str[si]
    cmp al, '$'
    je kraj
    mov es:[bx], al   
    mov es:[bx+1], ah
    add bx, 2
    add si, 1
    jmp petlja
kraj:           

    mov ax, si
    add al, pozX
    mov ah, pozY
    setXY al ah
    pop si
    pop bx
    pop ax
endm  
; Ucitavanje znaka bez prikaza
readkey macro c
    push ax
    mov ah, 08
    int 21h
    mov c, al
    pop ax 
endm
; Ispis znaka na tekucu poziciju
wchr macro c
    push ax
    push dx
    mov ah, 02
    mov dl, c
    int 21h
    pop dx
    pop ax
endm

code segment

paintlevel proc
    push ax
    push bx
    push cx
    push si
                
    ; boja okvira
    mov ah, 8
    
    mov al, 0c9h    ; znak gornjeg levog coska
    mov bx, 0       ; adresa gornjeg levog coska
    mov es:[bx], ax
    
    mov al, 0bbh    ; znak gornjeg desnog coska
    mov bx, 158     ; adresa gornjeg desnog coska
    mov es:[bx], ax
    
    mov al, 0c8h    ; znak donjeg levog coska
    mov bx, 3840    ; adresa donjeg levog coska
    mov es:[bx], ax
    
    mov al, 0bch    ; znak donjeg desnog coska
    mov bx, 3998    ; adresa donjeg desnog coska
    mov es:[bx], ax
    
    mov al, 0cdh    ; znak horizontalne ivice
    mov bx, 2       ; adresa trenutnog znaka
    mov si, 3840    ; offset za poslednji red
    mov cx, 78      ; sirina ekrana
loop_h:
    mov es:[bx], ax
    mov es:[si+bx], ax
    add bx, 2
    loop loop_h

    mov al, 0bah    ; znak vertikalne ivice    
    mov bx, 160     ; prvi znak u drugom redu
    mov si, 158     ; offset za desnu kolonu
    mov cx, 23
loop_v:
    mov es:[bx], ax
    mov es:[si+bx], ax
    add bx, 160
    loop loop_v
    
    dtoa 26 12
    drawplayer 9

    dtoa 53 12    
    drawplayer 14
    
    pop si
    pop cx
    pop bx
    pop ax
    ret
paintlevel endp

paintmodal proc
    mov bp, sp
    mov ah, [bp+2+1]
    
    mov al, 0c9h
    mov bx,     
paintmodal endp

; procedura za proveru kolizija sa preprekama
; ocekuje 3 reci na stack-u
; prva je mesto za resenje (0 ako nema i 1 ako ima kolizija)
; druga je x koordinata
; treca je y koordinata
checkbounds proc
    push ax
    push bx
    push si
    push di

    ; ucitavanje koordinata
    mov bp, sp
    mov ax, [bp+10]
    
    dtoa ah al
    
    ; racunanje adrese u grafickoj memoriji
    mov bx, adresa

    ; pribavljanje znaka iz graficke memorije
    mov al, es:[bx]
    mov ah, es:[bx+1]
    
    ; postavljanje gornjeg bita na 0 (to je boja)
    mov ah, 0
    ; odmah se postavlja resenje na 0 (nema sudara)
    mov [bp+14], 0
    ; provera da li ima sudara (da li je znak 0 ili nesto drugo)
    cmp ax, 0
    ; ako je znak 0 onda nema sudara i vraca se 0
    je checkbounds_kraj

    ; ako ima sudara onda se vraca 1    
    mov [bp+12], 1

checkbounds_kraj:
    pop di
    pop si
    pop bx
    pop ax
    ret 2
checkbounds endp

start:
; set segment registers:
    mov ax, data
    mov ds, ax
    mov es, ax

    initgraph
    initgame
    
    call paintlevel
    
petlja:
    ; citanje bafera (tastature) bez blokiranja
    mov ah, 01h
    int 16h ; proveri da li ima nesto uneto
    ; u ah registar se upisuje bios scan code ali u al se upisuje ascii kod
    ; potom se proverava da li ascii kod odgovara nekom od komandnih dugmica
    
    jnz check
    jmp dalje

check:
    ; uzimanje prvog tastera sa bafera (16/01h samo cita)
    mov ah, 00h
    int 16h
    
    ; player 1 key checks
    
    cmp al, 61h ; player 1 left (a)
    je a_key
    
    cmp al, 73h ; player 1 down (s)
    je s_key
    
    cmp al, 64h ; player 1 right (d)
    je d_key
    
    cmp al, 77h ; player 1 up (w)
    je w_key
    
    
    
    ; player 2 key checks
    
    cmp al, 6ah ; player 2 left (j)
    je j_key
    
    cmp al, 6bh ; player 2 down (k)
    je k_key
    
    cmp al, 6ch ; player 2 right (l)
    je l_key
    
    cmp al, 69h ; player 2 up (i)
    je i_key
    
    jmp dalje
    
a_key:
    cmp p1xd, 1
    je dalje
    
    mov p1xd, 0ffh
    mov p1yd, 0
    jmp dalje

s_key:
    cmp p1yd, 0ffh
    je dalje
    
    mov p1xd, 0
    mov p1yd, 1
    jmp dalje

d_key:
    cmp p1xd, 0ffh
    je dalje
    
    mov p1xd, 1
    mov p1yd, 0
    jmp dalje

w_key:
    cmp p1yd, 1
    je dalje
    
    mov p1xd, 0
    mov p1yd, 0ffh
    jmp dalje
    
j_key:
    cmp p2xd, 1
    je dalje
    
    mov p2xd, 0ffh
    mov p2yd, 0
    jmp dalje

k_key:
    cmp p2yd, 0ffh
    je dalje
    
    mov p2xd, 0
    mov p2yd, 1
    jmp dalje

l_key:
    cmp p2xd, 0ffh
    je dalje
    
    mov p2xd, 1
    mov p2yd, 0
    jmp dalje

i_key:
    cmp p2yd, 1
    je dalje
    
    mov p2xd, 0
    mov p2yd, 0ffh
    jmp dalje

dalje:
    ;; pomeranje prvog igraca

    ; u donji bajt se ucitava x koordinata za prvog igraca
    mov ah, p1x
    ; u donji bajt se ucitava y koordinata za prvog igraca
    mov al, p1y
    ; u ax i bx se ucitavaju delte x i y koordinata respektivno
    mov bh, p1xd
    mov bl, p1yd
    ; sabiraju se delte sa koordinatama da se dobije sledeca koordinata
    add ah, bh
    add al, bl
    
    ; provera kolizija za prvog igraca
    push 0
    push ax
    call checkbounds
    pop cx
    
    cmp cx, 0
    jne kraj

    ; iscrtavanje sledeceg mesta glave igraca i repa
    drawplayer 9
    mov bh, p1x
    mov bl, p1y
    dtoa bh bl
    drawtrail 9
    move1 ah al
    
    ;; pomeranje drugog igraca
    mov ah, p2x
    mov al, p2y
    mov bh, p2xd
    mov bl, p2yd
    add ah, bh
    add al, bl
    
    push 0
    push ax
    call checkbounds
    pop cx
    
    cmp cx, 0
    jne kraj
    
    drawplayer 14
    mov bh, p2x
    mov bl, p2y
    dtoa bh bl
    drawtrail 14
    move2 ah al
    
    
    ; ovde ide iscrtavanje
    jmp petlja
    

plavi_pobednik:
    
    

kraj:
    
    mov bl, al
            
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
