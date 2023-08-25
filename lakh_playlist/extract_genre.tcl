# extract_genre.tcl

set inhandle [open "genre.tsv" "r"]
set contents [read $inhandle]
close $inhandle
set contents [split $contents \n]
foreach line $contents {
  set line [split $line \t]
  set g [lindex $line 1]
  if {$g != 0 && $g != "unknown" } {
    puts $line
    }
}

