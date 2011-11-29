stats	; Display some stats
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



	d header^http("text/xml")
	w "<?xml version='1.0'?>",!
	w "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1'>",!
	w "<defs>",!
	w "<line id='horizontalLine' x1='0px' y1='0px' x2='700px' y2='0px' stroke='grey' stroke-width='1px'/>",!
	w "<line id='verticalLine' x1='0px' y1='0px' x2='0px' y2='200px' stroke='grey' stroke-width='1px'/>",!
	w "<rect id='blue' x='0px' y='0px' width='3px' height='200px' fill='blue' fill-opacity='0.5'/>",!
	w "<rect id='green' x='0px' y='0px' width='3px' height='200px' fill='green' fill-opacity='0.5'/>",!
	w "<rect id='red' x='0px' y='0px' width='3px' height='200px' fill='red' fill-opacity='0.5'/>",!
	w "</defs>",!
	;
	w "<rect x='0px' y='0px' width='700px' height='200px' fill='none' stroke='grey' stroke-width='2px'/>",!
	;
	f x=20:20:180 w "<use xlink:href='#horizontalLine' transform='translate(0,",x,")'/>",!
	;
	f y=50:50:700 w "<use xlink:href='#verticalLine' transform='translate(",y,",0)'/>",!
	;
	s column=0
	s oldCount=0
        s date="20071129"
        f  d  i date="" q
        . s date=$o(^total("date",date)) i date="" q
        . s count=^total("date",date,"item",20,"distinct")
        . s difference=count-oldCount
        . s oldCount=count
	. s column=column+1
	. s pubs=^total("date",date,"item",5,"count")-6500/20
	. s churches=^total("date",date,"item",7,"count")-6500/20
	. d bar(column,difference,"green")
	. ;d bar(column,pubs,"red")
	. ;d bar(column,churches,"blue")
	w "</svg>",!
        q
bar(column,value,class)	;
	w "<use ",!
	w "xlink:href='#",class,"' "
	w "transform='translate("
	w 3*(column-1),",200) "
	w "scale(1,",(value/200)*-1,")"
	w "'"
	w "/>",!
	q
