.cseg
.org 0x0000
RJMP init

.org INT0addr
RJMP INT0_vector 

.org INT1addr
RJMP INT1_vector 

.def temp = R16		;Рабочая переменная
.def num_lump_1 = R17 ;Номер лампочки(0-23)
.def num_line = R18	;Номер линии(1-3)
.def step = R19		;размер шага (0-8)
.def num_lump_1b = R20
.def temp_int = R21
.def num_lump_2 = R23
.def num_lump_3 = R24
.def num_lump_2b = R25
.def num_lump_3b = R22

;-------------------------------------------------------------------- Предварительная настройка
init:                           ; Инициализируем начальные параметры
    ldi temp, Low(RAMEND)       ; Определяем стек
    out SPL, temp
    ldi temp, High(RAMEND)
    out SPH, temp

    ser temp                    ; Настраиваем порты A, B, C на выход
	out DDRA, temp
    out DDRB, temp
    out DDRC, temp
    ldi temp, 0b11110011            ; Настраиваем порт первые четыре pin'а порта D на вход, остальные на выход(11110011)
    out DDRD, temp

    ldi num_lump_1, 0            ; Определяем начальные значения параметров
	ldi num_lump_2, 0          ; Определяем начальные значения параметров
	ldi num_lump_3, 0            ; Определяем начальные значения параметров
    ldi num_line, 1
    ldi step, 5
	clr temp
	rcall EERead
    ldi num_lump_1b, 1
	ldi num_lump_2b, 1
	ldi num_lump_3b, 1
    ldi temp_int, 0

    sei
    ldi temp, 0b00001111		; было 00001111
	out MCUCR, temp
	ldi temp, 0b11000000		; было 11000000
	out GICR, temp


cycle:                      ; Выбор порта, когда шаг>0
	cpi num_line,3
	breq trip_line_jump
	cpi num_line,2
	breq dub_line_cycle
; ----------------------------------- Одна линия огоньков 
	cpi step,4
	brlt step_back_one
	mov temp,step
	subi temp,4
	add num_lump_1,temp
	cpi num_lump_1,24
	brsh mod_lump_1
one_line_cycle_loop:
	cpi temp,0
	breq show_light_1
	lsl num_lump_1b
	cpi num_lump_1b,0
	breq get_1b_1l
after_mod1:
	dec temp
	brne one_line_cycle_loop
	rjmp show_light_1
get_1b_1l:
	ldi num_lump_1b,1
	jmp after_mod1
mod_lump_1:
	subi num_lump_1,24
	rjmp one_line_cycle_loop

step_back_one:      
	ldi temp, 4
	sub temp, step
	cp num_lump_1,temp
	brlt mod_lump_1neg
	sub num_lump_1,temp
one_line_cycle_back:
	cpi temp,0
	breq show_light_1
	lsr num_lump_1b
	cpi num_lump_1b,0
	breq get_1b_1R
after_nmod1:
	dec temp
	brne one_line_cycle_back
	rjmp show_light_1
get_1b_1R:
	ldi num_lump_1b,128
	jmp after_nmod1
mod_lump_1neg:
	ldi temp_int, 24
	add num_lump_1,temp_int
	sub num_lump_1,temp
	rjmp one_line_cycle_back                ; Выбор порта, когда шаг<0
trip_line_jump:
	rjmp trip_line_cycle

show_light_1:
	
	rcall show_number
	clr temp
	out PORTA, temp
	out PORTB, temp
	out PORTC, temp

	cpi num_lump_1,16
	brsh print13
	cpi num_lump_1,8
    brsh print12

	out PORTA, num_lump_1b
	rcall delay
    rjmp cycle
print12:
	out PORTB, num_lump_1b
    
	rcall delay
    rjmp cycle
print13:
	out PORTC, num_lump_1b
    
	rcall delay
    rjmp cycle


; --------------------------------------- Две линии огоньков ------------------
dub_line_cycle:
	cpi step,4
	brlt step_back_dub
	mov temp,step
	subi temp,4
	add num_lump_1,temp
	add num_lump_2,temp

	cpi num_lump_1,24
	brge mod_lump_21
	cpi num_lump_2,24
	brge mod_lump_22
dub_line_cycle_loop:
	cpi temp,0
	breq show_light_2

	lsl num_lump_1b
	lsl num_lump_2b

	cpi num_lump_1b,0
	breq get_1b_21l

	cpi num_lump_2b,0
	breq get_1b_22l
