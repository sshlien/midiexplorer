#groove2abc.tcl

set groove "8:152:8:136"
#puts "enter groove code:"
#gets stdin groove
puts "groove = $groove"

proc has16thnotes {n} {
  set z [expr $n & 5592405]
  # binary of 5592405 = 10101010101010101010101
  if {$z != 0} {set z 1}
  return $z
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

  


set hits [split $groove :]
puts "hits = $hits"
set binarybass ""
set has16th 0
foreach hit $hits {
  set hithigh [expr $hit/16]
  set binsnare [format %04b $hithigh] 
  append binarysnare $binsnare
  puts -nonewline "$binsnare "
  set has16th  [expr $has16th || [has16thnotes $hithigh]]
  }
  puts -nonewline " snare "
  puts ""
foreach hit $hits {
  set hitlow [expr $hit % 16]
  set binbass [format %04b $hitlow] 
  append binarybass $binbass
  set has16th  [expr $has16th || [has16thnotes $hitlow]]
  puts -nonewline "$binbass "
  }
  puts -nonewline " bass "
  puts ""
  set notesnare [string map {1 d 0 x} $binarysnare]
  set notebass [string map {1 F 0 x} $binarybass]
  puts "has16th = $has16th"
  puts "$binarybass $notebass"
  puts "$binarysnare $notesnare"
  set snare "[split $notesnare {}]|"
  set bass "[split $notebass {}]|"

  if {$has16th == 0} {
    set snare [chopoff16thnotes $snare] 
    set bass  [chopoff16thnotes $bass] 
    set L 1/8
  } else {
    set L 1/16
    }

  set c [combineSnareAndBass $snare $bass $has16th]

set head "X:1
T: $groove
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
$c|"
close $outhandle



