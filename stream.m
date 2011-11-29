stream	; Stream Class
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
	
	
openFile(stream,fileName)	; Public ; Create a stream object for a file and open the stream
	;
	o fileName:READ
	;
	s stream("current")=""
	s stream("fileName")=fileName
	s stream("recordCount")=0
	s stream("type")="file"
	;
	q
	
	
openPipe(stream,fileName)	; Public ; Create a stream object for a pipe and open the stream
	;
	o fileName:FIFO
	;
	s stream("current")=""
	s stream("fileName")=fileName
	s stream("recordCount")=0
	s stream("type")="pipe"
	;
	q
	
	
openPayload(stream)	; Public ; Create a stream object for an http payload
	;
	s stream("current")=""
	s stream("i")=""
	s stream("recordCount")=0
	s stream("type")="payload"
	;
	q
	
	
	
read(stream)	; Public ; Read a record from a stream
	;
	n line
	;
	; Get the next line
	i stream("type")="payload" d
	. s stream("i")=$o(^serverLink("payload",$j,stream("i"))) i stream("i")="" s line="" q
	. s line=^serverLink("payload",$j,stream("i"))
	e  u stream("fileName") r line
	;
	s stream("current")=line
	s stream("recordCount")=stream("recordCount")+1
	;
	q line
	
	
close(stream)	; Public ; Close the stream and destroy the stream object
	;
	i stream("type")="payload" ; no-op
	e  c stream("fileName")
	k stream
	q
	

eof(stream)	; Public ; End of File?
	;
	n eof
	;
	s eof=0
	i stream("type")="payload",stream("i")="" s eof=1
	i stream("type")="pipe" w 1/0 ; TODO
	i stream("type")="file" w 1/0 ; TODO
	q eof
	
	
