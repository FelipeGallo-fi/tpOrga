; procesamiento.asm

; ---------------------------------------------------------------------
; Trabajo Práctico - Organización del Computador
; Conversión de imagen RGB a escala de grises perceptual (modelo sRGB)
; - Paso 1: descompresión gamma RGB → lineal (valorRGBlineal)
; - Paso 2: luminancia perceptual Ylineal = 0.2126R + 0.7152G + 0.0722B
; - Paso 3: compresión gamma inversa (valorYcomprimido) → Ysrgb
; Resultado: imagen RGB donde R = G = B = Ysrgb
; ---------------------------------------------------------------------

extern pow

global procesarImagen
global valorRGBlineal
global valorYcomprimido

section .data
    escalar               dq 12.92
    multiplicador_gamma   dq 1.055
    offset_gamma          dq 0.055
    limiteRGB             dq 0.04045
    exponente_gammaRGB    dq 2.4
    limiteY               dq 0.0031308
    exponente_gammaY      dq 0.4166666666666667     ; 1 / 2.4
    const_R               dq 0.2126
    const_G               dq 0.7152
    const_B               dq 0.0722
    division_factor       dq 255.0

section .text
; ---------------------------------------------------------------------
; int procesarImagen(unsigned char* p, int nRows, int nCols, int channels);
; Entrada:
;   rdi = puntero a la imagen (unsigned char*)
;   rsi = cantidad de filas
;   rdx = cantidad de columnas
;   rcx = cantidad de canales (3 para RGB)
; Salida:
;   eax = 0
;
; Descripción:
;   Convierte una imagen RGB en escala de grises perceptual.
;   Mantiene los 3 canales (R, G, B) con el mismo valor calculado por
;   transformaciones gamma estándar sRGB.
; ---------------------------------------------------------------------
procesarImagen:
    mov     r12, rdi                ; guardar puntero a imagen (rdi se pisa con pow)
    mov     r13, rsi                ; cantidad de filas
    mov     r14, rdx                ; cantidad de columnas
    mov     r15, rcx                ; cantidad de canales (3)
    xor     r8, r8                  ; i = 0

procesar_filas:
    cmp     r8, r13
    jge     fin_procesar
    xor     r9, r9                  ; j = 0

procesar_columnas:
    mov     rax, r14
    imul    rax, r15                ; ancho en bytes de una fila
    cmp     r9, rax
    jge     siguiente_fila

    ; Calcular índice lineal: idx = i * nCols * channels + j
    mov     r10, r8
    imul    r10, r14
    imul    r10, r15
    add     r10, r9

    ; Leer canal B y normalizar
    movzx   r11, byte [r12 + r10]               ; leer byte
    cvtsi2sd xmm0, r11                          ; convertir a double
    divsd   xmm0, qword [rel division_factor]   ; normalizar [0, 1]
    call    valorRGBlineal                      ; descomprimir gamma
    movsd   xmm6, xmm0                          ; guardar Blineal

    ; Leer canal G
    movzx   r11, byte [r12 + r10 + 1]
    cvtsi2sd xmm0, r11
    divsd   xmm0, qword [rel division_factor]
    call    valorRGBlineal
    movsd   xmm7, xmm0                          ; guardar Glineal

    ; Leer canal R
    movzx   r11, byte [r12 + r10 + 2]
    cvtsi2sd xmm0, r11
    divsd   xmm0, qword [rel division_factor]
    call    valorRGBlineal                      ; xmm0 = Rlineal

    ; Calcular Ylineal = 0.2126*R + 0.7152*G + 0.0722*B
    movsd   xmm1, xmm0
    mulsd   xmm1, qword [rel const_R]
    movsd   xmm0, xmm6
    mulsd   xmm0, qword [rel const_B]
    addsd   xmm0, xmm1
    movsd   xmm1, xmm7
    mulsd   xmm1, qword [rel const_G]
    addsd   xmm0, xmm1                          ; xmm0 = Ylineal

    call    valorYcomprimido                    ; aplicar gamma inversa → xmm0 = Ysrgb

    movsd   xmm1, qword [rel division_factor]
    mulsd   xmm0, xmm1                          ; pasar a rango [0,255]
    cvttsd2si r11, xmm0                         ; truncar a entero

    ; Escribir R, G, B con el mismo valor Y
    mov byte [r12 + r10], r11b
    mov byte [r12 + r10 + 1], r11b
    mov byte [r12 + r10 + 2], r11b

    add     r9, r15
    jmp     procesar_columnas

siguiente_fila:
    inc     r8
    jmp     procesar_filas

fin_procesar:
    xor     eax, eax
    ret

; ---------------------------------------------------------------------
; double valorRGBlineal(double c)
; Entrada: xmm0 = componente sRGB en [0,1]
; Salida : xmm0 = componente lineal
; Formula:
;   Si c <= 0.04045 -> c / 12.92
;   Si c >  0.04045 -> pow((c + 0.055) / 1.055, 2.4)
; ---------------------------------------------------------------------
valorRGBlineal:
    movsd   xmm1, qword [rel limiteRGB]
    ucomisd xmm0, xmm1
    jbe     caso_linealRGB

    ; Exponencial: pow((c + 0.055) / 1.055, 2.4)
    movsd   xmm1, qword [rel offset_gamma]
    addsd   xmm0, xmm1
    movsd   xmm1, qword [rel multiplicador_gamma]
    divsd   xmm0, xmm1
    movsd   xmm1, qword [rel exponente_gammaRGB]

    ; Guardar base y exponente en pila para pow()
    sub     rsp, 16
    movsd   qword [rsp], xmm0
    movsd   qword [rsp + 8], xmm1

    ; Guardar registros y xmm6/7 (caller-saved)
    push    r8 
    push r9 
    push r10 
    push r11
    sub     rsp, 16
    movdqu  [rsp], xmm6
    movdqu  [rsp + 8], xmm7
    call    pow
    movdqu  xmm6, [rsp]
    movdqu  xmm7, [rsp + 8]
    add     rsp, 16
    pop r11
    pop r10
    pop r9
    pop r8

    add     rsp, 16
    ret

caso_linealRGB:
    movsd   xmm1, qword [rel escalar]
    divsd   xmm0, xmm1
    ret

; ---------------------------------------------------------------------
; double valorYcomprimido(double y)
; Entrada: xmm0 = Ylineal
; Salida : xmm0 = Ysrgb
; Formula:
;   Si y < 0.0031308 -> y * 12.92
;   Si y >=           -> 1.055 * pow(y, 1/2.4) - 0.055
; ---------------------------------------------------------------------
valorYcomprimido:
    movsd   xmm1, qword [rel limiteY]
    ucomisd xmm0, xmm1
    jb      caso_linealY

    ; Exponencial: 1.055 * pow(y, 1/2.4) - 0.055
    sub     rsp, 16
    movsd   qword [rsp], xmm0
    movsd   xmm1, qword [rel exponente_gammaY]
    movsd   qword [rsp + 8], xmm1
    push    r8
    push r9 
    push r10 
    push r11
    call    pow
    pop r11
    pop r10
    pop r9
    pop r8
    add     rsp, 16

    movsd   xmm1, qword [rel multiplicador_gamma] ; multiplicar por 1.055
    mulsd   xmm0, xmm1
    movsd   xmm1, qword [rel offset_gamma]        ; restar 0.055
    subsd   xmm0, xmm1
    ret

caso_linealY:
    movsd   xmm1, qword [rel escalar]
    mulsd   xmm0, xmm1
    ret
