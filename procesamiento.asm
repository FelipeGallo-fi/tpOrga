; funciones.asm

global procesarImagen
global valorRGBlineal
global valorYcomprimido

section .text

; ---------------------------------------------------------------------
; int procesarImagen(unsigned char* p, int nRows, int nCols, int channels)
; Retorna: eax = 0
; ---------------------------------------------------------------------
procesarImagen:
    ; TODO: implementar el procesamiento completo
    xor     eax, eax      ; devuelve 0
    ret

; ---------------------------------------------------------------------
; double valorRGBlineal(double RGBcomprimido)
; Entrada: xmm0 = RGBcomprimido
; Salida:  xmm0 = resultado
; ---------------------------------------------------------------------
valorRGBlineal:
    ; TODO: usar pow, comparar con 0.04045, etc.
    movsd   xmm0, qword [dummyRGB]  ; como ejemplo
    ret

; ---------------------------------------------------------------------
; double valorYcomprimido(double valorYlineal)
; Entrada: xmm0 = valorYlineal
; Salida:  xmm0 = resultado
; ---------------------------------------------------------------------
valorYcomprimido:
    ; TODO: usar pow, comparar con 0.0031308, etc.
    movsd   xmm0, qword [dummyY]    ; como ejemplo
    ret

section .data
ejemploCte: dq 0.5

