LoadDiff	; Load planet diff file with fully indexed tags
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
	
	
	
run	; Public ; Run loadDiff
	;
	l +^loadDiff("running"):0 e  q
	k ^loadDiff("stop")
	f  i '$$file() q:$g(^loadDiff("stop"))=1  h 30
	l -^loadDiff("running")
	q
	
	
stop	; Public ; Stop loadDiff
	s ^loadDiff("stop")=1
	q
	
	
file()	; Public ; Get the next file and process it
	;
	n dateTime,hDateTime1,hDateTime2,dateTime1,dateTime2,filegz,file
	n sFile
	;
	s lastFile=^loadDiff("lastFile")
	;
	; Increment file name
	s nextFile=lastFile
	s nextFile=$e(1000000000+lastFile+1,2,10)
	s file=$e(nextFile,7,9)_".osc"
	s filegz=file_".gz"
	s state=$e(nextFile,7,9)_".state.txt"
	zsystem "rm -f "_filegz
	zsystem "rm -f "_file
	zsystem "rm -f "_state
	;
	s stateUrl=^loadDiff("url")_$e(nextFile,1,3)_"/"_$e(nextFile,4,6)_"/"_$e(nextFile,7,9)_".state.txt"
	zsystem "wget "_stateUrl
	o state:(READ:EXCEPTION="g fail"):0 e  q 0 ; File does not exist yet
	u state r header,sequenceNumber,txnMaxQueried,timestamp
	c state
	;
	s timestamp=$tr($p(timestamp,"=",2),"\","")
	;
	s fileUrl=^loadDiff("url")_$e(nextFile,1,3)_"/"_$e(nextFile,4,6)_"/"_$e(nextFile,7,9)_".osc.gz"
	zsystem "wget "_fileUrl
	;
	zsystem "gunzip "_filegz
	;
	; ====== TRANSACTION START =================================================================================
	; tstart *
	; i $trestart u 0 w !,"restart",!
	c file ; If this is a restart then the file may already have been opened, so close it to be sure.
	d oneFile(file,.sFile)
	;
	; Only update dateTime after the file has been loaded successfully
	s ^loadDiff("timestamp")=timestamp
	s ^osmPlanet("date")=$tr($e(timestamp,1,10),"-","")
	s ^loadDiff("lastFile")=nextFile
	;
	; tcommit
	; ====== TRANSACTION END ===================================================================================
	;
	; Tidy up
	zsystem "rm "_file
	zsystem "rm "_state
	;
	; Someone wants us to stop
	i $g(^loadDiff("stop"))=1 q 0
	;
	q 1
	
	
fail	; Error handler if file does not exist
	q 0
	
	
setup	; Public ; Setup loadDiff
	;
	n url,startDate,in
	;
	s url=$g(^loadDiff("url")) i url="" s url="http://ftp.heanet.ie/mirrors/openstreetmap.org/minute/"
	s startDate=$g(^loadDiff("dateTime"))
	;
setup10	;
	w !,"URL? <",url,"> " r in i in="" s in=url w in
	i in="" w " Eh?" g setup10
	s url=in
	;
setup20	;
	w !,"Start date/time ccyymmddhhmm? "
	i startDate'="" w "<",startDate,"> "
	r in i in="" s in=startDate w in
	i in'?12n w " Eh?" g setup20
	s startDate=in
	;
	s ^loadDiff("url")=url
	s ^loadDiff("dateTime")=startDate
	q
	
	; Strategy:
	; 1) Import everything into the changeset.
	; 2) Process all the relations in the changeset (don't delete a relation if it is in use by some relation that is not in the changeset)
	; 3) Process all ways.  Do not delete ways if they are in use by relations that are not in this changeset)
	; 4) Process all nodes.  Do not delete nodes if they are in use by any ways (unless deleted in this changeset)
	
