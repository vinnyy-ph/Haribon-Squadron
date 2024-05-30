; ---------------------------------------------------------
; This file contains the Aliens' procedures, including:
; - Printing the Aliens
; - Moving the Aliens
; - Shooting by the Aliens
; - Updating the Aliens' shots
; - Checking if an Alien was hit by the player's shot
; ---------------------------------------------------------

CODESEG

; ---------------------------------------------------------
; Printing the Aliens marked as alive in the status array
; Starting at the location saved in memory
; ---------------------------------------------------------
proc PrintAliens
	push bp
	mov bp, sp
	;create local variables for line+row:
	sub sp, 4
	;line: bp - 2
	;row: bp - 4

	mov ax, [AliensPrintStartLine]
	mov [bp - 2], ax

	xor bx, bx ;current Alien #

	mov cx, 3
@@printAliensLine:
	push cx

	mov ax, [AliensPrintStartRow]
	mov [bp - 4], ax


	mov cx, 8
@@printAlien:
	push cx

	push bx

	cmp [byte ptr AliensStatusArray + bx], 1
	jne @@skipAlien

	
	;Print Alien:
	push [word ptr AlienFileHandle]
	push AlienLength
	push AlienHeight
	push [word ptr bp - 2]
	push [word ptr bp - 4]
	push offset FileReadBuffer
	call PrintBMP

@@skipAlien:
	pop bx
	inc bx

	pop cx


	add [word ptr bp - 4], 36 ;set location for next Alien

	loop @@printAlien

	add [word ptr bp - 2], 20 ;Set location for next line

	pop cx
	loop @@printAliensLine

	add sp, 4

	pop bp
	ret
endp PrintAliens


; ---------------------------------------------------------------------------------------------------
; Replacing every printed Alien with black color (with a black frame around it, to handle movement)
; ---------------------------------------------------------------------------------------------------
proc ClearAliens
	push bp
	mov bp, sp
	;create local variables for line+row:
	sub sp, 4
	;line: bp - 2
	;row: bp - 4

	mov ax, [AliensPrintStartLine]
	mov [bp - 2], ax

	xor bx, bx ;current Alien #

	mov cx, 3
@@printAliensLine:
	push cx

	mov ax, [AliensPrintStartRow]
	mov [bp - 4], ax


	mov cx, 8
@@printAlien:
	push cx

	push bx

	cmp [byte ptr AliensStatusArray + bx], 1
	jne @@skipAlien

	
	;clear Alien:
	push 30
	push 24
	mov ax, [bp - 2]
	sub ax, 4
	push ax
	mov ax, [bp - 4]
	sub ax, 4
	push ax
	push BlackColor
	call PrintColor

@@skipAlien:
	pop bx
	inc bx

	pop cx


	add [word ptr bp - 4], 36 ;set location for next Alien

	loop @@printAlien

	add [word ptr bp - 2], 20 ;Set location for next line

	pop cx
	loop @@printAliensLine

	add sp, 4

	pop bp
	ret
endp ClearAliens


; --------------------------------------------------------
; Moving the Aliens location by current location
; Going down after moving a full line, changing directions
; --------------------------------------------------------
proc UpdateAliensLocation
	cmp [byte ptr AliensMovesToSideDone], 8
	je @@reverseDirectionGoDown


	inc [byte ptr AliensMovesToSideDone]


	cmp [byte ptr AliensMoveRightBool], 1
	je @@moveRight

	;Left:
	sub [word ptr AliensPrintStartRow], 4
	jmp @@procEnd


@@moveRight:
	add [word ptr AliensPrintStartRow], 4
	jmp @@procEnd

@@reverseDirectionGoDown:
	xor [byte ptr AliensMoveRightBool], 1
	mov [byte ptr AliensMovesToSideDone], 0
	add [word ptr AliensPrintStartLine], 4
	
@@procEnd:
	ret
endp UpdateAliensLocation


; ---------------------------------------------------------------
; Updating Aliens location once every 4 game loops
; When updated location is updated and Aliens are printed again
; ---------------------------------------------------------------
proc CheckAndMoveAliens
	cmp [byte ptr AliensLoopMoveCounter], 3
	jne @@skipPrint

	;Move:
	call ClearAliens
	call PrintAliens
	call UpdateAliensLocation
	mov [byte ptr AliensLoopMoveCounter], 0
	jmp @@procEnd

@@skipPrint:
	inc [byte ptr AliensLoopMoveCounter]

@@procEnd:
	ret
endp CheckAndMoveAliens

