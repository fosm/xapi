status	 ; XAPI Server Status
	; This program is free software: you can redistribute it and/or modify
	; Copyright (C) 2009  Etienne Cherdlu <80n80n@gmail.com>
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
	
	
	; Quasi mapReduce stuff
	d map^mapReduce("status")
	d reduce^mapReduce("status")
	;
	d header^http("text/html")
	;
	w "<html>",!
	w "<head>",!
	w "<title>XAPI Status for ",^osmPlanet("instance"),"</title>",!
	w "<meta http-equiv='Refresh' content='60; URL=' />"
	w "<style>",!
	w "table{border-collapse:collapse;}",!
	w ".page{font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#6b6d72; line-height:normal; text-align:left;}",!
	w ".table{font-size:105%; border-style:solid; border-width:1px; border-color:#b8c3cc; margin:10px; background-color:#FFFFFF;}",!
	w "td{padding-left: 3px; padding-right: 3px; padding-top: 2px; padding-bottom: 2px;}",!
	w ".title{font-family:Arial,Helvetica,sans-serif; color:#003c66; font-weight:bold; font-style:italic; font-size:105%; background-image:url(/images/blue_gradient.gif); background-color:#eff6fa; background-repeat:repeat-x; padding:2px; border-bottom:#b8c3cc 1px solid;}",!
	w ".white{background-color:#FFFFFF; border-left:1px solid #a1aab3; border-right:1px solid #a1aab3; border-bottom:1px solid #bdc3ce; }",!
	w ".blue{background-color:#ebf7ff; border-left:1px solid #a1aab3; border-right:1px solid #a1aab3; border-bottom:1px solid #bdc3ce; }",!
	w ".red{background-color:pink; border-left:1px solid #a1aab3; border-right:1px solid #a1aab3; border-bottom:1px solid #bdc3ce; }",!
	w ".grey{background-color:#eeeeee; border-left:1px solid #a1aab3; border-right:1px solid #a1aab3; border-bottom:1px solid #bdc3ce; }",!
	w "</style>",!
	
	w "<head>",!
	w "<body>",!
	;
	w "<div class='page'>",!
	w "<table border='1' class='table'>",!
	;
	; Summary table header
	w "<tr>",!
	w "<td class='title'>Summary</td>",!
	s instance=""
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"logId")) q
	. w "<td class='title'>",instance,"</td>",!
	w "</tr>",!
	;
	; Generate row for total requests
	w "<tr>",!
	w "<td>Total requests:</td>",!
	s instance=""
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"logId")) q
	. w "<td align='right'>",$fn($g(^status("server",instance,"logId")),","),"</td>",!
	w "</tr>",!
	;
	; Generate row for average response time
	w "<tr>",!
	w "<td>Average response time:</td>",!
	s instance=""
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"logId")) q
	. s responseTime=$g(^status("server",instance,"munin","responseTotal"),1)/$g(^status("server",instance,"munin","apiCalls"),1)
	. w "<td align='right'>",$j(responseTime,0,2),"</td>",!
	w "</tr>",!
	;
	; Generate row for active requests across all servers
	w "<tr>",!
	w "<td>Active requests:</td>",!
	s instance=""
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"logId")) q
	. w "<td align='right'>",^status("server",instance,"activeProcesses"),"/",^status("server",instance,"totalProcesses"),"</td>",!
	w "</tr>",!
	;
	w "</table>",!
	w "</div>",!
	;
	; Recent and active requests
	d active
	;
	; Import table
	w "<div class='page'>",!
	w "<table border='1' class='table'>",!
	;
	; Summary table header
	w "<tr>",!
	w "<td class='title'>Data import</td>",!
	s instance=""
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"loadDiff")) q
	. w "<td class='title'>",instance,"</td>",!
	w "</tr>",!
	;
	; Generate row for source
	; w "<tr>",!
	; w "<td>Source</td>",!
	; s instance=""
	; f  d  i instance="" q
	; . s instance=$o(^status("loadDiff",instance)) i instance="" q
	; . w "<td> ",$g(^status("loadDiff",instance,"url"))," </td>",!
	; w "</tr>",!
	;
	; Generate row for last File
	w "<tr>",!
	w "<td>Last file</td>",!
	s instance=""
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"loadDiff")) q
	. s lastFile=$g(^status("server",instance,"loadDiff","lastFile"),"000000000")
	. w "<td> ",$e(lastFile,1,3),"/",$e(lastFile,4,6),"/",$e(lastFile,7,9),".osc"," </td>",!
	w "</tr>",!
	;
	; Generate row for diff timestamp
	w "<tr>",!
	w "<td>Timestamp</td>",!
	s instance=""
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"loadDiff")) q
	. w "<td> ",$g(^status("server",instance,"loadDiff","timestamp"))," </td>",!
	w "</tr>",!
	;
	w "<tr>",!
	w "<td>Average file length</td>",!
	s instance=""
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"loadDiff")) q
	. s files=^status("server",instance,"loadDiff","files")
	. s lines=^status("server",instance,"loadDiff","lines")/files
	. w "<td align='right'>",$j(lines,0,0)," lines","</td>",!
	w "</tr>",!
	;
	w "<tr>",!
	w "<td>Average updates per file</td>",!
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"loadDiff")) q
	. s files=^status("server",instance,"loadDiff","files")
	. s modified=^status("server",instance,"loadDiff","modified")/files
	. w "<td align='right'>",$j(modified,0,0)," elements</td>",!
	w "</tr>",!
	;
	w "<tr>",!
	w "<td>Average deletions per file</td>",!
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"loadDiff")) q
	. s files=^status("server",instance,"loadDiff","files")
	. s deleted=^status("server",instance,"loadDiff","deleted")/files
	. w "<td align='right'>",$j(deleted,0,0)," elements</td>",!
	w "</tr>",!
	;
	w "<tr>",!
	w "<td>Average processing time</td>",!
	f  d  i instance="" q
	. s instance=$o(^status("server",instance)) i instance="" q
	. i '$d(^status("server",instance,"loadDiff")) q
	. s files=^status("server",instance,"loadDiff","files")
	. s duration=^status("server",instance,"loadDiff","duration")/files
	. w "<td align='right'>",$$minutes(duration),"</td>",!
	w "</tr>",!
	;
	w "</table>",!
	w "</div>",!
	;
	d userAgentByRequest
	d userAgentBySize
	;
	w "</body>",!
	w "</html>",!
	q
	
	
