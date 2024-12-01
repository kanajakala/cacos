BITS 64;

mov dx, 0xe9 ;output port

mov al, 0x48 ;H
out dx, al ;used to output to the debug console (out <PORT> <CHAR>)
mov al, 0x45 ;E
out dx, al
mov al, 0x4C ;L
out dx, al
mov al, 0x4C ;L
out dx, al
mov al, 0x4F ;O
out dx, al

;return control to the kernel
int 34
