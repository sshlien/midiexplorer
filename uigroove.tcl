package require Ttk

set c .container
frame $c
frame $c.groovelist
set g .groovelist.box
ttk::treeview $c$g -columns {code count filecount}    -yscroll {$c.groovelist.scroll set} -height 15 -show headings
scrollbar $c.groovelist.scroll -bd 2 -command {$c$g yview}
pack $c$g $c.groovelist.scroll -side left -fill y
pack $c.groovelist
$c$g column code -width 120
$c$g column count -width 60
$c$g column filecount -width 60

frame $c.filelist
set f .filelist.box
ttk::treeview $c$f -columns {filename}    -yscroll {$c.filelist.scroll set} -height 15 -show headings
scrollbar $c.filelist.scroll -bd 2 -command {$c$f yview}
pack $c$f $c.filelist.scroll -side left -fill y
$c$f column filename -width 300
pack $c.groovelist $c.filelist -side left

frame .summary
label .summary.k
label .summary.bin 
button .summary.abc -text abc -command {
   groove2abc 
   exec "../runabc.tcl"
   }

button .summary.help -text help
pack $c .summary -side top
pack .summary.bin .summary.k .summary.abc .summary.help -side left

set os $tcl_platform(platform)
if {$os == "unix"} {
  set midi(rootdir) "/home/seymour/clean midi/"
  set midi(explorer) "~seymour/abc/midiexplorer.tcl"
} else {
  set midi(rootdir) "C:/Users/fy733/Music/lakh clean midi"
  set midi(explorer) C:/Users/fy733/OneDrive/Documents/abc/tcl/midiexplorer.tcl
}


set inhandle [open "grooves.csv" r]
while {[eof $inhandle] != 1} {
  gets $inhandle line
  set linelist [split $line ,]
  set groove [lindex $linelist 0]
  set count [lindex $linelist 1]
  set filecount [lindex $linelist 2]
  $c$g insert {} end -values "$groove $count $filecount"
  incr i
  if {$i > 200} break
  }
close $inhandle
bind $c$g <<TreeviewSelect>> {get_groove_info}
bind $c$f <<TreeviewSelect>> {gotoexplorer}

proc get_groove_info {} {
global code
set c .container
set index [$c.groovelist.box selection]
set values [$c.groovelist.box item $index -values]
set code [lindex $values 0]
set count [lindex $values 1]
set filecount [lindex $values 2]
decodegroove $code
.summary.k configure -text "$count
$filecount"

filesWithGroove $code 
}

proc decodegroove {groove} {
global notesnare notebass has16th
set hits [split $groove :]
set has16th 0
foreach hit $hits {
  set hithigh [expr $hit/16]
  set binsnare [format %04b $hithigh]
  append binarysnare $binsnare
  append strbinarysnare "$binsnare "
  set has16th  [expr $has16th || [has16thnotes $hithigh]]
  }
append strbinarysnare "snare"
foreach hit $hits {
  set hitlow [expr $hit % 16]
  set binbass [format %04b $hitlow]
  append binarybass $binbass
  append strbinarybass "$binbass "
  set has16th  [expr $has16th || [has16thnotes $hitlow]]
  }
append strbinarybass "bass"
.summary.bin configure -text "$strbinarysnare
$strbinarybass"
set notesnare [string map {1 d 0 x} $binarysnare]
set notebass [string map {1 F 0 x} $binarybass]
set notesnare "[split $notesnare {}]|"
set notebass "[split $notebass {}]|"


#puts "has16th = $has16th"
}

proc has16thnotes {n} {
  set z [expr $n & 5592405]
  # binary of 5592405 = 10101010101010101010101
  if {$z != 0} {set z 1}
  return $z
  }

proc filesWithGroove {groove} {
set c .container
set f .filelist.box
$c.filelist.box delete [$c.filelist.box children {}]

set inhandle [open "grooveFile.txt" "r"]
set j 0
while {[eof $inhandle] != 1} {
  incr j
  gets $inhandle line
  set linelist [split $line ,]
  set topgroove [lindex $linelist 1]
  set topgroove [string trim $topgroove]
  if {[string equal $topgroove $groove]} {
     $c$f insert {} end -values [lindex $linelist 0]
     }
  }
close $inhandle
}


proc chopoff16thnotes {list16} {
set list8 [list]
set i 0
foreach elem $list16 {
  if {[expr $i % 2] == 0} {lappend list8 $elem}
  incr i
  }
return $list8
}


proc combineSnareAndBass {snare bass has16th} {
#puts "snare = $snare"
#puts "bass = $bass"

set c "|:"
set i 0
foreach s $snare b $bass {
  if {$s == "x" && $b == "x"} {
      append c z
      }
  if {$s == "d" && $b == "x"} {
      append c $s
      }
  if {$s == "x" && $b == "F"} {
      append c $b
      }
  if {$s == "d" && $b == "F"} {
      append c "\[Fd\]"
      }
  incr i
  if {[expr $i % 4] == 0} {append c " "}
  if {$has16th == 0 && [expr $i % 2] ==0} {append c " "}
  }
append c ":|"
return $c
}

proc groove2abc {} {
global notesnare notebass has16th
global code L
 if {$has16th == 0} {
    set notesnare [chopoff16thnotes $notesnare]
    set notebass  [chopoff16thnotes $notebass]
    set L 1/8
  } else {
    set L 1/16
    }

set combo [combineSnareAndBass $notesnare $notebass $has16th] 
#puts "combo = $combo"
set head "X:1
T: $code
M: 4/4
L: $L
Q: 1/4 = 120
K: C"
set outhandle [open "tmp.abc" "w"]
puts $outhandle $head
puts $outhandle "%%MIDI channel 10
%%MIDI drummap F 36
%%MIDI drummap d 38
%%percmap F b-d-1
%%percmap d a-s
$combo|"
close $outhandle
}


proc gotoexplorer {} {
global explorer
global os
global midi
set c .container
set index [$c.filelist.box selection]
set filename [$c.filelist.box item $index -values]
set filename [string range $filename 1 end-1]
#puts $filename
set fullpath [file join $midi(rootdir) $filename]

#puts "fullpath = $fullpath"
if {$os == "unix"} {
  set cmd "exec /usr/bin/wish $midi(explorer) [list $fullpath] &"
} else {
  set cmd "exec wish $midi(explorer) $fullpath &"
}
#puts "cmd = $cmd"
catch {eval $cmd} result
#puts "result = $result"
}

