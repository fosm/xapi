rest	; XAPI REST interface
	; Copyright (C) 2008  Etienne Cherdlu <80n80n@gmail.com>
	;
	; This program is free software: you can redistribute it and/or modify
	; it under the terms of the GNU Affero General Public License as
	; published by the Free Software Foundation, either version 3 of the
	; License, or (at your option) any later version.
	;
	; This program is distributed in the hope that it will be useful,
	; but WITHOUT ANY WARRANTY; without even the implied warranty of
	; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	; GNU Affero General Public License for more details.
	;
	; You should have received a copy of the GNU Affero General Public License
	; along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	
	; Set-up error frame
	s $zt="do error^rest zgoto "_$zlevel
	;
	d main
	;
	; control returns here once an error has been handled
	q
	
	
error	; Private ; Handle error
	;
	n errorId,errorCode
	;
	s errorCode=$ecode
	;
	s $zt="",$ecode="" ; Clear error handler
	;
	; Socket errors are ok, the client disconnected
	i $zstatus["%GTM-E-SOCKWRITE" q
	;
	; Log the error
	l +^error
	s (errorId,^error)=$g(^error)+1
	l -^error
	;
	zshow "*":^error(errorId)
	;
	q
	
	
main	; Private ; Process requests
	;
	n string,step,encodedCharacters
	;
	; Set up some globals for expression delimiters
	s EQUALS=$c(1)
	s LEFTBRACKET=$c(2)
	s RIGHTBRACKET=$c(3)
	s BAR=$c(4)
	s SLASH=$c(5)
	s ASTERISK=$c(6)
	;
	; Establish the session
	s %session=$$establish^session()
	;	
	s string=%ENV("REQUEST_URI")
	s string=$$unescape(string)
	;
	; Encode the query string and then apply escapes
	s string=$$encode^xapi(string)
	s encodedCharacters=EQUALS_","_LEFTBRACKET_","_RIGHTBRACKET_","_BAR_","_SLASH_","_ASTERISK
	f i=2:1:$l(string) i $e(string,i-1)="\",(","_encodedCharacters_",")[(","_$e(string,i)_",") s $e(string,i-1,i)=$$decode^xapi($e(string,i))
	;
	; Eat leading slash
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	i step'="" d error^http q
	;
	; Process steps
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	i step="api" d api q
	i step="user" d user q
	i step="oauth" d oauth q
	i step="login" d login^user q
	i step="replicate-sequences" d replicateSequences q
	i $p(step,"?",1)="edit" d edit q
	i step="" d xmlHome("","") q
	d notFound^http
	q
	
	
	
xmlHome(message,description)	; Serve the front page
	;
	n uid,user
	;
	d header^http("text/xml")
	d prolog^osmXml("/home.xsl")
	;
	s uid=$g(^session(%session,"uid"))
	s name=""
	i uid'="" s name=$g(^user(uid,"name"))
	;
	w "<Form"
	i uid'="" w $$attribute^osmXml("uid",uid,"")
	i name'="" w $$attribute^osmXml("name",name,"")
	w ">",$c(13,10)
	;
	i message'="" d
	. w "<Message"
	. w $$attribute^osmXml("title",message,""),!
	. w ">",!
	. w description,!
	. w "</Message>",!
	;
	d xmlMetrics
	;
	w "</Form>",!
	q
	
	
	
xmlMetrics	; Private ; Serve metrics
	;
	w "<Metrics>",!
	w "  <osm>",!
	w "    <nodeCount>",$g(^metric("osmNodeCount")),"</nodeCount>",!
	w "    <wayCount>",$g(^metric("osmWayCount")),"</wayCount>",!
	w "    <relationCount>",$g(^metric("osmRelationCount")),"</relationCount>",!
	w "  </osm>",!
	w "  <fosm>",!
	w "    <nodeCount>",$g(^metric("nodeCount")),"</nodeCount>",!
	w "    <wayCount>",$g(^metric("wayCount")),"</wayCount>",!
	w "    <relationCount>",$g(^metric("relationCount")),"</relationCount>",!
	w "  </fosm>",!
	w "</Metrics>",!
	q
	
	
	
	
edit	; Serve a potlatch edit instance
	;
	n uid,user
	n query
	;
	; Use REQUEST_URI because step has been escaped and so won't work with unpackQuery here
	d unpackQuery^rest(.query,$p(%ENV("REQUEST_URI"),"?",2))
	;
	d header^http("text/xml")
	d prolog^osmXml("potlatchFosm.xsl")
	;
	s uid=$g(^session(%session,"uid"))
	s name=""
	i uid'="" s name=$g(^user(uid,"name"))
	;
	w "<Form"
	i uid'="" w $$attribute^osmXml("uid",uid,"")
	i name'="" w $$attribute^osmXml("name",name,"")
	w $$attribute^osmXml("lat",$g(query("lat")),"")
	w $$attribute^osmXml("lon",$g(query("lon")),"")
	w $$attribute^osmXml("zoom",$g(query("zoom")),"")
	w ">",$c(13,10)
	;
	w "</Form>",!
	q
	
	
	
replicateSequences	; Private ; Return state file for timestamp
	;
	s currentDevice=$i
	;
	s timestamp=$p(%ENV("REQUEST_URI"),"?",2)
	i $e(timestamp,1)="Y"!($e(timestamp,1)="y") d
	. d unpackQuery^rest(.query,$p(%ENV("REQUEST_URI"),"?",2))
	. i $g(query("Y"))'="" s query("y")=query("Y")
	. i $g(query("M"))'="" s query("m")=query("M")
	. i $g(query("D"))'="" s query("d")=query("D")
	. i $g(query("H"))'="" s query("h")=query("H")
	. i $g(query("I"))'="" s query("i")=query("I")
	. i $g(query("S"))'="" s query("s")=query("S")
	. s timestamp=$g(query("y"))_"-"_$g(query("m"))_"-"_$g(query("d"))_"T"_$g(query("h"))_":"_$g(query("i"))_":"_$g(query("s"))_"Z"
	s timestamp=$tr(timestamp,"TZ-:","")
	s timestamp=$e(timestamp,1,12) ; Strip seconds
	i timestamp="" d notFound^http q
	i '$d(^exportDiff("minutelyReplicateSequences",timestamp)) s timestamp=$o(^exportDiff("minutelyReplicateSequences",timestamp),-1)
	i timestamp="" d notFound^http q
	s stateFile=$g(^exportDiff("minutelyReplicateSequences",timestamp,"stateFile"))
	i stateFile="" d notFound^http q
	;
	d header^http("text/plain")
	o stateFile
	f  d  i eof q
	. u stateFile r x s eof=$zeof i eof q
	. u currentDevice w x,!
	u currentDevice
	c stateFile
	q
	
	
oauth	; oauth methods
	;
	n step
	;
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	i $p(step,"?",1)="request_token" d requestToken^oauth q
	i $p(step,"?",1)="authorize" d authorize^oauth q
	i $p(step,"?",1)="access_token" d accessToken^oauth q
	i step="login" d oauthLogin q
	i step="api" d api q
	;
	d error^http
	q
	
	
oauthLogin	; Oauth login page
	;
	n step,token
	;
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	;
	s token=step
	d login^oauth(token)
	q
	
	
api	; API
	;
	n step
	;
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	i step="0.6" d api06 q
	d error^http
	q
	
	
api06	; API 0.6
	;
	n done,error,bbox,keyseq,qualifiers
	n constraint ; Constraint object
	n bllon,bllat,trlon,trlat
	;
	s bbox="-180,-90,180,90"
	s keySeq=0
	s error=0
	s done=0
	;
	; Parse query steps
	f  d  i string="" q
	. s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	. ;
	. i step="tile" d tile s done=1 s string="" q
	. i step="watch" d rss^watch(string) s done=1,string="" q
	. i step="requests" d requests^log s done=1,string="" q
	. i step="status" d ^status s done=1,string="" q
	. i step="node" d restNode^node(string) s done=1,string="" q
	. i $p(step,"?",1)="nodes" d restNodes^node(step,string) s done=1,string="" q
	. i step="way" d restWay^way(string) s done=1,string="" q
	. i $p(step,"?",1)="ways" d restWays^way(step,string) s done=1,string="" q
	. i step="relation" d restRelation^relation(string) s done=1,string="" q
	. i $p(step,"?",1)="relations" d restRelations^relation(step,string) s done=1,string="" q
	. i step="map" d restMap^mapReduce(string) s done=1,string="" q  ; This is mapReduce not map?bbox=
	. i step="changeset" d changeset s done=1,string="" q
	. i step="changesets" d changesets s done=1,string="" q
	. i step="user" d api06user s done=1,string="" q
	. ;
	. s element=$p(step,LEFTBRACKET,1),step=LEFTBRACKET_$p(step,LEFTBRACKET,2,$l(step))
	. ;
	. i element?1"$stylesheet=".e d  q
	. . s stylesheet=$p(element,"=",2,$l(element))
	. ;
	. ;
	. i $p(element,"?",1)="map" d map s done=1,string="" q
	. i element="stats" d ^stats s done=1,string="" q
	. i element'="node",element'="way",element'="relation",element'=ASTERISK d errorMessage("Expected: element = node|way|relation") s error=1,string="" q
	. ;
	. s constraint("element")=element
	. ;
	. ; Process predicates
	. f  d  i step="" q
	. . s predicate=$p($p(step,RIGHTBRACKET,1),LEFTBRACKET,2),step=$p(step,RIGHTBRACKET,2,$l(step))
	. . s lhs=$p(predicate,EQUALS,1),rhs=$p(predicate,EQUALS,2,$l(predicate))
	. . i lhs="bbox" s bbox=rhs q
	. . i predicate="way" s constraint("node/way")=1 q
	. . i predicate="not(way)" s constraint("node/way")=0 q
	. . i predicate="nd" s constraint("way/nd")=1 q
	. . i predicate="not(nd)" s constraint("way/nd")=0 q
	. . i predicate="tag" s constraint("node/tag")=1,constraint("way/tag")=1,constraint("relation/tag")=1 q
	. . i predicate="not(tag)" s constraint("node/tag")=0,constraint("way/tag")=0,constraint("relation/tag")=0 q
	. . ;
	. . ; It must be a key=value constraint
	. . s keySeq=keySeq+1
	. . s constraint("kv",keySeq,"key")=lhs
	. . s constraint("kv",keySeq,"value")=rhs
	i error q
	i done q
	;
	; Anything left in string are qualifiers which can be passed to the main query function
	s qualifiers=string
	;
	; Unpack bbox
	s bllon=$p(bbox,",",1)
	s bllat=$p(bbox,",",2)
	s trlon=$p(bbox,",",3)
	s trlat=$p(bbox,",",4)
	;
	; Send headers and prolog
	d xml^http("data.osm")
	d xmlProlog("")
	;
	d bbox^xapi(bllat,bllon,trlat,trlon,.constraint,qualifiers)
	q
	
	
changeset	; Changeset methods
	;
	n step
	;
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	i $p(step,"?",1)="create" d create^changeset q
	i step?1.n d changesetId q
	q
	
	
changesetId	; Specific changeset
	;
	n changesetId
	;
	s changesetId=step
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	i $p(step,"?",1)="upload" d upload^changeset(changesetId) q
	i $p(step,"?",1)="download" d download^changeset(changesetId) q
	i $p(step,"?",1)="close" d close^changeset(changesetId) q
	i $p(step,"?",1)="",$g(%ENV("REQUEST_METHOD"))="GET" d restChangeset^changeset(changesetId) q
	i $p(step,"?",1)="",$g(%ENV("REQUEST_METHOD"))="PUT" d update^changeset(changesetId) q
	q
	
	
changesets	; Changesets query
	; For now ignore any query parameters and just return the 100 most recent changesets
	d query^changeset
	q
	
	
	
user	; User preferences/details
	;
	n step
	;
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	;
	i step="new" d new^user q
	i step="create" d create^user q
	i step="confirm" d confirm^user q
	;
	d error^http
	q
	
	
api06user	; User preferences/details
	;
	n user,uid,step
	;
	; Get the authenticated user
	i '$$authenticated^user(.uid,.user) d error^http q
	;
	s step=$p(string,SLASH,1),string=$p(string,SLASH,2,$l(string))
	i step="details" d getDetails^user(uid) q
	i step="preferences" d getPreferences^user(uid) q
	i step="conflicts" d getConflicts^user(uid) q
	q
	
	
map	; Traditional map request
	;
	n bbox,bllon,bllat,trlon,trlat
	n constraint ; Constraint object
	n qualifiers
	;
	s constraint("element")=ASTERISK
	s qualifiers=""
	;
	s bbox=$p(element,"?bbox"_EQUALS,2)
	s bllon=$p(bbox,",",1)
	s bllat=$p(bbox,",",2)
	s trlon=$p(bbox,",",3)
	s trlat=$p(bbox,",",4)
	d header^http("text/xml")
	d xmlProlog("")
	d bbox^xapi(bllat,bllon,trlat,trlon,.constraint,qualifiers)
	q
	
	
tile	;
	s predicate=$p($p(step,"]",1),"[",2),step=$p(step,"]",2,$l(step))
	s x=$p(predicate,",",1)
	s y=$p(predicate,",",2)
	s z=$p(predicate,",",3)
	;
	s type=$p(string,"/",1)
	;
	; Use the IP address for the moment, use a cookie in the future
	s id=$g(%ENV("REMOTE_ADDR"))
	;
	; Has this user already flagged this tile?
	i $d(^tile(x,y,z,type,id)) d  q
	. d header^http("text/html")
	. w "You have already marked this tile"
	;
	s reputation=+$g(^reputation(id))
	s tileScore=$g(^tile(x,y,z,type))
	;
	; Enhance the user's reputation by the current score for this tile
	s reputation=reputation+tileScore
	i reputation>10 s reputation=10 ; max.
	s ^reputation(id)=reputation
	;
	; Add this user's weight to the tile
	s newTileScore=reputation
	i newTileScore=0 s newTileScore=1
	s ^tile(x,y,z,type)=newTileScore
	s ^tile(x,y,z,type,id)=reputation
	;
	d header^http("text/html")
	f type1="land","sea","mixed" i $d(^tile(x,y,z,type1)) w "Tile marked as: "_type1_" with score "_(^tile(x,y,z,type1)+1/10)_"<br/>"
	;
	s f="/home/etienne/osmxapi/www/tiles.txt"
	o f:APPEND
	u f w x,",",y,",",z,",",type,",",$zd($h,"YEAR-MM-DD 24:60:SS"),",",(^tile(x,y,z,type)+1/10),!
	c f
	q
	
	
	
errorMessage(message)	w message
	q
	
	
xmlProlog(xslTemplate)	; Public ; Write xml Prolog and xsl stylesheet elements
	;
	w "<?xml version='1.0' encoding='UTF-8'?>",!
	i xslTemplate'="" w "<?xml-stylesheet type='text/xsl' href='"_xslTemplate_"'?>",!
	;
	q
	
	
unpackQuery(params,string)	; Public ; Create the %KEY array from the name-value string sent from the client
	; Array structure:
	;   %KEY(name)=value
	;   or, if multiple values:
	;   %KEY(name,1..*)=value	
	;
	n x,pair,name,value,oldValue,seq
	;
	f x=1:1:$l(string,"&") d
	. s pair=$p(string,"&",x)
	. s name=$p(pair,"=",1)
	. s value=$p(pair,"=",2,$l(pair,"="))
	. i name="" q
	. ;
	. ; NB the sequence of the following three blocks is significant
	. ;    
	. ; If we already have a value of this kind then make it into an array
	. i $d(params(name))=1 d
	. . s oldValue=params(name)
	. . k params(name)
	. . s params(name,1)=oldValue
	. ;
	. ; Array item
	. i $d(params(name))=10 d
	. . s seq=$o(params(name,""),-1)+1
	. . s params(name,seq)=$$unescape(value)
	. ;
	. ; Single item
	. i $d(params(name))=0 s params(name)=$$unescape(value)
	. ;
	q
	
	
	; Unescape String
unescape(string)	;
	n match,char1,char2,char
	;
	; Special case - spaces are converted to + by browser
	s string=$tr(string,"+"," ")
	;
	; Convert the two characters following each % character from hex to ascii
	; then replace %HH with A.  eg replace abc%2Bdef with abc+def.
	s match=0
	f  d  i match=0 q
	. s match=$f(string,"%",match) i match=0 q
	. s char1=$$hexToDec($e(string,match))
	. s char2=$$hexToDec($e(string,match+1))
	. s char=$c(char1*16+char2)
	. s string=$e(string,1,match-2)_char_$e(string,match+2,$l(string))
	q string
	
hexToDec(hex)	;
	i hex?1n q hex
	i hex="A" q 10
	i hex="B" q 11
	i hex="C" q 12
	i hex="D" q 13
	i hex="E" q 14
	i hex="F" q 15
	i hex="a" q 10
	i hex="b" q 11
	i hex="c" q 12
	i hex="d" q 13
	i hex="e" q 14
	i hex="f" q 15
	q ""
	
	
	; Switch namespace/UCI
switch(nspace)	;
	n mImplementation
	s mImplementation=$$mImplementation()
	; i mImplementation="CACHE" znspace nspace
	i mImplementation="HBOM" d switchHbom(nspace)
	i mImplementation="GTM" ; No-op
	q
	
	
switchHbom(ucivol)	;
	n uci,vol,ucivolno,ucino,z
	;
	s uci=$p(ucivol,",",1)
	s vol=$p(ucivol,",",2)
	s ucivolno=$zu(uci,vol)
	s ucino=$p(ucivolno,",",1)
	i ucino="" q "BadUCI"/0
	;
	; s z=$zinfo(7,"pvector","ucino",ucino)
	q
	
	
	; Test for M implementation
mImplementation()	;
	i $zv["Cache" q "CACHE"
	i $zv["HBOM" q "HBOM"
	i $zv["GT.M" q "GTM"
	q "Unsupported"/0
