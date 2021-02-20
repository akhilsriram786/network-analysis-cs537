#Create a new simulator object 
set ns [new Simulator]        

#Create a trace file
set tracefd [open trace.tr w]
$ns trace-all $tracefd

#Open the output files
set f0 [open cwnd.tr w]
set f1 [open thrpt.tr w]

# Define a 'finish' procedure
proc finish {} {
   global f0 f1
   #Close the output files
   close $f0
   close $f1
   #Exit the simulation
   exit 0
}

# Create the nodes:
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]
set n7 [$ns node]
set n8 [$ns node]
set n9 [$ns node]

# Create the links:
$ns duplex-link $n0 $n4    2Mb 100ms  DropTail
$ns duplex-link $n1 $n4    2Mb 100ms  DropTail
$ns duplex-link $n2 $n4    2Mb 100ms  DropTail
$ns duplex-link $n3 $n4    2Mb 100ms  DropTail
$ns duplex-link $n4 $n5  0.2Mb 500ms  DropTail
$ns duplex-link $n5 $n6    2Mb 100ms  DropTail
$ns duplex-link $n5 $n7    2Mb 100ms  DropTail
$ns duplex-link $n5 $n8    2Mb 100ms  DropTail
$ns duplex-link $n5 $n9    2Mb 100ms  DropTail


# Create a bottleneck with a maximum queue size of 5 packets
$ns queue-limit $n4 $n5 6

# Establish a TCP connection between n0 and n4 
# Add a TCP sending module to node n0
set tcp0 [new Agent/TCP/Reno]
set tcp1 [new Agent/TCP/Reno]
set tcp2 [new Agent/TCP/Reno]
set tcp3 [new Agent/TCP/Reno]

$ns attach-agent $n0 $tcp0
$ns attach-agent $n1 $tcp1
$ns attach-agent $n2 $tcp2
$ns attach-agent $n3 $tcp3

# Add a TCP receiving module to node n4
set sink0 [new Agent/TCPSink]
set sink1 [new Agent/TCPSink]
set sink2 [new Agent/TCPSink]
set sink3 [new Agent/TCPSink]

$ns attach-agent $n6 $sink0
$ns attach-agent $n7 $sink1
$ns attach-agent $n8 $sink2
$ns attach-agent $n9 $sink3


# Direct traffic from "tcp0" to "sink0"
$ns connect $tcp0 $sink0
$ns connect $tcp1 $sink1
$ns connect $tcp2 $sink2
$ns connect $tcp3 $sink3


# Setup a FTP traffic generator on "tcp0"
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0
$ftp0 set type_ FTP  

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp1 set type_ FTP    

set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ftp2 set type_ FTP     

set ftp3 [new Application/FTP]
$ftp3 attach-agent $tcp3
$ftp3 set type_ FTP  

            
     

# Schedule start/stop times
$ns at 0.0   "$ftp0 start"
$ns at 100.0 "$ftp0 stop"

$ns at 5   "$ftp1 start"
$ns at 100.0 "$ftp1 stop"

$ns at 10   "$ftp2 start"
$ns at 100.0 "$ftp2 stop"

$ns at 15   "$ftp3 start"
$ns at 100.0 "$ftp3 stop"



# Set simulation end time
$ns at 105.0 "finish"            


##################################################
## Obtain CWND from TCP agent
##################################################

proc congWin {} {
   global ns f0 tcp0 tcp1 tcp2 tcp3 
   

   set now [$ns now]
   set interval 0.1

   set cwnd0 [$tcp0 set cwnd_]
   set cwnd1 [$tcp1 set cwnd_]
   set cwnd2 [$tcp2 set cwnd_]
   set cwnd3 [$tcp3 set cwnd_]
  

   ###Print TIME CWND   into the output file   
   puts  $f0  "$now $cwnd0 $cwnd1 $cwnd2 $cwnd3"
   

   $ns at [expr $now+$interval] "congWin"
}

#Print Column names at the first row of output file
#This line will be used to plot the chart 
puts  $f0  "Time cwnd_tcp0 cwnd_tcp1 cwnd_tcp2 cwnd_tcp3"


$ns  at  0.0  "congWin"

##################################################
## Obtain Throughput from TCP agent
##################################################

proc throughput {} {
   global ns f1 sink0 sink1 sink2 sink3
  

   set now [$ns now]
   set interval 0.5 

   set acked0 [$sink0 set bytes_]
   set acked1 [$sink1 set bytes_]
   set acked2 [$sink2 set bytes_]
   set acked3 [$sink3 set bytes_]

   #Calculate the throughput (in Mbit/s) 
   #Throughput is the amount of ACKed data reached the destination 
   set thr0 [expr $acked0/$interval*8/1000000]
   set thr1 [expr $acked1/$interval*8/1000000]
   set thr2 [expr $acked2/$interval*8/1000000]
   set thr3 [expr $acked3/$interval*8/1000000]


   ###Print TIME THROUGHTPUT   into the output file   
   puts  $f1  "$now $thr0 $thr1 $thr2 $thr3"
   
   #Reset the bytes_ values on the traffic sinks
   $sink0 set bytes_ 0
   $sink1 set bytes_ 0
   $sink2 set bytes_ 0
   $sink3 set bytes_ 0

   $ns at [expr $now+$interval] "throughput"
}

#Print Column names at the first row of output file
#This line will be used to plot the chart 
puts  $f1  "Time Throughput_sink0 Throughput_sink1 Throughput_sink2 Throughput_sink3"


$ns  at  0.0  "throughput"


# Run simulation 
$ns run