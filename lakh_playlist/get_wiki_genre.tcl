# get_wiki_genre.tcl

package require http
package require tls
http::register https 443 ::tls::socket

proc getgenre {htmldata} {
global genre_db
set pat {"[^"]*"}
set loc [string first "Music genre" $htmldata 0]
if {$loc < 1} {return "unknown"}
#puts [string range $htmldata $loc [expr $loc+60]]
set loc [string first "title=" $htmldata [expr $loc + 20]]
#puts "loc = $loc"
set genre_string [string range $htmldata $loc [expr $loc +40]]
#puts "genre_string = $genre_string"
set success [regexp -indices $pat $genre_string match]
#puts "success = $success"
if {$success == 1} {
  set pos1 [lindex $match 0]
  set pos2 [lindex $match 1]
  set genre [string range $genre_string $pos1 $pos2]
  } else {
  set genre "unknown"
  }
return $genre
}

# main
set inhandle [open "genre.tsv" "r"]
set outhandle [open "cgenre.tsv" "w"]
set contents [read $inhandle]
close $inhandle
set contents [split $contents \n]
set i 0
foreach line $contents {
  incr i
  puts $i
  set originalLine $line
  set line [split $line \t]
  set g [lindex $line 1]
  if {($g == 0 || $g == "unknown") &&
    ([string first "%" $line] < 0) &&
    ([string first "\[" $line] < 0) } {
    set tune [lindex $line 0]
    set song [split $tune / ]
    set song [lindex $song end]
    set song [string map {{ } _} $song]
    set url "https://en.wikipedia.org/wiki/$song"
    #puts "url = $url"
    set webpage [http::geturl $url]
    upvar #0 $webpage state
    set body $state(body)
    #puts "body length = [string length $body]"
    set genre [getgenre $body]
    if {$genre == "unknown"} {
      puts $outhandle $originalLine
      } else {
      puts $outhandle "$tune\t$genre"
      }

    } else {
    puts $outhandle $originalLine
    }
#if {$i > 100} break
}
close $outhandle


