watch	; Watch class
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


	
rss(string)	; Public ; Generate rss feed of a users watch items
	;
	n watchlist,user,category,sequence,count
	;
	s watchlist=$p(string,"/",1,2)
	s user=$p(watchlist,"/",1)
	s category=$p(watchlist,"/",2)
	;
	d header^http("application/rss+xml")
	d prolog^osmXml("")
	;
	w "<rss version='2.0'>",!
	w "<channel>",!
	w "<title>OSM Watchlist</title>",!
	w "<description>RSS feed of OpenStreetMap changes being watched by user "_$p(watchlist,"/",1)
	i category'="" w " for category "_category
	w ".</description>",!
	;
	s sequence=""
	f count=1:1 d  i sequence="" q
	. s sequence=$o(^watchRss(watchlist,sequence),-1) i sequence="" q
	. i count>30 s sequence="" q
	. ;
	. m event=^watchRss(watchlist,sequence)
	. ;
	. ; If this is a category event then link to the RSS feed for this user's category
	. i event("type")="category" d category(.event,user)
	. e  d element(.event)
	;
	w "</channel>",!
	w "</rss>",!
	q
	
	
category(event,user)	; Category event
	;
	w "<item>",!
	w "<title>",event("id")_" ",event("mode")," by ",event("changedBy"),"</title>",!
	w "<pubDate>",event("timestamp"),"</pubDate>",!
	w "<link>http://www.informationfreeway.org/api/0.5/watch/"_user_"/"_event("id")_"</link>",!
	w "<guid>http://www.informationfreeway.org/api/0.5/watch/"_user_"/"_event("id")_"</guid>",!
	w "</item>",!
	;
	q
	
	
element(event)	; Element event
	;
	n name
	;
	s name=$g(event("name"))
	i name="" s name=event("type")_" "_event("id")
	;
	w "<item>",!
	w "<title>",name_" ",event("mode")," by ",event("changedBy"),"</title>",!
	w "<pubDate>",event("timestamp"),"</pubDate>",!
	w "<link>http://www.openstreetmap.org/api/0.5/"_event("type")_"/"_event("id")_"/history</link>",!
	w "<guid>http://www.openstreetmap.org/api/0.5/"_event("type")_"/"_event("id")_"/history</guid>",!
	w "</item>",!
	;
	q
	
