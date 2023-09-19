# runstats.tcl
# runs midistats on all files in clean_midi folder
# and records percussion statistics in output files
# for future analysis.
#
# pulsenalysis computes the histogram of all note onsets
# inside a beat and returns it as a 12 dimensional vector.
# This distingishes the complexity of the rhythms. (i.e.
# presence of eighth notes or triplets)
#
# corestats returns the ppqn, number of beats, and number
# of note onsets for each file. This information is useful
# to ensure that enough space is available to analyze this
# data.
#
#

proc rglob { basedir pattern } {
  # Fix the directory name, this ensures the directory name is in the
  # native format for the platform and contains a final directory seperator
  set basedir [string trimright [file join [file normalize $basedir] { }]]
  set fileList {}

  # Look in the current directory for matching files, -type {f r}
  # means ony readable normal files are looked at, -nocomplain stops
  # an error being thrown if the returned list is empty
  foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
                        lappend fileList $fileName
                }

  # Now look for any sub direcories in the current directory
  foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
       # Recusively call the routine on the sub directory and append any
       # new files to the results
       set subDirList [rglob $dirName $pattern]
       if { [llength $subDirList] > 0 } {
               foreach subDirFile $subDirList {
                        lappend fileList $subDirFile
                        }
          }
       }
  return $fileList
  }

set inFolder "/home/seymour/clean_midi"
#inFolderLength is used for returning the file path relative
#to the root folder inFolder.
set inFolderLength  [string length $inFolder]
incr inFolderLength
set midifileList [rglob $inFolder *.mid]
set midifileList [lsort $midifileList]

proc make_core {inFolderLength} {
global midifileList
set i 0
set outfile "core.tsv"
set outhandle [open $outfile  w]
puts "outhandle = $outhandle"
foreach midi $midifileList {
set cmd "exec ../midistats [list $midi] -corestats"
set fname [string range $midi $inFolderLength end]
catch {eval $cmd} output
if {[string first "exited" $output] > 0} {
  puts "$fname $output"
  } else {
  puts $outhandle $fname\t$output
  incr i
  #if {$i > 200} break
  }
}
close $outhandle
}


proc make_pulseanalysis {inFolderLength} {
global midifileList
set i 0
set outfile "pulse12.csv"
set outnames "filenames4pulses.txt"
set outhandle [open $outfile  w]
set outhandlenames [open $outnames w]
puts "outhandle = $outhandle"
foreach midi $midifileList {
set cmd "exec midistats [list $midi] -pulseanalysis"
set fname [string range $midi $inFolderLength end]
catch {eval $cmd} output
if {[string first "exited" $output] > 0 ||
    [string first "premature" $output] >0 ||
    [string first "MTrk" $output] >0 ||
    [string first "MThd" $output] >0 ||
    [string first "time" $output] > 0 ||
    [string first "unexpected" $output] > 0} {
  puts "$fname $output"
  } else {
  #puts $outhandle $fname$output
  puts $outhandle $output
  puts $outhandlenames $fname
  incr i
  if {[expr $i  % 200] == 0} {puts $i}
  }
}
close $outhandle
close $outhandlenames
}

proc make_pitchanalysis {inFolderLength} {
global midifileList
set i 0
set outfile "pitchclass.csv"
set outnames "filenames4pitches.txt"
set outhandle [open $outfile  w]
#puts $outhandle "i, C,C#,D,D#,E,F,F#,G,G#,A,A#,B"
set outhandlenames [open $outnames w]
#puts "outhandle = $outhandle"
foreach midi $midifileList {
set cmd "exec midistats [list $midi] -pitchclass"
set fname [string range $midi $inFolderLength end]
catch {eval $cmd} output
if {[string first "exited" $output] > 0 ||
    [string first "premature" $output] >0 ||
    [string first "MTrk" $output] >0 ||
    [string first "MThd" $output] >0 ||
    [string first "time" $output] > 0 ||
    [string first "unexpected" $output] > 0} {
  puts "$fname $output"
  } else {
  #puts $outhandle $fname$output
  if {[string first -nan $output] >= 0} {
	  puts "$fname only percussion channel"
	  continue
  }
#  puts $outhandle $i,$output
   puts $outhandle $output
  puts $outhandlenames $fname
  incr i
  if {[expr $i  % 200] == 0} {puts $i}
  }
}
close $outhandle
close $outhandlenames
}

