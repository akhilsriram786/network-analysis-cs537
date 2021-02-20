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

# Create the links:
$ns duplex-link $n0 $n2   2Mb  100ms DropTail
$ns duplex-link $n1 $n2   2Mb  100ms DropTail
$ns duplex-link $n2 $n3 0.2Mb  500ms DropTail
$ns duplex-link $n3 $n4   2Mb  100ms DropTail
$ns duplex-link $n3 $n5   2Mb  100ms DropTail

# Create a bottleneck with a maximum queue size of 5 packets
$ns queue-limit $n2 $n3 6


# Establish a TCP connection between n0 and n4 
# Add a TCP sending module to node n0
set tcp0 [new Agent/TCP/Reno]
$ns attach-agent $n0 $tcp0

# Add a TCP receiving module to node n4
set sink0 [new Agent/TCPSink]
$ns attach-agent $n4 $sink0

# Direct traffic from "tcp0" to "sink0"
$ns connect $tcp0 $sink0

# Setup a FTP traffic generator on "tcp0"
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0
$ftp0 set type_ FTP               

# Schedule start/stop times
$ns at 0.1   "$ftp0 start"
$ns at 50.0 "$ftp0 stop"

# Set simulation end time
$ns at 55.0 "finish"            


##################################################
## Obtain CWND from TCP agent
##################################################

proc congWin {} {
   global ns f0 tcp0

   set now [$ns now]
   set interval 0.1

   set cwnd0 [$tcp0 set cwnd_]

   ###Print TIME CWND   into the output file   
   puts  $f0  "$now $cwnd0"

   $ns at [expr $now+$interval] "congWin"
}

#Print Column names at the first row of output file
#This line will be used to plot the chart 
puts  $f0  "Time cwnd_tcp0"

$ns  at  0.0  "congWin"

##################################################
## Obtain Throughput from TCP agent
##################################################

proc throughput {} {
   global ns f1 sink0

   set now [$ns now]
   set interval 0.5 

   set acked0 [$sink0 set bytes_]

   #Calculate the throughput (in Mbit/s) 
   #Throughput is the amount of ACKed data reached the destination 
   set thr0 [expr $acked0/$interval*8/1000000]


   ###Print TIME THROUGHTPUT   into the output file   
   puts  $f1  "$now $thr0"

   #Reset the bytes_ values on the traffic sinks
   $sink0 set bytes_ 0

   $ns at [expr $now+$interval] "throughput"
}

#Print Column names at the first row of output file
#This line will be used to plot the chart 
puts  $f1  "Time Throughput_sink0"

$ns  at  0.0  "throughput"

#Establish a UDP connection between n1 and n5
set udp1 [new Agent/UDP] 
$ns attach-agent $n1 $udp1  
set udpsink1 [new Agent/LossMonitor]  
$ns attach-agent $n5 $udpsink1 
$ns connect $udp1 $udpsink1 
 
# Create a CBR traffic generator at source n1 and attach it to udp1
set cbr1 [new Application/Traffic/CBR] 
$cbr1 set type_ CBR 
$cbr1 set packet_size_ 1000 
$cbr1 set rate_ 0.05Mb 
$cbr1 set random_ false 
 
$cbr1 attach-agent $udp1 
 
$ns at 0.1   "$cbr1 start" 
$ns at 50.0 "$cbr1 stop" 

 
proc throughput {} {   
 global ns f1 sink0 udpsink1 
 
   set now [$ns now] 
   set interval 0.5  
 
   set acked0 [$sink0 set bytes_] 
   set rcved1 [$udpsink1 set bytes_] 
 
   #Calculate the throughput (in Mbit/s)  
   #Throughput is the amount of ACKed data reached the destination  
   set thr0 [expr $acked0/$interval*8/1000000] 
 
   #Throughput is the amount of UDP data reached the destination  
   set thr1 [expr $rcved1/$interval*8/1000000] 
 
 
   ###Print TIME THROUGHTPUT   into the output file      
 puts  $f1  "$now $thr0 $thr1" 
 
   #Reset the bytes_ values on the traffic sinks 
   $sink0 set bytes_ 0 
   $udpsink1 set bytes_ 0 
 
   $ns at [expr $now+$interval] "throughput" 
} 
  
#Print Column names at the first row of output file 
#This line will be used to plot the chart  
puts  $f1  "Time Throughput_sink0 Throughput_udpsink1" 



# Run simulation 
$ns run