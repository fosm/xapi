session	; Session Class
	
establish()	; Public ; Establish an existing session or create a new one
	;
	n session,cookie
	;
	s session=""
	;
	; Get existing session if there is one
	s cookie=$g(%ENV("HTTP_COOKIE"))
	i cookie'="" d
	. s session=$p($p(cookie,"_osm_session=",2),";",1)
	. i session'="",'$d(^session(session)) s session="" ; Non-existant session
	;
	; If no existing session then create one
	i session="" d
	. f  s session=$$token(32) i '$d(^session(session)) q
	. s ^session(session,"createdAt")=$h
	;
	; Increment session counter
	s ^session(session,"count")=$g(^session(session,"count"))+1
	;
	q session
	
	
cookie	; Public ; Give the client a cookie containing the existing session
	;
	; TODO: Add expiry data if user asked to be remembered
	;
	w "Set-cookie: _osm_session="_%session_"; path=/; HttpOnly",!
	;
	q
	
	
token(length)	; Generate random token
	;
	n token,i
	;
	s token=""
	f i=1:1:length s token=token_$e("abcdefghijklmnopqrstuvwxyz0123456789",$r(35)+1)
	q token
	
	
