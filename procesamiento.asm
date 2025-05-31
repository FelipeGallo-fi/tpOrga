; procesamiento.asm

extern pow

global procesarImagen
global valorRGBlineal
global valorYcomprimido

section .data
    escalar      dq 12.92
    multiplicador_gamma    dq 1.055
    offset_gamma  dq 0.055
    limiteRGB     dq 0.04045
    exponente_gammaRGB dq 2.4
    limiteY        dq 0.0031308
    exponente_gammaY     dq 0.4166666666666667     ; 1 / 2.4


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
; Descripción:
; Esta función calcula el valor lineal de cada un pixel RGB.
; Si el valor es menor que el límite (0.04045), se aplica una escala lineal.
; En caso contrario, se utiliza una transformación exponencial con gamma.
; La transformación incluye una llamada a la función pow y operaciones
; adicionales para ajustar el resultado según la fórmula especificada.
; double valorRGBlineal (double RGBcomprimido) {
; 	double resultado;
; 	double a,b;
; 	if (isless(RGBcomprimido,0.04045)) {
; 		resultado = RGBcomprimido / 12.92;
; 	} else {
; 		a = (RGBcomprimido+0.055);
; 		b = (a/1.055);
; 		resultado = pow(b,(2.4));
; 	}
; 	return (resultado);
; }
; ---------------------------------------------------------------------
valorRGBlineal:
    ; TODO: usar pow, comparar con 0.04045, etc.
    ; Comparar con 0.04045
    movsd   xmm1, qword [rel limiteRGB]
    ucomisd xmm0, xmm1         ; if (xmm0 < limite)
    jb      caso_linealRGB

    ; caso exponencial
    sub     rsp, 16            ; reservar 16 bytes para pasar los argumentos a pow

    ; armar argumentos para pow((RGBcomprimido + 0.055) / 1.055, 2.4)
    movsd   xmm1, qword [rel offset_gamma]  ; xmm1 = 0.055
    addsd   xmm0, xmm1         ; xmm0 += 0.055

    movsd   xmm1, qword [rel multiplicador_gamma]  ; xmm1 = 1.055
    divsd   xmm0, xmm1         ; xmm0 /= 1.055
    
    movsd   qword [rsp], xmm0                  ; x
    movsd   xmm1, qword [rel exponente_gammaRGB]  ; xmm1 = 2.4
    movsd   qword [rsp+8], xmm1                ; y

    call    pow                 ; xmm0 = pow(xmm0, 2.4)

    add     rsp, 16            ; vacio pila

    ret

caso_linealRGB:
    ; xmm0 /= 12.92
    movsd   xmm1, qword [rel escalar]
    divsd   xmm0, xmm1
    ret

; ---------------------------------------------------------------------

;double valorYcomprimido (double valorYlineal) {
;	double resultado;
;	double a, b;
;	if (isless(valorYlineal,0.0031308)) {
;		resultado = valorYlineal * 12.92;
;	} else {
;		a = pow(valorYlineal,(1/2.4));
;		b = 1.055 * a;
;		resultado =  b - 0.055;
;	}
;	return (resultado);
;}
;
; double valorYcomprimido(double valorYlineal)
; Entrada: xmm0 = valorYlineal
; Salida:  xmm0 = resultado
; Descripción:
; Esta función calcula el valor comprimido de Y a partir de su valor lineal.
; Si el valor es menor que el límite (0.0031308), se aplica una escala lineal.
; En caso contrario, se utiliza una transformación exponencial con gamma.
; La transformación incluye una llamada a la función pow y operaciones
; adicionales para ajustar el resultado según la fórmula especificada.
; ---------------------------------------------------------------------
valorYcomprimido:
    ; Comparar con 0.0031308
    movsd   xmm1, qword [rel limiteY]
    ucomisd xmm0, xmm1         ; if (xmm0 < limite)
    jb      caso_linealY

    ;caso exponencial
    sub     rsp, 16            ; reservar 16 bytes para pasar los argumentos a pow

    ; armar argumentos para pow(valorYlineal, 1/2.4)
    movsd   qword [rsp], xmm0                  ; x
    movsd   xmm1, qword [rel exponente_gammaY]
    movsd   qword [rsp+8], xmm1                ; y

    call    pow                 ; xmm0 = pow(valorYlineal, 1/2.4)

    add     rsp, 16            ; vacio pila

    ; xmm0 = resultado de pow(valorYlineal, 1/2.4)
    ; multiplicar por 1.055
    movsd   xmm1, qword [rel multiplicador_gamma]
    mulsd   xmm0, xmm1         ; xmm0 *= 1.055

    ; restar 0.055
    movsd   xmm1, qword [rel offset_gamma]
    subsd   xmm0, xmm1         ; xmm0 -= 0.055

    ret

caso_linealY:
    ; xmm0 *= 12.92
    movsd   xmm1, qword [rel escalar]
    mulsd   xmm0, xmm1
    ret
