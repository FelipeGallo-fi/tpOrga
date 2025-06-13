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
    const_R dq 0.2126
    const_G dq 0.7152
    const_B dq 0.0722
    division_factor dq 255.0


section .text
; ---------------------------------------------------------------------
; int procesarImagen(unsigned char* p, int nRows, int nCols, int channels);
; Retorna: eax = 0
;
; int procesarImagen(uchar* p, int nRows, int nCols, int channels) {
;
;	int i,j;
;	double valorR, valorG, valorB; // valores RGB en rango 0..1
;	double Rlineal, Glineal, Blineal; // El array esta ordenado como BGR
;	double Ylineal, Yrgb;
;
;	for (i=0; i < nRows; i++) {
;		for (j=0; j < nCols*channels; j+=3) {
;			// B
;			valorB = (((double)(*(p+j+i*nCols*channels)))/255.0);
;			Blineal = valorRGBlineal (valorB);
;			// G
;			valorG = (((double)(*(p+j+i*nCols*channels+1)))/255.0);
;			Glineal = valorRGBlineal (valorG);
;			// R
;			valorR = (((double)(*(p+j+i*nCols*channels+2)))/255.0);
;			Rlineal = valorRGBlineal (valorR);
;			// Y lineal
;			Ylineal = 0.2126*Rlineal + 0.7152*Glineal + 0.0722*Blineal;
;			// Y comprimido
;			Yrgb = 255 * valorYcomprimido (Ylineal);
;			// RGB grayscale
;			*(p+j+i*nCols*channels) = FLOAT_TO_INT((Yrgb));
;			*(p+j+i*nCols*channels+1) = FLOAT_TO_INT((Yrgb));
;			*(p+j+i*nCols*channels+2) = FLOAT_TO_INT((Yrgb));
;		}
;	}
;	return (0);
;}
; ---------------------------------------------------------------------
procesarImagen:
    ; Entrada: rdi = p (puntero a la imagen) unsigned char*
    ;          rsi = nRows
    ;          rdx = nCols
    ;          rcx = channels
    ; Salida: eax = 0
    ; Guardo el rdi en un registro ya que pow le asigna el valor 0x0
    mov     r12, rdi
    ; Guardo todos los parametros de entrada en registros
    mov     r13, rsi             ; nRows
    mov     r14, rdx             ; nCols
    mov     r15, rcx             ; channels (asumimos 3 para RGB)
    ; Inicializo otros registros en 0 con carga inmediata
    mov     r8, 0              ; i = 0 (fila)
    mov     r10, 0             ; r10 = índice
    mov     r11, 0             ; r11 = valor para RGB

procesar_filas:
    cmp     r8, r13
    jge     fin_procesar
    mov     r9, 0              ; j = 0 (reiniciar columna)

procesar_columnas:
    mov     rax, r14
    imul    rax, r15              ; rax = nCols * channels
    cmp     r9, rax
    jge     siguiente_fila

    ; índice = i * nCols * channels + j
    mov     r10, r8
    imul    r10, r14
    imul    r10, r15
    add     r10, r9

    ; Leer B
    movzx   r11, byte [r12 + r10]       ; B
    cvtsi2sd xmm0, r11
    divsd   xmm0, qword [rel division_factor]            ; xmm0 = B / 255.0
    call    valorRGBlineal               ; xmm0 = Blineal

    ; Guardar Blineal en xmm6
    movsd  xmm6, xmm0

    ; Leer G
    movzx   r11, byte [r12 + r10 + 1]
    cvtsi2sd xmm0, r11
    divsd   xmm0, qword [rel division_factor]
    call    valorRGBlineal               ; xmm0 = Glineal

    ; Guardar Glineal en xmm7
    movsd  xmm7, xmm0

    ; Leer R
    movzx   r11, byte [r12 + r10 + 2]
    cvtsi2sd xmm0, r11
    divsd   xmm0, qword [rel division_factor] ; xmm0 = R / 255.0
    call    valorRGBlineal               ; xmm0 = Rlineal

    ; Calcular Ylineal = 0.2126*R + 0.7152*G + 0.0722*B
    movsd   xmm1, xmm0                 ; xmm1 = Rlineal
    mulsd   xmm1, qword [rel const_R]  ; Rlineal * 0.2126
    movsd   xmm0, xmm6                 ; xmm0 = Blineal
    mulsd   xmm0, qword [rel const_B]  ; Blineal * 0.0722
    addsd   xmm0, xmm1                 ; xmm0 = Rlineal * 0.2126 + Blineal * 0.0722
    movsd   xmm1, xmm7                 ; xmm1 = Glineal
    mulsd   xmm1, qword [rel const_G]  ; Glineal * 0.7152
    addsd   xmm0, xmm1                 ; xmm0 = Ylineal = Rlineal * 0.2126 + Glineal * 0.7152 + Blineal * 0.0722

    ; Calcular Y comprimido
    call    valorYcomprimido           ; xmm0 = Y comprimido

    ; Convertir Y a byte [0..255]
    movsd   xmm1, qword [rel division_factor]
    mulsd   xmm0, xmm1         ; xmm0 = Yrgb (en rango 0..255) es decir Ycomprimido * 255.0
    cvttsd2si r11, xmm0               ; r11 = Yrgb (convertido a entero)
    
    mov byte [r12 + r10], r11b
    mov byte [r12 + r10 + 1], r11b
    mov byte [r12 + r10 + 2], r11b

    add     r9, r15                 ; j += channels (3)
    jmp     procesar_columnas

