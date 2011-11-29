log	; Request log
	; Copyright (C) 2008  Etienne Cherdlu <80n80n@gmail.com>
	;
	; This program is free software: you can redistribute it and/or modify
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
	
	
requests	; Public ; Generate list of most recent requests
	;
	d header^http("text/html")
	;
	w "<html>",!
	w "<body>",!
	w "<h2>Recent xapi requests on ",^osmPlanet("instance"),"</h2>",!
	w "<table border='0'>",!
	w "<td>",!
	w "<tr>",!
	w "<td>Id</td>",!
	w "<td>Request</td>",!
	w "<td>Start time</td>",!
	w "<td>Duration</td>",!
	w "</tr>",!
	;
	s logId=""
	f i=1:1:50 d  i logId="" q
	. s logId=$o(^log(logId),-1) i logId="" q
	. w "<tr>",!
	. w "<td>",logId,"</td>",!
	. w "<td>",^log(logId,"request"),"</td>",!
	. w "<td>",^log(logId,"start"),"</td>",!
	. w "<td>",$g(^log(logId,"duration")),"</td>",!
	. w "</tr>",!
	;
	w "</table>",!
	w "</body>",!
	w "</html>",!
	q
	
	