; -------------------------------------------------
; Choosing a random Alien to shoot
; If not found after a few tries, no shot performed
; Updating shot location, adding it to shots arrays
; -------------------------------------------------
proc AliensRandomShot
	push bp
	mov bp, sp

	;Check if max reached:
	mov al, [AliensShootingCurrentAmount]
	cmp [AliensShootingMaxAmount], al
	je @@procEnd

	;Shoot only after Aliens movement:
	cmp [byte ptr AliensLoopMoveCounter], 3
	jne @@procEnd


	mov al, [AliensShootingMaxAmount]
	sub al, 2
	cmp al, [AliensShootingCurrentAmount]
	ja @@shootRandomly

	;Shoot or not, randomly:
	;Chance of 3/4 to shoot
	push 4
	call Random
	cmp ax, 0
	je @@procEnd

@@shootRandomly:
	sub sp, 2 ;create local variable counting fails
	;address: bp - 2
	mov [word ptr bp - 2], 0

@@getRandomAlien:
	;Get a random Alien
	push 24
	call Random
	mov si, ax

	;Check if Alien 'alive':
	cmp [byte ptr AliensStatusArray + si], 0
	jne @@setShootingLocation

	inc [word ptr bp - 2]

	cmp [word ptr bp - 2], 4
	jne @@getRandomAlien

	add sp, 2 ;clear local variable
	jmp @@procEnd


@@setShootingLocation:
	add sp, 2 ;clear local variable

	mov bl, 8
	div bl

	;al = lines, ah = rows
	push ax

	mov dx, [AliensPrintStartLine]
	add dx, 15 ;set to buttom of first Alien

	;set correct line:
	xor ah, ah
	mov bl, 20
	mul bl

	add dx, ax
	mov bl, [AliensShootingCurrentAmount]
	xor bh, bh
	shl bx, 1
	mov [AliensShootingLineLocations + bx], dx


	pop ax
	shr ax, 8 ;rows # in al
	mov bl, 35
	mul bl

	add ax, 10 ;set to middle of Alien
	add ax, [AliensPrintStartRow]

	mov bl, [AliensShootingCurrentAmount]
	xor bh, bh
	shl bx, 1
	mov [AliensShootingRowLocations + bx], ax

	inc [byte ptr AliensShootingCurrentAmount]

@@procEnd:
	pop bp
	ret
endp AliensRandomShot


; -------------------------------------------------------
; Updating Aliens' shots location by moving them down
; Removing shots that reached the bottom of the screen
; -------------------------------------------------------
proc UpdateAliensShots

	cmp [byte ptr AliensShootingCurrentAmount], 0
	je @@procEnd

	xor ch, ch
	mov cl, [AliensShootingCurrentAmount]

	xor di, di

@@moveShooting:
	add [word ptr AliensShootingLineLocations + di], 10

	add di, 2
	loop @@moveShooting

	;Check if oldest shot reached the bottom:
	cmp [word ptr AliensShootingLineLocations], StatsAreaBorderLine - 12
	jb @@procEnd

	;Remove shot:
	mov [word ptr AliensShootingLineLocations], 0

	mov [word ptr AliensShootingRowLocations], 0

	;If it's the only shot, no need to move others in array:
	cmp [byte ptr AliensShootingCurrentAmount], 1
	je @@decShootingsAmount

	cld

	mov ax, ds
	mov es, ax

	mov si, offset AliensShootingLineLocations
	mov di, si
	add si, 2

	mov cx, 9
	rep movsw


	mov si, offset AliensShootingRowLocations
	mov di, si
	add si, 2

	mov cx, 9
	rep movsw

@@decShootingsAmount:
	dec [byte ptr AliensShootingCurrentAmount]

@@procEnd:
	ret
endp UpdateAliensShots


; --------------------------------------------------------------------
; Printing the Aliens' shots at their current locations
; --------------------------------------------------------------------
proc PrintAliensShots
	cmp [byte ptr AliensShootingCurrentAmount], 0
	je @@procEnd

	xor si, si

	xor ch, ch
	mov cl, [AliensShootingCurrentAmount]

@@printShooting:
	push cx
	push si

	push ShootingLength
	push ShootingHeight
	push [word ptr AliensShootingLineLocations + si]
	push [word ptr AliensShootingRowLocations + si]
	push GreenColor
	call PrintColor

	pop si
	add si, 2

	pop cx
	loop @@printShooting


@@procEnd:
	ret
endp PrintAliensShots


