#drumloop.tcl
# This script generates the files grooves.csv and grooveFile.txt
# from a large collection of midi files. These files are the
# the input to the program uigroove.tcl
#
# uigroove.tcl is a user interface for analyzing the drum patterns
# in a large collection of midi files. A drum pattern or groove
# is a repeated pattern of length 4 beats which appears in the
# percussion channel of a midi file. The drum pattern is encoded
# in a character string of 4 numbers by 3 colons. For example
# 8:128:8:128 is a common groove.
# drumloop identifies these unique  patterns, determines their
# distribution (histogram), and identifies  the midi files where
# these patterns occur. The information is recorded in the txt
# files mentioned above.

# Here is a description of the files.
# grooves.csv
# Each line contains the groove code, number of occurrences in the
# midi data base, and the number of files containing instances of
# that groove. The grooves are in descending frequency order.
#
# grooveFile.txt
# name of the midi file and the grooves which appear at least
# 10 times in that midi file.  

# Drumloop.tcl works together with midistats  a program in C
# which is part of the abcmidi package.


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



global patcount

proc count_drum_grooves_for_file {} {
global filepatcount 
global patcount
global midifileList
set k 0
set rootfolder "/home/seymour/clean midi/"
set rootfolderbytes [string length $rootfolder]

set outhandle [open "grooveFile.txt" "w"]

foreach midifile $midifileList {
  if {[info exist filepatcount]} {unset filepatcount} 
  incr k
  if {[expr $k % 500] == 0} {puts $k}
  #if {$k > 300} break
  #puts $midifile
  set compactMidifile [string range $midifile $rootfolderbytes end]

  puts -nonewline $outhandle \"$compactMidifile\"

  set drumpats [get_midi_drum_pat $midifile]
#puts "drumpats = $drumpats"
  set drumpats [split $drumpats]
  set j 0
  set pat ""
  foreach i $drumpats {
    incr j
    if {$j == 4} {
       append pat $i
       #puts "pat = $pat"
       if {[info exist filepatcount($pat)]} {
          set filepatcount($pat) [expr $filepatcount($pat) + 1]
       } else {
          set filepatcount($pat) 1
       }
       if {[info exist patcount($pat)]} {
          set patcount($pat) [expr $patcount($pat) + 1]
       } else {
          set patcount($pat) 1
       }
     set j 0
     set pat ""
    } else {
    append pat $i:
      }
  }
output_file_grooves $outhandle
update_groove_file_references 
 }
close $outhandle
output_fileref
output_patcount
}


proc output_patcount {} {
global patcount
global filepatcount
global fileref
set patlist [array names patcount]
set patcountlist [list]
foreach pat $patlist {
  #if {$patcount($pat) > 400} {puts "$pat\t $patcount($pat)"}
  lappend patcountlist [list $pat $patcount($pat)]
  }
set patcountlist [lsort -index 1 -integer -decreasing $patcountlist]
set outhandle [open "grooves.csv" "w"]
foreach patitem $patcountlist {
  set pat [lindex $patitem 0]
  set patinstances [lindex $patitem 1]
  if {[info exist fileref($pat)]} {set filecount $fileref($pat)
    } else {
    set filecount 0
    }
  puts $outhandle "$pat,$patinstances,$filecount"
  if {[lindex $patitem 1] < 10} break
  }
close $outhandle
}


proc output_file_grooves {outhandle} {
global filepatcount
set patlist [array names filepatcount]
foreach pat $patlist {
  if {$pat == "0:0:0:0"} continue
  if {$filepatcount($pat) > 10} {puts -nonewline $outhandle ", $pat"}
  }
  puts $outhandle ""
}

proc update_groove_file_references {} {
# counts the number of midi files containing a particular groove pattern
# The function is called for each midi file and filepatcount is an
# array containing all the grooves local to that midi file. 
global filepatcount
global fileref
set patlist [array names filepatcount]
foreach pat $patlist {
  #if {$filepatcount($pat) < 10} continue
  if {[info exist fileref($pat)]} {
    incr fileref($pat)
    } else {
    set fileref($pat) 1
    }
  }
}

proc output_fileref {} {
# the global array fileref was created by update_groove_file_references
global filepatcount
global fileref
set patcountlist [list]
set patlist [array names fileref]
foreach pat $patlist {
  if {$fileref($pat) > 6} {
    lappend patcountlist [list $pat $fileref($pat)]
    }
  }
set patcountlist [lsort -index 1 -integer -decreasing $patcountlist]
set outhandle [open "groovefilereferences.txt" "w"]
foreach pat $patcountlist {
  puts $outhandle $pat
  }
close $outhandle
}


proc get_midi_drum_pat {midifile} {
 global midi exec_out
 global midilength
 global midifileList
 set midilength 0
 #puts "midifile = $midifile"
 set fileexist [file exist $midifile]
 #puts "get_midi_info_for: midifilein = $midi(midifilein) filexist = $fileexist"
 if {$fileexist} {
   set exec_options "[list $midifile ] -ppat"
   set cmd "exec ../midistats [list $midifile] -ppat"
   catch {eval $cmd} midi_info
   set exec_out $cmd\n$midi_info
   #update_console_page
   set pats [lindex [split $midi_info \n] 2]
   return $pats
   } else {
   set msg "Unable to find file $midifile" 
   puts $msg
   }
}

set rootfolder "/home/seymour/clean midi"
#inFolderLength is used for returning the file path relative
#to the root folder inFolder.
set inFolderLength  [string length $rootfolder]
incr inFolderLength
set midifileList [rglob $rootfolder *.mid]
# alphabetical sort
set midifileList [lsort $midifileList]

count_drum_grooves_for_file