after_mod2:
	dec temp
	brne dub_line_cycle_loop
	rjmp show_light_2
get_1b_21l:
	ldi num_lump_1b,1
	cpi num_lump_2b,0
	breq get_1b_22l
	jmp after_mod2
get_1b_22l:
	ldi num_lump_2b,1
	jmp after_mod2
mod_lump_21:
	subi num_lump_1,24
	cpi num_lump_2,24
	brge mod_lump_22
	rjmp dub_line_cycle_loop
mod_lump_22:
	subi num_lump_2,24
	rjmp dub_line_cycle_loop

step_back_dub:      
	clr temp
	sbr temp, 4
	sub temp, step
	cp num_lump_1,temp
	brlt mod_lump_21neg
	sub num_lump_1,temp
	cp num_lump_2,temp
	brlt mod_lump_22neg
	sub num_lump_2,temp
dub_line_cycle_back:
	cpi temp,0
	breq show_light_2

	lsr num_lump_1b
	lsr num_lump_2b

	cpi num_lump_1b,0
	breq get_1b_21r

	cpi num_lump_2b,0
	breq get_1b_22r
after_nmod2:
	dec temp
	brne dub_line_cycle_back
	rjmp show_light_2
get_1b_21r:
	ldi num_lump_1b,128
	cpi num_lump_2b,0
	breq get_1b_22r
	jmp after_nmod2
get_1b_22r:
	ldi num_lump_2b,128
	jmp after_nmod2
mod_lump_21neg:
	ldi temp_int, 24
	add num_lump_1,temp_int
	sub num_lump_1,temp
	cp num_lump_2,temp
	brlt mod_lump_22neg
	sub num_lump_2,temp
	rjmp dub_line_cycle_back
mod_lump_22neg:
	ldi temp_int, 24
	add num_lump_2,temp_int
	sub num_lump_2,temp
	rjmp dub_line_cycle_back

show_light_2:
	rcall show_number
	clr temp
	out PORTA, temp
	out PORTB, temp
	out PORTC, temp

	cpi num_lump_1,16
	brsh print23
	cpi num_lump_1,8
    brsh print22

	out PORTA, num_lump_1b
	
	cpi num_lump_2,16
	brsh print_23
	cpi num_lump_2,8
    brsh print_22

	mov temp,num_lump_1b
	or temp,num_lump_2b
	out PORTA, temp
    
	rcall delay
    rjmp cycle
print22:
	out PORTB, num_lump_1b
	
	cpi num_lump_2,16
	brsh print_23
	cpi num_lump_2,8
    brlo print_21
	
	mov temp,num_lump_1b
	or temp,num_lump_2b
	out PORTB, temp
    
	rcall delay
    rjmp cycle
print23:
	out PORTC, num_lump_1b
	
	cpi num_lump_2,8
	brlo print_21
	cpi num_lump_2,16
    brlo print_22
	
	mov temp,num_lump_1b
	or temp,num_lump_2b
	out PORTC, temp
    
	rcall delay
    rjmp cycle
print_21:
	out PORTA,num_lump_2b
	
	rcall delay
    rjmp cycle
print_22:
	out PORTB,num_lump_2b
	
	rcall delay
    rjmp cycle
print_23:
	out PORTC,num_lump_2b
	
	rcall delay
    rjmp cycle
;------------------------------------ Три линии огоньков
show_light_3a:
	rjmp show_light_3
trip_line_cycle:
	cpi step,4
	brlt step_back_trip
	mov temp,step
	subi temp,4
mod_trip_lines:
	add num_lump_1,temp
	add num_lump_2,temp
	add num_lump_3,temp
	cpi num_lump_1,24
	brge mod_lump_31
	cpi num_lump_2,24
	brge mod_lump_32
	cpi num_lump_3,24
	brge mod_lump_33
trip_line_cycle_loop:
	cpi temp,0
	breq show_light_3a

	lsl num_lump_1b
	lsl num_lump_2b
	lsl num_lump_3b

	cpi num_lump_1b,0
	breq get_1b_31l
	cpi num_lump_2b,0
	breq get_1b_32l
	cpi num_lump_3b,0
	breq get_1b_33l
after_mod3:
	dec temp
	brne trip_line_cycle_loop
	rjmp show_light_3
get_1b_31l:
	ldi num_lump_1b,1
	cpi num_lump_2b,0
	breq get_1b_32l
	cpi num_lump_3b,0
	breq get_1b_33l
	jmp after_mod3
