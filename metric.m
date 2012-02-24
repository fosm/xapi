metric	; Metrics class
	

update(metric,value)	; Public ; Increment or decrement a metric
	;
	tstart ():SERIAL
	s ^metric(metric,"count")=$g(^metric(metric,"count"))+value
	i $g(^debug)=1,$trestart=0 trestart
	tcommit
	q
	
