set inhandle [open playlistCounts.txt]
set inputdata [read $inhandle]
close $inhandle
set input [split $inputdata \n]
set bar "|"
foreach line $input {
  set line [string map  {\t |} $line]
  set line $bar$line$bar
  puts $line
  }

