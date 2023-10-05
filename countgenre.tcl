proc load_genre_database {} {
#global genre_db
global sortedgenrelist
global midi
global exec_out
if {[array exist genre_db]} return
set genrefile cleanedsortedgenre.txt

set i 0
set genrelist {}
set inhandle [open $genrefile]
while {![eof $inhandle]} {
  gets $inhandle line
  set data [split $line \t]

  set f [lindex $data 0]
  set g [lindex $data 1]
  
  if {![info exist count($g)]} {
   set count($g) 1} else {
   set count($g) [expr $count($g) + 1]
   }

  incr i
  }
close $inhandle
puts "last record number = $i"
set countlist [array get count]
set gcounts {}
foreach {item0 item1} $countlist {
  #puts "$item0 $item1"
  set elem [list $item0 $item1] 
  lappend gcounts $elem
  }

set gcounts [lsort -index 1 -integer $gcounts]
foreach elem $gcounts {
  puts "[lindex $elem 0]\t[lindex $elem 1]"
  }
}

load_genre_database




