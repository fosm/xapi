threeen1c
        ; Find the maximum cycle lenth for the 3n+1 problem for all integers through two input integers.
        ; See http://docs.google.com/View?id=dd5f3337_12fzjpqbc2
        ; Assumes input format is 3 integers separated by a space with the first integer smaller than the second.
        ; Third integer is number of threads.  No input error checking is done.  -- K.S. Bhaskar 20091122
        ; No claim of copyright is made with respect to this program.
        ;
        ; Loop over lines in input
        For  Read input Quit:$ZEOF!'$Length(input)  Do
        .Set i=$Piece(input," ",1)              ; i - starting number
        .Set j=$Piece(input," ",2)              ; j - ending number
        .Set k=$Piece(input," ",3)              ; k - parallel execution streams requested
        .Write i," ",j," ",k                    ; Reproduce input on output
        .;Open "cpus":(COMMAND="grep processor /proc/cpuinfo|wc -l":READONLY)::"PIPE"
        .;Use "cpus" Read cpus Use $PRINCIPAL    ; Get number of CPUS on system
        .;Close "cpus"
	.s cpus=4
        .Set:4*cpus>k k=4*cpus                  ; at least four execution streams per CPU
        .Write " ",k                            ; Report actual number of execution streams
        .Set blk=(j-i+k)\k                      ; Calculate size of blocks (last block may be smaller)
        .Set ^count=0                           ; Clear count - may have residual value if restarting from crash
	.set ^count("next")=0
	.Lock +l1                               ; Set lock for process synchronization
        .For s=i:blk:j Do
        ..Set c=$Increment(^count)              ; Atomic increment of counter in database for process synchronization
	..Set ^count(c)=s_"|"_(s+blk-1)_"|"_i_"|"_j
	..;Job doblk(s,s+blk-1,i,j)              ; Job process for next block of numbers
	..zsystem "$gtmrun doblk^threen1c three"_c
	.For  Quit:'^count  Hang 0.1            ; Wait for processes to start (^count goes to 0 when they do)
        .Lock -l1                               ; Release lock so processes can run
        .Set startat=$HOROLOG                   ; Starting time
        .Lock +l2                               ; Wait for processes to finish
        .set endat=$HOROLOG                     ; Ending time
        .Write " ",^result," ",(86400*($Piece(endat,",",1)-$Piece(startat,",",1)))+$Piece(endat,",",2)-$Piece(startat,",",2),!
        .Lock -l2                               ; Release lock for next run
        .Do dbinit                              ; Initialize database for next run
        Quit
        ;
dbinit                                          ; Initializes database
        Kill ^cycle,^count                      ; Clear database for next iteration
        Set ^result=1                           ; Initialize ^result to minimum legal cycle length
        Quit
        ;
; This is where Jobbed processes start
	;doblk(myfirst,mylast,allfirst,alllast)
doblk	;
        h 5
	Lock +l2($JOB)                          ; Get lock parent will wait on till Jobbed processes are done
	s next=$i(^count("next"))
	s args=^count(next)
	Set tmp=$Increment(^count,-1)           ; Decrement ^count to say this process is alive
	Lock +l1($JOB)                          ; Getting lock on l1($JOB) means parent has released lock on l
	s myfirst=$p(args,"|",1)
	s mylast=$p(args,"|",2)
	s allfirst=$p(args,"|",3)
	s alllast=$p(args,"|",4)
	Do docycle(myfirst,mylast)              ; Do the block I am assigned to, then do the other blocks
        Do:alllast>mylast docycle(mylast+1,alllast)
        Do:allfirst<myfirst docycle(allfirst,myfirst-1)
        Lock -l1($JOB),-l2($JOB)
        Quit
        ;
docycle(first,last)                             ; Calculate
        New current,currpath,i,n                ; New variables used in this routine
        For current=first:1:last Do
        .Set n=current                          ; Start n at current
        .Kill currpath                          ; Currpath holds path to 1 for current
        .For i=0:1 Quit:$Data(^cycle(n))!(1=n)  Do         ; Go till we reach 1 or a number with a known cycle
        ..Set currpath(i)=n                     ; log n as current number in sequence
        ..Set n=$Select('(n#2):n/2,1:3*n+1)     ; compute the next number
        .Do:0<i                                 ; if 0=i we already have an answer for n
        ..If 1=n Set i=i+1
        ..Else  S i=i+^cycle(n)
        ..TStart ()                             ; Atomically set maximum
        ..Set:i>^result ^result=i
        ..TCommit
        ..Set n="" For  Set n=$Order(currpath(n)) Quit:""=n  Set ^cycle(currpath(n))=i-n
        Quit