loadCounts(count)	; Private ; Get diff load counts for the last 100 files
	;
	n lines,delete,modify,files,duration
	n file
	;
	s duration=0
	s delete=0
	s modify=0
	s lines=0
	s files=0
	;
	k count
	s count("duration")=0
	s count("deleted")=0
	s count("modified")=0
	s count("lines")=0
	s count("files")=0
	;
	s file=""
	f  d  i file="" q
	. s file=$o(^loadDiff(file)) i file="" q
	. i file'?.e1".osc" q
	. s files=files+1
	. s lines=lines+$g(^loadDiff(file,"totalLines"))
	. s modify=modify+$g(^loadDiff(file,"totalNodesModified"))
	. s modify=modify+$g(^loadDiff(file,"totalWaysModified"))
	. s modify=modify+$g(^loadDiff(file,"totalRelationsModified"))
	. s delete=delete+$g(^loadDiff(file,"totalNodesDelete"))
	. s delete=delete+$g(^loadDiff(file,"totalWaysDeleted"))
	. s delete=delete+$g(^loadDiff(file,"totalRelationsDeleted"))
	. i $g(^loadDiff(file,"duration"))>0 s duration=duration+$g(^loadDiff(file,"duration")) ; Skip negative durations
	;
	; Counts
	s count("duration")=duration
	s count("deleted")=delete
	s count("modified")=modify
	s count("lines")=lines
	s count("files")=files
	q
	
	
