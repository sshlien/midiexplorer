#groove2abc.tcl

set groove "8:136:8:136"
#puts "enter groove code:"
#gets stdin groove
puts "groove = $groove"

set head "X:1
T: $groove
M: 4/4
L: 1/16
Q: 1/4 = 120
K: C
%%staves \[(1 | 2)\]"

set hits [split $groove :]
puts "hits = $hits"
set binarybass ""
foreach hit $hits {
  set hithigh [expr $hit/16]
  #set hitlow [expr $hit % 16]
  set binbass [format %04b $hithigh] 
  append binarybass $binbass
  puts -nonewline "$binbass "
  }
  set notebass [string map {1 F 0 x} $binarybass]
  puts "$binarybass $notebass"
foreach hit $hits {
  #set hithigh [expr $hit/16]
  set hitlow [expr $hit % 16]
  set binsnare [format %04b $hitlow] 
  append binarysnare $binsnare
  puts -nonewline "$binsnare "
  }
  set notesnare [string map {1 d 0 x} $binarysnare]
  puts "$binarysnare $notesnare"
  set snare "[split $notesnare {}]|"
  set bass "[split $notebass {}]|"

set outhandle [open "tmp.abc" "w"]
puts $outhandle $head
puts $outhandle "V:1
%%MIDI channel 10
%%MIDI drummap F 36
%%percmap F b-d-1
$bass"
puts $outhandle "V:2
%%MIDI channel 10
%%MIDI drummap d 38
%%percmap d a-s
$snare"
close $outhandle



