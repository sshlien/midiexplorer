#grooveUsage.tcl
puts "enter groove code:"
gets stdin groove
puts "groove = $groove"




#search grooveFiles.txt for all files containing this
#groove
set inhandle [open "grooveFile.txt" "r"]
set j 0
while {[eof $inhandle] != 1} {
  incr j
  gets $inhandle line
  set linelist [split $line ,]
  set topgroove [lindex $linelist 1]
  set topgroove [string trim $topgroove]
  if {[string equal $topgroove $groove]} {
     puts $line
     }
  }
close $inhandle

