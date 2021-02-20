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
$ns duplex-link $n0 $n2   5Mb  20ms DropTail
$ns duplex-link $n1 $n2   5Mb  20ms DropTail
$ns duplex-link $n2 $n3 0.5Mb 100ms DropTail
$ns duplex-link $n3 $n4   5Mb  20ms DropTail
$ns duplex-link $n3 $n5   5Mb  20ms DropTail


# Create a bottleneck with a maximum queue size of 5 packets
$ns queue-limit $n2 $n3 5

# Establish a TCP connection between n0 and n4 
# Add a TCP sending module to node n0
set tcp0 [new Agent/TCP/Linux]
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


# Run simulation 
$ns run