; --------------------------------------------------
; Replacing printed Aliens' shots with black color
; (before printing at updated locations)
; --------------------------------------------------
proc ClearAliensShots
	xor si, si
	
	xor ch, ch
	mov cl, [AliensShootingCurrentAmount]

	cmp cx, 0
	jne @@clearShot

	ret

@@clearShot:
	push cx
	push si

	push ShootingLength
	push ShootingHeight
	push [AliensShootingLineLocations + si]
	push [AliensShootingRowLocations + si]
	push BlackColor
	call PrintColor

	pop si
	add si, 2
	pop cx
	loop @@clearShot
	
	ret
endp ClearAliensShots


; ------------------------------------------------
; Checks if an Alien was hit by player's shot
; If true, Alien is marked as 'hit' and removed
; ------------------------------------------------
proc CheckAndHitAlien
	;Check if Alien hit:
	;Check above:
	mov ah, 0Dh
	mov dx, [PlayerBulletLineLocation]
	dec dx
	mov cx, [PlayerShootingRowLocation]
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@hitAlien

	;Check below:
	mov ah, 0Dh
	mov dx, [PlayerBulletLineLocation]
	add dx, 4
	mov cx, [PlayerShootingRowLocation]
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@hitAlien

	mov ah, 0Dh
	mov dx, [PlayerBulletLineLocation]
	sub dx, 3
	mov cx, [PlayerShootingRowLocation]
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@hitAlien

	;Check from left
	mov ah, 0Dh
	mov dx, [PlayerBulletLineLocation]
	mov cx, [PlayerShootingRowLocation]
	dec cx
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@hitAlien

	;Check from right
	mov ah, 0Dh
	mov dx, [PlayerBulletLineLocation]
	mov cx, [PlayerShootingRowLocation]
	add cx, 2
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@hitAlien

	jmp @@procEnd


@@hitAlien:

	;Play sound:
	call playSoundAlien

	;set cursor to top left
	xor bh, bh
	xor dx, dx
	mov ah, 2
	int 10h

	mov ax, [PlayerBulletLineLocation]
	sub ax, [AliensPrintStartLine]

	cmp ax, 22
	jb @@hitInLine0

	cmp ax, 0FFE0h
	ja @@hitInLine0

	cmp ax, 42
	jb @@hitInLine1

	push 2
	jmp @@checkhitRow

@@hitInLine0:
	push 0
	jmp @@checkhitRow

@@hitInLine1:
	push 1

@@checkhitRow:
	cmp [byte ptr DebugBool], 1
	jne @@skipLineDebugPrint

; Print hit debug info (if used debug flag):
	mov ah, 2
	xor bh, bh
	xor dx, dx
	int 10h

	mov dl, 'L'
	int 21h

	pop dx
	push dx
	add dl, 30h
	mov ah, 2
	int 21h

@@skipLineDebugPrint:
	mov ax, [PlayerShootingRowLocation]
	sub ax, [AliensPrintStartRow]
	add ax, 2

	;In some rare cases startRow is bigger than shootingRow, check:
	cmp ax, 0FFE0h
	jb @@setForRowFind

	xor cx, cx
	jmp @@rowFound

@@setForRowFind:
	xor cx, cx ;row counter
	mov dx, 28
@@checkRow:
	cmp ax, dx
	jb @@rowFound

	add dx, 36
	inc cx
	jmp @@checkRow

@@rowFound:
	cmp [byte ptr DebugBool], 1
	jne @@skipRowDebugPrint

	mov ah, 2
	mov dl, 'R'
	int 21h

	mov dx, cx
	add dl, 30h
	int 21h

@@skipRowDebugPrint:
	pop bx
	;bx holding line, cx holding row

	shl bx, 3 ;multiply by 8
	add bx, cx

	push bx

	mov [byte ptr AliensStatusArray + bx], 0
	dec [byte ptr AliensLeftAmount]

	mov [byte ptr PlayerShootingExists], 0
	mov [word ptr PlayerBulletLineLocation], 0
	mov [word ptr PlayerShootingRowLocation], 0

	;Increase and update score:
	inc [byte ptr Score]
	call UpdateScoreStat

	pop ax
	;clear hit Alien print
	mov bl, 8
	div bl
	push ax
	xor ah, ah
	mov bl, 20
	mul bl

	mov dx, ax
	add dx, [AliensPrintStartLine]
	sub dx, 4

	pop ax
	shr ax, 8
	mov bl, 36
	mul bl
	add ax, [AliensPrintStartRow]
	sub ax, 4

	push 36
	push 24
	push dx
	push ax
	push BlackColor
	call PrintColor

@@procEnd:
	ret
endp CheckAndHitAlien