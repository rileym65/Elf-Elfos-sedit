; *******************************************************************
; *** This software is copyright 2005 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    ../bios.inc
include    ../kernel.inc

d_idewrite: equ    044ah
d_ideread:  equ    0447h

           org     02000h
begin:     br      start
           eever
           db      'Written by Michael H. Riley',0

sector:    dw      0

start:     ldi     high sector         ; point to base page
           phi     rb
           ldi     low sector          ; need to indicate invalid sector
           plo     rb
           ldi     0ffh                ; indicate no sector loaded
           str     rb                  ; write to pointer
           inc     rb
           str     rb


mainlp:    ldi     high prompt         ; get address of prompt
           phi     rf
           ldi     low prompt
           plo     rf
           sep     scall               ; display prompt
           dw      o_msg
           sep     scall
           dw      loadbuf
           sep     scall               ; get input from user
           dw      o_input
           sep     scall
           dw      docrlf
           sep     scall
           dw      loadbuf
           lda     rf                  ; get command byte
           plo     re                  ; keep a copy
           smi     'a'                 ; check if below lc
           lbnf    mainlpgo            ; jump if so
           smi     27                  ; check if above lc
           lbdf    mainlpgo
           glo     re                  ; convert to uppercase
           smi     32
           plo     re
mainlpgo:  glo     re
           smi     'L'                 ; check for display Low command
           lbz     disp_lo             ; jump if so
           glo     re                  ; recover command
           smi     'H'                 ; check for display high command
           lbz     disp_hi             ; jump if so
           glo     re                  ; recover command
           smi     'R'                 ; check for read sector command
           lbz     rd_sec              ; jump if so
           glo     re                  ; recover command
           smi     'N'                 ; check for next sector command
           lbz     nxt_sec             ; jump if so
           glo     re                  ; recover command
           smi     'P'                 ; check for previous sector command
           lbz     prv_sec             ; jump if so
           glo     re                  ; recover command
           smi     'D'                 ; check for display current sector
           lbz     dsp_sec             ; jump if so
           glo     re                  ; recover command
           smi     'E'                 ; check for enter bytes command
           lbz     enter               ; jump if so
           glo     re                  ; recover command
           smi     'W'                 ; check for write sector command
           lbz     write               ; jump if so
           glo     re                  ; recover command
           smi     'Q'                 ; check for quit command
           lbz     quit                ; jump if so
           glo     re                  ; recover command
           smi     'A'                 ; check for read AU command
           lbz     rd_au               ; jump if so
           glo     re                  ; recover command
           smi     'C'                 ; check for read AU chain command
           lbz     chain               ; jump if so

           lbr     mainlp

quit:      ldi     0
           sep     sret                ; return to Elf/OS

disp_hi:   ldi     0                   ; setup address
           plo     r9
           plo     rc                  ; setup counter
           ldi     1
           phi     r9
           ldi     high (secbuf+256)   ; point to sector buffer
           phi     ra
           ldi     low (secbuf+256)
           plo     ra
           lbr     disp_ct             ; process display
disp_lo:   ldi     0                   ; setup address
           phi     r9
           plo     r9
           plo     rc                  ; setup counter
           ldi     high secbuf         ; point to sector buffer
           phi     ra
           ldi     low secbuf
           plo     ra
disp_ct:   ldi     high outbuf         ; point to output buffer
           phi     rf
           ldi     low outbuf
           plo     rf
           ldi     high ascbuf         ; point to ascii buffer
           phi     r7
           ldi     low ascbuf
           plo     r7
           ldi     0                   ; initial line is empty
           str     rf
           str     r7
disp_lp:   glo     rc                  ; get count
           ani     0fh                 ; need to see if on 16 byte boundary
           lbnz    disp_ln             ; jump to display line
           ldi     0                   ; place terminator
           str     rf
           str     r7
           ldi     high outbuf         ; point to output buffer
           phi     rf
           ldi     low outbuf
           plo     rf
           sep     scall               ; output the last line
           dw      o_msg
           ldi     high ascbuf         ; point to ascii buffer
           phi     rf
           ldi     low ascbuf
           plo     rf
           sep     scall               ; output the last line
           dw      o_msg
           sep     scall
           dw      docrlf
           ldi     high outbuf         ; point to output buffer
           phi     rf
           ldi     low outbuf
           plo     rf
           ldi     high ascbuf         ; point to ascii buffer
           phi     r7
           ldi     low ascbuf
           plo     r7
           ghi     r9                  ; get address
           phi     rd                  ; and get for hexout
           glo     r9
           plo     rd
           sep     scall               ; output the address
           dw      f_hexout4
           ldi     ':'                 ; colon following address
           str     rf
           inc     rf
           ldi     ' '                 ; and a space
           str     rf
           inc     rf
           glo     r9                  ; increment address
           adi     16
           plo     r9
           ghi     r9
           adci    0
           phi     r9
disp_ln:   lda     ra                  ; get next byte
           plo     re                  ; keep a copy
           ani     0e0h                ; check for values below 32
           lbz     dsp_dot             ; display a dot
           ani     080h                ; check for high values
           lbnz    dsp_dot
           glo     re                  ; recover original character
           lbr     asc_go              ; and continue
dsp_dot:   ldi     '.'                 ; place dot into ascii buffer
asc_go:    str     r7                  ; store into buffer
           inc     r7                  ; and increment
           glo     re                  ; recover value
           plo     rd                  ; setup for output
           sep     scall               ; convert it
           dw      f_hexout2
           ldi     ' '                 ; space after number
           str     rf
           inc     rf
           dec     rc                  ; decrement count
           glo     rc                  ; get count
           lbnz    disp_lp             ; loop back if more to go
           ldi     0                   ; place terminator
           str     rf
           str     r7
           ldi     high outbuf         ; point to output buffer
           phi     rf
           ldi     low outbuf
           plo     rf
           sep     scall               ; output the last line
           dw      o_msg
           ldi     high ascbuf         ; point to ascii buffer
           phi     rf
           ldi     low ascbuf
           plo     rf
           sep     scall               ; output the last line
           dw      o_msg
           sep     scall
           dw      docrlf
           lbr     mainlp              ; back to main loop