active	; Current active requests
	;
	n sAge,logId,count
	;
	w "<div class='page'>",!
	w "<table class='table'>",!
	w "<tr>",!
	w "<td class='title'>Age</td>",!
	w "<td class='title'>Server</td>",!
	w "<td class='title'>LogId</td>",!
	w "<td class='title'>pid</td>",!
	w "<td class='title'>Query</td>",!
	w "<td class='title'>User Agent</td>",!
	w "<td class='title'>Extent</td>",!
	w "<td class='title'>Time</td>",!
	w "<td class='title'>Elements</td>",!
	;
	s count=0
	;
	s sAge=""
	f  d  i sAge="" q
	. s sAge=$o(^status("log",sAge)) i sAge="" q
	. s logId=""
	. f  d  i logId="" q
	. . s logId=$o(^status("log",sAge,logId)) i logId="" q
	. . s ps=$g(^status("log",sAge,logId,"ps"))
	. . s count=count+1
	. . i (ps'="")!(count<999) d displayTask(sAge,logId)
	;
	w "</table>",!
	w "</div>",!
	q
	
	
displayTask(sAge,logId)	;
	;
	n hNow,sNow,query,start,age,pid,age,extent,userAgent,count,colour,title
	;
	;
	s instance=$g(^status("log",sAge,logId,"instance"))
	;
	s hNow=$g(^status("server",instance,"now"))
	s sNow=$p(hNow,",",1)*86400+$p(hNow,",",2)
	;
	s query=$g(^status("log",sAge,logId,"request"))
	s start=$g(^status("log",sAge,logId,"start")) s start=$p(start,",",1)*86400+$p(start,",",2)
	s age=$$minutes(sNow-start)
	s end=$g(^status("log",sAge,logId,"end"),hNow) s end=$p(end,",",1)*86400+$p(end,",",2)
	s pid=$g(^status("log",sAge,logId,"pid"))
	s ps=$g(^status("log",sAge,logId,"ps"))
	s time=$$minutes(end-start)
	s extent=17-$l($g(^status("log",sAge,logId,"qs"))) i extent=17 s extent=0
	s userAgent=$g(^status("log",sAge,logId,"userAgent"))
	s count=$g(^status("log",sAge,logId,"count"),0)
	;
	s colour="white",title=""
	i ps'="" s colour="blue",title=ps
	w "<tr title='"_title_"'>",!
	w "<td align='right' class='"_colour_"'>",$$minutes(sAge),"</td>",!
	w "<td align='right' class='"_colour_"'>",instance,"</td>",!
	w "<td align='right' class='"_colour_"'>",logId,"</td>",!
	w "<td align='right' class='"_colour_"'>",pid,"</td>",!
	w "<td class='"_colour_"'>",query,"</td>",!
	w "<td class='"_colour_"'>",userAgent,"</td>",!
	w "<td align='right' class='"_colour_"'>",extent,"</td>",!
	w "<td align='right' class='"_colour_"'>",time,"</td>",!
	w "<td align='right' class='"_colour_"'>",count,"</td>",!
	w "</tr>",!
	;
	q
	
minutes(seconds)	; Convert seconds to minutes
	q (seconds)\60_":"_$e(100+((seconds)#60),2,3)
	
	
processes(ps)	; Get status of zappy processes
	;
	n temp,i,line,pid,io
	;
	k ps
	s ps=0
	s io=$i
	;
	s temp="/tmp/xapi_status"_$j_".tmp"
	zsystem "ps -Al|grep "_^osmPlanet("instance")_" >"_temp
	;
	o temp:READ
	s $zt="g eof"
	f i=1:1 u temp r line s pid=$tr($e(line,10,15)," ","") i pid'="" s ps(pid)=line,ps=ps+1
eof	s $zt="",$ze="" c temp
	;
	zsystem "rm "_temp
	u io
	q
	
	
userAgentByRequest	; Display UserAgents by Requests
	;
	n active,r,logId
	s global="^%logStats"
	;
	w "<div class='page'>",!
	w "<table border='1' class='table'>",!
	w "<tr>",!
	w "<td class='title'>User Agent</td>",!
	w "<td class='title'>Requests</td>",!
	w "<td class='title'>Average size</td>",!
	w "<td class='title'>Extent</td>",!
	w "<td class='title'>Response time</td>",!
	;
	; Iterate the user agents by log frequency
	s log=""
	f  d  i log="" q
	. s log=$o(^status("byLog",log),-1) i log="" q
	. i log<100 s log="" q
	. s agent=""
	. f  d  i agent="" q
	. . s agent=$o(^status("byLog",log,agent)) i agent="" q
	. . s count=^status("byAgent",agent,"count")
	. . s qsl=^status("byAgent",agent,"qsl")
	. . s duration=^status("byAgent",agent,"duration")
	. . s title="Sample request: "_$g(^status("byAgent",agent,"sampleRequest"))_" Sample UserAgent: "_$g(^status("byAgent",agent,"sampleUserAgent"))
	. . w "<tr title='"_title_"'>",!
	. . i $d(^userAgent(agent,"url")) w "<td><a href='"_^userAgent(agent,"url")_"'>",agent,"</a></td>",!
	. . e  w "<td>",agent,"</td>",!
	. . w "<td align='right'>",$fn(log,","),"</td>",!
	. . w "<td align='right'>",$fn(count/log,",",0),"</td>",!
	. . w "<td align='right'>",$fn(qsl/log*6.25,",",2),"%</td>",!
	. . w "<td align='right'>",$fn(duration/log,",",2),"</td>",!
	. . w "</tr>",!
	;
	w "</table>",!
	w "</div>",!
	q
	
	
userAgentBySize	; Display UserAgents by Size of request
	;
	n active,r,logId
	s instance=^osmPlanet("instance")
	;
	w "<div class='page'>",!
	w "<table border='1' class='table'>",!
	w "<tr>",!
	w "<td class='title'>User Agent</td>",!
	w "<td class='title'>Size</td>",!
	w "<td class='title'>Requests</td>",!
	;
	; Iterate the user agents by size
	s count=""
	f  d  i count="" q
	. s count=$o(^status("byCount",count),-1) i count="" q
	. i count<1000 s count="" q
	. s agent=""
	. f  d  i agent="" q
	. . s agent=$o(^status("byCount",count,agent)) i agent="" q
	. . s log=^status("byAgent",agent,"log")
	. . s title="Sample request: "_$g(^status("byAgent",agent,"sampleRequest"))_" Sample UserAgent: "_$g(^status("byAgent",agent,"sampleUserAgent"))
	. . w "<tr title='"_title_"'>",!
	. . i $d(^userAgent(agent,"url")) w "<td><a href='"_^userAgent(agent,"url")_"'>",agent,"</a></td>",!
	. . e  w "<td>",agent,"</td>",!
	. . w "<td align='right'>",$fn(count,","),"</td>",!
	. . w "<td align='right'>",$fn(log,","),"</td>",!
	. . w "</tr>",!
	;
	w "</table>",!
	w "</div>",!
	q
	
	
mapReduce	;
	d map^mapReduce("status")
	d reduce^mapReduce("status")
	q
	
	
mapInit	q
	
	
mapFinal	q
	
	
mapMain	; Build table of current active requests
	;
	n active,activeProcesses,request,logId,ps,count
	;
	s global="^%status"_^osmPlanet("instance")
	s @global@("now")=$h
	;
	; Get array of active processes
	d processes(.ps)
	;
	k @global@("log")
	;
	; Create array of active tasks sorted by logId
	; As a by product, delete any dead tasks
	s activeProcesses=0
	s request=""
	f  d  i request="" q
	. s request=$o(^requestx(request)) i request="" q
	. s logId=""
	. f  d  i logId="" q
	. . s logId=$o(^requestx(request,logId)) i logId="" q
	. . s pid=^log(logId,"pid")
	. . i '$d(ps(pid)) k ^requestx(request,logId) q
	. . s active(logId)=""
	;
	; Add most recent tasks to table
	s logId=""
	f i=1:1:10 d  i logId="" q
	. s logId=$o(^log(logId),-1) i logId="" q
	. s pid=$g(^log(logId,"pid"))
	. m @global@("log",logId)=^log(logId)
	. i $d(ps(pid)) s @global@("log",logId,"ps")=ps(pid),activeProcesses=activeProcesses+1
	. k active(logId)
	;
	; Add any remaining active tasks to table
	f  d  i logId="" q
	. s logId=$o(active(logId),-1) i logId="" q
	. s pid=$g(^log(logId,"pid"))
	. s request=$g(^log(logId,"request"))
	. m @global@("log",logId)=^log(logId)
	. i $d(ps(pid)) s @global@("log",logId,"ps")=ps(pid),activeProcesses=activeProcesses+1
	;
	; Logfile stats
	i $d(^log) d
	. s @global@("activeProcesses")=activeProcesses
	. s @global@("totalProcesses")=ps
	. s @global@("logId")=$g(^log)
	. m @global@("munin")=^munin
	;
	i $d(^loadDiff) d
	. s @global@("loadDiff","url")=$g(^loadDiff("url"),"None")
	. s @global@("loadDiff","lastFile")=$g(^loadDiff("lastFile"),"000000000")
	. s @global@("loadDiff","timestamp")=$g(^loadDiff("timestamp"),"Never run")
	. ;
	. d loadCounts(.count)
	. m @global@("loadDiff")=count
	;
	q
	
	
userAgentStatistics	; Public ; Build log file ua stats
	;
	k ^tempStatus($j)
	s l=""
	f  d  i l="" q
	. s l=$o(^log(l)) i l="" q
	. s ua=$g(^log(l,"userAgent"))
	. s count=$g(^log(l,"count"))
	. s agent=$p($p(ua," ",1),"/",1) i agent="" s agent="unknown"
	. s duration=$g(^log(l,"duration")) i duration<0 s duration=0
	. s qs=$g(^log(l,"qs"))
	. s qsl=16-$l(qs)
	. s ^tempStatus($j,"byAgent",agent,"log")=$g(^tempStatus($j,"byAgent",agent,"log"))+1
	. s ^tempStatus($j,"byAgent",agent,"count")=$g(^tempStatus($j,"byAgent",agent,"count"))+count
	. s ^tempStatus($j,"byAgent",agent,"qsl")=$g(^tempStatus($j,"byAgent",agent,"qsl"))+qsl
	. s ^tempStatus($j,"byAgent",agent,"duration")=$g(^tempStatus($j,"byAgent",agent,"duration"))+duration
	. s ^tempStatus($j,"byAgent",agent,"sampleRequest")=$g(^log(l,"request"))
	. s ^tempStatus($j,"byAgent",agent,"sampleUserAgent")=$g(^log(l,"userAgent"))
	;
	s global="^%status"_^osmPlanet("instance")
	k @global@("byAgent")
	m @global@("byAgent")=^tempStatus($j,"byAgent")
	q
	
	
reduceInit	; Public ; Initialize log file reduction
	;
	k ^status
	;
	q
	
	
reduceMain(key,global)	; Public ; Reduce a log file
	;
	n hNow,sNow,agent,logId,hStart,sStart,sAge
	;
	; Make all the unreduced data available
	m ^status("server",key)=@global
	;
	; hNow is the time on the originating server.  Servers will be in various timezones, and their clocks may be out by a bit,
	; so always measure time relative to hNow on the originating server.
	s hNow=@global@("now")
	s sNow=$p(hNow,",",1)*86400+$p(hNow,",",2)
	;
	; Consolidate each instance of log stats into a single log stats file
	s agent=""
	f  d  i agent="" q
	. s agent=$o(@global@("byAgent",agent)) i agent="" q
	. s ^status("byAgent",agent,"count")=$g(^status("byAgent",agent,"count"))+@global@("byAgent",agent,"count")
	. s ^status("byAgent",agent,"duration")=$g(^status("byAgent",agent,"duration"))+@global@("byAgent",agent,"duration")
	. s ^status("byAgent",agent,"log")=$g(^status("byAgent",agent,"log"))+@global@("byAgent",agent,"log")
	. s ^status("byAgent",agent,"qsl")=$g(^status("byAgent",agent,"qsl"))+@global@("byAgent",agent,"qsl")
	. s ^status("byAgent",agent,"sampleRequest")=@global@("byAgent",agent,"sampleRequest")
	. s ^status("byAgent",agent,"sampleUserAgent")=@global@("byAgent",agent,"sampleUserAgent")
	;
	; Sort active log entries by age
	s logId=""
	f  d  i logId="" q
	. s logId=$o(@global@("log",logId)) i logId="" q
	. s hStart=@global@("log",logId,"start"),sStart=$p(hStart,",",1)*86400+$p(hStart,",",2)
	. s sAge=sNow-sStart
	. m ^status("log",sAge,logId)=@global@("log",logId)
	. s ^status("log",sAge,logId,"instance")=key ; Note which server this log entry came from
	;
	q
	
	
reduceFinal	; Public ; Finalize a log file reduction
	;
	n agent,instance
	n logId,activeProcesses,totalProcesses,apiCalls,responseTotal
	;
	; Build byCount and byLog indexes from byAgent stats
	;
	s agent=""
	f  d  i agent="" q
	. s agent=$o(^status("byAgent",agent)) i agent="" q
	. s log=^status("byAgent",agent,"log")
	. s count=^status("byAgent",agent,"count")
	. s ^status("byCount",count,agent)=""
	. s ^status("byLog",log,agent)=""
	;
	; Create log total (if there is more than one instance)
	s instance=$o(^status("server","")) i $o(^status("server",instance))'="" d
	. ;
	. s logId=0
	. s activeProcesses=0
	. s totalProcesses=0
	. s apiCalls=0
	. s responseTotal=0
	. ;
	. s instance=""
	. f  d  i instance="" q
	. . s instance=$o(^status("server",instance)) i instance="" q
	. . i '$d(^status("server",instance,"logId")) q
	. . s logId=logId+^status("server",instance,"logId")
	. . s activeProcesses=activeProcesses+^status("server",instance,"activeProcesses")
	. . s totalProcesses=totalProcesses+^status("server",instance,"totalProcesses")
	. . s apiCalls=apiCalls+^status("server",instance,"munin","apiCalls")
	. . s responseTotal=responseTotal+^status("server",instance,"munin","responseTotal")
	. ;
	. s ^status("server","Total","logId")=logId
	. s ^status("server","Total","activeProcesses")=activeProcesses
	. s ^status("server","Total","totalProcesses")=totalProcesses
	. s ^status("server","Total","munin","apiCalls")=apiCalls
	. s ^status("server","Total","munin","responseTotal")=responseTotal
	q
