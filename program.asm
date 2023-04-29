stack segment para stack
db 64 dup (' ')
stack ends
data segment para 'data'
	ball_orginal_x dw 0a0h
	ball_orginal_y dw 64h
	xpos dw 0ah
	ypos dw 0ah
	bsize dw 04h ;size of ball
	time_aux db 0
	xbvel dw 05h; X velocity
	ybvel dw 02h; y velocity
	window_width dw 140h
	window_height dw 0c8h
	paddle_left_x dw 0ah
	paddle_left_y dw 0ah
	paddle_right_x dw 130h
	paddle_right_y dw 0ah
	paddle_width dw 05h
	paddle_height dw 1fh
	paddle_velocity dw 05h
	paddle_point db 00h,00h
	game_over_sign db 'game over$',0
	rekey db 'press space key to restart$',0
	
data ends 
code segment para 'code'
	main proc far
	assume cs:code,ds:data,ss:stack
	mov ax,data
	mov ds,ax
	call clear_screen
	check_time:
		mov ah,2ch ; get sys tym
		int 21h ; ch = hr cl = min dh second dl = 1/100 second
		cmp dl,time_aux
		je check_time
		mov time_aux,dl				; update time
		call clear_screen
		call move_ball
		call drawb
		call move_paddle
		call drawp
		call draw_ui
		jmp check_time
	ret
	main endp
	
	move_ball proc near
		mov ax,xbvel
		add xpos,ax
		cmp xpos,00h
		je reset_x 
		mov ax,window_width
		cmp xpos,ax
		je reset_x2
		jmp move
		reset_x2:
			inc [paddle_point]
			call reset_ball_position
			cmp [paddle_point],05h
			je game_over
			ret
		reset_x:
			inc [paddle_point+1]
			call reset_ball_position
			cmp [paddle_point+1],05h
			je game_over
			ret
		
		game_over:
			repi:
				mov ah,02h
				mov bh,00h
				mov dl,80h
				mov dh,02h
				int 10h
				
				mov ah,09h
				lea dx,game_over_sign
				int 21h
				
				mov ah,02h
				mov bh,00h
				mov dl,00h
				mov dh,05h
				int 10h
				
				mov ah,09h
				lea dx,rekey
				int 21h
				
				mov ah,01h
				int 16h
				mov ah,00h
				int 16h
				cmp al,20h
				jne repi
			mov [paddle_point],00h
			mov [paddle_point+1],00h
		move:
		mov ax,ybvel
		add ypos,ax
		
		cmp ypos,00h
		je neg_velocity_y
		mov ax,window_height
		cmp ypos,ax
		je neg_velocity_y
		
		mov ax,xpos
		add ax,bsize
		cmp ax,paddle_right_x
		jng left
		mov ax,paddle_right_x
		add ax,paddle_width
		cmp ax,xpos
		jng left
		mov ax,ypos
		add ax,bsize
		cmp ax,paddle_right_y
		jng left
		mov ax,paddle_right_y
		add ax,paddle_height
		cmp ax,ypos
		jng left
		neg xbvel
		ret
		left:
			mov ax,xpos
			add ax,bsize
			cmp ax,paddle_left_x
			jng exito
			mov ax,paddle_left_x
			add ax,paddle_width
			cmp ax,xpos
			jng exito
			mov ax,ypos
			add ax,bsize
			cmp ax,paddle_left_y
			jng exito
			mov ax,paddle_left_y
			add ax,paddle_height
			cmp ax,ypos
			jng exito
			neg xbvel
			ret
		exito:
			ret
		neg_velocity_y:
			neg ybvel
			ret
		
	move_ball endp
	
	
	reset_ball_position proc near
	mov ax,ball_orginal_x
	mov xpos,ax 
	mov ax,ball_orginal_y
	mov ypos,ax
	ret
	reset_ball_position endp
	
	clear_screen proc near
		mov ah,00h ;set the config to vid mode
		mov al,13h ;choose the vid mode
		int 10h ;excute
		mov ah,0bh ; set config
		mov bh,00h ; bg clr
		mov bl,00h ;black
		int 10h
		ret
	clear_screen endp
	drawb proc near
	mov cx,xpos ;set x pos
	mov dx,ypos ; set y pos
	drawx:
		mov ah,0ch ;pixel wrt
		mov al,0fh ;white clr
		mov bh,00h ; page set
		int 10h
		inc cx
		mov ax,cx
		sub ax,xpos
		cmp ax,bsize
		jng drawx
		mov cx,xpos
		inc dx
		mov ax,dx
		sub ax,ypos
		cmp ax,bsize
		jng drawx
	
	ret
	drawb endp
	
	
	drawp proc near
	mov cx,paddle_left_x ;set x pos
	mov dx,paddle_left_y	; set y pos
	drawpx:
		mov ah,0ch ;pixel wrt
		mov al,0fh ;white clr
		mov bh,00h ; page set
		int 10h
		inc cx
		mov ax,cx
		sub ax,paddle_left_x
		cmp ax,paddle_width
		jng drawpx
		mov cx,paddle_left_x
		inc dx
		mov ax,dx
		sub ax,paddle_left_y
		cmp ax,paddle_height
		jng drawpx
	mov cx,paddle_right_x ;set x pos
	mov dx,paddle_right_y	; set y pos
	drawprx:
		mov ah,0ch ;pixel wrt
		mov al,0fh ;white clr
		mov bh,00h ; page set
		int 10h
		inc cx
		mov ax,cx
		sub ax,paddle_right_x
		cmp ax,paddle_width
		jng drawprx
		mov cx,paddle_right_x
		inc dx
		mov ax,dx
		sub ax,paddle_right_y
		cmp ax,paddle_height
		jng drawprx
	ret
	drawp endp
	
	
	move_paddle proc near
	mov ah,01h
	int 16h
	jz check_r_paddle ;zf = 1 , jz -> chk_r_paddle
	mov ah,00h
	int 16h
	cmp al,77h
	je move_l_up
	cmp al,73h 
	je move_l_down
	jmp check_r_paddle
	
	move_l_up:
		mov ax,paddle_velocity
		sub paddle_left_y,ax
		cmp paddle_left_y,05h
		jl fix_y_u
		jmp check_r_paddle

		fix_y_u:
			mov paddle_left_y,05h
			jmp check_r_paddle
	move_l_down:
		mov ax,paddle_velocity
		add paddle_left_y,ax
		mov ax,window_height
		sub ax,05h
		sub ax,paddle_height
		cmp paddle_left_y,ax
		jg fix_y_d
		jmp check_r_paddle
		fix_y_d:
			mov paddle_left_y,ax
			jmp check_r_paddle
	check_r_paddle:
		cmp al,69h
		je move_r_up
		cmp al,6bh 
		je move_r_down
		jmp exits
	move_r_up:
		mov ax,paddle_velocity
		sub paddle_right_y,ax
		cmp paddle_right_y,05h
		jl fix_r_u
		jmp exits
		fix_r_u:
			mov paddle_right_y,05h
			jmp exits
	move_r_down:
		mov ax,paddle_velocity
		add paddle_right_y,ax
		mov ax,window_height
		sub ax,05h
		sub ax,paddle_height
		cmp paddle_right_y,ax
		jg fix_r_d
		jmp exits
		fix_r_d:
			mov paddle_right_y,ax
			jmp exits
	
	exits:
	
		ret
	move_paddle endp
	
	draw_ui proc near
	mov ah,02h
	mov bh,00h
	mov dl,0eh
	mov dh,02h
	int 10h
	
	mov bl,[paddle_point]
	add bl,30h
	mov ah,06h
	mov dl,bl
	int 21h
	
	mov ah,02h
	mov bh,00h
	mov dl,8fh
	mov dh,02h
	int 10h
	
	mov ah,06h
	mov bl,[paddle_point+1]
	add bl,30h
	mov dl,bl
	int 21h
	
	ret
	draw_ui endp
code ends
end
