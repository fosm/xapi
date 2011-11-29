streamx	; Stream Class
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
	s stream("buffer")=""
	;
	q
	
	
openPipe(stream,fileName)	; Public ; Create a stream object for a pipe and open the stream
	;
	o fileName:FIFO
	;
	s stream("current")=""
	s stream("fileName")=fileName
	s stream("recordCount")=0
	s stream("buffer")=""
	;
	q
	
	
read(stream)	; Public ; Read a record from a stream
	;
	n line
	;
	u stream("fileName") r line
	s stream("current")=line
	s stream("recordCount")=stream("recordCount")+1
	;
	q line
	
readx(stream)	; Public ; Read buffered data from a stream
	;
	n line,data
	;
	; Keep the buffer filled (between 10,000 and 20,000 bytes)
	i $l(stream("buffer"))<10000 d
	. u stream("fileName") r line#10000 i $l(line)=0 q
	. s stream("buffer")=stream("buffer")_line
	;
	; Read up to the next >< delimited point
	i stream("buffer")'["><" s data=stream("buffer") ; Should be end of file (I hope)
	e  s data=$p(stream("buffer"),"><",1)_">",stream("buffer")=$e(stream("buffer"),$l(data)+1,30000)
	s stream("recordCount")=stream("recordCount")+1
	;
	q data	
	
close(stream)	; Public ; Close the stream and destroy the stream object
	;
	c stream("fileName")
	k stream
	q
	