get_1b_32l:
	ldi num_lump_2b,1
	cpi num_lump_3b,0
	breq get_1b_33l
	jmp after_mod3
get_1b_33l:
	ldi num_lump_3b,1
	jmp after_mod3
mod_lump_31:
	subi num_lump_1,24
	cpi num_lump_2,24
	brge mod_lump_32
	cpi num_lump_3,24
	brge mod_lump_33
	rjmp trip_line_cycle_loop
mod_lump_32:
	subi num_lump_2,24
	cpi num_lump_3,24
	brge mod_lump_33
	rjmp trip_line_cycle_loop
mod_lump_33:
	subi num_lump_3,24
	rjmp trip_line_cycle_loop

step_back_trip:      
	clr temp
	sbr temp, 4
	sub temp, step

	cp num_lump_1,temp
	brlt mod_lump_31neg
	sub num_lump_1,temp

	cp num_lump_2,temp
	brlt mod_lump_32neg
	sub num_lump_2,temp
	
	cp num_lump_3,temp
	brlt mod_lump_33neg
	sub num_lump_3,temp


trip_line_cycle_back:
	cpi temp,0
	breq show_light_3
	
	lsr num_lump_1b
	lsr num_lump_2b
	lsr num_lump_3b

	cpi num_lump_1b,0
	breq get_1b_31r

	cpi num_lump_2b,0
	breq get_1b_32r
	
	cpi num_lump_3b,0
	breq get_1b_33r
after_nmod3:
	dec temp
	brne trip_line_cycle_back
	rjmp show_light_3
get_1b_31r:
	ldi num_lump_1b,128

	cpi num_lump_2b,0
	breq get_1b_32r
	
	cpi num_lump_3b,0
	breq get_1b_33r

	jmp after_nmod3
get_1b_32r:
	ldi num_lump_2b,128

	cpi num_lump_3b,0
	breq get_1b_33r

	jmp after_nmod3
get_1b_33r:
	ldi num_lump_3b,128

	jmp after_nmod3
mod_lump_31neg:
	sbr num_lump_1, 24
	sub num_lump_1,temp
	
	cp num_lump_2,temp
	brlt mod_lump_32neg
	sub num_lump_2,temp
	
	cp num_lump_3,temp
	brlt mod_lump_33neg
	sub num_lump_3,temp
	
	rjmp trip_line_cycle_back
mod_lump_32neg:
	sbr num_lump_2, 24
	sub num_lump_2,temp

	cp num_lump_3,temp
	brlt mod_lump_33neg
	sub num_lump_3,temp

	rjmp trip_line_cycle_back
mod_lump_33neg:
	sbr num_lump_3, 24
	sub num_lump_3,temp
	rjmp trip_line_cycle_back

jmp_p_33:
	rjmp print_33
jmp_p_3_3:
	rjmp print_3_3
jmp_p_3_2:
	RJMP print_3_2
show_light_3:
	rcall show_number
	clr temp
	out PORTA,temp
	out PORTB, temp
	out PORTC, temp

	cpi num_lump_1,16
	brge print33
	cpi num_lump_1,8
    brge print32

	out PORTA, num_lump_1b

	cpi num_lump_2,16
	brge jmp_p_33
	cpi num_lump_1,8
    brge print_32

	mov temp,num_lump_1b
	or temp,num_lump_2b
	out PORTA, temp

	cpi num_lump_3,16
	brge jmp_p_3_3
	cpi num_lump_3,8
    brge jmp_p_3_2

	mov temp,num_lump_1b
	or temp,num_lump_2b
	or temp,num_lump_3b
	out PORTA, temp
    rcall delay
    rjmp cycle

print32:
	out PORTB, num_lump_1b

	cpi num_lump_2,16
	brge print_33
	cpi num_lump_2,8
    brlt print_31

	mov temp,num_lump_1b
	or temp,num_lump_2b
	out PORTB, temp

	cpi num_lump_3,16
	brge print_3_3
	cpi num_lump_3,8
    brlt print_3_1

	mov temp,num_lump_1b
	or temp,num_lump_2b
	or temp,num_lump_3b
	out PORTB, temp
    
	rcall delay
    rjmp cycle
print33:
	out PORTC, num_lump_1b

	cpi num_lump_2,8
	brlt print_31
	cpi num_lump_2,16
    brlt print_32

	mov temp,num_lump_1b
	or temp,num_lump_2b
	out PORTC, temp

	cpi num_lump_3,8
	brlt print_3_1
	cpi num_lump_3,16
    brlt print_3_2

	mov temp,num_lump_1b
	or temp,num_lump_2b
	or temp,num_lump_3b
	out PORTC, temp

    rcall delay
    rjmp cycle
