serverLink	; Server Link
	; Copyright (C) 2008,2011  Etienne Cherdlu <80n80n@gmail.com>
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
	
	q
	
	
	; Main entry point
start(port,logLevel)	; 
	n mImplementation
	s mImplementation=$$mImplementation()
	;
	s port=$g(port) i port="" s port=6500
	i $d(^serverLink("port")) s port=^serverLink("port")
	s logLevel=$g(logLevel) i logLevel="" s logLevel=0
	i $d(^serverLink("logLevel")) s logLevel=^serverLink("logLevel")
	;
	k ^serverLink("stop")
	d logMessage("Server started",1,port)
	;
	i mImplementation="CACHE" d open01(port,logLevel)
	i mImplementation="HBOM" d open02(port,logLevel)
	i mImplementation="GTM" d open03(port,logLevel)
	q
	
	
	; Test for M implementation
mImplementation()	;
	i $zv["Cache" q "CACHE"
	i $zv["HBOM" q "HBOM"
	i $zv["M21" q "HBOM"
	i $zv["GT.M" q "GTM"
	q "Unsupported"/0
	
	
	
	; Open socket for listening (accept mode)
	; Cache
open01(port,logLevel)	;
	n socket,stop,string
	;
	s socket="|TCP|"_port
	o socket:(:port:"PSTA"):10 e  d logMessage("Cannot open socket",0,port) s stop=1 q
	s stop=0
	;
	f  d  i stop q
	. u socket:"PSTA"
	. r string:60 e  s stop=$$checkStop q
	. d logMessage("Server connection"_string,2,port)
	. j sub01^serverLink(port,logLevel):(:4:socket:socket):10 e  d logMessage("Cannot spawn sub-process",1,port) q
	;
	c socket
	d logMessage("Server stopped",1,port)
	q
	
	
	; Open socket for listening (accept mode)
	; HBOM
open02(port,logLevel)	;
	n device,socket,stop
	;
	s device=9050
	o device:("TCP":"":port):10 e  d logMessage("Cannot open socket",0,port) s stop=1 q
	u device w /listen(10)
	s stop=0
	;
	f  d  i stop q
	. u device w /wait(60)
	. i $key'="CONNECT" s stop=$$checkStop q
	. s socket=$zsocket(device)
	. d logMessage("Server connection socket #"_socket,2,port)
	. u device:(::::::socket) ; Detach socket
	. i $device'="" d logMessage("Unable to detach socket #"_socket_" $device="_$device,1,port)
	. c device:socket
	. j sub02^serverLink(port,socket,logLevel)::10 e  d logMessage("Cannot spawn sub-process for socket #"_socket,1,port) q
	;
	c device
	d logMessage("Server stopped",1,port)
	q
	
	
	; Open socket for listening (accept mode)
	; GT.M
	; Because GT.M cannot pass sockets between processes we are using the following strategy:
	; 1 Job off a real serverLink process which will listen on the port
	; 2 Use a lock to monitor when it has completed
	; 1 Open port 5000 in listen mode
	; 2 Job another process which will also attempt to listen on port 5000. It will hang until
	;   this process closes the listen socket.
	; 3 As soon as this process gets a connection, close the listen socket and start to service the
	;   the active connection.
open03(port,logLevel)	  ;
	n process,started
	;
	; Allocate a process Id for this spawner
	tstart *
	s process=$g(^serverLink("process"))+1
	s ^serverLink("process")=process
	tcommit
	;
	; Keep starting servers
	f  d  i $$checkStop^serverLink() q
	. l +^serverLink("process",process) ; Wait until the last job has finished
	. s ^serverLink("process",process)="starting"
	. l -^serverLink("process",process)
	. ; j open03a^serverLink(port,logLevel,process)
	. zsystem "$zappy/scripts/"_^osmPlanet("instance")_" "_port_" "_$g(^serverLink("logLevel"))_" "_process
	. ;
	. ; Wait until it has started
	. s started=0
	. f  d  i started q
	. . i $g(^serverLink("process",process))="started" s started=1 q
	;
	; Tidy up
	k ^serverLink("process",process)
	q
	
	
	; Started serverLink process (GT.M)
open03a(port,logLevel,process)	;
	;
	; Lock and keep the lock until the process completes
	l +^serverLink("process",process)
	s ^serverLink("process",process)="started"
	d open03b(port,logLevel)
	l -^serverLink("process",process)
	q
	
	
	; GT.M real serverLink process
open03b(port,logLevel)	;
	n device,socket,stop,ok
	; 
	s device="|TCP|"_port
	s stop=0,ok=0
	f  d  i stop!ok q
	. o device:(ZLISTEN=port_":TCP":DELIMITER=$c(10):ATTACH="listen":NOWRAP:IOERROR="TRAP"):60:"SOCKET" e  s stop=$$checkStop q
	. s ok=1
	i stop d logMessage("Server stopped",1,port) q
	;
	; Now listen
	d logMessage("Server listening on port "_port,3,port)
	u device w /listen(1)
	;
	s stop=0
	f  d  i stop q
	. u device w /wait(60)
	. i $p($key,"|",1)'="CONNECT" s stop=$$checkStop q
	. s socket=$p($key,"|",2)
	. d logMessage("Server connection socket #"_socket,2,port)
	. ;
	. ; Release listen socket so that the next listener can fire up
	. c device:(SOCKET="listen")
	. ;
	. ; Process the request
	. d sub03^serverLink(port,socket,logLevel)
	. s stop=1
	;
	c device
	d logMessage("Server stopped",1,port)
	q
	
	
	; Start here with a connection
	; Cache
	; TCP socket is current device
sub01(port,logLevel)	;
	n socket,stop,eof,string,key,%ENV
	;
	; Top level error handler
	n $et
	s $et="i $estack=0 znspace """_$znspace_""" g error^serverLink"
	;
	s socket=$p
	d logMessage("Sub-process started on socket #"_socket,2,port)
	;
	; Handshake
	u socket:(::"STP")
	r string:60 e  d logMessage("Handshake timeout",0,port) c socket q
	d logMessage("Handshake from client: "_string,2,port)
	i '$$clientVersion(string) d  c socket q
	. d logMessage("Handshake rejected from client: "_string,0,port)
	w $$serverVersion,!
	;
	s stop=0
	s eof=0
	f  d  i stop!eof q
	. u socket:(::"STP")
	. r string:60 e  d logMessage("Client timeout",1,port) s stop=1 q 
	. i string="%END" s eof=1 q
	. i $e(string,1,5)="%ENV:" d
	. . s key=$p($e(string,6,$l(string)),"=",1)
	. . i key'="" s %ENV(key)=$e(string,6+$l(key)+1,$l(string))
	. d logMessage(string,2,port)
	;
	; Check for stop
	i stop c socket q
	;
	; Authenticate and execute
	i $$authentic(.%ENV,port,logLevel) d
	. u socket
	. d exec
	;
	; Termination
	c socket
	d logMessage("Sub-process stopped",2,port)
	q
	
	
	; Start here with a connection
	; HBOM
	; socket handle is passed, attach to device
sub02(port,socket,logLevel)	;
	n device,stop,eof,string,substring,timeout,key,%ENV
	n ucivol,uci,vol,ucivolno,ucino
	;
	; Derive current UCI number
	s ucivol=$zu(0)
	s uci=$p(ucivol,",",1)
	s vol=$p(ucivol,",",2)
	s ucivolno=$zu(uci,vol)
	s ucino=$p(ucivolno,",",1)
	;
	; Top level error handler
	n $et
	s $et="q:0&$zinfo(7,""pvector"",""ucino"","_ucino_")  g error^serverLink"
	;
	s device=9050
	o device:("TCP":""::::socket) ; Attach socket
	i $device'="" d logMessage("Sub-process unable to start on socket #"_socket_" $device="_$device,1,port) c device q
	;
	d logMessage("Sub-process started on socket #"_socket,2,port)
	;
	; Handshake
	s string=$$sub02read(port,socket,device)
	d logMessage("Handshake from client: "_string,2,port)
	i '$$clientVersion(string) d  c device q
	. d logMessage("Handshake rejected from client: "_string,0,port)
	w $$serverVersion,!
	;
	s stop=0
	s eof=0
	f  d  i stop!eof q
	. s string=$$sub02read(port,socket,device)
	. d logMessage(string,2,port)
	. ;
	. i string="%STOP" s stop=1 q
	. i string="%END" s eof=1 q
	. i string="" s eof=1 q  ; Retain for backward compatability (old serverLink.cgi may send null)
	. ;
	. i $e(string,1,5)="%ENV:" d
	. . s key=$p($e(string,6,$l(string)),"=",1)
	. . i key'="" s %ENV(key)=$e(string,6+$l(key)+1,$l(string))
	;
	; Check for stop
	i stop c device q
	;
	; Authenticate and execute
	i $$authentic(.%ENV,port,logLevel) d
	. u device
	. d exec
	;
	; Termination
	c device
	d logMessage("Sub-process stopped",2,port)
	q
	
	
	; Read $c(10) terminated string from socket
sub02read(port,socket,device)	;
	n string,stop,eor,substring,timeout
	s string=""
	s stop=0
	s eor=0
	u device:(:::$c(10))
	f  d  i stop!eor q
	. r substring:60 s timeout='$t
	. i $device'="" d logMessage("Error reading from socket #"_socket_" $device="_$device,1,port) s stop=1 q
	. d logMessage("Substring: "_substring,3,port)
	. s string=string_substring
	. i timeout d logMessage("Client timeout, for socket #"_socket,1,port) s stop=1 q 
	. i $key=$c(10) s eor=1 q
	i stop q "%STOP"
	q string
	
	
	; Start here with a connection
	; GT.M
	; socket handle is passed, attach to device
sub03(port,socket,logLevel)	    ;
	n device,stop,eof,string,substring,timeout,key,%ENV
	;
	; Set log level override
	s logLevel=$g(^serverLink("logLevel"),logLevel)
	;
	; Top level error handler
	; Need to check for quotes in $zroutines!!
	n $zt
	s $zt="s $zroutines="""_$zroutines_""" d error^serverLink zgoto "_($zlevel-1)
	;
	; Attach to socket
	s device="|TCP|"_port
	;
	d logMessage("Sub-process started on socket #"_socket,2,port)
	;
	; Handshake
	s string=$$sub03rea(port,socket,device)
	d logMessage("Handshake from client: "_string,2,port)
	i '$$clientVersion(string) d  c device q
	. d logMessage("Handshake rejected from client: "_string,0,port)
	w $$serverVersion,!
	;
	s payload=0
	k ^serverLink("payload",$j)
	;
	s stop=0
	s eof=0
	f  d  i stop!eof q
	. s string=$$sub03rea(port,socket,device)
	. d logMessage(string,2,port)
	. ;
	. i string="%STOP" s stop=1 q
	. i string="%END" s eof=1 q
	. ;
	. i $e(string,1,5)="%ENV:" d
	. . s key=$p($e(string,6,$l(string)),"=",1)
	. . s string=$e(string,6+$l(key)+1,$l(string))
	. . i key'="" s %ENV(key)=string
	. . i key="PAYLOAD"!(key="POST_DATA") s payload=1,seq=0
	. . e  s payload=0
	. i payload d
	. . s seq=seq+1
	. . s ^serverLink("payload",$j,seq)=string
	. ;
	;
	; Check for stop
	i stop c device q
	;
	; Authenticate and execute
	i $$authentic(.%ENV,port,logLevel) d
	. u device
	. d exec
	;
	; Termination
	c device
	;k ^serverLink("payload",$j)
	d logMessage("Sub-process stopped",2,port)
	q
	
	
	; Read $c(10) terminated string from socket
sub03rea(port,socket,device)	   ;
	n string,stop,eor,substring,timeout
	s string=""
	s stop=0
	s eor=0
	u device:(SOCKET=socket)
	f  d  i stop!eor q
	. r substring:60 s timeout='$t
	. i $device'=0 d logMessage("Error reading from socket #"_socket_" $device="_$device,1,port) s stop=1 q
	. d logMessage("Substring: "_substring,3,port)
	. s string=string_substring
	. i timeout d logMessage("Client timeout, for socket #"_socket,1,port) s stop=1 q
	. i $key=$c(10) s eor=1 q
	i stop q "%STOP"
	q string
	
	
	; Execute script
exec	;
	n requestUri,scriptName,mRoutine
	;
	i $d(^serverLink("REST")) s mRoutine=^serverLink("REST")
	e  d
	. ; Apache Server
	. s requestUri=$g(%ENV("REQUEST_URI"))
	. ;
	. ; Microsoft IIS or PWS
	. i requestUri="" s requestUri=$g(%ENV("SCRIPT_NAME"))_"?"_$g(%ENV("QUERY_STRING"))
	. ;
	. d logMessage("RequestUri="_requestUri,1,port)
	. d logMessage("PostData="_$g(%ENV("POST_DATA")),1,port)
	. s scriptName=$p(requestUri,"?",1)
	. s mRoutine=$p($p(scriptName,"/",$l(scriptName,"/")),".",1) ; Can use any file extension
	. i $e(mRoutine,1,4)="nph-" s mRoutine=$e(mRoutine,5,999) ; Strip non-parsed header prefix
	;
	; Unless it is a percent routine then execute it
	i mRoutine'="",$e(mRoutine,1)'="%" d
	. i mRoutine'?1.AN.1".".AN Q  ;; L2021 security fix - only allow AN with possibly one "."
	. n (mRoutine,%ENV)
	. i $g(%ENV("REMOTE_ADDR"))'="",$G(^serverLink("Serenji",%ENV("REMOTE_ADDR"))),'$$DEBUG^%Serenji("^"_mRoutine,%ENV("REMOTE_ADDR")) q
	. d @("^"_mRoutine)
	;
	q
	
	
	; Authenticate that the request has come from a trusted source.
	; If the pass-phrase matches then ok, otherwise log error.
	; Allow multiple pass-phrases so that multiple different servers can connect etc.
	; Authentication string restricted to 60 text characters to prevent <MXSTR> or <SUBSCR> type errors
	; which may be attempts to breach security.
authentic(%ENV,port,logLevel)	;
	n auth
	s auth=$g(%ENV("GJS_SERVERLINK_AUTH"))
	i auth?1.60anp,$d(^serverLink("GJS_SERVERLINK_AUTH",auth)) d  q 1
	. d logMessage("Authenticated connection from: "_^serverLink("GJS_SERVERLINK_AUTH",auth),2,port)
	. k %ENV("GJS_SERVERLINK_AUTH") ; Delete pass-phrase to reduce window of opportunity
	d logMessage("Unauthenticated web-server: "_auth,0,port)
	q 0
	
	
	; Check whether a stop signal has been sent
checkStop()	;
	q $d(^serverLink("stop"))'=0
	
	
	; Log a message (to the console for now)
logMessage(string,importance,port)	;
	i $d(logLevel),importance>logLevel q
	s ^serverLink("log",port)=$g(^serverLink("log",port))+1
	s ^serverLink("log",port,^serverLink("log",port))=$h_" "_$j_" "_string
	q
	
	
	; Method to set the stop flag
setStop(port)	;
	s ^serverLink("stop")=1
	q
	
	
	; Error handler
error	n error
	;
	s error=$ze
	i $zv["GT.M" s error=$zstatus
	;
	i $zv["Cache" s $ec=""
	i $zv["HBOM" s $ec=""
	i $zv["M21" s $ec=""
	;
	s $ze=""
	; s $zt="bigError"
	;
	; Log all errors
	d logMessage("Error: "_error,0,$g(port,"<undef>"))
	;
	; If development/debug then dump the error to the user
	i '$d(^serverLink("debug")) q
	;
	d header^http
	;
	w "<html>",!
	w "<br>",!
	w $$htmlEscape(error),!
	w "<br>",!
	d int^symbolTable
	;
	w "</html>",!
	q
	
	
	; Error handling an error
bigError	n bigError
	s bigError=$ze
	i $zv["GT.M" s error=$zstatus
	;
	i $zv["Cache" s $ec=""
	i $zv["HBOM" s $ec=""
	i $zv["M21" s $ec=""
	;
	s $ze=""
	s $zt=""
	;
	d logMessage("Big error "_bigError_" handling error "_$g(error),0,$g(port,"<undef>"))
	q
	
	
htmlEscape(string)	;
	s string=$$substitute(string,"&","&amp;")
	s string=$$substitute(string,"<","&lt;")
	s string=$$substitute(string,">","&gt;")
	q string
	
	
substitute(string,replace,with)	;
	f  q:string'[replace  s string=$p(string,replace,1)_with_$p(string,replace,2,$l(string,replace))
	q string
	
	
	; Acceptable client versions
clientVersion(version)	;
	i version="serverLink.cgi/1.4" q 1
	q 0
	
	
	; Server version
serverVersion()	q "r.serverLink/1.4"
	
	
	; Setup Pass-phrase for server access
setup	;
	n auth,desc,newDesc
	w !,"Configure authenticated web-servers"
	; 
setup1	w !,"Pass-phrase? " r auth i auth="" q
	i auth="?" d  g setup1
	. w !!,"Pass-phrase",?15,"Description"
	. s auth=""
	. f  d  i auth="" q
	. . s auth=$o(^serverLink("GJS_SERVERLINK_AUTH",auth)) i auth="" q
	. . w !,"***",?15,^serverLink("GJS_SERVERLINK_AUTH",auth)
	i auth'?1.60anp w "  invalid" g setup1
	s desc=$g(^serverLink("GJS_SERVERLINK_AUTH",auth))
	w !,"Web-server description "
	i desc'="" w "<",desc,"> "
	r newDesc
	i newDesc="" s newDesc=desc w newDesc
	i newDesc'=" " s ^serverLink("GJS_SERVERLINK_AUTH",auth)=newDesc
	e  k ^serverLink("GJS_SERVERLINK_AUTH",auth) w " deleted"
	g setup1
	
	
	; Enable Serenji hook for serverLink requests coming from a browser at
	; a specified IP address. Default is same address as my interactive login
debugOn(addr)	;
	i $g(addr)="" s addr=$$IAM^%Serenji
	q:addr=""
	s ^serverLink("Serenji",addr)=1
	q
	
	
	; Disable Serenji hook for serverLink requests coming from a browser at
	; a specified IP address. Default is same address as my interactive login
debugOff(addr)	;
	i $g(addr)="" s addr=$$IAM^%Serenji
	q:addr=""
	k ^serverLink("Serenji",addr)
	q
	
