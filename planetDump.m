planetDump	; Dump the planet
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
	
	
	; Public ; Run planet dump
	; Dump all nodes, ways and relations.
	; 
	;
	l +^planetDump("running"):0 e  q
	d main
	l -^planetDump("running")
	q
	
	
	
main	;
	n iDateTile,file
	;
	s iDateTime=$$toNumber^date($$nowZulu^date())
	s file=$$createPlanetFile(iDateTime)
	q
	
createPlanetFile(iDateTime)	;
	;
	; iDateTime = ccyymmddhhmmss
	;
	n directory,tempFile,zipFile,pipe
	;
	s directory=$g(^planetDump("directory"))
	s pipe=directory_"earth.pipe"
	s tempFile=directory_"earth-"_iDateTime_".temp"
	s zipFile=directory_"earth-"_iDateTime_".osm.bz2"
	zsystem "rm "_pipe_"; mkfifo "_pipe_"; bzip2 -9 <"_pipe_" >"_tempFile_" &"
	;
	o pipe:(nowrap:stream:fifo)
	;
	; Let's do it
	u pipe
	d xmlProlog^rest("")
	d dump()
	;
	c pipe
	;
	zsystem "mv "_tempFile_" "_zipFile
	;
	q ""
	
	
	
dump()	; Emit everything
	;
	;
	w "<osm"
	w $$attribute^osmXml("version","0.6","")
	w $$attribute^osmXml("generator","fosm 1.0","")
	w ">",$c(13,10)
	;
	d nodes
	d ways
	d relations
	;
	w "</osm>",$c(13,10)
	q
	
	
nodes	;
	n q,n,count
	;
	k ^planetDump("nodeCount")
	k ^planetDump("nodeCheckpoint")
	;
	s count=0
	s q=""
	f  d  i q="" q
	. s q=$o(^e(q)) i q="" q
	. s n=""
	. f  d  i n="" q
	. . s n=$o(^e(q,"n",n)) i n="" q
	. . w $$xml^node("",n,"",q)
	. . s count=count+1
	. . i count#10000=0 d
	. . . s ^planetDump("nodeCount")=count
	. . . s ^planetDump("nodeCheckpoint")=q_"|"_n
	;
	q
	
	
ways	;
	n w,count
	;
	k ^planetDump("wayCount")
	k ^planetDump("wayCheckpoint")
	;
	s count=0
	s w=""
	f  d  i w="" q
	. s w=$o(^way(w)) i w="" q
	. w $$xml^way("",w,"way|nd|tag|@*")
	. s count=count+1
	. i count#10000=0 d
	. . s ^planetDump("wayCount")=count
	. . s ^planetDump("wayCheckpoint")=w
	;
	q
	
	
relations	;
	;
	n r,count
	;	
	k ^planetDump("relationCount")
	k ^planetDump("relationCheckpoint")
	;
	s count=0
	s r=""
	f  d  i r="" q
	. s r=$o(^relation(r)) i r="" q
	. w $$xml^relation("",r,"relation|member|tag|@*")
	. s count=count+1
	. i count#10000=0 d
	. . s ^planetDump("relationCount")=count
	. . s ^planetDump("relationCheckpoint")=r
	;
	q
