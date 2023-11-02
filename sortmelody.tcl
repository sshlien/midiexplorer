proc load_melody_database {} {
#global genre_db
global sortedgenrelist
global midi
global exec_out
if {[array exist genre_db]} return
#set genrefile [file join $midi(rootfolder) genre.tsv]
set genrefile melody.txt

#if {![file exist $genrefile]} {
#   append exec_out "Could not find genre.tsv in $midi(rootfolder)\ncreating template."
#   initialize_genre_database}

set i 0
set genrelist {}
set inhandle [open $genrefile]
while {![eof $inhandle]} {
  gets $inhandle line
  set data [split $line \t]

  set f [lindex $data 0]
  set g [lindex $data 1]
  
  #set gtrimmed [string map {\" {}} $g]
  set gtrimmed [string trimleft $g \"]
  set gtrimmed [string trimright $gtrimmed \"]

  set newdata [list $f $gtrimmed]

  lappend genrelist $newdata

  incr i
  }
close $inhandle
set sortedgenrelist [lsort -index 0 $genrelist]
puts "last record number = $i"
}


load_melody_database

set outhandle [open sortedmelody.txt w]
foreach item $sortedgenrelist {
  set has_slash [string first \/ [lindex $item 0]]
  if {$has_slash < 0} {
    puts "illegal artist [lindex $item 0]"
    } else {
    puts $outhandle "[lindex $item 0]\t[lindex $item 1]"
    }
  }
close $outhandle


