exportDiff	; Export minutely diff
	; Copyright (C) 2010  Etienne Cherdlu <80n80n@gmail.com>
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
	
	
run	; Public ; Run exportDiff
	; Export repeatedly until we catch up with the import or with the current minute
	;
	l +^exportDiff("running"):0 e  q
	k ^exportDiff("stop")
	f  i '$$main() q
	l -^exportDiff("running")
	q


stop	; Public ; Stop exportDiff
	s ^exportDiff("stop")=1
	q
	
	
main()	; Export 
	;
	n iMinute,iEndSecond,hEndSecond,loadDiff,iLoadDiff
	n sequence,iSequence,file,stateFile
	n hSecond
	;
	; Find a minute to process
	s iMinute=$g(^exportDiff("minutelyTimestamp"))
	s iEndSecond=iMinute_"59"
	;
	; Add a few minutes so that we are sure we have got all updates
	s hEndSecond=$$dttih^date(iEndSecond)
	s hEndSecond=$$hAddSeconds^date(hEndSecond,60*5)
	s iEndSecond=$$dtthi^date(hEndSecond)
	;
	; Do not export until the current minute has passed
	i $$toNumber^date($$nowZulu^date())<iEndSecond q 0
	;
	s loadDiff=$g(^loadDiff("timestamp"))
	s iLoadDiff=$$toNumber^date(loadDiff)
	;
	; If the OSM data is not loaded yet, and it can be a few minutes late, then we have to wait for it.
	; i iLoadDiff<iEndSecond q 0
	;	
	; Derive file name
	s sequence=$g(^exportDiff("minutelySequence"),1100000000)
	s sequence=sequence+1
	;
	s iSequence=$e(sequence,2,$l(sequence)) ; Remove 1 prefix
	s file=$$createZipFile(iSequence,iMinute)
	s stateFile=$$createStateFile(iSequence,iMinute)
	;
	; Copy the state file to the root directory
	zsystem "cp "_stateFile_" "_$g(^exportDiff("minutelyDirectory"))_"state.txt"
	;
	; Create some indexes to help with recreating these files if needed
	s ^exportDiff("sequence",iSequence,"minute")=iMinute
	s ^exportDiff("minute",iMinute,"sequence")=iSequence
	;
	; Increment timestamp and sequence
	s hSecond=$$dttih^date(iMinute_"00")
	s hSecond=$$hAddSeconds^date(hSecond,60)
	s iMinute=$e($$dtthi^date(hSecond),1,12)
	s ^exportDiff("minutelyTimestamp")=iMinute
	s ^exportDiff("minutelySequence")=sequence
	;
	; Someone wants us to stop
	i $g(^exportDiff("stop"))=1 q 0
	;
	q 1
	
	
createZipFile(sequence,iMinute)	;
	; Sequence = 111222333 (without the 1 prefix which is stored on file)
	; iMinute = ccyymmddhhmm
	; Returns full name, including path, of file created
	;
	n directory1,directory2,root,file
	;
	s directory1=$g(^exportDiff("minutelyDirectory"))_$e(sequence,1,3)_"/"
	s directory2=$g(^exportDiff("minutelyDirectory"))_$e(sequence,1,3)_"/"_$e(sequence,4,6)_"/"
	s root=directory2_$e(sequence,7,9)
	s file=root_".osc"
	;
	; Create directories if needed (errors to /dev/null if already exists)
	zsystem "mkdir "_directory1_" 2>/dev/null"
	zsystem "mkdir "_directory2_" 2>/dev/null"
	;
	o file:(NEW:STREAM:NOWRAP)
	u file
	;
	; Let's do it
	d xmlProlog^rest("")
	d minute(iMinute)
	c file
	;
	; Now zip the file
	zsystem "rm -f "_file_".gz"
	zsystem "gzip "_file
	;
	q file_".gz"
	
	
createStateFile(sequence,iMinute)	;
	; Sequence = 111222333 (without the 1 prefix which is stored on file)
	; iMinute = ccyymmddhhmm
	; Returns full name, including path, of file created
	;
	n directory1,directory2,root,stateFile
	n timestamp,iEndSecond,zEndSecond,transactionMax
	;
	s directory1=$g(^exportDiff("minutelyDirectory"))_$e(sequence,1,3)_"/"
	s directory2=$g(^exportDiff("minutelyDirectory"))_$e(sequence,1,3)_"/"_$e(sequence,4,6)_"/"
	s root=directory2_$e(sequence,7,9)
	s stateFile=root_".state.txt"
	;
	; Create directories if needed (errors to /dev/null if already exists)
	zsystem "mkdir "_directory1_" 2>/dev/null"
	zsystem "mkdir "_directory2_" 2>/dev/null"
	;
	; Write state file
	o stateFile:NEW
	u stateFile
	s timestamp=$$nowZulu^date()
	s iEndSecond=iMinute_"59"
	s zEndSecond=$$toZulu^date(iEndSecond)
	s transactionMax=iEndSecond-20100101010101_$e(10000+$r(9999),2,5) ; Random garbage
	w "# "_timestamp,!
	w "sequenceNumber=",sequence,!
	w "txnMaxQueried=",transactionMax,!
	w "timestamp=",$p(zEndSecond,":",1)_"\:"_$p(zEndSecond,":",2)_"\:"_$p(zEndSecond,":",3),!
	w "txnReadyList=",!
	w "txnMax=",transactionMax,!
	w "txnActiveList=",!
	c stateFile
	;
	q stateFile
	
	
