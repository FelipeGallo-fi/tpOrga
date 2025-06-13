; procesamiento.asm

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
;   rdi = puntero al buffer de imagen (unsigned char*)
;   rsi = nRows (cantidad de filas)
;   rdx = nCols (cantidad de columnas)
;   rcx = channels (cantidad de canales, asumido 3)
; Salida:
;   eax = 0 (retorno entero)
;
; Descripción:
;   Convierte una imagen RGB en tonos de gris, manteniendo formato RGB
;   Se calcula luminancia perceptual con corrección gamma:
;     - Linealización de R, G, B con valorRGBlineal
;     - Luminancia Y = 0.2126*R + 0.7152*G + 0.0722*B
;     - Compresión gamma de Y con valorYcomprimido
;     - El resultado se aplica a los tres canales (R=G=B)
; ---------------------------------------------------------------------
procesarImagen:
    mov     r12, rdi         ; puntero a imagen
    mov     r13, rsi         ; nRows
    mov     r14, rdx         ; nCols
    mov     r15, rcx         ; channels (3)

    mov     r8, 0            ; fila i
procesar_filas:
    cmp     r8, r13
    jge     fin_procesar
    mov     r9, 0            ; columna j

procesar_columnas:
    mov     rax, r14
    imul    rax, r15         ; ancho total en bytes (nCols * channels)
    cmp     r9, rax
    jge     siguiente_fila

    ; índice lineal: idx = i * nCols * channels + j
    mov     r10, r8
    imul    r10, r14
    imul    r10, r15
    add     r10, r9

    ; --- Canal B ---
    movzx   r11, byte [r12 + r10]
    cvtsi2sd xmm0, r11
    divsd   xmm0, qword [rel division_factor]   ; B / 255.0
    call    valorRGBlineal
    movsd   xmm6, xmm0         ; Blineal

    ; --- Canal G ---
    movzx   r11, byte [r12 + r10 + 1]
    cvtsi2sd xmm0, r11
    divsd   xmm0, qword [rel division_factor]
    call    valorRGBlineal
    movsd   xmm7, xmm0         ; Glineal

    ; --- Canal R ---
    movzx   r11, byte [r12 + r10 + 2]
    cvtsi2sd xmm0, r11
    divsd   xmm0, qword [rel division_factor]
    call    valorRGBlineal     ; xmm0 = Rlineal

    ; Ylineal = 0.2126*R + 0.7152*G + 0.0722*B
    movsd   xmm1, xmm0
    mulsd   xmm1, qword [rel const_R]
    movsd   xmm0, xmm6
    mulsd   xmm0, qword [rel const_B]
    addsd   xmm0, xmm1
    movsd   xmm1, xmm7
    mulsd   xmm1, qword [rel const_G]
    addsd   xmm0, xmm1         ; xmm0 = Ylineal

    ; Yrgb = 255 * valorYcomprimido(Ylineal)
    call    valorYcomprimido
    movsd   xmm1, qword [rel division_factor]
    mulsd   xmm0, xmm1
    cvttsd2si r11, xmm0

    ; Asignar Yrgb a canales R, G y B
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
; double valorRGBlineal (double RGBcomprimido)
; Entrada : xmm0 = valor RGB normalizado (0..1)
; Salida  : xmm0 = valor linealizado
;
; Si RGB < 0.04045:   RGB / 12.92
; Si RGB >= 0.04045:  pow((RGB + 0.055)/1.055, 2.4)
; ---------------------------------------------------------------------
valorRGBlineal:
    movsd   xmm1, qword [rel limiteRGB]
    ucomisd xmm0, xmm1
    jb      caso_linealRGB

    ; caso exponencial
    movsd   xmm1, qword [rel offset_gamma]
    addsd   xmm0, xmm1
    movsd   xmm1, qword [rel multiplicador_gamma]
    divsd   xmm0, xmm1
    movsd   xmm1, qword [rel exponente_gammaRGB]

    sub     rsp, 16
    movsd   qword [rsp], xmm0
    movsd   qword [rsp + 8], xmm1
    push    r8 r9 r10 r11
    call    pow
    pop     r11 r10 r9 r8
    add     rsp, 16
    ret

caso_linealRGB:
    movsd   xmm1, qword [rel escalar]
    divsd   xmm0, xmm1
    ret

; ---------------------------------------------------------------------
; double valorYcomprimido (double valorYlineal)
; Entrada : xmm0 = Y lineal (0..1)
; Salida  : xmm0 = Y comprimido (0..1)
;
; Si Y < 0.0031308:      Y * 12.92
; Si Y >= 0.0031308:     1.055 * pow(Y, 1/2.4) - 0.055
; ---------------------------------------------------------------------
valorYcomprimido:
    movsd   xmm1, qword [rel limiteY]
    ucomisd xmm0, xmm1
    jb      caso_linealY

    ; caso exponencial
    sub     rsp, 16
    movsd   qword [rsp], xmm0
    movsd   xmm1, qword [rel exponente_gammaY]
    movsd   qword [rsp + 8], xmm1
    push    r8 r9 r10 r11
    call    pow
    pop     r11 r10 r9 r8
    add     rsp, 16

    ; * 1.055
    movsd   xmm1, qword [rel multiplicador_gamma]
    mulsd   xmm0, xmm1

    ; - 0.055
    movsd   xmm1, qword [rel offset_gamma]
    subsd   xmm0, xmm1
    ret

caso_linealY:
    movsd   xmm1, qword [rel escalar]
    mulsd   xmm0, xmm1
    ret
