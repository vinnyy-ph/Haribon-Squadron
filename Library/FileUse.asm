; -----------------------------------------------------------
; This file contains the OpenFile and CloseFile procedures.
; OpenFile: Opens a file with read and write permissions.
; CloseFile: Closes a file.
; -----------------------------------------------------------

CODESEG

; ---------------------------------------------------------------------
; Get FileName address, and destination FileHandle location from stack.
; Put the FileHandle in destination address
; If succeed, ax=1, if failed ax=0
; ---------------------------------------------------------------------
proc OpenFile
	push bp ;Preserve bp's value
	mov bp, sp ;Use bp as a not-changing memory pointer for using pushed values before call

; ------------------------------------------------------
; Stack State:
; | bp | bp + 2 |       bp + 4      |       bp + 6      |
; | bp |   sp   | FileHandle traget | FileName location |
; ------------------------------------------------------

	mov ah, 3Dh ;ah=3Dh -> opening file
	mov al, 2 ;al=2 -> Read + Write permissions
	mov dx, [bp + 6] ;dx holding file name address
	int 21h ;Open the file

	jc @@printError ;Carry flag turned on means there was an error.

	mov bx, [bp + 4] ;Hold destination FileHandle address
	mov [bx], ax ;Save the FileHandle from ax to memory

	mov ax, 1

	jmp @@procEnd

@@printError:
	cmp [byte ptr DebugBool], 0 ;skip print if debug disabled
	je @@zeroAX

	push ax ;save error code

	;set cursor to top left:
	mov ah, 2
	xor bh, bh
	xor dx, dx
	int 10h
	
	;Print error message if got an error opening the file:
	mov dx, offset OpenErrorMsg
	mov ah, 9
	int 21h

	pop ax ;get error code

	;print appropriate error message:
	cmp ax, 2
	je @@printNotFound

	cmp ax, 4
	je @@printTooManyFiles

	cmp ax, 5
	je @@printAccessDenied

	cmp ax, 12
	je @@printInvalidAccess


	;print unknown error:
	mov dx, offset UnknownErrorMsg
	mov ah, 9
	int 21h
	jmp @@zeroAX

@@printNotFound:
	mov dx, offset FileNotFoundMsg
	mov ah, 9
	int 21h
	jmp @@zeroAX

@@printTooManyFiles:
	mov dx, offset TooManyOpenFilesMsg
	mov ah, 9
	int 21h
	jmp @@zeroAX

@@printAccessDenied:
	mov dx, offset AccessDeniedMsg
	mov ah, 9
	int 21h
	jmp @@zeroAX

@@printInvalidAccess:
	mov dx, offset InvalidAccessMsg
	mov ah, 9
	int 21h

@@zeroAX:
	xor ax, ax

@@procEnd:
	pop bp ;pop bp's value back + Clear the stack from pushed values
	ret 4 ;End proc + Clear the stack from pushed values
endp OpenFile


; ------------------------------------------------------------
; Get FileHandle from stack.      Stack State:
; Close the file.                 | bp | bp + 2 |   bp + 4   |
;                                 | bp |   sp   | FileHandle |
; ------------------------------------------------------------
proc CloseFile
	push bp ;Preserve bp's value
	mov bp, sp ;Use bp as a not-changing memory pointer for using pushed values before call

	mov bx, [bp + 4] ;Hold the FileHandle
	mov ah, 3Eh ;ah=3 -> Close the file
	int 21h ;Close the file

	jnc @@procEnd ;carry off means no error

	;Print error if got an error closing the file:
	mov dx, offset CloseErrorMsg
	mov ah, 9
	int 21h

@@procEnd:
	pop bp ;pop bp's value back + Clear the stack from pushed values
	ret 2 ;End proc + Clear the stack from pushed values
endp CloseFile