minute(iMinute)	; Emit all changes for a whole minute
	;
	n mode,iStart,iEnd,start,end,timestamp,iTimestamp
	;
	w "<osmChange"
	w $$attribute^osmXml("version","0.6","")
	w $$attribute^osmXml("generator","fOsmosis 1.0","")
	w ">",$c(13,10)
	;
	s mode=""
	s iStart=iMinute_"00"
	s iEnd=iMinute_"59"
	s start=$$toZulu^date(iStart)
	s end=$$toZulu^date(iEnd)
	s timestamp=start
	d second(.mode,timestamp)
	f  d  i timestamp="" q
	. s timestamp=$o(^export(timestamp)) i timestamp="" q
	. s iTimestamp=$$toNumber^date(timestamp)
	. i iTimestamp>iEnd s timestamp="" q
	. d second(.mode,timestamp)
	;
	i mode'="" w "</"_mode_">",$c(13,10)
	w "</osmChange>",$c(13,10)
	q
	
	
second(mode,timestamp)	;
	;
	n changeset,nodeId,wayId,relationId,version,action
	;
	s changeset=""
	f  d  i changeset="" q
	. s changeset=$o(^export(timestamp,"n",changeset)) i changeset="" q
	. s nodeId=""
	. f  d  i nodeId="" q
	. . s nodeId=$o(^export(timestamp,"n",changeset,nodeId)) i nodeId="" q
	. . s version=""
	. . f  d  i version="" q
	. . . s version=$o(^export(timestamp,"n",changeset,nodeId,version)) i version="" q
	. . . ;
	. . . s action=$$action(changeset,"n",nodeId,version)
	. . . i action'=mode s mode=$$changeMode("",mode,action)
	. . . ;
	. . . w $$xml^nodeVersion("",nodeId,changeset,version,"node|tag|@*")
	;
	s changeset=""
	f  d  i changeset="" q
	. s changeset=$o(^export(timestamp,"w",changeset)) i changeset="" q
	. s wayId=""
	. f  d  i wayId="" q
	. . s wayId=$o(^export(timestamp,"w",changeset,wayId)) i wayId="" q
	. . s version=""
	. . f  d  i version="" q
	. . . s version=$o(^export(timestamp,"w",changeset,wayId,version)) i version="" q
	. . . ;
	. . . s action=$$action(changeset,"w",wayId,version)
	. . . i action'=mode s mode=$$changeMode("",mode,action)
	. . . ;
	. . . w $$xml^wayVersion("",wayId,changeset,version,"way|@*|nd|tag|")
	;
	s changeset=""
	f  d  i changeset="" q
	. s changeset=$o(^export(timestamp,"r",changeset)) i changeset="" q
	. s relationId=""
	. f  d  i relationId="" q
	. . s relationId=$o(^export(timestamp,"r",changeset,relationId)) i relationId="" q
	. . s version=""
	. . f  d  i version="" q
	. . . s version=$o(^export(timestamp,"r",changeset,relationId,version)) i version="" q
	. . . ;
	. . . s action=$$action(changeset,"r",relationId,version)
	. . . i action'=mode s mode=$$changeMode("  ",mode,action)
	. . . ;
	. . . w $$xml^relationVersion("",relationId,changeset,version,"relation|@*|member|tag|")
	;
	q
	
	
action(changeset,element,nodeId,version)	; Derive whether it's a create, modify or delete
	;
	i version=1 q "create"
	i $p($g(^c(changeset,"n",nodeId,"v",version,"a")),$c(1),5)="false" q "delete"
	i $g(^c(changeset,"n",nodeId,"v",version,"t","@visible"))="false" q "delete"
	q "modify"
	
	
changeMode(indent,oldMode,newMode)	; Emit mode tags and return current mode
	i oldMode'="" w indent_"</"_oldMode_">",$c(13,10)
	w indent_"<"_newMode_">",$c(13,10)
	q newMode
	
	
	
setup	; Public ; Setup exportDiff
	;
	n url,startDate,in
	;
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
	
	
	