print_31:
	out PORTA,num_lump_2b

	cpi num_lump_3,16
	brge print_3_3
	cpi num_lump_3,8
    brge print_3_2

	mov temp,num_lump_2b
	or temp,num_lump_3b
	out PORTA, temp

	rcall delay
    rjmp cycle
print_32:
	out PORTB,num_lump_2b
	
	cpi num_lump_3,16
	brge print_3_3
	cpi num_lump_3,8
    brlt print_3_1

	mov temp,num_lump_2b
	or temp,num_lump_3b
	out PORTB, temp

	rcall delay
    rjmp cycle
print_33:
	out PORTC,num_lump_2b

	cpi num_lump_3,8
	brlt print_3_1
	cpi num_lump_3,16
    brlt print_3_2

	mov temp,num_lump_2b
	or temp,num_lump_3b
	out PORTC, temp

	rcall delay
    rjmp cycle

print_3_1:
	out PORTA, num_lump_3b
	rcall delay
	rjmp cycle
print_3_2:
	out	PORTB, num_lump_3b
	rcall delay
	rjmp cycle
print_3_3:
	out	PORTC, num_lump_3b
	rcall delay
	rjmp cycle


;-------------------------------------------------------- выдержка времени горения ----------
delay:                          ; Delay 1 599 999 cycles
	ldi temp, 9
    mov R13, temp
	ldi temp, 30
    mov R14, temp
	ldi temp, 229
    mov R15, temp
delay_sub:                      ; 199ms 999us 875 ns at 8.0 MHz
    dec R15
    brne delay_sub
    dec R14
    brne delay_sub
    dec R13
    brne delay_sub
    ret
;------------------------------------------------------- Прерывания 
INT0_vector:                    ; Увеличивает шаг на 1
	in R3,SREG
    inc step
	cpi step, 9
    brlt show_int 
    subi step,9 
    rjmp show_int

INT1_vector:                    ; добавляем линию
	in R3, SREG
    inc num_line
	cpi num_line, 4
    brlt show_int		; ТУТ Н
	clr num_lump_1
	clr num_lump_2
	clr num_lump_3
	clr num_lump_1b
	clr num_lump_2b
	clr num_lump_3b
	inc num_lump_1b
	inc num_lump_2b
	inc num_lump_3b
	subi num_line,3
    rjmp show_int
;------------------------------------------------------------- Вывод на порт Д
show_int:                        ; Показ модуля шага и выход

	clr temp_int
    rcall EEWrite
	rcall show_number
	out SREG,R3
    reti
show_number:                    ; Вывод чисел на порт Д для + шага

    cpi step, 4
    brlt show_negative
    mov temp_int, step
	subi temp_int,4
    swap temp_int
    add temp_int, num_line
	out PORTD, temp_int
    ret
    
show_negative:                  ; Вывод чисел на порт Д для - шага
	clr temp_int
	sbr temp_int,4
    sub temp_int, step
	sbr temp_int,8
    swap temp_int
    add temp_int, num_line
	out PORTD, temp_int
    ret
;-------------------------------------- Работа с памятью

EEWrite:	
	SBIC	EECR,EEWE		; Ждем готовности памяти к записи. Крутимся в цикле
	RJMP	EEWrite 		; до тех пор пока не очистится флаг EEWE
 
	CLI				; Затем запрещаем прерывания.
	OUT 	EEARL,temp_int 		; Загружаем адрес нужной ячейки
	OUT 	EEARH,temp_int  		; старший и младший байт адреса
	OUT 	EEDR,step 		; и сами данные, которые нам нужно загрузить
 
	SBI 	EECR,EEMWE		; взводим предохранитель
	SBI 	EECR,EEWE		; записываем байт
 
	SEI 				; разрешаем прерывания
	RET 				; возврат из процедуры
EERead:	
	SBIC 	EECR,EEWE		; Ждем пока будет завершена прошлая запись.
	RJMP	EERead			; также крутимся в цикле.
	OUT 	EEARL, temp		; загружаем адрес нужной ячейки
	OUT  	EEARH, temp		; его старшие и младшие байты
	SBI 	EECR,EERE 		; Выставляем бит чтения
	IN 		step, EEDR 		; Забираем из регистра данных результат
	RET