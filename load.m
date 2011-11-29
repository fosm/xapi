load	; Load Monitor
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


	
	l ^load:0 e  q  ; Lood monitor already running

	s logFile="muninLoad.log"
	s ok=1
	f  d  i 'ok q
	. i $g(^load("run"))=0 s ok=0 q
	. s request=""
	. f c=0:1 s request=$o(^requestx(request)) i request="" q
	. s ^load("log",$h)=c
	. ;
	. o logFile:NEW u logFile w c,! c logFile
	. ;
	. h ^load("interval")
	q
