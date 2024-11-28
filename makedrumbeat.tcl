#makedrumbeat.tcl
#!/bin/sh
#

#This program creates the files drumbeat.csv and filenames4drumbeat.txt
#drumbeat.csv contains a normalized histogram of the most common beat
#code words for each file. These frequent code words are listed in the file
#groovebeatfreq.csv. These files are used for the python programs
#in jupyter notebooks to correct umap and hdbscan representations.

set freqbeatcodes { 8 128 130 136 10 2 1 16 40 129\
 9 32 160 24 4 138}




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


set os $tcl_platform(platform)
if {$os == "unix"} {
  set rootfolder  "/home/seymour/clean midi/"
  set midistats_path "../midistats"
} else {
  set rootfolder "C:/Users/fy733/Music/lakh clean midi"
  set midistats_path "C:/Users/fy733/OneDrive/Documents/abc/tcl/midistats.exe"
}
 if {![file exist $midistats_path]} {
   tk_messageBox -message "cannot find $midistats_path" -type ok
   exit
   }



proc count_drum_grooves_for_file {} {
global filepatcount 
global midifileList
global rootfolder
set k 0
#set rootfolder "/home/seymour/clean midi/"
set rootfolderbytes [string length $rootfolder]

set outhandle [open "drumbeat.csv" "w"]
set outhandlefilename [open "filenames4drumbeat.txt" "w"]

foreach midifile $midifileList {
  if {[info exist filepatcount]} {unset filepatcount} 
  incr k
  if {[expr $k % 500] == 0} {
     puts $k
     update
     }
  #if {$k > 5} break
  #puts $midifile
  set compactMidifile [string range $midifile $rootfolderbytes end]

  puts $outhandlefilename \"$compactMidifile\"

  set drumpats [get_midi_drum_pat $midifile]
  set drumpatsize [llength $drumpats]
#puts "drumpats = $drumpats"
  set drumpats [split $drumpats]
  foreach i $drumpats {
     if {[info exist filepatcount($i)]} {
        set filepatcount($i) [expr $filepatcount($i) + 1]
       } else {
          set filepatcount($i) 1
       }
  }
output_file_grooves $outhandle $drumpatsize
 }
close $outhandle
}



proc output_file_grooves {outhandle drumpatsize} {
global filepatcount
global freqbeatcodes
set line ""
foreach code $freqbeatcodes {
  if {[info exist filepatcount($code)]} {
    set probability [format "%4.2f" [expr $filepatcount($code)/double($drumpatsize)]]
    append line "$probability,"
    } else {
    append line "0.00,"
    }
 }
set line [string range $line 0 end-1]
puts $outhandle $line
#puts $line
}

proc get_midi_drum_pat {midifile} {
 global midi exec_out
 global midilength
 global midifileList
 global midistats_path
 set midilength 0
 #puts "midifile = $midifile"
 set fileexist [file exist $midifile]
 #puts "get_midi_info_for: midifilein = $midi(midifilein) filexist = $fileexist"
 if {$fileexist} {
   set exec_options "[list $midifile ] -ppat"
   set cmd "exec $midistats_path [list $midifile] -ppat"
   catch {eval $cmd} midi_info
   #puts "midi_info = $midi_info"
   set exec_out $cmd\n$midi_info
   #update_console_page
   set pats [lindex [split $midi_info \n] 2]
   return $pats
   } else {
   set msg "Unable to find file $midifile" 
   puts $msg
   }
}

#set rootfolder "/home/seymour/clean midi"
#inFolderLength is used for returning the file path relative
#to the root folder inFolder.
#set inFolderLength  [string length $rootfolder]
#incr inFolderLength
set midifileList [rglob $rootfolder *.mid]
# alphabetical sort
set midifileList [lsort $midifileList]

count_drum_grooves_for_file


