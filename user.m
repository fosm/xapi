user	; User details
	
new	; Public ; Create an account
	;
	n query,errors
	;
	d xmlNew(.query,.errors)
	;
	q
	
	
xmlNew(query,errors)	; Generate new user form
	d header^http("text/xml")
	d prolog^osmXml("/userNew.xsl")
	;
	w "<Form"
	s attribute=""
	f  d  i attribute="" q
	. s attribute=$o(query(attribute)) i attribute="" q
	. w $$attribute^osmXml(attribute,query(attribute),"")
	w ">",!
	;
	i $g(errors) d
	. w "<Errors>",!
	. f i=1:1:errors d
	. . w "<Error"
	. . w $$attribute^osmXml("field",errors(i,"field"),"")
	. . w ">",!
	. . w errors(i,"message")
	. . w "</Error>",!
	. w "</Errors>",!
	w "</Form>",!
	q
	
create	; Public ; Create user account
	;	
	n query,email,emailConfirmation,name,password,passwordConfirmation,emailToken,errors
	;
	;
	s errors=0
	;
	d unpackQuery^rest(.query,%ENV("POST_DATA"))
	;
	s email=query("userEmail")
	s emailConfirmation=query("userEmailConfirmation")
	s name=query("userDisplayName")
	s password=query("userPassCrypt")
	s passwordConfirmation=query("userPassCryptConfirmation")
	s claimOsmName=$g(query("claimOsmName"))
	;
	; Some basic validation
	i $l(email)<2 d error(.errors,"userEmail","Email is required")
	i email'=emailConfirmation d error(.errors,"userEmailConfirmation","Email addresses do not match")
	i password'=passwordConfirmation d error(.errors,"userPassCryptConfirmation","Passwords do not match")
	i $l(password)<6 d error(.errors,"userPassCrypt","Password is a bit on the short side to be very secure")
	i name="" d error(.errors,"userDisplayName","Please enter a display name")
	;
	i $d(^pendingUserx("nameOrEmail",name)) d error(.errors,"userDisplayName","Display Name is not available") ; Duplicate displayname
	i claimOsmName'="on",$d(^userx("name",name)) d error(.errors,"userDisplayName","Display Name is not available") ; Duplicate displayname
	i claimOsmName="on",'$d(^userx("name",name)) d error(.errors,"userDisplayName","Display Name is not recognized as an existing OpenStreetMap account name.") ; OSM name
	i $d(^userx("nameOrEmail",email)) d error(.errors,"userEmail","Email already registered.  Have you lost your password?") ; Duplicate email
	i $d(^pendingUserx("nameOrEmail",email)) d error(.errors,"userEmail","Email already registered.  Have you lost your password?") ; Duplicate email
	;
	; TODO: Need to check if this username is already registered (if sha256Password exists then account has already been registered/claimed
	;
	; Punt if there are errors in the form
	i errors d xmlNew(.query,.errors) q
	;
	l +^id("pendingUid")
	s uid=$g(^id("pendingUid"),100000000)+1
	s ^id("pendingUid")=uid
	l -^id("pendingUid")
	;
	; Allocate a token
	s emailToken=$$token()
	;
	s ^pendingUser(uid,"email")=email
	s ^pendingUser(uid,"name")=name
	s ^pendingUser(uid,"sha256Password")=$$dgst^openssl(password,"sha256")
	s ^pendingUser(uid,"emailToken")=emailToken
	s ^pendingUser(uid,"createdAt")=$$nowZulu^date()
	s ^pendingUser(uid,"claimOsmName")=claimOsmName
	s ^pendingUserx("name",name)=uid
	s ^pendingUserx("email",email)=uid
	s ^pendingUserx("nameOrEmail",name)=uid
	s ^pendingUserx("nameOrEmail",email)=uid
	s ^pendingUserx("emailToken",emailToken)=uid
	;
	; Log this event
	s userLogId=$g(^userLog)+1
	s ^userLog=userLogId
	s ^userLog(userLogId,"email")=email
	s ^userLog(userLogId,"name")=name
	s ^userLog(userLogId,"osm")=claimOsmName
	;
	s currentDevice=$i
	;
	; Send email to new user
	s file="confirm"_$j_".tmp"
	o file:NEW
	u file
	s emailAddress="<"_email_">"
	i name'=email s emailAddress=name_" "_emailAddress
	w "To: "_emailAddress,!
	w "From: fosm <80n@xenserver-2.ucsd.edu>",!
	w "Subject: fosm :: Confirm your account creation request",!
	w !
	w name,!
	w "Thank you for requesting an account to contribute to fosm.org.",!
	w !
	w "Please click the link below to confirm your request:",!
	w "http://www.fosm.org/user/confirm/"_emailToken,!
	w !
	w "If you did not apply for an account at FOSM please ignore this message and accept our apologies.",!
	w !
	w "Thank you.",!
	w "The FOSM community",!
	w ".",!
	c file
	zsystem "cat confirm"_$j_".tmp|/usr/sbin/sendmail -t"
	;
	o file c file:DELETE
	;
	; Send email to me
	s file="confirm"_$j_".tmp"
	o file:NEW
	u file
	w "To: 80n80n@gmail.com",!
	w "From: fosm <80n@xenserver-2.ucsd.edu>",!
	w "Subject: fosm signup",!
	w !
	w "The following user signed up to fosm",!
	w "Name = ",name,!
	w "email = ",email,!
	w "claim osm = ",claimOsmName,!
	w "email token = ",emailToken,!
	w !
	zwr %ENV
	w !
	w ".",!
	c file
	zsystem "cat confirm"_$j_".tmp|/usr/sbin/sendmail -t"
	;
	o file c file:DELETE
	;
	u currentDevice
	;
	; Send response to user
	; d header^http("text/html")
	s message="Thank you.  Please check your email."
	;
	d xmlHome^rest("Confirmation",message)
	;
	c currentDevice
	;
	q
	
	
error(errors,field,message)	; Add an error message to the errors object
	s errors=errors+1
	s errors(errors,"field")=field
	s errors(errors,"message")=message
	q
	
	
login	; Public ; Login
	;
	; If itis not a POST then display a blank login form
	i $g(%ENV("REQUEST_METHOD"))="GET" d xmlLogin("","","") q
	;
	d unpackQuery^rest(.query,%ENV("POST_DATA"))
	s name=$g(query("user%5Bemail%5D"))
	s password=$g(query("user%5Bpassword%5D"))
	;
	; Check user
	i name="" d xmlLogin(name,"Sorry, could not log in with those details.",$$loginHelp) q
	s uid=$g(^userx("nameOrEmail",name))
	i uid="" d xmlLogin(name,"Sorry, could not log in with those details.",$$loginHelp) q
	;
	; Check password
	i password="" d xmlLogin(name,"Sorry, could not log in with those details.",$$loginHelp) q
	s sha256Password=$$dgst^openssl(password,"sha256")
	;
	s actualSha256Password=$g(^user(uid,"sha256Password"))
	i actualSha256Password'=sha256Password d xmlLogin(name,"Sorry, could not log in with those details.",$$loginHelp) q
	;
	s ^session(%session,"authenticated")=1 ; TODO: individual roles
	s ^session(%session,"uid")=uid
	;
	; If there is a redirect request then go there
	s session=$g(^session(%session,"redirect"))
	i session'="" k ^session(%session,"redirect") d @session q
	;
	; Now go to the home page (issue client side redirect)
	w "Status: 301 Moved Permanently",!
	w "Location: /",!
	d cookie^session
	w !
	q
	
	
loginHelp()	; Help the user login
	q "Please check that you have entered your email address or username and your password correctly.  Passwords are case sensitive.  If you cannot remember your password please follow the Lost your Password link to reset it."
	
	
xmlLogin(name,message,description)	; Return form contents and error details
	d header^http("text/xml")
	d prolog^osmXml("login.xsl")
	;
	w "<Form"
	w $$attribute^osmXml("userEmail",name,"")
	w $$attribute^osmXml("rememberMe","","")
	w ">",$c(13,10)
	;
	i message'="" d
	. w "<Message"
	. w $$attribute^osmXml("title",message,""),!
	. w ">",!
	. w description,!
	. w "</Message>",!
	w "</Form>",!
	q
	
	
add(uid,name)	; Public ; Add a user (from external source, not an authorized account here)
	;
	i uid="" q
	i name="" q
	i '$d(^user(uid)) d
	. s ^user(uid,"name")=name
	. s ^user(uid,"alias",name)=""
	. s ^user(uid,"createdAt")=$$nowZulu^date()
	. s ^userx("name",name)=uid
	. s ^userx("nameOrEmail",name)=uid
	;
	; User may have changed their name
	i $g(^user(uid,"name"))'=name d
	. s ^user(uid,"name")=name
	. s ^user(uid,"alias",name)=""
	. s ^userx("name",name)=uid
	. s ^userx("nameOrEmail",name)=uid
	;
	q
	
	
onEdit(uid)	; Public ; Called when a user edits something
	;
	; Record edit counts
	s ^user(uid,"lastEditAt")=$$nowZulu^date()
	s ^user(uid,"editCount")=$g(^user(uid,"editCount"))+1
	;
	q
	
	
authenticated(uid,name)	; Public ; Is this session authenticated?
	;
	n ok,authorization,oauthToken,queryString
	n b64NamePassword,namePassword,password,sha256Password,actualSha256Password
	;
	; There are three possible ways that the request can be authorized:
	; 1) Basic digest - The user's displayName will be in the Authorization header REDIRECT_HTTP_AUTHORIZATION
	; 2) OAuth - The user's OAuth credentials will be in the Authorization header REDIRECT_HTTP_AUTHORIZATION
	; 3) OAuth - The user's OAuth credentials will be in the query string of the REQUEST_URI
	; 4) TODO: cookie - If the user has a cookie for an authenticated session then they are in
	;
	
	i $d(^session(%session,"uid")) d  q 1
	. s uid=^session(%session,"uid")
	. s name=^user(uid,"name")
	;
	s ok=1
	s authorization=$g(%ENV("REDIRECT_HTTP_AUTHORIZATION"))
	i $p(authorization," ",1)="Basic" d  i 'ok d error401 q 0
	. s b64NamePassword=$p(authorization," ",2)
	. i b64NamePassword="" s ok=0 q
	. s namePassword=$$fromB64^string(b64NamePassword)
	. s name=$p(namePassword,":",1)
	. s password=$p(namePassword,":",2,$l(namePassword))
	. i name="" s ok=0 q
	. s uid=$g(^userx("nameOrEmail",name))
	. i uid="" s ok=0 q
	. s sha256Password=$$dgst^openssl(password,"sha256")
	. s actualSha256Password=$g(^user(uid,"sha256Password"))
	. i sha256Password'=actualSha256Password s ok=0 q
	. s ok=1
	;
	i $p(authorization," ",1)="OAuth" d  i 'ok d error401 q 0
	. s oauthToken=$p($p(authorization,"oauth_token=""",2),"""",1)
	. i oauthToken="" s ok=0 q
	. s uid=$g(^oauth("access",oauthToken,"uid"))
	. i uid="" s ok=0
	;
	i authorization="" d  i 'ok d error401 q 0
	. s queryString=$g(%ENV("REQUEST_URI"))
	. s oauthToken=$p($p(queryString,"oauth_token=",2),"&",1)
	. i oauthToken="" s ok=0 q
	. s uid=$g(^oauth("access",oauthToken,"uid"))
	. i uid="" s ok=0
	;
	s ^session(%session,"authenticated")=1
	s ^session(%session,"uid")=uid
	s name=^user(uid,"name")
	q 1		
	
	
error401	; Send http 401 response
	w "Status: 401 Authorization Required",!
	w "WWW-Authenticate: Basic realm=""FOSM""",!
	w "Content-Type: text/html",!
	w !
	w "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN' 'http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd'>",!
	w "<HTML>",!
	w "<HEAD>",!
	w "<TITLE>Error</TITLE>",!
	w "<META HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=ISO-8859-1'>",!
	w "</HEAD>",!
	w "<BODY><H1>401 Unauthorized.</H1></BODY>",!
	w "</HTML>",!
	q
	
	
	
	
sendOsmMessage(name,title,body)	; Send a message to an Osm user (from FOSM)	
	;
	n message,length,session,socket,m
	;
	s message="message%5Btitle%5D="_title
	s message=message_"&message%5Bbody%5D="_body
	s message=message_"&commit=Send"
	s length=$l(message)
	s session=^osmPlanet("osmSession")
	s socket="|TCP|"_$j
	o socket:(CONNECT="www.openstreetmap.org:80:TCP":DELIMITER=$C(13,10):ATTACH="client":NOWRAP):60:"SOCKET"
	u socket
	w "POST /message/new/"_$$urlEscape(name)_" HTTP/1.1",$c(13,10)
	w "Host: www.openstreetmap.org",$c(13,10)
	w "User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.9.2.9) Gecko/20100824 Firefox/3.6.9 (.NET CLR 3.5.30729)",$c(13,10)
	w "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",$c(13,10)
	w "Accept-Language: en-gb,en;q=0.5",$c(13,10)
	w "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7",$c(13,10)
	w "Keep-Alive: 115",$c(13,10)
	w "Connection: keep-alive",$c(13,10)
	w "Cookie: _osm_location=-3.4322779774666|55.75741619093|5|M; _osm_session="_session,$c(13,10)
	w "Content-Type: application/x-www-form-urlencoded",$c(13,10)
	w "Content-Length: "_length,$c(13,10)
	w $c(13,10)
	w message,$c(13,10)
	w $c(13,10)
	f m=1:1:20 u socket r x u 0 w x
	c socket
	q
	
	
tellUser(message)	; Tell the user something
	d header^http("text/html")
	w message,!
	q
	
	
confirm	; Public ; Confirm account application
	;
	n step,token,password,name,email
	;
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	;
	s token=step
	i $l(token)'=30 d error^http q
	;	
	; Check that the user has a valid token
	i '$d(^pendingUserx("emailToken",token)) d error^http q
	;
	; Confirm the token
	i $d(^pendingUserx("emailToken",token)) d
	. s pendingUid=^pendingUserx("emailToken",token)
	. s ^pendingUser(pendingUid,"emailConfirmed")=1
	;
	; Get the current state
	s emailConfirmed=$g(^pendingUser(pendingUid,"emailConfirmed"))
	;
	; Are we good to go?
	i emailConfirmed=1 d approve(pendingUid) q
	;
	; We shouldn't be here...
	d xmlHome^rest("Oops...","Something unexpected has happened.  Sorry.")
	q
	
	
approve(pendingUid)	; Approve a pending request
	;
	n name,email,sha256Password
	;
	s name=^pendingUser(pendingUid,"name")
	s email=^pendingUser(pendingUid,"email")
	s sha256Password=^pendingUser(pendingUid,"sha256Password")
	;
	; Use an existing uid if the name has been confirmed otherwise allocate a new uid
	i $g(^pendingUser(pendingUid,"claimOsmName"))="on" s uid=$g(^userx("name",name))
	e  d
	. l +^id("uid")
	. s uid=$g(^id("uid"),100000000)+1
	. s ^id("uid")=uid
	. l -^id("uid")
	;
	s ^user(uid,"email")=email
	s ^user(uid,"name")=name
	s ^user(uid,"alias",name)=""
	s ^user(uid,"createdAt")=$$nowZulu^date()
	s ^user(uid,"sha256Password")=sha256Password
	s ^userx("name",name)=uid
	s ^userx("nameOrEmail",name)=uid
	s ^userx("email",email)=uid
	s ^userx("nameOrEmail",email)=uid
	;
	; Delete the pending user details now
	s emailToken=$g(^pendingUser(pendingUid,"emailToken"))
	k ^pendingUser(pendingUid)
	k ^pendingUserx("name",name)
	k ^pendingUserx("nameOrEmail",name)
	k ^pendingUserx("email",email)
	k ^pendingUserx("nameOrEmail",email)
	k ^pendingUserx("emailToken",emailToken)
	;
	; Log the user in
	s ^session(%session,"authenticated")=1
	s ^session(%session,"uid")=uid
	;
	d xmlHome^rest("Confirmation","Your account has been confirmed.  Welcome to FOSM.  You can now use JOSM, Merkaartor and other tools to contribute content.")
	q
	
	
token()	; Generate 30 character random token
	;
	n token,i
	;
	s token=""	
	f i=1:1:30 s token=token_$e("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",$r(61)+1)
	q token
	
	
getConflicts(uid)	; Public ; Get details of edit conflicts
	;
	n seq,changeset,version,nodeId,wayId,relationId,type,id
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	w "<conflict"
	w $$attribute^osmXml("uid",uid,"")
	w $$attribute^osmXml("name",$g(^user(uid,"name")),"")
	w ">",$c(13,10)
	;
	s seq=""
	f  d  i seq="" q
	. s seq=$o(^conflict(uid,seq)) i seq="" q
	. s type=$g(^conflict(uid,seq,"@type"))
	. s id=$g(^conflict(uid,seq,"@id"))
	. s a=$g(^conflict(uid,seq,"a"))
	. s version=$p(a,$c(1),1)
	. s changeset=$p(a,$c(1),2)
	. s timestamp=$p(a,$c(1),3)
	. s conflictUid=$p(a,$c(1),4)
	. s visible=$p(a,$c(1),5)
	. ;
	. w "<"_type
	. w $$attribute^osmXml("id",id,"")
	. w $$attribute^osmXml("version",version,"")
	. w $$attribute^osmXml("changeset",changeset,"")
	. w $$attribute^osmXml("uid",uid,"")
	. i conflictUid'="" w $$attribute^osmXml("name",$g(^user(conflictUid,"name")),"")
	. w $$attribute^osmXml("timestamp",timestamp,"")
	. i visible'="" w $$attribute^osmXml("visible",visible,"")
	. w "/>",$c(13,10)
	w "</conflict>",$c(13,10)
	q
	
	
getDetails(uid)	; Public ; Get user details and return as xml
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	w "<osm"
	w $$attribute^osmXml("version","0.6","")
	w $$attribute^osmXml("generator","FreeOSM API 0.6","")
	w ">",$c(13,10)
	;
	w "  ","<user"
	w $$attribute^osmXml("display_name",$g(^user(uid,"name")),"")
	w $$attribute^osmXml("id",uid,"")
	w $$attribute^osmXml("account_created",$g(^user(uid,"createdAt"),"2010-01-01T01:01:01Z"),"")
	w ">",$c(13,10)
	;
	w "    ","<description/>",$c(13,10)
	;
	w "    ","<contributor_terms"
	w $$attribute^osmXml("pd","false","")
	w $$attribute^osmXml("agreed","false","")
	w "/>",$c(13,10)
	;
	w "    ","<home"	
	w $$attribute^osmXml("lat","-17.39575516448","")
	w $$attribute^osmXml("lon","-66.158661736574","")
	w $$attribute^osmXml("zoom","3","")
	w "/>",$c(13,10)
	;
	w "    ","<languages>",$c(13,10)
	w "      ","<lang>","en","</lang>",$c(13,10)
	w "    ","</languages>",$c(13,10)
	;
	w "  ","</user>",$c(13,10)
	;
	w "</osm>",$c(13,10)
	;
	q
	
	
getPreferences(uid)	; Public ; Get user preferences
	;
	n key,value
	;
	d header^http("text/xml")
	d xmlProlog^rest("")
	;
	w "<osm"
	w $$attribute^osmXml("version","0.6","")
	w $$attribute^osmXml("generator","FreeOSM API 0.6","")
	w ">",$c(13,10)
	;
	w "  ","<preferences>",$c(13,10)
	s key=""
	f  d  i key="" q
	. s key=$o(^user(uid,"preferences",key)) i key="" q
	. s value=^user(uid,"preferences",key)
	. w "    ","<preference"
	. w $$attribute^osmXml("k",key,"")
	. w $$attribute^osmXml("v",value,"")
	. w "/>",$c(13,10)
	w "  ","</preferences>",$c(13,10)
	;
	w "</osm>",$c(13,10)
	;
	q
	
	
urlEscape(string)	; Private ; Url Escape a string
	;
	n out,c
	;
	s out=""
	f c=1:1:$l(string) s out=out_$$urlChar($a(string,c))
	q out
	
	
urlChar(ascii)	; Private ; Url Escape a character
	;
	n hex1,hex2
	;
	i ascii>64,ascii<91 q $c(ascii) ; A-Z
	i ascii>96,ascii<123 q $c(ascii) ; a-z
	i ascii>47,ascii<58 q $c(ascii) ; 0-9
	i ascii>255 q $c(ascii) ; ?
	;
	s hex1=$e("0123456789ABCDEF",ascii\16+1)
	s hex2=$e("0123456789ABCDEF",ascii#16+1)
	q "%"_hex1_hex2	