rd_au:     sep     scall               ; convert au number
           dw      f_hexin
           ldi     3                   ; need to shift by 3
           plo     rc
au_lp:     glo     rd                  ; multiply by 2
           shl
           plo     rd
           ghi     rd
           shlc
           phi     rd
           dec     rc                  ; decrement count
           glo     rc                  ; see if done
           lbnz    au_lp               ; loop back if not
           lbr     readit              ; read first sector of au
rd_sec:    sep     scall               ; convert sector number
           dw      f_hexin
readit:    ldi     low sector          ; point to sector number
           plo     rb
           ghi     rd                  ; and write sector address
           str     rb
           inc     rb
           glo     rd
           str     rb
           ghi     rd                  ; prepare for sector read
           phi     r7
           glo     rd
           plo     r7
           ldi     0
           plo     r8
           ldi     0e0h                ; in lba mode
           phi     r8
           ldi     high secbuf         ; point to sector buffer
           phi     rf
           ldi     low secbuf
           plo     rf
           sep     scall               ; read the sector
           dw      d_ideread
           lbr     dsp_sec

write:     ldi     low sector          ; point to sector number
           plo     rb
           lda     rb                  ; and read it
           phi     r7
           lda     rb
           plo     r7
           ldi     0
           plo     r8
           ldi     0e0h                ; in lba mode
           phi     r8
           ldi     high secbuf         ; point to sector buffer
           phi     rf
           ldi     low secbuf
           plo     rf
           sep     scall               ; write the sector
           dw      d_idewrite
           lbr     dsp_sec
 
nxt_sec:   ldi     low sector          ; point to current sector number
           plo     rb
           lda     rb                  ; and read it
           phi     rd
           lda     rb
           plo     rd
           inc     rd                  ; increment sector number
           lbr     readit              ; and read new physical sector

prv_sec:   ldi     low sector          ; point to current sector number
           plo     rb
           lda     rb                  ; and read it
           phi     rd
           lda     rb
           plo     rd
           dec     rd                  ; decrement sector number
           lbr     readit              ; and read new physical sector

dsp_sec:   ldi     high sec_msg        ; display message
           phi     rf
           ldi     low sec_msg
           plo     rf
           sep     scall               ; and display it
           dw      o_msg
           ldi     low sector          ; get current sector number
           plo     rb
           lda     rb                  ; and retrieve it
           phi     rd
           lda     rb
           plo     rd
           sep     scall               ; point to buffer
           dw      loadbuf
           sep     scall               ; convert sector number
           dw      f_hexout4
           ldi     0                   ; write terminator
           str     rf
           sep     scall               ; point to buffer
           dw      loadbuf
           sep     scall               ; and display it
           dw      o_msg
           sep     scall               ; carriage return
           dw      docrlf
           lbr     mainlp              ; back to main loop

enter:     sep     scall               ; convert address
           dw      f_hexin
           glo     rd                  ; transfer address
           adi     low secbuf          ; add in sector buffer offset
           plo     ra
           ghi     rd
           adci    high secbuf
           phi     ra
enter_lp:  sep     scall               ; move past whitespace
           dw      f_ltrim
           ldn     rf                  ; see if at terminator
           lbz     mainlp              ; jump if done
           sep     scall               ; otherwise convert number
           dw      f_hexin
           glo     rd                  ; get number
           str     ra                  ; write into sector
           inc     ra                  ; point to next position
           lbr     enter_lp            ; and look for more

chain:     sep     scall               ; convert address
           dw      f_hexin
           ghi     rd                  ; transfer address
           phi     ra
           glo     rd
           plo     ra
chain_lp:  sep     scall               ; read specified lump
           dw      o_rdlump
           ghi     ra                  ; transfer for display
           phi     rd
           glo     ra
           plo     rd
           sep     scall               ; setup buffer
           dw      loadbuf
           sep     scall               ; convert number
           dw      f_hexout4
           ldi     ' '                 ; need a space
           str     rf
           inc     rf
           ldi     0                   ; and terminator
           str     rf
           sep     scall               ; setup buffer
           dw      loadbuf
           sep     scall               ; display it
           dw      o_msg
           glo     ra                  ; check for nonzero entry
           lbnz    chain_nz            ; jump if not
           ghi     ra
           lbnz    chain_nz
chain_dn:  sep     scall               ; display a CR/LF
           dw      docrlf
           lbr     mainlp              ; and back to main loop
chain_nz:  glo     ra                  ; check for end of chain code
           smi     0feh
           lbnz    chain_ne            ; jump if not end
           ghi     ra
           smi     0feh
           lbz     chain_dn            ; jump if end of chain
chain_ne:  glo     ra                  ; check for invalid entry
           xri     0ffh
           lbnz    chain_lp            ; jump if not
           ghi     ra
           xri     0ffh
           lbnz    chain_lp
           lbr     chain_dn
loadbuf:   ldi     high buffer
           phi     rf
           ldi     low buffer
           plo     rf
           sep     sret

docrlf:    ldi     high crlf
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall
           dw      o_msg
           sep     sret

prompt:    db      '>',0
crlf:      db      10,13,0
sec_msg:   db      'Current sector: ',0

endrom:    equ     $

.suppress

buffer:    ds      256
ascbuf:    ds      80
outbuf:    ds      80
secbuf:    ds      512

           end     begin

