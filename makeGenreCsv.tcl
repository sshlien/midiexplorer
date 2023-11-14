set midi(rootfolder) /home/seymour/clean_midi/

proc load_genre_database {} {
global genre_db
global midi
set genrefile $midi(rootfolder)/genre.tsv
#puts "genrefile = $genrefile"
if {![file exist $genrefile]} {
   appendInfoError "cannot find $genrefile"
   return
   }
set i 0
set inhandle [open $genrefile]
while {![eof $inhandle]} {
  gets $inhandle line
  set data [split $line \t]
  set f [lindex $data 0]
  set g [lindex $data 1]
  set genre_db($f) $g
  incr i
  }
close $inhandle
}

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

proc lakh_core_filename {midiname} {
#assumes clean lakh midi filename convention
set midiname [string range $midiname 0 end-4]
set l [string length $midiname]
set l [expr $l -1]
set last [string index $midiname $l]
set l1 [expr $l -1]
set l2 [expr $l -2]
set last1 [string index $midiname $l1]
set last2 [string index $midiname $l2]
#puts "last1 = $last1 last2=$last"
if {[string is integer $last1] && ($last2 == ".")} {
 set midiname [string range $midiname 0 [expr $l1 -2] ]
 } elseif {[string is integer $last] && ($last1 == ".")} {
 set midiname [string range $midiname 0 [expr $l -2] ]
 }
return $midiname
}



proc blowup_genre_csv {} {
global midifileList
global inFolderLength
global genre_db
set outhandle [open fullGenre.csv w]
puts $outhandle "file\tgenre"
set i 0
foreach midifile $midifileList {
  set filename [string range $midifile $inFolderLength end]
  set shortname [lakh_core_filename $filename]
  puts $outhandle "$filename\t$genre_db($shortname)"
  incr i
  #if {$i > 5} break
  }
close $outhandle
}

load_genre_database
blowup_genre_csv