siguiente_fila:
    add     r8, 1                         ; i += 1
    jmp     procesar_filas

fin_procesar:
    xor     eax, eax
    ret
; ---------------------------------------------------------------------
; double valorRGBlineal (double RGBcomprimido) {
; 	double resultado;
; 	double a,b;
; 	if (isless(RGBcomprimido,0.04045)) {
; 		resultado = RGBcomprimido / 12.92;
; 	} else {
; 		a = (RGBcomprimido + 0.055);
; 		b = (a / 1.055);
; 		resultado = pow(b, 2.4);
; 	}
; 	return resultado;
; }
;
; Entrada: xmm0 = RGBcomprimido (en rango [0,1])
; Salida:  xmm0 = valor RGB linealizado
; ---------------------------------------------------------------------
valorRGBlineal:
    ; Comparar con el umbral 0.04045
    movsd   xmm1, qword [rel limiteRGB]
    ucomisd xmm0, xmm1
    jbe      caso_linealRGB     ; Si es menor o igual, va al caso lineal

    ; -------------------------------
    ; Caso exponencial:
    ; Calcular: pow( (RGB + 0.055) / 1.055, 2.4 )
    ; -------------------------------

    ; xmm0 += 0.055
    movsd   xmm1, qword [rel offset_gamma]
    addsd   xmm0, xmm1

    ; xmm0 /= 1.055
    movsd   xmm1, qword [rel multiplicador_gamma]
    divsd   xmm0, xmm1

    ; Preparar exponente: xmm1 = 2.4
    movsd   xmm1, qword [rel exponente_gammaRGB]

    ; Llamar a pow(xmm0, xmm1)
    sub     rsp, 16                    ; Reservar espacio para los argumentos
    movsd   qword [rsp], xmm0         ; Base
    movsd   qword [rsp + 8], xmm1     ; Exponente

    ; Guardar registros antes de llamar
    push    r8
    push    r9
    push    r10
    push    r11
    sub     rsp, 16               ; reservo 16 bytes para xmm6 y xmm7
    movdqu  [rsp], xmm6
    movdqu  [rsp + 8], xmm7
    call    pow                 ; xmm0 = pow(xmm0, 2.4)
    ; recupero los registros
    movdqu  xmm6, [rsp]
    movdqu  xmm7, [rsp + 8]
    add     rsp, 16
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    add     rsp, 16                    ; Limpiar pila

    ret

; -------------------------------
; Caso lineal: resultado = RGB / 12.92
; -------------------------------
caso_linealRGB:
    movsd   xmm1, qword [rel escalar] ; escalar = 12.92
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
    movsd   qword [rsp + 8], xmm1              ; y
    push    r8
    push    r9
    push    r10
    push    r11
    call    pow                 ; xmm0 = pow(valorYlineal, 1/2.4)
    pop     r11
    pop     r10
    pop     r9
    pop     r8
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