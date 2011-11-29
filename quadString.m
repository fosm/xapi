quadString	; QuadString Library
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


	
llToQs(lat,lon)	; Public ; Convert lat/lon to quadString
	;
	n qsTile,latIncrement,lonIncrement,zoom
	;
	s qsTile=""
	s latIncrement=90
	s lonIncrement=180
	;
	f zoom=1:1:15 d
	. s latIncrement=latIncrement/2
	. s lonIncrement=lonIncrement/2
	. i lat<0,lon<0 s lat=lat+latIncrement,lon=lon+lonIncrement,qsTile=qsTile_"c" q
	. i lat<0 s lat=lat+latIncrement,lon=lon-lonIncrement,qsTile=qsTile_"d" q
	. i lon<0 s lat=lat-latIncrement,lon=lon+lonIncrement,qsTile=qsTile_"a" q
	. s lat=lat-latIncrement,lon=lon-lonIncrement,qsTile=qsTile_"b" q
	;
	q qsTile
	
	
qsToLl(qsItem)	; Public ; Convert quadString to lat/lon
	;
	n lat,lon
	;
	s lat=0,lon=0
	;
	d qsToLl1(qsItem,.lat,.lon,90,180)
	;
	q lat_","_lon
	
	
qsToLl1(qsItem,lat,lon,latIncrement,lonIncrement)	;
	;
	n tile
	;
	s tile=$e(qsItem,1) i tile="" q
	;
	s latIncrement=latIncrement/2
	s lonIncrement=lonIncrement/2
	;
	i tile="a" s lat=lat+latIncrement,lon=lon-lonIncrement
	i tile="b" s lat=lat+latIncrement,lon=lon+lonIncrement
	i tile="c" s lat=lat-latIncrement,lon=lon-lonIncrement
	i tile="d" s lat=lat-latIncrement,lon=lon+lonIncrement
	;
	d qsToLl1($e(qsItem,2,$l(qsItem)),.lat,.lon,latIncrement,lonIncrement)
	;
	q
	
	
qsToBbox(qsItem,bllat,bllon,trlat,trlon)	; Public ; Convert quadString to bbox
	;
	s bllat=-90,bllon=-180,trlat=90,trlon=180
	;
	d qsToBbox1(qsItem,.bllat,.bllon,.trlat,.trlon,90,180)
	;
	q
	
	
qsToBbox1(qsItem,bllat,bllon,trlat,trlon,latIncrement,lonIncrement)	;
	;
	n tile
	;
	s tile=$e(qsItem,1)
	;
	i tile="a" s bllat=bllat+latIncrement,trlon=trlon-lonIncrement
	i tile="b" s bllat=bllat+latIncrement,bllon=bllon+lonIncrement
	i tile="c" s trlat=trlat-latIncrement,trlon=trlon-lonIncrement
	i tile="d" s trlat=trlat-latIncrement,bllon=bllon+lonIncrement
	;
	i $l(qsItem)>1 d qsToBbox1($e(qsItem,2,$l(qsItem)),.bllat,.bllon,.trlat,.trlon,latIncrement/2,lonIncrement/2)
	;
	q
	
qsRoot(qsRoot,qsItem)	  ; Public ; Return common root of two quadStrings
	;
	n x
	;
	f x=$l(qsRoot):-1:0 i $e(qsItem,1,x)=$e(qsRoot,1,x) s qsRoot=$e(qsRoot,1,x) q
	q qsRoot
	
	
bbox(bllat,bllon,trlat,trlon)	; Public ; Return quadString for a given bounding box
	;
	n qsbl,qstl,qsbr,qstr,qsRoot
	;
	s qsbl=$$llToQs(bllat,bllon)
	s qstl=$$llToQs(trlat,bllon)
	s qsbr=$$llToQs(bllat,trlon)
	s qstr=$$llToQs(trlat,trlon)
	s qsRoot=qsbl
	s qsRoot=$$qsRoot^quadString(qsRoot,qstl)
	s qsRoot=$$qsRoot^quadString(qsRoot,qsbr)
	s qsRoot=$$qsRoot^quadString(qsRoot,qstr)
	;
	q qsRoot
	
	
bboxInQs(bbox,qsItem)	; Public ; Is any part of this bbox contained within this quadString?
	;
	n bllat,bllon,trlat,trlon
	;
	d qsToBbox(qsItem,.bllat,.bllon,.trlat,.trlon)
	;
	q $$overlap(bllat,bllon,trlat,trlon,bbox("bllat"),bbox("bllon"),bbox("trlat"),bbox("trlon"))
	
	
incrementQs(qsItem)	; Public ; Add 1 to a quadTile number (eg aaa+1=aab, abd+1=aca)
	;
	n rest,last
	;
	; ddd+1 returns null
	i $tr(qsItem,"d","")="" q ""
	;
	s rest=$e(qsItem,1,$l(qsItem)-1)
	s last=$e(qsItem,$l(qsItem))
	;
	i last="d" s rest=$$incrementQs(rest) q rest
	i last="c" s last="d"
	i last="b" s last="c"
	i last="a" s last="b"
	q rest_last
	
	
overlap(bllat1,bllon1,trlat1,trlon1,bllat2,bllon2,trlat2,trlon2)	;
	;
	; Algorithm from http://www.siliconchisel.com/Articles/Development_&_Tools/Fast_Window_Overlap_Checking_Algorithm/
	;
	i ((trlat1-bllat2)<0)'=((bllat1-trlat2)<0),((bllon1-trlon2)<0)'=((trlon1-bllon2)<0) q 1
	;
	q 0
