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
# corestats returns the number of tracks, ppqn, number of beats, and number
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

set inFolder "/home/seymour/clean midi"
#inFolderLength is used for returning the file path relative
#to the root folder inFolder.
set inFolderLength  [string length $inFolder]
incr inFolderLength
set midifileList [rglob $inFolder *.mid]
set midifileList [lsort $midifileList]

proc make_core {inFolderLength} {
global midifileList
set i 0
set outfile "MidiCoreStats.tsv"
set outhandle [open $outfile  w]
puts "outhandle = $outhandle"
puts $outhandle "file\tdefective\tntrks\tnchan\tppqn\tbpm\tlastEvent\tlastBeat"
foreach midi $midifileList {
set cmd "exec ../midistats [list $midi] -corestats"
set fname [string range $midi $inFolderLength end]
catch {eval $cmd} output
if {[string first "exited" $output] >= 0 ||\
    [string first "bad time" $output] >= 0 ||\
    [string first "Error" $output] >= 0} {
  set output "NaN\tNaN\tNaN\tNaN\tNaN\tNaN"
  puts $outhandle "$fname\t1\t$output"
  } else {
  puts $outhandle "$fname\t0\t$output"
  incr i
  #if {$i > 500} break
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
         if {[string first "Melody" $out] > 0} {
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


set programtext {"Acoustic Grand" "Bright Acoustic" "Electric Grand" "Honky-Tonk" 
"Electric Piano 1" "Electric Piano 2" "Harpsichord" "Clav" 
"Celesta" "Glockenspiel" "Music Box" "Vibraphone" 
"Marimba" "Xylophone" "Tubular Bells" "Dulcimer" 
"Drawbar Organ" "Percussive Organ" "Rock Organ" "Church Organ" 
"Reed Organ" "Accordian" "Harmonica" "Tango Accordian" 
"Acoustic Guitar (nylon)" "Acoustic Guitar (steel)" "Electric Guitar (jazz)" "Electric Guitar (clean)" 
"Electric Guitar (muted)" "Overdriven Guitar" "Distortion Guitar" "Guitar Harmonics" 
"Acoustic Bass" "Electric Bass (finger)" "Electric Bass (pick)" "Fretless Bass" 
"Slap Bass 1" "Slap Bass 2" "Synth Bass 1" "Synth Bass 2" 
"Violin" "Viola" "Cello" "Contrabass" 
"Tremolo Strings" "Pizzicato Strings" "Orchestral Strings" "Timpani" 
"String Ensemble 1" "String Ensemble 2" "SynthStrings 1" "SynthStrings 2" 
"Choir Aahs" "Voice Oohs" "Synth Voice" "Orchestra Hit" 
"Trumpet" "Trombone" "Tuba" "Muted Trumpet" 
"French Horn" "Brass Section" "SynthBrass 1" "SynthBrass 2" 
"Soprano Sax" "Alto Sax" "Tenor Sax" "Baritone Sax" 
"Oboe" "English Horn" "Bassoon" "Clarinet" 
"Piccolo" "Flute" "Recorder" "Pan Flute" 
"Blown Bottle" "Skakuhachi" "Whistle" "Ocarina" 
"Lead 1 (square)" "Lead 2 (sawtooth)" "Lead 3 (calliope)" "Lead 4 (chiff)" 
"Lead 5 (charang)" "Lead 6 (voice)" "Lead 7 (fifths)" "Lead 8 (bass+lead)" 
"Pad 1 (new age)" "Pad 2 (warm)" "Pad 3 (polysynth)" "Pad 4 (choir)" 
"Pad 5 (bowed)" "Pad 6 (metallic)" "Pad 7 (halo)" "Pad 8 (sweep)" 
"FX 1 (rain)" "FX 2 (soundtrack)" "FX 3 (crystal)" "FX 4 (atmosphere)" 
"FX 5 (brightness)" "FX 6 (goblins)" "FX 7 (echoes)" "FX 8 (sci-fi)" 
"Sitar" "Banjo" "Shamisen" "Koto" 
"Kalimba" "Bagpipe" "Fiddle" "Shanai" 
"Tinkle Bell" "Agogo" "Steel Drums" "Woodblock" 
"Taiko Drum" "Melodic Tom" "Synth Drum" "Reverse Cymbal" 
"Guitar Fret Noise" "Breath Noise" "Seashore" "Bird Tweet" 
"Telephone ring" "Helicopter" "Applause" "Gunshot" 
}


proc get_melody_parameters_for {filename channel} {
global programtext
set fullfilename [file join "../../clean_midi/" $filename]
#puts "fullfilename = $fullfilename"
set cmd "exec ../midistats [list $fullfilename]" 
catch {eval $cmd} output
set output [split $output '\n]
#puts $output
foreach line $output {
  set line [split $line " "]
  set type [lindex $line 0]
  if {$type == "trkinfo"} {
    set c [lindex $line 1]
    if {$c == $channel} {
     #puts $line
     set prg [lindex $line 2]
     set prgtext [lindex $programtext $prg]
     set notes [lindex $line 3]
     set chordnotes [lindex $line 4]
     set allnotes [expr $notes + $chordnotes]
     set pavg [expr round ([lindex $line 5] / double($allnotes))]
     set rpat [lindex $line 10]
     puts \"$filename\",$prg,$prgtext,$allnotes,$chordnotes,$pavg,$rpat
     }
   }
 }
}


proc get_all_melody_parameters_for {filename channel} {
global programtext
global ppqn
set fullfilename [file join "../../clean_midi/" $filename]
#puts "fullfilename = $fullfilename"
set cmd "exec ../midistats [list $fullfilename]" 
catch {eval $cmd} output
set output [split $output '\n]
#puts $output
foreach line $output {
  set line [split $line " "]
  set type [lindex $line 0]
  if {$type == "ppqn"} {
     set ppqn [lindex $line 1]
     }
  if {$type == "trkinfo"} {
    set c [lindex $line 1]
    if {$c == $channel} {
         set melody "T"
       } else {
         set melody "F"
       }
    if {$c == 10} continue
     set prg [lindex $line 2]
     set prgtext [lindex $programtext $prg]
     set notes [lindex $line 3]
     set chordnotes [lindex $line 4]
     set allnotes [expr $notes + $chordnotes]
     set pavg [expr round ([lindex $line 5] / double($allnotes))]

     set pitchmin [lindex $line 11]
     set pitchmax [lindex $line 12]
     set pitchrange [expr $pitchmax - $pitchmin]

     set dur [lindex $line 6]
     set dur [expr $dur / $allnotes]
     set dur [expr double($dur) / $ppqn]
     set dur [format %5.3f $dur]

     set rpat [lindex $line 10]
     if {$notes > 0} {
       set rcrit [expr round(200.0 * $rpat / $notes)]
       } else {set rcrit 0}

     set chordratio [expr $notes / double($allnotes)]
     set chordratio [format %3.2f $chordratio]

     set zeros [lindex $line 16]
     set steps [lindex $line 17]
     set jumps [lindex $line 18]
     set nonsteps [expr $zeros + $jumps]
     if {$nonsteps > 0} {
      set stepscriterion [expr $steps/double($nonsteps)]
      } else {set stepscriterion  0.0}
     set stepscriterion [format %5.3f $stepscriterion]

     puts \"$filename\",$melody,$prg,$prgtext,$notes,$chordratio,$pavg,$pitchrange,$rpat,$dur,$steps
   }
 }
}


proc extract_melody_parameters {} {
set melodyhandle [open "/home/seymour/abc/midiexplorer/melody.txt" r]
set i 0
#puts "file,ismelody,program,instrument,notes,chordratio,avgpitch,pitchrange,rpat,stepscrit,dur"
puts "file,ismelody,program,instrument,notes,chordratio,avgpitch,pitchrange,rpat,dur,steps"
while {[gets $melodyhandle line] >= 0} {
  set linedata [split $line \t]
  set filename [lindex $linedata 0]
  set channel [lindex [lindex $linedata 1] 0]
  #puts "file = $filename channel = $channel"
  #get_melody_parameters_for $filename  $channel 
  get_all_melody_parameters_for $filename  $channel 
  incr i
  if {$i > 3300} break
  }
close $melodyhandle
}

proc load_progMelProb {} {
global progMelProb
set inhandle [open "progMelProb.csv" r]
while {[gets $inhandle line] >= 0} {
  set linedata [split $line ',']
  set p [lindex $linedata 0]
  set prob [lindex $linedata 1]
  set progMelProb($p) $prob
  }
close $inhandle
#puts "set progMel "
#for {set i 0} {$i < 128} {incr i} {
#  set prgProb [expr round(100.0*$progMelProb($i))] 
#  puts -nonewline "$prgProb "
#  }
#puts "\n"
}

proc get_melody_step_parameters_for {filename channel} {
global programtext
global ppqn
global progMelProb
set fullfilename [file join "../../clean_midi/" $filename]
#puts "fullfilename = $fullfilename"
set cmd "exec ../midistats [list $fullfilename]" 
catch {eval $cmd} output
set output [split $output '\n]
#puts $output
foreach line $output {
  set line [split $line " "]
  set type [lindex $line 0]
  if {$type == "ppqn"} {
     set ppqn [lindex $line 1]
     }
  if {$type == "trkinfo"} {
    set c [lindex $line 1]
    if {$c == $channel} {
         set melody "T"
       } else {
         set melody "F"
       }
    if {$c == 10} continue

     set chn [lindex $line 1]
     set prg [lindex $line 2]
     set n [lindex $line 3]
     set h [lindex $line 4]
     set totalpitches [lindex $line 5]
     set pavg [expr $totalpitches/($n + $h)]
     set prgProb $progMelProb($prg)
     set prgProb [expr round(100.0*$prgProb)] 
     set rpat  [lindex $line 10]
     set zeros [lindex $line 17]
     set steps [lindex $line 18]
     set jumps [lindex $line 19]

     puts \"$filename\",$chn,$melody,$prgProb,$rpat,$zeros,$steps,$jumps,$pavg
   }
 }
}

proc extract_melody_step_parameters {} {
load_progMelProb
set melodyhandle [open "/home/seymour/abc/midiexplorer/melody.txt" r]
set i 0
puts "file,chn,ismelody,prgP,rpat,zeros,steps,jumps,pavg"
while {[gets $melodyhandle line] >= 0} {
  set linedata [split $line \t]
  set filename [lindex $linedata 0]
  set channel [lindex [lindex $linedata 1] 0]
  #puts "file = $filename channel = $channel"
  #get_melody_parameters_for $filename  $channel 
  get_melody_step_parameters_for $filename  $channel 
  incr i
  if {$i > 3300} break
  #if {$i > 3} break
  }
close $melodyhandle
}

proc gather_derived_stats {inFolderLength} {
global midifileList
set i 0
set outfile "derivedstats.csv"
set outhandle [open $outfile  w]
puts "outhandle = $outhandle"
puts $outhandle "file\ttempocounts\tquantizer\tpplexity\tkeysig"
foreach midi $midifileList {
set cmd "exec ../midistats [list $midi]" 
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
  set quantizer "u"
  foreach line $outputlines {
    #puts $line
    if {[string first "tempocmds" $line] == 0} {
      set tempocounts  [lindex $line 1]
       }
    if {[string first "unquantized" $line] == 0} {
      set quantizer "n"
      }
    if {[string first "dithered_quantization" $line] == 0} {
      set quantizer "d"
      }
    if {[string first "clean_quantization" $line] == 0} {
      set quantizer "c"
      }
    if {[string first "pitchperplexity" $line] == 0} {
      set entropy  [lindex $line 1]
      set pperplexity [expr 2 ** $entropy]
       }
    if {[string first "key" $line] == 0} {
      set keysig  [lindex $line 1]
      set confidence [lindex $line 3]
      if {$confidence < 0.4} {set keysig "u"}
      }
  }
 incr i
 if {[expr $i  % 1000] == 0} {puts $i}
 puts $outhandle "$fname\t$tempocounts\t$quantizer\t$entropy\t$keysig"
 }
}
close $outhandle
}


#make_programcolorCdf $inFolderLength
#make_programcolor $inFolderLength
#make_pulseanalysis $inFolderLength
#make_perc_structure $inFolderLength
#make_core $inFolderLength
#make_pitchanalysis $inFolderLength
#find_melody_labels $inFolderLength
#extract_melody_parameters
#extract_melody_step_parameters 
#gather_derived_stats $inFolderLength