oneFile(filename,sFile)	      ; Public ; Load data from filename
	;
	n q,ccyymmdd
	n line
	n gNodeDeleteCount,gWayDeleteCount,gNodeModifyCount,gWayModifyCount,gRelDeleteCount,gRelModifyCount,fileId
	;
	s q=""""
	s gNodeDeleteCount=0
	s gWayDeleteCount=0
	s gRelDeleteCount=0
	s gNodeModifyCount=0
	s gWayModifyCount=0
	s gRelModifyCount=0
	;
	s fileId=filename
	k ^loadDiff(fileId)
	s ^loadDiff(fileId,"start")=$h
	s ^loadDiff(fileId,"pid")=$j
	k ^temp($j,"loadDiff")
	;
	;
	; Read the file
	d openFile^stream(.sFile,filename)
	s line=$$read^stream(.sFile) ; prolog
	s line=$$read^stream(.sFile) ; <osm...>
	;
	f  d  i line["</osmChange>" q
	. s line=$$read^stream(.sFile)
	. i sFile("recordCount")#10000=0 d checkpoint
	. i line["<delete" d delete q
	. i line["<modify" d modify q
	. i line["<create" d modify q
	;
	; Apply the changes to the active dataset (assumes all changes in a single diff file are referentially integral)
	; Apply relations first, then ways and then nodes.  In the case of a way deletion it's nodes cannot be deleted
	; until the way has been deleted.  Also OSM may try to delete elements that are still in use in fosm.  In either case
	; the referential integrity checks will prevent the node from being deleted.
	; Why apply backwards?  Nodes first surely?  
	; d apply^relation(fileId)
	; d apply^way(fileId)
	d applyNodes
	d applyWays
	;
	s ^loadDiff(fileId,"end")=$h
	s ^loadDiff(fileId,"totalLines")=sFile("recordCount")
	s ^loadDiff(fileId,"totalNodesDelete")=gNodeDeleteCount
	s ^loadDiff(fileId,"totalWaysDeleted")=gWayDeleteCount
	s ^loadDiff(fileId,"totalRelationsDeleted")=gRelDeleteCount
	s ^loadDiff(fileId,"totalNodesModified")=gNodeModifyCount
	s ^loadDiff(fileId,"totalWaysModified")=gWayModifyCount
	s ^loadDiff(fileId,"totalRelationsModified")=gRelModifyCount
	s ^loadDiff(fileId,"duration")=$p(^loadDiff(fileId,"end"),",",2)-$p(^loadDiff(fileId,"start"),",",2)
	;
	d close^stream(.sFile)
	q
	
	
applyNodes	; Apply node changes in this file to the active database
	;
	n nodeId,a,version,changeset,uid,visible
	n fork
	n currentVersion,currentChangeset,currentA,currentUid,blockedByUid
	;
	s nodeId=""
	f  d  i nodeId="" q
	. s nodeId=$o(^temp($j,"loadDiff","n",nodeId)) i nodeId="" q
	. s a=^temp($j,"loadDiff","n",nodeId,"a")
	. s version=$p(a,$c(1),1)
	. s changeset=$p(a,$c(1),2)
	. s uid=$p(a,$c(1),4)
	. s visible=$p(a,$c(1),5)
	. s currentVersion=$$currentVersion^node(nodeId)
	. ;
	. ; Is the user blocked
	. i uid'="",$g(^user(uid,"osmImport"))="block" d  q
	. . s blockedByUid=$g(^user(uid,"blockedByUid"),uid)
	. . d log^conflict("node",nodeId,blockedByUid,a,"User #"_uid_" ("_$g(^user(uid,"name"),"unknown")_") blocked by "_blockedByUid) q
	. ;
	. ; Don't load older versions
	. i currentVersion>version q
	. ;
	. s quit=0
	. i currentVersion'="" d  i quit q  ; In a test database many nodes will be missing
	. . s currentChangesetId=^nodeVersion(nodeId,"v",currentVersion)
	. . s currentA=$g(^c(currentChangesetId,"n",nodeId,"v",currentVersion,"a")) i currentA="" q
	. . s currentUid=$p(currentA,$c(1),4)
	. . s fork=$p(currentA,$c(1),6)
	. . ;
	. . ; Has the element been forked
	. . ; Log conflict against user who edited in fosm
	. . i fork d  s quit=1 q
	. . . d log^conflict("node",nodeId,currentUid,a,"Edited in fosm")
	. . ;
	. . ; If the node is to be deleted, but the last editor has requested deletions to be preserved (eg because they are a ct_decliner)
	. . ; then do not apply the change.
	. . i visible="false",currentUid'="",$g(^user(currentUid,"osmImport"))="doNotDelete" d  s quit=1 q
	. . . s blockedByUid=$g(^user(currentUid,"blockedByUid"),currentUid)
	. . . d log^conflict("node",nodeId,blockedByUid,a,"Deletion of element belonging to #"_currentUid_" ("_$g(^user(currentUid,"name"),"unknown")_") preserved.  Do not delete requested by user #"_blockedByUid)
	. ;
	. ; If the node is to be deleted, but is still in-use then don't delete it.  Instead add it to the conflict file
	. ; for manual inspection
	. i visible="false",$d(^wayByNode(nodeId)) d log^conflict("node",nodeId,uid,a,"Deleted in OSM but still in use in fosm") q
	. ;
	. d addNodeFromChangeset^node(changeset,nodeId,version)
	q
	
	
applyWays	; Apply way changes in this file to the active database
	;
	n nodeId,a,version,changeset,uid,visible
	n fork
	n currentVersion,currentChangeset,currentA,currentUid,blockedByUid
	;
	s wayId=""
	f  d  i wayId="" q
	. s wayId=$o(^temp($j,"loadDiff","w",wayId)) i wayId="" q
	. s a=^temp($j,"loadDiff","w",wayId,"a")
	. s version=$p(a,$c(1),1)
	. s changeset=$p(a,$c(1),2)
	. s uid=$p(a,$c(1),4)
	. s visible=$p(a,$c(1),5)
	. s currentVersion=$$currentVersion^way(wayId)
	. ;
	. ; Is the user blocked
	. i uid'="",$g(^user(uid,"osmImport"))="block" d  q
	. . s blockedByUid=$g(^user(uid,"blockedByUid"),uid)
	. . d log^conflict("way",wayId,blockedByUid,a,"User #"_uid_" ("_$g(^user(uid,"name"),"unknown")_") blocked by "_blockedByUid) q
	. ;
	. ; Don't load older versions
	. i currentVersion>version q
	. ;
	. s quit=0
	. i currentVersion'="" d  i quit q  ; In a test database many ways will be missing
	. . s currentChangesetId=$g(^wayVersion(wayId,"v",currentVersion))
	. . i currentChangesetId="" s currentChangesetId=^waytag(wayId,"@changeset")
	. . s currentUid=$g(^c(currentChangesetId,"w",wayId,"v",currentVersion,"t","@uid"))
	. . s fork=$g(^c(currentChangesetId,"w",wayId,"v",currentVersion,"t","@fork"))
	. . ;
	. . ; Has the element been forked
	. . ; Log conflict against user who edited in fosm
	. . i fork d  s quit=1 q
	. . . d log^conflict("way",wayId,currentUid,a,"Edited in fosm")
	. . ;
	. . ; If the way is to be deleted, but the last editor has requested deletions to be preserved (eg because they are a ct_decliner)
	. . ; then do not apply the change.
	. . i visible="false",currentUid'="",$g(^user(currentUid,"osmImport"))="doNotDelete" d  s quit=1 q
	. . . s blockedByUid=$g(^user(currentUid,"blockedByUid"),currentUid)
	. . . d log^conflict("way",wayId,blockedByUid,a,"Deletion of element belonging to #"_currentUid_" ("_$g(^user(currentUid,"name"),"unknown")_") preserved.  Do not delete requested by user #"_blockedByUid)
	. ;
	. d addWayFromChangeset^way(changeset,wayId,version)
	q
	
	
	
delete	 ; Delete some stuff, read all lines until end of delete element
	f  d  i line["</delete>" q
	. s line=$$read^stream(.sFile)
	. i sFile("recordCount")#10000=0 d checkpoint
	. i line["<node" s gNodeDeleteCount=gNodeDeleteCount+1 d import^node(.sFile,1) q
	. i line["<way" s gWayDeleteCount=gWayDeleteCount+1 d import^way(.sFile,1) q
	. i line["<relation" s gRelDeleteCount=gRelDeleteCount+1 d add^relation(.sFile,1) q
	;
	q
	
	
modify	 ; Create or modify stuff, read all lines until end of modify or create element
	f  d  i (line["</modify>")!(line["</create>") q
	. s line=$$read^stream(.sFile)
	. i sFile("recordCount")#10000=0 d checkpoint
	. i line["<node" s gNodeModifyCount=gNodeModifyCount+1 d import^node(.sFile,0) q
	. i line["<way" s gWayModifyCount=gWayModifyCount+1 d import^way(.sFile,0) q
	. i line["<relation" s gRelModifyCount=gRelModifyCount+1 d add^relation(.sFile,0) q
	;
	q
	
	
checkpoint	     ; Private ; Update checkpoint
	;
	s ^loadDiff(fileId,"currentLineCount")=sFile("recordCount")
	s ^loadDiff(fileId,"currentNodeDeleteCount")=gNodeDeleteCount
	s ^loadDiff(fileId,"currentWayDeleteCount")=gWayDeleteCount
	s ^loadDiff(fileId,"currentRelDeleteCount")=gRelDeleteCount
	s ^loadDiff(fileId,"currentNodeModifyCount")=gNodeModifyCount
	s ^loadDiff(fileId,"currentWayModifyCount")=gWayModifyCount
	s ^loadDiff(fileId,"currentRelModifyCount")=gRelModifyCount
	q
