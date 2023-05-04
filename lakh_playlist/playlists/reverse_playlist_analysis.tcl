#reverseplaylistanalysis.tcl
#This script extracts the names of all the folders in the
#clean lakh midi dataset which are referenced in all the
#*.txt files. It puts the list of folder names in the file
#../artistlist.txt
set filelist [glob *.txt]
set i 0
set fullartistlist {}
foreach filename $filelist {
	puts $filename
	#if {$i > 5} break
	incr i
	set inhandle [open $filename r]
	set contents [read $inhandle]
	close $inhandle
	set localartistlist [split $contents \n]
	foreach artist $localartistlist {
		#puts $artist
		if {[string length $artist] < 1} continue
		if {[lsearch $fullartistlist $artist] < 0} {
			lappend fullartistlist [list $artist $filename]
		}
	}
	set fullartistlist [lsort $fullartistlist]

}
        set outhandle [open ../artistlist.txt  w]
	foreach artist  $fullartistlist {
	   puts $outhandle $artist
        }
	close $outhandle