proc make_programcolor {inFolderLength} {
global midifileList
set i 0
set outfile "programcolor.csv"
set outnames "filenames4programcolor.txt"
set outhandle [open $outfile  w]
set outhandlenames [open $outnames w]
puts "outhandle = $outhandle"
foreach midi $midifileList {
set cmd "exec midistats [list $midi]" 
catch {eval $cmd} output
if {[string first "exited" $output] > 0 ||
    [string first "premature" $output] >0 ||
    [string first "bad time" $output] >0 ||
    [string first "expecting MThd" $output] > 0 ||
    [string first "unexpected" $output] > 0} {
  #puts "$fname $output"
  } else {
  #puts $outhandle $fname$output
  set outputlines [split $output \n]
  set fname [string range $midi $inFolderLength end]
  foreach line $outputlines {
    if {[string first progcolor $line] == 0} {
      set out [string range $line 10 end]
      set out [replaceSpacesWithCommas $out]
      puts $outhandle $out
      puts $outhandlenames $fname
     }
  }
  incr i
  if {[expr $i  % 200] == 0} {puts $i}
}
}
close $outhandle
close $outhandlenames
}

proc make_programcolorCdf {inFolderLength} {
global midifileList
set i 0
set outfile "programcolorCdf.csv"
set outnames "filenames4programcolor.txt"
set outhandle [open $outfile  w]
set outhandlenames [open $outnames w]
puts "outhandle = $outhandle"
foreach midi $midifileList {
set cmd "exec midistats [list $midi]" 
catch {eval $cmd} output
if {[string first "exited" $output] > 0 ||
    [string first "premature" $output] >0 ||
    [string first "bad time" $output] >0 ||
    [string first "expecting MThd" $output] > 0 ||
    [string first "unexpected" $output] > 0} {
  #puts "$fname $output"
  } else {
  #puts $outhandle $fname$output
  set outputlines [split $output \n]
  set fname [string range $midi $inFolderLength end]
  foreach line $outputlines {
    if {[string first progcolor $line] == 0} {
      set out [string range $line 10 end]
      set out [compute_cumulative_distribution $out]
      set out [replaceSpacesWithCommas $out]
      puts $outhandle $out
      puts $outhandlenames $fname
     }
  }
  incr i
  if {[expr $i  % 200] == 0} {puts $i}
}
}
close $outhandle
close $outhandlenames
}

proc compute_cumulative_distribution {data} {
set total 0.0
set df {}
foreach value $data {
  set total [expr $value + $total]
  lappend df $total
  }
if {$total < 0.001} {return $data}
set out {}
foreach value $df {
  set value [expr 1000.0*$value/$total]
  set value [expr round($value)/1000.0]
  lappend out $value
  }
return $out
}
  


# we can run with either -ppat or -ppathist. If
# you call this function, the output goes to stdout.
# You should direct the output to a csv file.
proc make_perc_structure {inFolderLength} {
global midifileList
set i 0
foreach midi $midifileList {
  incr i
  set fname [string range $midi $inFolderLength end]
  set cmd "exec ../midistats [list $midi] -ppathist"
  catch {eval $cmd} output
  puts $fname
  puts $output
  }
}

proc find_melody_labels {inFolderLength} {
global midifileList
set i 0
foreach midi $midifileList {
  incr i
  set fname [string range $midi $inFolderLength end]
  set cmd "exec ../midistats [list $midi]"
  catch {eval $cmd} output
  set output [split $output \n]
  set melodyfound 0
  foreach line $output {
    if {[string first "trk" $line] >= 0} {
      set trk [lindex $line 1]
      }
    if {[string first "metatext" $line] >= 0} {
         set out [string range $line 10 end]
         if {[string first "MELODY" $out] > 0} {
            #puts $midi
            #puts $trk
            set melodyfound 1}
         }
    if {[string first "program" $line] >= 0} {
      set channel [lindex $line 1]
      set prog [lindex $line 2]
      if {$melodyfound} {
         set fname [string range $midi $inFolderLength end]
         puts "$fname\t$channel $prog"
         set melodyfound 0
         }
      }
  }
  if {$i > 17200} break
  }
puts "done"
}

proc replaceSpacesWithCommas {datavalues} {
set output ""
foreach value $datavalues {
  append output $value,
  }
#remove trailing comma
set output [string range $output 0 end-1]
return $output
}

#make_programcolorCdf $inFolderLength
#make_programcolor $inFolderLength
#make_pulseanalysis $inFolderLength
#make_perc_structure $inFolderLength
#make_pitchanalysis $inFolderLength
find_melody_labels $inFolderLength
