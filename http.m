http	; serverLink http library functions
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
	
	q
	
	
word(fileName)	; Public ; Word document (as attachment)
	;
	w "Status: 200 OK",!
	w "Content-Type: application/msword; name="_fileName,!
	w "Content-Disposition: attachment; filename="_fileName,!
	w !
	q
	
	
excel(fileName)	; Public ; In-line excel spreadsheet
	;
	w "Status: 200 OK",!
	w "Content-Type: application/vnd.ms-excel; name="_fileName,!
	w "Content-Disposition: inline; filename="_fileName,!
	w !
	q
	
	
header(type)	; Public ; Print simple/minimal http header
	;
	w "Status: 200 OK",!
	w "Content-Type: ",type,!
	i $d(%session) d cookie^session
	w !
	q
	
	
gone	; Public ; Print 410 gone header
	;
	w "Status: 410 Gone",!
	w !
	q
	
	
notFound	; Public ; Print 404 Not Found header
	;
	w "Status: 404 Not Found",!
	w !
	q
	
	
xml(filename)	; Public ; Generate xml attachment header
	;
	w "Status: 200 OK",!
	w "Content-Type: text/xml",!
	w "Content-Disposition: attachment; filename=",filename,!
	w !
	q
	
	
error	; Public ; Server-side error
	; NB send a content-type record because IE 6.0 may otherwise try to download the content (erroneously).
	;
	w "Status: 500 Internal Server Error",!
	w "Content-Type: text/html",!
	w !
	q
	
	
error409(message)	; Public ; Generate a 409 error
	;
	w "Status: 409 Conflict",!
	w "Content-Type: text/plain",!
	w "Error: ",message,!
	w !
	;
	q
	
	
redirect(location)	; Public ; Server-side redirect
	;
	w "Location: ",location,!
	w !
	q
