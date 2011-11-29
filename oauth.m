oauth	; oauth methods
	;
	
	
	; authenticated()	; Public ; Authenticate the user using the provided oauth credentials
	;
	; Sets %ENV("REMOTE_USER") if a valid oauth_token was provided.  Leaves it undefined if
	; no token was provided.
	;
	n query,accessToken
	;
	d unpackQuery^rest(.query,$p(%ENV("REQUEST_URI"),"?",2,$l(%ENV("REQUEST_URI"))))
	;
	s accessToken=$g(query("oauth_token"))
	i accessToken="" q 0
	i '$d(^oauth("access",accessToken)) d error^http q
	s uid=^oauth("access",accessToken,"uid")
	s name=^user(uid,"name")
	;
	s %ENV("REMOTE_USER")=name
	q 1
	
	
requestToken	; Public ; Provide a request token to anyone who asks for it
	;
	n query,authorization,version,nonce,signatureMethod,consumerKey,token,timestamp,signature
	n tokenSecret
	;
	; Inspect the authorization header first
	s authorization=$g(%ENV("REDIRECT_HTTP_AUTHORIZATION"))
	i $p(authorization," ",1)="OAuth" d
	. s version=$p($p(authorization,"oauth_version=""",2),"""",1)
	. s nonce=$p($p(authorization,"oauth_nonce=""",2),"""",1)
	. s signatureMethod=$p($p(authorization,"oauth_signature_method=""",2),"""",1)
	. s consumerKey=$p($p(authorization,"oauth_consumer_key=""",2),"""",1)
	. s token=$p($p(authorization,"oauth_token=""",2),"""",1)
	. s timestamp=$p($p(authorization,"oauth_timestamp=""",2),"""",1)
	. s signature=$p($p(authorization,"oauth_signature=""",2),"""",1)
	;
	; Otherwise it may be in the query string
	i authorization="" d
	. d unpackQuery^rest(.query,$p(%ENV("REQUEST_URI"),"?",2,$l(%ENV("REQUEST_URI"))))
	. s version=$g(query("oauth_version"))
	. s nonce=$g(query("oauth_nonce"))
	. s signatureMethod=$g(query("oauth_signature_method"))
	. s consumerKey=$g(query("oauth_consumer_key"))
	. s token=$g(query("oauth_token"))
	. s timestamp=$g(query("oauth_timestamp"))
	. s signature=$g(query("oauth_signature"))
	;
	; Validate that the consumer key is known to us
	i consumerKey="" d error401 q
	i '$d(^oauth("consumer",consumerKey)) d error401 q
	;
	s token=$$token(16)
	s tokenSecret=$$token(16)
	s ^oauth("request",token,"consumerKey")=consumerKey
	s ^oauth("request",token,"tokenSecret")=tokenSecret
	s ^oauth("request",token,"createdAt")=$$nowZulu^date()
	;
	d header^http("text/plain")
	w "oauth_token="_token_"&oauth_token_secret="_tokenSecret,$c(13,10)
	q
	
	
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
	
	
	
authorize	; Public ; Ask the user to log in and authorize the request token
	;
	n query
	;
	d unpackQuery^rest(.query,$p(%ENV("REQUEST_URI"),"?",2,$l(%ENV("REQUEST_URI"))))
	;
	; Check that the request token is one that was issued by us
	s token=$g(query("oauth_token"))
	i $l(token)'=16 d error^http q  ; Check for null or overlong tokens (typical of hacking attacks)
	;
	i '$d(^oauth("request",token)) d error^http q  ; Not a token that we recognize
	;
	; TODO: is the user already authenticated?
	i $d(^session(%session,"authenticated"))
	;
	; Set up a redirect
	s ^session(%session,"redirect")="authenticated^oauth("""_token_""")"
	;
	; Get registered consumer details
	s consumerKey=^oauth("request",token,"consumerKey")
	s consumerName=^oauth("consumer",consumerKey,"name")
	;
	; Ask the user to authenticate
	d header^http("text/xml")
	d prolog^osmXml("/login.xsl")
	w "<Form>",!
	w "<Message",!
	w $$attribute^osmXml("title","Authorization Request from "_consumerName,"")
	w ">",!
	w "You have made a request to allow "_consumerName_" to have access to your account so that",!
	w "it can read your user setting and edit content using your credentials.",!
	w "It is possible for malicious applications to masquerade as "_consumerName_" and",!
	w "trick you into authenticating at this site.",!
	w "If you initiated this request from a web-site or application that you do not trust",!
	w "then we recommend that you do not proceed.",!
	w "</Message>",!
	w "</Form>",!
	;
	q
	
	
authenticated(token)	; Public ; Authorize the request token for the logged in user
	;
	; TODO: need to add roles to authentication else the consumer could do everything
	;i '$$authenticated^user(.uid,.name) d error^http q
	s uid=$g(^session(%session,"uid"))
	i uid="" d error^http q
	s name=^user(uid,"name")
	;
	s ^oauth("request",token,"uid")=uid
	s consumerKey=^oauth("request",token,"consumerKey")
	s consumerName=^oauth("consumer",consumerKey,"name")
	;
	d header^http("text/html")
	w "<html>",!
	w "<head>",!
	w "<title>FOSM :: Access to "_consumerName_"confirmed</title>",!
	w "</head>",!
	w "<body>",!
	w "<p>You have granted access to "_consumerName_" to access your account at www.fosm.org</p>",!
	w "<p>Now return to "_consumerName_" to continue with the authentication process</p>",!
	q
	
	
accessToken	; Public ; Provide an access token if the user has authorized the request token
	;
	n query,authorization,version,nonce,signatureMethod,consumerKey,requestToken,timestamp,signature
	n accessToken,accessTokenSecret,uid
	;
	; Inspect the authorization header first
	s authorization=$g(%ENV("REDIRECT_HTTP_AUTHORIZATION"))
	i $p(authorization," ",1)="OAuth" d
	. s version=$p($p(authorization,"oauth_version=""",2),"""",1)
	. s nonce=$p($p(authorization,"oauth_nonce=""",2),"""",1)
	. s signatureMethod=$p($p(authorization,"oauth_signature_method=""",2),"""",1)
	. s consumerKey=$p($p(authorization,"oauth_consumer_key=""",2),"""",1)
	. s requestToken=$p($p(authorization,"oauth_token=""",2),"""",1)
	. s timestamp=$p($p(authorization,"oauth_timestamp=""",2),"""",1)
	. s signature=$p($p(authorization,"oauth_signature=""",2),"""",1)
	;
	; Otherwise it may be in the query string
	i authorization="" d
	. d unpackQuery^rest(.query,$p(%ENV("REQUEST_URI"),"?",2,$l(%ENV("REQUEST_URI"))))
	. s version=$g(query("oauth_version"))
	. s nonce=$g(query("oauth_nonce"))
	. s signatureMethod=$g(query("oauth_signature_method"))
	. s consumerKey=$g(query("oauth_consumer_key"))
	. s requestToken=$g(query("oauth_token"))
	. s timestamp=$g(query("oauth_timestamp"))
	. s signature=$g(query("oauth_signature"))
	;
	; Validate that the consumer key is known to us
	i consumerKey="" d error401 q
	i '$d(^oauth("consumer",consumerKey)) d error401 q
	;
	; Check that the request token is one that was issued by us
	i $l(requestToken)'=16 d error^http q  ; Check for null or overlong tokens (typical of hacking attacks)
	;
	i '$d(^oauth("request",requestToken)) d error401 q  ; Not a token that we recognize
	;
	; Has it been authorized yet?
	s uid=$g(^oauth("request",requestToken,"uid")) i uid="" d error401 q
	;
	; Generate an access token and another secret
	s accessToken=$$token(22)
	s accessTokenSecret=$$token(41)
	s ^oauth("access",accessToken)=""
	s ^oauth("access",accessToken,"consumerKey")=consumerKey
	s ^oauth("access",accessToken,"nonce")=nonce
	s ^oauth("access",accessToken,"signature")=signature
	s ^oauth("access",accessToken,"signatureMethod")=signatureMethod
	s ^oauth("access",accessToken,"timestamp")=timestamp
	s ^oauth("access",accessToken,"requestToken")=requestToken
	s ^oauth("access",accessToken,"accessTokenSecret")=accessTokenSecret
	s ^oauth("access",accessToken,"uid")=uid
	s ^oauth("access",accessToken,"createdAt")=$$nowZulu^date()
	;
	w "Status: 200 OK",!
	w "Set-Cookie: _osm_session=b15b254a2db61f53c0792d17d2eab208; path=/; HttpOnly",!
	w "Content-Type: text/html",!
	w "Content-Length: 95",!
	w !
	w "oauth_token="_accessToken_"&oauth_token_secret="_accessTokenSecret
	q
	
	
token(length)	; Generate random token
	;
	n token,i
	;
	s token=""
	f i=1:1:length s token=token_$e("abcdefghijklmnopqrstuvwxyz0123456789",$r(35)+1)
	q token
	
	
