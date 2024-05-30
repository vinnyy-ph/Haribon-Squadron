; -----------------------------------------------------------
; This file contains the strings used in the game
; and also the error messages used for debugging
; -----------------------------------------------------------

DATASEG
	ScoreString				db	'Score: ', '$'
	LevelString				db	'Level: ', '$'

	GameOverString			db	'Game Over !$'

	WinString				db	'You Won !$'

	YouEarnedXString		db	'You earned $'
	ScoreWordString			db	' Score!$'

	PerfectLevelString		db	'Perfect level, +5 Score!$'
	HitString				db	'You got hit, -5 Score :($'

	NAString				db	'N/A$'

	RankString				db	'Rank$'
	NameString				db	'Name$'
	JustScoreString			db	'Score$'

	EnterYourNameString		db	'Enter your name, Haribon: $'

	ScoreSavedString		db	'Your score was saved!$'


;Debug strings:
	OpenErrorMsg			db	'File Open Error', 10,'$'
	FileNotFoundMsg			db	'File not found$' ;error code 2
	TooManyOpenFilesMsg		db	'Too many open files$' ;error code 4
	AccessDeniedMsg			db	'Access Denied$' ;error code 5
	InvalidAccessMsg		db	'Invalid Access$' ;error code 12
	UnknownErrorMsg			db	'Unknown Error$'

	CloseErrorMsg			db	'File Close Error', 10,'$'

	PointerSetErrorMsg		db	'Pointer Set Error', 10, '$'
	ReadErrorMsg			db	'Read Error', 10, '$'


	PlayersInTableString	db	' Players in table$'

	NoNeedToSortString		db	'0 or 1 score in table, no need to sort$'
	ReplacedRanksString		db	'Replaced ranks $'
	AndWordString			db	' and $'