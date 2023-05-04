#package provide app-midiexplorer 1.0
#   MidiExplorer
#!/bin/sh
# the next line restarts using wish \
exec wish8.6 "$0" "$@"

global midiexplorer_version
set midiexplorer_version "MidiExplorer version 4.01 2023-05-04 10:45" 
set briefconsole 1

# Copyright (C) 2019-2022 Seymour Shlien
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# Original page:
#      http://ifdo.ca/~seymour/runabc/top.html

# Table of Contents
#
#   Part 1.0 Initialize, Save, Read state midipage.ini
#   Part 2.0  Main Window
#        file menu button
#        view menubutton
#        utilities menubutton
#        pitch/rhythm analysis button (plots)
#        global analysis menubutton (plots)
#        find title button
#        main help button
#        message line
#        font selector
#        tooltips switch
#   Part 3.0 Directory Structure Tree View
#        rglob, populatedir, populateTree
#   Part 4.0 Midi summary listing in table form
#   Part 5.0 Midi summary header
#        presentMidiInfo, interpret_midi...,tinfoSelect
#   Part 6.0 Midi file selection support
#        selected_midi,  readMidiFileHeader,
#        get_midi_info_for, parse_midi_info, get_trkinfo,
#        midi_type0_table, midiType1Table
#   Part 7.0 Program selector and support
#   Part 8.0 Piano Roll window
#         beat graph
#         chord histogram
#         chordgram plot 
#         notegram plot
#   Part 9.0 Midistructure window and support
#   Part 10.0 Drum Roll Window
#   Part 11.0 Midi Statistics for Pianoroll and DrumRoll
#   Part 12.0 Graphics Package (Namespace)
#   Part 13.0 Mftext user interface
#   Part 14.0 Database creation functions and search
#         make_midi_database, get_midi_features, load_desc,
#         search_window, searchname, searchtempo, searchprogs,
#         searchperc, searchex, searchbends, matchprogs, etc.
#   Part 15.0 Screen Layout (getGeometryOfAllToplevels)
#   Part 16.0 Track/Channel analysis
#         get_note_patterns {}, analyze_note_patterns {},
#         dictview_window {}, dictlistp {dictdata dicthist},
#         binary_to_pitchclasses {binaryvector}, get_all_note_patterns,
#         full_notedata_analysis
#   Part 17.0 Playlist support
#   Part 18.0 google_search
#   Part 19.0 abc file
#   Part 20.0 Pgram
#   Part 21.0 Key map
#   Part 22.0 PercMap
#   Part 23.0 PitchClass Map
#   Part 24.0 Console Support
#   Part 25.0 internals
#   Part 26.0 aftertouch
#   Part 27.0 notebook
#

set welcome "Welcome to $midiexplorer_version. This application\
is designed to provide a means of exploring a large collection\
of midi files. The program is still in the development phase.\
The program saves its state in a text file called midiexplorer.ini.\
The program requires the latest version of midi2abc and midicopy executables\
in order to run properly. If the executables midi2abc and\
midicopy are not in the same folder as this script, you will\
need to specify their path using the file/support programs\
menu item.

When you start the program for the first time, you need to specify\
the path to the folder containing your collection of midifiles,\
using the file/root directory menu command. Once this folder path\
is displayed, click on the arrow or + to browse through this\
folder and select a particular midi file. The view menu on the\
top provides different graphical representations for the file."


# tooltip.tcl --
#
#       Balloon help
#
# Copyright (c) 1996-2003 Jeffrey Hobbs
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# RCS: @(#) $Id: tooltip.tcl,v 1.5 2005/11/22 00:55:07 hobbs Exp $
#
# Initiated: 28 October 1996


package require Tk 8.5
package provide tooltip 1.1


#------------------------------------------------------------------------
# PROCEDURE
#	tooltip::tooltip
#
# DESCRIPTION
#	Implements a tooltip (balloon help) system
#
# ARGUMENTS
#	tooltip <option> ?arg?
#
# clear ?pattern?
#	Stops the specified widgets (defaults to all) from showing tooltips
#
# delay ?millisecs?
#	Query or set the delay.  The delay is in milliseconds and must
#	be at least 50.  Returns the delay.
#
# disable OR off
#	Disables all tooltips.
#
# enable OR on
#	Enables tooltips for defined widgets.
#
# <widget> ?-index index? ?-item id? ?message?
#	If -index is specified, then <widget> is assumed to be a menu
#	and the index represents what index into the menu (either the
#	numerical index or the label) to associate the tooltip message with.
#	Tooltips do not appear for disabled menu items.
#	If message is {}, then the tooltip for that widget is removed.
#	The widget must exist prior to calling tooltip.  The current
#	tooltip message for <widget> is returned, if any.
#
# RETURNS: varies (see methods above)
#
# NAMESPACE & STATE
#	The namespace tooltip is used.
#	Control toplevel name via ::tooltip::wname.
#
# EXAMPLE USAGE:
#	tooltip .button "A Button"
#	tooltip .menu -index "Load" "Loads a file"
#
#------------------------------------------------------------------------

namespace eval ::tooltip {
    namespace export -clear tooltip
    variable tooltip
    variable G
    
    array set G {
        enabled		1
        DELAY		500
        AFTERID		{}
        LAST		-1
        TOPLEVEL	.__tooltip__
    }
    
    # The extra ::hide call in <Enter> is necessary to catch moving to
    # child widgets where the <Leave> event won't be generated
    bind Tooltip <Enter> [namespace code {
        #tooltip::hide
        variable tooltip
        variable G
        set G(LAST) -1
        if {$G(enabled) && [info exists tooltip(%W)]} {
            set G(AFTERID) \
                    [after $G(DELAY) [namespace code [list show %W $tooltip(%W) cursor]]]
        }
    }]
    
    bind Menu <<MenuSelect>>	[namespace code { menuMotion %W }]
    bind Tooltip <Leave>	[namespace code hide]
    bind Tooltip <Any-KeyPress>	[namespace code hide]
    bind Tooltip <Any-Button>	[namespace code hide]
}

proc ::tooltip::tooltip {w args} {
    variable tooltip
    variable G
    switch -- $w {
        clear	{
            if {[llength $args]==0} { set args .* }
            clear $args
        }
        delay	{
            if {[llength $args]} {
                if {![string is integer -strict $args] || $args<50} {
                    return -code error "tooltip delay must be an\
                            integer greater than 50 (delay is in millisecs)"
                }
                return [set G(DELAY) $args]
            } else {
                return $G(DELAY)
            }
        }
        off - disable	{
            set G(enabled) 0
            hide
        }
        on - enable	{
            set G(enabled) 1
        }
        default {
            set i $w
            if {[llength $args]} {
                set i [uplevel 1 [namespace code "register [list $w] $args"]]
            }
            set b $G(TOPLEVEL)
            if {![winfo exists $b]} {
                toplevel $b -class Tooltip
                if {[tk windowingsystem] eq "aqua"} {
                    ::tk::unsupported::MacWindowStyle style $b help none
                } else {
                    wm overrideredirect $b 1
                }
                wm positionfrom $b program
                wm withdraw $b
                label $b.label -highlightthickness 0 -relief solid -bd 1 \
                        -background lightyellow -fg black -justify left
                pack $b.label -ipadx 1
            }
            if {[info exists tooltip($i)]} { return $tooltip($i) }
        }
    }
}

proc ::tooltip::register {w args} {
    variable tooltip
    set key [lindex $args 0]
    while {[string match -* $key]} {
        switch -- $key {
            -index	{
                if {[catch {$w entrycget 1 -label}]} {
                    return -code error "widget \"$w\" does not seem to be a\
                            menu, which is required for the -index switch"
                }
                set index [lindex $args 1]
                set args [lreplace $args 0 1]
            }
            -item	{
                set namedItem [lindex $args 1]
                if {[catch {$w find withtag $namedItem} item]} {
                    return -code error "widget \"$w\" is not a canvas, or item\
                            \"$namedItem\" does not exist in the canvas"
                }
                if {[llength $item] > 1} {
                    return -code error "item \"$namedItem\" specifies more\
                            than one item on the canvas"
                }
                set args [lreplace $args 0 1]
            }
            default	{
                return -code error "unknown option \"$key\":\
                        should be -index or -item"
            }
        }
        set key [lindex $args 0]
    }
    if {[llength $args] != 1} {
        return -code error "wrong \# args: should be \"tooltip widget\
                ?-index index? ?-item item? message\""
    }
    if {$key eq ""} {
        clear $w
    } else {
        if {![winfo exists $w]} {
            return -code error "bad window path name \"$w\""
        }
        if {[info exists index]} {
            set tooltip($w,$index) $key
            #bindtags $w [linsert [bindtags $w] end "TooltipMenu"]
            return $w,$index
        } elseif {[info exists item]} {
            set tooltip($w,$item) $key
            #bindtags $w [linsert [bindtags $w] end "TooltipCanvas"]
            enableCanvas $w $item
            return $w,$item
        } else {
            set tooltip($w) $key
            bindtags $w [linsert [bindtags $w] end "Tooltip"]
            return $w
        }
    }
}

proc ::tooltip::clear {{pattern .*}} {
    variable tooltip
    foreach w [array names tooltip $pattern] {
        unset tooltip($w)
        if {[winfo exists $w]} {
            set tags [bindtags $w]
            if {[set i [lsearch -exact $tags "Tooltip"]] != -1} {
                bindtags $w [lreplace $tags $i $i]
            }
            ## We don't remove TooltipMenu because there
            ## might be other indices that use it
        }
    }
}

proc ::tooltip::show {w msg {i {}}} {
    # Use string match to allow that the help will be shown when
    # the pointer is in any child of the desired widget
    if {![winfo exists $w] || ![string match $w* [eval [list winfo containing] [winfo pointerxy $w]]]} {
        return
    }
    
    variable G
    
    set b $G(TOPLEVEL)
    $b.label configure -text $msg
    update idletasks
    if {$i eq "cursor"} {
        set y [expr {[winfo pointery $w]+20}]
        if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
            set y [expr {[winfo pointery $w]-[winfo reqheight $b]-5}]
        }
    } elseif {$i ne ""} {
        set y [expr {[winfo rooty $w]+[winfo vrooty $w]+[$w yposition $i]+25}]
        if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
            # show above if we would be offscreen
            set y [expr {[winfo rooty $w]+[$w yposition $i]-\
                        [winfo reqheight $b]-5}]
        }
    } else {
        set y [expr {[winfo rooty $w]+[winfo vrooty $w]+[winfo height $w]+5}]
        if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
            # show above if we would be offscreen
            set y [expr {[winfo rooty $w]-[winfo reqheight $b]-5}]
        }
    }
    if {$i eq "cursor"} {
        set x [winfo pointerx $w]
    } else {
        set x [expr {[winfo rootx $w]+[winfo vrootx $w]+\
                    ([winfo width $w]-[winfo reqwidth $b])/2}]
    }
    # only readjust when we would appear right on the screen edge
    if {$x<0 && ($x+[winfo reqwidth $b])>0} {
        set x 0
    } elseif {($x+[winfo reqwidth $b])>[winfo screenwidth $w]} {
        set x [expr {[winfo screenwidth $w]-[winfo reqwidth $b]}]
    }
    if {[tk windowingsystem] eq "aqua"} {
        set focus [focus]
    }
    wm geometry $b +$x+$y
    wm deiconify $b
    raise $b
    if {[tk windowingsystem] eq "aqua" && $focus ne ""} {
        # Aqua's help window steals focus on display
        after idle [list focus -force $focus]
    }
}

proc ::tooltip::menuMotion {w} {
    variable G
    
    if {$G(enabled)} {
        variable tooltip
        
        set cur [$w index active]
        # The next two lines (all uses of LAST) are necessary until the
        # <<MenuSelect>> event is properly coded for Unix/(Windows)?
        if {$cur == $G(LAST)} return
        set G(LAST) $cur
        # a little inlining - this is :hide
        after cancel $G(AFTERID)
        catch {wm withdraw $G(TOPLEVEL)}
        if {[info exists tooltip($w,$cur)] || \
                    (![catch {$w entrycget $cur -label} cur] && \
                    [info exists tooltip($w,$cur)])} {
            set G(AFTERID) [after $G(DELAY) \
                    [namespace code [list show $w $tooltip($w,$cur) $cur]]]
        }
    }
}

proc ::tooltip::hide {args} {
    variable G
    
    after cancel $G(AFTERID)
    catch {wm withdraw $G(TOPLEVEL)}
}

proc ::tooltip::wname {{w {}}} {
    variable G
    if {[llength [info level 0]] > 1} {
        # $w specified
        if {$w ne $G(TOPLEVEL)} {
            hide
            destroy $G(TOPLEVEL)
            set G(TOPLEVEL) $w
        }
    }
    return $G(TOPLEVEL)
}

proc ::tooltip::itemTip {w args} {
    variable tooltip
    variable G
    
    set G(LAST) -1
    set item [$w find withtag current]
    if {$G(enabled) && [info exists tooltip($w,$item)]} {
        set G(AFTERID) [after $G(DELAY) \
                [namespace code [list show $w $tooltip($w,$item) cursor]]]
    }
}

proc ::tooltip::enableCanvas {w args} {
    $w bind all <Enter> [namespace code [list itemTip $w]]
    $w bind all <Leave>		[namespace code hide]
    $w bind all <Any-KeyPress>	[namespace code hide]
    $w bind all <Any-Button>	[namespace code hide]
}


# colors.tcl --
#
# This demonstration script creates a listbox widget that displays
# many of the colors from the X color database.  You can click on
# a color to change the application's palette.



proc colorScheme {} {
global midi
global df
set w .colors
catch {destroy $w}
toplevel $w
positionWindow $w
wm title $w "Listbox Demonstration (colors)"
wm iconname $w "Listbox"

label $w.msg  -wraplength 4i -justify left -font $df -text "A listbox containing several color names is displayed\
below, along with a scrollbar.  You can scan the list either using the scrollbar or by dragging in the \
listbox window with button 2 pressed.  If you double-click button 1 on a color, then the application's \
color palette will be set to match that color"
pack $w.msg -side top
frame $w.action
button $w.action.default -text "restore defaults" -font $df -command {
	set midi(colorscheme) ""
        tk_setPalette grey90}
pack $w.action
pack $w.action.default -side left

frame $w.frame -borderwidth 10
pack $w.frame -side top -expand yes -fill y

scrollbar $w.frame.scroll -command "$w.frame.list yview"
listbox $w.frame.list -yscroll "$w.frame.scroll set" \
	-width 20 -height 16 -setgrid 1 -font $df
pack $w.frame.list $w.frame.scroll -side left -fill y -expand 1

bind $w.frame.list <Double-1> {
    tk_setPalette [selection get]
    set midi(colorscheme) [selection get]
}
$w.frame.list insert 0 gray60 gray70 gray80 gray85 gray90 gray95 \
    snow1 snow2 snow3 snow4 seashell1 seashell2 \
    seashell3 seashell4 AntiqueWhite1 AntiqueWhite2 AntiqueWhite3 \
    AntiqueWhite4 bisque1 bisque2 bisque3 bisque4 PeachPuff1 \
    PeachPuff2 PeachPuff3 PeachPuff4 NavajoWhite1 NavajoWhite2 \
    NavajoWhite3 NavajoWhite4 LemonChiffon1 LemonChiffon2 \
    LemonChiffon3 LemonChiffon4 cornsilk1 cornsilk2 cornsilk3 \
    cornsilk4 ivory1 ivory2 ivory3 ivory4 honeydew1 honeydew2 \
    honeydew3 honeydew4 LavenderBlush1 LavenderBlush2 \
    LavenderBlush3 LavenderBlush4 MistyRose1 MistyRose2 \
    MistyRose3 MistyRose4 azure1 azure2 azure3 azure4 \
    SlateBlue1 SlateBlue2 SlateBlue3 SlateBlue4 RoyalBlue1 \
    RoyalBlue2 RoyalBlue3 RoyalBlue4 blue1 blue2 blue3 blue4 \
    DodgerBlue1 DodgerBlue2 DodgerBlue3 DodgerBlue4 SteelBlue1 \
    SteelBlue2 SteelBlue3 SteelBlue4 DeepSkyBlue1 DeepSkyBlue2 \
    DeepSkyBlue3 DeepSkyBlue4 SkyBlue1 SkyBlue2 SkyBlue3 \
    SkyBlue4 LightSkyBlue1 LightSkyBlue2 LightSkyBlue3 \
    LightSkyBlue4 SlateGray1 SlateGray2 SlateGray3 SlateGray4 \
    LightSteelBlue1 LightSteelBlue2 LightSteelBlue3 \
    LightSteelBlue4 LightBlue1 LightBlue2 LightBlue3 \
    LightBlue4 LightCyan1 LightCyan2 LightCyan3 LightCyan4 \
    PaleTurquoise1 PaleTurquoise2 PaleTurquoise3 PaleTurquoise4 \
    CadetBlue1 CadetBlue2 CadetBlue3 CadetBlue4 turquoise1 \
    turquoise2 turquoise3 turquoise4 cyan1 cyan2 cyan3 cyan4 \
    DarkSlateGray1 DarkSlateGray2 DarkSlateGray3 \
    DarkSlateGray4 aquamarine1 aquamarine2 aquamarine3 \
    aquamarine4 DarkSeaGreen1 DarkSeaGreen2 DarkSeaGreen3 \
    DarkSeaGreen4 SeaGreen1 SeaGreen2 SeaGreen3 SeaGreen4 \
    PaleGreen1 PaleGreen2 PaleGreen3 PaleGreen4 SpringGreen1 \
    SpringGreen2 SpringGreen3 SpringGreen4 green1 green2 \
    green3 green4 chartreuse1 chartreuse2 chartreuse3 \
    chartreuse4 OliveDrab1 OliveDrab2 OliveDrab3 OliveDrab4 \
    DarkOliveGreen1 DarkOliveGreen2 DarkOliveGreen3 \
    DarkOliveGreen4 khaki1 khaki2 khaki3 khaki4 \
    LightGoldenrod1 LightGoldenrod2 LightGoldenrod3 \
    LightGoldenrod4 LightYellow1 LightYellow2 LightYellow3 \
    LightYellow4 yellow1 yellow2 yellow3 yellow4 gold1 gold2 \
    gold3 gold4 goldenrod1 goldenrod2 goldenrod3 goldenrod4 \
    DarkGoldenrod1 DarkGoldenrod2 DarkGoldenrod3 DarkGoldenrod4 \
    RosyBrown1 RosyBrown2 RosyBrown3 RosyBrown4 IndianRed1 \
    IndianRed2 IndianRed3 IndianRed4 sienna1 sienna2 sienna3 \
    sienna4 burlywood1 burlywood2 burlywood3 burlywood4 wheat1 \
    wheat2 wheat3 wheat4 tan1 tan2 tan3 tan4 chocolate1 \
    chocolate2 chocolate3 chocolate4 firebrick1 firebrick2 \
    firebrick3 firebrick4 brown1 brown2 brown3 brown4 salmon1 \
    salmon2 salmon3 salmon4 LightSalmon1 LightSalmon2 \
    LightSalmon3 LightSalmon4 orange1 orange2 orange3 orange4 \
    DarkOrange1 DarkOrange2 DarkOrange3 DarkOrange4 coral1 \
    coral2 coral3 coral4 tomato1 tomato2 tomato3 tomato4 \
    OrangeRed1 OrangeRed2 OrangeRed3 OrangeRed4 red1 red2 red3 \
    red4 DeepPink1 DeepPink2 DeepPink3 DeepPink4 HotPink1 \
    HotPink2 HotPink3 HotPink4 pink1 pink2 pink3 pink4 \
    LightPink1 LightPink2 LightPink3 LightPink4 PaleVioletRed1 \
    PaleVioletRed2 PaleVioletRed3 PaleVioletRed4 maroon1 \
    maroon2 maroon3 maroon4 VioletRed1 VioletRed2 VioletRed3 \
    VioletRed4 magenta1 magenta2 magenta3 magenta4 orchid1 \
    orchid2 orchid3 orchid4 plum1 plum2 plum3 plum4 \
    MediumOrchid1 MediumOrchid2 MediumOrchid3 MediumOrchid4 \
    DarkOrchid1 DarkOrchid2 DarkOrchid3 DarkOrchid4 purple1 \
    purple2 purple3 purple4 MediumPurple1 MediumPurple2 \
    MediumPurple3 MediumPurple4 thistle1 thistle2 thistle3 \
    thistle4
}

#   Part 1.0 Initialize, Save, Read state midipage.ini

set install_folder [pwd]

set execpath [pwd]

set cleanData 0

proc setupMidiexplorer {} {
# will create midiexplorer_home in the user's directory if
# it does not already exist and cd to that folder.
global env
if {[info exist env(MIDIEXPLORERPATH)]} {
     set midiexplorerpath [file join $env(MIDIEXPLORER) midiexplorer_home]
     #puts "MIDIEXPLORER = $midiexplorerpath"
     cd $env(MIDIEXPLORERPATH)} else {
     # if no environment variable MIDIEXPLORERPATH then
     set midiexplorerpath [file join $env(HOME) midiexplorer_home]}

     if {[file exists $midiexplorerpath]} {
     puts "folder $midiexplorerpath exists"
     } else {
     set msg "midiexplorer is creating the folder $midiexplorerpath\
     to store midiexplorer.ini and various temporary midi files."
     tk_messageBox -message $msg  -type ok
     file mkdir $midiexplorerpath
     set handle [open $midiexplorerpath/README.txt w]
     puts $handle "This folder is used by midiexplorer to store\n
            preferences and temporary data.\n\n\
            You may delete this folder if midiexplorer is not\
            on your system."
    close $handle
    if {[file exists midiexplorer.ini]} {file copy midiexplorer.ini $midiexplorerpath}
    }
cd $midiexplorerpath
puts "active path is $midiexplorerpath"
}

setupMidiexplorer 

# default values for options
proc midiInit {} {
    global midi df sf dfreset tocf dfi
    global midiexplorer_version
    global tcl_platform
    global drumentry
    global env
    set drumentry "none"
    set midi(version) $midiexplorer_version
    set midi(font_family) [font actual helvetica -family]
    set midi(font_family_toc) courier
    #set midi(font_size) [font actual . -size]
    set midi(font_size) 10
    set midi(encoder) [encoding system]
    set midi(font_weight) normal
    set df [font create -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)]
    set dfi [font create -family $midi(font_family) -size $midi(font_size) \
            -slant italic]
    set sf [font create -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)]
    set dfreset [font create -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)]
    set tocf [font create -family $midi(font_family_toc) -size $midi(font_size) \
            -weight $midi(font_weight)]
    set midi(dir_abcmidi) .
    if {$tcl_platform(platform) == "windows"} {
        set midi(path_midi2abc) midi2abc.exe
	set midi(path_midistats) midistats.exe
        set midi(path_midicopy) midicopy.exe
	set midi(path_abc2midi) abc2midi.exe
	set midi(path_abcm2ps)  abcm2ps.exe
        set midi(path_gs) ""

        set midi(path_midiplay) "C:/Program Files/Windows Media Player/wmplayer.exe"
        set midi(midiplay_options) "/play /close"
        set midi(browser) " C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
        } else {
        set midi(path_midi2abc) midi2abc
	set midi(path_midistats) midistats
        set midi(path_midicopy) midicopy
	set midi(path_abc2midi) abc2midi
	set midi(path_abcm2ps)  abcm2ps
        set midi(path_midiplay) timidity
        set midi(midiplay_options) "-A 50 -ik"
        set midi(browser) firefox
        set midi(path_gs) gs
        }

    # window geometry
    set midi(autoposition) 1
    set midi(.) ""
    set midi(.notice) ""
    set midi(.console) ""
    set midi(.progsel) ""
    set midi(.piano) ""
    set midi(.beatgraph) ""
    set midi(.chordstats) ""
    set midi(.chordview) ""
    set midi(.chordgram) ""
    set midi(.notegram) ""
    set midi(.colors) ""
    set midi(.midistructure) ""
    set midi(.drumsel) ""
    set midi(.drumroll) ""
    set midi(.drumanalysis) ""
    set midi(.drumrollconfig) ""
    set midi(.drummap) ""
    set midi(.fontwindow) ""
    set midi(.indexwindow) ""
    set midi(.pitchpdf) ""
    set midi(.ppqn) ""
    set midi(.preferences) ""
    set midi(.velocitypdf) ""
    set midi(.onsetpdf) ""
    set midi(.offsetpdf) ""
    set midi(.durpdf) ""
    set midi(.pitchclass) ""
    set midi(.keypitchclass) ""
    set midi(.midivelocity) ""
    set midi(.mftext) ""
    set midi(.searchbox) ""
    set midi(.graph) ""
    set midi(.support) ""
    set midi(.wiki) ""
    set midi(.dictview) ""
    set midi(.barmap) ""
    set midi(.playmanage) ""
    set midi(.data_info) ""
    set midi(.midiplayer) ""
    set midi(.tmpfile) ""
    set midi(.cfgmidi2abc) ""
    set midi(.pgram) ""
    set midi(.keystrip) ""
    set midi(.channel9) ""
    set midi(.ribbon) ""
    set midi(.ptableau) ""
    set midi(.touchplot) ""
    set midi(.effect) ""
    set midi(.csettings) ""

    
    set midi(player1) ""
    set midi(player2) ""
    set midi(player3) ""
    set midi(player4) ""
    set midi(player5) ""
    set midi(player6) ""
    set midi(player1opt) ""
    set midi(player2opt) ""
    set midi(player3opt) ""
    set midi(player4opt) ""
    set midi(player5opt) ""
    set midi(player6opt) ""
    set midi(player_sel) 1
    set midi(playmethod) 1
    
    # other ps default parameters
    set midi(otherps) " > Out.ps"
    
    # open/save parameters
    set midi(midi_save) sample.mid
    
    # midi2abc settings
    set midi(midifilein) Choose_input_midi_file.mid
    set midi(rootfolder) ""
    set midi(history_length) 0
    for {set i 0} {$i < 10} {incr i} {set midi(history$i) ""}

    set midi(outfilename) tmp.mid
    
    
    # piano roll
    set midi(midishow_sep) track
    set midi(nodrumroll) 1
    set midi(midishow_follow) 1
    set midi(trackSelector) dynamic
    
    #  for drumeditor.tcl
    set midi(selected_drums) ""
    set midi(dstrong) 110
    set midi(dmedium) 90
    set midi(dweak)  70
    
    #  for drumtool
    set midi(drumpatfile) drumpatterns.drum
    

    # drumroll
    set midi(playdrumdata) normaldrum
    set midi(mutelev) 20
    set midi(mutefocus) 20
    set midi(mutenodrum) 0
    set midi(drumvelocity) 0
    set midi(drumloudness) 90

    # info interface
    set midi(tooltips) 1

    # midistructure interface
    set midi(segment_gap) 8
    set midi(attenuation) 70
    set midi(sortchordnames) key
    set midi(chordgram) fifths
    set midi(notegram) 1
    set midi(tableau5) 0
    set midi(chordhist) graphics
    set midi(pitchclassfifths) 0
 
    # initial search parameters
    set midi(tempo) 120 
    set midi(proglist) {29 30}
    set midi(drumlist) {}
    set midi(progexlist) {24 25 26 27 28 29}
    set midi(sname) "one"
    set midi(nbends) 100 
    set midi(ndrums) 3
    set midi(pcolthr) 0.85
    set midi(pitchthr) 0.90
    set midi(progthr) 0.50
    set midi(pitche) 3.0
    set midi(matchcriterion) 1

    set midi(mftextunits) 2
    set midi(autoopen) 0
    set midi(colorscheme) ""


    set midi(midirest) 2
    set midi(splits) 0

    set midi(webscript) 3

    set midi(pgrammode) nochord
    set midi(pgramwidth) 500
    set midi(pgramheight) 350
    set midi(pgramthick) 2

# keymap
    set midi(pitchcoef) ss
    set midi(keySpacing) 12
    set midi(pitchWeighting) 0
    set midi(stripwindow) 500 

    set midi(percspeed) 1.0

# pitch class map
    set midi(dotsize) 1
# afterTouch
   set midi(speed) 0.5
   set midi(tplotWidth) 600
   set midi(tres) 50
}

# save all options, current abc file
proc WriteMidiExplorerIni {} {
    global midi
    global midiexplorer_version
    set midi(version) $midiexplorer_version
    set outfile  midiexplorer.ini
    set handle [open $outfile w]
    #tk_messageBox -message "writing $outfile"  -type ok
    foreach item [lsort [array names midi]] {
        puts $handle "$item $midi($item)"
    }
    close $handle
}

proc set_midiplayer {} {
global midi
switch $midi(player_sel) {
  1 {if {[string length $midi(player1)] > 1} {
       set midi(path_midiplay) $midi(player1)
       set midi(midiplay_options) $midi(player1opt)
       }
    }
  2 {if {[string length $midi(player2)] > 1} {
       set midi(path_midiplay) $midi(player2)
       set midi(midiplay_options) $midi(player2opt)
       }
    }
  3 {if {[string length $midi(player3)] > 1} {
       set midi(path_midiplay) $midi(player3)
       set midi(midiplay_options) $midi(player3opt)
       }
    }
  4 {if {[string length $midi(player4)] > 1} {
       set midi(path_midiplay) $midi(player4)
       set midi(midiplay_options) $midi(player4opt)
       }
    }
  5 {if {[string length $midi(player5)] > 1} {
       set midi(path_midiplay) $midi(player5)
       set midi(midiplay_options) $midi(player5opt)
       }
    }
  6 {if {[string length $midi(player6)] > 1} {
       set midi(path_midiplay) $midi(player6)
       set midi(midiplay_options) $midi(player6opt)
       }
    }
#puts "midiplay_options $midi(midiplay_options)"
  }
}

# read all options
proc readMidiexplorerIni {} {
    global midi df tocf
    set infile midiexplorer.ini
    set handle [open $infile r]
    #tk_messageBox -message "reading $infile"  -type ok
    while {[gets $handle line] >= 0} {
        set error_return [catch {set n [llength $line]} error_out]
        if {$error_return} continue
        set contents ""
        set param [lindex $line 0]
	set from [expr [string length $param] + 1]
	set contents [string range $line $from end]
        #if param is not already a member of the midi array (set by midiInit),
        #then we ignore it. This prevents midi array filling up with obsolete
        #parameters used in older versions of the program.
        set member [array names midi $param]
        if [llength $member] { set midi($param) $contents }
    }
    font configure $df -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)
    font configure $tocf -family $midi(font_family_toc) -size $midi(font_size) \
            -weight $midi(font_weight)

    set_midiplayer 
}

proc findLinuxExecutables {} {
global midi
global execpath
set execlist "abc2midi abc2abc abcm2ps midi2abc midicopy"
puts "findLinuxExecutables in [pwd]"
foreach ex  $execlist {
  set cmd "exec which $ex"
  set exx [file join $execpath $ex]
  if {[file exist $exx]} {
	  set midi(path_$ex) [file join [pwd] $exx]
     } else {
     catch {eval $cmd} result
     if {[string first "abnormal" $result] > 0} {
       } else {
       set midi(path_$ex) $result
       }
     }
  }
}


midiInit
if {[file exists midiexplorer.ini]} {
	readMidiexplorerIni
} else {
  if {$tcl_platform(platform) == "windows"} {
      set midi(dir_abcmidi) $install_folder
      set midi(path_abc2midi) [file join $install_folder abc2midi.exe]
      set midi(path_abcm2ps) [file join $install_folder abcm2ps.exe]
      set midi(path_midi2abc) [file join $install_folder midi2abc.exe]
      set midi(path_midistats) [file join $install_folder midistats.exe]
      set midi(path_midicopy) [file join $install_folder midicopy.exe]
      set midi(path_gs) ""
  } elseif {$tcl_platform(platform) == "unix"} {
      findLinuxExecutables
       }
}





wm protocol . WM_DELETE_WINDOW {
    getGeometryOfAllToplevels 
    WriteMidiExplorerIni 
    if {[array exist genre_db]} {update_genre_database}
    exit
    }


proc getVersionNumber {executable} {
    set found [file exist $executable]
    if {$found == 0} {
	    .info.txt insert insert "cannot find $executable\n" red
             }
    set cmd "exec [list $executable] -ver"
    catch {eval $cmd} result
    return $result}

set miditype {{{midi files} {*.mid *.MID *.midi *.kar *.KAR}}}


proc positionWindow {window} {
   global midi
   if {[string length $midi($window)] < 1} return
   if {$midi(autoposition) == 0} return
   wm geometry $window $midi($window)
   }

#
#   Part 2.0  Main Window
#

set font_family [font actual helvetica -family]
set font [font create -family $font_family -size 11]

global exec_out
set exec_out "empty"

package require Tk

# .top contains both .treebrowser and .info
positionWindow "."
panedwindow .top -orient vertical -showhandle 1 -sashwidth 10 -sashrelief sunken -sashpad 4 
pack .top -expand 1 -fill both

set systembackground [lindex [. configure -background] 3]

set w .treebrowser
frame $w
wm title . $midiexplorer_version

if {[string length $midi(colorscheme)] > 0} {
  tk_setPalette $midi(colorscheme)
  }


#        file menu button
frame $w.menuline
frame $w.menuline2
set ww $w.menuline.file.items
menubutton $w.menuline.file -text file -menu $w.menuline.file.items -font $df
menu $ww -tearoff 0
$ww add command -label "root directory" -font $df -command {
    set midi(rootfolder) [tk_chooseDirectory -title "Choose the directory containing the midi files or folders"]
    if {[file exist $midi(rootfolder)]}  {populatedir .treebrowser.tree $midi(rootfolder)
    }
    if {[info exist desc]} {unset desc}
    }
$ww add command -label "reload last midi file" -font $df -command load_last_midi_file -accelerator "ctrl-m"

$ww add command -label "restore root directory" -font $df -command restore_root_folder

$ww add cascade -label "recent" -font $df -menu $ww.recent

$ww add command -label "playlist manager" -font $df -command make_playlist_manager

$ww add command -label "quit" -font $df -command {
    WriteMidiExplorerIni 
    exit
    }

$ww add command -label "help" -font $df -command {show_message_page $hlp_filemenu word}

menu .treebrowser.menuline.file.items.recent -tearoff 0
for {set i 0} {$i < $midi(history_length)} {incr i} {
    $ww.recent add radiobutton  -label $midi(history$i) \
       -value $i -variable history_index -command "open_recent_folder [list $midi(history$i)]" -font $df
}


#unfortunately none of these tooltips are visible on Windows due to a bug
tooltip::tooltip $ww -index 0 "select the folder containing midi
files to browse. This will be called\nthe root folder."
tooltip::tooltip $ww -index 1 "extract the information of the last
midi file that you viewed."
tooltip::tooltip $ww -index 2 "restores the last root folder in\nthe directory structure viewer"
tooltip::tooltip $ww -index 3 "recent folders open"
tooltip::tooltip $ww -index 4 "opens a selector of midi files
of specific genres."
tooltip::tooltip $ww -index 5 "shut down this program remembering
some of your choices."
tooltip::tooltip $ww -index 6 "pop ups a window with brief instructions"

tooltip::tooltip .treebrowser.menuline.file "This menu contains functions to
set the midi directory, restore states,
and configure the behaviour of the program."

set hlp_filemenu "File menu items\n\n\
root directory: sets the root directory where all the midi subfolders are\
found.\n\n\
reload last midi file: restores the last midi file you examined when you\
exited this program.\n\n\
restore root directory: restores the active root directory\n\n\
recent: select one of the subfolders you opened recently\n\n\
playlist manager: a tool for finding an artist subfolder belonging to a\
certain genre.\n\n\
quit: terminates this program saving state variables in midiexplorer.ini\
which is stored in the midiexplorer_home folder.

"

set ww $w.menuline.settings.items
menubutton $w.menuline.settings -text settings -menu $w.menuline.settings.items -font $df
menu $ww -tearoff 0

$ww add command -label "supporting executables" -font $df -command {
  set_external_programs}

$ww add command -label "midi player" -font $df -command {
  set_midi_players} -accelerator ctrl-p

$ww add command -label "font selector" -font $df -command fontSelector

$ww add command -label "midi2abc configuration" -font $df -command midi2abc_config

$ww add command -label "color scheme" -font $df -command colorScheme

$ww add checkbutton -label "auto-open" -font $df -variable midi(autoopen)

$ww add checkbutton -label "tooltips" -font $df -variable midi(tooltips)\
  -command cfgtooltips

$ww add checkbutton -label "remember locations of windows" -font $df\
 -variable midi(autoposition)

$ww add command -label "clear recents" -font $df -command deleteHistory

$ww add command -label "help" -font $df -command {show_message_page $hlp_settings word}
tooltip::tooltip .treebrowser.menuline.settings "This menu contains functions to
configure the colours, fonts and other 
characteristics of this program."


set ww $w.menuline.internals.items
menubutton $w.menuline.internals -text internals -menu $w.menuline.internals.items -font $df
menu $ww -tearoff 0
$ww add command -label "console" -font $df -command {
		   show_console_page $exec_out word} -accelerator "ctrl-k"
$ww add command -label "check version numbers" -font $df\
                 -command show_checkversion_summary 
$ww add command -label "mftext of output midi file" -font $df \
                 -command mftext_local_analysis
$ww add command -label "save output midi file" -font $df \
                 -command save_output_midi_file
$ww add command -label "contents of midiexplorer_home" -command dirhome -font $df
tooltip::tooltip .treebrowser.menuline.internals "This menu contains functions to
expose how this program operates"


#        view menubutton

menubutton $w.menuline.view -text view -menu $w.menuline.view.items -font $df -state disabled
	set ww $w.menuline.view.items
	menu $ww -tearoff 0
	$ww add command -label "google search" -font $df -accelerator "ctrl-o"\
	    -command google_search 
	$ww add command -label "google genre" -font $df -accelerator "ctrl-g"\
	    -command "google_search genre"
	$ww add command -label "duckduckgo search" -font $df -accelerator "ctrl-u"\
	    -command duckduckgo_search
        $ww add command -label "pgram" -font $df -command pgram_window 
        $ww add command -label keymap -font $df -command {keymap none} -accelerator "ctrl-y"
	$ww add command -label chordgram -font $df -command {chordgram_plot none} -accelerator "ctrl-h"
	$ww add command -label "midi structure" -font $df -accelerator "ctrl-s"\
            -command {midi_structure_display}
        $ww add command  -label "tableau" -font $df \
            -command detailed_tableau -accelerator "ctrl-t"
	$ww add command -label pianoroll -font $df -accelerator "ctrl-r"\
            -command piano_roll_display
	$ww add command -label drumroll -font $df -command {drumroll_window} -accelerator "ctrl-d"
	$ww add command -label percView -font $df -command percMapInterface
        $ww add command -label "control settings" -font $df\
          -command getAllControlSettings
        $ww add command -label afterTouch -font $df -command aftertouch -accelerator "ctrl-a"
	$ww add command -label "mftext by beats" -font $df -command {
             set midi(mftextunits) 2
             mftextwindow $midi(midifilein) 0}
	$ww add command -label "mftext by pulses" -font $df -command {
             set midi(mftextunits) 3
             mftextwindow $midi(midifilein) 0}
        $ww add command -label "help" -font $df -command {
                   show_message_page $hlp_view word}	           

tooltip::tooltip .treebrowser.menuline.view "Popups various windows for analyzing
the selected midi file.  The console
is useful for debugging this program
when it is not running as expected."

button $w.menuline.play -text play -command "play_selected_lines none" -font $df -state disabled
#bind $w.menuline.play <3> {playmidifile 0}
bind $w.menuline.play <3> {play_and_exclude_selected_lines}

tooltip::tooltip $w.menuline.play "Right click plays all tracks or channels excluding\n the selected tracks or channels."

set hlp_view "view menu items\n\n\
google search: opens up an internet browser to the google search results\
for the selected artist subfolder and midi file. If you are lucky, there is a\
a youtube video showing the artist performing this song.\n\n\
midi structure: there are presently two versions of this function. It\
shows where the tracks (or channels) are active and what instruments\
are playing for the active midi file. See its help file for more details.\n\n\
pianoroll: a piano roll representation of the midi file. It has a separate\
help text.\n\n\
drumroll: a drum roll representation for the percussion channel. There is\
also a help button where you can get more details.\n\n\
mftext (by beats or pulses): displays a text representation of the midi file.\
Also has a separate help button.
"

#
#
#        pitch analysis button (plots)

menubutton $w.menuline.pitch -text pitch\nanalysis -menu $w.menuline.pitch.items -font $df -state disabled
set ww $w.menuline.pitch.items
menu $ww -tearoff 0
        $ww add command  -label "pitch distribution" -font $df \
            -command {midi_statistics pitch none
                      plotmidi_pitch_pdf
                      }
        $ww add command  -label "pitch class plot" -font $df \
            -command {midi_statistics pitch none
                      show_note_distribution
                     } 
        $ww add command  -label "pitch class map" -font $df \
            -command simple_tableau
	$ww add command -label chordgram -font $df -command {chordgram_plot none}
#	$ww add command -label "chord histogram" -font $df -command chord_histogram
#        $ww add command -label "chordtext" -font $df -command chordtext_window
        $ww add command -label notegram -font $df -command {notegram_plot none}
        $ww add command -label keymap -font $df -command {keymap none}
	$ww add command -label "entropy analysis" -font $df -command analyze_note_patterns
tooltip::tooltip $w.menuline.pitch "Computes the and plots the distribution
of various pitch related parameters of the selected midi file."

#
#        rhythm analysis button (plots)
#
menubutton $w.menuline.rhythm -text rhythm\nanalysis -menu $w.menuline.rhythm.items -font $df -state disabled
set ww $w.menuline.rhythm.items
menu $ww -tearoff 0
	$ww add command -label "onset distribution" -font $df\
            -command {midi_statistics onset none
                      plotmidi_onset_pdf 
                     }
	$ww add command -label "offset distribution" -font $df\
            -command {midi_statistics offset none
                      plotmidi_offset_pdf 
                     }
        $ww add command  -label "note duration distribution" -font $df \
            -command {midi_statistics duration none
                      plotmidi_duration_pdf 
                     }
        $ww add command  -label "velocity distribution" -font $df \
            -command {midi_statistics velocity none
                plotmidi_velocity_pdf}
        $ww add command  -label "velocity map" -font $df \
            -command {plot_velocity_map none}
        $ww add command  -label "beat graph" -font $df \
            -command {beat_graph none}

tooltip::tooltip $w.menuline.rhythm "Computes the and plots the distribution
of various rhythm related parameters of the selected midi file."

#        database menubutton
menubutton $w.menuline.database -text database -menu $w.menuline.database.items -font $df
set ww $w.menuline.database.items
menu $ww -tearoff 0
       $ww add command -label "create database" -font $df -command {make_midi_database}

       $ww add command -label search -font $df -command {load_desc
                                                  search_window
                                                 }
       $ww add command -label "defective files" -font $df -command find_bad_files
       $ww add cascade -label "export" -font $df -menu $ww.export


tooltip::tooltip $ww -index 0 "Scan all midi files in the given directory
extract their properties and record this
information in a file called MidiDescriptors.txt"
tooltip::tooltip $ww -index 1 "Load the MidiDescriptors.txt database
and search for the midi files which
satisfy certain characteristics."
tooltip::tooltip $ww -index 2 "List the midi files which were
found to have some problems"

menu $ww.export -tearoff 0
$ww.export add command -label "info data" -font $df -command export_info_to_tsv
$ww.export add command -label "file index" -font $df -command export_fileindex
$ww.export add command -label "progcolor data" -font $df -command export_progcolor_to_csv
$ww.export add command -label "prog data" -font $df -command "export_progs_to_csv 0"
$ww.export add command -label "normalized prog data" -font $df -command "export_progs_to_csv 1"
$ww.export add command -label "drum data" -font $df -command export_drum_to_csv
$ww.export add command -label "drum hits data" -font $df -command export_drum_hits_to_csv
$ww.export add command -label "pitch data" -font $df -command export_pitches_to_csv
$ww.export add command -label "bad midi files" -font $df -command export_list_of_defective_files

$ww add command -label "indexed file" -font $df -command index_window

tooltip::tooltip $w.menuline.database "After you create a database which
lists the characteristic of each midi
file in the active directory, you can
search for midi files with specific
properties.  Depending on the size of
the directory, it could take a while
to compute this database which will be
stored in a text file called 
MidiDescriptors.txt."


$ww add cascade -label "plots" -font $df -menu $ww.plots

#        database plots 

set ww $w.menuline.database.items.plots
menu $ww -tearoff 0
       $ww add command -label "tempo distribution" -font $df -command {univariateDistribution tempo 300 50 "beats per minute"}
       $ww add command -label "distribution of number of beats" -font $df -command {univariateDistribution midilength 1000 200 "number of beats"}
       $ww add command -label "pitchbend distribution" -font $df -command {univariateDistribution pitchbend 1000 300 "number of pitchbends"}
       $ww add command -label "program distribution" -font $df -command programStatistics
       $ww add command -label "drum complexity distribution" -font $df -command drumComplexityDistribution
       $ww add command -label "drum distribution" -font $df -command drumDistribution
       $ww add command -label "pitch class entropy distribution" -command pitchEntropyDistribution -font $df


button $w.menuline.abc -text abc -font $df -command {create_abc_file none}
tooltip::tooltip $w.menuline.abc "Convert the selected tracks (channels) or entire\nmidi file to abc notation and open an abc editor."

#        find title 
button .treebrowser.menuline2.jump -text find -command {findChildInTree .treebrowser $findname} -font $df

entry .treebrowser.menuline2.name -width 16 -textvariable findname -font $df

bind .treebrowser.menuline2.name <Return> {findChildInTree .treebrowser $findname}

button .treebrowser.menuline2.random -text "random pick" -font $df -command {randomPick .treebrowser}

tooltip::tooltip .treebrowser.menuline2.jump "If you know the name of a subfolder
in this directory, it may be more practical
to jump to this location rather than scrolling
down. Enter the name or first few letters in the
entry box followed by a return."



#        main help button
menubutton .treebrowser.menuline.help -text help  -font $df -borderwidth 3 -relief ridge -menu .treebrowser.menuline.help.actions
menu .treebrowser.menuline.help.actions -tearoff 0
.treebrowser.menuline.help.actions add command -label "Context Help" -command {show_message_page $hlp_midiexplorer word} -font $df
.treebrowser.menuline.help.actions add command -label "Web Help" -command webhelp -font $df


set hlp_midiexplorer "A long description of this program can be\
found on https://midiexplorer.sourceforge.io/ .\n\n\
This is the toplevel of the program. (Closing\
that window will shutdown the program.) The various modules of this\
program are accessible using the controls in the 'view' and utilities\
menus; however before you start you need to specify the directory\
where all the midi files are found, using the 'file/folder browser' menu\
item. You may also need to specify the paths to the executables using\
the 'supporting executables' menu item.

After selecting a midi directory and a midi file, a summary and\
track by track (or channel by channel) description will appear\
in the frames below and other buttons in the menubar will become\
activated. The descriptors for the individual tracks\
or channels list the number of notes, chords, the spread of the notes,\
the average pitch, the  average note duration, number of rhythm patterns\
and other channels  commands . You can sort the this data by clicking\
on their respective headers.

You can select particular channels or tracks\
by clicking on them with your mouse pointer. Those tracks will\
be highlighted in blue. To highlight more than one track, hold\
down the control key on your keyboard. (You can also deselect\
a track in the same manner.) Holding the shift key down will\
permit you to select a contiguous group of tracks. Some of the\
button functions like play, rhythm and pitch  analysis may only act on the\
selected tracks. The selected channels/tracks is also linked\
to the midistructure window (described elsewhere). When you\
left click the play button, it will play the selected region and\
channel/tracks in the midistructure window even though the\
midistructure window is not exposed. If you right click the\
play button, then the selection in the midistructure window will\
be ignored.


Other help instructions will appear when you click the help button,\
or help menu item in other windows. More detailed user's guide\
can be found on the web page http:\\\\midiexplorer.sf.io.

The program was developed for a screen resolution of 1920 by 1080.\
You can modify the font size, using the 'file/font selector' menu item."

set hlp_settings "Settings\n\n\

supporting executables: for specifying the path to the executables that\
are required. It allows you to select one of the midi players to use\
when you click the play button.\n\n\
font selector: allows you to use a different font in case the current one\
is too small or too large for your screen.\n\n\
color scheme: if you get tired of the black and white user interface.\n\n\
auto-open: automatically opens subfolders containing only one midi file.\
This may slow down the program on some platforms.\n\n\
tooltips: if checked (recommended) a tooltip will appear above some of\
the buttons or menubuttons.\n\n\
remember locations of windows: when a window pops up, it is positioned\
to the same place you had moved it when you last ran this program.\n\n\
clear recents: clears all the items in the recent menu (above).\n\n\
If you hover the mouse pointer on some of the buttons or menu items,\
you may see a pop up tooltip with some advice. If this is annoying,\
You can turn this off by unticking the menu item 'tooltips'.

By default midiexplorer will attempt to open folders that contain\
only one midi file. This may slow down the startup of midiexplorer\
on Windows. If this is the case, you can untick the 'auto-open'\
checkbutton in the files menu.

Many of the modules will pop up their own window. By default\
the window will appear in the center of the screen. You should\
move it to another location so that it does not overlap another\
window. Midiexplorer will remember this location if this window\
is still exposed when you exit midiexplorer.
"

# pack everything and set binding to quick keys
set ww $w.menuline
pack $ww.file  $ww.view $ww.play $ww.rhythm $ww.pitch  $ww.database $ww.abc $ww.settings $ww.internals $ww.help -anchor w -side left
pack .treebrowser.menuline2.jump .treebrowser.menuline2.name .treebrowser.menuline2.random -side left
pack .treebrowser.menuline -anchor w
pack .treebrowser.menuline2 -anchor w

proc bind_accelerators {} {
bind all <Control-a> aftertouch
bind all <Control-d> drumroll_window
bind all <Control-e> count_bar_rhythm_patterns
bind all <Control-g> {google_search genre}
bind all <Control-h> {chordgram_plot none}
bind all <Control-k> {show_console_page $exec_out word}
bind all <Control-o> google_search
bind all <Control-n> {notebook}
bind all <Control-p> set_midi_players
bind all <Control-r> piano_roll_display
bind all <Control-s> {midi_structure_display}
bind all <Control-t> {detailed_tableau}
bind all <Control-u> duckduckgo_search
bind all <Control-w> {playmidifile 0}
bind all <Control-y> {keymap none}
}

bind_accelerators



#        message line
label .treebrowser.menuline2.messageline -fg red
pack .treebrowser.menuline2.messageline 

proc clearMessageLine {} {
.treebrowser.menuline2.messageline configure -text ""
}

proc messagetxt {txt} {
.treebrowser.menuline2.messageline configure -text $txt
}


#        font selector

proc fontSelector {} {
global midi
set w .fontwindow
set sizelist {6 7 8 9 10 11 12 13 14 15}
toplevel $w
positionWindow .fontwindow
set fontfamily [lsort [font families]]
ttk::combobox $w.fontbox -width 24  -textvariable midi(font_family)\
         -values $fontfamily
bind .fontwindow.fontbox <<ComboboxSelected>> {changeFont}
entry $w.fontsel -textvariable midi(font_family) -width 26
label $w.fontsellab -text "font family"
grid $w.fontsellab $w.fontsel
label $w.fontboxlab -text "font selector"
grid  $w.fontboxlab $w.fontbox
radiobutton $w.fontnormal -text normal -variable midi(font_weight) \
       	-value normal -command changeFont
radiobutton $w.fontbold -text bold     -variable midi(font_weight) \
       	-value bold -command changeFont
grid $w.fontnormal $w.fontbold
label $w.fontsizelab -text "font size"
ttk::combobox $w.fontsize -width 8  -textvariable midi(font_size)\
         -values $sizelist
bind .fontwindow.fontsize <<ComboboxSelected>> {changeFont}
grid $w.fontsizelab $w.fontsize
#button $w.fontset -text "font set" -command changeFont
button $w.fontreset -text "font reset" -command reset_font
#grid $w.fontset $w.fontreset
grid $w.fontreset
}

proc reset_font {} {
global midi
global df
global dfi
set midi(font_family) [font actual helvetica -family]
set midi(font_size) 10
set midi(font_weight) normal
set sizeminus [expr $midi(font_size) -1]
font configure $df -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)
font configure $dfi -family $midi(font_family) -size $sizeminus \
            -weight $midi(font_weight) -slant italic
if {[winfo exist .midistructure]} {
  destroy .midistructure
  midi_structure_window 
  }
}

proc doresize { win } {
   if { $win eq "." } {
      puts "Win $win now has width: [winfo width $win]"
   }
}

proc changeFont {} {
global midi
global df
global dfi
set sizeminus [expr $midi(font_size) -1]
font configure $df -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)
font configure $dfi -family $midi(font_family) -size $sizeminus \
            -weight $midi(font_weight) -slant italic
if {[winfo exist .midistructure]} {
  destroy .midistructure
  midi_structure_window 
  }
set w .tinfo
foreach col {trk chn program notes spread pavg duration rpat bends controls} {
  $w.tree column $col -width [expr [font measure $df $col] + 10]
 }
$w.tree column program -width [font measure $df "WWWWWWWWWWWWWW"]
$w.tree column notes -width [font measure $df "WWWWWWWW"]
pack forget .tinfo.tree .tinfo.vsb
pack forget .tinfo
pack .tinfo.tree .tinfo.vsb -side left -expand 1 -fill both 
pack .tinfo
tk_messageBox -message "Restart midiexplorer to fix font problems or resize mainwindow."
}

#        tooltips switch
proc cfgtooltips {} {
   global midi
   if {$midi(tooltips)} {
        tooltip::tooltip enable
        } else {
        tooltip::tooltip disable
        }
   }

# enable or disable tooltips
cfgtooltips

proc updateHistory {openfile} {
    global midi history_index df
    set w .treebrowser.menuline.file.items.recent
    #check if file is in history
    for {set i 0} {$i < $midi(history_length)} {incr i} {
        if {[string compare $midi(history$i) $openfile] ==  0} return
    }
    
    if {$midi(history_length) == 0}  {
        $w add radiobutton  -value 0 -font $df\
                -variable history_index -command "open_recent_folder [list $openfile]"
    }
    
    # push history down open stack
    for {set i $midi(history_length)} {$i > 0} {incr i -1}  {
        set j [expr $i -1]
        set k [expr $i +2]
        set midi(history$i) $midi(history$j)
        if {$midi(history_length) < 10 && $i == $midi(history_length) } {
            $w add radiobutton  -label $midi(history$i) \
                    -value $i -variable history_index\
                    -font $df -command "open_recent_folder [list $openfile]"
        } else {
            $w entryconfigure  $k -label $midi(history$j)
        }
    }
    set midi(history0) $openfile
    $w entryconfigure 2 -label $midi(history0)
    if {$midi(history_length) < 10} {incr midi(history_length)}
}



proc deleteHistory {} {
global midi
for {set i 1} {$i < $midi(history_length)} {incr i} {
  unset midi(history$i)}
.treebrowser.menuline.file.items.recent delete 0 $midi(history_length)
set midi(history_length) 0
}


proc popMessage {text} {
  set b ._msg_
  if {![winfo exists $b]} {
    toplevel $b -class Tooltip
    wm overrideredirect $b 1
    wm positionfrom $b program
    set xy [winfo pointerxy .]
    set x [lindex $xy 0]
    set y [lindex $xy 1]
    wm geometry $b +$x+$y
    label $b.label -highlightthickness 0 -relief solid -bd 1 \
      -background lightyellow -fg black -justify left -text $text
    pack $b.label -ipadx 1
    }
}


#   Part 3.0 Directory Structure Tree View
#
## Create the tree and set it up
ttk::style configure Treeview.Heading -font $df
ttk::style configure Treeview -background azure1
ttk::treeview $w.tree -columns {fullpath type size criterion} -displaycolumns {size criterion} \
	-yscroll "$w.vsb set" -xscroll "$w.hsb set" -selectmode browse -padding 3
#puts [$w.tree configure]
ttk::scrollbar $w.vsb -orient vertical -command "$w.tree yview"
ttk::scrollbar $w.hsb -orient horizontal -command "$w.tree xview"
$w.tree heading \#0 -text "Directory Structure"
$w.tree heading size -text "File Size"
$w.tree column size -stretch 0 -width [font measure $df "File SizeWW"]
$w.tree heading criterion -text "Criterion"
$w.tree column criterion -stretch 0 -width [font measure $df "CriterionWW "]
$w.tree column \#0 -width [font measure $df "WWWWWWWWWWWWWWWWWWWWWWWWWWW"]
$w.tree heading criterion -command [list TreeBrowserSortBy criterion 0]
bind $w.tree <<TreeviewOpen>> {populateTree %W [%W focus]}
bind $w.tree <<TreeviewSelect>> {selected_midi}

# right click
bind $w.tree <Button-3> {FillFolderInTree %x %y}


## Arrange the tree and its scrollbars 
lower [ttk::frame $w.dummy]
pack $w.dummy -fill both -expand 1
grid $w.tree $w.vsb -sticky nsew -in $w.dummy
grid $w.hsb -sticky nsew -in $w.dummy
grid columnconfigure $w.dummy 0 -weight 1
grid rowconfigure $w.dummy 0 -weight 1


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


proc populatedir {tree root} {
   global font rootnode
   $tree tag configure fnt -font $font
   $tree delete [$tree children {}]
   set rootnode [$tree insert {} end -text $root -values [list $root directory] -tag fnt]
   populateTree $tree $rootnode
   }




proc formatSize {size} {
      if {$size >= 1024*1024*1024} {
	set size [format %.1f\ GB [expr {$size/1024/1024/1024.}]]
      } elseif {$size >= 1024*1024} {
	set size [format %.1f\ MB [expr {$size/1024/1024.}]]
      } elseif {$size >= 1024} {
	set size [format %.1f\ kB [expr {$size/1024.}]]
      } else {
	append size " bytes"
      }
return $size
}


## Code to populate a node of the tree
proc populateTree {tree node} {
    global df
    global midi
    if {[$tree set $node type] ne "directory"} {
	return
    }
    $tree tag configure fnt -font $df
    set path [$tree set $node fullpath]
    #puts "path = $path"
    $tree delete [$tree children $node]
    set i 0
    set filelist [lsort -dictionary [glob -nocomplain -dir $path *]] 
    set nfiles [llength $filelist]
    messagetxt "scanning $nfiles files. Could take a while."
    foreach f $filelist {
	set type [file type $f]
	if {$type eq "directory"} {
	    ## Make it so that this node is openable
	    set folderfiles [glob -nocomplain -dir $f *]
	    # in case there is only one midi file in the folder,
	    # we substitute this file in the treeview.
            set size [llength $folderfiles]
	    if {$size ==  1 && $midi(autoopen)} {
  	      set folder_item [lindex $folderfiles 0]
	    # We have to ensure that it is not a folder.
	      if {[file type $folder_item] eq "file"} {
                set ext [file extension $folder_item]
		if {$ext == ".mid" || $ext == ".MID"} {
	           set id [$tree insert $node end\
	             -text [file tail $f]/$folder_item\
	             -values [list $folder_item file] -tag fnt]
	           $tree item $id -text "[file tail $f]/[file tail $folder_item]" -tag fnt
	           set size [file size $folder_item]
	           $tree set $id size [formatSize $size]
	           }
                } 
            } else { 
	    set id [$tree insert $node end -text [file tail $f]\
		-values [list $f $type] -tag fnt]
	       $tree insert $id 0 -text dummy -tag fnt ;# a dummy
	       $tree item $id -text [file tail $f]/
	       $tree set $id size [llength $folderfiles]
	   }
	} elseif {$type eq "file"} {
            set ext [file extension $f]
            if {$ext == ".mid" || $ext == ".MID"} {
	      set id [$tree insert $node end -text [file tail $f] \
		-values [list $f $type] -tag fnt]
	      set size [file size $f]
	    ## Format the file size nicely
	      set size [formatSize $size] 
	      $tree set $id size $size
              }
	}
    incr i
    if {[expr $i % 50] == 0} {
         messagetxt "scanning [expr $nfiles -$i] files. Could take a while."
	  update}
    }

    # Stop this code from rerunning on the current node
    $tree set $node type processedDirectory
    clearMessageLine 
}

proc findChildInTree {w name} {
# in case the root folder is not there
restore_root_folder 
#puts "searching for $name"
set nodes [$w.tree children [$w.tree children {}]]
foreach node $nodes {
 set c [$w.tree item $node -value]
 set n [file tail [lindex $c 0]]
 set n [string tolower $n]
 set na [string tolower $name]
 if {[string first $na $n] == 0} {$w.tree see $node
                                  break}
 }
}

proc randomPick {w} {
# in case the root folder is not there
restore_root_folder 
set nodes [$w.tree children [$w.tree children {}]]
set nnodes [llength $nodes]
set pick [expr int(rand()*$nnodes)]
set node [lindex $nodes $pick]
$w.tree see $node
}


proc TreeBrowserSortBy {col direction} {
    set data {}
    foreach row [.treebrowser.tree children {}] {
        lappend data [list [.treebrowser.tree set $row $col] $row]
    }
    set dir [expr {$direction ? "-decreasing" : "-increasing"}]
    set r -1
    # Now reshuffle the rows into the sorted order
    foreach info [lsort -dictionary -index 0 $dir $data] {
        .treebrowser.tree  move [lindex $info 1] {} [incr r]
    }
    # Switch the heading so that it will sort in the opposite direction
    .treebrowser.tree heading $col -command [list TreeBrowserSortBy  $col [expr {!$direction}]]
}

#   Part 4.0 Midi summary listing in table form

set w .tinfo
frame $w 
set fontheight [font metrics $df -linespace]
ttk::treeview $w.tree -columns {trk chn program notes spread pavg duration rpat bends controls} -show headings -yscroll "$w.vsb set" -height $fontheight
ttk::scrollbar $w.vsb -orient vertical -command ".tinfo.tree yview"
foreach col {trk chn program notes spread pavg duration rpat bends controls} {
  $w.tree heading $col -text $col
  $w.tree heading $col -command [list TinfoSortBy $col 0]
  $w.tree column $col -width [expr [font measure $df $col] + 10]
  }
$w.tree column program -width [font measure $df "WWWWWWWWWWWWWW"]
$w.tree column notes -width [font measure $df "WWWWWWWW"]
$w.tree tag configure fnt -font $df
pack $w.tree $w.vsb -side left -expand 1 -fill both 
bind $w.tree <<TreeviewSelect>> {tinfoSelect}
$w.tree configure -height 10

proc TinfoSortBy {col direction} {
    set data {}
    foreach row [.tinfo.tree children {}] {
        lappend data [list [.tinfo.tree set $row $col] $row]
    }
    set dir [expr {$direction ? "-decreasing" : "-increasing"}]
    set r -1
    # Now reshuffle the rows into the sorted order
    foreach info [lsort -dictionary -index 0 $dir $data] {
        .tinfo.tree  move [lindex $info 1] {} [incr r]
    }
    # Switch the heading so that it will sort in the opposite direction
    .tinfo.tree heading $col -command [list TinfoSortBy  $col [expr {!$direction}]]
}

set idlist {}

proc FillFolderInTree {x y} {
global idlist
if {[llength $idlist] > 0} {
  .treebrowser.tree delete $idlist
  }
set idlist {}
.treebrowser.tree tag configure green -foreground green
.treebrowser.tree selection set {}
.treebrowser.tree selection set [.treebrowser.tree identify row $x $y]
set loc [.treebrowser.tree selection]
set c [.treebrowser.tree item $loc -values]
set p [lindex $c 4]
if {$p == ""} {return}
if {[lindex $c 1] == "file"} {
  set f [lindex $c 0]
  set f [file dirname $f]
  set filelist [rglob $f *.mid]
  set filelist [concat $filelist [rglob $f *.MID]]
  foreach f $filelist {
     set id [.treebrowser.tree insert {} $p -text $f -tag green -values [list $f "file"]]
     lappend idlist $id
    }
  } 
}

proc SwitchBetweenInfoAndTinfo {} {
.top add .info
.top add .tinfo
}


#   Part 5.0 Midi summary header

# Make info window
frame .info
text .info.txt -wrap word -width 80 -height 5 -font $df
.info.txt tag configure red -foreground red -font $df

# Lay them out
#grid .info.txt -sticky nsew
pack .info.txt -fill both -expand 1 -side right

# join .treebrowser and .info in the panedwindow called .top
.top add .treebrowser 

proc presentMidiInfo {} {
   global midi
   global ntrks
   global lasttrack
   grab_all_program_commands
   if {$ntrks == 0} return
   if {$ntrks == 1} {
     interpretMidiType0
   } else {
     interpretMidiType1
   }
   set lasttrack $ntrks
}

proc interpretMidiType0 {} {
global trkinfo
global midi
global tempo
global ppqn
global lastbeat
global programmod
global miditxt
global addendum
global midierror
global keysig
global nkeysig
global timesig
global ntimesig
global df
global lastbeat

gatherMidiSummary
midi_type0_table 

array unset miditext
array unset programmod
if {[info exist tempo]} {unset tempo}
set addendum ""
set i 1
set miditxt(0) "$midi(midifilein)\n 1 track      $ppqn pulses/beat"

#update_table_header

if {![info exist tempo]} {set tempo 120}
append miditxt(0) "     tempo:$tempo beats/minute"
append miditxt(0) "     $lastbeat beats in the file\n"
if {$nkeysig < 1} {set keysig C}
append miditxt(0) "key signature:$keysig"
if {$ntimesig < 1} {set timesig 4/4}
append miditxt(0) "     time signature: $timesig\n"
if {$nkeysig > 1} {append miditxt(0) "\nThere are $nkeysig key signatures in the file."}
if {$ntimesig > 1} {append miditxt(0) "\nThere are $ntimesig time signatures in the file."}


set nchannels $i
if {[string length $addendum] > 2} {append miditxt(0) $addendum}
set txtbuf $miditxt(0)\n  
.info.txt delete 1.0 end
if {[string length $midierror]>0} {
     .info.txt insert insert "$midierror\n" red -font $df
   }
.info.txt insert insert $txtbuf 
}

proc clearMidiTracksAndChannels {} {
global miditracks
global midichannels
global midispeed
for {set i 0} {$i < 40} {incr i} {
  set miditracks($i) 0 
  }
for {set i 0} {$i < 17} {incr i} {
  set midichannels($i) 0
  }
set midispeed 1.0
}

proc invertMidiTracksAndChannels {} {
global midi
global miditracks
global midichannels
set w .midistructure.leftbuttons
if {$midi(midishow_sep) == "track"} {
 for {set i 2} {$i <40} {incr i} {
  set miditracks($i) [expr 1 - $miditracks($i)]
  if {$miditracks($i) && [winfo exists $w.$i] } {
      $w.$i select
      } elseif {[winfo exists $w.$i] && $miditracks($i) == 0 } {
      $w.$i deselect}
  }
 }
if {$midi(midishow_sep) == "chan"} {
 for {set i 1} {$i < 17} {incr i} {
  set midichannels($i) [expr 1 - $midichannels($i)] 
  if {$midichannels($i) && [winfo exists $w.$i] } {
      $w.$i select
      } elseif {[winfo exists $w.$i] && $midichannels($i) == 0} {
      $w.$i deselect}
  }
 }
}

clearMidiTracksAndChannels

proc interpretMidiType1 {} {
  global ntrks
  global trkinfo
  global mlist
  global midi
  global track2channel
  global channel2program
  global xchannel2program
  global tempo
  global ppqn
  global lastbeat
  global programmod
  global addendum
  global miditxt
  global midierror
  global keysig
  global nkeysig
  global timesig
  global ntimesig
  global df

  if {[info exist tempo]} {unset tempo}
  array unset miditxt 
  array unset track2channel
  array unset channel2program
  array unset track2program
  array unset programmod

  gatherMidiSummary 
  midiType1Table

  set miditxt(0) "$midi(midifilein)
 $ntrks tracks       $ppqn pulses/beat"
  set addendum ""

#update_table_header
if {$nkeysig < 1} {set keysig C}
if {![info exist tempo]} {set tempo 120}
append miditxt(0) "         tempo:$tempo beats/minute"
append miditxt(0) "      $lastbeat beats in the file\n"
append miditxt(0) "key signature: $keysig"
if {$ntimesig > 0} {append miditxt(0) "     time signature: $timesig"}
if {$ntimesig > 1} {append miditxt(0) "\nThere are $ntimesig time signatures in the file."}
if {$nkeysig > 1} {append miditxt(0) "\nThere are $nkeysig key signatures in the file."}

 if {[string length $addendum] > 2} {append miditxt(0) $addendum}
 set txtbuf $miditxt(0)\n  
 .info.txt delete 1.0 end
  if {[string length $midierror]>0} {
     .info.txt insert insert "$midierror\n" red -font $df
     }
  #print_programmod
  .info.txt insert insert $txtbuf 

}

proc tinfoSelect {} {
global midi
global miditracks
global midichannels
global ntrks
global cleanData
set cleanData 0
#puts "tinfo selection"
set indices [.tinfo.tree selection]
clearMidiTracksAndChannels
foreach i $indices {
  set iline [.tinfo.tree item $i -values]
  set chn [lindex $iline 1]
  set trk [lindex $iline 0]
  #if {[winfo exists .midistructure]} {
  #	     .midistructure.leftbuttons.c$chn select
  #        }
  set midichannels($chn) 1
  if {$ntrks > 1} {
        set miditracks($trk) 1
        }
  #if {[winfo exists .midistructure]} {
  #	     .midistructure.leftbuttons.c$chn select
  #        }
    }
midiStructureSelect
updateAllWindows none
}


proc midiStructureSelect {} {
global miditracks
global midichannels
global cleanData
set cleanData 0
if {[winfo exists .midistructure]} {
set w .midistructure.leftbuttons
for {set i 2} {$i < 40} {incr i} {
  if {$miditracks($i)} {
	  $w.$i select
     } else {$w.$i deselect}
 }
for {set i 1} {$i < 17} {incr i} {
  if {$midichannels($i)} {
	  $w.c$i select
     } else {$w.c$i deselect}
  }
}	
}


proc open_recent_folder {recent_folder} {
findChildInTree .treebrowser [file tail $recent_folder]
}


#   Part 6.0 Midi file selection support

proc selected_midi {} {
 global midi
 global ntrks
 global df
 global cleanData
 global pianorollwidth
 global pianoPixelsPerFile
 global compactMidifile
 set cleanData 0
 set sel [.treebrowser.tree selection]
 set c [.treebrowser.tree item $sel -values]
 set f [lindex $c 0]
 #puts "selected midi $sel $f"
 set extension [string tolower [file extension $f]]
 if {$extension == ".mid"} {  
   .treebrowser.menuline.view configure -state normal
   .treebrowser.menuline.play configure -state normal
   .treebrowser.menuline.rhythm configure -state normal
   .treebrowser.menuline.pitch configure -state normal
   set midi(midifilein) $f
   updateHistory [file dirname $f]
   clearMidiTracksAndChannels
   set midi_info [get_midi_info_for]
   parse_midi_info $midi_info
   SwitchBetweenInfoAndTinfo 
   presentMidiInfo
   loadMidiFile
   set cleanData 1
   if {[winfo exist .piano]} {
            zero_trksel
            set pianoPixelsPerFile $pianorollwidth
            compute_pianoroll
            update_displayed_pdf_windows .piano.can}
   if {[winfo exist .midistructure]} {
            zero_trksel
	    midi_structure_window 
	    }
   if {[winfo exist .mftext]} {mftextwindow $midi(midifilein) 0}
   if {[winfo exist .drumroll]} {show_drum_events}
   updateAllWindows pianoroll
   }
}


proc load_last_midi_file {} {
 .treebrowser.menuline.view configure -state normal
 .treebrowser.menuline.play configure -state normal
 .treebrowser.menuline.rhythm configure -state normal
 .treebrowser.menuline.pitch configure -state normal
 set midi_info [get_midi_info_for]
 if {$midi_info == ""} return
 parse_midi_info $midi_info
 SwitchBetweenInfoAndTinfo 
 presentMidiInfo
} 

bind . <Control-m> load_last_midi_file

proc readMidiFileHeader {openfile} {
    global ntrk
    global ppqn
    global midihandle
    global mthd_header
    global mlen mformat ppqn
    global piano_qnote_offset
    global midi
    if {[string length $openfile] > 0} {
        set midihandle [open $openfile r]
    }
    fconfigure $midihandle -translation binary
    set mthd_header [read $midihandle 14]
    unpack_mthd_header
    close $midihandle
    set piano_qnote_offset 0
    #puts "header says $ntrk tracks mformat = $mformat"
    if {$mformat == 0} {set midi(midishow_sep)  "chan"}
    }


proc normalizeActivity {vector} {
set fnorm 0.0
if {[llength $vector] < 1} {return vector}
foreach pc $vector {
  set pc [expr double($pc)]
  set fnorm [expr $fnorm + ($pc*$pc)]
  }
set fnorm [expr sqrt($fnorm)]
set nvector [list]
foreach pc $vector {
  lappend nvector [expr $pc/$fnorm]}
return $nvector
}

proc get_midi_info_for {} {
 global midi_info midi exec_out
 global midilength
 set midilength 0
 set fileexist [file exist $midi(midifilein)]
 if {$fileexist} {
   set exec_options "[list $midi(midifilein) ]"
   set cmd "exec [list $midi(path_midistats)] $exec_options"
   catch {eval $cmd} midi_info
   set exec_out $cmd\n$midi_info
   update_console_page
   return $midi_info
   } else {
   set msg "Unable to find file $midi(midifilein). Perhaps you should \
   clear the recent history."
   show_message_page $msg word
   }
 }

proc parse_midi_info {midi_info} {
global ntrks
global trkinfo
global ppqn
global cprogcolor
global cprogs
global cprogsact
global pitchcl
global channel_activity
global midierror
global useflats
global compactMidifile
global midi
array unset trkinfo
set midierror ""
set ntrks 0
set rootfolder $midi(rootfolder)
set rootfolderbytes [string length $rootfolder]
incr rootfolderbytes
set compactMidifile [string range $midi(midifilein) $rootfolderbytes end]
if {[string length $compactMidifile] > 40} {
   set a [string range $compactMidifile 0 40]
   set b [string range $compactMidifile 40 end]
   set compactMidifile $a\n$b
   }
foreach line [split $midi_info '\n'] {
  #puts $line
  set trk 0
  #remove any embedded double quotes and braces if present
  set line [string map {\" {} \{ {} \} {}} $line]
  set info_id [lindex $line 0] 
  switch $info_id {
    ntrks {set ntrks [lindex $line 1]}
    ppqn {set ppqn [lindex $line 1]}
    tsignature {set tsignature [lindex $line 1]}
    trk {set t [lindex $line 1]
         set trkinfo($t) ""}
    progcolor {set cprogcolor [lrange $line 1 end]
               set cprogcolor [normalize_vectorlist $cprogcolor]
              }
    pitchact {set pitchcl [lrange $line 1 end]
               set pitchcl [normalize_vectorlist $pitchcl]
              }
    chnact   {set channel_activity [lrange $line 1 end]}
    progs {set cprogs [lrange $line 1 end]}
    progsact {set cprogsact [lrange $line 1 end]}
    Error: {set problem [lrange $line 1 end]
            set midierror  "defective file : $problem\t"
           }
    activetrack {set ntrks [lindex $line 1]
                 append midierror "only $ntrks valid tracks"}
    default {if {[info exist t]} {lappend trkinfo($t) $line }
            }
    }
 }
 set flats [expr [lindex $pitchcl 3] + [lindex $pitchcl 10]]
 set sharps [expr [lindex $pitchcl 1] + [lindex $pitchcl 6]]
 set useflats 0
 if {$flats > $sharps} {set useflats 1}
 set cprogsact [normalizeActivity $cprogsact]
 return 0
}

proc update_programmod {c p beat} {
  global programmod
  if {![info exist programmod($c)]}  {
     set programmod($c) "[list $beat] [list $p]"
      } else {
      set beatlist [lindex $programmod($c) 0] 
      lappend beatlist $beat
      set proglist [lindex $programmod($c) 1]
      lappend proglist $p
      set programmod($c) [list $beatlist $proglist]
      }
  }

proc update_tempomod {tempo beat} {
  global tempomod
  lappend tempomod [list $tempo $beat]
  }

proc program_mod {c beat} {
  global programmod
  if {![info exist programmod($c)]} {return -1}
  set beatlist [lindex $programmod($c) 0] 
  set proglist [lindex $programmod($c) 1]
  # get position of first beat value in beatlist which is greater than beat
  set n [llength $beatlist]
  for {set i 0} {$i < $n} {incr i} {
    if {[lindex $beatlist $i] > $beat} break
    }
  set index [expr $i -1]
  if {$index < 0} {return -1}
  return [lindex $proglist $index]
  }

proc list_progammod {} {
  global programmod
  global mlist
  set msg ""
  append msg "channel\tbeat number\tprogram\n"
  for {set i 0} {$i < 17} {incr i} {
    if {[info exist programmod($i)] == 0} {continue}
    set beatlist [lindex $programmod($i) 0]
    set proglist [lindex $programmod($i) 1]
    foreach b $beatlist p $proglist {
      append msg "$i\t$b\t[lindex $mlist $p]\n"
      }
    }
  popMessage $msg
  }


proc list_tempomod {} {
  global tempomod
  set msg ""
  append msg "tempo\tbeat number\n"
  foreach tempocmd $tempomod {
    set t [lindex $tempocmd 0]
    set b [lindex $tempocmd 1]
    append msg "$t\t$b\n"
    }
  popMessage $msg
  }  
  
proc list_timesigmod {} {
  global timesigmod
  set msg ""
  append msg "time sig\tbeat number\n"
  foreach tsigcmd $timesigmod {
    set t [lindex $tsigcmd 0]
    set b [lindex $tsigcmd 1]
    append msg "$t\t$b\n"
    }
  popMessage $msg
  }  

proc list_keysigmod {} {
  global keysigmod
  set msg ""
  append msg "key sig\tbeat number\n"
  foreach ksigcmd $keysigmod {
    set k [lindex $ksigcmd 0]
    set b [lindex $ksigcmd 1]
    append msg "$k\t$b\n"
    }
  popMessage $msg
  }  
 

proc get_trkinfo {channel nnotes nharmony pmean duration pitchbendCount cntlparamCount pressureCount quietTime rhythmpatterns token} {
 global ppqn
 global pitchbendsplit
 upvar 1 $channel c
 upvar 1 $nnotes n
 upvar 1 $nharmony h
 upvar 1 $pmean pavg
 upvar 1 $duration dur 
 upvar 1 $cntlparamCount cntlCount
 upvar 1 $pressureCount pressCount
 upvar 1 $pitchbendCount pbend
 upvar 1 $quietTime qtime
 upvar 1 $rhythmpatterns rpat
 set c [lindex $token 1]
 set n [lindex $token 3]
 set h [lindex $token 4]
 set qtime [lindex $token 9]
 set rpat [lindex $token 10]
 set pavg [lindex $token 5]
 set pavg [expr $pavg/($n +$h)]
 set dur [lindex $token 6]
 set dur [expr $dur / ($n + $h)]
 set dur [expr double($dur) / $ppqn]
 set dur [format %5.3f $dur]
 set cntlCount [lindex $token 7]
 set pressCount [lindex $token 8]
 if {[info exist pitchbendsplit($c)]} {
       set pbend $pitchbendsplit($c)
   } else {
       set pbend 0
   }
}


proc gatherMidiSummary {} {
global trkinfo
global ppqn
global ntrks
global addendum
global miditxt
global lastbeat
global lastpulse
global tempo
global pitchbends
global tempocmds
global mididuration
global keysig
global nkeysig
global timesig
global ntimesig
global nprogramchange
global pitchbendsplit
global tempomod
global timesigmod
global keysigmod
global midiTempo

set nkeysig 0
set ntimesig 0
set nprogramchange 0
set tempocmds 1
set addendum ""
if {[info exist pitchbendsplit]} {unset pitchbendsplit} 
set tempomod {}
set timesigmod {}
set keysigmod {}

set tempo 120
for {set i 1} {$i <= $ntrks} {incr i} {
   foreach token $trkinfo($i) {
     if {[lindex $token 0] == "cprogram"} {
        set c [lindex $token 1]
        set p [lindex $token 2]
        set beat [lindex $token 3]
        update_programmod $c $p $beat
     } elseif {[lindex $token 0] == "pitchbends"} {
      set pitchbends [lindex $token 1]
      if {$nvalue > 0} {append addendum " There are $pitchbends pitchbends split between channels"}
     } elseif {[lindex $token 0] == "pitchbendin"} {
      append addendum " [lindex $token 1] ([lindex $token 2]),"
      set pitchbendsplit([lindex $token 1]) [lindex $token 2]
     } elseif {[lindex $token 0] == "tempocmds"} {
      set nvalue [lindex $token 1]
      set tempocmds $nvalue
      if {$nvalue > 1} {append addendum " There are $nvalue tempo commands."}
     } elseif {[lindex $token 0] == "ctempo"} {
       update_tempomod [lindex $token 1] [lindex $token 2]
     } elseif {[lindex $token 0] == "programcmd"} {
      set nprogramchange [lindex $token 1]
      if {$nprogramchange > 1} {append addendum " The program assignment for any channel was modified $nprogramchange times."}
     } elseif {[lindex $token 0] == "tempo"} {
        set tempo [lindex $token 1]
        set midiTempo $tempo
        append miditxt(0) "The tempo is set to $tempo beats/minute."
     } elseif {[lindex $token 0] == "npulses"} {
	set lastpulse [lindex $token 1]
        set lastbeat [expr $lastpulse/$ppqn]
        append miditxt(0) " $lastbeat beats long."
     } elseif {[lindex $token 0] == "timesig"} {
        set timesig [lindex $token 1]
        lappend timesigmod [lrange $token 1 end]
        incr ntimesig
     } elseif {[lindex $token 0] == "keysig"} {
        set keysig [lindex $token 1]
        incr nkeysig
        lappend keysigmod [lrange $token 1 end]
     } 
   }
 }
set mididuration [expr 60.0*$lastbeat/$tempo]
set mididuration [format %6.1f $mididuration]
}



proc midi_type0_table {} {
global trkinfo
global mlist
global midi
global channel2program
global xchannel2program
global channel_activity
global activechan
global lastpulse

array unset activechan

set w .tinfo
$w.tree delete [$w.tree children {}]
set trknum 1

set nlines 1
foreach token $trkinfo(1) {
  if {[lindex $token 0] == "trkinfo"} {
    get_trkinfo channel nnotes nharmony pmean duration pitchbendCount cntlparamCount pressureCount quietTime rhythmpatterns $token
    set activechan($channel) 1
    set totalnotes [expr $nnotes+$nharmony]
    set channel2program($channel) $xchannel2program($channel)
    set chan_action [lindex $channel_activity [expr $channel -1]]
    set chan_spread [expr ($lastpulse - $quietTime)]
    set chan_spread [expr $chan_spread/double($lastpulse)]
    set chan_spread [format %5.3f $chan_spread]
    if {$channel == 10} {
      set prog [list drum channel]
    } else {
      set prog $xchannel2program($channel)
      set prog [lindex $mlist $prog]
    }
    set outline "$trknum $channel [list $prog ]"
    append outline " $nnotes/$totalnotes $chan_spread $pmean $duration $rhythmpatterns $pitchbendCount $cntlparamCount"
    #append outline " $nnotes/$totalnotes $chan_spread $pmean $duration $pitchbendCount $cntlparamCount $pressureCount"
    set id [$w.tree insert {} end -values $outline -tag fnt]
    incr nlines
    }
  }
  $w.tree configure -height $nlines
}

proc midiType1Table {} {
global trkinfo
global mlist
global midi
global channel2program
global xchannel2program
global channel_activity
global ntrks
global activechan
global track2channel
global lastpulse

array unset activechan
array unset track2channel

set w .tinfo
$w.tree delete [$w.tree children {}]


for {set i 1} {$i <= $ntrks} {incr i} {
  foreach token $trkinfo($i) {
    if {[lindex $token 0] == "trkinfo"} {
      get_trkinfo channel nnotes nharmony pmean duration pitchbendCount cntlparamCount pressureCount quietTime rhythmpatterns $token
      set activechan($channel) 1
      set track2channel($i) $channel
      set totalnotes [expr $nnotes+$nharmony]
      set chan_action [lindex $channel_activity [expr $channel -1]]
      set chan_spread [expr ($lastpulse - $quietTime)]
      set chan_spread [expr $chan_spread/double($lastpulse)]
      set chan_spread [format %5.3f $chan_spread]
      set channel2program($channel) $xchannel2program($channel)
      if {$channel == 10} {
        set prog "drum channel"
      } else {
        set prog $xchannel2program($channel)
        set prog [lindex $mlist $prog]
      }
      set outline "$i $channel [list $prog ]"
      append outline " $nnotes/$totalnotes $chan_spread $pmean $duration $rhythmpatterns $pitchbendCount $cntlparamCount"
      #append outline " $nnotes/$totalnotes $chan_spread $pmean $duration $pitchbendCount $cntlparamCount $pressureCount"
      set id [$w.tree insert {} end -values $outline -tag fnt]
      }
   }
 }
}



proc grab_all_program_commands {} {
# Some type 1 midi files define all the program
# assignments in a separate track (eg last track).
# As a precaution we look for the program commands
# separately rather than rely on trkinfo
global ntrks
global trkinfo
global xchannel2program
for {set i 0} {$i < 17} {incr i}  {set xchannel2program($i) 0}
for {set i 1} {$i <= $ntrks} {incr i} {
  foreach token $trkinfo($i) {
     if {[lindex $token 0] == "program"} {
       set c [lindex $token 1]
       set p [lindex $token 2]
       set xchannel2program($c) $p
       }
  }
}
#for {set i 0} {$i < 17} {incr i} {
#  puts "chan $i prog $xchannel2program($i)"
#  }
}




proc midi_file_browser {} {
    # contains Bob Sheskey's Windows 95 fix for double click problem
    # i.e. wm withdraw .. destroy .temp
    # comp.lang.tcl 1997/12/07
    #
    global midi tcl_platform
    global active_sheet
    global miditype
    set filedir [file dirname $midi(midifilein)]
    set str "Windows 95"
    set os $tcl_platform(os)
    if {[string compare $os $str] == 0} {
        wm withdraw [toplevel .temp]
        grab .temp}
    set openfile [tk_getOpenFile -initialdir $filedir \
            -filetypes $miditype]
    if {[string length $openfile] < 1} {
	    return $midi(midifilein)}
    if {[string compare $os $str] == 0} {
        update
        destroy .temp
    }

    return $openfile
}

# Part 22.0	PercMap

set hlp_channel9 "\tPercView\n\n
This is an application for visualizing the percussion channel\
of a MIDI file. Percussion sequences in MIDI files tend to consist\
of various loops corresponding to one or more musical measures.\
These loops are best identified when the percussion sequences are\
displayed in a compact form.\n\n\
The percussion hits (events) are shown as a function of time in\
color coded form as vertical line sements.  Their minimum temporal\
separation is one sixteenth note.  if several percussion instruments\
play at the same time, they are stacked vertically. The colors refer\
to the type of percussion instrument. Thus bass drums, floor toms,\
and similar instruments are shown in bluish colors. Snare drums\
are red, hi-hats green, and etc. If you position the mouse cursor\
over one of the colored rectangles, the name of the instrument\
will appear on a status line.\n\n\
The play button will play whatever portion of the MIDI file that\
is exposed. You can scroll to the area of interest and resize the window\
to display the desired MIDI data.\
The spinbox besides the play button controls the speed of the playback.\
data. The value of 1.0 plays it at normal speed, fractions such as 0.5\
slows it down. In order for this to be effective, you must adjust it\
prior to clicking the play button.\n\n\
The hi-hat and some of the cymbol instruments beat like a metronome and\
may not provide useful information. You can suppress these instruments\
using the checkbox 'ignore hi-hat'.\n\n\
"

proc percMapInterface {} {
global df
global midi
global exec_out

set exec_out "percMapInterface\n"

set w .channel9
if {[winfo exist $w]} return
toplevel .channel9 
positionWindow .channel9

frame $w.header 
pack $w.header
frame $w.blk
frame $w.blk.left
frame $w.blk.right
pack $w.blk.left $w.blk.right -side left
pack $w.blk
label $w.header.filename -text "" -font $df -width 60
pack  $w.header.filename -side left -anchor w
button $w.blk.left.help -text help -font $df -width 9 -command {show_message_page $hlp_channel9 w}
button $w.blk.left.play -text play -font $df -width 9 -command perc_play_exposed
spinbox $w.blk.left.speed -from 0.2 -to 1.2 -increment 0.1 -font $df -width 4 -textvariable midi(percspeed)
frame $w.blk.left.mag
label $w.blk.left.maglab -text scale -font $df
spinbox $w.blk.left.magbox -values {0.25 0.50 1.0 2.0 4.0} -font $df -width 4 -textvariable midi(percmag) -command change_horizontal_resolution 
$w.blk.left.magbox set 0.5 
grid $w.blk.left.maglab $w.blk.left.magbox 
grid $w.blk.left.play $w.blk.left.speed
grid $w.blk.left.mag
grid $w.blk.left.help 

canvas $w.blk.right.can -height 100 -width 1000 -scrollregion {0. 0. 1000.0 50.} -xscrollcommand {.channel9.blk.right.scr set} -bg grey4
scrollbar .channel9.blk.right.scr -orient horiz -command {.channel9.blk.right.can xview}
label $w.blk.right.status -text ""
pack $w.blk.right.can
pack $w.blk.right.scr -fill x
pack $w.blk.right.status


frame $w.prf
label $w.prf.ignlab -text "ignore hi-hat" -font $df
checkbutton $w.prf.ignchk -variable midi(ignoreHiHat) -command switchIgnoreHiHat
label $w.prf.seplab -text "separate drums" -font $df
checkbutton $w.prf.sepchk -variable midi(separate) -command compute_drum_pattern
pack   $w.prf.ignlab $w.prf.ignchk $w.prf.seplab $w.prf.sepchk -side left 

bind_all_percussion_tags
compute_drum_pattern 
update_console_page
}

proc compareOnset {a b} {
    set a_onset [lindex $a 0]
    set b_onset [lindex $b 0]
    if {$a_onset > $b_onset} {
        return 1}  elseif {$a_onset < $b_onset} {
        return -1} else {return 0}
}

proc extractAndSortPercussionEvents {} {
  global midi
  global ppqn
  global sorted_events
  set ignoreperc {42 44 46 69 71 72}
  if {![file exist [list $midi(path_midi2abc)]]} {
       set msg "channel9 requires the executable midi2abc which you can\
 find in the midiAbc package. Click the settings button and indicate the\
 path to this file and restart this program."
      tk_messageBox -message $msg
      return
      }
  if {![file exist $midi(midifilein)]} {
       set msg "Cannot find the file $midi(midifilein). Use the open button to browse to the midi file that\
you want to analyze."
       tk_messageBox -message $msg
       return
       }
  set cmd "exec [list $midi(path_midi2abc)] [list $midi(midifilein)] -midigram"
  catch {eval $cmd} pianoresult
  set pianoresult [split $pianoresult \n]
  if {[llength $pianoresult] < 1} {
      return
      }
  set ppqn [lindex [lindex $pianoresult 0] 3]
  set eventlist {}
  foreach line $pianoresult {
      if {[llength $line] != 6} continue
      set begin [lindex $line 0]
      if {[string is double $begin] != 1} continue
      set c [lindex $line 3]
      if {$c != 10} continue
      set note [lindex $line 4]
      set velocity [lindex $line 5]
      if {[lindex $line 5] < 1} continue
      if {$note < 35 || $note > 81} continue
      if {$midi(ignoreHiHat) && [lsearch $ignoreperc $note] >= 0} continue
      lappend eventlist [list $begin $note $velocity]
      }
set sorted_events [lsort -command compareOnset $eventlist]
#return $sorted_events
}

proc show_percussion_info {note} {
global drumpatches
set patchnum [expr $note - 35]
set patchcolor [lindex [lindex $drumpatches $patchnum] 2]
set patchname [lindex [lindex $drumpatches $patchnum] 1]
#puts "$patchnum $patchname $patchcolor"
.channel9.blk.right.status configure -text "$patchnum $patchname"
}

proc compute_drum_pattern {} {
    global midi
    global ppqn
    global drumpatches
    global lastBeat
    global sorted_events
    global drumstrip rdrumstrip
    global gram_ndrums
    global exec_out

    extractAndSortPercussionEvents 

    array unset perc2color

    set mag $midi(percmag)
    if {[llength $sorted_events] < 2} return
    set ppqn4 [expr $ppqn/4]
    .channel9.blk.right.can delete all
   

    set ixlast 0
    set lastBeat 0
    set beatNumber 0
    set ix1 0
    set ypos 0
    set ix2 0
    foreach event $sorted_events {
        set begin [lindex $event 0]
        set note [lindex $event 1]
        set ix [expr $begin/$ppqn4]
        set beatNumber [expr $begin/$ppqn]
        if {$beatNumber > $lastBeat} {set lastBeat $beatNumber}
       
        
        if {$ix != $ixlast} {
           set ix1 [expr $ix*4*$mag]
           set ix2 [expr $ix1 + $mag]
           set ixlast $ix
           set ypos 0
           } else {
           incr ypos}

        if {[info exist perc2color($note)] == 0} {
           set patchnum [expr $note - 35]
           set patchcolor [lindex [lindex $drumpatches $patchnum] 2]
           if {[string length $patchcolor] > 1} {
             set xcol $patchcolor
           } else {
             puts "no color assigned for patch $patchnum [lindex [lindex $drumpatches $patchnum] 1]"
           }
         } else {
         set xcol $perc2color($note)
         }
           
      set iy1 [expr 10 + $ypos*11] 
      set iy2 [expr $iy1 + 8]

        #.channel9.blk.right.can create line $ix1 $iy1 $ix1 $iy2 -fill $xcol -width 3 -tag n$note -width 1
        .channel9.blk.right.can create rectangle $ix1 $iy1 $ix2 $iy2 -fill $xcol -width 3 -tag n$note -width 0
    }
    displayBeatGrid_for_perc $mag
    .channel9.blk.right.can configure -scrollregion [.channel9.blk.right.can bbox all]
    append exec_out "compute_drum_pattern\n"
}

proc displayBeatGrid_for_perc {mag} {
 global lastBeat
 global df
 set height 100
 set iy0  [expr $height -32 ]
 set iy1  [expr $height -22 ]
 set iy2  [expr $height -12 ]
 set iy3  [expr $height -2  ]
 set x 0
 set spacing [expr round(4/$mag)]
 if {$spacing < 1} {set spacing 1}
 while {$x < $lastBeat} {
    set x1  [expr $x*16*$mag]
    if {[expr $x % $spacing] == 0} {
    .channel9.blk.right.can create line $x1 $iy0 $x1 $iy2 -dash {1 1} -fill white
    .channel9.blk.right.can create text $x1 $iy3 -text $x -fill white -font $df 
    } else {
    .channel9.blk.right.can create line $x1 $iy1 $x1 $iy2 -dash {1 1} -fill white
    }
    incr x
    }
}

proc bind_all_percussion_tags {} {
global exec_out
for {set i 35} {$i < 81} {incr i} {
     .channel9.blk.right.can bind n$i <Enter> "show_percussion_info $i"
    }
append exec_out "bind_all_percussion_tags\n"
}

proc change_horizontal_resolution {} {
set xv [lindex [.channel9.blk.right.can xview] 0]
compute_drum_pattern
.channel9.blk.right.can xview moveto $xv
}

proc copy_midi_to_tmp_for_drums {fbeat tbeat} {
    global midi
    global exec_out
    if {![file exist $midi(path_midicopy)]} {
       set msg "cannot find $midi(path_midicopy). Install midicopy \
from the abcMIDI package, click settings and set the path to its location."
       tk_messageBox -message $msg
       return
       }
    set cmd "exec [list $midi(path_midicopy)]"
    append cmd " -frombeat $fbeat -tobeat $tbeat -chns 10 -speed $midi(percspeed)"
    append cmd " [list $midi(midifilein)] tmp.mid"
    catch {eval $cmd} midicopyresult
    set exec_out "percMap - play_exposed\n\n$cmd\n $midicopyresult\n"
    return $midicopyresult
}


proc perc_play_exposed {} {
global midi
global lastBeat
#set scrollregion [.channel9.blk.right.can cget -scrollregion]
set xv [.channel9.blk.right.can xview]
set fbeat [expr [lindex $xv 0] * $lastBeat]
set tbeat [expr [lindex $xv 1] * $lastBeat]
copy_midi_to_tmp_for_drums $fbeat $tbeat
if {![file exist $midi(path_midiplay)]} {
     set msg "You need to specify the path to a program which plays\
midi files using the settings button. The box to the right can contain\
 any runtime options."
     tk_messageBox -message $msg
     return
     }
set cmd "exec [list $midi(path_midiplay)]"
if {![file exist tmp.mid]} {
    set msg "Something is wrong. Midicopy should create a the tmp.mid
file."
    tk_messageBox -message $msg
    return
    }
append cmd " $midi(midiplay_options) tmp.mid &"
catch {eval $cmd} midiplayerresult
}


# Part 23.0           Pitch Class Maps

proc loadMidiFile {} {
# Extracts information from a midi file.
global midi
global pianoresult
global midilength
global lastbeat
global ntrks
global midicommands
global ppqn
global chanprog
global cleanData
global exec_out

append exec_out "\nloadMidiFile : extracting info from $midi(midifilein)"

if {$cleanData} return
if {![file exist $midi(midifilein)]} {
 set msg "Cannot find the file $midi(midifilein). Use the open button to browse to the midi file that\
you want to analyze."
       tk_messageBox -message $msg
       return -1
       }

if {![file exist $midi(path_midi2abc)]} {
    set msg "channel9 requires the executable midi2abc which you can\
 find in the midiAbc package. Click the settings button and indicate the\
 path to this file and restart this program."
      tk_messageBox -message $msg
      return -1
      }


readMidiFileHeader $midi(midifilein); # read midi header
set cmd "exec [list $midi(path_midi2abc)] [list $midi(midifilein)] -midigram"
catch {eval $cmd} pianoresult
#puts "midifilein = $midi(midifilein)"
set nrec [llength $pianoresult]
set midilength [lindex $pianoresult [expr $nrec -1]]
if {![string is integer $midilength]} {
	.info.txt insert insert "cannot process this file" red
	return
#except for midi2abc -mftext, all other functions will fail.
#midi2abc -midigram does not return midilength and midicopy
#also fails. Midifile.c exits the application when it encounters
#an error.
        }
set pianoresult [split $pianoresult \n]

set ppqn [lindex [lindex $pianoresult 0] 3]
set lastbeat [expr $midilength/$ppqn]
#puts "nrec = $nrec midilength = $midilength lastbeat = $lastbeat"
set midicommands [lsort -command compare_onset $pianoresult ]

for {set i 0} {$i < 17} {incr i} {
   set chanprog($i) 0
   }
}

set hlp_PitchClassMap "Pitch Class Map\n\n\
Like the tableau, this diagram plots the note onsets as a\
function of the beat number. The channels are not separated\
here and there is more room to indicate the note pitch names.
"

proc updateTableauWindows {} {
 if {[winfo exist .ribbon]} simple_tableau
 if {[winfo exist .ptableau]} detailed_tableau
 }

proc noteRibbon {} {
# creates window for the simple and detailed tableau
global df
global midie
global hlp_PitchClassMap
if {![winfo exist .ribbon]} {
  toplevel .ribbon
  positionWindow ".ribbon"
  label .ribbon.filename -text "" -font $df
  set v .ribbon.buttonfrm
  frame  $v 
  button $v.help -text help -font $df -command {show_message_page $hlp_PitchClassMap word}
  button $v.play -text play -font $df
  checkbutton $v.circle -text "circle of fifths" -variable midi(tableau5) -font $df -command updateTableauWindows
  pack $v.play $v.circle $v.help -side left -anchor nw
  
  set w .ribbon.frm
  frame $w
  canvas $w.can -height 160 -width 1000 -scrollregion {0. 0. 10000.0 50.} -xscrollcommand {.ribbon.scr set} -bg grey4
  canvas $w.labcan -height 160 -width 50 -bg grey4
  scrollbar .ribbon.scr -orient horiz -command {.ribbon.frm.can xview}
  label $w.status -text ""
  pack $w.labcan $w.can -side left
  pack .ribbon.scr -fill x -side bottom
  pack $w.status
  pack .ribbon.filename -side top
  pack .ribbon.buttonfrm -side top -anchor nw
  pack $w
  fillRibbonSideBar
  }
}

proc fillRibbonSideBar {} {
global midi
global sharpnotes
set sharp5notes {C G D A E B F# C# G# D# A# F}
set dfsmall [font create -size 8]
for {set i 0} {$i < 12} {incr i} {
  if {$midi(tableau5)} {
    label .ribbon.frm.labcan.$i -text [lindex $sharp5notes $i] -width 2 -fg white -font $dfsmall -bg black
   } else {
    label .ribbon.frm.labcan.$i -text [lindex $sharpnotes $i] -width 2 -fg white -font $dfsmall -bg black
   }  
   if {[expr $i % 2] == 0} {
      .ribbon.frm.labcan create window 8 [expr  ($i*8) + 2] -window .ribbon.frm.labcan.$i -anchor nw
     } else {
      .ribbon.frm.labcan create window 30 [expr  ($i*8) + 2] -window .ribbon.frm.labcan.$i -anchor nw
     }
  }
.ribbon.frm.labcan configure -height 150 
}

set hlp_tableau "Tableau - Pitch Class Map

For each channel, the pitch classes of each note onset are shown as\
function of time up to a resolution of 1/16 note. These onsets are\
color coded according to their midi program (musical instrument).\
The dot size menu controls how prominent these onsets appear in the\
plots. If the dot sizes are too large, the onsets may overlap.\n\
Hovering the mouse pointer on one of the channel checkboxes will\
pop up the midi program number and name. The lower horizontal scale\
indicates the beat number (quarter note) position.\n\n\
Ticking the circle of fifths checkbutton, will lay out the note\
onsets according to the circle of fifths (C,G,D, etc) instead of\
sequentially (C,C#,D, etc). This may produce a more compact\
representation making it easier to detect key changes.\n\n\
Like the midi structure view, many of the other functions, play\
and plots are sensitive to the channels that are selected in the\
checkboxes and the exposed region. If no channels are ticked then\
the functions apply to all channels. In addition, you can select\
a time interval by dragging the mouse pointer over a region while\
depressing the left mouse button. The width of the tableau can\
be adjusted and only the visible portion is played or plotted.
"

# for handling x scrolling for tableau
proc BindXview_for_tableau {lists args} {
    foreach l $lists {
        eval {$l xview} $args
    }
    updateWindows_for_tableau
}



proc tableauWindow {} {
# creates window for the simple and detailed tableau
global midi
global df
set w .ptableau
if {![winfo exist $w]} {
  toplevel $w
  positionWindow $w
  set w .ptableau.frm
  frame $w
  canvas $w.can -height 60 -width 1000 -scrollregion {0. 0. 10000.0 50.} -xscrollcommand {.ptableau.scr set} -bg grey20
  scrollbar .ptableau.scr -orient horiz -bg #002000\
   -activebackground #004000 -command [list BindXview_for_tableau [list .ptableau.frm.can]]
  canvas $w.chkscan -width 50 -height 300 -bg #002000
  label .ptableau.status -text "$midi(midifilein)"
  frame $w.header
  button $w.header.play -text play -command {playExposed tableau} -font $df
  menubutton $w.header.dot -text "dot size" -font $df -menu $w.header.dot.items
  menu $w.header.dot.items -tearoff 0
  $w.header.dot.items add radiobutton -label 0 -font $df -command {dotmod 0}
  $w.header.dot.items add radiobutton -label 1 -font $df -command {dotmod 1}
  $w.header.dot.items add radiobutton -label 2 -font $df -command {dotmod 2}
  $w.header.dot.items add radiobutton -label 3 -font $df -command {dotmod 3}
  $w.header.dot.items add radiobutton -label 4 -font $df -command {dotmod 4}
  $w.header.dot.items add radiobutton -label 5 -font $df -command {dotmod 5}

 menubutton $w.header.plot -text plot -menu $w.header.plot.items -font $df
  menu $w.header.plot.items -tearoff 0
 $w.header.plot.items add command  -label "pitch class plot" -font $df \
            -command {
                      midi_statistics pitch tableau
                      show_note_distribution
                     } 
 $w.header.plot.items add command  -label "pitch distribution" -font $df \
            -command {
                      midi_statistics pitch tableau
                      plotmidi_pitch_pdf
                      }
 $w.header.plot.items  add command -label "onset distribution" -font $df\
            -command {
                      midi_statistics onset tableau
                      plotmidi_onset_pdf 
                     }
 $w.header.plot.items add command  -label "note duration distribution" -font $df \
            -command {
                      midi_statistics duration tableau
                      plotmidi_duration_pdf
                     }
 $w.header.plot.items add command  -label "velocity distribution" -font $df \
            -command {
                      midi_statistics velocity tableau
                      plotmidi_velocity_pdf
                      }
 $w.header.plot.items add command -label keymap -font $df -command {keymap tableau}
 $w.header.plot.items add command -label chordgram -font $df -command {chordgram_plot tableau}
 $w.header.plot.items add command -label notegram -font $df -command {notegram_plot tableau}
 $w.header.plot.items add command -label "pitch class map" -font $df -command simple_tableau
 $w.header.plot.items add command -label "chordtext" -font $df -command {chordtext_window tableau}
 tooltip::tooltip $w.header.plot "Various plots including chordgram and notegram"


  checkbutton $w.header.circle -text "circle of fifths" -variable midi(tableau5) -font $df -command updateTableauWindows

  button $w.header.abc -text abc -font $df -command tableau_abc
 
  button $w.header.help -text help -font $df -command {show_message_page $hlp_tableau word} -width 4
  label $w.header.msg -text "" -font $df -relief flat
  pack $w.header.play $w.header.dot $w.header.circle $w.header.plot $w.header.abc  $w.header.help $w.header.msg -side left -anchor nw
  pack .ptableau.status
  pack $w.header -side top -anchor nw
  pack .ptableau.scr -fill x -side bottom 
  pack $w.chkscan $w.can -side left
  pack $w

  bind .ptableau.frm.can <ButtonPress-1> {tableau_Button1Press %x %y}
  bind .ptableau.frm.can <ButtonRelease-1> tableau_Button1Release
  bind .ptableau.frm.can <Double-Button-1> tableau_ClearMark

  }
  .ptableau.status configure -text "$midi(midifilein)"
}

proc tableau_Button1Press {x y} {
    global tableauHeight40
    set xc [.ptableau.frm.can canvasx $x]
    .ptableau.frm.can raise mark
    .ptableau.frm.can coords mark $xc 0 $xc $tableauHeight40
    bind .ptableau.frm.can <Motion> { tableau_Button1Motion %x }
}

proc tableau_Button1Motion {x} {
    global tableauHeight40
    set xc [.ptableau.frm.can canvasx $x]
    if {$xc < 0} { set xc 0 }
    set co [.ptableau.frm.can coords mark]
    .ptableau.frm.can coords mark [lindex $co 0] 0 $xc $tableauHeight40
}

proc tableau_Button1Release {} {
    bind .ptableau.frm.can <Motion> {}
    set co [.ptableau.frm.can coords mark]
    if {[winfo exist .midistructure]} {
          tableau_migrate_to_midistruct $co
      }
   updateWindows_for_tableau
   }

proc tableau_migrate_to_midistruct {co} {
global midistructureheight
global pixels_per_beat
set beatlimits [chordgram_limits $co]
set beat1 [expr [lindex $beatlimits 0]*$pixels_per_beat]
set beat2 [expr [lindex $beatlimits 1]*$pixels_per_beat]
.midistructure.can coords mark $beat1 0 $beat2 $midistructureheight
}

proc tableau_ClearMark {} {
    .ptableau.frm.can coords mark -1 -1 -1 -1
}



proc dotmod {size} {
global midi
set midi(dotsize) $size
detailed_tableau
}

proc tableau_midi_limits {can} {
    global lastpulse
    global ppqn
    if {![winfo exists $can]} {return "0 $lastpulse"}
    set co [$can coords mark]
    #   is there a marked region of reasonable extent ?
    set extent [expr [lindex $co 2] - [lindex $co 0]]
    puts "extent = $extent"
    if {$extent > 10} {
        set xvleft [lindex $co 0]
        set xvright [lindex $co 2]
    } else {
        #get start and end time of displayed area
        set xv [$can xview]
        #puts $xv
        set scrollregion [$can cget -scrollregion]
        #puts $scrollregion
        set xvleft [lindex $xv 0]
        set xvright [lindex $xv 1]
        set width [lindex $scrollregion 2]
        set xvleft [expr $xvleft*$width]
        set xvright [expr $xvright*$width]
    }

    set begin [expr round($xvleft/4)]
    set end [expr round($xvright/4)]
    puts "begin = $begin end = $end"
    if {$begin < 0} {
        set $begin 0
    }
    return [list $begin $end]
}



proc displayBeatGrid {height xspacing xmult mag can} {
 global lastbeat
 global df
 set mag 1
 set iy0  [expr $height -40 ]
 set iy1  [expr $height -30 ]
 set iy2  [expr $height -20 ]
 set iy3  [expr $height -10  ]
 set x 0
 set spacing [expr round(4/$mag)]
 if {$spacing < 1} {set spacing 1}
 while {$x < $lastbeat} {
    set x1  [expr $x*$xspacing*$mag]
    if {[expr $x % $spacing] == 0} {
    $can create line $x1 $iy0 $x1 $iy2 -dash {1 1} -fill white
    $can create text $x1 $iy3 -text [expr $x * $xmult] -fill white -font $df
    } else {
    $can create line $x1 $iy1 $x1 $iy2 -dash {1 1} -fill white
    }
    incr x
    }
}

proc extractPitchClasses {notecode} {
set representation [binary_to_pitchclass_codes $notecode]
return $representation
}


proc binary_to_pitchclass_codes {binaryvector} {
# The binaryvector is a 12 bit number where every bit
# references one of the 11 pitch classes. This function
# returns the positions of all the on-bits in the number
# or a list of all the pitch classes.
global sharpnotes
global flatnotes
global useflats
set useflats 0
set i 0
set pitchcodelist [list]
while {$binaryvector > 0} {
  if {[expr $binaryvector % 2] == 1} {
   lappend pitchcodelist $i
   }
 set binaryvector [expr $binaryvector/2]
 incr i
 }
return $pitchcodelist
}

proc simple_tableau {} {
global midi
global df

set permut5th {0 7 2 9 4 11 6 1 8 3 10 5}
loadMidiFile
noteRibbon
.ribbon.frm.can delete all

set result [get_note_patterns]
set notepat [lindex $result 0]
set size [dict get $notepat size]
for {set i 0} {$i < $size} {incr i} {
  set notecode [dict get $notepat $i]
  set codes [extractPitchClasses $notecode]
  foreach code $codes {

  if {$midi(tableau5)} {
        set code [lindex $permut5th $code]
     } 

    set ix1 $i
    #set ix1 [expr $i*2]
    set iy1 [expr $code*8 + 4]
    set iy2 [expr $iy1 + 3]
    .ribbon.frm.can create rectangle $ix1 $iy1 $ix1 $iy2 -fill yellow -width 0
    incr i
    }
  }
set region "0 0 $i 150"
.ribbon.frm.can configure -height 150 -scrollregion $region
displayBeatGrid 145 16 4 1 .ribbon.frm.can
.ribbon.filename configure -text $midi(midifilein)
}

set progmapper {
 0  0  0  0  0  0  0  0
 0  1  1  1  1  1  1  2
 3  3  3  3  3  3  3  3
 2  2  4  4  4  4  4  2
 4  4  4  4  4  4  4  4
 5  5  5  5  5  2  6  8
 6  6  6  6  6  6  6  6
 7  7  7  7  7  7  7  7
 9  9  9  9  9  9  9  9
 9  9  9  9  9  9  9  9
10 10 10 10 10 10 10 10
10 10 10 10 10 10 10 10
11 11 11 11 11 11 11 11
 2  2  2  2  2  9  6  9 
 1  1  8  8  8  8  8  1
 11 11 11 11 11 11 11 11
}

proc plot_tableau_data {} {
# new code follows here
#
  global midi
  global df
  global midicommands
  global ppqn
  global chn2prg
  global chanlist
  global progmapper
  global groupcolors
  global mlist

  set permut5th {0 7 2 9 4 11 6 1 8 3 10 5}
  set dotsize $midi(dotsize)
  set dotsizehalf [expr $dotsize/2]
  set ppqn4 [expr $ppqn/4]
  set maxwidth 0
  for {set i 0} {$i < 17} {incr i} {set chn2prg($i) 0}
  foreach line $midicommands {
     set begin [lindex $line 0]
     set end [lindex $line 1]
     if {[llength $line] == 6} {
       set begin [expr $begin/$ppqn4]
       if {$begin > $maxwidth} {set maxwidth $begin}
       set t [lindex $line 2]
       set c [lindex $line 3]
       set pitch [lindex $line 4]
       set pitchindex [expr $pitch % 12]
       if {$midi(tableau5)} {
          set pitchindex [lindex $permut5th $pitchindex]
          } 
       if {$c == 10} {
         continue
       } else {
         if {[info exist chn2prg($c)]} {
            set p $chn2prg($c)
         } else {
            set p 0
         }
         set g [lindex $progmapper $p]
         set color [lindex $groupcolors $g]
       }

    set row [lsearch $chanlist $c]

    set ix1 [expr $begin ]
    set iy1 [expr $pitchindex*4 + $row*50]
    set iy2 [expr $iy1 + 2 + $dotsize]
    set ix2 [expr $ix1 + $dotsizehalf]
    .ptableau.frm.can create rectangle $ix1 $iy1 $ix2 $iy2 -fill $color -width 0 -tag r$row
    }

    if {$end == "Program"} {
       set c [lindex $line 2]
       set p [lindex $line 3]
       set chn2prg($c) $p 
       set g [lindex $progmapper $p]
       }
    }
foreach c $chanlist {
  checkbutton .ptableau.frm.chkscan.$c -text $c -background #606070 -width 2 -fg black -variable midichannels($c) -font $df -command updateWindows_for_tableau
  set row [lsearch $chanlist $c]
  .ptableau.frm.chkscan create window 4 [expr $row*50 +10] -window .ptableau.frm.chkscan.$c -anchor nw
  set prog $chn2prg($c)
  tooltip::tooltip .ptableau.frm.chkscan.$c "[lindex $mlist $prog]"
  }

return $maxwidth
}



proc detailed_tableau {} {
# creates separate pitch class plots for the different
# tracks.
global ntrks
global notepat
global activechan
global chanlist
global beatsperbar
global lastTableau
global tableauHeight40
global exec_out

set exec_out "detailed_tableau"

loadMidiFile
set lastTableau "pitch"
update_console_page


set chanlist [list]
for {set i 1} {$i <= 16} {incr i} {
  if {![info exist activechan($i)]} continue
  if {$activechan($i) > 0 && $i != 10} {lappend chanlist $i}
  }

#puts "there are [llength $trklist] channels in the file."
set tableauHeight40 [expr [llength $chanlist]*50]
set tableauHeight [expr $tableauHeight40 + 40]
tableauWindow
.ptableau.frm.can delete all
# destroy buttons
for {set i 1} {$i<17} {incr i} {
  destroy .ptableau.frm.chkscan.$i
  }


.ptableau.frm.can create rect -1 -1 -1 -1 -tags mark -fill gray35 -stipple gray12

# outline channel bands
set i 0
foreach chan $chanlist {
   set iy2 [expr ($i+1)*50]
   set iy1 [expr $iy2 - 50] 
# distinguish the tracks by different shade of gray background
   if {[expr $i % 2] ==  1} {
     .ptableau.frm.can create rectangle 0 $iy1 10000 $iy2 -fill #151505 -width 0 -tag row$i
   } else {
     .ptableau.frm.can create rectangle 0 $iy1 10000 $iy2 -fill #05050A -width 0 -tag row$i
   }
     .ptableau.frm.can bind row$i <Enter> "highlightTableauStrip $i"
     .ptableau.frm.can bind row$i <Leave> "unhighlightTableauStrip $i"
   incr i
}


set maxsize [plot_tableau_data]

set region "0 0 $maxsize $tableauHeight"
.ptableau.frm.can configure -height $tableauHeight -scrollregion $region
.ptableau.frm.chkscan configure -height $tableauHeight

set spacing [expr 4*$beatsperbar]
#put barlines
for {set ix 0} {$ix < $maxsize} {incr ix $spacing} {
  .ptableau.frm.can create line $ix 0 $ix $tableauHeight -fill #606060 -stipple gray25 -width 2
  }

displayBeatGrid $tableauHeight 16 4 1 .ptableau.frm.can
}

proc highlightTableauStrip {i} {
global tableauRowColor
global chanlist
global chn2prg
global mlist
global df
set chan [lindex $chanlist $i]
set p $chn2prg($chan)
set p [lindex $mlist $p]
set tableauRowColor [.ptableau.frm.can itemcget r$i -fill]
.ptableau.frm.can itemconfigure r$i -fill white 
.ptableau.frm.header.msg configure -text $p -relief flat
}

proc unhighlightTableauStrip {i} {
global tableauRowColor
.ptableau.frm.can itemconfigure r$i -fill $tableauRowColor 
.ptableau.frm.header.msg configure -text ""
}


proc playExposed {source} {
global midi
global lastbeat
global midichannels
global exec_out
set exec_out "playExposed\ncopyMidiToTmp $source\n"
copyMidiToTmp $source
set cmd "exec [list $midi(path_midiplay)]"
if {![file exist tmp.mid]} {
    set msg "Something is wrong. Midicopy should create a the tmp.mid
file."
    tk_messageBox -message $msg
    return
    }
append cmd " $midi(midiplay_options) tmp.mid &"
catch {eval $cmd} midiplayerresult
set midi(outfilename) tmp.mid
append exec_out "\n$cmd\n$midiplayerresult"
update_console_page
}

proc tableau_abc {} {
global midi
global midichannels
global exec_out
set exec_out ""
set limits  [tableau_limits]
set options ""
if {[llength $limits] > 1} {
  set fbeat [lindex $limits 0]
  set tbeat [lindex $limits 1]
  append options " -frombeat $fbeat -tobeat $tbeat "
  } 
  set trkchn ""
  for {set i 1} {$i < 17} {incr i} {
     if {$midichannels($i)} {append trkchn "$i,"}
     }
  if {[string length $trkchn] > 0} {
         append options "-chns $trkchn"}
  set cmd "exec [list $midi(path_midicopy)]  $options"
  lappend cmd  $midi(midifilein) tmp.mid
  catch {eval $cmd} miditime
  append exec_out "tableau_abc\n\n$cmd\n\$miditime"

  set title [file root [file tail $midi(midifilein)]]
  set options ""
  if {$midi(midirest) > 0} {set options [concat $options "-sr $midi(midirest)"]}
  set cmd "exec [list $midi(path_midi2abc)] tmp.mid $options -noly -title [list $title]" 
  catch {eval $cmd} result
  append exec_out "\n$cmd"
  edit_abc_output $result
}

proc tableau_limits {} {
global lastbeat
set co [.ptableau.frm.can coords mark]
#   is there a marked region of reasonable extent ?
set extent [expr [lindex $co 2] - [lindex $co 0]]
if {$extent > 10} {
        set fbeat  [expr round([lindex $co 0]/4)]
        set tbeat [expr round([lindex $co 2]/4)]
  } else {
        set xv [.ptableau.frm.can xview]
        set fbeat [expr [lindex $xv 0] * $lastbeat]
        set tbeat [expr [lindex $xv 1] * $lastbeat]
        }
return [list $fbeat $tbeat]
}





# Part 24.0           Console Page Support Functions

#source warning.tcl

proc update_console_page {} {
    global exec_out
    if {[winfo exist .console]} {show_console_page $exec_out char}
}

proc show_console_page {text wrapmode} {
    global active_sheet df
    #remove_old_sheet
    set p .console
    set pat1 {Error in line-char ([0-9]+)\-([0-9]+)}
    set pat2 {Warning in line-char ([0-9]+)\-([0-9]+)}
    if [winfo exist .console] {
        $p.t configure -state normal -font $df
        $p.t delete 1.0 end
        set taglist [$p.t tag names]
        foreach t $taglist {$p.t tag delete $t}
    } else {
        toplevel $p
        positionWindow $p
        text $p.t -height 15 -width 50 -wrap $wrapmode -font $df -yscrollcommand {
            .console.ysbar set}
        scrollbar $p.ysbar -orient vertical -width 16 -command {.console.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p -expand true -fill both
    }
    $p.t tag configure grey -background grey80
    set textlist [split $text \n]
    set lkount 1
    foreach textline $textlist {
        set ln 0
        set r [regexp $pat1 $textline result ln charpos]
        set r [regexp $pat2 $textline result ln charpos]
        if {$ln} {
            $p.t tag configure m$lkount -foreground darkblue
            $p.t insert end $textline\n m$lkount
            $p.t tag bind m$lkount <1> "highlight_line $lkount $ln $charpos"
        } else {
            $p.t insert end $textline\n
        }
        incr lkount
    }
    #$p.t configure -state disabled
    #set active_sheet notice
    #pack $p
    raise $p .
    focus $p
}

proc show_tmpfile {} {
    global midi df
    set p .tmpfile
    set num 0
    if [winfo exist $p] {destroy $p}
    toplevel $p
    positionWindow ".tmpfile"
    text $p.t -height 15 -width 80 -wrap char \
            -font $df -yscrollcommand ".tmpfile.ysbar set"
    scrollbar $p.ysbar -orient vertical -command {.tmpfile.t yview}
    pack $p.ysbar -side right -fill y -in $p
    pack $p.t -in $p -expand y -fill both
    $p.t tag configure grey -background grey80
    $p.t tag configure red -foreground red
    set handle [open X.tmp]
    while {[eof $handle] != 1} {
        gets $handle line
        incr num
        $p.t insert end "$num: $line\n"
    }
    close $handle
}

proc save_tmpfile {} {
    global midi
    global types
    set filedir [file dirname $midi(midi_save)]
    set midi(abc_save) [tk_getSaveFile -initialdir $filedir -filetypes $types]
    file copy -force  X.tmp $midi(abc_save)
    puts "copied X.tmp to $midi(abc_save)"
}

proc save_output_midi_file {} {
    global midi
    set midiExt ".mid"
    set midiExt {{{midi files} {*.mid}}}
    set filedir [file dirname $midi(midi_save)]
    set midi(abc_save) [tk_getSaveFile -initialdir $filedir -filetypes $midiExt]
    file copy -force  $midi(outfilename) $midi(abc_save)
    puts "done"
}


proc highlight_line {line1 line2 charpos} {
    .notice.t tag remove grey 0.0 end
    .notice.t tag  add grey $line1.0 $line1.end
    highlight_xtmp_line $line2 $charpos
}

proc highlight_xtmp_line {line charpos} {
    global tmp_clock console_clock
    set rightshift [expr int(log10($line))]
    set charpos [expr $charpos + $rightshift +3]
    set charpos2 [expr $charpos+1]
    #if {[winfo exist .tmpfile] == 0\
    #            || $tmp_clock != $console_clock} show_tmpfile
    show_tmpfile 
    .tmpfile.t tag remove grey 0.0 end
    .tmpfile.t tag remove red 0.0 end
    .tmpfile.t tag add grey $line.0 $line.end
    .tmpfile.t tag add red $line.$charpos $line.$charpos2
    set viewline [expr $line -5]
    if {$viewline < 1} {set $viewline 1}
    .tmpfile.t yview $viewline
    #set tmp_clock $console_clock
}
# end of source.tcl


proc show_message_page {text wrapmode} {
    global active_sheet df
    #remove_old_sheet
    set p .notice
    if [winfo exist .notice] {
        $p.t configure -state normal -font $df
        $p.t delete 1.0 end
        $p.t insert end $text
        #   $p.t configure -state disabled -wrap $wrapmode
    } else {
        toplevel $p
        positionWindow $p
        text $p.t -height 15 -width 50 -wrap $wrapmode -font $df -yscrollcommand {.notice.ysbar set}
        scrollbar $p.ysbar -orient vertical -command {.notice.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p -fill both -expand true
        $p.t insert end $text
        #   $p.t configure -state disabled
    }
    raise $p .
}

proc webhelp {} {
global midi
set url "https://midiexplorer.sourceforge.io/"
set cmd "exec [list $midi(browser)] $url &"
eval $cmd
}


proc set_external_programs {} {
global df
global midi
set w .support
if {[winfo exist $w]} {
  raise $w .
  return}

toplevel $w
positionWindow $w
label $w.header -text executables -font $df
grid $w.header -row 0 -column 1

button $w.abcmidibut -text "abcmidi folder" -width 14 -command {locate_abcmidi_executables} -font $df
entry $w.abcmidient -width 64 -relief sunken -textvariable midi(dir_abcmidi) -font $df
grid $w.abcmidibut -row 1 -column 1
grid $w.abcmidient -row 1 -column 2
bind $w.abcmidient <Return> {focus .support.header
                             set_abcmidi_executables 
		            }

button $w.browserbut -text "internet browser" -width 14 -command {locate_browser} -font $df
entry $w.browserent -width 64 -relief sunken -textvariable midi(browser) -font $df
grid $w.browserbut -row 10 -column 1
grid $w.browserent -row 10 -column 2
bind $w.browserent <Return> {focus .support.header}

button $w.gsbut -text "ghostscript" -width 14 -command {locate_ghostscript} -font $df
entry $w.gsent -width 64 -relief sunken -textvariable midi(path_gs) -font $df
grid $w.gsbut -row 11 -column 1
grid $w.gsent -row 11 -column 2
bind $w.gsent <Return> {focus .support.header}
}


proc set_midi_players {} {
global df
global player1 player2 player3
global player1opt player2opt player3opt
global midi
set w .midiplayer
if {[winfo exist $w]} {
  raise $w .
  return}

toplevel $w
positionWindow $w

label $w.header -text "midi player" -font $df
grid $w.header -row 0 -column 1

radiobutton $w.player1rad -command set_midiplayer -variable midi(player_sel) -value 1 
button $w.player1but -text "midiplayer 1" -width 14 -font $df\
   -command {setpath player1; .midiplayer.player1rad invoke} 
entry $w.player1ent -width 48 -relief sunken -textvariable midi(player1) -font $df
grid $w.player1rad -row 2 -column 0
grid $w.player1but -row 2 -column 1
grid $w.player1ent -row 2 -column 2
bind $w.player1ent <Return> {set_midiplayer
                             focus .midiplayer.header}

button $w.player1optbut -text "midiplayer options" -width 14 -command {}  -font $df
entry $w.player1optent -width 48 -relief sunken -textvariable midi(player1opt) -font $df
grid $w.player1optbut -row 3 -column 1
grid $w.player1optent -row 3 -column 2
bind $w.player1optent <Return> {set_midiplayer
                                focus .midiplayer.header}

radiobutton $w.player2rad -command set_midiplayer -variable midi(player_sel) -value 2
button $w.player2but -text "midiplayer 2" -width 14 -font $df\
   -command {setpath player2; .midiplayer.player2rad invoke} 
entry $w.player2ent -width 48 -relief sunken -textvariable midi(player2) -font $df
grid $w.player2rad -row 4 -column 0
grid $w.player2but -row 4 -column 1
grid $w.player2ent -row 4 -column 2
bind $w.player2ent <Return> {set_midiplayer
                             focus .midiplayer.header}

button $w.player2optbut -text "midiplayer 2 options" -width 14 -command {}  -font $df
entry $w.player2optent -width 48 -relief sunken -textvariable midi(player2opt) -font $df

grid $w.player2optbut -row 5 -column 1
grid $w.player2optent -row 5 -column 2
bind $w.player2optent <Return> {set_midiplayer
                                focus .midiplayer.header}

radiobutton $w.player3rad -command set_midiplayer -variable midi(player_sel) -value 3
button $w.player3but -text "midiplayer 3" -width 14 -font $df \
   -command {setpath player3; .midiplayer.player3rad invoke} 
entry $w.player3ent -width 48 -relief sunken -textvariable midi(player3) -font $df
grid $w.player3rad -row 6 -column 0
grid $w.player3but -row 6 -column 1
grid $w.player3ent -row 6 -column 2
bind $w.player3ent <Return> {set_midiplayer
                             focus .midiplayer.header}

button $w.player3optbut -text "midiplayer 3 options" -width 14 -command {}  -font $df
entry $w.player3optent -width 48 -relief sunken -textvariable midi(player3opt) -font $df
grid $w.player3optbut -row 7 -column 1
grid $w.player3optent -row 7 -column 2
bind $w.player3optent <Return> {set_midiplayer
                               focus .midiplayer.header}

radiobutton $w.player4rad -command set_midiplayer -variable midi(player_sel) -value 4
button $w.player4but -text "midiplayer 4" -width 14 -font $df \
   -command {setpath player4; .midiplayer.player4rad invoke} 
entry $w.player4ent -width 48 -relief sunken -textvariable midi(player4) -font $df
grid $w.player4rad -row 8 -column 0
grid $w.player4but -row 8 -column 1
grid $w.player4ent -row 8 -column 2
bind $w.player4ent <Return> {set_midiplayer
                             focus .midiplayer.header}

button $w.player4optbut -text "midiplayer 4 options" -width 14 -command {}  -font $df
entry $w.player4optent -width 48 -relief sunken -textvariable midi(player4opt) -font $df
grid $w.player4optbut -row 9 -column 1
grid $w.player4optent -row 9 -column 2
bind $w.player4optent <Return> {set_midiplayer
                               focus .midiplayer.header}

radiobutton $w.player5rad -command set_midiplayer -variable midi(player_sel) -value 5
button $w.player5but -text "midiplayer 5" -width 14 -font $df \
   -command {setpath player5; .midiplayer.player5rad invoke} 
entry $w.player5ent -width 48 -relief sunken -textvariable midi(player5) -font $df
grid $w.player5rad -row 10 -column 0
grid $w.player5but -row 10 -column 1
grid $w.player5ent -row 10 -column 2
bind $w.player5ent <Return> {set_midiplayer
                             focus .midiplayer.header}

button $w.player5optbut -text "midiplayer 5 options" -width 14 -command {}  -font $df
entry $w.player5optent -width 48 -relief sunken -textvariable midi(player5opt) -font $df
grid $w.player5optbut -row 11 -column 1
grid $w.player5optent -row 11 -column 2
bind $w.player5optent <Return> {set_midiplayer
                               focus .midiplayer.header}

radiobutton $w.player6rad -command set_midiplayer -variable midi(player_sel) -value 6
button $w.player6but -text "midiplayer 6" -width 14 -font $df \
   -command {setpath player6; .midiplayer.player6rad invoke} 
entry $w.player6ent -width 48 -relief sunken -textvariable midi(player6) -font $df
grid $w.player6rad -row 12 -column 0
grid $w.player6but -row 12 -column 1
grid $w.player6ent -row 12 -column 2
bind $w.player6ent <Return> {set_midiplayer
                             focus .midiplayer.header}

button $w.player6optbut -text "midiplayer 6 options" -width 14 -command {}  -font $df
entry $w.player6optent -width 48 -relief sunken -textvariable midi(player6opt) -font $df
grid $w.player6optbut -row 13 -column 1
grid $w.player6optent -row 13 -column 2
bind $w.player6optent <Return> {set_midiplayer
                               focus .midiplayer.header}
}


proc setpath {path_var} {
    global midi
    
    set filedir [file dirname $midi($path_var)]
    set openfile [tk_getOpenFile -initialdir $filedir]
    if {[string length $openfile] > 0} {
        set midi($path_var) $openfile
        update
    }
}


proc locate_abcmidi_executables {} {
    global midi
    global exec_out
    set exec_out "locate_abcmidi_executables\n\n"
    set dirname [tk_chooseDirectory]
    if {[string length $dirname] < 1} return
    set midi(dir_abcmidi) $dirname
    foreach exec {midi2abc midistats midicopy abc2midi abcm2ps} {
        if {[file exist $dirname/$exec.exe]} {
            set midi(path_$exec) $dirname/$exec.exe
        } elseif {[file exist $dirname/$exec]} {
            set filename $exec
            set midi(path_$exec) $dirname/$exec
        } else {
            append exec_out "cannot find $dirname/$exec or $dirname/$exec.exe\n"
        }
     
    }
    check_midi2abc_midistats_and_midicopy_versions
    update_console_page
}

proc set_abcmidi_executables {} {
global midi
global exec_out
set exec_out ""
set dirname $midi(dir_abcmidi)
foreach exec {midi2abc midicopy} {
    if {[file exist $dirname/$exec.exe]} {
        set midi(path_$exec) $dirname/$exec.exe
	append exec_out "midi(path_$exec) = $midi(path_$exec)\n"
    } elseif {[file exist $dirname/$exec]} {
        set midi(path_$exec) $dirname/$exec
	append exec_out "midi(path_$exec) = $midi(path_$exec)\n"
    } else {
        append exec_out "cannot find $dirname/$exec or $dirname/$exec.exe\n"
    }
   }
	show_console_page $exec_out char
}




proc locate_browser {} {
    global midi
    set midi(browser) [tk_getOpenFile]
    }


proc locate_ghostscript {} {
    global midi
    set midi(path_gs) [tk_getOpenFile]
    }


proc set_preferences {} {
global df
global midi
set w .preferences
if {[winfo exist $w]} {
  raise $w .
  return
  }
toplevel $w
positionWindow $w
radiobutton $w.track -text "separate by track" -font $df\
          -value track -variable midi(midishow_sep)\
          -command {zero_trksel
                    midi_structure_window 
                    }
radiobutton $w.channel -text "separate by channel" -font $df\
          -value chan -variable midi(midishow_sep)\
          -command {zero_trksel
                    midi_structure_window 
                    }
radiobutton $w.focus -text "play and focus on selected" -value 1 -variable midi(playmethod) -font $df
radiobutton $w.only -text "play only selected" -value 2 -variable midi(playmethod) -font $df
radiobutton $w.ex -text "play excluding selected" -value 3 -variable midi(playmethod) -font $df
grid $w.track -sticky nw
grid $w.channel -sticky nw
grid $w.focus -sticky nw
grid $w.only -sticky nw
grid $w.ex -sticky nw

label $w.lab5 -text "for focus attenuate non selected by" -font $df
entry $w.attent -width 3 -textvariable midi(attenuation) -font $df
grid $w.lab5 $w.attent -sticky nw
}



#   Part 7.0 Program selector and support

set mlist {"0 Acoustic Grand" "1 Bright Acoustic" "2 Electric Grand" "3 Honky-Tonk" 
"4 Electric Piano 1" "5 Electric Piano 2" "6 Harpsichord" "7 Clav" 
" 8 Celesta" " 9 Glockenspiel" "10 Music Box" "11 Vibraphone" 
"12 Marimba" "13 Xylophone" "14 Tubular Bells" "15 Dulcimer" 
"16 Drawbar Organ" "17 Percussive Organ" "18 Rock Organ" "19 Church Organ" 
"20 Reed Organ" "21 Accordian" "22 Harmonica" "23 Tango Accordian" 
"24 Acoustic Guitar (nylon)" "25 Acoustic Guitar (steel)" "26 Electric Guitar (jazz)" "27 Electric Guitar (clean)" 
"28 Electric Guitar (muted)" "29 Overdriven Guitar" "30 Distortion Guitar" "31 Guitar Harmonics" 
"32 Acoustic Bass" "33 Electric Bass (finger)" "34 Electric Bass (pick)" "35 Fretless Bass" 
"36 Slap Bass 1" "37 Slap Bass 2" "38 Synth Bass 1" "39 Synth Bass 2" 
"40 Violin" "41 Viola" "42 Cello" "43 Contrabass" 
"44 Tremolo Strings" "45 Pizzicato Strings" "46 Orchestral Strings" "47 Timpani" 
"48 String Ensemble 1" "49 String Ensemble 2" "50 SynthStrings 1" "51 SynthStrings 2" 
"52 Choir Aahs" "53 Voice Oohs" "54 Synth Voice" "55 Orchestra Hit" 
"56 Trumpet" "57 Trombone" "58 Tuba" "59 Muted Trumpet" 
"60 French Horn" "61 Brass Section" "62 SynthBrass 1" "63 SynthBrass 2" 
"64 Soprano Sax" "65 Alto Sax" "66 Tenor Sax" "67 Baritone Sax" 
"68 Oboe" "69 English Horn" "70 Bassoon" "71 Clarinet" 
"72 Piccolo" "73 Flute" "74 Recorder" "75 Pan Flute" 
"76 Blown Bottle" "77 Skakuhachi" "78 Whistle" "79 Ocarina" 
"80 Lead 1 (square)" "81 Lead 2 (sawtooth)" "82 Lead 3 (calliope)" "83 Lead 4 (chiff)" 
"84 Lead 5 (charang)" "85 Lead 6 (voice)" "86 Lead 7 (fifths)" "87 Lead 8 (bass+lead)" 
"88 Pad 1 (new age)" "89 Pad 2 (warm)" "90 Pad 3 (polysynth)" "91 Pad 4 (choir)" 
"92 Pad 5 (bowed)" "93 Pad 6 (metallic)" "94 Pad 7 (halo)" "95 Pad 8 (sweep)" 
" 96 FX 1 (rain)" " 97 (soundtrack)" " 98 FX 3 (crystal)" " 99 FX 4 (atmosphere)" 
"100 FX 5 (brightness)" "101 FX 6 (goblins)" "102 FX 7 (echoes)" "103 FX 8 (sci-fi)" 
"104 Sitar" "105 Banjo" "106 Shamisen" "107 Koto" 
"108 Kalimba" "109 Bagpipe" "110 Fiddle" "111 Shanai" 
"112 Tinkle Bell" "113 Agogo" "114 Steel Drums" "115 Woodblock" 
"116 Taiko Drum" "117 Melodic Tom" "118 Synth Drum" "119 Reverse Cymbal" 
"120 Guitar Fret Noise" "121 Breath Noise" "122 Seashore" "123 Bird Tweet" 
"124 Telephone ring" "125 Helicopter" "126 Applause" "127 Gunshot" 
}

proc programSelector {} {
global mlist
global progmapper
global groupcolors
global df
set w .progsel
if {[winfo exist $w]} {
  raise $w .
  return}
toplevel $w 
positionWindow $w
for {set i 0} {$i < 128} {incr i} {
 set g [lindex $progmapper $i]
 set kolor [lindex $groupcolors $g]
 checkbutton $w.$i -text [lindex $mlist $i] -variable progselect($i) -command update_proglist -background $kolor -font $df -width 24 -anchor w -borderwidth 0 
 if {[lsearch {0 1 6 7 10 11 14 15 16} $g] >-1} {
     $w.$i configure -foreground white -selectcolor black}
 }
for {set i 0} {$i < 32} {incr i} {
  set i2 [expr $i + 32]
  set i3 [expr $i + 64]
  set i4 [expr $i + 96]
  grid $w.$i $w.$i2 $w.$i3 $w.$i4 -sticky w
  } 
update_progselect
}


proc program_legend_c {} {
global mlist
global progmapper
global groupcolors
global df
set w .progsel
if {[winfo exist $w]} {
  raise $w .
  return}
toplevel $w 
positionWindow $w
canvas $w.c -width 680 -height 512
pack $w.c
for {set i 0} {$i < 128} {incr i} {
 set g [lindex $progmapper $i]
 set kolor [lindex $groupcolors $g]
 set x [expr 170*($i/32)]
 set y [expr 16*($i % 32)]
 if {[lsearch {0 1 6 7 10 11 14 15 16} $g] >-1} {
     set fg white} else {set fg black}
 $w.c create rectangle $x $y [expr $x+170] [expr $y+16] -fill $kolor
 $w.c create text $x [expr $y+8] -text [lindex $mlist $i] -font $df -width 170 -anchor w  -fill $fg -font $df
 }
update
$w.c postscript -file progcolorlegend.ps
}

# call program_legend_c from wish (after midiexplorer.ini is loaded).
# use bold font.


proc update_progselect {} {
global midi
global progselect
for {set i 0} {$i < 127} {incr i} {set progsel($i) 0}
foreach p $midi(proglist) {
  set progselect($p) 1
  }
}


proc update_proglist {} {
global midi
global progselect
set p ""
for {set i 0} {$i < 127} {incr i} {
  if {$progselect($i)} {lappend p $i}
  }
set midi(proglist) $p
}



#   Part 8.0 Piano Roll window
#
#global variables
set trkchan 1
# flag to to separate by track or channel

#run time messages
set piano_yview_pos 0.35 ;# scroll position for piano roll display
set pianoresult {} 
global activechan
global trksel
global highlighted_trk
global trkchan
global exec_out
global piano_yview_pos

# We initialize trksel to 0 to indicate
# that no tracks or channels have been selected yet.
for {set i 0} {$i < 32} {incr i} {
    set trksel($i) 0
    update_console_page
}

set hlp_pianoroll " The function will display the selected MIDI file in a piano\
        roll form in a resizeable separate window.\n\n\
        Vertical lines indicate beat numbers as determined by the\
        the conversion factor PPQN (pulses per quarter note) defined in the\
        header of the MIDI file. If you place the mouse pointer on\
        any one of the MIDI notes as indicated by a black horizontal\
        arrow, the associated channel or track checkbutton will appear\
        in red, and the parameters of this note\
        will appear in a short text line below the scroll bar of this display.\n\n\
        It is best to zoom into a limited section of the midi file.\
        The zoom and unzoom buttons will magnify or scale down the display.\
        You can specify an area to zoom into by holding down the mouse left\
        mouse button and sweeping an area. This area will be highlighted.\
        (A double click will clear the highlighted area marker -- yellow stipple.)\
        Clicking the zoom button will zoom into the highlighted area.\n\n\
	The behaviour of the channel/track checkbuttons depend upon whether\
        dynamic or static highlighting in the config menu is checked. If\
        dynamic highlighting is chosen,\
        hovering the mouse pointer over any of the channel/track checkbuttons will\
        highlight the notes of that track in red in the piano roll. (Note that those\
        notes may not be visible in the current view.) If you check one of those\
        buttons those notes will be highlighted in blue. If static highlighting\
	is chosen, red accentuation will be suppressed and ticking\
       	one or more buttons will hide all the other\
	tracks and expose only the selected tracks in blue \n\n\
        Note that if any of these functions\
        do not seem to run correctly, you should click the console\
        button and view the messages.\n\n The program attempts to follow\
        the playing with a vertical red line based on the estimated duration\
        of the output. Due to possible latencies in the midiplayer there may\
        be some loss of synchronization for some players. Pressing any key on\
        the keyboard while the focus is on the piano canvas will stop the tracker.\
        Unfortunately, I have not found a way of stopping the midi player from\
        this application. You can turn off the tracker from the options menu.\n\n\
	There is a speed control slider which allows you to adjust\
	the tempo of the MIDI file. You must set it prior to playing\
	the exposed music.\n\n\
        You may configure the program to either distinguish tracks\
        or channels. It is recommended that you separate the midi notes\
        by channel rather than by tracks. A sequence of checkbuttons\
        at the bottom of the window allows you to select the particular\
        channels or tracks for playing or for further analysis using\
        the action menu. If nothing is selected then all channels/tracks\
        are processed. Hovering the mouse button on any of these\
        checkbuttons will indicate what musical instrument (program) that was\
        assigned to this channel. The notes assigned to the associated\
        channel (or track) will also be displayed in red while the\
        mouse pointer is over that checkbutton. Note that the highlighted\
        notes may not be present in the particular scrolled region of\
        the display. In the case where the program assignment was\
        changed at a later time, only the last assignment is displayed.\n\n\
        It is possible to shift or change the spacing of the vertical quarter\
        note line indications by selecting the config/ppqn adjustment item.\
        This temporarily changes the ppqn value of the MIDI file which\
        also affects the output of action/beat graph."


proc check_midi2abc_midistats_and_midicopy_versions {} {
    global midi
    #puts "check_midi2abc : $midi(path_midi2abc)"
    set result [getVersionNumber $midi(path_midi2abc)]
    #puts $result
    set err [scan $result "%f" ver]
    set msg "You need midi2abc.exe version 3.57.\n"
    if {$err == 0 || $ver < 3.57} { .info.txt insert insert $msg red
                    return $msg}
    set result [getVersionNumber $midi(path_midicopy)]
    set err [scan $result "%f" ver]
    #puts $result
    set msg "You need midicopy.exe version 1.38 or higher.\n"
    if {$err == 0 || $ver < 1.38} { .info.txt insert insert $msg red
                    return $msg}
    set result [getVersionNumber $midi(path_midistats)]
    set msg "You need midistats.exe version 0.68 or higher.\n"
    set err [scan $result "%f" ver]
    if {$err == 0 || $ver < 0.68} { .info.txt insert insert $msg red
                    return $msg}
    return pass
}


# tmpname returns a random file midi file name
proc uniqid {} "
lindex [string repeat {[lindex {0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z} [expr {entier(rand() * 62)}]]} 8]"

proc tmpname {} {
concat x[uniqid].mid}




proc playmidifile {option} {
    global midi
    global lastbeat
    global exec_out

    set exec_out ""
    set cmd "file delete -force -- $midi(outfilename)"
    catch {eval $cmd} done
    set midi(outfilename) [tmpname]

    switch $option {
       0 {
         file copy $midi(midifilein) $midi(outfilename)
         play_midi_file $midi(outfilename)
         update_console_page
         }
       1 {
         set startbeat 0
         set endbeat [expr $lastbeat/4]
         midi_to_midi_from_structure $startbeat $endbeat "" 0
         play_midi_file $midi(outfilename)
         }
       2 {
         set startbeat [expr $lastbeat/4]
         set endbeat [expr $lastbeat/2]
         midi_to_midi_from_structure $startbeat $endbeat "" 0
         play_midi_file $midi(outfilename)
         }
       3 {
         set startbeat [expr $lastbeat/2]
         set endbeat [expr 3*$lastbeat/4]
         midi_to_midi_from_structure $startbeat $endbeat "" 0
         play_midi_file $midi(outfilename)
         }
       4 {
         set startbeat [expr 3*$lastbeat/4]
         set endbeat $lastbeat
         midi_to_midi_from_structure $startbeat $endbeat "" 0
         play_midi_file $midi(outfilename)
         }
      }
    }


proc play_midi_file {name} {
# plays midi file located in same folder as midiexplorer.
    global midi
    global exec_out
    set cmd "exec [list $midi(path_midiplay)] $midi(midiplay_options) "
    set cmd [concat $cmd [file join [pwd] $name] ]
    set cmd [concat $cmd &]
    eval $cmd
    set exec_out $exec_out\n\n$cmd
    update_console_page
}


set pianorollwidth 500

proc piano_roll_display {} {
   global cleanData
   piano_window
   #load_midifile
   loadMidiFile
   set cleanData 1
   show_events
   }

proc configureTrackSelector {} {
global midi
if {$midi(trackSelector) == "static"} {
 for {set i 0} {$i < 32} {incr i} {
  .piano.trkchn.$i configure -command "highlightTrackStatic $i"
   }
 } else {
 for {set i 0} {$i < 32} {incr i} {
  .piano.trkchn.$i configure -command "highlight_track $i"
   }
 }
}

proc piano_window {} {
    global pianorollwidth
    global exec_out
    set exec_out "piano_roll"
    global midi
    global df
    global midispeed
    if {[winfo exist .piano]} {destroy .piano}
    toplevel .piano
    positionWindow .piano
   
    # menu bar  
    set p .piano.f
    frame $p
    
    menubutton $p.config -text config -width 8 -menu $p.config.items -font $df
    menu $p.config.items -tearoff 0
    $p.config.items add radiobutton -label "separate by track" -font $df\
            -value track -variable midi(midishow_sep)\
            -command {zero_trksel
                      compute_pianoroll
                      show_prog_structure}
    $p.config.items add radiobutton -label "separate by channel" -font $df\
            -value chan -variable midi(midishow_sep)\
            -command {zero_trksel
                      compute_pianoroll
                      show_prog_structure}
    $p.config.items add radiobutton -label "dynamic highlighting" -font $df\
    -value dynamic -variable midi(trackSelector) -command configureTrackSelector
    $p.config.items add radiobutton -label "static highlighting" -font $df\
    -value static -variable midi(trackSelector) -command configureTrackSelector
    $p.config.items add checkbutton -label "suppress drum channel" -font $df\
            -variable midi(nodrumroll) -command compute_pianoroll
    $p.config.items add checkbutton -label "follow while playing" -font $df\
            -variable midi(midishow_follow)
    $p.config.items add command -label "ppqn adjustment" -font $df\
            -command ppqn_adjustment_window
    $p.config.items add command -label "external executables" -font $df\
            -command set_external_programs
    
    
    #buttons for zooming in and zooming out
    button $p.zoom -text zoom -relief flat -command piano_zoom -font $df
    menubutton $p.unzoom -text unzoom -width 8 -menu $p.unzoom.items -font $df
    menu $p.unzoom.items -tearoff 0
    $p.unzoom.items add command -label "Unzoom 1.5" -font $df \
            -command {piano_unzoom 1.5}
    $p.unzoom.items add command -label "Unzoom 3.0" -font $df \
            -command {piano_unzoom 3.0}
    $p.unzoom.items add command -label "Unzoom 5.0" -font $df \
            -command {piano_unzoom 5.0}
    $p.unzoom.items add command -label "Total unzoom" -command piano_total_unzoom -font $df
    
    # action menu
    menubutton $p.action -text action -menu $p.action.items -font $df
    menu $p.action.items -tearoff 0
    $p.action.items add command -label "mftext" -font $df \
            -command mftext_tmp_midi
    $p.action.items add command  -label "pitch distribution" -font $df \
            -command {pianoroll_statistics pitch .piano.can
                      plotmidi_pitch_pdf
                      }
    $p.action.items add command  -label "pitch class plot" -font $df \
            -command {pianoroll_statistics pitch .piano.can
                      show_note_distribution
                     } 
    $p.action.items add command  -label "onset distribution" -font $df \
            -command {pianoroll_statistics onset .piano.can
                      plotmidi_onset_pdf 
                     }
    $p.action.items add command  -label "note duration distribution" -font $df \
            -command {pianoroll_statistics duration .piano.can
                      plotmidi_duration_pdf 
                     }
    $p.action.items add command  -label "velocity distribution" -font $df \
            -command {pianoroll_statistics velocity .piano.can
                plotmidi_velocity_pdf}
    $p.action.items add command  -label "velocity map" -font $df \
            -command {plot_velocity_map .piano.can}
    $p.action.items add command  -label "beat graph" -font $df \
            -command {beat_graph pianoroll}
    $p.action.items add command  -label "notegram" -font $df \
            -command {notegram_plot pianoroll}
    $p.action.items add command  -label "chordtext" -font $df \
            -command {chordtext_window pianoroll}
    $p.action.items add command  -label "chord histogram" -font $df \
            -command {chord_histogram none}
    $p.action.items add command  -label "chordgram" -font $df \
            -command {chordgram_plot pianoroll}
    $p.action.items add command -label "help" -font $df\
            -command {show_message_page $hlp_pianoroll_actions word}
    
    scale $p.speed -length 100 -from 0.1 -to 3.0 -orient horizontal\
 -resolution 0.05 -width 10 -variable midispeed
    set midispeed 1.0
    label $p.speedlabel -text speed -font $df -relief flat -pady 1
    button $p.help -text help -relief flat -font $df\
            -command {show_message_page $hlp_pianoroll word}
    
    #pack all buttons
    grid  $p.config $p.zoom $p.unzoom $p.action $p.speedlabel $p.speed $p.help -sticky news
    grid $p -column 1
    
    # file name entry box
    set p .piano.file
    frame $p -relief ridge -borderwidth 2
    entry $p.fileinent -width 72 -textvariable midi(midifilein) -font $df
    $p.fileinent xview moveto 1.0
    bind $p.fileinent <Return> {focus .piano.file
        show_events}
    grid $p.fileinent 
    grid $p -column 0 -columnspan 3
    
    
    # create frame for displaying canvas of piano roll.
    set p .piano
    scrollbar $p.hscroll -orient horiz -command [list BindXview [list $p.can\
            $p.canx]]
    scrollbar $p.vscroll -command BindYview
    
    canvas $p.can -width $pianorollwidth -height 400 -border 3 -relief sunken -scrollregion\
            {0 0 2500 500} -xscrollcommand "$p.hscroll set" -yscrollcommand\
            "$p.vscroll set" -border 3 -bg white
    canvas $p.canx -width $pianorollwidth -height 20 -border 3 -relief sunken -scrollregion\
            {0 0 2500 20}
    canvas $p.cany -width 20 -height 300 -border 3 -relief sunken -scrollregion\
            {0 0 20 724}
    grid $p.cany $p.can $p.vscroll -sticky news
    grid $p.canx -sticky news -column 1
    label $p.txt -text midishow
    grid $p.hscroll -sticky ew -column 1
    grid $p.txt -column 1
    grid rowconfig $p 2 -weight 1 -minsize 0
    grid columnconfig $p 1 -weight 1 -minsize 0
    frame .piano.trkchn
    grid .piano.trkchn -columnspan 3 -sticky nw
    
    for {set i 0} {$i < 32} {incr i} {
        if {$midi(trackSelector) == "static"} {
          checkbutton .piano.trkchn.$i -text $i -variable trksel($i) -font $df
         } else {
          checkbutton .piano.trkchn.$i -text $i -variable trksel($i) -font $df
        }
    }

    configureTrackSelector
    button .piano.trkchn.play -relief raised -padx 1 -pady 1
    grid .piano.trkchn.play -column 1
    bind .piano.trkchn.play <Button> {
        set miditime [midi_to_midi 1]
        piano_play_midi_extract
        startup_playmark_motion $miditime
    }
    button .piano.trkchn.display -relief raised -padx 1 -pady 1
    grid .piano.trkchn.display -column 1
    bind .piano.trkchn.display <Button> {
        set miditime [midi_to_midi 1]
        piano_display_midi_extract
}
    
    
    bind $p.can <ButtonPress-1> {piano_Button1Press %x %y}
    bind $p.can <ButtonRelease-1> {piano_Button1Release}
    bind $p.can <Double-Button-1> piano_ClearMark
    bind $p.can <Configure> piano_resize
    set result [check_midi2abc_midistats_and_midicopy_versions]
    if {[string equal $result pass]} {show_events} else {
        .piano.txt configure -text $result -foreground red -font $df}
}

proc highlight_track {num} {
global trksel
global last_checked_button
if {$trksel($num)} {
  .piano.can itemconfigure trk$num -fill blue -width 4
  } else {
  .piano.can itemconfigure trk$num -fill black -width 2
  }
update_displayed_pdf_windows .piano.can
}



proc highlightTrackStatic {num} {
global trksel
global last_checked_button

set nselected [count_trksel]
if {$nselected == 0} {hideExposeSomePianoRollTracksChannels 0
	             return}

if {$trksel($num)} {
  hideExposeSomePianoRollTracksChannels 1 
  .piano.can itemconfigure trk$num -fill blue -width 4
  } else {
  .piano.can itemconfigure trk$num -fill "" -width 4
  }
update_displayed_pdf_windows .piano.can
}

proc applyHighlightTrackStatic {} {
global trksel
global midi
if {$midi(trackSelector) != "static"} return
if {[count_selected_midi_tracks] == 0} return
for {set i 0} {$i < 32} {incr i} {
 if {$trksel($i)} {
   hideExposeSomePianoRollTracksChannels 1 
  .piano.can itemconfigure trk$i -fill blue -width 4
   } else {
  .piano.can itemconfigure trk$i -fill "" -width 4
  }
 }
}


proc highlight_all_chosen_tracks {} {
global trksel
for {set i 0} {$i < 32} {incr i} {
  if {$trksel($i)} {highlight_track $i}
  }
}
  
proc zero_trksel {} {
global trksel
for {set i 0} {$i < 32} {incr i} {
    set trksel($i) 0
    }
}

proc count_trksel {} {
global trksel
set count 0
for {set i 0} {$i < 32} {incr i} {
    if {$trksel($i)} {incr count}
    }
return $count
}


#


#        Support functions

proc piano_Button1Press {x y} {
    set xc [.piano.can canvasx $x]
    .piano.can raise mark
    .piano.can coords mark $xc 0 $xc 720
    bind .piano.can <Motion> { piano_Button1Motion %x }
    update_piano_txt $x $y
}

proc piano_Button1Motion {x} {
    set xc [.piano.can canvasx $x]
    if {$xc < 0} { set xc 0 }
    set co [.piano.can coords mark]
    .piano.can coords mark [lindex $co 0] 0 $xc 720
}

proc piano_Button1Release {} {
    bind .piano.can <Motion> {}
    set co [.piano.can coords mark]
    update_displayed_pdf_windows .piano.can
}

proc piano_ClearMark {} {
    .piano.can coords mark -1 -1 -1 -1
}



# for handling x scrolling of piano roll
proc BindXview {lists args} {
    foreach l $lists {
        eval {$l xview} $args
    }
    update_displayed_pdf_windows [lindex $lists 0]
}

# for handling y scrolling of piano roll
proc BindYview {args} {
    global piano_yview_pos
    eval .piano.can yview $args
    eval .piano.cany yview $args
    set piano_yview_pos [lindex [.piano.can yview] 0]
}




proc unpack_mthd_header {} {
    # read binary header block of midi file to get
    # format type and number of tracks. Saves having
    # to call a C program.
    global mthd_header id mlen mformat ntrk ppqn trkchan
    binary scan $mthd_header a4ISSS id mlen mformat ntrk ppqn
    set trkchan $mformat
}



# This procedure is associated with the piano roll button.
# It calls the midi2abc executable to do most of the work.
proc show_events {} {
    global midi trkchan
    global trk
    global midilength
    global piano_yview_pos
    global exec_out
    global pianorollwidth
    global pianoPixelsPerFile
    global df
    global last_checked_button
    focus .
    
    set last_checked_button -1  
    if {[file exist $midi(midifilein)] == 0} {
        .piano.txt configure -text "can't open file $midi(midifilein)"\
                -foreground red -font $df
        return
    }
    set pianoPixelsPerFile $pianorollwidth
    append exec_out "\ncompute_pianoroll\n"
    compute_pianoroll
    .piano.can yview moveto $piano_yview_pos
    .piano.cany yview moveto $piano_yview_pos
    piano_horizontal_scroll 0
    update_console_page
}


#horizontal zoom of piano roll
proc piano_zoom {} {
    global pianoPixelsPerFile
    set co [.piano.can coords mark]
    set zoomregion [expr [lindex $co 2] - [lindex $co 0]]
    set displayregion [winfo width .piano.can]
    set scrollregion [.piano.can cget -scrollregion]
    if {$zoomregion > 5} {
        set mag [expr $displayregion/$zoomregion]
        set pianoPixelsPerFile [expr $pianoPixelsPerFile*$mag]
        compute_pianoroll
        set xv [expr double([lindex $co 0])/double([lindex $scrollregion 2])]
        piano_horizontal_scroll $xv
    } else {
        set pianoPixelsPerFile [expr $pianoPixelsPerFile*1.5]
        if {$pianoPixelsPerFile > 250000} {
            set $pianoPixelsPerFile 250000}
        set xv [lindex [.piano.can xview] 0]
        compute_pianoroll
        piano_horizontal_scroll $xv
    }
    update_displayed_pdf_windows .piano.can
    applyHighlightTrackStatic 
}


proc piano_unzoom {factor} {
    global pianoPixelsPerFile
    set displayregion [winfo width .piano.can]
    set PixelsPerFile [expr $displayregion -8]
    set pianoPixelsPerFile [expr $pianoPixelsPerFile /$factor]
    if {$pianoPixelsPerFile < $PixelsPerFile} {
       set factor [expr $PixelsPerFile/$pianoPixelsPerFile]
       set pianoPixelsPerFile $PixelsPerFile
    }
    set xv [.piano.can xview]
    set xvl [lindex $xv 0]
    set xvr [lindex $xv 1]
    set growth [expr ($factor - 1.0)*($xvr - $xvl)]
    set xvl [expr $xvl - $growth/2.0]
    if {$xvl < 0.0} {set xv 0.0}
    compute_pianoroll
    piano_horizontal_scroll $xvl
    update_displayed_pdf_windows .piano.can
    applyHighlightTrackStatic 
}

proc piano_total_unzoom {} {
    global pianoPixelsPerFile
    set displayregion [winfo width .piano.can]
    #puts "displayregion $displayregion"
    # subtract 8 to allow for growth of bbox of .piano.can
    set pianoPixelsPerFile [expr $displayregion -8]
    compute_pianoroll
    .piano.can configure -scrollregion [.piano.can bbox all]
    update_displayed_pdf_windows .piano.can
    applyHighlightTrackStatic 
}

proc piano_zoom_to {beginbeat endbeat} {
    global lastbeat
    global pianoPixelsPerFile
    global pianorollwidth
    set fraction [expr ($endbeat - $beginbeat)/$lastbeat]
    if {$fraction < 0.05} {set fraction 0.05}
    set pianoPixelsPerFile [expr $pianorollwidth/$fraction]
    compute_pianoroll
    set xvl [expr $beginbeat/$lastbeat]
    piano_horizontal_scroll $xvl
    update_displayed_pdf_windows .piano.can
    applyHighlightTrackStatic 
    }
 
proc piano_resize {} {
global pianoPixelsPerFile
set displayregion [winfo width .piano.can]
if {$pianoPixelsPerFile < $displayregion} {
   # shrink pianoPixelsPerFile since the bbox of .drumroll.can tends
   # to grow on account of the thick lines.
   set pianoPixelsPerFile [expr $displayregion -20]
   compute_pianoroll
   .piano.can configure -scrollregion [.piano.can bbox all]
   }
}


set hlp_pianoroll_actions "The action menu provides miscellaneous\
        functions that can be applied on the exposed temporal part of the\
        MIDI file.\n\n\
        create midi  - creates tmp.mid and renames it to whatever you select.\n\n\
        mftext  -  creates tmp.mid and displays the midi file in mftext form.\n\n\
        velocity distribution - produces a histogram of the velocity values\
        of the notes in the exposed area.\n\n\
        pitch distribution - produces both a histogram of the MIDI pitch values\
        and the pitch classes of the exposed area.\n\n\
        velocity map - plots the velocity of the notes versus beat number.\n\n\
        beat graph - plots the onset time relative to the start of a beat\
        versus the beat number for each note. You should see horizontal lines\
        if the note onset times follow exact musical positions in a measure.\n\n\
        chordtext - shows the midi pitches of all the notes that were\
        played in a specific beat for all the displayed beats. If the\
        number of displayed beats is less than 20\
        then the time when the notes were playing is given to a higher\
        temporal resolution.\n\n\
        chord histogram - lists the number of times each chord\
        type occurs.\n\n\
        chordgram - graphically displays the chord type occurring in each\
        beat. Major chords - red, Minor chords - blue, Diminished\
        chords - green, and augmented chords - purple."
        

#         beat graph
proc beat_graph {source} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global pianoresult ppqn
    global midi
    global fbeat
    global tbeat
    
    
    set tsel [count_selected_midi_tracks]

    copyMidiToTmp $source
    set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -midigram"
    catch {eval $cmd} pianoresult
    set nrec [llength $pianoresult]
    set midilength [lindex $pianoresult [expr $nrec -6]]
    set pianoresult [split $pianoresult \n]
    
    set bgraph .beatgraph.c
    if {[winfo exists .beatgraph] == 0} {
        toplevel .beatgraph
        positionWindow .beatgraph
        pack [canvas .beatgraph.c -width $scanwidth -height $scanheight]\
                -expand yes -fill both
    } else {.beatgraph.c delete all}
     
    # white or black characters
    set colfg [lindex [.info.txt config -fg] 4]

    set delta_tick [expr int(($tbeat - $fbeat)/10.0)]
    if {$delta_tick < 1} {set delta_tick 1}
    $bgraph create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx $fbeat $tbeat -0.0625 1.0
    Graph::draw_x_ticks $bgraph $fbeat $tbeat $delta_tick 2 0 %3.0f $colfg
    Graph::draw_y_ticks $bgraph 0.0 1.0 0.125 2 %3.2f $colfg
    
    set i 0
    foreach line $pianoresult {
        if {[llength $line] != 6} continue
        set onset [expr double([lindex $line 1])/$ppqn]
        set beat [expr floor($onset)]
        set frac [expr $onset - $beat]
	set beat [expr $beat + $fbeat]
	if {$beat > $tbeat} break
        incr i
        set ix [Graph::ixpos $beat]
        set iy [Graph::iypos $frac]
        $bgraph create rectangle $ix $iy [expr $ix +2] [expr $iy +2] -fill black
    }
}



proc ppqn_adjustment_window {} {
    global df
    if {[winfo exist .ppqn]} return
    toplevel .ppqn
    positionWindow .ppqn
    button .ppqn.1 -text "increase ppqn" -font  $df -repeatdelay 500\
            -repeatinterval 50 -command {qnote_spacing_adjustment 1}
    button .ppqn.2 -text "decrease ppqn" -font $df -repeatdelay 500\
            -repeatinterval 50 -command {qnote_spacing_adjustment -1}
    button .ppqn.3 -text "+ pulse offset" -font $df -repeatdelay 500\
            -repeatinterval 50 -command {qnote_offset_adjustment 1}
    button  .ppqn.4 -text "- pulse offset" -font $df -repeatdelay 500\
            -repeatinterval 50 -command {qnote_offset_adjustment -1}
    pack .ppqn.1 .ppqn.2 .ppqn.3 .ppqn.4
}



#         chord histogram
proc chord_histogram_window {} {
    global df
    global midi
    
    if {[winfo exist .chordstats]} return
    set w .chordstats
    toplevel $w
    positionWindow .chordstats
    
    frame $w.head
    label $w.head.lab -text "sort by" -font $df
    radiobutton $w.head.key -text key -font $df -variable midi(sortchordnames) -value key -command chord_histogram
    radiobutton $w.head.freq -text frequency -font $df -variable midi(sortchordnames) -value freq -command chord_histogram
    radiobutton $w.head.txt -text list -font $df -variable midi(chordhist) -value txt -command switch_text_barchart
    radiobutton $w.head.bar -text barchart -font $df -variable midi(chordhist) -value bar -command switch_text_barchart
    pack $w.head.lab $w.head.key $w.head.freq $w.head.txt $w.head.bar -side left -anchor w
    pack $w.head -anchor w
    
    frame $w.chords
    text $w.chords.t -width 64 -height 16 -yscrollcommand {.chordstats.chords.ysbar set} -font $df
    scrollbar $w.chords.ysbar -orient vertical -command {.chordstats.chords.t yview}
    pack $w.chords.t -side left
    pack $w.chords.ysbar -side left -fill y
    #pack $w.chords
    
   if {![winfo exist .chordstats.bar]} {
     canvas .chordstats.bar -width 450 -height 270
   } else {
   .chordstats.bar delete all
   }

    
    $w.chords.t configure -tabs "120 left 240 left 360 left 480 left"
    update
    #puts "dimensions = [winfo geometry $w.chords.t]"
}





proc chordtext_window {source} {
   global df

   if {[winfo exist .chordview] == 0} {
     set f .chordview
     toplevel $f
     positionWindow $f
     frame $f.1 
     frame $f.2
     pack $f.1 $f.2 -side top
     text $f.2.txt -yscrollcommand {.chordview.2.scroll set} -width 64 -font $df
     scrollbar .chordview.2.scroll -orient vertical -command {.chordview.2.txt yview}
     pack $f.2.txt $f.2.scroll -side left -fill y
     }
   make_and_display_chords $source
}


proc compare_onset {a b} {
    set a_onset [lindex $a 0]
    set b_onset [lindex $b 0]
    if {$a_onset > $b_onset} {
        return 1}  elseif {$a_onset < $b_onset} {
        return -1} else {return 0}
}



proc midi_to_pitchclass {midipitch} {
    global sharpnotes
    global flatnotes
    global useflats
    set midipitch [expr round($midipitch)]
    if {$useflats} {
      set keyname [lindex $flatnotes [expr $midipitch % 12]]
      } else {
      set keyname [lindex $sharpnotes [expr $midipitch % 12]]
      }
    return $keyname
}



proc label_notelist {notelist} {
    set labeled_list ""
    foreach elem $notelist {
        set labeled_list "$labeled_list [midi_to_key $elem]"
    }
    return $labeled_list
}

proc label_pitchlist {pitchlist} {
    set labeled_list ""
    foreach elem $pitchlist {
        set labeled_list "$labeled_list [midi_to_pitchclass $elem]"
    }
    return $labeled_list
}

set notelist {}



proc count_chords {chord} {
    global chordcount
    global total_chordcount
    if {[info exist chordcount($chord)]} {
        incr chordcount($chord)
    } else {
        set chordcount($chord) 1
    }
    incr total_chordcount
}



proc print_chordcount {w} {
    global chordcount
    global total_chordcount
    global midi
    set chordcountlist {}
    foreach {elem1 elem2} [array get chordcount] {
      lappend chordcountlist [list $elem1 $elem2]
      }
    
    if {$midi(sortchordnames) == "key"} {
      set sortedcountlist [lsort -index 0 $chordcountlist]
      } else {
      set sortedcountlist [lsort -index 1 -integer -decreasing $chordcountlist]
      }
    set i 0
    set nrows [expr 1+ [llength $sortedcountlist] /4]
    foreach chord $sortedcountlist {
        set j [expr ($i % $nrows)+1]
        set n [expr $i/ $nrows]
        if {$n == 0} {
            $w.chords.t insert $j.0  "[lindex $chord 0]  [lindex $chord 1]\n"
        } else {
            $w.chords.t insert $j.end  "\t[lindex $chord 0] [lindex $chord 1]"
        }
        incr i
    }
}


proc reorganize_pianoresult {source} {
    global pianoresult
    global sorted_midiactions
    global midi
    global trksel
    set midiactions {}
    set tsel [count_selected_midi_tracks]
    if {$source == "none"} {set tsel 0}
    #puts "reorganize_pianoresult for [llength $pianoresult] records"
    foreach cmd $pianoresult {
        if {[llength $cmd] < 5} continue
        set onset [lindex $cmd 0]
        set stop  [lindex $cmd 1]
        set trk   [lindex $cmd 2]
        set chn   [lindex $cmd 3]
        set pitch [lindex $cmd 4]
        if {$chn == 10} continue
        if {$midi(midishow_sep) == "track"} {set sep $trk} else {set sep $chn}
        if {$tsel == 0} {
          lappend midiactions [list $onset $pitch 1]
          lappend midiactions [list $stop  $pitch 0]
          } else {
          if {$tsel != 0 && $trksel($sep) == 0} continue
          lappend midiactions [list $onset $pitch 1]
          lappend midiactions [list $stop  $pitch 0]
          }
     }
    set sorted_midiactions [lsort -command compare_onset $midiactions]
}


proc turn_off_all_notes {} {
    global notestatus
    for {set i 0} {$i < 128} {incr i } {
        set notestatus($i) 0 }
}


proc reset_beat_notestatus {} {
    global notestatus
    global beat_notestatus
    for {set i 0} {$i < 128} {incr i} {
       set beat_notestatus($i) $notestatus($i)
       }
}


proc list_on_notes {} {
    global notestatus
    set notelist {}
    set j 0
    for {set i 0} {$i < 128} {incr i } {
        if {$notestatus($i)} {lappend notelist $i
            incr j}
    }
    return $notelist
}

proc list_on_notes_in_beat {} {
    global beat_notestatus
    set notelist {}
    set j 0
    for {set i 0} {$i < 128} {incr i } {
        if {$beat_notestatus($i)} {lappend notelist $i
            incr j}
    }
    return $notelist
}



proc switch_note_status {midicmd} {
    global notestatus
    global beat_notestatus
    set notestatus([lindex $midicmd 1]) [lindex $midicmd 2]
    if {[lindex $midicmd 2] == 1} {
      set beat_notestatus([lindex $midicmd 1]) 1
      } 
}


proc make_and_display_chords {source} {
    global midi
    global sorted_midiactions
    global total_chordcount
    global chordcount
    global ppqn
    global pianoresult
    global useflats
    
    set limits [getCanvasLimits $source] 
    set start [lindex $limits 0]
    set stop  [lindex $limits 1]
    set nbeats [expr ($stop - $start)]
    #puts "make_and_display_chords: nbeats = $nbeats" 
    
    set v .chordview.2.txt
    $v delete 0.0 end
    
    reorganize_pianoresult $source
    turn_off_all_notes
    reset_beat_notestatus
    
    set last_time 0.0
    set last_beat_number 0
    set i 0
   
    set start [expr $start*$ppqn]
    set stop   [expr $stop  *$ppqn]
 
    foreach midiunit $sorted_midiactions {
        set begin [lindex $midiunit 0]
        if {[string is double $begin] != 1} continue
        if {$begin < $start} continue
        set end [lindex $midiunit 0]
        if {$end   > $stop}  continue
        
        #  if {$i > 40} break
        incr i
        set present_time [lindex $midiunit 0]
        set beat_time [format %5.2f [expr double($present_time)/$ppqn]]
        set beat_number [expr int($beat_time)]
        if {$last_beat_number != $beat_number} {
            set chordstring [label_notelist [list_on_notes_in_beat]]
            set name [chordname $chordstring [root_of $chordstring]]
            $v insert insert "$last_beat_number  $name   $chordstring \n"
            reset_beat_notestatus
            set last_beat_number $beat_number
            } 

         # detailed list if less than 20 beats were selected
         if {$nbeats < 20.1} { 
           if {[expr $present_time - $last_time] > 0.2} {
             set onlist [list_on_notes]
             set chordstring [label_notelist $onlist]
             $v insert end "   $beat_time $chordstring\n"
            }
          }

            
         set last_time $present_time
         switch_note_status $midiunit
         }
    }

proc root_of {chordstring} {
# Using Craig Stuart Sapp's algorithm described in
# Computational Chord-Root Identification in Symbolic Musical
# Data: Rationale, Methods and Applications
# Published in "Tonal Theory for the Digital Age" (Computing
# in Musicology 15, 2007) pp 99-119.
# http://www.ccarh.org/publications/books/cm/
set w {0 4 1 5 2 6 3}
set k {C D E F G A B}
set sharp #
set flat b
set minsum 100
for {set shift 0} {$shift < 7} {incr shift} {
  set sum 0
  foreach note $chordstring {
    set key [string index $note 0]
    set keyloc [lsearch $k $key]
    set v [lindex $w [expr ($keyloc - $shift) % 7]]
    incr sum $v
    }
  if {$sum < $minsum} {
    set bestshift $shift
    set minsum $sum
    }
  }
  set bass  [lindex $k $bestshift]
  if {[string first $bass$sharp $chordstring] > -1} {set bass $bass$sharp}
  if {[string first $bass$flat $chordstring] > -1} {set bass $bass$flat}
  return $bass
}  


proc chordname {chordstring root} {
  # remove numbers from chordstring
  regsub -all -line {\d} $chordstring "" clean_notes
  set sharpmapper {C# 1 C 0 D# 3 D 2 E 4 F# 6 F 5 G# 8 G 7 A# 10 A 9 B 11}
  set flatmapper {C 0 Db 1 D 2 Eb 3 E 4 F 5 Gb 6 G 7 Ab 8 A 9 Bb 10 B 11}
  set maj "maj"
  set min "min"
  set aug "aug"
  set dim "dim"
  if {[string first # $chordstring] > -1} {
     set notevals [string map $sharpmapper $clean_notes]
     set rootval [string map $sharpmapper $root]
     } else {
     set notevals [string map $flatmapper $clean_notes]
     set rootval [string map $flatmapper $root]
     }
  #puts $clean_notes
  for {set i 0} {$i < [llength $notevals]} {incr i} {
    lset notevals $i [expr ([lindex $notevals $i] - $rootval) % 12]
    }
  set notevals [lsort -increasing -unique -integer $notevals]
  #puts "$root $rootval"
  if {[lsearch $notevals 3] > 0} {
    if {[lsearch $notevals 6] > 0} {
      set key $root$dim
      } elseif {[lsearch $notevals 7] > 0} {
      set key $root$min
      } else {set key $root$min}
   } elseif {[lsearch $notevals 4] > 0} {
     if {[lsearch $notevals 7] >0} {
      set key $root$maj
      } elseif {[lsearch $notevals 8] > 0} {
      set key $root$aug
      } else {set key $root$maj}
  } else {set key $root}
  #puts $key
  return $key
  }


proc determineChordSequence {source} {
    global midi
    global sorted_midiactions
    global ppqn
    global pianoresult
    global midilength
    global exec_out
    global cleanData
    global briefconsole

    append exec_out "determineChordSequence $source\n"
    set list_of_chords [dict create]
    #Force loadMidiFile in case notegram alters pianoresult
    set midilength 0
    set cleanData 0
    if {$source == "pianoroll"} {
      set limits [midi_limits .piano.can]
      set start [lindex $limits 0]
      set stop  [lindex $limits 1]
      if {$midilength == 0} loadMidiFile
      set cleanData 1
      } elseif {$source == "tableau"} {
      set limits [midi_limits .ptableau.frm.can]
      set start [lindex $limits 0]
      set stop  [lindex $limits 1]
      if {$midilength == 0} loadMidiFile
      set cleanData 1
      } elseif {$source == "midistructure"} {
      set limits [midi_limits .midistructure.can]
      set start [lindex $limits 0]
      set stop  [lindex $limits 1]
      if {$midilength == 0} loadMidiFile
      set cleanData 1
      } else {
# if not called from .piano window
      copyMidiToTmp $source
      set cleanData 0
      set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -midigram"
      catch {eval $cmd} pianoresult
      if {$briefconsole} {
         append exec_out "\n\n$cmd\n\n [string range $pianoresult 0 200]..."
      } else {
         append exec_out "\n\n$cmd\n\n $pianoresult"
      }
      set nrec [llength $pianoresult]
      set midilength [lindex $pianoresult [expr $nrec -1]]
      set pianoresult [split $pianoresult \n]
      set start 0
      set stop $midilength
      }


    reorganize_pianoresult $source
    
    set tsel [count_selected_midi_tracks]
    
    
    turn_off_all_notes
    reset_beat_notestatus
    
    set last_time 0.0
    set last_beat_number 0

    set last_beat [expr int($midilength/$ppqn)]
    for {set i 0} {$i <$last_beat} {incr i} {
       dict set list_of_chords $i ""
       }
    set i 0
    
    foreach midiunit $sorted_midiactions {
        set begin [lindex $midiunit 0]
        if {[string is double $begin] != 1} continue
        if {$begin < $start} continue
        set end [lindex $midiunit 0]
        if {$end   > $stop}  continue
        
        set present_time [lindex $midiunit 0]
        set beat_time [format %5.2f [expr double($present_time)/$ppqn]]
        set beat_number [expr int($beat_time)]
        if {$last_beat_number != $beat_number} {
            set onlist [list_on_notes_in_beat]
            reset_beat_notestatus
            set last_beat_number $beat_number
            set chordstring [label_notelist $onlist]
            set chordname [chordname $chordstring [root_of $chordstring]]
            dict set list_of_chords $beat_number $chordname
            set last_time $present_time
        }
        
        switch_note_status $midiunit
    }
    dict set list_of_chord size $last_beat
    return $list_of_chords
}

proc make_chord_histogram {source} {
global total_chordcount
global chordcount
set total_chordcount 0
array unset chordcount
set chord_sequence [determineChordSequence $source]
set last_beat [dict size $chord_sequence]
for {set beat 0} {$beat < $last_beat} {incr beat} {
     set chord [dict get  $chord_sequence $beat]
     count_chords $chord}
set w .chordstats
$w.chords.t delete 0.0 end
$w.bar delete all
print_chordcount $w
chord_barchart
}



proc chord_barchart {} {
global chordcount
global total_chordcount
global midi
set chordcountlist {}
  foreach {elem1 elem2} [array get chordcount] {
     lappend chordcountlist [list $elem1 $elem2]
     }
set sortedcountlist [lsort -index 1 -integer -decreasing $chordcountlist]
.chordstats.bar create rectangle 50 20 420 230 -outline black\
            -width 2 -fill white
set i 0
set maxcount [lindex [lindex $sortedcountlist 0] 1]
set maxcount [expr $maxcount*1.2]
Graph::alter_transformation 50 420 230 20 0.0 $maxcount 8.0 0.0
while {$i < [llength $sortedcountlist]} {
  set chorddata [lindex $sortedcountlist $i]
  set chord [lindex $chorddata 0]
  set count [lindex $chorddata 1]
  set ix [Graph::ixpos 0.0]
  set iy1 [expr [Graph::iypos $i] + 4]
  set iy2 [expr [Graph::iypos [incr i]] - 4]
  set ix1 [Graph::ixpos $count]
  .chordstats.bar create rectangle $ix $iy1 $ix1 $iy2 -fill blue -stipple gray12
  .chordstats.bar create text 20 [expr $iy1 + 10] -text $chord
  if {$i > 7} break
  }
set spacing [best_grid_spacing $maxcount]
Graph::draw_x_grid .chordstats.bar $spacing $maxcount $spacing 1  0 %5.0f
}

proc switch_text_barchart {} {
global midi
if {$midi(chordhist) == "bar"} {
  pack forget .chordstats.chords
  pack .chordstats.bar
  } else {
  pack .chordstats.chords
  pack forget .chordstats.bar
  }
}

proc chord_histogram {source} {
    chord_histogram_window
    make_chord_histogram $source
    switch_text_barchart
}



#         chordgram plot 

set hlp_chordgram "Chordgram

Plots the predominant chord for each beat. The chord root is\
determined using Craig Sapp's algorithm, and then the type of chord\
is determined by looking at the spaces between the pitches. Major\
chords are in red, minor blue, diminished green and augmented in\
purple. The vertical scale is either sequential or follows the circle\
of fifths.\n\n
To zoom into an area, sweep the mouse pointer over the region holding\
the left mouse button down. Then press the zoom button. The chordgram\
may be linked to the midi structure window or the piano roll window\
if they are exposed.\n\n
Clicking the save data button will record the plotted results in the\
file chordgram.txt which can be found in the midiexplorer_home folder.

"

proc chordgram_plot {source} {
   global pianorollwidth
   global midi
   global df
   global chord_sequence
   global seqlength
   global exec_out
   set exec_out "chordgram_plot\n"
   if {![winfo exist .chordgram]} {
     toplevel .chordgram
     positionWindow .chordgram
     frame .chordgram.head
     checkbutton .chordgram.head.2 -text "circle of fifths" -variable midi(chordgram) -font $df -command "call_compute_chordgram $source"
     button .chordgram.head.play -text play -font $df -command {playExposed chordgram}
  tooltip::tooltip .chordgram.head.play "play the highlighted area or
 the exposed plot."
     button .chordgram.head.zoom -text zoom -command zoom_chordgram -font $df
  tooltip::tooltip .chordgram.head.zoom  "zooms into the region that you highlighted."
     button .chordgram.head.unzoom -text unzoom -command unzoom_chordgram -font $df 
  tooltip::tooltip .chordgram.head.unzoom  "zooms out to the full midi file."
     button .chordgram.head.save -text "save data" -font $df -command saveChordgramData
  tooltip::tooltip .chordgram.head.save  "Save chords list in\n midiexplorer_home/chordgram.txt"
     button .chordgram.head.help -text help -font $df -command {show_message_page $hlp_chordgram word}
     pack  .chordgram.head.2 .chordgram.head.play .chordgram.head.zoom .chordgram.head.unzoom .chordgram.head.save .chordgram.head.help -side left -anchor w
     pack  .chordgram.head -side top -anchor w 
     set c .chordgram.can
     canvas $c -width $pianorollwidth -height 250 -border 3 -relief sunken
     pack $c

     bind .chordgram.can <ButtonPress-1> {chordgram_Button1Press %x %y}
     bind .chordgram.can <ButtonRelease-1> chordgram_Button1Release
     bind .chordgram.can <Double-Button-1> chordgram_ClearMark
     }
   set chord_sequence [determineChordSequence $source]
   set last_beat [dict size $chord_sequence]
   set seqlength $last_beat
   call_compute_chordgram $source
   update_console_page
}

proc getCanvasLimits {source} {
global lastbeat
global fbeat
global tbeat
global ppqn
set start -1
set stop $lastbeat
switch $source {
  chordgram {
    set co [.chordgram.can coords mark]
    #puts "co = $co"
    set limits [chordgram_limits $co]
       if {[lindex $co 0] > 0} {
       set start [expr [lindex $limits 0]]
       set stop  [expr [lindex $limits 1]]
       } else {
       set start $fbeat
       set stop $tbeat
       #puts "fbeat = $fbeat tbeat = $tbeat"
       }
    }
  notegram {
    set co [.notegram.can coords mark]
    if {[lindex $co 0] > 0} {
       set limits [notegram_limits $co]
       set start [expr [lindex $limits 0]]
       set stop  [expr [lindex $limits 1]]
       } else {
       set start $fbeat
       set stop $tbeat
       }
    }
  pianoroll {
    set limits [midi_limits .piano.can]
    if {[lindex $limits 0] >= 0} {
       set start [expr [lindex $limits 0]/double($ppqn)]
       set stop  [expr [lindex $limits 1]/double($ppqn)]
       }
    }
  midistructure {
    set limits [midistruct_limits .midistructure.can]
    if {$limits != "none"} {
       set start [lindex $limits 0]
       set stop [lindex $limits 1]
       }
    }
  pgram {
    set limits  [pgram_limits .pgram.c]
    if {[llength $limits] > 1} {
       set start [lindex $limits 0]
       set tbeat [lindex $limits 1]
       }
   }
  tableau {
    set limits [tableau_limits]
    if {$limits != "none"} {
       set start [lindex $limits 0]
       set stop [lindex $limits 1]
       }
    }
  default {
    if {[info exist fbeat]} {
     set start 0
     set stop $lastbeat
     }
   }
  }
return [list $start $stop]
}

proc call_compute_chordgram {source} {
global exec_out
append exec_out "\ncall_compute_chordgram\n"
set limits [getCanvasLimits $source]
set start [lindex $limits 0]
set stop  [lindex $limits 1]
compute_chordgram $start $stop
}

proc chordgram_Button1Press {x y} {
    set xc [.chordgram.can canvasx $x]
    .chordgram.can raise mark
    .chordgram.can coords mark $xc 20 $xc 220
    bind .chordgram.can <Motion> { chordgram_Button1Motion %x }
}

proc chordgram_Button1Motion {x} {
    set xc [.chordgram.can canvasx $x]
    if {$xc < 0} { set xc 0 }
    set co [.chordgram.can coords mark]
    .chordgram.can coords mark [lindex $co 0] 20 $xc 220
}

proc chordgram_Button1Release {} {
    bind .chordgram.can <Motion> {}
    set co [.chordgram.can coords mark]
    if {[winfo exist .midistructure]} {
          chordgram_migrate_to_midistruct $co  
      }
   }

proc chordgram_limits {co} {
global midistructureheight
global chordgram_xfm
# convert to beat numbers
set b [lindex $chordgram_xfm 0]
set a [lindex $chordgram_xfm 2]
set left [lindex $co 0]
set right [lindex $co 2]
set beat1 [expr ($left -$a)/$b] 
set beat2 [expr ($right-$a)/$b]
return [list $beat1 $beat2]
}

proc zoom_chordgram {} {
call_compute_chordgram chordgram
}

proc unzoom_chordgram {} {
global seqlength
set start -1
set stop $seqlength
compute_chordgram $start $stop
}

proc chordgram_migrate_to_midistruct {co} {
global midistructureheight
global pixels_per_beat
set beatlimits [chordgram_limits $co]
set beat1 [expr [lindex $beatlimits 0]*$pixels_per_beat]
set beat2 [expr [lindex $beatlimits 1]*$pixels_per_beat]
.midistructure.can coords mark $beat1 0 $beat2 $midistructureheight
}

proc chordgram_ClearMark {} {
    .chordgram.can coords mark -1 -1 -1 -1
}



proc compute_chordgram {start stop} {
   global pianorollwidth
   global sharpnotes
   global flatnotes
   global sharpnotes5
   global flatnotes5
   global useflats
   global ppqn
   global midi
   global chordgram_xfm
   global chord_sequence
   global seqlength
   global chordgramLimits
   global fbeat
   global tbeat
   global exec_out
   append exec_out "compute_chordgram $start $stop\n"
   set fbeat $start
   set tbeat $stop
   set chordgramLimits [list $start $stop]
   # useflats is set by plot_pitch_class_histogram
   set xrbx [expr $pianorollwidth - 3]
   set xlbx  40
   set ytbx 20
   set ybbx 220 
   set c .chordgram.can
   $c delete all
   $c create rectangle $xlbx $ybbx $xrbx $ytbx -outline black -width 2 -fill lightgrey 
  set start5 [expr (1 + int($start)/5)*5.0]

   # white or black characters
  set colfg [lindex [.info.txt config -fg] 4]

   set pixelsperbeat [expr ($xrbx - $xlbx) / double($stop - $start)]
   Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx $start $stop 0.0 200.0 
   set chordgram_xfm [Graph::save_transform] 
   for {set j 0} {$j <$seqlength} {incr j} {
     if {$j < $start || $j > $stop} continue
     set chord [dict get $chord_sequence $j]
     if {$chord == ""} continue
     if {[string index $chord 1] == "#"} {
        set key [string range $chord 0 1]
        set chordtype [string range $chord 2 end]
        } elseif {[string index $chord 1] == "b"} {
        set key [string range $chord 0 1]
        set chordtype [string range $chord 2 end]
        } else {
        set key [string index $chord 0]
        set chordtype [string range $chord 1 end]
        }
     if {$midi(chordgram) == 1} {
       if {$useflats == 1} {
         set loc [lsearch $flatnotes5 $key]
         } else { 
         set loc [lsearch $sharpnotes5 $key]
         }
     } else {
       if {$useflats == 1} {
         set loc [lsearch $flatnotes $key]
         } else { 
         set loc [lsearch $sharpnotes $key]
         }
     }
     #puts "chord = $key $chordtype $loc"
     set ix [Graph::ixpos [expr double($j)]]
     set iy [Graph::iypos [expr double($loc*16) + 7 ]]
     set iy1 [expr $iy - 3]
     set iy2 [expr $iy + 3]
     set ix1 [expr $ix - 3]
     set ix2 [expr $ix + 3]
     switch $chordtype {
       maj {$c create oval $ix1 $iy1 $ix2 $iy2 -fill darkred}
       min {$c create oval $ix1 $iy1 $ix2 $iy2 -fill blue}
       dim {$c create oval $ix1 $iy1 $ix2 $iy2 -fill darkgreen}
       aug {$c create oval $ix1 $iy1 $ix2 $iy2 -fill purple}
       default {$c create oval $ix1 $iy1 $ix2 $iy2 -fill black}
       }
     }
  set i 0
  set ix 15 
  if {$midi(chordgram) == 1} {
    if {$useflats} {
      foreach name $flatnotes5 {
         set iy [Graph::iypos [expr double($i * 16)]] 
         set iy [expr $iy - 5]
         $c create text $ix $iy -text $name -fill $colfg
         incr i
         }
      } else {
      foreach name $sharpnotes5 {
         set iy [Graph::iypos [expr double($i * 16)]] 
         set iy [expr $iy - 5]
         $c create text $ix $iy -text $name -fill $colfg
         incr i
         }
     }
   } else {
    if {$useflats} {
      foreach name $flatnotes {
         set iy [Graph::iypos [expr double($i * 16)]] 
         set iy [expr $iy - 5]
         $c create text $ix $iy -text $name -fill $colfg
         incr i
         }
      } else {
      foreach name $sharpnotes {
         set iy [Graph::iypos [expr double($i * 16)]] 
         set iy [expr $iy - 5]
         $c create text $ix $iy -text $name -fill $colfg
         incr i
         }
      }
   }
    set graphlength [expr $stop - $start]
    set spacing [best_grid_spacing $graphlength]
    Graph::draw_x_grid $c $start5 $stop $spacing 1  0 %5.0f $colfg

   .chordgram.can create rect -1 -1 -1 -1 -tags mark -fill yellow -stipple gray25
}

proc saveChordgramData {} {
global midi
global chord_sequence
global seqlength
global chordgramLimits
global midiTempo
set beats2seconds [expr 60.0/double($midiTempo)]
set start [lindex $chordgramLimits 0]
set stop [lindex $chordgramLimits 1]
set outhandle [open "chordgram.txt" w]
puts $outhandle "chordgram results for $midi(midifilein)"
for {set j 0} {$j <$seqlength} {incr j} {
  if {$j < $start} continue
  if {$j > $stop} break
  set chord [dict get $chord_sequence $j]
  set seconds [format "%5.2f" [expr $j * $beats2seconds]]
  puts $outhandle "$j\t$seconds\t$chord"
  }
close $outhandle
tk_messageBox -message "saved in midiexplorer_home/chordgram.txt"  -type ok
}


proc notegram_plot {source} {
   global pianorollwidth
   global midi
   global df
   if {![winfo exist .notegram]} {
     toplevel .notegram
     positionWindow .notegram
     frame .notegram.head
     checkbutton .notegram.head.2 -text "circle of fifths" -variable midi(notegram) -font $df -command {compute_notegram none}
     button .notegram.head.play -text play -font $df -command {playExposed notegram}
     button .notegram.head.zoom -text zoom -command zoom_notegram -font $df
     button .notegram.head.unzoom -text unzoom -command unzoom_notegram -font $df
     pack  .notegram.head.2 .notegram.head.play .notegram.head.zoom .notegram.head.unzoom -side left -anchor w
     pack  .notegram.head -side top -anchor w 
     set c .notegram.can
     canvas $c -width $pianorollwidth -height 250 -border 3 -relief sunken
     pack $c
     }
     bind .notegram.can <ButtonPress-1> {notegram_Button1Press %x %y}
     bind .notegram.can <ButtonRelease-1> notegram_Button1Release
     bind .notegram.can <Double-Button-1> notegram_ClearMark

    compute_notegram $source
}


proc notegram_Button1Press {x y} {
    set xc [.notegram.can canvasx $x]
    .notegram.can raise mark
    .notegram.can coords mark $xc 20 $xc 220
    bind .notegram.can <Motion> { notegram_Button1Motion %x }
}

proc notegram_Button1Motion {x} {
    set xc [.notegram.can canvasx $x]
    if {$xc < 0} { set xc 0 }
    set co [.notegram.can coords mark]
    .notegram.can coords mark [lindex $co 0] 20 $xc 220
}

proc notegram_Button1Release {} {
    bind .notegram.can <Motion> {}
    set co [.notegram.can coords mark]
    if {[winfo exist .midistructure]} {
          notegram_migrate_to_midistruct $co  
      }
    }

proc notegram_ClearMark {} {
    .notegram.can coords mark -1 -1 -1 -1
}


proc zoom_notegram {} {
compute_notegram notegram
}

proc unzoom_notegram {} {
global seqlength
compute_notegram none
}


proc notegram_limits {co} {
global midistructureheight
global notegram_xfm
# convert to beat numbers
set b [lindex $notegram_xfm 0]
set a [lindex $notegram_xfm 2]
set left [lindex $co 0]
set right [lindex $co 2]
set beat1 [expr ($left -$a)/$b] 
set beat2 [expr ($right-$a)/$b]
return [list $beat1 $beat2]
}

proc notegram_migrate_to_midistruct {co} {
global midistructureheight
global pixels_per_beat
set beatlimits [notegram_limits $co]
set beat1 [expr [lindex $beatlimits 0]*$pixels_per_beat]
set beat2 [expr [lindex $beatlimits 1]*$pixels_per_beat]
.midistructure.can coords mark $beat1 0 $beat2 $midistructureheight
}


proc compute_notegram {source} {
   global pianorollwidth
   global pianoresult
   global lastbeat
   global sharpnotes
   global flatnotes
   global sharpnotes5
   global flatnotes5
   global useflats
   global ppqn
   global midi
   global fbeat
   global tbeat
   global notegram_xfm
   global cleanData
   global exec_out
   global briefconsole
   set exec_out "compute_notegram:\n"
   set permut5th {0 7 2 9 4 11 6 1 8 3 10 5}
   # white or black characters
   set colfg [lindex [.info.txt config -fg] 4]
   copyMidiToTmp $source
   set cleanData 0
   set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -midigram"
   catch {eval $cmd} pianoresult
   if {$briefconsole} {
      set exec_out [append exec_out "\nnotegram:\n\n$cmd\n\n [string range $pianoresult 0 200]"]
      } else {
      set exec_out [append exec_out "\nnotegram:\n\n$cmd\n\n $pianoresult]
      } 
   # useflats is set by plot_pitch_class_histogram
   set xrbx [expr $pianorollwidth - 3]
   set xlbx  40
   set ytbx 20
   set ybbx 220 
   set c .notegram.can
   $c delete all
   set start 0
   if {$tbeat == 0} {set tbeat $lastbeat}
   $c create rectangle $xlbx $ybbx $xrbx $ytbx -outline black -width 2 -fill lightgrey 
   Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx $fbeat $tbeat 0.0 200.0 
   set notegram_xfm [Graph::save_transform] 
   foreach line [split $pianoresult \n] {
     if {[llength $line] != 6} continue
     set begin [lindex $line 0]
     set end [lindex $line 1]
     set t [lindex $line 2]
     set channel [lindex $line 3]
     if {$channel == 10} continue
     set note [lindex $line 4]
     set note [expr $note % 12]
     if {$midi(notegram) == 1} {
        set loc [lindex $permut5th $note]
     } else {set loc $note}
     set ix [Graph::ixpos [expr $fbeat + double($begin)/$ppqn]]
     set iy [Graph::iypos [expr double($loc*16) + 7 ]]
     set iy1 [expr $iy - 3]
     set iy2 [expr $iy + 3]
     set ix1 [expr $ix - 3]
     set ix2 [expr $ix + 3]
     $c create oval $ix1 $iy1 $ix2 $iy2 -fill black
     }
  set i 0
  set ix 15 
  if {$midi(notegram) == 1} {
    if {$useflats} {
      foreach name $flatnotes5 {
         set iy [Graph::iypos [expr double($i * 16)]] 
         set iy [expr $iy - 5]
         $c create text $ix $iy -text $name -fill $colfg
         incr i
         }
      } else {
      foreach name $sharpnotes5 {
         set iy [Graph::iypos [expr double($i * 16)]] 
         set iy [expr $iy - 5]
         $c create text $ix $iy -text $name -fill $colfg
         incr i
         }
     }
   } else {
    if {$useflats} {
      foreach name $flatnotes {
         set iy [Graph::iypos [expr double($i * 16)]] 
         set iy [expr $iy - 5]
         $c create text $ix $iy -text $name -fill $colfg
         incr i
         }
      } else {
      foreach name $sharpnotes {
         set iy [Graph::iypos [expr double($i * 16)]] 
         set iy [expr $iy - 5]
         $c create text $ix $iy -text $name -fill $colfg
         incr i
         }
      }
   }
    set start5 0
    if {$fbeat != 0} {set start5 [expr (1 + int($fbeat)/5)*5.0]}
    set spacing [best_grid_spacing [expr ($tbeat - $fbeat)]]
    Graph::draw_x_grid $c $start5 $tbeat $spacing 1  0 %5.0f $colfg

   .notegram.can create rect -1 -1 -1 -1 -tags mark -fill yellow -stipple gray25
}


#   Part 9.0 Midistructure window and support
#
set hlp_midistructure "Displays the times when different channels\
or tracks are active. The different musical instruments, midi\
programs, are divided into 17 classes and assigned specific colors.\
For example all keyboard instruments are dark blue, wind\
instruments are green, and percussion instruments are black.\
If you move the mouse pointer over one of these coloured bar,\
the actual midi program name (musical instrument) will be shown\
below.

Like the pianoroll, the midistructure allows you to select\
tracks or channels using the checkbuttons. Specific actions\
are applied to only the checked items unless none are checked.\
The invert button reverses all the checked items.\
You can also select a specific time interval by\
by holding down the left mouse button and sweeping the cursor\
over the desired interval.

Depending on how the options are set, the play button will accentuate\
the selected tracks/channels, play them exclusively, or play all\
tracks/channels except those selected.  The speed slider allows\
you to speed up or slow down the music for playback.

The program actually creates a temporary midi file with a\
random 8 letter name beginning with x containing the desired\
music. This file is automatically deleted during cleanup.\
Clicking the save button allows you to copy this file for\
future analysis giving it a more meaningful name.

The abc button allows you to convert the current temporary\
midi file into abc notated text and display it in a\
customized editor.  The help button in this editor provides\
more details.

The midistructure window displays other data such as the\
program color and pitch class distributions. The program color\
distribution indicates the amount of activity in each of\
the 17 classes of midi programs. This information could be used\
to search for other files having the same distributions using\
the database/search window. The mapping function of\
the colors to the midi programs is shown when you use the\
database/search window and click the button\
labeled 'contains program'.
"




set midistructurewidth 400

proc midi_structure_display {} {
   global midi
   global cleanData
   loadMidiFile
   set cleanData 1
   destroy .midistructure
   midi_structure_window 
   bind .midistructure <Alt-p> midistructure_postscript_output
}

proc midi_structure_window {} {
  set w .midistructure
  global ntrk df
  global midi
  global midichannels
  global miditracks
  global highlighted_segment
  global chosen_segment
  global midistructurewidth
  global xstrpick ystrpick
  global midispeed

  if {[winfo exist $w]} {
    raise $w .
    show_prog_structure
    return
    }
  toplevel $w
  positionWindow $w
  wm title $w "midi structure "
  set entrywidth [expr int(800/double($midi(font_size)))]
  set wm $w.menuline
  frame $wm
  button $wm.options -text options -font $df -width 7 -relief flat \
   -command {set_preferences}
  tooltip::tooltip $wm.options "Controls the behaviour of the midistructure
function"

  button $wm.invert -text invert -font $df -command invertMidiTracksAndChannels

  button $wm.play -text play -font $df -command midistructure_play
  tooltip::tooltip $wm.play "play entire selection or selected\nchannels/tracks\
 according to options."
  label $wm.speedlabel -text speed -font $df
  scale $wm.speed -length 140 -from 0.1 -to 4.0 -orient horizontal\
     -resolution 0.05 -width 10 -variable midispeed -font $df
  set midispeed 1.0

  tooltip::tooltip $wm.speedlabel "Change the speed of the playback\n by the specified factor."

  button $wm.save -text save -font $df -command save_temporary_midi_file
  tooltip::tooltip $wm.save "Save the last temporary\n midi file you created"

  menubutton $wm.plot -text plot -menu $wm.plot.items -font $df
  menu $wm.plot.items -tearoff 0
 $wm.plot.items add command  -label "pitch class plot" -font $df \
            -command {midi_statistics pitch midistructure
                      show_note_distribution
                     } 
 $wm.plot.items add command  -label "pitch distribution" -font $df \
            -command {midi_statistics pitch midistructure
                      plotmidi_pitch_pdf
                      }
 $wm.plot.items add command -label chordgram -font $df -command {chordgram_plot midistructure}
 $wm.plot.items add command -label notegram -font $df -command {notegram_plot midistructure}
 tooltip::tooltip $wm.plot "Various plots including chordgram and notegram"


  button $wm.abc -text abc -font $df -command {create_abc_file midistructure}
  tooltip::tooltip $wm.abc "Convert the selected tracks (channels) or entire\nmidi file to abc notation and open an abc editor."

  button $wm.help -text help -font $df -command {show_message_page $hlp_midistructure word}

  entry $w.fileinent -width $entrywidth -textvariable midi(midifilein) -font $df\
    -state readonly 
  label $w.txt -text ""
  label $w.txt2 -text "midi structure" -font $df
  label $w.beat -text beat -font $df
  $w.fileinent xview moveto 1.0
  bind $w.fileinent <Return> {focus .midistructure.file}
  grid $w.fileinent -columnspan 2
  pack $wm.options $wm.invert $wm.play $wm.speedlabel $wm.speed $wm.save $wm.plot $wm.abc $wm.help -side left
  grid $wm -columnspan 2 -sticky nw
    

  set f [frame $w.leftbuttons -bd 3 -relief sunken]
  for {set i 2} {$i <40} {incr i} {
    checkbutton .midistructure.leftbuttons.$i -text "trk$i" -variable miditracks($i) -font $df -command {updateAllWindows midistructure}
    }
  for {set i 1} {$i <17} {incr i} {
    checkbutton .midistructure.leftbuttons.c$i -text "chan$i" -variable midichannels($i) -font $df -command {updateAllWindows midistructure}
    }
  set yspacing [winfo reqheight .midistructure.leftbuttons.2]
  canvas $w.can -width $midistructurewidth -height 200 -border 3 -relief sunken -scrollregion "0. 0. $midistructurewidth 200"
  canvas $w.canx -width $midistructurewidth -height 20  -border 3 -relief sunken
  grid $w.leftbuttons $w.can -sticky news
  grid $w.beat $w.canx -sticky news
  grid $w.txt -column 1
  grid $w.txt2 -column 1


    bind .midistructure.can <ButtonPress-1> {mstruct_Button1Press %x %y}
    bind .midistructure.can <ButtonRelease-1> {mstruct_Button1Release}
    bind .midistructure.can <Double-Button-1> mstruct_ClearMark


   midiStructureSelect
   show_prog_structure
}

proc mstruct_Button1Press {x y} {
    global midistructureheight
    set xc [.midistructure.can canvasx $x]
    .midistructure.can raise mark
    .midistructure.can coords mark $xc 0 $xc $midistructureheight
    bind .midistructure.can <Motion> { mstruct_Button1Motion %x }
}

proc mstruct_Button1Motion {x} {
    global midistructureheight
    set xc [.midistructure.can canvasx $x]
    #puts "mstruct_Button1Motion $xc"
    if {$xc < 0} { set xc 0 }
    set co [.midistructure.can coords mark]
    .midistructure.can coords mark [lindex $co 0] 0 $xc $midistructureheight
}

proc mstruct_Button1Release {} {
    bind .midistructure.can <Motion> {}
    set co [.midistructure.can coords mark]
    updateAllWindows midistructure
    }

proc mstruct_ClearMark {} {
    .midistructure.can coords mark -1 -1 -1 -1
}

proc midistruct_limits {can} {
# limits of selected region in midistructure
    global pixels_per_beat
    set co [$can coords mark]
    #   is there a marked region of reasonable extent ?
    set extent [expr [lindex $co 2] - [lindex $co 0]]
    if {$extent > 5} {
        set xleft [expr [lindex $co 0]/$pixels_per_beat]
        set xright [expr [lindex $co 2]/$pixels_per_beat]
        #puts "midistruct_limits: $xleft $xright beats"
	return "$xleft $xright"
    } else {
        #puts "midistruct_limits: none"
        return none}
}


set progmapper {
 0  0  0  0  0  0  0  0 
 0  1  1  1  1  1  1  2
 3  3  3  3  3  3  3  3
 2  2  4  4  4  4  4  2 
 5  5  5  5  5  5  5  5 
 6  6  6  6  6  2  7 10 
 7  7  7  7  8  8  8  8 
 9  9  9  9  9  9  9  9 
11 11 11 11 11 11 11 11
12 12 12 12 12 12 12 12
13 13 13 13 13 13 13 13
14 14 14 14 14 14 14 14 
15 15 15 15 15 15 15 15 
 2  2  2  2  2 12  6 12 
 1  1 10 10 10 10 10  1 
16 16 16 16 16 16 16 16 
}



set groupcolors {{medium blue}  
                 Dodgerblue4    
                 orange3   
                 {chartreuse}   
                 {orange red}   
                 {indian red}   
                 {blue violet}  
                 magenta4       
                 {deep pink}    
                 yellow
                 gray30         
                 green4         
                 turquoise
                 firebrick      
                 sienna4        
                 maroon         
		 {dodger blue} 
		 {slate gray} 
                 }

set groupnames { "piano keyboard"
                 "xylophone category"
                 "acoustic guitar category"
                 "organ class"
                 "electric guitar set"
                 "electric bass set"
                 "solo strings (eg. violin)"
                 "string ensembles"
                 "choir"
                 "brass"
                 "drum class"
                 "woodwind"
                 "flute category"
                 "lead class"
                 "pad class"
                 "FX class"
                 "Banjo class"
                 "electronic synthesizer"
                }

               


proc show_prog_structure {} {
  global midi lastbeat
  global midistructurewidth
  global midistructureheight
  global ntrks
  global activechan
  global chanprog
  global xchannel2program
  global track2program
  global track2channel
  global pixels_per_beat
  global yspacing
  global progmapper
  global groupcolors
  global df
  global cprogcolor
  global cprogsact
  global cprogs
  global exec_out
  #global seglink

  set exec_out "show_prog_structure"
  #puts "show_midi_structure channel2program [array get channel2program]"
  if {![winfo exist .midistructure]} return

  if {$midi(midishow_sep) == "track" && $ntrks == 1} {
     .midistructure.txt configure -text "Type 0 midi file. Cannot separate by track" -foreground red
     set midi(midishow_sep) "chan"
     return
     }


  set nbut 0
  .midistructure.can delete all
  .midistructure.canx delete all
  for {set i 2} {$i < 32} {incr i} {pack forget .midistructure.leftbuttons.$i}
  for {set i 1} {$i < 17} {incr i} {pack forget .midistructure.leftbuttons.c$i}
  #puts "activechan = [array get activechan]"
  #puts "track2channel = [array get track2channel]"
  if {$midi(midishow_sep) == "track"} {
    for {set i 2} {$i < 32} {incr i} {
       if {[info exist track2channel($i)]} {
	       set c $track2channel($i)
       } else {#puts "track2channel($i) does not exist"
	       break
	       }
       if {$activechan($c)} {
         pack .midistructure.leftbuttons.$i -side top
         # ct2band maps track/channel to button band
         incr nbut
         set ct2band($i) $nbut
         } 
       }
  } else {
    #puts "nseg = $nseg"
    # separating by channel  
    set yspacing [winfo reqheight .midistructure.leftbuttons.2]
    for {set i 0} {$i < 17} {incr i} {
       if {[info exist activechan($i)]} {
	 set c $i
	 if {![info exist ct2band($c)]} {
           incr nbut
           set ct2band($c) $nbut
           }
         pack .midistructure.leftbuttons.c$c -side top
       }
    }
  }
  .midistructure.can create rect -1 -1 -1 -1 -tags mark -fill yellow -stipple gray25
  #plot_programcolor
  #plot_program_activity


  set yspacing [winfo reqheight .midistructure.leftbuttons.2]
  set midistructureheight [expr $nbut * $yspacing + 3]
  .midistructure.can configure -height [expr $nbut * $yspacing]
  for {set i 1} {$i <  $nbut } {incr i} {
    set y [expr $yspacing*$i]
    .midistructure.can create line 1 $y 399 $y -dash {1 2}
    }


  set pixels_per_beat [expr double($midistructurewidth)/$lastbeat]
  set xspacing [best_grid_spacing $lastbeat]
  set x  0
  while {$x < $lastbeat} {
    set x  [expr $x + $xspacing]
    set x1 [expr $x * $pixels_per_beat]
    .midistructure.can create line $x1 0 $x1 [expr $nbut*$yspacing] -dash {1 2}
    .midistructure.canx create text $x1 15 -text $x -font $df
    }


# new code follows here
#
  global pianoresult
  global midicommands
  global ppqn
  global chn2prg
  #set sorted_pianoresult [lsort -command compare_onset $pianoresult]
  set taglist {}

  for {set i 0} {$i < 128} {incr i}  {set progactivity($i) 0}
  for {set i 0} {$i < 17} {incr i} {set koloractivity($i) 0}

  foreach line $midicommands {
     set begin [lindex $line 0]
     set end [lindex $line 1]
     if {[llength $line] == 6} {
       set begin [expr $begin/$ppqn]
       set end [expr [lindex $line 1]/$ppqn]
       set t [lindex $line 2]
       set c [lindex $line 3]
       if {$c == 10} {
         set kolor black
       } else {
         if {[info exist chn2prg($c)]} {
            set p $chn2prg($c)
         } else {
            set p 0
         }
         set g [lindex $progmapper $p]
         set kolor [lindex $groupcolors $g]
       }
       if {$c != 10} {
         set progactivity($p) [expr $progactivity($p) + $end - $begin]
         set koloractivity($g) [expr $koloractivity($g) + $end - $begin] 
         }
       set x1 [expr $begin*$pixels_per_beat]
       set x2 [expr $end*$pixels_per_beat]
       if {$midi(midishow_sep) == "track"} {
         set y [expr $ct2band($t) *$yspacing  - 14]
         } else {
         set y [expr $ct2band($c) *$yspacing  - 14]
         }
      set x1 [expr round($x1) -2]
      set x2 [expr round($x2) +2]
      set y [expr round($y)]
      if {$c != 10} {
        set tagname p$p
        set tagname c$c$tagname
        if {[lsearch $taglist $tagname] < 0} {lappend taglist $tagname}
        .midistructure.can create line $x1 $y $x2 $y -width 13 -tag $tagname -fill $kolor -activefill red
        } else {
        .midistructure.can create line $x1 $y $x2 $y -width 13 -tag drum -fill $kolor
        }

      }
      if {$end == "Program"} {
	     set c [lindex $line 2]
	     set p [lindex $line 3]
             set chn2prg($c) $p 
	     set g [lindex $progmapper $p]
             }
    }


    set cprogcolor ""
    for {set i 0} {$i < 17} {incr i} {
       append cprogcolor " $koloractivity($i)" 
      }
    set cprogcolor [normalize_vectorlist $cprogcolor]

    set cprogsact ""
    set cprogs ""
    for {set i 0} {$i < 128} {incr i} {
      if {$progactivity($i) != 0} {
	      append cprogs " $i"
	      append cprogsact " $progactivity($i)"}
      }
    set cprogsact [normalize_vectorlist $cprogsact]

      
    plot_programcolor
    append exec_out "\nplot_programcolor"
    plot_program_activity
    append exec_out "\nplot_program_activity"
    update_console_page

    #puts $taglist
    lappend taglist drum
    bind_midistructure_tags $taglist 
  }

proc midistructure_postscript_output {} {
  update
  .midistructure.programcolor.c postscript -file progcolor.ps
  .midistructure.pitchclasses.c postscript -file pitchclasses.ps
  puts "progcolor.ps and pitchclasses.ps saved"
}



# set binding when mouse pointer enters or leaves a segment.
proc bind_segments {nseg} {
    global midi
    global xstrpick ystrpick
    global chosen_segment
    global highlighted_segment
    set w .midistructure.can
    for {set num 1} {$num < $nseg} {incr num} {
        .midistructure.can bind seg$num <Enter> "highlight_segment $num %x %y"
        .midistructure.can bind seg$num <Leave> "unhighlight_segment $num"
        #puts "trk$num"
    }
}

proc bind_midistructure_tags {taglist} {
global mlist
foreach tagelem $taglist {
 scan $tagelem "c%dp%d" c p
 set msg "channel $c -> [lindex $mlist $p]"
 .midistructure.can bind $tagelem <Enter> "highlight_midistructure $tagelem %x %y"
# .midistructure.can bind $tagelem <Leave> "unhighlight_midistructure $tagelem %x %y"
 } 
}

proc highlight_midistructure {tag x y} {
global df
global mlist
scan $tag "c%dp%d" c p
if {$tag == "drum"} {
  set msg "channel 10 -> percussion channel"
} else {
  set msg "channel $c -> [lindex $mlist $p]"
  }
.midistructure.txt configure -text $msg -font $df
#.midistructure.can itemconfigure $tag -fill red
} 

proc unhighlight_midistructure {tag x y} {
global chn2prg
global progmapper
global groupcolors
scan $tag "c%dp%d" c p
set p $chn2prg($c)
set g [lindex $progmapper $p]
set kolor [lindex $groupcolors $g]
.midistructure.can itemconfigure $tag -fill $kolor
}

# change color of segment 

set highlighted_segment 0

proc highlight_segment {num x y} {
    set w .midistructure.can
    global highlighted_segment seglink channel2program
    global mlist
    global pixels_per_beat
    global df
    .midistructure.can itemconfigure seg$num -fill red 
    set highlighted_segment $num
    set beatnumber [expr $x/$pixels_per_beat]
    set c [lindex $seglink($highlighted_segment) 1]
    if {$c == 10} {
      set program "Drum channel"
      } else {
      set program [lindex $mlist $channel2program($c)]
      set p [program_mod $c $beatnumber]
      if {$p > -1} {
         set program [lindex $mlist $p]
         }
      }
    .midistructure.txt configure -text "channel $c -> $program" -font $df
}


proc unhighlight_segment {num} {
    global highlighted_segment
    global seglink
    global channel2program
    global progmapper
    global groupcolors
    global df
    set c [lindex $seglink($num) 1]
    if {$c == 10} {
      set kolor black
      } else {
      set p $channel2program($c)
      set g [lindex $progmapper $p]
      set kolor [lindex $groupcolors $g]
      }
    .midistructure.can itemconfigure seg$num -fill $kolor
    set highlighted_segment 0
    .midistructure.txt configure -text "" -font $df
}


proc adjust_vert_spacing {vspace} {
# make vspace either 1,2,5 or 10 times suitable power of 10
  set pow 0
  while {$vspace > 10.0} {
    incr pow
    set vspace [expr $vspace/10.0]
    }
  if {$vspace > 7.0} {set vspace 10.0
   } elseif {$vspace > 3.0} {set vspace 5.0
   } elseif {$vspace > 1.4} {set vspace 2.0
   } else {set vspace 1.0}
  while {$pow > 0} {
   incr pow -1
   set vspace [expr $vspace * 10]
   }
 set vspace [expr int($vspace)]
 return $vspace
 } 

# procedure for drawing on the piano roll canvas.
proc compute_pianoroll {} {
    global midi
    global midilength
    global pianoPixelsPerFile
    global pianoresult pianoxscale
    #global activechan
    global ppqn
    global piano_vert_lines
    global chanprog
    global track2channel
    global df
    global piano_qnote_offset
    global exec_out
    
    #set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -midigram"
    set cmd "exec [list $midi(path_midi2abc)] [list $midi(midifilein)] -midigram"
    append exec_out $cmd
    catch {eval $cmd} pianoresult
    set nrec [llength $pianoresult]
    set midilength [lindex $pianoresult [expr $nrec -1]]
    set pianoresult [split $pianoresult \n]
    
    #puts "compute_pianoroll [llength $pianoresult]"
    update_console_page 
    if {[llength $pianoresult] < 1} {
        return
    }
    
    
    set p .piano
    if {![winfo exist .piano]} return
    set piano_qnote_offset 0
    # subtract 4 to prevent growing bbox of .piano.can
    set pianoxscale [expr ($midilength / double($pianoPixelsPerFile -4))]
    
    set qnspacing  [expr $pianoPixelsPerFile*$ppqn/double($midilength)]
    set piano_vert_lines [expr 40.0/$qnspacing]
    set piano_vert_lines [adjust_vert_spacing $piano_vert_lines]
    #puts "piano_vert_lines = $piano_vert_lines"
    if {$piano_vert_lines <1} {set piano_vert_lines 1}
    
    set xvright [expr round($midilength/$pianoxscale +20)]
    $p.can delete all
    
    $p.can create rect -1 -1 -1 -1 -tags mark -fill yellow -stipple gray25
    
    if [info exist activechan] {
        unset activechan
    }
    for {set i 0} {$i <89} {incr i} {
        set j [expr ($i+8)%12]
        switch -- $j {
            1 -
            3 -
            6 -
            8 -
            10 {
                $p.can create rectangle 0 [expr 724-$i*8] $pianoPixelsPerFile\
                        [expr 716-$i*8] -fill gray80 -outline ""
            }
            default {
                $p.can create rectangle 0 [expr 724-$i*8] $pianoPixelsPerFile\
                        [expr 716-$i*8] -fill LemonChiffon1 -outline ""
            }
        }
        if {$j == 0} {
            set octave [expr $i/12 + 1]
            set legend [format "C%d" $octave]
            $p.cany create text 10 [expr 724-$i*8] -text $legend
        }
        if {$j == 5} {
            set octave [expr $i/12 + 1]
            set legend [format "F%d" $octave]
            $p.cany create text 10 [expr 724-$i*8] -text $legend
        }
    }
    .piano.txt configure -text "" -foreground Black

    
    piano_qnotelines

    foreach line $pianoresult {
        if {[string match "Program" [lindex $line 1]] == 1} {
          set chanprog([lindex $line 2]) [lindex $line 3]
        } elseif {[string match [lindex $line 0] "Header"]} {
          set midifiletype [lindex $line 1]
          .piano.txt configure -text [format "midi file type %d" $midifiletype] -foreground Black -font $df
        } 
        if {$midifiletype == 0} {set midi(midishow_sep) "chan"} 
	if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        if {[string is double $begin] != 1} continue
        set end [lindex $line 1]
        set t [lindex $line 2]
        set c [lindex $line 3]
        set track2channel($t) $c
        if {$midi(midishow_sep) == "track"} {set sep $t} else {set sep $c}
        set note [lindex $line 4]
        set ix1 [expr $begin/$pianoxscale]
        set ix2 [expr $end/$pianoxscale]
        set iy [expr 720 - ($note-20)*8]
        if {$midi(nodrumroll) == 0 || $c != 10} {
          $p.can create line $ix1 $iy $ix2 $iy -width 3 -tag trk$sep\
                -arrow last -arrowshape {2 2 2}
          #puts "tag = trk$sep"
          }
        set activechan($sep) 1
    }
    #puts "activechan/tracks = [array names activechan]"
    bind_tracks
    set bounding_box [$p.can bbox all]
    set top [lindex $bounding_box 1]
    set bot [lindex $bounding_box 3]
    
    
    
    set bounding_boxx [list [lindex $bounding_box 0] 0 [lindex $bounding_box\
            2] 20]
    set bounding_boxy [list 0 [lindex $bounding_box 1] 20\
            [lindex $bounding_box 3]]
    $p.can configure -scrollregion $bounding_box
    $p.canx configure -scrollregion $bounding_boxx
    $p.cany configure -scrollregion $bounding_boxy
    put_trkchan_selector
    highlight_all_chosen_tracks 
}


proc piano_qnotelines {} {
    global ppqn midilength pianoxscale piano_vert_lines
    global piano_qnote_offset vspace
    set p .piano
    $p.canx delete all
    set bounding_box [$p.can bbox all]
    set top [lindex $bounding_box 1]
    set bot [lindex $bounding_box 3]
    $p.can delete -tag  barline
    if {$piano_vert_lines > 0} {
        set vspace [expr $ppqn*$piano_vert_lines]
        set txspace $vspace
        while {[expr $txspace/$pianoxscale] < 40} {
            set txspace [expr $txspace + $vspace]
        }
        
        
        for {set i $piano_qnote_offset} {$i < $midilength} {incr i $vspace} {
            set ix1 [expr $i/$pianoxscale]
            if {$ix1 < 0} continue
            $p.can create line $ix1 $top $ix1 $bot -width 1 -tag barline -fill green
        }
        
        for {set i $piano_qnote_offset} {$i < $midilength} {incr i $txspace} {
            set ix1 [expr $i/$pianoxscale]
            if {$ix1 < 0} continue
            $p.canx create text $ix1 5 -text [expr $piano_vert_lines*int($i/$vspace)]
        }
    }
}

proc qnote_spacing_adjustment {ppqn_incr} {
    global ppqn piano_qnote_offset
    #change ppqn and adjust piano_qnote_offset so that
    #the qnote line near left edge remains almost stationary.
    set limits [midi_limits .piano.can]
    set leftedge [lindex $limits 0]
    set leftedgeqnote [expr double($leftedge - $piano_qnote_offset)/$ppqn]
    incr ppqn $ppqn_incr
    set leftedgeqnote2 [expr double($leftedge - $piano_qnote_offset)/$ppqn]
    set deltaqnote [expr $leftedgeqnote2 - $leftedgeqnote]
    set offset_adjustment [expr int($deltaqnote*$ppqn)]
    incr piano_qnote_offset $offset_adjustment
    piano_qnotelines
    .piano.txt configure -text [format "ppqn = %d" $ppqn] -foreground Black
    if {[winfo exists .beatgraph]} {beat_graph pianoroll}
}

proc qnote_offset_adjustment {offset} {
    global piano_qnote_offset
    incr piano_qnote_offset $offset
    piano_qnotelines
    if {[winfo exists .beatgraph]} {beat_graph pianoroll}
}


proc hideExposeSomePianoRollTracksChannels {hide} {
global activechan
global track2channel
global midi
global trksel
if {$hide == 1} {
  set col ""
  } else {
  set col black
  }
if {$midi(midishow_sep) == "track"} {
  for {set i 2} {$i < 32} {incr i} {
    if {[info exist track2channel($i)] && $trksel($i) == 0} {
      .piano.can itemconfigure trk$i -fill $col -width 4
      }
  }
} else {
  for {set i 0} {$i <17} {incr i} {
    if {[info exist activechan($i)] && $trksel($i) == 0} {
      .piano.can itemconfigure trk$i -fill $col -width 4
    }
  }
}
}



proc put_trkchan_selector {} {
# places a line of buttons at the bottom of the .piano window
# for selecting midi channels or tracks for further action.
    global activechan midi chanprog mlist df
    global track2channel
    global last_checked_button

    #puts "track2channel [array get track2channel]"
    set j 0
    for {set i 0} {$i < 32} {incr i} {
        grid forget .piano.trkchn.$i
        }
# depending on whether we are separating by midi channel or track number
    if {$midi(midishow_sep)=="track"} {
        .piano.trkchn.play configure -text "play selected tracks" -font $df
        .piano.trkchn.display configure -text "display selected tracks" -font $df
	for {set i 2} {$i <32} {incr i} {
            if {[info exist track2channel($i)]} {
              grid .piano.trkchn.$i -sticky nw -row [expr $j/10] -column [expr 2 +( $j % 10)]
              incr j
              }
           }

    } else {

        .piano.trkchn.play configure -text "play selected channels" -font $df
        .piano.trkchn.display configure -text "display selected channels" -font $df
	for {set i 0} {$i <17} {incr i} {
            if {[info exist activechan($i)]} {
              grid .piano.trkchn.$i -sticky nw -row [expr $j/10] -column [expr 2 +( $j % 10)]
              incr j
              }
        } 
    }

#  Bind the buttons so they detect the mouse pointer entering or leaving
#  the button. The appropriate notes on the pianoroll display will be
#  highlighted in red. 

       for {set i 0} {$i < $j} {incr i} {
            #puts "binding $i"
            bind .piano.trkchn.$i <Enter> {
              #puts "window = [split %W .]" 
              set n [lindex [split %W .] 3]
              set num $n

              if {$midi(midishow_sep)=="track"} {
                 set num $track2channel($n)}
              if {$num == 10} {
                 .piano.txt configure -text "drum channel" -font $df
              } elseif {[info exist chanprog($num)]} {
                 .piano.txt configure -text [lindex $mlist $chanprog($num)] -font $df
              } else {
                 .piano.txt configure -text [lindex $mlist 0] -font $df
              }

              #puts ".piano.trkchn.$i bound to trk$n"
	      #puts "trksel($n) = $trksel($n)"
              if {$trksel($n) == 0 && $midi(trackSelector) == "dynamic"} {
                 .piano.can itemconfigure trk$n -fill red -width 3
                 } 
              # restore checkbutton to black in case it is still red.
              if {$last_checked_button >= 0} {
                .piano.trkchn.$last_checked_button configure -foreground black
                set last_checked_button -1
                }
              } 

            bind .piano.trkchn.$i <Leave> {
              set n [lindex [split %W .] 3]
              if {$trksel($n) == 0 && $midi(trackSelector) == "dynamic"} {
                .piano.can itemconfigure trk$n -fill black -width 3
                }
              }
            }
}





proc piano_horizontal_scroll {val} {
    .piano.can xview moveto $val
    .piano.canx xview moveto $val
}



# set binding when mouse pointer enters or leaves a note on/off bar.
proc bind_tracks {} {
    global activechan
    foreach {num} [array names activechan] {
        .piano.can bind trk$num <Enter> "highlight_checkbutton $num %x %y"
        .piano.can bind trk$num <Leave> "unhighlight_checkbutton $num"
        #puts "trk$num"
    }
}


proc highlight_checkbutton {num x y} {
    global highlighted_trk
    global last_checked_button
    if {$last_checked_button >= 0} {
      .piano.trkchn.$last_checked_button configure -foreground black
      set last_checked_button -1
      }
    .piano.trkchn.$num configure -foreground red
    set highlighted_trk $num
    update_piano_txt $x $y
    after 3000 unhighlight_checkbutton $num
}


proc unhighlight_checkbutton {num} {
    global highlighted_trk
    global last_checked_button
    set highlighted_trk 0
    set last_checked_button $num 
    if {[winfo exist .piano]} {
      .piano.trkchn.$num configure -foreground black
      }
}



proc midi_to_key {midipitch} {
    global note
    global sharpnotes
    global flatnotes
    global useflats
    set midipitch [expr round($midipitch)]
    set octave [expr $midipitch/12 -1]
    if {$useflats} {
      set keyname [lindex $flatnotes [expr $midipitch % 12]]
      } else {
      set keyname [lindex $sharpnotes [expr $midipitch % 12]]
      }
    return $keyname$octave
}


proc update_piano_txt {x y} {
    global pianoxscale ppqn
    global trkchan
    global midi
    global track2channel
    global chanprog
    global mlist
    focus .piano.can
    set x [.piano.can canvasx $x]
    set y [.piano.can canvasy $y]
    set pos [expr $x*$pianoxscale]
    set beat [expr $pos/$ppqn]
    set pitch [expr int(32 +(628 - $y)/8)]
    set note [midi_to_key $pitch]
    set id [.piano.can find withtag current]
    set taglist [.piano.can gettag $id]
    set trk [lindex $taglist [lsearch -glob $taglist trk*]]
    set notedata $trk


    # if this is a not a note just show the position.
    if {[string length $notedata] == 0} {
      .piano.txt configure -text \
          [format "%s = %6.0f pulses = %4.0f beats" $note $pos $beat] \
          -foreground Black
       return}

    # get note information (channel/track and program)
    set num [scan $notedata trk%d]
    if {$midi(midishow_sep) == "chan"} {
        set trk [string replace $trk 0 2 chan]
       } else {
       set num $track2channel($num)
       }
    if {$num == 10} {set prog "drum channel"
       } elseif {[info exist chanprog($num)]} {
         set prog [lindex $mlist $chanprog($num)]
       } else {
         set prog [lindex $mlist 0]
       }
    .piano.txt configure -text \
          [format "%s = %6.0f pulses = %4.0f beats %s %s" $note $pos $beat $trk $prog] \
          -foreground Black
 }


proc midi_limits {can} {
    global pianoxscale
    global drumxscale
    global lastpulse
    global pixels_per_beat
    global ppqn
    set ppqn4 [expr $ppqn/4]
    if {![winfo exists $can]} {return "0 $lastpulse"}
    set co [$can coords mark]
    #   is there a marked region of reasonable extent ?
    set extent [expr [lindex $co 2] - [lindex $co 0]]
    if {$extent > 10} {
        set xvleft [lindex $co 0]
        set xvright [lindex $co 2]
        if {$xvleft < 0} {set xvleft 0}
    } else {
        #get start and end time of displayed area
        set xv [$can xview]
        set scrollregion [$can cget -scrollregion]
        set xvleft [lindex $xv 0]
        set xvright [lindex $xv 1]
        set width [lindex $scrollregion 2]
        set xvleft [expr $xvleft*$width]
        set xvright [expr $xvright*$width]
    }
    
    if {$can == ".piano.can"} {
      set begin [expr round($xvleft*$pianoxscale)]
      set end [expr round($xvright*$pianoxscale)]
      } elseif {$can == ".ptableau.frm.can"} {
      set begin [expr round($xvleft * $ppqn4)]
      set end   [expr round($xvright* $ppqn4)]
      } elseif {$can == ".midistructure.can"} {
      set structxscale [expr $ppqn/double($pixels_per_beat)]
      set begin [expr round($xvleft * $structxscale)]
      set end [expr round($xvright * $structxscale)]
      #puts "midi_limits returns $begin $end for midistructure"
     } elseif {$can == ".drumroll.can"} {
      set begin [expr round($xvleft*$drumxscale)]
      set end [expr round($xvright*$drumxscale)]
      #puts "drumxscale = $drumxscale"
      }

    if {$begin < 0} {
        set $begin 0
    }
    return [list $begin $end]
}


proc count_selected_midi_tracks {} {
    set tsel 0
    global trksel
    for {set i 0} {$i <32} {incr i} {
        if {$trksel($i)} {
            incr tsel
        }
    }
    return $tsel
}



proc midi_to_midi {sel} {
    # creates midi.tmp containing an extract from the open midi file.
    # If sel = 0, midi_to_midi was called by right clicking on the
    # piano canvas and the highlighted_trk is used to control
    # what is played. If sel = 1, then midi_to_midi was called
    # from other functions and it is controlled by the tsel array.
    #
    # Everything in the displayed time interval is copied if tsel
    # is empty or no highlight_track was set.
    
    global highlighted_trk
    global  midi
    global exec_out
    global trkchan
    global trksel
    global midi
    global midipulse_limits
    global midispeed
    global ppqn
    
    # We first delete the old file in case winamp is still playing it.
    set cmd "file delete -force -- $midi(outfilename)"
    catch {eval $cmd} done
    set midi(outfilename) [tmpname]

    set midipulse_limits [midi_limits .piano.can]
    set begin [lindex $midipulse_limits 0]
    set end   [lindex $midipulse_limits 1]
    #quantize to beat unit
    set begin [expr $ppqn*($begin/$ppqn)]
    
    #puts "sel = $sel"
    set tsel 0
    set trkstr ""
    if {$sel} {
        #always include track 1 because it contains the tempo and other stuff
        for {set i 0} {$i <32} {incr i} {
            if {$trksel($i)} {
                if {$tsel > 0} {
                    set trkstr $trkstr,$i
                    } else {
                    set trkstr $i
                    }
                incr tsel
            }
        }
    } else {
        if {[info exist highlighted_trk] == 0} {set highlighted_trk 0}
        if {$highlighted_trk != 0} { set trkstr $highlighted_trk}
        } 

   set selvoice ""
   if {[string length $trkstr] > 0} {
     #puts "trkstr = $trkstr"
     if {$midi(midishow_sep) == "track"} {
        set selvoice "-trks 1,$trkstr"
       } else {
        set selvoice "-chns $trkstr"
       }
    }

   #puts "selvoice = $selvoice"

    # We first delete the old file in case winamp is still playing it.
    set cmd "file delete -force -- $midi(outfilename)"
    catch {eval $cmd} pianoresult
        
    # create temporary midi file
    set cmd "exec [list $midi(path_midicopy)]  $selvoice  -from $begin\
                -to $end" 
    if {$midispeed != 1.00} {lappend cmd " -speed $midispeed"}
    lappend cmd  $midi(midifilein) $midi(outfilename)

    #puts "cmd = $cmd"
    
    catch {eval $cmd} miditime
    #    puts $miditime
    set exec_out midi_to_midi:\n$cmd\n\n$miditime
    update_console_page
    return $miditime
}

proc midistructure_play {} {
global midi
switch $midi(playmethod) {
	1 {focus_and_play}
	2 {play_selected_lines midistructure}
	3 {play_and_exclude_selected_lines}
        }
}

proc focus_and_play {} {
global trksel
global midi
global miditracks
global midichannels
global lasttrack
global midispeed
global exec_out
set exec_out "focus_and_play:\n"
set trkchn ""
set option ""
if {$midi(midishow_sep) == "track"} {
  for {set i 0} {$i <= $lasttrack} {incr i} {
     if {$miditracks($i)} {append trkchn "$i,"}
     }
  if {[string length $trkchn] > 0} {
         set option "-attenuation $midi(attenuation) -focusontracks $trkchn"
         set option [string range $option 0 end-1]
         }
  } else {
  for {set i 0} {$i < 17} {incr i} {
     if {$midichannels($i)} {append trkchn "$i,"}
     }
  if {[string length $trkchn] > 0} {
         set option "-attenuation $midi(attenuation) -focusonchannels $trkchn"}
         set option [string range $option 0 end-1]
  }
set limits [midistruct_limits .midistructure.can]
  if {$limits != "none"} {
         set fbeat [lindex $limits 0]
         set tbeat [lindex $limits 1]
         append option " -frombeat $fbeat -tobeat $tbeat"
    }

if {$midispeed != 1.00} {append option " -speed $midispeed"}
# We first delete the old temporary midi file
# in case windows is still playing it.
set cmd "file delete -force -- $midi(outfilename)"
catch {eval $cmd} done
append exec_out "$cmd\n $done\n"
set midi(outfilename) [tmpname]
# create temporary file
if {[string length $option] > 0} {
  set cmd "exec [list $midi(path_midicopy)]  $option"
  lappend cmd  $midi(midifilein) $midi(outfilename)
  catch {eval $cmd} miditime
  set exec_out focus_and_play:\n$cmd\n\n$miditime
  } else {
  set cmd "file copy $midi(midifilein) $midi(outfilename)"
  file copy $midi(midifilein) $midi(outfilename)
  append exec_out "\n$cmd\n"
  }
play_midi_file $midi(outfilename)
append exec_out "play_midi_file $midi(outfilename)"
update_console_page
}


proc play_selected_lines {source} {
global midi
global exec_out
set exec_out "play_selected_lines $source\n"
copyMidiToTmp $source
append exec_out "\nplay_midi_file $midi(outfilename)"
play_midi_file $midi(outfilename)
update_console_page
}


proc copyMidiToTmp {source} {
global midi
global miditracks
global midichannels
global lasttrack
global midispeed
global fbeat
global tbeat
global exec_out
set limits [getCanvasLimits $source]
#puts "copyMidiToTmp $source: limits = $limits"
set fbeat [lindex $limits 0]
set tbeat  [lindex $limits 1]
set trkchn ""
set option ""
if {$midi(midishow_sep) == "track"} {
  for {set i 0} {$i <= $lasttrack} {incr i} {
     if {$miditracks($i)} {append trkchn "$i,"}
     }
  if {[string length $trkchn] > 0} {
         set option "-trks $trkchn"
         set option [string range $option 0 end-1]
         }
  } else {
  for {set i 1} {$i < 17} {incr i} {
     if {$midichannels($i)} {append trkchn "$i,"}
     }
  if {[string length $trkchn] > 0} {
         set option "-chns $trkchn"}
         set option [string range $option 0 end-1]
  }
if {$midispeed != 1.00} {append option " -speed $midispeed"}
if {$limits != "none"} {
	append option " -frombeat $fbeat -tobeat $tbeat "
        }
# We first delete the old temporary midi file
# in case windows is still playing it.
set cmd "file delete -force -- $midi(outfilename)"
catch {eval $cmd} done
set midi(outfilename) tmp.mid
# create temporary file
#puts "play_selected_lines option = $option"
if {[string length $option] > 0} {
  set cmd "exec [list $midi(path_midicopy)]  $option"
  lappend cmd  $midi(midifilein) $midi(outfilename)
  catch {eval $cmd} miditime
  append exec_out "copyMidiToTmp from $source\n$cmd\n\n$miditime"
  } else {
  set cmd "file copy $midi(midifilein) $midi(outfilename)"
  file copy $midi(midifilein) $midi(outfilename)
  append exec_out "copyMidiToTmp:\n$cmd\n"
  }
  update_console_page
}


proc play_and_exclude_selected_lines {} {
global trksel
global midi
global miditracks
global midichannels
global lasttrack
global midispeed
global exec_out
set trkchn ""
set option ""
set exec_out "play_and_exclude_selected_lines\n"
if {$midi(midishow_sep) == "track"} {
  for {set i 0} {$i <= $lasttrack} {incr i} {
     if {$miditracks($i)} {append trkchn "$i,"}
     }
  if {[string length $trkchn] > 0} {
         set option "-xtrks $trkchn"
         set option [string range $option 0 end-1]
         }
  } else {
  for {set i 1} {$i < 17} {incr i} {
     if {$midichannels($i)} {append trkchn "$i,"}
     }
  if {[string length $trkchn] > 0} {
         set option "-xchns $trkchn"}
         set option [string range $option 0 end-1]
  }
if {$midispeed != 1.00} {append option " -speed $midispeed"}
# We first delete the old temporary midi file
# in case windows is still playing it.
set cmd "file delete -force -- $midi(outfilename)"
catch {eval $cmd} done
#set midi(outfilename) [tmpname]
set midi(outfilename) tmp.mid
# create temporary file
if {[string length $option] > 0} {
  set cmd "exec [list $midi(path_midicopy)]  $option"
  lappend cmd  $midi(midifilein) $midi(outfilename)
  catch {eval $cmd} miditime
  append exec_out "\n$cmd\n\n$miditime"
  } else {
  set cmd "file copy $midi(midifilein) $midi(outfilename)"
  file copy $midi(midifilein) $midi(outfilename)
  append exec_out "\n$cmd\n"
  }
append exec_out "\nplay_midi_file $midi(outfilename)"
play_midi_file $midi(outfilename)
update_console_page
}

proc midi_to_midi_from_structure {begin end trkchn focus} {
    # creates midi.tmp containing an extract from the open midi file.
    # The function is called when one of the segments in the
    # structure window is picked.
    
    global  midi
    global exec_out
    global trkchan
    global midi
    global midispeed
    global ppqn
    
    set begin [expr int($begin * $ppqn)]
    set end   [expr int($end   * $ppqn)]
    

   if {$midi(midishow_sep) == "track"} {
        if {$focus} {
          set selvoice "-attenuation $midi(attenuation) -focusontracks $trkchn"
          } else {
          set selvoice "-trks 1,$trkchn"
          }
       } else {
         if {$focus} {
          set selvoice "-attenuation $midi(attenuation) -focusonchannels $trkchn"
          } else {
          set selvoice "-chns $trkchn"
          }
       }

   if {[string length $trkchn] < 1} {
        set selvoice ""}

    # We first delete the old temporary midi file
    # in case winamp is still playing it.
    set cmd "file delete -force -- $midi(outfilename)"
    catch {eval $cmd} done
    set midi(outfilename) [tmpname]
        
    # create temporary file
    set cmd "exec [list $midi(path_midicopy)]  $selvoice  -from $begin\
                -to $end" 
    lappend cmd  $midi(midifilein) $midi(outfilename)

    #puts "cmd = $cmd"
    
    catch {eval $cmd} miditime
    #    puts $miditime
    set exec_out midi_to_midi_from_structure:\n$cmd\n\n$miditime
    update_console_page
    return $miditime
}

proc save_temporary_midi_file {} {
global midi
set miditype {{{midi files} {*.mid *.MID *.midi *.kar *.KAR}}}
set filename [tk_getSaveFile -filetypes $miditype]
file rename -force $midi(outfilename) $filename
}


proc startup_playmark_motion {miditime} {
    global midipulse_limits
    global playtime
    global pianoplayend
    global advance_per_50ms
    global midi
    if {!$midi(midishow_follow)} return
    if {[string length $miditime] ==  0 } return
    if {![string is double $miditime]} return
    if {$miditime < 0.01} return
    set begin [lindex $midipulse_limits 0]
    set end   [lindex $midipulse_limits 1]
    set rate [expr ($end - $begin)/$miditime]
    set advance_per_50ms [expr $rate/20.0]
    #puts "startup_playmark_motion $advance_per_50ms"
    set playtime $begin
    set pianoplayend $end
    #puts "playtime $playtime playend $pianoplayend"
    .piano.can create line -1 -1 -1 -1 -fill red -tags playmark
    
    bind .piano.can  <KeyPress> stop_playmarker
    move_playmark
}



proc move_playmark {} {
    global advance_per_50ms
    global playtime
    global pianoxscale
    global pianoplayend
    set ix [expr int($playtime/$pianoxscale)]
    .piano.can coords playmark $ix 0 $ix 720
    #puts "$playtime $ix"
    set playtime [expr $playtime + $advance_per_50ms]
    if {$playtime > $pianoplayend} {
        .piano.can coords playmark -1 -1 -1 -1
        after 0
        return
    }
    after 50 move_playmark
}

proc stop_playmarker {} {
    global pianoplayend
    global playtime
    set pianoplayend $playtime
}



proc piano_play_midi_extract {} {
    global midi
    play_midi_file  [file join [pwd] $midi(outfilename)]
}

proc piano_display_midi_extract {} {
    global midi
    piano_abc_file
}

proc create_midi_file {} {
    midi
    midi_to_midi 1
    set filename [tk_getSaveFile]
    if {[string length $filename] > 1} {
        file rename -force $midi(outfilename) $filename
    }
}

proc mftext_local_analysis {} {
    global midi
    set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -mftext"
    mftextwindow $midi(outfilename) 1
}

proc mftext_tmp_midi {} {
    global midi
    midi_to_midi 1
    set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -mftext"
    mftextwindow $midi(outfilename) 1
}

proc mftext_tmp {} {
# for testing. use <Control-T>
    global midi
    set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -mftext"
    output_mftext $midi(outfilename) 
}


#end of source pianoroll.tcl



#   Part 10.0 Drum Roll Window
#source drumgram.tcl


set drumpatches {
    {35	{Acoustic Bass Drum} DodgerBlue1}
    {36	{Bass Drum 1} SteelBlue1}
    {37	{Side Stick} DeepPink2}
    {38	{Acoustic Snare} tomato1}
    {39 {Hand Clap} HotPink1}
    {40	{Electric Snare} red1}
    {41	{Low Floor Tom} DodgerBlue2}
    {42	{Closed Hi Hat} SeaGreen1}
    {43	{High Floor Tom} SteelBlue2}
    {44	{Pedal Hi-Hat} SeaGreen2}
    {45	{Low Tom} DeepSkyBlue1}
    {46	{Open Hi-Hat} SpringGreen1}
    {47	{Low-Mid Tom} DeepSkyBlue2}
    {48	{Hi Mid Tom} DeepSkyBlue2}
    {49	{Crash Cymbal 1} Green1}
    {50	{High Tom} SkyBlue1}
    {51	{Ride Cymbal 1} PaleGreen1}
    {52	{Chinese Cymbal} Green2}
    {53	{Ride Bell} DarkOliveGreen1}
    {54	Tambourine LightGoldenrod1}
    {55	{Splash Cymbal} Green2}
    {56	Cowbell burlywood1}
    {57	{Crash Cymbal 2} Green2}
    {58	Vibraslap seashell1}
    {59	{Ride Cymbal 2} PaleGreen2}
    {60	{Hi Bongo} IndianRed1}
    {61	{Low Bongo} IndianRed2}
    {62	{Mute Hi Conga} sienna1}
    {63	{Open Hi Conga} sienna2}
    {64 {Low Conga} salmon1}
    {65 {High Timbale} magenta1}
    {66	{Low Timbale} magenta2}
    {67	{High Agogo} plum1}
    {68	{Low Agogo} plum2}
    {69	Cabasa maroon2}
    {70	Maracas orchid1}
    {71	{Short Whistle} purple1}
    {72	{Long Whistle} purple2}
    {73	{Short Guiro} purple3}
    {74	{Long Guiro} DarkOliveGreen1}
    {75	{Claves} cyan1}
    {76	{Hi Wood Block} cyan2}
    {77	{Low Wood Block} cyan3}
    {78	{Mute Cuica} chartreuse1}
    {79	{Open Cuica} chartreuse2}
    {80	{Mute Triangle} OliveDrab1}
    {81	{Open Triangle} OliveDrab2}
}



proc drum_selector {} {
global drumpatches
#global progmapper
#global groupcolors
global df
set w .drumsel
if {[winfo exist $w]} {
  raise $w .
  return}
toplevel $w 
positionWindow $w
button .drumsel.47 -command clear_drum_select -font $df -text "clear all"
for {set i 0} {$i < 47} {incr i} {
 set elem [lindex $drumpatches $i]
 set lab "[lindex $elem 0] [lindex $elem 1]"
 checkbutton $w.$i -text $lab -variable drumselect($i) -command update_drumlist -font $df -width 24 -anchor w -borderwidth 0 
 }
for {set i 0} {$i < 12} {incr i} {
  set i2 [expr $i + 12]
  set i3 [expr $i + 24]
  set i4 [expr $i + 36]
  grid $w.$i $w.$i2 $w.$i3 $w.$i4 -sticky w
  } 
update_drumselect
}

proc clear_drum_select {} {
global drumselect
global midi
for {set i 0} {$i < 47} {incr i} {set drumselect($i) 0}
set midi(drumlist) {}
}


proc update_drumselect {} {
global midi
global drumselect
for {set i 0} {$i < 47} {incr i} {set drumselect($i) 0}
foreach p $midi(drumlist) {
  set drumselect([expr $p -35]) 1
  }
}

proc update_drumlist {} {
global midi
global drumselect
set p ""
for {set i 0} {$i < 47} {incr i} {
  if {$drumselect($i)} {lappend p [expr $i +35]}
  }
set midi(drumlist) $p
}

proc active_drums {} {
    global pianoresult
    global drumstrip rdrumstrip
    global gram_ndrums
    global activedrum avgvel
   
    array unset activedrum
    for {set i 35} {$i <82} {incr i} {
      set activedrum($i) 0
      set avgvel($i) 0
      }
    
    foreach line $pianoresult  {
        if {[llength $line] != 6} continue
        set c [lindex $line 3]
        if {$c != 10} continue
        set note [lindex $line 4]
        set vel [lindex $line 5]
        incr activedrum($note) 
        incr avgvel($note) $vel
    }

    set gram_ndrums 0
    for {set i 35} {$i <82} {incr i} {
      if {$activedrum($i) != 0} {
         set j [expr $i -35]
         set drumstrip($i) $gram_ndrums
         set rdrumstrip($gram_ndrums) $i
         set avgvel($i) [expr $avgvel($i)/$activedrum($i)]
         incr gram_ndrums
         }
      }
}



proc drumroll_Button1Press {x y} {
    set xc [.drumroll.can canvasx $x]
    .drumroll.can raise mark
    .drumroll.can coords mark $xc -10 $xc 600
    bind .drumroll.can <Motion> { drumroll_Button1Motion %x }
}

proc drumroll_Button1Motion {x} {
    set xc [.drumroll.can canvasx $x]
    if {$xc < 0} { set xc 0 }
    set co [.drumroll.can coords mark]
    .drumroll.can coords mark [lindex $co 0] -10 $xc 600
}

proc drumroll_Button1Release {} {
    bind .drumroll.can <Motion> {}
    set co [.drumroll.can coords mark]
    update_drumroll_pdfs
}

proc drumroll_ClearMark {} {
    .drumroll.can coords mark -1 -1 -1 -1
}


set drumrollwidth 400


proc drumroll_window {} {
    global df
    global midispeed
    global drumrollwidth

    if {[winfo exist .drumroll]} return
    set midispeed 1.0
    toplevel .drumroll
    positionWindow ".drumroll"
    #Create top level menu bar.
    set p .drumroll.f
    frame $p

    button $p.invert -text invert -width 6 -relief flat\
         -command invert_drumpick -font $df
    tooltip::tooltip $p.invert "Invert drum selections"
    button $p.config -text config -width 8 -relief flat\
	 -command drumroll_config -font $df
    tooltip::tooltip $p.config "Configure how drumroll\n is played"
    button $p.play -text play -relief flat -font $df -command play_drumroll
    tooltip::tooltip $p.play "Play all drum lines\n in exposed area"
    button $p.zoom -text zoom -relief flat -command drumroll_zoom -font $df
    menubutton $p.unzoom -text unzoom -width 8 -menu $p.unzoom.items -font $df
    menu $p.unzoom.items -tearoff 0
    $p.unzoom.items add command -label "Unzoom 1.5" -font $df \
            -command {drumroll_unzoom 1.5}
    $p.unzoom.items add command -label "Unzoom 3.0" -font $df \
            -command {drumroll_unzoom 3.0}
    $p.unzoom.items add command -label "Unzoom 5.0" -font $df \
            -command {drumroll_unzoom 5.0}
    $p.unzoom.items add command -label "Total unzoom" -command drumroll_total_unzoom -font $df

    button $p.analysis -text analysis -relief flat -font $df\
            -command {analyze_drum_patterns 0}
    tooltip::tooltip $p.analysis "Detailed analysis of drum patterns"

    menubutton $p.plots -text plots -width 8 -menu $p.plots.items -font $df
    menu $p.plots.items -tearoff 0
    tooltip::tooltip $p.plots "Various plots"
    $p.plots.items add command -label "onset distribution" -font $df \
            -command {drumroll_statistics onset
                      plotmidi_onset_pdf
                     }
    $p.plots.items add command -label "velocity distribution" -font $df \
            -command {drumroll_statistics velocity
                      plotmidi_velocity_pdf
                     }
    
    button $p.help -text help -relief flat -font $df\
            -command {show_message_page $hlp_drumroll word}
    
    grid  $p.invert $p.play $p.config $p.zoom $p.unzoom $p.analysis $p.plots $p.help -sticky news
    grid $p -column 1
    
    set p .drumroll.file
    frame $p -relief ridge -borderwidth 2
    label $p.fileinlab -text  "input midi file" -font $df
    button $p.fileinbr -text "browse" -relief flat -font $df\
            -command {set midi(midifilein) midi_file_browser
                show_drum_events}
    entry $p.fileinent -width 48 -textvariable midi(midifilein) -font $df
    $p.fileinent xview moveto 1.0
    bind $p.fileinent <Return> {focus .drumroll.file.roll
        show_drum_events}
    grid $p.fileinlab $p.fileinent $p.fileinbr 
    grid $p -column 0 -columnspan 3
    
    
    set p .drumroll
    
    # create frame for displaying canvas of drum roll.
    
    scrollbar $p.hscroll -orient horiz -command [list BindXview [list $p.can\
            $p.canx]]
    
    canvas $p.can -width $drumrollwidth -height 200 -border 3 -relief sunken -scrollregion\
            {0 0 2500 500} -xscrollcommand "$p.hscroll set" -border 3 -bg white
    canvas $p.canx -width $drumrollwidth -height 20 -border 3 -relief sunken -scrollregion\
            {0 0 2500 20}
    canvas $p.cany -width 180 -height 200 -border 3 -relief sunken -scrollregion\
            {0 0 20 200}
    label $p.speedlabel -text speed -font $df
    scale $p.speed -length 140 -from 0.1 -to 4.0 -orient horizontal\
 -resolution 0.05 -width 10 -variable midispeed -font $df
    grid $p.cany $p.can -sticky news
    grid $p.speedlabel $p.canx -sticky news
    label $p.txt -text drumgram -font $df
    grid $p.speed $p.hscroll -sticky ew
    grid $p.txt -column 1
    grid rowconfig $p 2 -weight 1 -minsize 0
    grid columnconfig $p 1 -weight 1 -minsize 0
    
    
    
    bind $p.can <ButtonPress-1> {drumroll_Button1Press %x %y}
    bind $p.can <ButtonRelease-1> {drumroll_Button1Release}
    bind $p.can <Double-Button-1> drumroll_ClearMark
    bind $p.can <Configure> {drumroll_resize}
  set result [check_midi2abc_midistats_and_midicopy_versions]
  if {[string equal $result pass]} {show_drum_events} else {
      .drumroll.txt configure -text $result -foreground red -font $df
      }
}

proc drumroll_config {} {
    set p .drumrollconfig
    global df midi
    if {[winfo exist $p]} return
    toplevel $p
    positionWindow $p
    radiobutton $p.normal -text "play everything" -variable midi(playdrumdata) -value normaldrum -font $df 
    radiobutton $p.nodrum -text "do not play the percussion lines" -variable midi(playdrumdata) -font $df -value nodrums
    radiobutton $p.onlydrum -text "play only the percussion lines" -variable midi(playdrumdata) -font $df -value onlydrums
#    radiobutton $p.focussel -text "boost selection" -variable midi(playdrumdata) -font $df -value boostdrumsel
#    checkbutton $p.mute -text "mute nondrum channels"\
# -variable midi(mutenodrum) -font $df
#    checkbutton $p.drumboost -text "set selected drum loudness"\
# -variable midi(drumvelocity) -font $df
    pack $p.normal $p.nodrum $p.onlydrum -side top -anchor w
}

set hlp_drumroll_config "Drum Roll Configuration\n\n\
The options control how the drum midi events are played.\
If the 'mute nondrum channels' is checked the regular midi\
events that are not in channel 9 are reduced in loudness to the\
level specified by in the 'mute no drum level' entry box.\
The level must be in the range of 0 and 127.\n\n\
The mute focus level refers to the playback of individual drum\
lines. It controls the maximum loudness of the nonselected drums.\
Its value must also be in the range of 0 and 127.\n\n\
The checkbox 'set selected drum loudness' also applies to\
the playback of the individual drum line. In some cases,\
even though the focus is on the individual drum line, its\
loudness may be set low in the original MIDI file.\
If the checkbox is set, then the original loudness is overriden\
and set to the specified value in the entry box 'selected\
drum loudness.
"

proc show_drum_events {} {
    global drumPixelsPerFile
    global midi
    global pianoresult
    global df
    global exec_out
    global drumrollwidth

 if {[file exist $midi(midifilein)] == 0} {
        .drumroll.txt configure -text "can't open file $midi(midifilein)"\
                -foreground red -font $df
        return
    }
    .drumroll.txt configure -text drumgram -font $df -foreground black

    set drumPixelsPerFile $drumrollwidth
    readMidiFileHeader $midi(midifilein); # read midi header

    set exec_options "[list $midi(midifilein)] -midigram"

    set cmd "exec [list $midi(path_midi2abc)] $exec_options"
    catch {eval $cmd} pianoresult
    if {[string first "no such" $pianoresult] >= 0} {abcmidi_no_such_error $midi(path_midi2abc)}
    set exec_out $cmd\n\n$pianoresult
    set pianoresult [split $pianoresult "\n"]
    set nrec [llength $pianoresult]
    set midilength [lindex $pianoresult [expr $nrec -1]]
    if {[string is integer $midilength] != 1} {
        .drumroll.txt configure -text "$midilength ??"
        return
    }
    compute_drumroll 
    if {[winfo exist .drumanalysis]} {analyze_drum_patterns 0}
}


proc drumroll_qnotelines {} {
    global ppqn
    global midilength
    global drumxscale
    global piano_vert_lines
    global piano_qnote_offset
    global vspace
    global df
    set p .drumroll
    $p.canx delete all
    set bounding_box [$p.can bbox all]
    set top [lindex $bounding_box 1]
    set bot [lindex $bounding_box 3]
    $p.can delete -tag  barline
    if {$piano_vert_lines > 0} {
        set vspace [expr $ppqn*$piano_vert_lines]
        set txspace $vspace
        while {[expr $txspace/$drumxscale] < 40} {
            set txspace [expr $txspace + $vspace]
        }
        
        
        for {set i $piano_qnote_offset} {$i < $midilength} {incr i $vspace} {
            set ix1 [expr $i/$drumxscale]
            if {$ix1 < 0} continue
            $p.can create line $ix1 $top $ix1 $bot -width 1 -tag barline -dash {1 2} -fill yellow
        }
        
        for {set i $piano_qnote_offset} {$i < $midilength} {incr i $txspace} {
            set ix1 [expr $i/$drumxscale]
            if {$ix1 < 0} continue
            $p.canx create text $ix1 11 -font $df -text [expr $piano_vert_lines*int($i/$vspace)]
        }
    }
}


proc compute_drumroll {} {
    global midi
    global midilength
    global drumPixelsPerFile
    global pianoresult
    global drumxscale
    #global activechan
    global ppqn
    global piano_vert_lines
    global drumstrip rdrumstrip
    global drumpatches    
    global gram_ndrums
    global df
    global activedrum avgvel
    global drumpick
    
    if {[llength $pianoresult] < 1} {
        return
    }
    
    
    set nrec [llength $pianoresult]
    set midilength [lindex $pianoresult [expr $nrec -1]]
    set sep 10

    
    set p .drumroll
    set drumxscale [expr ($midilength / double($drumPixelsPerFile))]
    
    set qnspacing  [expr $drumPixelsPerFile*$ppqn/double($midilength)]
    set piano_vert_lines [expr 40.0/$qnspacing]
    set piano_vert_lines [adjust_vert_spacing $piano_vert_lines]
    if {$piano_vert_lines <1} {set piano_vert_lines 1}
    
    $p.can delete all
    $p.cany delete all
    
    $p.can create rect -1 -1 -1 -1 -tags mark -fill yellow -stipple gray25
    
    if [info exist activechan] {
        unset activechan
    }

    active_drums

   if {$gram_ndrums < 1} {.drumroll.txt configure -text "no drum notes" \
                -foreground red -font $df}
    for {set i 0} {$i <$gram_ndrums} {incr i} {
            $p.can create line 0 [expr $i*20 +20] $drumPixelsPerFile\
                        [expr $i*20+20] -dash {1 1}
            set jj $rdrumstrip($i)
            set j [expr $jj - 35]
            set patch [lindex [lindex $drumpatches $j] 1]
            set legend [format "%s" $patch]
            set legend "$rdrumstrip($i) $legend"
	    if {[winfo exist $p.cany.drm$i] != 1} {
              set drumpick($i) 0
	      checkbutton $p.cany.drm$i -text $legend -variable drumpick($i)\
	         -command update_drumroll_pdfs -font $df
              tooltip::tooltip $p.cany.drm$i  "$activedrum($jj) strikes\nvelocity = $avgvel($jj)"
               } else {
             $p.cany.drm$i configure -text $legend 
             $p.cany.drm$i deselect 
             }
	     set item [$p.cany create window 10 [expr $i*20 + 0] -anchor nw -window $p.cany.drm$i]
        }
    set canheight [expr $gram_ndrums*20 + 10]
    $p.can configure -height $canheight -background grey28
    $p.cany configure -height $canheight
    
    drumroll_qnotelines
    
    foreach line $pianoresult {
        if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        if {[string is double $begin] != 1} continue
        set end [lindex $line 1]
        set t [lindex $line 2]
        set c [lindex $line 3]
        if {$c != 10} continue
        set note [lindex $line 4]
        set velocity [lindex $line 5]
        if {[lindex $line 5] < 1} continue
        if {$note < 35 || $note > 81 || $velocity < 32} continue
        if {$velocity < 64} {set velocity 64}
        set ix1 [expr $begin/$drumxscale]
        set ix2 [expr $ix1+3]
        if {$ix2 > $drumPixelsPerFile} {
           #puts "$begin $note $ix1 $ix2"
           continue
           }
        set width [expr 4 + ($velocity-64)/6]
        set iy [expr $drumstrip($note)*20 + 10]
        set percindex [expr $note - 35]
        set kolor [lindex [lindex $drumpatches $percindex] 2]
        $p.can create line $ix1 $iy $ix2 $iy -width $width -tag trk$sep -fill $kolor
        set activechan($sep) 1
    }
    #bind_tracks


    set bounding_box [$p.can bbox all]
    set top [lindex $bounding_box 1]
    set bot [lindex $bounding_box 3]
    
    
    
    
    set bounding_boxx [list [lindex $bounding_box 0] 0 [lindex $bounding_box\
            2] 20]
    set bounding_boxy [list 0 [lindex $bounding_box 1] 20\
            [lindex $bounding_box 3]]
    $p.can configure -scrollregion $bounding_box
    $p.canx configure -scrollregion $bounding_boxx
    $p.cany configure -scrollregion $bounding_boxy
}

proc invert_drumpick {} {
global drumpick
global gram_ndrums
for {set i 0} {$i < $gram_ndrums} {incr i} {
  set drumpick($i) [expr 1 - $drumpick($i)]
  }
}


proc make_in_and_ex_lists {} {
    global gram_ndrums
    global drumpick
    global drumstrip rdrumstrip
    set includelist {}
    set excludelist {}
    for {set i 0} {$i <$gram_ndrums} {incr i} {
      set perc $rdrumstrip($i)
      if {$drumpick($i) == 0} {
	      lappend excludelist $perc
      } else {
	      lappend includelist $perc
      }
    }

    if {[llength $includelist] == 0} {
      # switch includelist with excludelist
      return "" 
      }

    if {[llength $includelist] < [llength $excludelist]} {
       set output " -indrums "
       foreach i $includelist {
         append output "$i,"
         }
       append output " "
       return $output
       } else {
       set output " -xdrums "
       foreach i $excludelist {
         append output "$i,"
         }
       append output " "
       return $output
       }
}

proc plot_for_ps_drumroll {} {
# not completed
set box [.drumroll.can bbox all]
set w [expr [lindex $box 2] - [lindex $box 0]]
set h [expr [lindex $box 3] - [lindex $box 1]]
puts "$w $h"
set midipulse_limits [midi_limits .drumroll.can]
set begin [lindex $midipulse_limits 0]
set end   [lindex $midipulse_limits 1]
puts "$begin $end"
}


proc drumroll_horizontal_scroll {val} {
    .drumroll.can xview moveto $val
    .drumroll.canx xview moveto $val
}



#horizontal zoom of piano roll
proc drumroll_zoom {} {
    global drumPixelsPerFile
    set co [.drumroll.can coords mark]
    set zoomregion [expr [lindex $co 2] - [lindex $co 0]]
    set displayregion [winfo width .drumroll.can]
    set scrollregion [.drumroll.can cget -scrollregion]
    if {$zoomregion > 5} {
        set mag [expr $displayregion/$zoomregion]
        set drumPixelsPerFile [expr $drumPixelsPerFile*$mag]
        compute_drumroll
        set xv [expr double([lindex $co 0])/double([lindex $scrollregion 2])]
        drumroll_horizontal_scroll $xv
    } else {
        set drumPixelsPerFile [expr $drumPixelsPerFile*1.5]
        if {$drumPixelsPerFile > 250000} {
            set $drumPixelsPerFile 250000}
        set xv [lindex [.drumroll.can xview] 0]
        compute_drumroll
        drumroll_horizontal_scroll $xv
        update_drumroll_pdfs
    }
}


proc drumroll_unzoom {factor} {
    global drumPixelsPerFile
    set displayregion [winfo width .drumroll.can]
    set PixelsPerFile [expr $displayregion -8]
    set drumPixelsPerFile [expr $drumPixelsPerFile /$factor]
    if {$drumPixelsPerFile < $PixelsPerFile} {
       set factor [expr $PixelsPerFile/$drumPixelsPerFile]
       set drumPixelsPerFile $PixelsPerFile
    }
    set xv [.drumroll.can xview]
    set xvl [lindex $xv 0]
    set xvr [lindex $xv 1]
    set growth [expr ($factor - 1.0)*($xvr - $xvl)]
    set xvl [expr $xvl - $growth/2.0]
    if {$xvl < 0.0} {set xv 0.0}
    compute_drumroll
    drumroll_horizontal_scroll $xvl
    update_drumroll_pdfs
}

proc drumroll_total_unzoom {} {
    global drumPixelsPerFile
    set displayregion [winfo width .drumroll.can]
    #puts "displayregion $displayregion"
    set drumPixelsPerFile [expr $displayregion -20]
    compute_drumroll
    update_drumroll_pdfs
    .drumroll.can configure -scrollregion [.drumroll.can bbox all]
}

proc drumroll_zoom_to {beginbeat endbeat} {
    global lastbeat
    global drumPixelsPerFile
    global drumrollwidth
    puts "drumroll_zoom_to $beginbeat"
    set fraction [expr ($endbeat - $beginbeat)/$lastbeat]
    if {$fraction < 0.05} {set fraction 0.05}
    set drumPixelsPerFile [expr $drumrollwidth/$fraction]
    compute_drumroll
    set xvl [expr $beginbeat/$lastbeat]
    drumroll_horizontal_scroll $xvl
    }


proc drumroll_resize {} {
global drumPixelsPerFile
set displayregion [winfo width .drumroll.can]
if {$drumPixelsPerFile < $displayregion} {
   # shrink drumPixelsPerFile since the bbox of .drumroll.can tends
   # to grow on account of the thick lines.
   set drumPixelsPerFile [expr $displayregion -20]
   compute_drumroll
   .drumroll.can configure -scrollregion [.drumroll.can bbox all]
   }
}

proc play_drumroll {} {
global midi
set miditime [drum_to_midi]
piano_play_midi_extract
#startup_playmark_motion $miditime
}


proc drum_to_midi  {} {
    global  midi
    global exec_out
    global midi
    global midipulse_limits
    global midispeed
    global rdrumstrip
    global ppqn
    
    set midipulse_limits [midi_limits .drumroll.can]
    set begin [lindex $midipulse_limits 0]
    set end   [lindex $midipulse_limits 1]
    #quantize to beat unit
    set begin [expr $ppqn*($begin/$ppqn)]
    
    # We first delete the old file in case winamp is still playing it.
    set cmd "file delete -force -- $midi(outfilename)"
    catch {eval $cmd} pianoresult

    switch $midi(playdrumdata) {
      normaldrum {
      set percsubset [make_in_and_ex_lists]
      set cmd "exec [list $midi(path_midicopy)]  -from $begin\
 -to $end $percsubset" 
      }
      onlydrums {
      set percsubset [make_in_and_ex_lists]
      set cmd "exec [list $midi(path_midicopy)]  -from $begin\
 -to $end  -onlydrums $percsubset" 
      }
      nodrums {
      set cmd "exec [list $midi(path_midicopy)]  -from $begin\
 -to $end  -nodrums " 
      }
      onlysel {
      set cmd "exec [list $midi(path_midicopy)]  -from $begin\
 -to $end  $percsubset" 
      }
      boostdrumsel {
      set cmd "exec [list $midi(path_midicopy)]  -from $begin\
 -to $end -drumfocus $rdrumstrip($drmno) $midi(mutefocus)" 
      if {$midi(mutenodrum)} {append cmd " -mutenodrum $midi(mutelev) "}
      if {$midi(drumvelocity) && $drmno != -1} {append cmd " -setdrumloudness $rdrumstrip($drmno)  $midi(drumloudness) "}
      }
    }

    if {$midispeed != 1.00} {append cmd " -speed $midispeed "}
    append cmd  "[list $midi(midifilein)] $midi(outfilename)"
    
    catch {eval $cmd} miditime
    #    puts $miditime
    set exec_out midi_to_midi:\n$cmd\n\n$miditime
    #puts "drum_to_midi: $exec_out"
    update_console_page
    return $miditime
}




#percussion_map the MIDI percussion instruments into classes
# 1 Bass Drum
# 2 Snare
# 3 Stick, Clap
# 4 Hi Hat
# 5 Cymbal
# 6 Cowbell
# 7 Vibraslap
# 8 Conga
# 9 Ride Bell
# 10 Tom
# 11 Tambourine
# 12 Agogo 
# 13 Cabasa
# 14 Maracas
# 15 Whistle
# 16 Wood Block
# 17 Guiro
# 18 Cuica
# 19 Timbale

array set percussionmap   {
35 1  36 1  37 3  38 2  39 3 
40 2  41 10  42 4  43 10  44 4 
45 10  46 4  47 10  48 10  49 5 
50 10  51 4  52 5  53 13  54 11 
55 5  56 6  57 5  58 7  59 4 
60 8  61 8  62 8  63 8  64 8 
65 19  66 19  67 12  68 12  69 9 
70 14  71 15  72 15  73 17  74 17  
75 3  76 16  77 16  78 18  79 18  
80 4  81 4
}


proc get_drum_patterns {simple} {
   #global drumstrip 
   global percussionmap
   global ppqn
   global pianoresult
   global midilength
   global mlength
   set limits [midi_limits .drumroll.can]
   set start [lindex $limits 0]
   set stop  [lindex $limits 1]
#  set start and stop onto a beat boundary.
   set bstart [expr $start/$ppqn]
   set bstop [expr $stop/$ppqn]
#   puts "in beats $bstart $bstop"
   set start [expr $bstart*$ppqn]
   set stop [expr $bstop*$ppqn]
   set mlength [expr $stop - $start]

   set ppqn4 [expr $ppqn/4]
   #set ndrumfrag [expr 5 + $mlength/$ppqn4]
   set ndrumfrag [expr 5 + $midilength/$ppqn4]
   set drumpat [dict create]
   for {set i 0} {$i <$ndrumfrag} {incr i} {
     dict set drumpat $i 0
     }
   foreach line $pianoresult {
        if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        if {$begin < $start} continue
        if {$begin > $stop} continue
#        set loc [expr ($begin - $start) / $ppqn4]
        set loc [expr $begin / $ppqn4]
        if {[string is double $begin] != 1} continue
        set c [lindex $line 3]
        if {$c != 10} continue
        if {[lindex $line 5] < 1} continue
        set note [lindex $line 4]
        if {$note < 35 || $note > 81} continue
        if {$simple == 0} {
          set drumindex [expr $note -35]
          } else {
          set drumindex [expr $percussionmap($note) - 1]
          }
        set patfrag [dict get $drumpat $loc]
        set patfrag [expr $patfrag | 1<<$drumindex]
        dict set drumpat $loc $patfrag 
        #puts "drumpat $loc $patfrag $note $drumindex"
       }
   return $drumpat
}

proc extract_drumpat_for {drum drumpat} {
set power [expr $drum - 35]
set mask [expr 1 << $power]
set sdrumpat [dict creat]
set drumpatSize [dict size $drumpat]
for {set i 0} {$i < $drumpatSize} {incr i} {
  set pat [dict get $drumpat $i]
  if {[expr $pat & $mask] != 0} {
      dict set sdrumpat $i 1
     } else {
      dict set sdrumpat $i 0
     }
  }
return $sdrumpat
}


proc write_drumpat drumpat {
  puts "writing drumpat in dm.txt"
  set f [open dm.txt w]
  for {set i 500} {$i < 1000} {incr i} {
    puts $f "$i [dict get $drumpat $i]"
    }
  close $f
  }


proc bitcount intlist {
    array set bits {
       0 0  1 1  2 1  3 2  4 1  5 2  6 2  7 3
       8 1  9 2  a 2  b 3  c 2  d 3  e 3  f 4
    }
    set sum 0
    foreach int $intlist {
       foreach nybble [split [format %x $int] ""] {
          incr sum $bits($nybble)
       }
    }
    set sum
 }

proc bit_correlate {series lag} {
set size [dict size $series]
set n [expr $size -$lag -1]
set andlist {}
for {set i 0} {$i < $n} {incr i} {
  set j [expr $i + $lag]
  lappend andlist [expr [dict get $series $i] & [dict get $series $j]]
  }  
return [bitcount $andlist]
}

proc drum_irregularity {series lag graph} {
# computes the change of the drumpat as a function
# of beat number assuming drumpat of length lag is
# periodic. (It measures the number of bits different
# between series(i) and series(i+lag) and accumulates
# this difference over a beat.)
set curve {}
set size [dict size $series]
set n [expr $size -$lag -1]
set irreq [dict create]
set nbeats [expr $size/4]
for {set i 0} {$i <$nbeats} {incr i} {
     dict set irreg $i 0
     }

for {set i 0} {$i < $n} {incr i} {
  set j [expr $i + $lag]
  set irregularity [bitcount [expr [dict get $series $i] ^ [dict get $series $j]]]
  set beat [expr $i / 4]
  dict set irreg $beat [expr [dict get $irreg $beat] + $irregularity]
  }  

set total 0.0
for {set i 0} {$i < $nbeats} {incr i} {
  set irregularity [expr double ([dict get $irreg $i])]
  set p [list [expr double($i)] $irregularity]
  set total [expr $total + $irregularity]
  lappend curve $p
  }
plot_line_graph $graph $curve 0.0 $nbeats 100.0  "beat number"  0.0 20.0  "irregularity"
set total [format %6.3f [expr $total/double($nbeats)]]
.drumanalysis.blk.ctl.10a configure -text $total
}

proc maxindex list {
   set index 0
   set maxindex $index
   set maxval [lindex $list 0]
   foreach val $list {
      if {$val > $maxval} {
         set maxindex $index
         set maxval $val
      }
      incr index
   }
   return $maxindex
}

set hlp_drumanalysis "Percussion Analysis\n\n\
This interface is quite complex and you can find\
a longer description on\
https://midiexplorer.sourceforge.io/
The percussion channel is represented in a\
hierarchical structure. A bar is split into\
quarter note beats, a beat is split into four\
tatums. A tatum represents the state of all\
47 percussion instruments during a 1/16 note\
time interval. Each of the distinct states is\
assigned a numerical index number and fortunately\
the number of distinct states is manageable.\
The beat is represented by concatenating the\
4 tatum index numbers and fortunately, the\
number of distinct beats is also manageable and\
also indexed numerically. Measures or bars are\
formed in a similar manner.\n\n\
The interface indicates the number of distinct\
tatums, distinct beats and distinct bars that\
are present in the exposed portion of the\
drumroll representation. The amount of diversity\
of these units is given by their entropy on\
respective buttons. Clicking the entropy value\
buttons will display the histogram of these\
units in an adjoining graph. Note the vertical\
scale is logarithmic. By default the adjoining\
graph displays the autocorrelation function of\
in beat units of the percussion track. The\
autocorrelation function provides a lot of\
information and in particular the number of\
beats in a measure or bar.\n\n\
The drum irregularity indicates how well\
one can predict the next bar from the\
previous measure. Peaks in this graph represent\
transition times where the drum pattern suddenly\
changes.\n\n\
The map bottom produces a separate window showing\
the distribution of the distinct bars for each\
percussion instrument. The bars are labeled with\
an alphanumeric character starting with the numeric\
0 and identical bars have the same character. When\
a different bar is encountered, it is represented\
by a new character. Zero indicates the absence of\
the drum in that bar.\n\n\
The i/j/k numbers indicate the\
number of distict tatums, beats, and bars that\
were encountered for the specific percussion instrument.\
For individual percussion instruments, i is always 1;\
however when all percussion instruments are combined,\
i can be as large as 2 to the exponent n where n is\
the number of percussion instruments.
"


proc analyze_drum_patterns {simple} {
# only simple = 0 is supported in the user interface
global df
global ppqn
global midilength
global mlength
global fullbarseqstring
global fullDrumStats
set d .drumanalysis.blk.ctl
set graph .drumanalysis.blk.c
set t .drumanalysis.t
set drumpat [get_drum_patterns $simple] 

if {[winfo exists $d] == 0} {
  setup_i2l
  toplevel .drumanalysis
  positionWindow .drumanalysis
  frame .drumanalysis.blk
  pack .drumanalysis.blk -side top
  frame $d 
  canvas $graph -bd 2 -relief solid -background LavenderBlush1
  pack $d $graph -side left

  label $d.1 -text "number of beats" -font $df
  label $d.1a  -font $df
  label $d.2 -text "number of tatums" -font $df
  label $d.2a  -font $df
  label $d.3 -text "period" -font $df
  label $d.3a -font $df
  label $d.4 -text "distinct tatums" -font $df
  label $d.4a  -font $df
  label $d.5 -text "tatum entropy" -font $df
  button $d.5a -font $df
  tooltip::tooltip $d.5a "Show histogram of all distinct tatums"
  label $d.6 -text "distinct beats" -font $df
  label $d.6a -font $df
  label $d.7 -text "beat entropy" -font $df
  button $d.7a -font $df
  tooltip::tooltip $d.7a "Show histogram of all distinct beats"
  label $d.8 -text "distinct bars" -font $df
  label $d.8a -font $df
  label $d.9 -text "bar entropy" -font $df
  button $d.9a -font $df
  tooltip::tooltip $d.9a "Show histogram of all distinct bars"
  button $d.10 -text "drum irregularity" -font $df
  tooltip::tooltip $d.10 "Plot the tatum irregularity"
  button $d.11 -text "postscript file" -command {make_postscript_file  .drumanalysis.c} -font $df
  tooltip::tooltip $d.11 "Save the current plot
in a PostScript file."
  button $d.12 -text help -command {show_message_page $hlp_drumanalysis word} -font $df
  button $d.10a -text "map" -font $df
  tooltip::tooltip $d.10a "Maps all the distinct bars
 for each percussion instrument"
  grid $d.1 $d.1a
  grid $d.2 $d.2a
  grid $d.3 $d.3a
  grid $d.4 $d.4a
  grid $d.5 $d.5a
  grid $d.6 $d.6a
  grid $d.7 $d.7a
  grid $d.8 $d.8a
  grid $d.9 $d.9a
  grid $d.10 $d.10a
  grid $d.11 $d.12
  }
set period 4
set nbeats [expr $mlength/$ppqn]
set ntatums [expr $nbeats*4]
set period [graph_drum_periodicity $drumpat $graph]
if {$period < 2} {set period 2}
$d.1a configure -text $nbeats
$d.2a configure -text $ntatums
$d.3a configure -text "$period beats"
$d.10 configure -command "drum_irregularity [list $drumpat] [expr $period*4] $graph" 
$d.10a configure -command "fullDrumMapAnalysis $period"

set tatumhistogram [make_string_histogram $drumpat]
set tentropy [string_entropy $tatumhistogram]
set tsize [llength [dict keys $tatumhistogram]]

$d.4a configure -text "$tsize patterns"
$d.5a configure -text $tentropy -command "plot_tatum_histogram $graph [list $tatumhistogram]"


set patindexdict [keys2index $tatumhistogram]
#puts "drumpat:\n$drumpat"
set beatseries [index_and_group $patindexdict $drumpat 4 "-"]
#puts "beatseries for drumpat:\n$beatseries"
set beathistogram [make_string_histogram $beatseries]
set bentropy [string_entropy $beathistogram]
set bsize [llength [dict keys $beathistogram]]

set patindex2dict [keys2index $beathistogram]
set barseries [index_and_group $patindex2dict $beatseries $period "_"]
set barhistogram [make_string_histogram $barseries]
set barsize [llength [dict keys $barhistogram]]
set barentropy [string_entropy $barhistogram]

set patindex3dict [keys2index $barhistogram]
set barseq [bar2index $patindex3dict $barseries]
set fullbarseqstring [barseq2string $patindex3dict $barseries]
set fullDrumStats [format "%2d/%2d/%2d " $tsize $bsize $barsize]
if {[winfo exist .drummap]} {fullDrumMapAnalysis $period}

$d.6a configure -text "$bsize patterns"
$d.8a configure -text "$barsize patterns"
$d.7a configure -text $bentropy -command "plot_tatum_histogram $graph [list $beathistogram]"
$d.9a configure -text $barentropy -command "plot_tatum_histogram $graph [list $barhistogram]"

}


proc analyzeDrumPatternsFor {drum period} {
global drumpatches
set b .drummap.txt
 set drumname [lindex [lindex $drumpatches [expr $drum-35] 1]]
set drumpat [get_drum_patterns 0] 
#write_drumpat $drumpat 
set sdrumpat [extract_drumpat_for $drum $drumpat]
set tatumhistogram [make_string_histogram $sdrumpat]
#set tentropy [string_entropy $tatumhistogram]
set patindexdict [keys2index $tatumhistogram]
set beatseries [index_and_group $patindexdict $sdrumpat 4 "-"]
set tsize [llength [dict keys $tatumhistogram]]
set beathistogram [make_string_histogram $beatseries]
set bsize [llength [dict keys $beathistogram]]
set patindex2dict [keys2index $beathistogram]
set barseries [index_and_group $patindex2dict $beatseries $period "_"]
set barhistogram [make_string_histogram $barseries]
set barsize [llength [dict keys $barhistogram]]
set patindex3dict [keys2index $barhistogram]
set barseq [bar2index $patindex3dict $barseries]
setup_i2l
set barseqstring [barseq2string $patindex3dict $barseries]
set drumStats [format "%2d/%2d/%2d " $tsize $bsize $barsize]
$b insert insert $drumname\t\t\t headr
$b insert end $drumStats\t headr
$b insert end $barseqstring\n
}


proc fullDrumMapAnalysis {period} {
global activedrum
global drumpatches
global fullbarseqstring
global fullDrumStats
active_drums
set b .drummap.txt
if {![winfo exist .drummap]} {
   toplevel .drummap 
   positionWindow .drummap
   text $b -width 80 -xscrollcommand {.drummap.xsbar set} -wrap none
   scrollbar .drummap.xsbar -orient horizontal -command {.drummap.txt xview}
   pack $b .drummap.xsbar -side top -fill x
   setup_i2l
   }
wm title .drummap "drummap"
$b delete 1.0 end
$b tag configure headr -background wheat3
$b insert insert "drum\t\t\t  i/j/k\n" headr
set nlines 0
foreach drum [array names activedrum] {
  if {$activedrum($drum) > 0} {
    if {$drum > 81} break
    #puts "activedrum($drum) == $activedrum($drum)"
    set drumname [lindex [lindex $drumpatches [expr $drum-35] 1]]
    analyzeDrumPatternsFor $drum $period
    incr nlines
    }
  }
.drummap.txt insert insert "All drums\t\t\t" headr
.drummap.txt insert insert $fullDrumStats\t headr
.drummap.txt insert end $fullbarseqstring
incr nlines
incr nlines
# mark bar numbers on top line
set nchar [string length $fullbarseqstring]
for {set i 1} {$i <$nchar} {incr i 8} {
    if {$i < 8} {set str [format %5d $i]
        } else  {set str [format %9d $i]}
    $b insert 1.end $str
}

$b configure -height $nlines
}


proc graph_drum_periodicity {drumpat graph} {
set curve {}
set peaks {}
set maxy [bit_correlate $drumpat 0]
#puts $maxy
set maxy [expr double($maxy)]
for {set i 0} {$i < 65} {incr i} {
 set y [expr [bit_correlate $drumpat $i] / $maxy]
 #puts "$i [bit_correlate $drumpat $i]"
 set x [expr $i/4.0]
 set p [list $x $y]
 lappend curve $p
 if {($i > 0) &&[expr $i % 4] == 0} {lappend peaks $y}
 }
#puts $curve
if {[winfo exists $graph] == 1} {$graph delete all}
plotUnivariateDistribution $graph $curve 0.0 16.0 2.0 "beat lag"
return [expr [maxindex $peaks]+1]
}

proc make_string_histogram {series} {
# Series contains a sequential list of strings in a
# dictionary structure. This function identifies all
# the distinct strings and counts their occurrences
# which is returned in a histogram indexed by these
# strings.
set size [dict size $series]
set keys [dict keys $series]
set histogram [dict create]
foreach key $keys {
  set pat [dict get $series $key]
  if {$pat == 0 } continue
  incr total
  if {[dict exist $histogram $pat]} {
    dict set histogram $pat [expr [dict get $histogram $pat] + 1]
    } else {
    dict set histogram $pat 1
    }
 }
return $histogram
}

proc make_string_histogram_for {series c size} {
#same as above but for specific channel (or track)
set histogram [dict create]
for {set i 0} {$i < $size} {incr i} {
  if {![dict exist $series $c,$i]} break
  set pat [dict get $series $c,$i]
  if {$pat == 0 } continue
  incr total
  if {[dict exist $histogram $pat]} {
    dict set histogram $pat [expr [dict get $histogram $pat] + 1]
    } else {
    dict set histogram $pat 1
    }
 }
return $histogram
}

proc plot_tatum_histogram {graph h} {
if {[winfo exist $graph]} {$graph delete all}
set i 0
set freqlist {}
foreach  {key value} $h {
  incr i
  #puts "$key $value"
  lappend freqlist $value
  }
set nbars [llength $freqlist]
set dnbars [expr double($nbars+1)]
if {$nbars < 25} {
   set step 4
   } else {
   set step [expr $nbars/6]
  }
$graph create rectangle 50 20 350 200 -outline black\
            -width 2 -fill white
Graph::alter_transformation 50 350 200 20 0 $dnbars 0.0 3.1
Graph::draw_x_grid $graph 0 $dnbars $step 1  0 %4.0f
Graph::draw_y_log10ticks $graph 0.0 3.0 %3.0f
set iyb [Graph::iypos 0.0]
for {set i 0} {$i < $nbars} {incr i} {
      set y [lindex $freqlist $i]
      if {$y > 1000} {set y 1000}
      set ix [Graph::ixpos [expr double($i)]]
      set ix2 [Graph::ixpos [expr double($i+1)]]
      set y [expr log10($y+1.0)]
      set iy  [Graph::iypos $y]
      $graph create rectangle $ix $iyb $ix2 $iy -fill lightblue
    }
}

proc string_entropy {histogram} {
# given a histogram in form of a dictionary structure,
# the function computes its entropy.
set total 0
foreach elem [dict keys $histogram] {
  if {$elem != 0} {
     set total [expr $total + [dict get $histogram $elem]]
     }
  } 
#puts "total = $total"
set total [expr double($total)]
set entropy 0.0
foreach elem [dict keys $histogram] {
  if {$elem != 0} {
     set p [expr [dict get $histogram $elem]/$total]
     #puts "key = $elem count = [dict get $histogram $elem]"
     set delta_entropy [expr $p*log($p)/log(2.0)]
     set entropy [expr $entropy - $delta_entropy]
     #puts "$elem [dict get $histogram $elem],$p,$delta_entropy"
     }
  }
set entropy [format %3.1f $entropy]
return $entropy
}

proc keys2index {histogram} {
# Creates a numeric label for each element in the histogram
# stored in a dict structure. Each of the keys in the 
# histogram are mapped into a numeric index which is returned
# in the patindexdict dictionary.
set patindexdict [dict create]
set patcounter 1
foreach elem [dict keys $histogram] {
  if {$elem != 0} {
     dict set patindexdict $elem $patcounter
     incr patcounter
     }
  }
dict set patindexdict 0 0
return $patindexdict
}



proc drum_entropy {series} {
set size [dict size $series]
array unset tatumhistogram
set total 0
for {set i 0} {$i < $size} {incr i} {
  set pat [dict get $series $i]
  if {$pat == 0 } continue
  incr total
  if {[info exist tatumhistogram($pat)]} {incr tatumhistogram($pat)
    } else {
    set tatumhistogram($pat) 1
    }
 }
if {[info exist tatumhistogram(0)]} {
  set total [expr $total - $tatumhistogram(0)]
  }
#puts [array get tatumhistogram]
set total [expr double($total)]
#puts "total = $total"
set entropy 0.0
set patcounter 1
set patindexdict [dict create]
foreach elem [array names tatumhistogram] {
  if {$elem != 0} {
     dict set patindexdict $elem $patcounter
     incr patcounter
     set p [expr $tatumhistogram($elem)/$total]
     set entropy [expr $entropy - $p*log($p)]
     }
  }
dict set patindexdict 0 0
set entropy [format %5.3f $entropy]
return [list [array size tatumhistogram] $entropy $patindexdict]
}
     
  
proc index_and_group {patindex series nunits connector} {
# Replaces each string in series with an index number using
# the dictionary patindex and combines nunits of these elements
# of series into one string using connector as a separator.
set beatpatseries [dict create]
set size [dict size $series]
set j 0
set k 0
set top [expr $nunits -1]
for {set i 0} {$i < $size} {incr i} {
  if {![dict exists $series $i]} continue
  set elem [dict get $series $i]
  set tatumname [dict get $patindex $elem]
  if {$j == 0} {set beatname $tatumname
      incr j
    } elseif {$j == $top} {
       set beatname $beatname$connector$tatumname
       dict set beatpatseries $k $beatname
       #puts "$k $beatname"
       incr k
       set j 0
    } else {
       set beatname $beatname$connector$tatumname
       incr j
       }
    }
return $beatpatseries 
}

proc index_and_group_for {patindex series c nunits connector} {
# like above but only selects channel (track) c
set beatpatseries [dict create]
set size [dict get $series $c,size]
set j 0
set k 0
set top [expr $nunits -1]
for {set i 0} {$i < $size} {incr i} {
  set elem [dict get $series $c,$i]
  set tatumname [dict get $patindex $elem]
  if {$j == 0} {set beatname $tatumname
      incr j
    } elseif {$j == $top} {
       set beatname $beatname$connector$tatumname
       dict set beatpatseries $k $beatname
       #puts "$k $beatname"
       incr k
       set j 0
    } else {
       set beatname $beatname$connector$tatumname
       incr j
       }
    }
return $beatpatseries 
}

proc bar2index {patindex series} {
set barseq [dict create]
set size [dict size $series]
for {set i 0} {$i < $size} {incr i} {
   set elem [dict get $series $i]
   set index [dict get $patindex $elem]
   dict set barseq $i $index
   }
return $barseq
}

proc bar2index_for {patindex series c} {
set barseq [dict create]
set size [dict size $series]
for {set i 0} {$i < $size} {incr i} {
   if {![dict exist $series $c,$i]} break
   set elem [dict get $series $c,$i]
   set index [dict get $patindex $elem]
   dict set barseq $i $index
   }
return $barseq
}

proc barseq2string {patindex series} {
set s ""
set size [dict size $series]
for {set i 0} {$i < $size} {incr i} {
   set elem [dict get $series $i]
   set index [dict get $patindex $elem]
   append s [index2letter $index]
   if {[expr $i % 32] == 7} {append s "\t"}
   if {[expr $i % 32] == 15} {append s "\t"}
   if {[expr $i % 32] == 23} {append s "\t"}
   if {[expr $i % 32] == 31} {append s "\t"}
   }
return $s
}

proc barseqcode {letter} {
# given the letter code for the bar pitch pattern,
# the function gets the beat sequence pattern corresponding
# to the code and then the tatum sequences for each beat
# and returns all this information in a string.
global patindex3dict
global patindex2dict
global patindexdict
global i2l
set code [string first $letter $i2l]
if {$code < 0} return
set code1 [dict get [lreverse $patindex3dict] $code]
set representation ""
foreach let [split $code1 _] {
  set code2 [dict get [lreverse $patindex2dict] $let]
   append representation "||" 
  foreach llet [split $code2 -] {
     append representation "/"
     set code3 [dict get [lreverse $patindexdict] $llet]
     #puts "\t$llet -> $code3"
     append representation [binary_to_pitchclasses $code3]
     } 
  }
return $representation
}

proc rbarseqcode {letter} {
# translates the letter symbol representation of a particular
# rhythm to its binary representation which is displayed on
# header of the dictview window.
global rpatindexdict
global i2l
set code [string first $letter $i2l]
if {$code < 0} return
set representation [dict get [lreverse $rpatindexdict] $code]
return $representation
}



proc setup_i2l {} {
global i2l
set i2l " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
for {set i 0} {$i < 80} {incr i} {
  set ch [expr 0x390 + $i]
  append i2l [format %c $ch]
  }
for {set i 0} {$i < 50} {incr i} {
  set ch [expr 0x410 + $i]
  append i2l [format %c $ch]
  }
}


proc index2letter {i} {
global i2l
if {$i > 190} {return "*"}
return [string index $i2l $i]
}



set hlp_drumroll "This tool is designed for viewing and analyzing\
midi drum sequences. The tool behaves somewhat similar to pianoroll\
but in addition labels the individual drum events. The percussion\
instruments are color coded so that similar instruments have\
similar colors. The height of the vertical bars representing the\
the individual note-on is proportional to the MIDI velocity of that note.\n\n\
The percussion channel can address many percussion instruments.\
Some of these instruments may be barely audible. This interface\
allows you to hear some of these percussion instruments alone\
without competing sounds. You can select the instruments of interest\
by checking the adjacent checkbox and then clicking play.\
If you do not check any of the boxes, then all the percussion\
instruments are played. The invert button with invert all your\
selections.\n\n\
The manner in which the file is played can be modified using\
the config button. For example, you can play only the percussion\
channel.\n\n\
As usual you can select a specific time interval to play by\
highlighting the designated area. (You can also zoom into this\
area and see more detail.\n\n\
"

# end of source drumgram.tcl




#   Part 11.0 Midi Statistics for Pianoroll and DrumRoll

proc pianoroll_statistics {choice canvs} {
    global pianoresult midi
    global histogram
    global ppqn
    global trksel
    global total
    global start stop
    global cleanData
    for {set i 0} {$i < 128} {incr i} {set histogram($i) 0}
    set limits [midi_limits $canvs]
    set start [lindex $limits 0]
    set stop  [lindex $limits 1]
    set exec_out "pianoroll_statistics\n\n"
    append exec_out "from $start to $stop\n\n"
    if {[llength $pianoresult] < 1} {loadMidiFile; set cleanData 1}
    set tsel [count_selected_midi_tracks]
    foreach line $pianoresult {
        if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        if {[string is double $begin] != 1} continue
        if {$begin < $start} continue
        set end [lindex $line 1]
        if {$end   > $stop}  continue
        set t [lindex $line 2]
        set c [lindex $line 3]
        if {$midi(midishow_sep) == "track"} {set sep $t} else {set sep $c}
        if {$tsel != 0 && $trksel($sep) == 0} continue
        set note [lindex $line 4]
        set vel [lindex $line 5]
        switch $choice {
            pitch {set histogram($note) [expr $histogram($note)+1]}
            velocity {set histogram($vel) [expr $histogram($vel)+1]}
            duration {set index [expr int((($end - $begin)*48)/$ppqn)]
                if {$index > 127} {set index 127}
                set histogram($index) [expr $histogram($index)+1]
            }
            onset {set s [expr int((100.0*$begin)/$ppqn) % 100]
                set histogram($s) [expr $histogram($s) + 1]
                }
        }
    }
    set total 0;
    for {set i 0} {$i <128} {incr i} {
        set total [expr $total+$histogram($i)]
    }
    if {$total < 1} return
    for {set i 0} {$i <128} {incr i} {
        set histogram($i) [expr double($histogram($i))/$total]
    }
}

proc make_list_of_percussions_of_interest {} {
    global gram_ndrums
    global drumpick
    global rdrumstrip
    set perclist {}
    for {set i 0} {$i <$gram_ndrums} {incr i} {
       if {$drumpick($i) > 0} {
	    set perc $rdrumstrip($i)
	    lappend perclist $perc
            }
       }
    return $perclist
}


proc drumroll_statistics {choice} {
    global pianoresult midi
    global histogram
    global ppqn
    global trksel
    global total
    global start stop

    set perclist [make_list_of_percussions_of_interest]
    set perclistlength [llength $perclist]

    for {set i 0} {$i < 128} {incr i} {set histogram($i) 0}
    set limits [midi_limits .drumroll.can]
    set start [lindex $limits 0]
    set stop  [lindex $limits 1]
    set exec_out "drumroll_statistics\n\n"
    append exec_out "from $start to $stop\n\n"
    set tsel [count_selected_midi_tracks]
    
    foreach line $pianoresult {
        if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        if {[string is double $begin] != 1} continue
        if {$begin < $start} continue
        set end [lindex $line 1]
        if {$end   > $stop}  continue
        set t [lindex $line 2]
        set c [lindex $line 3]
        if {$c != 10} continue
        if {$midi(midishow_sep) == "track"} {set sep $t} else {set sep $c}
        if {$tsel != 0 && $trksel($sep) == 0} continue
        set note [lindex $line 4]
        set vel [lindex $line 5]
	if {$perclistlength >0 && [lsearch $perclist $note] < 0} continue
        switch $choice {
            pitch {set histogram($note) [expr $histogram($note)+1]}
            velocity {set histogram($vel) [expr $histogram($vel)+1]}
            duration {set index [expr int((($end - $begin)*48)/$ppqn)]
                if {$index > 127} {set index 127}
                set histogram($index) [expr $histogram($index)+1]
            }
            onset {set s [expr int((100.0*$begin)/$ppqn) % 100]
                set histogram($s) [expr $histogram($s) + 1]
                }
        }
    }
    set total 0;
    for {set i 0} {$i <128} {incr i} {
        set total [expr $total+$histogram($i)]
    }
    #puts "total = $total"
    if {$total < 1} return
    for {set i 0} {$i <128} {incr i} {
        set histogram($i) [expr double($histogram($i))/$total]
    }
}


proc midi_statistics {choice source} {
# derived from pianoroll_statistics
    global pianoresult midi
    global histogram
    global ppqn
    global total
    global exec_out
    global midi
    global cleanData
    global briefconsole


    set cleanData 0
    set exec_out "midi_statistics $choice $source\n\n"
    copyMidiToTmp $source
    set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -midigram"
    catch {eval $cmd} pianoresult
    if {$briefconsole} {
       set exec_out [append exec_out "midi_statistics:\n\n$cmd\n\n [string range $pianoresult 0 200]..."]
       } else {
       set exec_out [append exec_out "midi_statistics:\n\n$cmd\n\n $pianoresult"]
       }

    update_console_page

    for {set i 0} {$i < 128} {incr i} {set histogram($i) 0}
    
    set pianoresult [split $pianoresult \n]
    foreach line $pianoresult  {
        if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        set end [lindex $line 1]
        set t [lindex $line 2]
        set c [lindex $line 3]
        set note [lindex $line 4]
        set vel [lindex $line 5]
        switch $choice {
            pitch {if {$c == 10} continue
                  set histogram($note) [expr $histogram($note)+1]}
            velocity {set histogram($vel) [expr $histogram($vel)+1]}
            duration {set index [expr int(($end - $begin)*32/$ppqn)]
                if {$index > 127} {set index 127}
                set histogram($index) [expr $histogram($index)+1]
            }
            onset {set s [expr int((100.0*$begin)/$ppqn) % 100]
                set histogram($s) [expr $histogram($s) + 1]
                }
            offset {set s [expr int((100.0*$end)/$ppqn) % 100]
                set histogram($s) [expr $histogram($s) + 1]
                }
        }
    }
    set total 0;
    for {set i 0} {$i <128} {incr i} {
        set total [expr $total+$histogram($i)]
    }
    if {$total < 1} return
    for {set i 0} {$i <128} {incr i} {
        set histogram($i) [expr double($histogram($i))/$total]
    }
}


set plotwidth 300
set plotheight 200
set xlbx 60; # left margin of bounding box
set ytbx 10; # top margin of bounding box
set xrbx [expr $xlbx + $plotwidth]
set ybbx [expr $ytbx + $plotheight]
set scanwidth [expr $xrbx+20]
set scanheight [expr $ybbx+30]





proc plotmidi_pitch_pdf {} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global histogram
    global midi
    global df
    global compactMidifile
    set hgraph ""
    set maxhgraph 0.0
    set statc .pitchpdf.c
    set colfg [lindex [.info.txt config -fg] 4]
    for {set i 0} {$i < 128} {incr i} {
        lappend hgraph $i
        lappend hgraph $histogram($i)
        if {$histogram($i) > $maxhgraph} {set maxhgraph $histogram($i)}
    }
    set maxhgraph [expr $maxhgraph + 0.1]
    if {[winfo exists .pitchpdf] == 0} {
        toplevel .pitchpdf
        positionWindow .pitchpdf
        pack [canvas $statc -width $scanwidth -height $scanheight]\
                -expand yes -fill both
    } else {
        .pitchpdf.c delete all}
    wm title .pitchpdf "probability versus midi pitch value"
    $statc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.0 130 0.0 $maxhgraph
    Graph::draw_x_ticks $statc 0.0 128.0 10.0 2 0 %4.0f $colfg
    Graph::draw_y_ticks $statc 0.0 $maxhgraph 0.05 2 %3.1f $colfg
    Graph::draw_impulses_from_list .pitchpdf.c $hgraph
    set ypos [expr $ytbx + 15]
    set xpos [expr $xlbx + 10]
    .pitchpdf.c create text $xpos $ypos -text $compactMidifile  -anchor w
}

proc plotmidi_velocity_pdf {} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global histogram
    global midi
    global df
    global compactMidifile
    set hgraph ""
    set maxhgraph 0.0
    set statc .velocitypdf.c
    for {set i 0} {$i < 128} {incr i} {
        lappend hgraph $i
        lappend hgraph $histogram($i)
        if {$histogram($i) > $maxhgraph} {set maxhgraph $histogram($i)}
    }
    set colfg [lindex [.info.txt config -fg] 4]
    set maxhgraph [expr $maxhgraph + 0.1]
    if {[winfo exists .velocitypdf] == 0} {
        toplevel .velocitypdf
        positionWindow .velocitypdf
        pack [canvas $statc -width $scanwidth -height $scanheight]\
                -expand yes -fill both
    } else {
        .velocitypdf.c delete all}
    wm title .velocitypdf "probability versus midi velocity"
    $statc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.0 130 0.0 $maxhgraph
    Graph::draw_x_ticks $statc 0.0 128.0 10.0 2 0 %4.0f $colfg
    Graph::draw_y_ticks $statc 0.0 $maxhgraph 0.05 2 %3.1f $colfg
    Graph::draw_impulses_from_list .velocitypdf.c $hgraph
    set ypos [expr $ytbx + 15]
    set xpos [expr $xlbx + 10]
    .velocitypdf.c create text $xpos $ypos -text $compactMidifile  -anchor w
}

proc plotmidi_onset_pdf {} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global histogram
    global midi
    global df
    global compactMidifile
    set hgraph ""
    set maxhgraph 0.0
    set statc .onsetpdf.c
    for {set i 0} {$i < 100} {incr i} {
        set index [format %4.2f [expr $i/100.0]]
        lappend hgraph $index
        lappend hgraph $histogram($i)
        if {$histogram($i) > $maxhgraph} {set maxhgraph $histogram($i)}
    }
    set colfg [lindex [.info.txt config -fg] 4]
    set maxhgraph [expr $maxhgraph + 0.1]
    if {[winfo exists .onsetpdf] == 0} {
        toplevel .onsetpdf
        positionWindow .onsetpdf
        pack [canvas .onsetpdf.c -width $scanwidth -height $scanheight]\
                -expand yes -fill both
    } else {
        .onsetpdf.c delete all}
    wm title .onsetpdf "distribution of note onset time in beat units"
    $statc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx -0.03 1.03 0.0 $maxhgraph
    Graph::draw_x_ticks $statc 0.0 1.01 0.10 2 0 %4.2f $colfg
    if {$maxhgraph > 0.2} {
      Graph::draw_y_ticks $statc 0.0 $maxhgraph 0.05 2 %3.1f $colfg
    } else {
      Graph::draw_y_ticks $statc 0.0 $maxhgraph 0.025 2 %3.2f $colfg
    }
    Graph::draw_impulses_from_list .onsetpdf.c $hgraph

    bind .onsetpdf <Alt-p> {histogram_ps_output .onsetpdf.c}
    set ypos [expr $ytbx + 15]
    set xpos [expr $xlbx + 10]
    .onsetpdf.c create text $xpos $ypos -text $compactMidifile  -anchor w
}

proc plotmidi_offset_pdf {} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global histogram
    global midi
    global df
    global compactMidifile
    set hgraph ""
    set maxhgraph 0.0
    set statc .offsetpdf.c
    for {set i 0} {$i < 100} {incr i} {
        set index [format %4.2f [expr $i/100.0]]
        lappend hgraph $index
        lappend hgraph $histogram($i)
        if {$histogram($i) > $maxhgraph} {set maxhgraph $histogram($i)}
    }
    set colfg [lindex [.info.txt config -fg] 4]
    set maxhgraph [expr $maxhgraph + 0.1]
    if {[winfo exists .offsetpdf] == 0} {
        toplevel .offsetpdf
        positionWindow .offsetpdf
        pack [canvas .offsetpdf.c -width $scanwidth -height $scanheight]\
                -expand yes -fill both
    } else {
        .offsetpdf.c delete all}
    wm title .offsetpdf "distribution of note off time in beat units"
    $statc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx -0.03 1.03 0.0 $maxhgraph
    Graph::draw_x_ticks $statc 0.0 1.01 0.10 2 0 %4.2f $colfg
    Graph::draw_y_ticks $statc 0.0 $maxhgraph 0.05 2 %3.1f $colfg
    Graph::draw_impulses_from_list .offsetpdf.c $hgraph
    set ypos [expr $ytbx + 15]
    set xpos [expr $xlbx + 10]
    .offsetpdf.c create text $xpos $ypos -text $compactMidifile  -anchor w
    bind .offsetpdf <Alt-p> {histogram_ps_output .offsetpdf.c}
}

proc plotmidi_duration_pdf {} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global histogram
    global midi
    global df
    global compactMidifile
    set hgraph ""
    set maxhgraph 0.0
    set statc .durpdf.c
    for {set i 0} {$i < 128} {incr i} {
        set index [format %4.2f [expr $i/48.0]]
        lappend hgraph $index
        lappend hgraph $histogram($i)
        if {$histogram($i) > $maxhgraph} {set maxhgraph $histogram($i)}
    }
    set maxhgraph [expr $maxhgraph + 0.1]
    set colfg [lindex [.info.txt config -fg] 4]
    if {[winfo exists .durpdf] == 0} {
        toplevel .durpdf
        positionWindow .durpdf
        pack [canvas .durpdf.c -width $scanwidth -height $scanheight]\
                -expand yes -fill both
    } else {
        .durpdf.c delete all}
    wm title .durpdf "probability versus note duration"
    $statc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.00 2.7 0.0 $maxhgraph
    Graph::draw_x_ticks $statc 0.0 3.0 0.5 1 0 %4.2f $colfg
    Graph::draw_y_ticks $statc 0.0 $maxhgraph 0.05 2 %3.1f $colfg
    Graph::draw_impulses_from_list .durpdf.c $hgraph
    set ypos [expr $ytbx + 15]
    set xpos [expr $xlbx + 10]
    .durpdf.c create text $xpos $ypos -text $compactMidifile  -anchor w
    }


proc update_displayed_pdf_windows {canvs} {
#puts "update_displayed_pdf_windows $canvs"
if {$canvs == ".drumroll.can"} {
   update_drumroll_pdfs
   return
   }
if {[winfo exists .pitchpdf]} {
   pianoroll_statistics pitch $canvs
   plotmidi_pitch_pdf
   }
if {[winfo exists .pitchclass]} {
   pianoroll_statistics pitch $canvs
   show_note_distribution
   }
if {[winfo exists .velocitypdf]} {
   pianoroll_statistics velocity $canvs
   plotmidi_velocity_pdf
   }
if {[winfo exists .onsetpdf]} {
   pianoroll_statistics onset $canvs
   plotmidi_onset_pdf
   }
if {[winfo exists .offsetpdf]} {
   midi_statistics offset pianoroll
   plotmidi_offset_pdf
   }
if {[winfo exists .durpdf]} {
   pianoroll_statistics duration $canvs
   plotmidi_duration_pdf
   }
if {[winfo exists .midivelocity]} {
   if {$canvs == ".piano.can"} {
     plot_velocity_map pianoroll
   } else {
     plot_velocity_map $canvs
     }
   }
if {[winfo exists .chordview]} {
   chordtext_window $canvs
   }
if {[winfo exists .chordstats]} {
   chord_histogram pianoroll
   }
if {[winfo exists .chordgram]} {
   chordgram_plot pianoroll
   }
if {[winfo exists .entropy]} {
   analyze_note_patterns
   }
if {[winfo exists .beatgraph]} {
   beat_graph pianoroll
   }
if {[winfo exists .channel9]} {
   compute_drum_pattern
   }
if {[winfo exists .notegram]} {
   notegram_plot pianoroll
   }
}


proc updateAllWindows {source} {
#puts "updateAllWindows $source"
if {[winfo exists .pitchpdf]} {
   midi_statistics pitch $source
   plotmidi_pitch_pdf
   }
if {[winfo exists .pitchclass]} {
   midi_statistics pitch $source
   show_note_distribution
   }
if {[winfo exists .velocitypdf]} {
   midi_statistics velocity $source
   plotmidi_velocity_pdf
   }
if {[winfo exists .onsetpdf]} {
   midi_statistics onset $source
   plotmidi_onset_pdf
   }
if {[winfo exists .offsetpdf]} {
   midi_statistics offset $source
   plotmidi_offset_pdf
   }
if {[winfo exists .durpdf]} {
   midi_statistics duration $source
   plotmidi_duration_pdf
   }
if {[winfo exists .midivelocity]} {
   plot_velocity_map $source
   }
if {[winfo exists .chordview]} {
   chordtext_window $source
   }
if {[winfo exists .chordstats]} {
   chord_histogram
   }
if {[winfo exists .chordgram]} {
   chordgram_plot $source 
   }
if {[winfo exists .entropy]} {
   analyze_note_patterns
   }
if {[winfo exists .notegram]} {
   notegram_plot $source
   }
if {[winfo exists .beatgraph]} {
   beat_graph $source
   }
if {[winfo exists .pgram]} {
   compute_pgram
   }
if {[winfo exist .keystrip]} {
   keymap $source
   }
if {[winfo exists .keypitchclass]} {
   displayKeyPitchHistogram
   }
if {[winfo exists .channel9]} {
   compute_drum_pattern
   }
if {[winfo exists .ptableau]} {
   detailed_tableau
   }
if {[winfo exists .effect]} {
   aftertouch
   }
if {[winfo exists .csettings]} {
   getAllControlSettings
   }
if {[winfo exists .data_info]} {
   dirhome 
   }
}

proc update_drumroll_pdfs {} {
if {[winfo exists .onsetpdf]} {
   drumroll_statistics onset 
   plotmidi_onset_pdf
   }
if {[winfo exists .velocitypdf]} {
   drumroll_statistics velocity 
   plotmidi_velocity_pdf
   } 
if {[winfo exist .drumanalysis]} {
   analyze_drum_patterns 0
   }
}
  
proc updateWindows_for_tableau {} {
  if {[winfo exists .pitchclass]} {
            midi_statistics pitch tableau
            show_note_distribution
            }
  if {[winfo exists .pitchpdf]} {
            midi_statistics pitch tableau
            plotmidi_pitch_pdf
            }
  if {[winfo exists .onsetpdf]} {
           midi_statistics onset tableau
           plotmidi_onset_pdf
           }
  if {[winfo exists .velocitypdf]} {
            midi_statistics velocity tableau
            plotmidi_velocity_pdf
            }
  if {[winfo exists .chordgram]} {
            chordgram_plot tableau
            }
  if {[winfo exists .notegram]} {
           notegram_plot tableau
           }
  if {[winfo exist .keystrip]} {
           keymap tableau
           }
  if {[winfo exists .durpdf]} {
          midi_statistics pitch tableau
          plotmidi_duration_pdf
   }
  if {[winfo exists .ribbon]} {
   simple_tableau 
   }
if {[winfo exists .chordview]} {
   chordtext_window tableau
   }
}

proc show_note_distribution {} {
    global histogram
    global exec_out total
    global start stop
    global notedist
    for {set i 0} {$i < 13} {incr i} {
        set notedist($i) 0}
    for {set i 0} {$i <128} {incr i} {
        set index [expr $i % 12]
        set notedist($index) [expr $notedist($index) + $histogram($i)]
    }
    plot_pitch_class_histogram
}

proc pdf_entropy {pdf} {
    set entropy 0.0
    set total 0.0
    foreach p $pdf {set total [expr $total + $p]}
    if {$total == 0.0} {return -1}
    foreach p $pdf {
      set p [expr $p / $total]
      if {$p < 0.00001} continue
      set e [expr $p * log($p)]
      set entropy [expr $entropy + $e]
      }
    return [expr -$entropy/log(2.0)]
    }

proc plot_pitch_class_histogram {} {
    global pitchxfm
    global notedist
    global total
    global exec_out
    global df
    global sharpnotes
    global flatnotes
    global pitchcl
    global midi
    
    set w 400
    set h 65 
    set xlbx 10
    set xrbx [expr $w -5]
    set ytbx 5
    set ybbx [expr $h -15]

    set maxgraph 0.0
    set pitchcl ""
    for {set i 0} {$i < 12} {incr i} {
        if {$notedist($i) > $maxgraph} {set maxgraph $notedist($i)}
	lappend pitchcl $notedist($i)
    }
    set pitchcl [normalize_vectorlist $pitchcl]
    set entropy [pdf_entropy $pitchcl]
    set entropy [format "%6.3f" $entropy]
    set maxgraph [expr $maxgraph + 0.2]

    set flats [expr $notedist(3) + $notedist(10)]
    set sharps [expr $notedist(1) + $notedist(6)]
    if {$flats > $sharps} {
      set notes $flatnotes
      } else {
      set notes $sharpnotes
      }


    
    set pitchc .pitchclass.c
    if {[winfo exists .pitchclass] == 0} {
        toplevel .pitchclass
        positionWindow .pitchclass
        
        checkbutton .pitchclass.circle -text "circle of fifths" -variable midi(pitchclassfifths) -font $df -command plot_pitch_class_histogram
        pack .pitchclass.circle
        pack [canvas $pitchc -width 425 -height 100]\
                -expand yes -fill both
    } else {.pitchclass.c delete all}
    
    $pitchc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.0 12.0 0.0 $maxgraph
    set pitchxfm [Graph::save_transform]
    
    set iy [expr $ybbx +10]
    set iy2 [Graph::iypos $maxgraph]
    set j 0
    foreach note $notes {
        if {$midi(pitchclassfifths)} {
          set i [expr ($j*7) % 12]
          } else {
          set i $j
          }
        set ix [Graph::ixpos [expr $i +0.5]]
        $pitchc create text $ix $iy -text $note -font $df
        set iyb [Graph::iypos $notedist($j)]
        set count [expr round($notedist($j)*$total)]
        append exec_out  "$note $count\n"
        set ix [Graph::ixpos [expr double($i)]]
        set ix2 [Graph::ixpos [expr double($i+1)]]
        $pitchc create rectangle $ix $ybbx $ix2 $iy2 -outline blue
        $pitchc create rectangle $ix $ybbx $ix2 $iyb -fill gray
        incr j
    }
    $pitchc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2
    $pitchc create text 70 80 -text "entropy = $entropy"
    bind .pitchclass <Alt-p> {histogram_ps_output .pitchclass.c}
}

proc annotate_group {g} {
  global groupnames
  global df
  .midistructure.txt configure -text [lindex $groupnames $g] -font $df
}

proc un_annotate_group {} {
   global df
  .midistructure.txt configure -text "" -font $df
}

proc bind_program_groups {} {
  set pc .midistructure.programcolor.c
  for {set i 0} {$i < 17} {incr i} {
    $pc bind prog$i <Enter> "annotate_group $i"
    $pc bind prog$i <Leave> "un_annotate_group"
    }
  }

proc plot_programcolor {} {
   global cprogcolor
   global groupcolors
   global df
   set w 400
   set h 60 
   set xlbx 5
   set xrbx [expr $w -5]
   set ytbx 5
   set ybbx [expr $h -5]
   set pc .midistructure.programcolor.c
   if {[winfo exists .midistructure.programcolor] == 0} {
     frame .midistructure.programcolor
     frame .midistructure.left1
     grid .midistructure.left1 .midistructure.programcolor 
     label .midistructure.left1.lab -text "program color" -font $df
     pack .midistructure.left1.lab
     pack [canvas $pc -width $w -height $h]\
           -expand yes -fill both
     bind_program_groups
     } else {$pc delete all}
   $pc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
   Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.0 17.0 0.0 1.0
   for {set i 0} {$i < 16} {incr i} {
     set ix [Graph::ixpos [expr double($i)]]
     set ix2 [Graph::ixpos [expr double($i+1)]]
     set iy [Graph::iypos [lindex $cprogcolor $i]]
     set c [lindex $groupcolors $i]
     $pc create rectangle $ix $ybbx $ix2 $ytbx -tags prog$i -fill white
     $pc create rectangle $ix $ybbx $ix2 $iy -fill $c -tags prog$i
     }
}


proc plot_program_activity {} {
   global cprogsact
   global cprogs
   global groupcolors
   global progmapper
   global df
   set w 400
   set h 60 
   set xlbx 5
   set xrbx [expr $w -5]
   set ytbx 5
   set ybbx [expr $h -5]
   set pc .midistructure.progact.c
   if {[winfo exists .midistructure.progact] == 0} {
     frame .midistructure.progact
     frame .midistructure.leftbottom
     grid .midistructure.leftbottom .midistructure.progact
     label .midistructure.leftbottom.laba -text "program activity" -font $df
     pack .midistructure.leftbottom.laba
     pack [canvas $pc -width $w -height $h]\
           -expand yes -fill both
     } else {$pc delete all}
   $pc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
   Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.0 128.0 0.0 1.0
   foreach prg $cprogs prgact $cprogsact  {
     set ix [Graph::ixpos [expr double($prg)]]
     set iy [Graph::iypos $prgact]
     set c [lindex $groupcolors [lindex $progmapper $prg]]
     $pc create line $ix $ybbx $ix $iy  -fill $c -tags prog$prg -width 3
     }
}


set sharpnotes  {C C# D D# E F F# G G# A A# B}
set flatnotes   {C Db D Eb E F Gb G Ab A Bb B}
set sharpnotes5 {C G D A E B F# C# G# D# A# F}
set flatnotes5  {C G D A E B Gb Db Ab Eb Bb F}


proc histogram_ps_output {canvaslink} {
global df midi
set types {{{postscript files} {*.ps}}}
$canvaslink postscript -file histogram.ps
puts "histogram.ps created"
}

proc make_postscript_file {canvaslink} {
   set types {{{postscript files} {*.ps}}}
   set psext ".ps"
   set filename [tk_getSaveFile -filetypes $types]
   if {[string length $filename] > 3} {
       set ext [file extension $filename]
       if {$ext != $psext} {set filename $filename$psext}
       $canvaslink postscript -file $filename
       }
   }


proc best_grid_spacing {x} {
# Given the scale range, x, it returns
# the grid spacing to get 8 to 4 tick marks.
 set divlist {2 2 1.25 2}
 set i 0
 set n 1
 while {$i < 20} {
   incr i
   set j [expr $i % 4] 
   set d [lindex $divlist $j]
   set n [expr $n * $d]
   set q [expr $x/$n]
   if {$q <8} break
   if {$q <4} break
   }
 return $n
}


#   Part 12.0 Graphics Package (Namespace)

namespace eval Graph {
    
    variable x_scale
    variable y_scale
    variable x_shift
    variable  y_shift
    variable left_edge
    variable bottom_edge
    variable top_edge
    variable right_edge
    
    
    
    namespace export set_xmapping
    proc set_xmapping {left right xleft xright} {
        variable x_scale
        variable x_shift
        variable left_edge
        variable right_edge
        set left_edge $left
        set right_edge $right
        set x_scale [expr double($right - $left) / double($xright - $xleft)]
        set x_shift [expr $left - $xleft*$x_scale]
    }
    
    namespace export set_ymapping
    proc set_ymapping {bottom top ybot ytop} {
        variable y_scale
        variable  y_shift
        variable bottom_edge
        variable top_edge
        set bottom_edge $bottom
        set top_edge $top
        set y_scale [expr double($top - $bottom) / double($ytop - $ybot)]
        set y_shift [expr $bottom - $ybot*$y_scale]
    }
    
    
    namespace export save_transform
    proc save_transform { } {
        variable x_scale
        variable x_shift
        variable y_scale
        variable y_shift
        list $x_scale $y_scale $x_shift $y_shift
    }
    
    
    namespace export restore_transform
    proc restore_transform {xfm} {
        variable x_scale
        variable x_shift
        variable y_scale
        variable y_shift
        foreach {x_scale y_scale x_shift y_shift} $xfm {}
    }
    
    
    namespace export alter_transformation
    proc alter_transformation {left right bottom top xleft xright ybot ytop} {
        set_xmapping $left $right $xleft $xright
        set_ymapping $bottom $top $ybot $ytop
    }
    
    namespace export ixpos
    proc ixpos xval {
        variable x_scale
        variable x_shift
        return [expr $x_shift + $xval*$x_scale]
    }
    
    namespace export iypos
    proc iypos yval {
        variable y_scale
        variable y_shift
        return [expr $y_shift + $yval*$y_scale]
    }
    
    
    namespace export pix_to_x
    proc pix_to_x ix {
        variable x_scale
        variable x_shift
        return [expr ($ix - $x_shift)/$x_scale]
    }
    
    namespace export pix_to_y
    proc pix_to_y iy {
        variable y_scale
        variable y_shift
        return [expr ($iy - $y_shift)/$y_scale]
    }
    
    
    namespace export draw_x_ticks
    proc draw_x_ticks {can xstart xend xstep nskip labindex fmt {colfg black}} {
        global df
        variable bottom_edge
        set xticks {}
        set i 0
        for {set x $xstart} {$x < $xend} {set x [expr $x + $xstep]} {
            set ix [ixpos $x]
            set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                    [expr $bottom_edge - 5]]]
            if {[expr $i % $nskip] == $labindex} {
                set str [format $fmt $x]
                set xticks [concat $xticks [$can create text $ix \
                        [expr $bottom_edge + 20] -text $str -font $df -fill $colfg]]
                set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                        [expr $bottom_edge - 10]]] 

            }
            incr i
        }
        set xticks
    }
    
    namespace export draw_x_grid
    proc draw_x_grid {can xstart xend xstep nskip labindex fmt {colfg black}} {
        global df
        variable bottom_edge
        variable top_edge
        set xticks {}
        set i 0
        for {set x $xstart} {$x < $xend} {set x [expr $x + $xstep]} {
            set ix [ixpos $x]
            set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                    [expr $bottom_edge - 5]]]
            if {[expr $i % $nskip] == $labindex} {
                set str [format $fmt $x]
                set xticks [concat $xticks [$can create text $ix \
                        [expr $bottom_edge + 20] -text $str -font $df -fill $colfg]]
                set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                        $top_edge -dash {1 2}]]]
            }
            incr i
        }
        set xticks
    }

    namespace export draw_y_ticks
    proc draw_y_ticks {can ystart yend ystep nskip fmt {colfg black}} {
        global df
        variable left_edge
        set i 0
        set yticks {}
        for {set y $ystart} {$y < $yend} {set y [expr $y + $ystep]} {
            set iy [iypos $y]
            set yticks [concat $yticks [$can create line  $left_edge \
                    $iy [expr $left_edge + 5] $iy]]
            if {[expr $i % $nskip] == 0} {
                set str [format $fmt $y]
                set yticks [concat $yticks [$can create text \
                        [expr $left_edge - 33] $iy -text $str -font $df -fill $colfg]]
                set yticks [concat $yticks [$can create line \
                        $left_edge $iy [expr $left_edge + 10] $iy]]
            }
            incr i
        }
        set yticks
    }
    
    namespace export draw_y_grid
    proc draw_y_grid {can ystart yend ystep nskip fmt} {
        global df
        variable left_edge
        variable right_edge
        set i 0
        set yticks {}
        for {set y $ystart} {$y < $yend} {set y [expr $y + $ystep]} {
            set iy [iypos $y]
            set yticks [concat $yticks [$can create line  $left_edge \
                    $iy [expr $left_edge + 5] $iy]]
            if {[expr $i % $nskip] == 0} {
                set str [format $fmt $y]
                set yticks [concat $yticks [$can create text \
                        [expr $left_edge - 33] $iy -text $str -font $df]]
                set yticks [concat $yticks [$can create line \
                        $left_edge $iy $right_edge $iy -dash {1 2}]]
            }
            incr i
        }
        set yticks
    }
    
    namespace export draw_x_log10ticks
    proc draw_x_log10ticks {can  start end fmt} {
        variable bottom_edge
        set xstart [expr floor($start)]
        set xend [expr floor($end)]
        for {set x $xstart} {$x<$xend} {set x [expr $x +1.0]} {
            set xval [expr pow(10.0,$x)]
            set ix [ixpos $x]
            $can create line $ix $bottom_edge $ix [expr $bottom_edge -10]
            set str [format $fmt $xval]
            $can create text $ix [expr $bottom_edge+20] -text $str
            for {set i 2} {$i<10} {incr i} {
                set xman [expr log10($i)]
                set ix [ixpos [expr $xman + $x]]
                $can create line $ix $bottom_edge $ix [expr $bottom_edge -5]
            }
        }
    }
    
    namespace export draw_y_log10ticks
    proc draw_y_log10ticks {can  start end fmt} {
        variable left_edge
        set ystart [expr floor($start)]
        set yend [expr floor($end)]
        for {set y $ystart} {$y<$yend} {set y [expr $y +1.0]} {
            set yval [expr pow(10.0,$y)]
            set iy [iypos $y]
            $can create line $left_edge $iy [expr $left_edge +10] $iy
            set str [format $fmt $yval]
            $can create text [expr $left_edge-20] $iy -text $str
            for {set i 2} {$i<10} {incr i} {
                set yman [expr log10($i)]
                set iy [iypos [expr $yman + $y]]
                $can create line  $left_edge $iy [expr $left_edge +5] $iy
            }
        }
    }
    
    
    namespace export draw_graph_from_arrays
    proc draw_graph_from_arrays {can xvals yvals npoints} {
        upvar $xvals xdata
        upvar $yvals ydata
        set points {}
        for {set i 0} {$i < $npoints} {incr i} {
            set ix [ixpos $xdata($i)]
            set iy [iypos $ydata($i)]
            lappend points $ix
            lappend points $iy
        }
        eval {$can create line} $points
    }
    
    
    namespace export draw_graph_from_list
    proc draw_graph_from_list {can datalist} {
        #can canvas
        #datalist {x y x y x y ...}
        set points {}
        foreach {xdata ydata} $datalist {
            set ix [ixpos $xdata]
            set iy [iypos $ydata]
            lappend points $ix
            lappend points $iy
        }
        eval {$can create line} $points
    }
    
    namespace export draw_impulses_from_list
    proc draw_impulses_from_list {can datalist} {
        #can canvas
        #datalist {x y x y x y ...}
        foreach {xdata ydata} $datalist {
            if {$ydata != 0.0} {
                set ix [ixpos $xdata]
                set iy [iypos $ydata]
                $can create line $ix [iypos 0] $ix $iy -fill blue -width 2
            }
        }
    }

    namespace export draw_points_from_list
    proc draw_points_from_list {can datalist color} {
        #can canvas
        #datalist {x y x y x y ...}
        foreach {xdata ydata} $datalist {
                set ix1 [expr [ixpos $xdata] - 3]
                set iy1 [expr [iypos $ydata] - 3]
                set ix2 [expr [ixpos $xdata] + 3]
                set iy2 [expr [iypos $ydata] + 3]
                $can create oval  $ix1 $iy1 $ix2 $iy2 -fill $color -width 0
        }
   }

   namespace export draw_curve_from_list
   proc draw_curve_from_list {can datalist color} {
        #can canvas
        #datalist {x y x y x y ...}
        set points {}
        foreach {xdata ydata} $datalist {
                lappend points [ixpos $xdata]
                lappend points [iypos $ydata]
                }
        $can create line $points
   }

} ;# end of namespace declaration

namespace import Graph::*


#end of midistats.tcl

#source velocitymap.tcl

proc plot_velocity_map {source} {
    global pianoresult midi ppqn
    global trksel
    global fbeat
    global tbeat
    set velmap .midivelocity.c
    if {[winfo exists .midivelocity] == 0} {
        toplevel .midivelocity
        positionWindow .midivelocity
        wm title .midivelocity "midi velocity versus beat number"        
        pack [canvas $velmap]
    } else {
        .midivelocity.c delete all}

    copyMidiToTmp $source
    set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -midigram"
    catch {eval $cmd} pianoresult
    set nrec [llength $pianoresult]
    set midilength [lindex $pianoresult [expr $nrec -6]]

    set colfg [lindex [.info.txt config -fg] 4]
    #set limits [midi_limits .piano.can]
    #set start [expr double([lindex $limits 0])/$ppqn]
    #set stop  [expr double([lindex $limits 1])/$ppqn]
    set delta_tick [expr int(($tbeat - $fbeat)/10.0)]
    if {$delta_tick < 1} {set delta_tick 1}
    set tsel [count_selected_midi_tracks]
    $velmap create rectangle 50 20 350 220 -outline black\
            -width 2 -fill white
    Graph::alter_transformation 50 350 220 20 $fbeat $tbeat 0.0 132
    Graph::draw_x_ticks $velmap $fbeat $tbeat $delta_tick 2  0 %4.0f $colfg
    Graph::draw_y_ticks $velmap 0.0 132.0 8.0 2 %3.0f $colfg
    set pianoresult [split $pianoresult '\n']
    foreach line $pianoresult {
        if {[llength $line] != 6} continue
        set begin [expr double([lindex $line 0])/$ppqn]
        set end [expr double([lindex $line 1])/$ppqn]
        if {[string is double $begin] != 1} continue
        #if {$begin < $fbeat} continue
        #if {$end   > $tbeat}  continue
	set begin [expr $begin+$fbeat]
	set end [expr $begin+1]
        set v [lindex $line 5]
        set t [lindex $line 2]
        set c [lindex $line 3]
        if {$midi(midishow_sep) == "track"} {set sep $t} else {set sep $c}
        if {$tsel != 0 && $trksel($sep) == 0} continue
        set ix1 [Graph::ixpos $begin]
        set ix2 [Graph::ixpos $end]
        set iy [Graph::iypos $v]
	if {$ix2 > 350} {set ix2 350}
        $velmap create line $ix1 $iy $ix2 $iy -width 3
    }
}

#end of velocitymap.tcl


#   Part 13.0 Mftext user interface

set hlp_mftext "mftext window\n\n\
        This window shows a textual representation of the MIDI\
        file specified in the entry box.\n\n\
        Clicking on the track number line will reveal or hide the\
        contents of the track.  The checkbuttons at the bottom of\
        the screen allow you to hide or reveal the output for\
        the specified MIDI commands. (Aftertouch includes both pressure\
        and pitchbend commands.) The number on the left is the beat number,\
        usually quarter notes. The channel number is usually placed after\
        the MIDI command."


proc mftext_tmp_midi {} {
    global midi
    midi_to_midi 1
    mftextwindow $midi(outfilename) 1
    }

proc mftextwindow {midifilein nofile} {
    global midi df
    global mfnotes mftouch mfcntl mfprog mfmeta
    set f .mftext
    if {[winfo exist $f]} {
      $f.fillab configure -text  $midifilein  
      output_mftext [list $midifilein]
      raise $f .
      return
      }

    toplevel $f
    positionWindow $f
    frame $f.1
    label $f.fillab -text $midifilein  -font $df 
    button $f.1.browse -text browse -font $df -command {
             set midifilein [midi_file_browser]
             output_mftext [list $midifilein]
	     .mftext.fillab configure -text $midifilein
             }
    button $f.1.help -text help -font $df\
            -command {show_message_page $hlp_mftext word}
    pack $f.fillab
    pack $f.1.browse $f.1.help -side left
    pack $f.1
    frame $f.2
    pack $f.1 $f.2 -side top -fill y -expand yes
    set f .mftext.4
    frame $f
    label $f.lab -text hide -font $df
    set mfnotes 0
    set mftouch 0
    set mfprog  0
    set mfmeta  0
    set mfcntl  0
    checkbutton $f.note -variable mfnotes  -text notes      -font $df\
            -command mfnotescmd
    checkbutton $f.touch -variable mftouch -text aftertouch -font $df\
            -command mftouchcmd
    checkbutton $f.prog  -variable mfprog  -text program    -font $df\
            -command mfprogcmd
    checkbutton $f.meta  -variable mfmeta  -text metatext   -font $df\
            -command mfmetacmd
    checkbutton $f.cntl  -variable mfcntl  -text cntl       -font $df\
            -command mfcntlcmd
    pack $f.lab $f.note $f.touch $f.prog $f.meta $f.cntl -side left
    pack $f -side top -anchor w

    if {$nofile} {
       pack forget .mftext.1
       } else {
       pack .mftext.1 -before .mftext.2 
       }
    output_mftext [list $midifilein]
    bind .mftext <Control-T> mftext_tmp
    # note you need to hold down the shift key too
}


proc output_mftext {midifilein} {
    global midi exec_out
    global df elidetrk
    global mfnotes mftouch mfcntl mfprog mfmeta
    global mfntracks
    if {[winfo exist .mftext.2.txt]} {
        .mftext.2.txt tag delete everywhere
        destroy .mftext.2.txt .mftext.2.scroll
        if {[info exist elidetrk]} {unset elidetrk}
    }
    text .mftext.2.txt -yscrollcommand {.mftext.2.scroll set} -width 52 -font $df
    scrollbar .mftext.2.scroll -orient vertical -command {.mftext.2.txt yview}
    pack .mftext.2.txt .mftext.2.scroll -side left -fill y
    #set f .mftext.2.txt
    if {$midi(mftextunits) == 2} {
       set cmd "exec [list $midi(path_midi2abc)] $midifilein -mftext"
    } else {
       set cmd "exec [list $midi(path_midi2abc)] $midifilein -mftextpulses"
    }
    catch {eval $cmd} mftextresults
    set exec_out $mftextresults
    if {[string first "no such" $exec_out] >= 0} {abcmidi_no_such_error $midi(path_midi2abc)}
    update_console_page 
    #$f delete 1.0 end
    set mflines [split $mftextresults \n]
    foreach line $mflines {
        tag_and_insert_mftext_line $line
    }
    for {set i 1} {$i <= $mfntracks} {incr i} {
        set elidetrk($i) 0
        elide_reveal_track $i
        }
      
}


proc tag_and_insert_mftext_line {line} {
    global df
    global trktag
    global mfntracks
    set f .mftext.2.txt
    set pat \[A-Za-z\]+
    set linelist [split $line]
    set type ""
    if {[string equal [lindex $linelist 0] "Track"]} {
        set trk [lindex $linelist 1]
        set trktag t$trk
        $f insert end $line\n tr$trk
        $f tag configure tr$trk -foreground blue
        $f tag bind tr$trk <1> "elide_reveal_track $trk"
        $f tag bind tr$trk <Enter> "$f tag configure tr$trk -foreground red"
        $f tag bind tr$trk <Leave> "$f tag configure tr$trk -foreground blue"
    } else {
        regexp $pat $linelist keyword
        switch $keyword {
            Note {set type note}
            Pressure {set type touch}
            Pitchbend {set type touch}
            Metatext {set type meta}
            Program  {set type prog}
            Chanpres {set type touch}
            CntlParm {set type cntl}
        }
        if {[info exist trktag]} {
            $f insert end $line\n [list $trktag $type]
        } else {
            $f insert end $line\n $type
        }
        #$f insert end $line\n $type
        #puts $keyword
    }
    if {[info exist trk]} {set mfntracks $trk}
}


proc elide_reveal_track no {
    global elidetrk
    global mfnotes mftouch mfcntl mfprog mfmeta
    set elidetrk($no) [expr 1 - $elidetrk($no)]
    .mftext.2.txt tag configure t$no -elide $elidetrk($no)
    .mftext.2.txt tag raise t$no
    if {$elidetrk($no) == 0} {
       if {$mfnotes} mfnotescmd      
       if {$mftouch} mftouchcmd
       if {$mfprog}  mfprogcmd
       if {$mfcntl}  mfcntlcmd 
       if {$mfmeta}  mfmetacmd
       }
    }

proc elide_tracks {} {
# Turning off the elide of one of the note, touch, cntl, ... tags
# effects all the tracks. We ensure that the hidden tracks remain
# hidden by raising the t$i tag. (Only the top tag on a line
# is effective in the case of when there is more than one tag
# configured.
    global mfntracks elidetrk
    for {set i 1} {$i <= $mfntracks} {incr i} {
      if {$elidetrk($i) == 1} {.mftext.2.txt tag raise t$i}
    }
}

proc mfnotescmd {} {
    global mfnotes
    .mftext.2.txt tag configure note -elide $mfnotes
    .mftext.2.txt tag raise note
    if {$mfnotes == 0} {elide_tracks}
}

proc mftouchcmd {} {
    global mftouch
    .mftext.2.txt tag configure touch -elide $mftouch
    .mftext.2.txt tag raise touch
    if {$mftouch == 0} {elide_tracks}
}

proc mfprogcmd {} {
    global mfprog
    .mftext.2.txt tag configure prog -elide $mfprog
    .mftext.2.txt tag raise  prog
    if {$mfprog == 0} {elide_tracks}
}

proc mfmetacmd {} {
    global mfmeta
    .mftext.2.txt tag configure meta -elide $mfmeta
    .mftext.2.txt tag raise meta
    if {$mfmeta == 0} {elide_tracks}
}

proc mfcntlcmd {} {
    global mfcntl
    .mftext.2.txt tag configure cntl -elide $mfcntl
    .mftext.2.txt tag raise cntl
    if {$mfcntl == 0} {elide_tracks}
}


#   Part 14.0 Database creation functions

proc make_midi_database {} {
global midi
set outfile [file join $midi(rootfolder) MidiDescriptors.txt]
if {[file exist $outfile]} {
  set choice [tk_messageBox -type yesno -default no \
    -message "Do you wish to replace the database?" -icon question]
  if {$choice == no} {
     .info.txt insert insert "\nAborted replacing database\n"
     return}
  }
set i 0
set stop 0
set sizelimit 20000
.info.txt delete 1.0 end
.info.txt insert insert "finding all midi files...\n"
update
set filelist [rglob $midi(rootfolder) *.mid ] 
set filelist [concat $filelist [rglob $midi(rootfolder) *.MID]]
set nfiles [llength $filelist]
set sizelimit [expr min($sizelimit,$nfiles)]
.info.txt insert insert "$nfiles midi files were found\n"
.info.txt insert insert "sorting the midi files...\n"
if {[winfo exists .csettings]} {
   getAllControlSettings
   }
set filelist [lsort $filelist]
.info.txt insert insert "extracting midi features..."
set outhandle [open $outfile w]
frame .status
label .status.msg -text ""
ttk::progressbar .status.progress -mode determinate -length 200 \
 -value 0 -maximum 1.0
pack .status
grid .status.progress .status.msg
.status.progress start
set starttime [clock seconds]
#fconfigure stdin -blocking 0 -buffering none
puts $outhandle "database_version 10"
foreach midifile $filelist {
  incr i
  #if {![eof stdin]} break
  #fileevent stdin readable exit
  if {$stop == 1} break
  puts $outhandle "index $i"
  if {[expr $i % 100] == 0} {
        set value [expr double($i)/$sizelimit]
        set elapsedtime [expr [clock seconds] - $starttime]
        set expectedtime [expr round($elapsedtime/$value)]
       .status.msg configure -text "$elapsedtime / $expectedtime seconds"
       .status.progress configure -value $value
        update}  
  set exec_options "[list $midifile] "
  set cmd "exec [list $midi(path_midistats)] $exec_options"
  catch {eval $cmd} midi_info
  get_midi_features $midifile $midi_info $outhandle $i
  if {$i > $sizelimit} break
  }
.info.txt insert insert "\ncreated file MidiDescriptors.txt\n"
set elapsedtime [expr [clock seconds] - $starttime]
.info.txt insert insert "elapsed time = $elapsedtime seconds\n"
close $outhandle
.status.progress stop
destroy .status.progress
destroy .status
load_desc
}
  

proc get_midi_features {midifile midi_info outhandle index} {
set programlist {}
set tempo 120.0
set pitchbends 0
set programcmd 0
#in case the midi file is corrupted
set midilength 0
set drums {}
set pcolor {}
foreach line [split $midi_info '\n'] {
  #puts $line
  #remove any embedded double quotes and braces if present
  set line [string map {\" {} \{ {} \} {}} $line]
  #puts "line = $line"
  set info_id [lindex $line 0] 
  switch $info_id {
    program {lappend programlist [lindex $line 2]}
    cprogram {lappend programlist [lindex $line 2]}
    tempo {set tempo [lindex $line 1]}
    pitchbends {set pitchbends [lindex $line 1]}
    programcmd {set programcmd [lindex $line 1]}
    drums {lappend drums [lrange $line 1 end]}
    drumhits {set drumhits [lrange $line 1 end]}
    progcolor {set progcolor [lrange $line 1 end]}
    ppqn {set ppqn [lindex $line 1]}
    npulses {if {[info exist ppqn]} {
          set npulses [lindex $line 1]
          set midilength [expr [lindex $line 1] /$ppqn]
          }
        }
    pitchact {set pitches [lrange $line 1 end]}
    progs {set progs [lrange $line 1 end]}
    progsact {set pprogsact [lrange $line 1 end]}
    pitchentropy {set pitchentropy [lindex $line 1]}
    Error: {.info.txt insert insert  "Defective file $midifile\n"
            puts $outhandle "damaged midifile"
            puts $outhandle "file  [list $midifile]"
            return
           }
    }
  }

set progsact {} 
if {[llength $progs] > 0} {
  foreach p $pprogsact {
    set p [format "%6.3f" [expr double($p)/$npulses]]
    append progsact "$p "
    }
  }

set programlist [lsort -unique -integer $programlist]
#puts "\nfile = $midifile"
#puts "progcolor = $progcolor"
set pcolor [normalize_vectorlist $progcolor]
set pitches [normalize_vectorlist $pitches]
#puts "pcolor    = $pcolor"
puts $outhandle "file  [list $midifile]"
puts $outhandle "tempo $tempo"
puts $outhandle "midilength $midilength"
puts $outhandle "pitchbend $pitchbends"
#puts $outhandle "programs [list $programlist]"
puts $outhandle "progs  $progs"
puts $outhandle "progsact $progsact"
puts $outhandle "programcmd $programcmd"
puts $outhandle "drums $drums"
puts $outhandle "drumhits $drumhits"
puts $outhandle "progcolor $pcolor"
puts $outhandle "pitches $pitches"
puts $outhandle "pitchentropy $pitchentropy"
}


proc normalize_vectorlist {vector} {
set fnorm 0.0
if {![info exist vector]} {
  puts $outhandle "damaged data"
  puts $outhandle "file [list $midifile]"
  return
  }
foreach pc $vector {
  set fnorm [expr $fnorm + ($pc*$pc)]
  }
set fnorm [expr sqrt($fnorm)]
if {$fnorm < 0.01} {set fnorm 0.01}
set dim [llength $vector]
for {set i 0} {$i < $dim} {incr i} {
  set p [lindex $vector $i]
  set p [expr $p/$fnorm]
  set p [format "%6.3f" $p]
  lappend pcolor [lindex $p 0]
  }
return $pcolor
}

proc rootmeansquare {vector} {
set meansquare 0.0
if {![info exist vector]} {
  puts $outhandle "damaged data"
  puts $outhandle "file [list $midifile]"
  return
  }
foreach pc $vector {
  set meansquare [expr $meansquare + ($pc*$pc)]
  }
set meansquare [expr sqrt($meansquare)]
return $meansquare
}


# ReadMidiDescriptors.tcl
# creates or updates dictionary desc with
# midi file descriptors from file MidiDescriptors.txt
proc load_desc {} {
global desc
global midi
if {[array exist desc]} return
set infile [file join $midi(rootfolder) MidiDescriptors.txt]
.info.txt delete 1.0 end
.info.txt insert insert "\nLooking for $infile\n"
if {![file exist $infile]} {
  .info.txt insert insert "First create database\n\n" red
   return
   }
set inhandle [open $infile r]
set index 0
set version 0
gets $inhandle line
if {[lindex $line 0] == "database_version"} {
  set version [lindex $line 1]}
if {$version != 10} {
  .info.txt insert insert "You should rerun create database to get version 10.\t" red}
while {![eof $inhandle]} {
  gets $inhandle line
  if {[llength $line] == 2} {
     set var1 [lindex $line 0]
     set var2 [lindex $line 1]
     if {$var1 == "index"} {
       set index $var2
       } else {
       set $var1 $var2
       dict set desc($index) $var1 $var2
       }
     }
  if {[llength $line] > 2} {
     set var1 [lindex $line 0]
     set var2 [lrange $line 1 end]
     dict set desc($index) $var1 $var2
     }
  }
close $inhandle
.info.txt insert insert "There are $index midi file descriptors\n\n"
}

proc search_window {} {
global searchstate
global df
global sname
global midi
set w .searchbox
if {[winfo exist $w]} {
  raise $w .
  return}


toplevel $w
positionWindow $w

frame $w.matchcriterion
radiobutton $w.matchcriterion.cosine -text "1 - cosine" -font $df\
 -value 1 -variable midi(matchcriterion) -command switch_criterion
radiobutton $w.matchcriterion.mse -text "root mean square error" -font $df\
 -value 2 -variable midi(matchcriterion) -command switch_criterion
pack $w.matchcriterion.cosine $w.matchcriterion.mse -side left
grid $w.matchcriterion -columnspan 3 -sticky w

checkbutton $w.checkname -variable searchstate(cname) -command searchname
label $w.labname -text "string in file name" -font $df 
entry $w.name -textvariable midi(sname) -width 16 -font $df -state disabled
grid $w.checkname $w.labname $w.name -sticky nsew


checkbutton $w.checkprogs -variable searchstate(checkprogs) -command searchprogs
button $w.labprogs -text "contains programs" -font $df -command programSelector
entry $w.progsin -textvariable midi(proglist) -font $df -state disabled
grid $w.checkprogs $w.labprogs $w.progsin -sticky nsew

checkbutton $w.checkperc -variable searchstate(checkperc) -command searchperc
button $w.labperc -text "contains percussion" -font $df -command drum_selector
entry $w.percin -textvariable midi(drumlist) -font $df -state disabled
grid $w.checkperc $w.labperc $w.percin -sticky nsew

checkbutton $w.checkexclude -variable searchstate(checkexclude) -command searchex
label $w.labexprog -text "excludes programs" -font $df
entry $w.excludein -textvariable midi(progexlist) -font $df -state disabled
grid $w.checkexclude $w.labexprog $w.excludein -sticky nsew

checkbutton $w.checkprog -variable searchstate(cprog) -command matchprogs
label $w.labprog -text "matches programs" -font $df
label $w.labprogthr -text "threshold" -font $df
scale $w.scaleprogthr -length 120 -from 0.0 -to 0.40 -orient horizontal\
  -resolution 0.005 -width 9 -variable midi(progthr) -font $df
grid $w.checkprog $w.labprog $w.scaleprogthr $w.labprogthr -sticky nsew


checkbutton $w.checkpcol -variable searchstate(cpcol) -command searchpcol
label $w.labpcol -text "matches program color" -font $df
label $w.labpcolthr -text "threshold" -font $df
scale $w.scalepcolthr -length 120 -from 0.0 -to 0.40 -orient horizontal\
  -resolution 0.005 -width 9 -variable midi(pcolthr) -font $df
grid $w.checkpcol $w.labpcol $w.scalepcolthr $w.labpcolthr -sticky nsew

checkbutton $w.checkpitch -variable searchstate(cpitch) -command searchpitch
label $w.labpitch -text "matches pitch class" -font $df
scale $w.scalepitchthr -length 120 -from 0.0 -to 0.40 -orient horizontal\
  -resolution 0.005 -width 9 -variable midi(pitchthr) -font $df
label $w.labpitchthr -text "threshold" -font $df
grid $w.checkpitch $w.labpitch $w.scalepitchthr $w.labpitchthr -sticky nsew

checkbutton $w.checktempo -variable searchstate(ctempo) -command searchtempo
label $w.labtempo -text "tempo is " -font $df 
scale $w.scaletempo -length 120 -from 40 -to 300 -orient horizontal\
  -resolution 10 -width 9 -variable midi(tempo) -font $df
label $w.labbeats -text "beats/minute" -font $df
grid $w.checktempo $w.labtempo $w.scaletempo  $w.labbeats -sticky nsew

checkbutton $w.cbends -variable searchstate(cbends) -command searchbends
label $w.labnbends -text "at least" -font $df
scale $w.scalebends -length 120 -from 500 -to 10000 -orient horizontal\
  -resolution 100 -width 9 -variable midi(nbends) -font $df
label $w.labbends -text "pitchbends" -font $df
grid $w.cbends $w.labnbends $w.scalebends $w.labbends -sticky nsew

checkbutton $w.checkndrums -variable searchstate(cndrums) -command searchndrums
label $w.labndrums -text "approximately" -font $df
scale $w.scaledrums -length 120 -from 2 -to 45 -orient horizontal\
  -resolution 1 -width 9 -variable midi(ndrums) -font $df
label $w.labndrums2 -text "percussion instruments" -font $df
grid $w.checkndrums $w.labndrums $w.scaledrums $w.labndrums2 -sticky nsew


checkbutton $w.checkpitchentropy -variable searchstate(cpitche) \
  -command searchpitche
label $w.labpitche -text "pitch entropy" -font $df
scale $w.scapitche -length 150 -from 1.6 -to 3.8 -orient horizontal\
  -resolution 0.05 -width 9 -variable midi(pitche) -font $df
grid $w.checkpitchentropy $w.labpitche $w.scapitche

set state {{cname sname} {ctempo tempo} {checkprogs proglist} {cbends nbends} {cndrums ndrums} {cpcol pcolthr} {cpitch pitchthr} {cpitche pitche}}

enable_disable_search_entries
  
button $w.scan -text scan -font $df -command scan_desc
label $w.msg -text "" -font $df
button $w.help -text help -font $df -command {show_message_page $hlp_search word}
grid $w.scan $w.msg $w.help
}

set hlp_search "This window allows you to search the entire midi\
collection in this root folder for midi files which satistfy\
certain properties. Tick the checkboxes of the properties of\
interest and specify the limits or values for those properties.

If you have not already done so, prior to running this search\
tool, you need to create a database of all the midi file\
descriptors. This data base is stored in the tab separated\
file called MidiDescriptors.txt. The file is stored in the\
same folder as the root folder; so you can have separate\
databases for the different root folders. Note that since\
that for large collections of midi files it may take some\
time to scan all the midi files and extract all the\
information for the database. Defective midi files will\
also be detected during this scan and will not be included\
in the database. (You can get a list of those files from\
the Utilities menu button. Clicking on those files will\
provide more information about those files.)

Once you have selected the properties of interest,\
you can now scan the database. Midi files that satisfy your\
criteria will be listed. For some features, a plot\
showing the distribution of the matching criteria may\
pop up. If more than 200 midi files match your criteria,\
then a random selection of those midi files will be displayed.\
Doing another scan with display a different random set.

You may order these files by clicking on the criterion\
heading. Clicking on one of those files will display the\
characteristics of this file in the lower frame of the\
main window.
"



proc switch_criterion {} {
searchpcol
searchpitch
matchprogs
}


proc enable_disable_search_entries {} {
  searchname
  searchprogs
  matchprogs
  searchperc
  searchex
  searchpcol 
  searchpitch
  }
  


proc searchname {} {
global sname
global searchstate
if {$searchstate(cname)} {
   .searchbox.name configure -state normal
   } else {
   .searchbox.name configure -state disabled
   }
}

proc searchtempo {} {
global searchstate
if {$searchstate(ctempo)} {
   .searchbox.scaletempo configure -state normal
   } else {
   .searchbox.scaletempo configure -state disabled
   }
}

proc searchprogs {} {
global searchstate
if {$searchstate(checkprogs)} {
   .searchbox.progsin configure -state readonly
   } else {
   .searchbox.progsin configure -state disabled
   }
}

proc searchperc {} {
global searchstate
if {$searchstate(checkperc)} {
   .searchbox.percin configure -state readonly
   } else {
   .searchbox.percin configure -state disabled
   }
}

proc searchex {} {
global searchstate
if {$searchstate(checkexclude)} {
   .searchbox.excludein configure -state normal
   } else {
   .searchbox.excludein configure -state disabled
   }
}

proc searchbends {} {
global searchstate 
if {$searchstate(cbends)} {
   .searchbox.scalebends configure -state normal
   } else {
   .searchbox.scalebends configure -state disabled
   }
}

proc searchndrums {} {
global searchstate 
if {$searchstate(cndrums)} {
   .searchbox.scaledrums configure -state normal
   } else {
   .searchbox.scaledrums configure -state disabled
   }
}

proc matchprogs {} {
global searchstate cprogs
global midi
if {![info exist cprogs] && $searchstate(cprog)} {
   .searchbox.msg configure -text "You need to select a midi file first." -fg red 
    set searchstate(cprog) 0
    return
    }
if {$searchstate(cprog) == 1} {
  set searchstate(cpcol) 0
  if {$midi(matchcriterion) == 1} {
    set searchstate(cprog1) 1
    set searchstate(cprog2) 0
    } else {
    set searchstate(cprog1) 0
    set searchstate(cprog2) 1
    }
  } else {
  set searchstate(cprog1) 0
  set searchstate(cprog2) 0
  }
}

proc searchpcol {} {
global searchstate cprogcolor
global midi
if {![info exist cprogcolor] && $searchstate(cpcol)} {
   .searchbox.msg configure -text "You need to select a midi file first." -fg red 
    set searchstate(cpcol) 0
    return
    }
if {$searchstate(cpcol) == 1} {
  set searchstate(cprog) 0
  if {$midi(matchcriterion) == 1} {
    set searchstate(cpcol1) 1
    set searchstate(cpcol2) 0
    } else {
    set searchstate(cpcol1) 0
    set searchstate(cpcol2) 1
    }
  } else {
  set searchstate(cpcol1) 0
  set searchstate(cpcol2) 0
  }
}

proc searchpitch {} {
global searchstate pitchcl
global midi
if {![info exist pitchcl] && $searchstate(cpitch)} {
   .searchbox.msg configure -text "You need to select a midi file first." -fg red 
    set searchstate(cpitch) 0
    return
    }
if {$searchstate(cpitch) == 1} {
  if {$midi(matchcriterion) == 1} {
    set searchstate(cpitch1) 1
    set searchstate(cpitch2) 0
    } else {
    set searchstate(cpitch1) 0
    set searchstate(cpitch2) 1
    }
  } else {
  set searchstate(cpitch1) 0
  set searchstate(cpitch2) 0
  }
}

proc searchpitche {} {
global searchstate
if {$searchstate(cpitche)} {
   .searchbox.scapitche configure -state normal
   } else {
   .searchbox.scapitche configure -state disabled
   }
}

set filter_code(cname) "if \{\[match_title \$item\] < 0\} \{return 0\}"
set filter_code(ctempo) "if \{\[match_tempo \$item\] == -1\} \{return 0\}"
set filter_code(checkprogs) "if \{\[dict exists \$desc(\$item) progs] && \[list_in_list \$midi(proglist) \[dict get \$desc(\$item) progs\]\] == 0\} \{return 0\}"
set filter_code(checkperc) "if \{\[list_in_list \$midi(drumlist) \[dict get \$desc(\$item) drums\]\] == 0\} \{return 0\}"
set filter_code(checkexclude) "return \[list_not_in_list \$midi(progexlist) \[dict get \$desc(\$item) progs\]\]"
set filter_code(cbends) "if \{\[dict get \$desc(\$item) pitchbend\] < \$midi(nbends)\} \{return 0\}"
set filter_code(cndrums) "if \{\[match_ndrums \$item\] == -1\} \{return 0\}"
set filter_code(cprog1) "if \{\[correlate_progs \$item\] > \$midi(progthr) \} \{
return 0\}"
set filter_code(cprog2) "if \{\[mse_progs \$item\] > \$midi(progthr) \} \{
return 0\}"
set filter_code(cpcol1) "if \{\[match_progcolor_dot \$item\] > \$midi(pcolthr) \} \{
return 0\}"
set filter_code(cpitch1) "if \{\[match_pitchclass_dot \$item\] > \$midi(pitchthr) \} \{
return 0\}"
set filter_code(cpcol2) "if \{\[match_progcolor_mse \$item\] > \$midi(pcolthr) \} \{
return 0\}"
set filter_code(cpitch2) "if \{\[match_pitchclass_mse \$item\] > \$midi(pitchthr) \} \{
return 0\}"
set filter_code(cpitche) "if \{\[match_pitch_entropy \$item\] == -1\} \{return 0\}"


proc expand_proglist {proglist} {
global mlist
set prognames ""
foreach prog $proglist {
  append prognames "[lindex $mlist $prog], " 
  }
return "That is $prognames\n"
}


proc expand_drumlist {drumlist} {
global drumpatches
set drumnames ""
foreach drum $drumlist {
  set elem [lindex $drumpatches [expr $drum -35]]
  append drumnames "[lindex $elem 0] [lindex $elem 2]\n" 
  }
return "That is \n$drumnames"
}

proc describe_filter {} {
global searchstate
global midi
set w .info.txt
$w delete 2.0 end
$w insert insert "\nSearching for midi files which satisfy all of these conditions.\n"
if {$searchstate(cname)} {
  $w insert insert "The file name contains the string '$midi(sname)'\n"
  }
if {$searchstate(ctempo)} {
  $w insert insert "The tempo lies between [expr $midi(tempo) -10] and [expr $midi(tempo) + 10]  beats/minute.\n"
  }
if {$searchstate(checkprogs)} {
  $w insert insert "The programs $midi(proglist) are all present. "
  $w insert insert [expand_proglist $midi(proglist)]
  }
if {$searchstate(checkperc)} {
  $w insert insert "The percussion codes $midi(drumlist) are all present. "
  $w insert insert [expand_drumlist $midi(drumlist)]
  }
if {$searchstate(cbends)} {
  $w insert insert "There are exist $midi(nbends) pitchbend commands present.\n"
  }
if {$searchstate(cndrums)} {
  $w insert insert "There are approximately $midi(ndrums) percussion instruments present.\n" 
  }
if {$searchstate(cpcol)} {
  $w insert insert "Matching the program color.\n" 
  }
if {$searchstate(cprog)} {
  $w insert insert "Matching the program activity.\n" 
  }
if {$searchstate(cpitch)} {
  $w insert insert "Matching the pitch class distribution.\n" 
  }
if {$searchstate(cpitche)} {
  $w insert insert "The pitch class entropy lies between [expr $midi(pitche) -0.05] and [format %5.2f [expr $midi(pitche) + 0.05]].\n"}
}

proc init_match_histogram {} {
global match_hist
for {set i 0} {$i < 101} {incr i} {
  set match_hist($i) 0
  }
}


proc dump_match_histogram {} {
global match_hist
for {set i 0} {$i < 101} {incr i} {
  puts "$i $match_hist($i)"
  }
}


proc plot_match_histogram {} {
    global df
    global match_hist
    global midi
    #dump_match_histogram
    set graph .graph.c
    if {[winfo exists .graph] == 0} {
        toplevel .graph
        positionWindow .graph
        pack [canvas $graph]
    } else {
        $graph delete all}
    raise .graph .
    set start 0.0
    set stop  0.4
    set delta_tick 50
    $graph create rectangle 50 20 350 200 -outline black\
            -width 2 -fill white
    Graph::alter_transformation 50 350 200 20 $start $stop 0.0 3.10
    Graph::draw_x_ticks $graph $start $stop 0.05 1  0 %4.2f
    set iyb [Graph::iypos 0.0]
    for {set i 0} {$i < 40} {incr i} {
      set y $match_hist($i)
      if {$y > 1000} {set y 1000}
      set ix [Graph::ixpos [expr double($i)/100.0]]
      set ix2 [Graph::ixpos [expr double($i+1)/100.0]]
      set y [expr log10($y+1.0)]
      set iy  [Graph::iypos $y]
      $graph create rectangle $ix $iyb $ix2 $iy -fill lightblue
      }
    Graph::draw_y_log10ticks $graph 0.0 3.0 %3.0f
    $graph create text 200 240 -text "matching criterion" -font $df
    }


proc prepare_filter {} {
global searchstate
global filter_code
global desc

if {$searchstate(cpcol)} {init_match_histogram}
if {$searchstate(cpitch)} {init_match_histogram}
if {$searchstate(cprog)} {init_match_histogram}

set revised_procedure "proc filter_files {item} \{\n"

append  revised_procedure "global searchstate desc midi\n"
append revised_procedure "if \{\[dict exists \$desc(\$item) damaged\]\} \{return 0\}"


set i 0
foreach item {cname ctempo checkprogs checkperc checkexclude cbends cndrums cpcol1 cpcol2 cpitch1 cpitch2 cpitche cprog1 cprog2} {
  if {$searchstate($item) > 0} {
     append revised_procedure "\n$filter_code($item)"
     incr i
     }
   }
 append revised_procedure "\nreturn 1\}"
if {$i == 0} {return 0}

eval $revised_procedure
#puts [info body filter_files]
return $i
}


proc dotproduct {vec1 vec2} {
 set sum 0.0
 foreach v1 $vec1 v2 $vec2 {
   set sum [expr $sum + ($v1*$v2)]
   }
 return $sum
}



proc root_mean_square_error {vec1 vec2} {
 set sum 0.0
 set k 0
 foreach v1 $vec1 v2 $vec2 {
   set sum [expr $sum + pow(($v1 - $v2),2)]
   incr k
   }
 set sum [expr sqrt($sum/$k)]
 return $sum
}


proc correlate_progs {item} {
global cprogsact
global cprogs
global match_hist
global desc
global rcriterion
#puts "item = $item"
if {[dict exist $desc($item) progs] == 0} {return 1.0}
set prg [dict get $desc($item) progs]
set prgact [dict get $desc($item) progsact]
set p2 0.0
set p3 0.0
foreach p $prg pa $prgact {
  set p2 [expr $p2 + $pa*$pa]
  set loc [lsearch $cprogs $p]
  if {$loc <0} {
    continue} else {
    set cpa [lindex $cprogsact $loc]
    set p3 [expr $p3 + $cpa*$pa]
    }
  }
set p2 [expr sqrt($p2)]
set r [expr 1.0 - $p3/$p2]  
if {$r <0.0} {set r 0.0001}
set rcriterion [format %5.3f $r]
set r100 [expr int(floor($r*100))]
set match_hist($r100) [expr $match_hist($r100) + 1]
return $r
}

proc mse_progs {item} {
global cprogsact
global cprogs
global match_hist
global desc
global rcriterion
#puts "item = $item"
if {[dict exist $desc($item) progs] == 0} {return 1.0}
set prg [dict get $desc($item) progs]
set prgact [dict get $desc($item) progsact]
set p2 0.0
set p3 0.0
#normalize prgact
foreach  pa $prgact {
  set p2 [expr $p2 + $pa*$pa]
  }
set p2 [expr sqrt($p2)]

set combinedprg [lsort -unique [concat $prg $cprogs]]

set prgact [normalize_activity $prgact]

#puts "combinedprg $combinedprg\n\n"

foreach p $combinedprg {
  set loc [lsearch $cprogs $p]
  if {$loc <0} {
      set cpa 0.0
      } else {
      set cpa [lindex $cprogsact $loc]
      }

  set loc [lsearch $prg $p]
  if {$loc <0} {
      set pa 0.0
      } else {
      set pa [lindex $prgact $loc]
      }

  set d [expr $cpa - $pa]
  set p3 [expr $p3 + $d*$d]
  #puts "$p $cpa $pa $d $p3"

  if {$p3 > 1.0} break
  }
set r  [expr sqrt($p3)] 

if {$r <0.0} {set r 0.0001}
set rcriterion [format %5.3f $r]
set r100 [expr int(floor($r*100))]
if {$r100 > 100} {set r100 100}
set match_hist($r100) [expr $match_hist($r100) + 1]
return $r
}


proc match_progcolor_dot {item} {
global cprogcolor
global match_hist
global desc
global rcriterion
#puts "item = $item"
set pcol [dict get $desc($item) progcolor]
set r [expr 1.0 - [dotproduct $cprogcolor $pcol]]
set rcriterion [format %5.3f $r]
if {$r <0.0} {set r 0.0001}
set r100 [expr int(floor($r * 100))]
set match_hist($r100) [expr $match_hist($r100) + 1]
return $r
}

proc match_progcolor_mse {item} {
global cprogcolor
global match_hist
global desc
global rcriterion
set pcol [dict get $desc($item) progcolor]
set r [root_mean_square_error $cprogcolor $pcol]
set rcriterion [format %5.3f $r]
set r100 [expr int(floor($r * 100))]
set match_hist($r100) [expr $match_hist($r100) + 1]
return $r
}

proc match_pitchclass_dot {item} {
global pitchcl
global match_hist
global desc
global rcriterion
set pcol [dict get $desc($item) pitches]
set r [expr 1 - [dotproduct $pitchcl $pcol]]
if {$r <0.0} {set r 0.0001}
set rcriterion [format %5.3f $r]
set r100 [expr int(floor($r * 100))]
set match_hist($r100) [expr $match_hist($r100) + 1]
return $r
}

proc match_pitchclass_mse {item} {
global pitchcl
global match_hist
global desc
global rcriterion
set pcol [dict get $desc($item) pitches]
set r [root_mean_square_error $pitchcl $pcol]
set rcriterion [format %5.3f $r]
set r100 [expr int(floor($r * 100))]
set match_hist($r100) [expr $match_hist($r100) + 1]
return $r
}

proc match_pitch_entropy {item} {
global midi
global desc
set min_entropy [expr $midi(pitche) -0.05]
set max_entropy [expr $midi(pitche) +0.05]
set pe [dict get $desc($item) pitchentropy]
if {$pe < $min_entropy || $pe > $max_entropy} {return -1}
return 1
}

proc match_tempo {item} {
global midi
global desc
set min_tempo [expr $midi(tempo) -10]
set max_tempo [expr $midi(tempo) +10]
set t [dict get $desc($item) tempo]
if {$t < $min_tempo || $t > $max_tempo} {return -1}
return 1
}

proc match_ndrums {item} {
global midi
global desc
set mindrums [expr $midi(ndrums) - 1]
set maxdrums [expr $midi(ndrums) + 1]
set ndrums [llength [dict get $desc($item) drums]]
if {$ndrums < $mindrums || $ndrums > $maxdrums} {return -1}
return 1
}

proc match_title {item} {
global desc
global midi
set needle [string tolower $midi(sname)]
set haystack [string tolower [dict get $desc($item) file]]
return [string first $needle $haystack]
}


proc find_bad_files {} {
global desc
global midi
if {[llength [.treebrowser.tree children {}]] > 0} {
  .treebrowser.tree delete [.treebrowser.tree children {}] }
load_desc
set descsize [array size desc]
for {set i 1} {$i < $descsize} {incr i} {
  if {[expr $i % 100] == 0} {
    update} 
  if {[dict exists $desc($i) damaged]} {
     set midifile [dict get $desc($i) file]
     set id [.treebrowser.tree insert {} end -text $midifile -values [list $midifile "file"]]
      }
  }
set ndefective [llength [.treebrowser.tree children {}]]
set msg "$ndefective defective files were found"
.info.txt insert insert "$msg\n"
}

proc index_window {} {
global df
global indexnum
set w .indexwindow
if {![winfo exist $w]} {
  toplevel $w
  positionWindow $w
  set indexnum 1
  frame $w.indexframe
  label $w.indexframe.lab -text "enter database index number" -font $df
  entry $w.indexframe.ent -width 6 -font $df -textvariable indexnum
  pack $w.indexframe.lab $w.indexframe.ent -side left
  pack $w.indexframe
  button $w.select -text select -command find_indexed_file
  pack $w.select
  bind $w.indexframe.ent <Return> find_indexed_file
  } else {
  raise $w .
  }
}

proc find_indexed_file {} {
global indexnum
global desc
if {[llength [.treebrowser.tree children {}]] > 0} {
  .treebrowser.tree delete [.treebrowser.tree children {}]
  }
load_desc
set midifile [dict get $desc($indexnum) file]
set id [.treebrowser.tree insert {} end -text $midifile -values [list $midifile "file"]]
.treebrowser.tree selection set $id
focus .indexwindow.select
}

proc count_filtered_files {} {
global desc
set descsize [array size desc]
set j 0 
for {set i 1} {$i < $descsize} {incr i} {
  if {[expr $i % 100] == 0} {
    set value [expr double($i)/$descsize]
    .status.progress configure -value $value
    update} 
  if {[filter_files $i]} {
     incr j
     }
  }
set msg "$j files were found which satisfied these conditions.\n"
.info.txt insert insert "$msg"
return $j
}


proc scan_desc {} {
global desc
global searchstate
global midi
global rcriterion
#global rootnode
set rootfolder $midi(rootfolder)
set rootfolderbytes [string length $rootfolder]
set n [prepare_filter]
if {$n < 1} {.searchbox.msg configure -text "First check one of the boxes"\
 -foreground red
 return
 } else {
  .searchbox.msg configure -text ""}
describe_filter
.treebrowser.tree tag configure purple -foreground purple

if {[llength [.treebrowser.tree children {}]] > 0} {
  .treebrowser.tree delete [.treebrowser.tree children {}] }
set position 0
set descsize [array size desc]
set j 0 
if {[winfo exist .status]} {destroy .status}
frame .status
ttk::progressbar .status.progress -mode determinate -length 200\
 -value 0 -maximum 1.0
grid .status.progress
pack .status
.status.progress start
set nfiles [count_filtered_files]
if {$descsize < 2} {.info.txt insert insert "midi descriptors are empty\n\n" red
              	   .searchbox.msg configure -text "First create database" -fg red} else {.searchbox.msg configure -text ""}

set threshold [expr 50.0 /$nfiles]
if {$threshold > 1.0} {set threshold 1.0}
if {[file exist $midi(midifilein)]} {
  set size [file size $midi(midifilein)]
  set size [formatSize $size] 
  } else {
   set size 20
  }
set id [.treebrowser.tree insert {} end -text $midi(midifilein) -values [list $midi(midifilein) file $size 0.0 "" $position] -tag purple]
for {set i 1} {$i < $descsize} {incr i} {
  #puts $i
  if {[expr $i % 100] == 0} {
    set value [expr double($i)/$descsize]
    .status.progress configure -value $value
    update} 
  if {[filter_files $i] && rand() < $threshold} {
     incr j
     if {$j > 200} break
     set midifile [dict get $desc($i) file]
     set compactMidifile [string range $midifile $rootfolderbytes end]
     set id [.treebrowser.tree insert {} end -text $compactMidifile -values [list $midifile "file" 0.0 "" $position]]
     incr position
     if {[file exist $midifile]} {
       set size [file size $midifile]
            ## Format the file size nicely
              if {$size >= 1024*1024*1024} {
                set size [format %.1f\ GB [expr {$size/1024/1024/1024.}]]
              } elseif {$size >= 1024*1024} {
                set size [format %.1f\ MB [expr {$size/1024/1024.}]]
              } elseif {$size >= 1024} {
                set size [format %.1f\ kB [expr {$size/1024.}]]
              } else {
                append size " bytes"
              }
      .treebrowser.tree set $id size $size
      if {[expr $searchstate(cpcol)+$searchstate(cpitch)+$searchstate(cprog)] == 1} {
         .treebrowser.tree set $id criterion $rcriterion
         } else { 
        .treebrowser.tree set $id criterion ""
         }
      }
    }
  }
 
set msg "[llength [.treebrowser.tree children {}]] files were inserted in list.\nScan again to get a different selection.\n"
.info.txt insert insert "$msg\n"
destroy .status.progress
destroy .status
if {[expr $searchstate(cpcol)+$searchstate(cpitch)]+$searchstate(cprog) == 1} plot_match_histogram
}


  
proc list_in_list {a b} {
  foreach item $a {
    if {[lsearch $b $item] <0 } {return 0}
    }
  return 1
  }

proc list_not_in_list {a b} {
  foreach item $a {
    if {[lsearch $b $item] >=0 } {return 0}
    }
  return 1
  }



proc filter_desc {item} {
# for testing call filter_desc instead of filter_files
  global desc
  set programs [dict get $desc($item) programs]
  if {[lsearch $programs 25] < 0 } {
    return 0
    }
  
  return 1
  } 


# export csv
proc export_drum_to_csv {} {
global desc
global midi
load_desc
set descsize [array size desc]
set csvfile [file join $midi(rootfolder) drum.csv]
set outhandle [open $csvfile w]
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set feat [dict get $desc($i) drums]
  puts -nonewline $outhandle "$i, "
  for {set j 35} {$j < 82} {incr j} {
    set drumdata($j) 0
    }
  foreach feature $feat {
    set drumdata($feature) 1
    }
  for {set j 35} {$j < 81} {incr j} {
    puts -nonewline $outhandle "$drumdata($j),"
    }
  puts $outhandle $drumdata(81)
  }
close $outhandle 
SwitchBetweenInfoAndTinfo 
.info.txt insert insert "\ndata stored in $csvfile"
}

proc export_drum_hits_to_csv {} {
global desc
global midi
load_desc
set descsize [array size desc]
set csvfile [file join $midi(rootfolder) drumhits.csv]
set outhandle [open $csvfile w]
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  #puts [dict keys $desc($i)]
  set feat [dict get $desc($i) drums]
  if {[dict exists $desc($i) drumhits] == 0} continue
  set hits [dict get $desc($i) drumhits]
  puts -nonewline $outhandle "$i, "
  
  for {set j 35} {$j < 82} {incr j} {
    set drumdata($j) 0
    }
  foreach feature $feat hit $hits {
    set drumdata($feature) $hit
    }
  for {set j 35} {$j < 81} {incr j} {
    puts -nonewline $outhandle "$drumdata($j),"
    }
  puts $outhandle $drumdata(81)
  #puts $feat
  }
close $outhandle
SwitchBetweenInfoAndTinfo 
.info.txt insert insert "\ndata stored in $csvfile"
}

proc export_progcolor_to_csv {} {
global desc
global midi
load_desc
set descsize [array size desc]
set csvfile [file join $midi(rootfolder) progcolor.csv]
set outhandle [open $csvfile w]
puts $outhandle "i ,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17"
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set feat [dict get $desc($i) progcolor]
  puts -nonewline $outhandle "$i, "
  set j 0
  foreach feature $feat {
    if {$j < 16} {
      puts -nonewline $outhandle "$feature," 
      } else {
      puts -nonewline $outhandle "$feature" 
      }
    incr j
    }
  puts $outhandle ""
  
  #puts $feat
  }
close $outhandle
SwitchBetweenInfoAndTinfo 
.info.txt insert insert "\ndata stored in $csvfile"
}

proc export_progs_to_csv {normalize} {
global desc
global midi
load_desc
set descsize [array size desc]
set csvfile [file join $midi(rootfolder) progs.csv]
set outhandle [open $csvfile w]
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  #puts [dict keys $desc($i)]
  if {[dict exists $desc($i) progs] == 0} continue
  set feat [dict get $desc($i) progs]
  #if {[dict exists $desc($i) progsact] == 0} continue
  set activity [dict get $desc($i) progsact]
  puts -nonewline $outhandle "$i, "

  for {set j 0} {$j < 128} {incr j} {
    set progdata($j) 0
    }

  set sum2 0.0
  if {$normalize} {
   foreach act $activity {
     set sum2 [expr $sum2 + $act*$act]
     }
   set sum2 [expr sqrt($sum2)]
   }

  foreach feat $feat act $activity {
    if {$sum2 == 0.0} {
      set progdata($feat) $act
    } else {
      set progdata($feat) [format %5.3f [expr $act/$sum2]]
    }
  }
  for {set j 0} {$j < 127} {incr j} {
    puts -nonewline $outhandle "$progdata($j),"
    }
  puts $outhandle $progdata(127)
  #puts $feat
  }
close $outhandle
SwitchBetweenInfoAndTinfo 
.info.txt insert insert "\ndata stored in $csvfile"
}

proc export_pitches_to_csv {} {
global desc
global midi
load_desc
set descsize [array size desc]
set csvfile [file join $midi(rootfolder) pitches.csv]
set outhandle [open $csvfile w]
#set outhandle stdout
puts $outhandle "i, C,C#,D,D#,E,F,F#,G,G#,A,A#,B"
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set feat [dict get $desc($i) pitches]
  puts -nonewline $outhandle "$i, "
  set j 0  
  foreach feature $feat {
    if {$j < 11} {
      puts -nonewline $outhandle "$feature," 
      } else {
      puts -nonewline $outhandle "$feature" 
      }
      incr j
    }
  puts $outhandle ""
  #puts $feat
  }
close $outhandle
SwitchBetweenInfoAndTinfo 
.info.txt insert insert "\ndata stored in $csvfile"
}

proc export_info_to_tsv {} {
global desc
global midi
load_desc
set descsize [array size desc]
set csvfile [file join $midi(rootfolder) info.tsv]
set outhandle [open $csvfile w]
#set outhandle stdout
puts $outhandle "i\tnbeats\ttempo\tpitchbend\tpitchentropy\tndrums\tfile"
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set tempo [dict get $desc($i) tempo]
  set pitchbends [dict get $desc($i) pitchbend]
  set pitchentropy [dict get $desc($i) pitchentropy]
  set filepath [dict get $desc($i) file]
  set ndrums [llength [dict get $desc($i) drums]]
  set nbeats [dict get $desc($i) midilength]
  puts $outhandle "$i\t$nbeats\t$tempo\t$pitchbends\t$pitchentropy\t$ndrums\t$filepath"
  }
close $outhandle
SwitchBetweenInfoAndTinfo 
.info.txt insert insert "\ndata stored in $csvfile"
}

proc export_fileindex {} {
global desc
global midi
load_desc
set descsize [array size desc]
set csvfile [file join $midi(rootfolder) fileindex.tsv]
set outhandle [open $csvfile w]
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set filepath [dict get $desc($i) file]
  puts $outhandle "$i\t$filepath"
  }
close $outhandle
SwitchBetweenInfoAndTinfo 
.info.txt insert insert "\ndata stored in $csvfile"
}


proc export_list_of_defective_files {} {
global desc
global midi
set csvfile [file join $midi(rootfolder) badfiles.txt]
set outhandle [open $csvfile w]
if {[llength [.treebrowser.tree children {}]] > 0} {
  .treebrowser.tree delete [.treebrowser.tree children {}] }
load_desc
set descsize [array size desc]
for {set i 1} {$i < $descsize} {incr i} {
  if {[expr $i % 100] == 0} {
    update} 
  if {[dict exists $desc($i) damaged]} {
     set midifile [dict get $desc($i) file]
     puts $outhandle $midifile
     }
  }
close $outhandle
puts "created $csvfile"
}

proc wikipedia_window {} {
global df
global genre_entry
if {[winfo exists .wiki] == 0} {
  toplevel .wiki
  positionWindow .wiki
  text .wiki.t -height 10 -width 50 -font $df
  frame .wiki.f
  button .wiki.f.b -text "search wikipedia" -command {open_wikipedia} -font $df 
  entry .wiki.f.e -textvariable genre_entry -width 25 -font $df
  pack .wiki.f.b .wiki.f.e -side top
  pack .wiki.t .wiki.f -side left
  bind .wiki.f.e <Return> {enter_genre}
  } else {
  .wiki.t delete 1.0 end
  set genre_entry ""
  update
  }
}

proc enter_genre {} {
global genre_entry
global tune
global genre_db
get_tune 
set genre_db($tune) $genre_entry
puts "genre_db($tune) $genre_db($tune)"
}

proc get_tune {} {
global tune
global midi
set len [string length $midi(rootfolder)]
incr len 
set tune $midi(midifilein)
set tune [string range $tune $len end]
set tune [file rootname $tune]
set tune [split $tune .]
set tune [lindex $tune 0]
puts $tune
}

proc open_wikipedia {} {
global midi
global tune
set len [string length $midi(rootfolder)]
incr len 
get_tune
set tunelist [split $tune /]
set tail "&title=Special:Search&go=Go"

set searchstring ""
set plus "+"
foreach word  [lindex $tunelist 0] {
  set searchstring $searchstring$word$plus
  }
set searchstring [string range $searchstring 0 end-1]
set searchstring $searchstring$tail
#puts $searchstring
set url https://en.wikipedia.org/w/index.php?search=$searchstring
#puts $url
set cmd "exec [list $midi(browser)] $url &"
catch {eval $cmd} result
}

proc initialize_genre_database {} {
global desc
global midi
load_desc
set descsize [array size desc]
set csvfile [file join $midi(rootfolder) genre.tsv]
set outhandle [open $csvfile w]
set len [string length $midi(rootfolder)]
incr len 
set lastfilepath ""
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set filepath [dict get $desc($i) file]
  set filepath [string range $filepath $len end]
  set filepath [file rootname $filepath]
  set filepath [split $filepath .]
  set filepath [lindex $filepath 0]
  if {[string equal $filepath $lastfilepath]} continue
  set lastfilepath $filepath
  puts $outhandle "$filepath\t 0"
  }
close $outhandle
}


proc update_genre_database {} {
global desc
global midi
global genre_db
load_desc
set descsize [array size desc]
set csvfile [file join $midi(rootfolder) genre.tsv]
file delete tmp.tsv
file rename $csvfile tmp.tsv
set outhandle [open $csvfile w]
set len [string length $midi(rootfolder)]
incr len 
set lastfilepath ""
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set filepath [dict get $desc($i) file]
  set filepath [string range $filepath $len end]
  set filepath [file rootname $filepath]
  set filepath [split $filepath .]
  set filepath [lindex $filepath 0]
  if {[string equal $filepath $lastfilepath]} continue
  set lastfilepath $filepath
  if {[info exist genre_db($filepath)]} {
	  set genre_db($filepath) [string trimleft $genre_db($filepath)]
          puts $outhandle "$filepath\t$genre_db($filepath)"
          }
  #puts  "$filepath\t $genre_db($filepath)"
  }
close $outhandle
#puts "updated genre.tsv"
}


proc load_genre_database {} {
global genre_db
global midi
if {[array exist genre_db]} return
set genrefile [file join $midi(rootfolder) genre.tsv]
if {![file exist $genrefile]} {initialize_genre_database}
set inhandle [open $genrefile]
while {![eof $inhandle]} {
  gets $inhandle line
  set data [split $line \t]
  set genre_db([lindex $data 0]) [lindex $data 1] 
  }
close $inhandle
} 


proc restore_root_folder {} {
global midi
.treebrowser.tree delete [.treebrowser.tree children {}]
populatedir .treebrowser.tree $midi(rootfolder)
}

# end ReadMidiDescriptors

proc univariateDistribution {featname max_x xspace xlabel} {
global desc
load_desc
array unset featcount
set minval 500
set maxval 0
set descsize [array size desc]
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set feat [dict get $desc($i) $featname]
  set feat [expr int($feat)]
  if {![info exist featcount($feat)]} {
     set featcount($feat) 1
     } else {
     set featcount($feat)  [expr $featcount($feat) + 1]
#     if {$feat > $maxval} {set maxval $feat}
#     if {$feat < $minval} {set minval $feat}
     }
  }
for {set i 0} {$i <= $max_x} {incr i} {
  if {![info exist featcount($i)]} {
      set featcount($i) 0
      }
  }
# cumulative distribution
for {set i 0} {$i < $max_x} {incr i} {
  set i1 [expr $i +1]
  set featcount($i1) [expr $featcount($i) + $featcount($i1)]
  }
set curve {}
set norm [expr double($featcount($max_x))]
for {set i 0} {$i < $max_x} {incr i} {
  set x $i
  set y [expr $featcount($i)/$norm]
  set p [list $x $y] 
  lappend curve $p
  }
#puts $curve
set graph .graph.c
  if {[winfo exists .graph] == 0} {
      toplevel .graph
      positionWindow .graph
      pack [canvas $graph]
  } else {
      $graph delete all}
raise .graph .
plotUnivariateDistribution $graph $curve 0.0 $max_x $xspace $xlabel
}


proc plotUnivariateDistribution {graph curve min_x max_x xspace xlabel} {
    global df
    set start $min_x
    set stop  $max_x
    set delta_tick 50
    $graph create rectangle 70 20 370 200 -outline black\
            -width 2 -fill white
    Graph::alter_transformation 70 370 200 20 $start $stop 0.0 1.0
    Graph::draw_x_grid $graph $start $stop $xspace 1  0 %4.1f
    Graph::draw_y_grid $graph 0.0 1.0 0.2 1 %3.2f
    set npoints [expr [llength $curve ] -1]
    for {set i 0} {$i < $npoints} {incr i} {
        set datapoint0 [lindex $curve $i]
        if {$datapoint0 < $min_x} continue
        set j [expr $i+1]
        set datapoint1 [lindex $curve $j]
        #puts "datapoints $datapoint0 $datapoint1"
        set x1 [lindex $datapoint0 0]
        set y1 [lindex $datapoint0 1]
        set x2 [lindex $datapoint1 0]
        set y2 [lindex $datapoint1 1]
        set ix1 [Graph::ixpos $x1]
        set iy1 [Graph::iypos $y1]
        set ix2 [Graph::ixpos $x2]
        set iy2 [Graph::iypos $y2]
        $graph create line $ix1 $iy1 $ix2 $iy2 
        }
    set iy1 [Graph::iypos -0.2]
    set ix1 200
    $graph create text $ix1 $iy1 -text $xlabel -font $df
}

proc plot_line_graph {graph curve min_x max_x xspace xlabel min_y max_y title} {
    global df
    if {[winfo exists $graph] == 1} {$graph delete all}
    set start [expr double($min_x)]
    set stop  [expr double($max_x)]
    $graph create rectangle 70 20 370 200 -outline black\
            -width 2 -fill white
    set yspace [expr ($max_y - $min_y)/5.0]
    Graph::alter_transformation 70 370 200 20 $start $stop $min_y $max_y
    Graph::draw_x_grid $graph $start $stop $xspace 1  0 %4.1f
    Graph::draw_y_grid $graph $min_y $max_y $yspace 1 %3.2f
    set npoints [expr [llength $curve ] -1]
    for {set i 0} {$i < $npoints} {incr i} {
        set datapoint0 [lindex $curve $i]
        if {$datapoint0 < $min_x} continue
        set j [expr $i+1]
        set datapoint1 [lindex $curve $j]
        #puts "datapoints $datapoint0 $datapoint1"
        set x1 [lindex $datapoint0 0]
        set y1 [lindex $datapoint0 1]
        set x2 [lindex $datapoint1 0]
        set y2 [lindex $datapoint1 1]
        set ix1 [Graph::ixpos $x1]
        set iy1 [Graph::iypos $y1]
        set ix2 [Graph::ixpos $x2]
        set iy2 [Graph::iypos $y2]
        $graph create line $ix1 $iy1 $ix2 $iy2 
        }
    set iy1 [expr [Graph::iypos $min_y] + 40]
    set ix1 200
    $graph create text $ix1 $iy1 -text $xlabel -font $df
    set iy1 [expr [Graph::iypos $max_y] + 20]
    $graph create text $ix1 $iy1 -text $title -font $df
}



proc drumComplexityDistribution {} {
load_desc
global desc
array unset featcount
set decsize [array size desc]
for {set i 1} {$i <$decsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set feat [dict get $desc($i) drums]
  set feat [llength $feat]
  if {![info exist featcount($feat)]} {
     set featcount($feat) 1
     } else {
     set featcount($feat)  [expr $featcount($feat) + 1]
     }
  }
for {set i 0} {$i < 47} {incr i} {
  if {![info exists featcount($i)]} {
     set featcount($i) 0
     }
  }
# cumulative distribution
for {set i 0} {$i < 46} {incr i} {
  set i1 [expr $i +1]
  set featcount($i1) [expr $featcount($i) + $featcount($i1)]
  }
set curve {}
set norm [expr double($featcount(46))]
for {set i 0} {$i < 46} {incr i} {
  set x $i
  set y [expr $featcount($i)/$norm]
  set p [list $x $y] 
  lappend curve $p
  }
#puts $curve
set graph .graph.c
  if {[winfo exists .graph] == 0} {
      toplevel .graph
      positionWindow .graph
      pack [canvas $graph]
  } else {
      $graph delete all}
raise .graph .
plotUnivariateDistribution $graph $curve 0 46 10 "number of percussion instruments"
}

proc drumDistribution {} {
load_desc
global desc
global drumpatches
set w .info.txt
$w delete 1.0 end
$w insert insert "\nThis lists the number of files which reference each of the\
 percussion instruments\n\n"
array unset featcount
set decsize [array size desc]
for {set i 1} {$i <$decsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set drumdata [dict get $desc($i) drums]
  foreach drum $drumdata {
  if {![info exist featcount($drum)]} {
     set featcount($drum) 1
     } else {
     set featcount($drum)  [expr $featcount($drum) + 1]
     }
  }
}

for {set i 35} {$i < 82} {incr i} {
   if {[info exist featcount($i)]} {
       set index [expr $i - 35]
       $w insert insert "$i [lindex [lindex $drumpatches $index] 1] $featcount($i)\n"
       }
   }
}


proc pitchEntropyDistribution {} {
global desc
load_desc
array unset featcount
set decsize [array size desc]
for {set i 1} {$i <$decsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  set feat [dict get $desc($i) pitchentropy]
  set feat [expr int($feat * 50.0)]
  if {![info exist featcount($feat)]} {
     set featcount($feat) 1
     } else {
     set featcount($feat)  [expr $featcount($feat) + 1]
     }
  }
for {set i 0} {$i < 201} {incr i} {
  if {![info exists featcount($i)]} {
     set featcount($i) 0
     }
  }
# cumulative distribution
for {set i 0} {$i < 200} {incr i} {
  set i1 [expr $i +1]
  set featcount($i1) [expr $featcount($i) + $featcount($i1)]
  }
set curve {}
set norm [expr double($featcount(199))]
for {set i 0} {$i < 200} {incr i} {
  set x [expr $i/50.0]
  set y [expr $featcount($i)/$norm]
  set p [list $x $y] 
  lappend curve $p
  }
set graph .graph.c
  if {[winfo exists .graph] == 0} {
      toplevel .graph
      positionWindow .graph
      pack [canvas $graph]
  } else {
      $graph delete all}
raise .graph .
plotUnivariateDistribution $graph $curve 2.0 4.0 0.5 "pitchclass entropy"
}

proc programStatistics {} {
load_desc
global desc
global mlist
global progcount
set w .info.txt
$w delete 2.0 end
$w insert insert "\nThis lists the number of files which reference each of the\
 GM programs\n\n"
set descsize [array size desc]
for {set i 0} {$i < 129} {incr i} {
  set progcount($i) 0
  }
for {set i 1} {$i < $descsize} {incr i} {
  if {[dict exists $desc($i) damaged]} continue
  if {[dict exists $desc($i) programs] == 0} continue
  set proglist [dict get $desc($i) programs]
  foreach prog $proglist {
    if {$prog > 128} continue
    set progcount($prog) [expr $progcount($prog) + 1]
    }
  }
for {set i 0} {$i < 128} {incr i} {
   $w insert insert "[lindex $mlist $i] $progcount($i)\n"
   }
plotProgramDistribution
}


proc plotProgramDistribution {} {
    global df
    global progcount
    set xspace 16
    set graph .graph.c
    if {[winfo exists .graph] == 0} {
        toplevel .graph
        positionWindow .graph
        pack [canvas $graph]
    } else {
        $graph delete all}
    raise .graph .
    set start 0
    set stop 128 
    set delta_tick 16
    $graph create rectangle 50 20 350 200 -outline black\
            -width 2 -fill white
    Graph::alter_transformation 50 350 200 20 $start $stop 0.0 10000
    Graph::draw_x_ticks $graph $start $stop $xspace 1  0 %4.0f
    Graph::draw_y_ticks $graph 0.0 10000 2000 1 %5.0f
    for {set i 0} {$i < 128} {incr i} {
        set x [expr double($i)]
        set y [expr double($progcount($i))]
        set ix [Graph::ixpos $x]
        set iy1 [Graph::iypos 0.0]
        set iy2 [Graph::iypos $y]
        $graph create line $ix $iy1 $ix $iy2
        }
    }

#Main
set ntrk 1
SwitchBetweenInfoAndTinfo 
check_midi2abc_midistats_and_midicopy_versions 
if {$midi(rootfolder) == ""} {
  .info.txt insert insert $welcome
  .info.txt configure -height 13
  } else {
  set msg "Last midi file opened was $midi(midifilein)\nYou can load it using the menu item file/reload last midi file."
  .info.txt insert insert $msg 
  }


proc getgenre {htmldata tune} {
global genre_db
set pat {"[^"]*"}
set loc [string first "Music genre" $htmldata 0]
if {$loc < 1} {
   .wiki.t insert insert "Music genre missing.\n" 
    }
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
  .wiki.t insert insert "genre = $genre" 
  } else {
  .wiki.t insert insert "unable to extract genre from $genre_string" 
  set genre "unknown"
  }
return $genre
}


proc get_genre {} {
package require http
package require tls
http::register https 443 ::tls::socket
global midi
global df
global genre_db
global body
wikipedia_window
load_genre_database
set len [string length $midi(rootfolder)]
incr len 
set s _(song)
set tune $midi(midifilein)
set tune [string range $tune $len end]
set tune [file rootname $tune]
set tune [split $tune .]
set tune [lindex $tune 0]
set genre $genre_db($tune)
if {$genre == 0 || $genre == "unknown"} {
  set song [split $tune /] 
  set song [lindex $song end]
  set song [string map {{ } _} $song]
  set url "https://en.wikipedia.org/wiki/$song"
  .wiki.t insert insert "$url \n" 
  set webpage [http::geturl $url]
  upvar #0 $webpage state
  .wiki.t insert insert "$state(http) \n" 
  .wiki.t insert insert "size  = $state(currentsize) \n" 
  set body $state(body)
  set genre [getgenre $body $tune]
  if {[string equal $genre  unknown]} {
    http::cleanup webpage
    set url $url$s
    .wiki.t insert insert $url\n 
    set webpage [http::geturl $url]
    upvar #0 $webpage state
    .wiki.t insert insert $state(http)\n 
    .wiki.t insert insert "size  = $state(currentsize)\n" 
    set body $state(body)
    set genre [getgenre $body $tune]
    }
#puts $genre
  set genre_db($tune) $genre
  } else {
  puts "genre already in database"
  }
}


bind . <Alt-g> get_genre


#   Part 15.0 Screen Layout (getGeometryOfAllToplevels)

proc getGeometryOfAllToplevels {} {
  global midi
  set toplevellist {"." ".notice" ".console" ".progsel" ".piano" ".chordstats"
               ".colors" ".chordview" ".chordgram" ".midistructure" 
               ".drumsel" ".drumroll" ".drumanalysis" ".pitchpdf"
               ".velocitypdf" ".onsetpdf" ".offsetpdf"  ".durpdf" ".pitchclass"
               ".midivelocity" ".mftext" ".searchbox" ".graph"
               ".fontwindow" ".support" ".preferences" ".beatgraph"
               ".ppqn" ".drumrollconfig" ".indexwindow" ".wiki"
               ".dictview" ".notegram" ".barmap" ".playmanage" ".data_info"
               ".midiplayer" ".tmpfile" ".cfgmidi2abc" ".pgram" ".keystrip"
               ".keypitchclass" ".channel9" ".ribbon" ".ptableau"
               ".touchplot" ".effect" ".csettings" ".drummap" }
  foreach top $toplevellist {
    if {[winfo exist $top]} {
      set g [wm geometry $top]"
      scan $g "%dx%d+%d+%d" w h x y
      #puts "$top $w $h $x $y"
      set midi($top) +$x+$y
      }
   }
  }

#   Part 16.0 Track/Channel analysis
 
# already defined
#proc compare_onset {a b} {
#    set a_onset [lindex $a 0]
#    set b_onset [lindex $b 0]
#    if {$a_onset > $b_onset} {
#        return 1}  elseif {$a_onset < $b_onset} {
#        return -1} else {return 0}
#}

 
proc get_note_patterns {} {
# This function finds all the unique patterns
# in the music stored in the pianoresult structure.
# Results are returned in two dictionaries.
# notepat contains the string representations of the
# notes that were onset for each tatum (1/16 time unit) 
# in the midi file.
# bar_rhythm contains the string representations of
# of the onset times (quantized to 24 units per bar) for
# each note occurring in the bar. 
# The dictionaries are indexed by the sequential positions
# of these tatums or bars.
   global ppqn
   global midicommands
   global midilength
   global beatsperbar
   global notefragments

   loadMidiFile
   set ppqn4 [expr $ppqn/4]
   set jitter [expr $ppqn4/2]
   set notefragments [expr 5 + $midilength/$ppqn4]
   set barsize [expr $ppqn*$beatsperbar]
   set nbars [expr $midilength/$barsize]
   incr nbars
   set notepat [dict create]
   for {set i 0} {$i <$notefragments} {incr i} {
     dict set notepat $i 0
     }
   set bar_rhythm [dict create]
   for {set i 0} {$i <$nbars} {incr i} {
     dict set bar_rhythm $i "" 
     }
   set colin ":"

   #puts "get_note_patterns: notefragments = $notefragments"

   set unitlength [expr $barsize/24]
   set rjitter [expr $unitlength/2]
   set lastbarnumber -1
   foreach line $midicommands {
        if {[llength $line] != 6} continue
        set onset [lindex $line 0]
        #set loc [expr $onset / $ppqn4]
        set loc [expr ($onset + $jitter) / $ppqn4]
        if {[string is double $onset] != 1} continue
        set c [lindex $line 3]
        if {$c == 10} continue
        if {[lindex $line 5] < 1} continue
        set pitch [lindex $line 4]
        set pitchindex [expr $pitch % 12]
        set patfrag [dict get $notepat $loc]
        set patfrag [expr $patfrag | 1<<$pitchindex]
        dict set notepat $loc $patfrag 
        #puts "notepat: $loc $patfrag $pitch $pitchindex"
	#set barnumber [expr $onset / $barsize]
	set barnumber [expr ($onset+$rjitter) / $barsize]
	if {$barnumber != $lastbarnumber} {
	   set lastbarnumber $barnumber
	   set lastunit ""
	   }
	#set unit [expr $onset % $barsize]
	set unit [expr ($onset + $rjitter) % $barsize]
	set unit [expr $unit/$unitlength]
	if {$lastunit != $unit} {
           set rhythmpat [dict get $bar_rhythm $barnumber] 
	   set rhythmpat [append rhythmpat $unit$colin]
           dict set bar_rhythm $barnumber $rhythmpat
	   set lastunit $unit
           }
        #puts "onset,barnumber,unit = $onset,$barnumber,$unit"	
       }
   dict set notepat size $loc
   return [list $notepat $bar_rhythm]
}

# for debugging only
proc dump_rhythmpat_for {rhythmpat c} {
puts "\n"
for {set i 0} {$i < 16} {incr i} {
  puts [dict get $rhythmpat $c,$i]
  }
}

proc dump_rhythmpat {rhythmpat} {
puts "\n"
for {set i 0} {$i < 16} {incr i} {
  puts [dict get $rhythmpat $i]
  }
}


proc get_all_note_patterns {} {
# This function finds all the unique patterns
# in the music stored in the pianoresult structure.
# Results are returned in two dictionaries.
# notepat contains the string representations of the
# notes that were onset for each tatum (1/16 time unit) 
# in the midi file.
# bar_rhythm contains the string representations of
# of the onset times (quantized to 24 units per bar) for
# each note occurring in the bar. 
# The dictionaries are indexed by the sequential positions
# of these tatums or bars.
   global ppqn
   global pianoresult
   global midilength
   global beatsperbar
   global midi
   global midicommands
   global chanprog

   #puts "calling get_all_note_patterns"

   set ppqn4 [expr $ppqn/4]
   set jitter [expr $ppqn4/2]
   set notefragments [expr 5 + $midilength/$ppqn4]
   #puts "notefragments = $notefragments"
   set barsize [expr $ppqn*$beatsperbar]
   set nbars [expr $midilength/$barsize]
   incr nbars
   set notepat [dict create]
   set bar_rhythm [dict create]
   set colin ":"


   set unitlength [expr $barsize/24]
   set rjitter [expr $unitlength/2]
   set lastbarnumber -1
   # sort all midi channel commands so that the program commands
   # appear at the right positions.
#   set midicommands [lsort -command compare_onset [split $pianoresult \n]]
   foreach line $midicommands {
          if {[string match "Program" [lindex $line 1]] == 1} {
             set chan [lindex $line 2]
             set prog [lindex $line 3]
             #set tatumTime [expr [lindex $line 0]/$ppqn4]
             #set progdata [list $tatumTime $prog]
             if {$chan != 10} {
                #puts "channel $chan --> $progdata"
                #dict set chanProgTable $chan $progdata
                set chanprog($chan) $prog
                }
           }

        if {[llength $line] != 6} continue
        set onset [lindex $line 0]
        set loc [expr ($onset + $jitter) / $ppqn4]
        #set loc [expr $onset / $ppqn4]
        if {[string is double $onset] != 1} continue
	set channel [lindex $line 3]
        set c [lindex $line 3]
        if {$channel == 10} continue
        if {[lindex $line 5] < 1} continue
        set pitch [lindex $line 4]
        set pitchindex [expr $pitch % 12]
        set cloc $c,$loc
	if {![dict exists $notepat $cloc]} {
             for {set i 0} {$i <$notefragments} {incr i} {
                dict set notepat $c,$i 0
             }
	     dict set notepat $c,size $notefragments
             #puts "setting notepat $c,size to $notefragments"
        }
        set patfrag [dict get $notepat $c,$loc]
        set patfrag [expr $patfrag | 1<<$pitchindex]
        dict set notepat $c,$loc $patfrag 
        #puts "notepat: $loc $patfrag $pitch $pitchindex"
	#set barnumber [expr $onset / $barsize]

	set barnumber [expr ($onset+$rjitter) / $barsize]
	if {$barnumber != $lastbarnumber} {
	   set lastbarnumber $barnumber
	   foreach e [array names lastunit] {
	     set lastunit($e) ""
             }
	   }

	#set unit [expr $onset % $barsize]
	set unit [expr ($onset + $rjitter) % $barsize]
	set unit [expr $unit/$unitlength]
        if {![dict exists $bar_rhythm $c,size]} {
           for {set i 0} {$i <$nbars} {incr i} {
              dict set bar_rhythm $c,$i "" 
           }
	   dict set bar_rhythm $c,size $nbars
	   set lastunit($c) ""
        }

	if {$lastunit($c) != $unit} {
           set rhythmpat [dict get $bar_rhythm $c,$barnumber] 
	   set rhythmpat [append rhythmpat $unit$colin]
           dict set bar_rhythm $c,$barnumber $rhythmpat
	   set lastunit($c) $unit
           }
        #puts "onset,barnumber,unit = $onset,$barnumber,$unit"	
       }
   return [list $notepat $bar_rhythm]
}


# button command variables are always defined in the global scope
# so we have to make the dictionaries global to pass it to the
# button command dictview window.
global patindexdict
global patindex2dict
global patindex3dict
global tatumhistogram
global beathistogram
global barhistogram
global barseqstring
global rhythmhistogram
global rpatindexdict
global beatsperbar
global bar_rhythm
set beatsperbar 4

proc entropyInterface {} {
global df
if {![winfo exist .entropy]} {
  setup_i2l
  set last_dictview 0
  set e .entropy
  frame $e
  label $e.plab -text "pitch class" -font $df
  label $e.tlab -text "" -font $df
  label $e.blab -text "" -font $df
  label $e.mlab -text "" -font $df
  label $e.relab -text "" -font $df
  menubutton $e.timesig -text "beats/bar" -menu $e.timesig.items -font $df -relief raised
  set em $e.timesig.items
  menu $em -tearoff 0
  $em add radiobutton -label 8 -font $df -variable beatsperbar -value 8\
    -command analyze_note_patterns
  $em add radiobutton -label 6 -font $df -variable beatsperbar -value 6\
    -command analyze_note_patterns
  $em add radiobutton -label 4 -font $df -variable beatsperbar -value 4\
    -command analyze_note_patterns
  $em add radiobutton -label 3 -font $df -variable beatsperbar -value 3\
    -command analyze_note_patterns
  $em add radiobutton -label 2 -font $df -variable beatsperbar -value 2\
    -command analyze_note_patterns
  button $e.tsize -text "" -font $df -command {dictlist_output patindexdict tatumhistogram; set last_dictview 1} 
  button $e.bsize -text "" -font $df -command {dictlist_output patindex2dict beathistogram; set last_dictview 2}
  button $e.msize -text "" -font $df -command {dictlist_output patindex3dict barhistogram; set last_dictview 3}
 
  menubutton $e.map -text "map" -menu $e.map.items -font $df -relief raised
  menu $e.map.items -tearoff 0
    $e.map.items add command -label "map" -font $df -command {dictview_map $patindex3dict $barseq; set last_dictview 4}
    $e.map.items add command -label "map all" -font $df -command {full_notedata_analysis pitch; set last_barmap pitch}
  label $e.rlab -text "rhythm" -font $df
  button $e.rsize -text "" -font $df -command {dictlist_output rpatindexdict rhythmhistogram; set last_dictview 5}
  menubutton $e.mapr -text "map" -menu $e.mapr.items -font $df -relief raised
  menu $e.mapr.items -tearoff 0
    $e.mapr.items add command -label "map" -font $df -command {rdictview_map $rpatindexdict $bar_rhythm; set last_dictview 6}
    $e.mapr.items add command -label "map all" -font $df -command {full_notedata_analysis rhythm; set last_barmap rhythm}

  button $e.help -text help -font $df -command {show_message_page $hlp_entropy word}
  button $e.close -text x -font $df -command {destroy .entropy} 
  pack $e.timesig $e.plab $e.tsize $e.bsize $e.msize $e.map $e.rlab $e.rsize $e.mapr $e.help $e.close -side left
  pack .entropy
  tooltip::tooltip $e.tsize "Number of distinct tatums."
  tooltip::tooltip $e.bsize "Number of distinct beats."
  tooltip::tooltip $e.msize "Number of distinct measures."
  tooltip::tooltip $e.rsize "Number of distinct measures."

  }
}


proc analyze_note_patterns {} {
# The procedure analyzes the note patterns and records all
# repeating (or nonrepeating patterns) into tcl dictionaries
# for the pitch tatum, beat, and bar time intervals and
# the rhythm representation. The hlp_entropy defined in this file
# gives some explanation of the system used here.
global midi
global df
global pianoresult
global exec_out
global midilength
global cleanData
# It is necessary to use global variables in order to pass these
# variables to the procedures called by the button controls.
global patindexdict
global patindex2dict
global patindex3dict
global tatumhistogram
global beathistogram
global barhistogram
global barseq
global rhythmhistogram
global rpatindexdict
global bar_rhythm
global beatsperbar
global last_dictview

set cleanData 0
entropyInterface 

# copyMidiToTmp deals with the selected tracks and time interval
copyMidiToTmp none
set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -midigram"
catch {eval $cmd} pianoresult
set nrec [llength $pianoresult]
set midilength [lindex $pianoresult [expr $nrec -1]]

set exec_out [append exec_out "note_patterns:\n\n$cmd\n\n $pianoresult"]
update_console_page


# we start by getting the pitch and rhythm patterns
# from the function get_note pattern.
set result [get_note_patterns] 
set notepat [lindex $result 0]
set bar_rhythm [lindex $result 1]
#
# pitch class analysis
# we look for repeated patterns by first computing the histogram
# of notepat.
set tatumhistogram [make_string_histogram $notepat]
set tsize [llength [dict keys $tatumhistogram]]
# using this histogram we create a dictionary for all the
# repeated patterns. The dictionary defines symbols representing
# the repeated patterns
set patindexdict [keys2index $tatumhistogram]
# using this dictionary, we translate notepat into higher level
# words (represented by new symbols), where these words denote
# sequences of pitches that re-occur. The representation for the
# beats put in beatseries by the function index_and_group.
set beatseries [index_and_group $patindexdict $notepat $beatsperbar "-"]
# now we start over again with beatseries and create another
# histogram of the occurrence of the beat symbols.
set beathistogram [make_string_histogram $beatseries]
# the beathistogram is used to create another dictionary, patindex2dict
# which denotes symbols for repeated sequences of beats.
set bsize [llength [dict keys $beathistogram]]
set patindex2dict [keys2index $beathistogram]
# using the patindex2dict translation table, we now represent each
# bar with a symbol. A new symbol is introduced if that bar did not
# appear earlier.
set barseq [index_and_group $patindex2dict $beatseries $beatsperbar "_"]
# compute a histograms of the different bars
set barhistogram [make_string_histogram $barseq]
#set barentropy [string_entropy $barhistogram]
set barsize [llength [dict keys $barhistogram]]
# create a translation table for the different bars
set patindex3dict [keys2index $barhistogram]
set barseries [bar2index $patindex3dict $barseq]
# represent each bar by a symbol
#
#
# rhythm analysis
set rhythmhistogram [make_string_histogram $bar_rhythm]
set rhythmentropy [string_entropy $rhythmhistogram]
set rhythmsize [llength [dict keys $rhythmhistogram]]
set rpatindexdict [keys2index $rhythmhistogram]
set rbarseries [bar2index $rpatindexdict $bar_rhythm]

.entropy.tsize configure -text $tsize 
.entropy.bsize configure -text $bsize
.entropy.msize configure -text $barsize
.entropy.rsize configure -text $rhythmsize
update_dictview
update_barmap
update_console_page
}


proc full_notedata_analysis {type} {
global midi
global pianoresult
global midilength
global lasttrack

set b .barmap.txt
if {![winfo exist .barmap]} {
   toplevel .barmap
   positionWindow .barmap
   text $b -width 80 -xscrollcommand {.barmap.xsbar set} -wrap none
   scrollbar .barmap.xsbar -orient horizontal -command {.barmap.txt xview}
   pack $b .barmap.xsbar -side top -fill x
   setup_i2l
   } 
wm title .barmap "$type map"
$b delete 1.0 end
$b tag configure headr -background wheat3

set cmd "exec [list $midi(path_midi2abc)] [list $midi(midifilein)] -midigram"
catch {eval $cmd} pianoresult
set nrec [llength $pianoresult]
set midilength [lindex $pianoresult [expr $nrec -1]]
set beatsperbar 4

set exec_out [append exec_out "note_patterns:\n\n$cmd\n\n $pianoresult"]
update_console_page
if {$midi(midishow_sep) == "track"} {
   $b insert insert "trk\tn  \n" wheat3
   set ntrks $lasttrack
   incr ntrks} else {
   $b insert insert "chn\ti/j/k       \n" wheat3
   set ntrks 16
   }
# identify all distinct note patterns. notepat deals with the pitches
# which includes all possible chords. bar-rhythm deals with all the
# rhythm patterns. We compute the histograms of all these patterns,
# assign an index to each of these patterns, and then group the time
# units into larger time units corresponding to beats and eventually
# bars. All the distinct beats are given separate indices and etc.
set result [get_all_note_patterns]
set notepat [lindex $result 0]
set bar_rhythm [lindex $result 1]
set nlines 0
for {set c 0} {$c < $ntrks} {incr c} {
  set trkchn [format %2d $c]
  if {$type == "pitch"} {
    if {[dict exists $notepat $c,size]} {
      set size  [dict get $notepat $c,size]
      set tatumhistogram [make_string_histogram_for $notepat $c $size]
      set patindexdict [keys2index $tatumhistogram]
      set tsize [llength $patindexdict]
      set beatseries [index_and_group_for $patindexdict $notepat $c $beatsperbar "-"]
      set beathistogram [make_string_histogram $beatseries]
      set patindex2dict [keys2index $beathistogram]
      set bsize [llength $patindex2dict]
      set barseq [index_and_group $patindex2dict $beatseries $beatsperbar "-"]
      set barhistogram [make_string_histogram $barseq]
      set barsize [llength [dict keys $barhistogram]]
      set patindex3dict [keys2index $barhistogram]
      set barseries [bar2index $patindex3dict $barseq]
      set channelStats $tsize/$bsize/$barsize
      $b insert insert $trkchn\t headr
      $b insert insert $channelStats\t\t headr
      set nchar [symbolfy_series $b $barseries 8] 
      incr nlines
      }
   } else {
    if {[dict exists $bar_rhythm $c,size]} {
      set size  [dict get $bar_rhythm $c,size]
      #puts "bar_rhythm:\n$bar_rhythm"
      set rhythmhistogram [make_string_histogram_for $bar_rhythm $c $size]
      set rhythmsize [llength [dict keys $rhythmhistogram]]
      set rpatindexdict [keys2index $rhythmhistogram]
      set rbarseries [bar2index_for $rpatindexdict $bar_rhythm $c]
      $b insert insert $trkchn\t$rhythmsize\t headr
      set nchar [symbolfy_series $b $rbarseries 8] 
      incr nlines
    }
  }

 }
 for {set i 1} {$i <$nchar} {incr i 8} {
    if {$i < 8} {set str [format %6d $i]
        } else  {set str [format %9d $i]}
    $b insert 1.end $str 
  }
$b tag add headr 1.0 1.end
incr nlines
$b configure -height $nlines
}

proc symbolfy_series {f series grouping} {
  global dfi
  set nchar 0
  $f tag configure italic -font $dfi
  set size [dict size $series]
  for {set i 0} {$i < $size} {incr i} {
      set index [dict get $series $i]
      $f insert insert [index2letter $index]
      incr nchar
      if {[expr ($i+1) % $grouping] == 0 && $i>0} {
	      $f insert insert "\t"
              incr nchar}
  }
  $f insert insert \n
  incr nchar
  return $nchar
}

proc update_dictview {} {
global patindexdict
global patindex2dict
global patindex3dict
global tatumhistogram
global beathistogram
global barhistogram
global barseq
global rhythmhistogram
global rpatindexdict
global bar_rhythm
global last_dictview
if {[winfo exist .dictview] == 0} return
switch $last_dictview {
   1 {dictlist_output patindexdict tatumhistogram}
   2 {dictlist_output patindex2dict beathistogram}
   3 {dictlist_output patindex3dict barhistogram}
   4 {dictview_map $patindex3dict $barseq}
   5 {dictlist_output rpatindexdict rhythmhistogram}
   6 {rdictview_map $rpatindexdict $bar_rhythm}
  }
}

proc update_barmap {} {
global last_barmap
if {[winfo exist .barmap] == 0} return
switch $last_barmap {
  pitch {full_notedata_analysis pitch}
  rhythm {full_notedata_analysis rhythm}
  }
}

proc dictview_window {} { 
# creates the dictview window for displaying histograms
# for pitch classes or rhythm (tatum, beat or bar resolution).
   global df
   if {[winfo exist .dictview] == 0} {
     set f .dictview
     toplevel $f
     positionWindow $f
     frame $f.1 
     label $f.1.lab -text ""
     pack $f.1.lab
     frame $f.2
     pack $f.1 $f.2 -side top
     text $f.2.txt -yscrollcommand {.dictview.2.scroll set} -width 64 -height 16 -font $df
     scrollbar .dictview.2.scroll -orient vertical -command {.dictview.2.txt yview}
     pack $f.2.txt $f.2.scroll -side left -fill y
     }
}

proc dictlist_output {dictdataname histogram} {
# outputs the tatum,  beat or bar pitch histograms in the
# dictview window.
   upvar #0 $dictdataname dictdata
   upvar #0 $histogram histdata
   dictview_window
   if {$dictdataname == "patindexdict"} {
     dictlistp $dictdata $histdata 
   } elseif {$dictdataname == "patindex2dict"} {
     dictlistb $dictdata $histdata
   } else {dictlist $dictdata $histdata }
 }



proc dictlistp {dictdata dicthist} {
# outputs the tatum histogram for pitch classes
   global notefragments
   set f .dictview.2.txt
   $f delete 1.0 end
   $f insert end "There are $notefragments tatums in the file\n"
   set line "index\tcode\tcount\tpitch classes"
   $f insert end $line\n
   dict for {key data} $dictdata {
     if {$key == 0} continue
     set count [dict get $dicthist $key]
     set line "$data\t$key\t$count\t[binary_to_pitchclasses $key]" 
     $f insert end $line\n 
     }
   }

proc dictlistb {dictdata dicthist} {
# outputs the beat histogram for pitch classes
   global patindexdict
   global notefragments
   global patindexdict
   set f .dictview.2.txt
   $f delete 1.0 end
   $f insert end "There are [expr $notefragments/4] beats in the file\n"
   set line "index\tcode\tcount\tpitch classes"
   $f insert end $line\n
   set rpatindexdict [lreverse $patindexdict]
   dict for {key data} $dictdata {
     set p ""
     set pkeys [split $key -]
     foreach k $pkeys {
	     lappend p [binary_to_pitchclasses [dict get $rpatindexdict $k]]
             }
     if {$key == 0} continue
     set count [dict get $dicthist $key]
     set line "$data\t$key\t$count\t$p" 
     $f insert end $line\n 
     }
   }

proc dictlist {dictdata dicthist} {
# outputs the bar pitch class histogram in the dictview
# window.
   global notefragments
   global beatsperbar
   set f .dictview.2.txt
   $f delete 1.0 end
   $f insert end "There are [expr $notefragments/4/$beatsperbar] bars in the file\n"
   set line "index\tcode\t\tcount"
   $f insert end $line\n
   dict for {key data} $dictdata {
     if {$key == 0} continue
     set count [dict get $dicthist $key]
     set line "$data\t$key\t\t$count" 
     $f insert end $line\n 
     }
   }


proc binary_to_pitchclasses {binaryvector} {
global sharpnotes
global flatnotes
global useflats
set i 0
set notes ""
while {$binaryvector > 0} {
  if {[expr $binaryvector % 2] == 1} {
    if {$useflats} {
      append notes [lindex $flatnotes $i]
      } else {
      append notes [lindex $sharpnotes $i]
      }  
    #append notes " "
   }
 set binaryvector [expr $binaryvector/2]
 incr i
 }
return $notes
}



proc dictview_map {patindex series} {
# produces the pitch map representing each distinct bar
# in the midi file with a distinct character. We group 8
# characters at a time.
   global dfi
   dictview_window
   set f .dictview.2.txt
   $f delete 1.0 end
   set size [dict size $series]
   for {set i 0} {$i < $size} {incr i} {
      set elem [dict get $series $i]
      set index [dict get $patindex $elem]
      $f insert insert [index2letter $index]
      if {[expr $i % 32] == 7} {$f insert insert "\t"}
      if {[expr $i % 32] == 15} {$f insert insert "\t"}
      if {[expr $i % 32] == 23} {$f insert insert "\t"}
      if {[expr $i % 32] == 31} {$f insert insert "\n"}
      }
   bind $f <ButtonRelease> getbarinfo_from_map
   bind $f <KeyRelease> getbarinfo_from_map
}

proc rdictview_map {patindex series} {
# pops up the dictview window and displays the  string
# of symbols (characters) for the rhythm representations
# of each measure. The symbols are puts into groups  of
# 8 to make the map more readable. The symbols are bound
# to mouse and keyboard events to allow interpretations
# to appear in the header.
   global dfi
   dictview_window
   set f .dictview.2.txt
   $f delete 1.0 end
   set size [dict size $series]
   for {set i 0} {$i < $size} {incr i} {
      set elem [dict get $series $i]
      set index [dict get $patindex $elem]
      $f insert insert [index2letter $index] italic
      if {[expr $i % 32] == 7} {$f insert insert "\t"}
      if {[expr $i % 32] == 15} {$f insert insert "\t"}
      if {[expr $i % 32] == 23} {$f insert insert "\t"}
      if {[expr $i % 32] == 31} {$f insert insert "\n"}
      }
   bind $f <ButtonRelease> rgetbarinfo_from_map
   bind $f <KeyRelease> rgetbarinfo_from_map
}

proc getbarinfo_from_map {} {
# The function gets the position of the letter code
# of interest in the text widget displayed in the
# dictview window. It calls barseqcode to interpret
# this letter and displays the interpretation in the
# top label widget of this window.
set loc [.dictview.2.txt index insert]
set letter [.dictview.2.txt get $loc]
.dictview.1.lab configure -text [barseqcode $letter]
}

proc rgetbarinfo_from_map {} {
# bound to event clicking on a character in the pitch map
# where each character represents a particular
# bar in the midi file.
set loc [.dictview.2.txt index insert]
set letter [.dictview.2.txt get $loc]
.dictview.1.lab configure -text [rbarseqcode $letter]
}
  


set hlp_entropy "This analysis is similar to the drum analysis except\
that now we are substituting the pitch class (pitch modulo 12) instead\
of the percussion instrument. Pitch class analysis is performed by\
fragmenting each bar into 1/16 note segments. For each segment we\
determine all the pitch classes that are onset in this interval and\
respresent this information in a 12 bit binary number. A histogram of the\
occurrences of all the distinct numbers are determined and the\
distinct numbers are assigned sequential numeric labels.\
These distinct instances can be considered to be the alphabet.\n\n\
Quarter note words are created by grouping the instances in fours,\
and the number of distinct words of the distinct words\
are determined and indicated.\n\n\
The distinct quarter note words are also assigned numeric labels and\
they are used to be grouped into bar words in the same fashion.\
It should be noted that we ignore the note durations in this analysis.\
Only the note onsets are considered.\n\n
The results are indicated in a thin frame containing the\
button labeled beats/bar at the bottom of the main window.\
By default it is assumed that the meter is 4/4 and that there are\
four beats per bar. If this is not the case, you should change it.\
The number of distinct 1/16 note segments,\
1/4 note segments, and bars are indicated on the buttons going left to right.\
Clicking on those buttons pops up another window with\
more details.  The map button displays the series of bars (in groups\
of 8) using alphanumeric characters to distinguish the distinct\
bars. If we run out of the 64 alphanumeric characters, we select\
greek and cyrillic characters. If we run out again, then we represent the bar\
with an asterisk. If you click on one of those characters, the computer representation\
of the bar is shown on the top of the map window. Slashes are used\
to separate the 1/16 note segments, and vertical lines are used to\
separate the 1/4 note beats. If you see two sequential\
slashes, this indicates an empty segment.\n\n\
The map all button is similar to the map button except the results\
are shown for all channels (or tracks). The top line indicates the\
beat number; the left columns indicates the channel or track number and\
the number of distinct bars.\n\n\

Rhythm analysis is performed by representing the 4 beat bars by a\
list of note onset times separated by colins. Each onset time is\
quantized so that a bar is split into 24 units. Notes sharing the\
same onset times (chordal notes) are ignored. The lists are represented\
by a strings and the histogram of the distinct strings are determined.
"



 
#   Part 17.0 Playlist support
#
set hlp_playlist "Playlist manager\n\n\
This window is used to get quick access to music of a particular\
genre. In order for this to work, you require a folder called playlists\
inside your active root folder of your music collection. The playlists\
folder contains a bunch of text files with a txt extension. The name\
of the text file should reflect the type of music of the artists\
that you are listing. For example, the file rnb.txt would contain\
a list of the rhythm and blues folders that exist in your database\
where each folder is on a separate line.\n\n\
When you start the playlist manager, a window with two listboxes should\
appear side by side. The left box shows the list of text files in your\
playlists folder where the txt extension is suppressed. When you\
click on one of the entries in the left listbox, the contents of\
the corresponding file is shown in the right listbox. Clicking on\
one of the items in the right box, will insert the artists name\
in the find entry box near the top of the main window, and the\
artist folder will positioned in the tree browser.\n\n\

Sample playlist files for the lakh clean database will be made
available with the online documentation.
"

proc make_playlist_manager {} {
  global midi
  global playlistfiles
  global lastplayfile_item
  global font df

  if {![winfo exist .playmanage]} {
    toplevel .playmanage
    positionWindow .playmanage
    button .playmanage.help -font $df -text help -command {show_message_page $hlp_playlist word}
    pack .playmanage.help
    set f .playmanage.left
    frame $f
    pack $f -side left
    listbox $f.list -yscrollcommand {.playmanage.left.ysbar set} -selectmode single -font $df
    scrollbar $f.ysbar -orient vertical -command {.playmanage.left.list yview}
    pack $f.ysbar -side right -fill y -in $f
    pack $f.list -fill both -expand y -in $f

    bind .playmanage.left.list <Button> {playlist_file_update [.playmanage.left.list nearest %y]}

    set f .playmanage.right
    frame $f
    pack $f -side left
    listbox $f.list -yscrollcommand {.playmanage.right.ysbar set} -selectmode single -font $df
    scrollbar $f.ysbar -orient vertical -command {.playmanage.right.list yview}
    pack $f.ysbar -side right -fill y -in $f
    pack $f.list -fill both -expand y -in $f
    bind .playmanage.right.list <Button> {playlist_artist_selected [.playmanage.right.list nearest %y]}
  }

  set lastplayfile_item -1
  set playlistfiles ""
  set playlistfolder [file join $midi(rootfolder) playlists]
  if {![file exist $playlistfolder]} {
    set msg "The folder $playlistfolder was not found."
    tk_messageBox -message $msg -type ok
    } else {
    set playlistfiles [glob $playlistfolder/*.txt]
    set playlistfiles [lsort $playlistfiles]
    }

  foreach playfile $playlistfiles {
    set play [file rootname [file tail $playfile]]
    .playmanage.left.list insert end $play
    }
  }

proc playlist_file_update {loc} {
global playlistfiles
global lastplayfile_item
set i [.playmanage.left.list index $loc]
set filepath [lindex $playlistfiles $i]
set inhandle [open $filepath r]
.playmanage.left.list itemconfigure $i -fg red
if {$lastplayfile_item >= 0} {
  .playmanage.left.list itemconfigure $lastplayfile_item -fg black
  }
set lastplayfile_item $i

#puts $filepath
set line ""
.playmanage.right.list delete 0 end
while {[eof $inhandle] != 1} {
   gets $inhandle line
   #set artist [file rootname [file tail $line]]
   set artist $line
   .playmanage.right.list insert end $artist
   #puts $line
   }
close $inhandle
}

proc playlist_artist_selected {loc} {
global findname
set findname [.playmanage.right.list get $loc]
findChildInTree .treebrowser $findname
}


#   Part 18.0 google_search
proc google_search {{modifier ""}} {
global midi
global exec_out
set exec_out "google_search:\n"
set splitname [file split $midi(midifilein)]
#puts $splitname
set l [llength $splitname]
set l1 [expr $l -1]
set l2 [expr $l -2]
set title [file root [lindex $splitname $l1]]
set artist [lindex $splitname $l2]
#puts $artist
#puts $title
set searchstring "$artist+$title+$modifier"
set searchstring [string map {{ } + & +} $searchstring]
#puts $searchstring
set s "https://www.google.ca/search?q=$searchstring"
#puts $s
set cmd "exec [list $midi(browser)] [list $s] &"
catch {eval $cmd} result
append exec_out $cmd\n$result
update_console_page
}

proc duckduckgo_search {} {
global midi
global exec_out
set splitname [file split $midi(midifilein)]
#puts $splitname
set l [llength $splitname]
set l1 [expr $l -1]
set l2 [expr $l -2]
set title [file root [lindex $splitname $l1]]
set artist [lindex $splitname $l2]
#puts $artist
#puts $title
set searchstring "$artist+$title"
set searchstring [string map {{ } + & +} $searchstring]
#puts $searchstring
set s "https://www.duckduckgo.com/?q=$searchstring"
#puts $s
set cmd "exec [list $midi(browser)] $s &"
catch {eval $cmd} result
set exec_out $cmd
update_console_page
#puts $result
}

#   Part 19.0 abc file
#
set hlp_abc_editor "Abc Editor\n\n\
This editor is designed to handle the large abc notated text\
produced by midiexplorer. Each of the voices, indicated in blue,\
are elided. To expose the voice content, click on the blue voice\
label. Click again, to elide this voice.\n\n\
The body of the abc file contains one measure per line of text.\
The bar number is indicated in the adjoining text window on the\
left and is there for information only. It is not used by the\
software. If you edit the abc text and introduce or remove a bar\
the indicated bar number on the left may be incorrect. To fix\
this problem click the recalc button.\n\n\
The play function will copy the existing abc notation to a file\
called X.tmp in the midiexplorer_home folder and then convert it into\
a midi file  X1.mid using the executable abc2midi. The midi file X1.mid\
will be forwarded to your designated midi player.\n\n\
The display function will also copy the existing abc notation to a file\
called X.tmp and then convert it to a PostScript file called\
Out.ps. Then Out.ps will be forwarded to a program that you designate\
to display this file.\n\n\
The web display button does not require abcm2ps, ghostscript and\
a PostScript viewer to display the music as it uses a completely\
different method. Instead, it merely requires an internet browser. The\
abc notation is inserted in an html file which links directly to\
a website containing Jef Moine's JavaScript code. When the browser\
displays this html file the JavaScript code is executed and renders\
the abc notation into a music score. If you click your mouse pointer\
on any note in the score, the music should start playing on your\
speakers and follow the score.\n\n\
"


proc create_abc_file {source} {
global midi
global exec_out
set exec_out "create_abc_file $source\n\n"
set title [file root [file tail $midi(midifilein)]]
copyMidiToTmp $source
# -sr 2 swallow small rests
set options " "
if {$midi(splits) == 1} {set options [concat $options -splitbars]}
if {$midi(splits) == 2} {set options [concat $options -splitvoices]}
if {$midi(midirest) > 0} {set options [concat $options "-sr $midi(midirest)"]}
set cmd "exec [list $midi(path_midi2abc)] [list $midi(outfilename)] $options -noly -title [list $title]" 
catch {eval $cmd} result
#puts $result
set exec_out $exec_out\n$cmd
edit_abc_output $result
update_console_page
}

proc piano_abc_file {} {
# converts the midi file to abc notation and uses abc2svg
# to display the abc notation in common music notation
# on your browser.
global midi
global exec_out
set title [file root [file tail $midi(midifilein)]]
# -sr 2 swallow small rests
set options " "
if {$midi(splits) == 1} {set options [concat $options -splitbars]}
if {$midi(splits) == 2} {set options [concat $options -splitvoices]}
if {$midi(midirest) > 0} {set options [concat $options "-sr $midi(midirest)"]}
set cmd "exec [list $midi(path_midi2abc)] [list $midi(outfilename)] $options -noly -title [list $title]" 
catch {eval $cmd} result
set exec_out $exec_out\n$cmd\n$result
set outhandle [open X.tmp w]
puts $outhandle $result
close $outhandle
copyXtmptohtml 
set cmd "exec [list $midi(browser)] file:[file join [pwd] $midi(outhtml)] &"
catch {eval $cmd} exec_out
set exec_out "$cmd\n$exec_out"
update_console_page
}

proc edit_abc_output {output} {
global midi
global df
global elidevoice
set f .abcoutput
set dots "..."
set pat {V:([0-9]+)}
if {![winfo exist .abcoutput]} {
  toplevel .abcoutput
  frame $f.1
  button $f.1.display -text display -font $df -command display_abc_file
  button $f.1.displaysvg -text "web display" -font $df -command display_abc_file_using_abc2svg
  tooltip::tooltip $f.1.display  "Convert the abc notation to a\nPostScript file and display."
  button $f.1.play -text play -font $df -command play_abc_file
  tooltip::tooltip $f.1.play  "Convert the abc notation to\na midi file and play."
  button $f.1.save -text save -font $df -command save_abc_file
  tooltip::tooltip $f.1.save  "Save the edited abc notation to\na file of your choice."
  button $f.1.recalc -text "recalc" -font $df\
     -command recalculate_bar_numbers
  tooltip::tooltip $f.1.recalc  "Recalculate the bar numbers."
  button $f.1.help -text help -font $df -command {show_message_page $hlp_abc_editor word}
  pack $f.1
  pack $f.1.display $f.1.displaysvg $f.1.play $f.1.save $f.1.recalc $f.1.help -side left
  frame $f.2
  text $f.2.txt -yscrollcommand {.abcoutput.2.scroll set} -width 80 -font $df -wrap none
  text $f.2.bar -yscrollcommand {.abcoutput.2.scroll set} -width 4 -font $df
  scrollbar $f.2.scroll -orient vertical -command [list BindYviewP [list .abcoutput.2.txt .abcoutput.2.bar]]
  pack $f.2.scroll -side right -fill y
  pack $f.2.bar -fill y -side left
  pack $f.2.txt  -side left -fill both -expand 1
  pack $f.2 -fill both -expand 1
  }
  $f.2.txt delete 1.0 end
  $f.2.bar delete 1.0 end
  set voiceno 0
  foreach line [split $output \n]  {
    if {[regexp $pat $line result voiceno]} {
       $f.2.txt tag configure vo$voiceno -foreground blue
       $f.2.txt tag bind vo$voiceno <1> "elide_reveal_voice $voiceno"
       $f.2.txt insert end $line\n vo$voiceno
       $f.2.bar insert end $dots\n 
       set elidevoice($voiceno) 0
       elide_reveal_voice $voiceno
       set barno 0
    } else {
       $f.2.txt insert end $line\n v$voiceno
       set first [string index $line 0]
       if {$voiceno != 0 && $first != "%"} {
	   incr barno
	   $f.2.bar insert end $barno\n b$voiceno
          } else {
           $f.2.bar insert end $dots\n b$voiceno
           }
    }
  }
}

proc recalculate_bar_numbers {} {
set f .abcoutput
$f.2.bar delete 1.0 end
set voiceno 0
set dots "..."
set pat {V:([0-9]+)}
set output [.abcoutput.2.txt get 1.0 end]
foreach line [split $output \n]  {
  if {[regexp $pat $line result voiceno]} {
     $f.2.bar insert end $dots\n 
     set barno 0
     } else {

       set initial [string index $line 0]
       set next [string index $line 1]
       if {[string first $initial ABCDEFGHIKLMNOPQRSTUVWwXZ]
        >= 0 && $next == ":" } {
		set field 1
        } else {set field 0}

       if {$voiceno != 0 && $initial != "%" && $field == 0} {
       incr barno
       $f.2.bar insert end $barno\n b$voiceno
       } else {
      $f.2.bar insert end $dots\n b$voiceno
      }
    }
  }
}

proc BindYviewP {lists args} {
# see Practical Programming in Tcl and Tk page 686
    foreach l $lists {
	    eval {$l yview} $args
    }
}

proc elide_reveal_voice no {
global elidevoice
set elidevoice($no) [expr 1 - $elidevoice($no)]
.abcoutput.2.txt tag configure v$no -elide $elidevoice($no)
.abcoutput.2.bar tag configure b$no -elide $elidevoice($no)
}

proc save_abc_file {} {
set abcfilename [tk_getSaveFile ]
set abcdata [.abcoutput.2.txt get 1.0 end]
set outhandle [open $abcfilename w]
puts $outhandle $abcdata
close $outhandle
}

proc play_abc_file {} {
global midi
global exec_out
if {![file exist $midi(path_abc2midi)]} {
  set msg "To use this function you require the executable abc2midi. Place it\
  in the directory midiexplorer_home."
  tk_messageBox -message $msg  -type ok
  return
  }
set ext ".abc"
set abcdata [.abcoutput.2.txt get 1.0 end]
set outhandle [open X.tmp w]
puts $outhandle $abcdata
close $outhandle
set cmd "exec [list $midi(path_abc2midi)] X.tmp"
catch {eval $cmd} exec_out
set exec_out $cmd\n\n$exec_out
#puts $exec_out
play_midi_file X1.mid
}



set urlpointer(1) "http://moinejf.free.fr/js/"
#set urlpointer(2) $midi(jslib)/

proc copyXtmptohtml {} {
global midi
global urlpointer

set html_preamble "<!DOCTYPE HTML>
<html>
<head>
"

 switch $midi(webscript) {
     1 {set abcweb abcweb-1.js}
     2 {set abcweb abcweb1-1.js}
     3 {set abcweb abcweb2-1.js}
     }

set remote_svg_script [make_js_script_list $urlpointer(1) $abcweb]
#set local_svg_script  [make_js_script_list $urlpointer(2) $abcweb]

set midi(remote) 1
set preface $html_preamble
  if {$midi(remote)} {
    set preface $preface$remote_svg_script
    } else {
    set preface $preface$local_svg_script
    }



 switch $midi(webscript) {
    1 {append preface "\n</head>\n<body>\n%abc\n"}
    2 {append preface "\n</head>\n<body>\n<!--\n"}
    3 {append preface "\n</head>\n<body>\n<script type=\"text/vnd.abc\" class=\"abc\">"}
}



set inhandle [open [file join [pwd] X.tmp] r]
set wholefile [read $inhandle]
close $inhandle


set midi(outhtml) X.html
set outhandle [open $midi(outhtml) w]
puts $outhandle $preface


set midi(fmt_chk) 0
if {$midi(fmt_chk) && [file exist $midi(ps_fmt_file)]} {
  set inhandle [open $midi(ps_fmt_file)]
  set fmt [read $inhandle]
  close $inhandle
  puts $outhandle $fmt
  }
puts $outhandle $wholefile
   switch $midi(webscript) {
       1 {puts $outhandle "\n</body>\n</html>\n"}
       2 {puts $outhandle "\n-->\n</body>\n</html>\n"}
       3 {puts $outhandle  "</script>\n</body>\n</html>\n"}
       }

close $outhandle
}

proc make_js_script_list {url abcweb} {
set scriptlist "        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>\n"
set styleblock "
        <style type=\"text/css\">
        svg {display:block}
        @media print{body{margin:0;padding:0;border:0}.nop{display:none}}
        </style>"
set w(0) "abc2svg-1.js"
set w(1) "snd-1.js"
set w(2) "follow-1.js"
set tail "\"></script>\n"
append scriptlist "     <script src=\"$url$w(0)$tail"
append scriptlist "     <script src=\"$url$abcweb$tail"
append scriptlist "     <script src=\"$url$w(1)$tail"
append scriptlist "     <script src=\"$url$w(2)$tail"
append scriptlist $styleblock
return $scriptlist
}


proc display_abc_file {} {
global midi
global exec_out
set ext ".abc"
if {![file exist $midi(path_abcm2ps)]} {
  set msg "To use this function you require the executable abcm2ps. Place it\
  in the directory midiexplorer_home."
  tk_messageBox -message $msg  -type ok
  return
  }
set abcdata [.abcoutput.2.txt get 1.0 end]
set outhandle [open X.tmp w]
puts $outhandle $abcdata
close $outhandle
set cmd "exec [list $midi(path_abcm2ps)] -j 1 X.tmp"
catch {eval $cmd} exec_out
set exec_out $cmd\n\n$exec_out
set cmd "exec [list $midi(path_gs)] -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -q -sOutputFile=Out.pdf Out.ps"
catch {eval $cmd} result
append exec_out "\n$cmd\n$result"
set cmd "exec [list $midi(browser)] file:[file join [pwd] Out.pdf] &"
append exec_out \n$cmd
catch {eval $cmd} result
append exec_out \n$result
}

proc display_abc_file_using_abc2svg {} {
global midi
global exec_out
set ext ".abc"
set abcdata [.abcoutput.2.txt get 1.0 end]
set outhandle [open X.tmp w]
puts $outhandle $abcdata
close $outhandle

copyXtmptohtml 
set cmd "exec [list $midi(browser)] file:[file join [pwd] $midi(outhtml)] &"
catch {eval $cmd} result
set exec_out "$exec_out\n$cmd\n$result"
}

proc midi2abc_config {} {
global midi
global df
set w .cfgmidi2abc
if {![winfo exist $w]} {
  toplevel $w
  positionWindow $w
  label $w.minrestlab -text "minimum rest" -font $df
  entry $w.minrestent -textvariable midi(midirest) -width 2 -font $df
  grid $w.minrestlab $w.minrestent
  radiobutton $w.nosplits -text "no splits" -value 0 -font $df -variable midi(splits)
  radiobutton $w.voicesplits -text "voice splits" -value 2 -font $df -variable midi(splits)
  radiobutton $w.barsplits -text "bar splits" -value 1 -font $df -variable midi(splits)
  grid $w.nosplits $w.barsplits $w.voicesplits
  }
}

#   Part 20.0 Pgram
#

set hlp_pgram "Pgram\n\n\
The pgram provides a different way of visualizing a midi file.\
The plot is similar to the piano roll representation, except the temporal\
detail is reduced in order to yield a big picture. The different\
instruments (programs) are color coded like in midi structure. (Keyboard\
instruments are in dark blue, string instruments in purple, and etc.)\
The higher pitches appear at higher elevations.\n\n\
Moving the mouse pointer on any of the notes will highlight all the\
notes belonging to the same midi channel and indicate in the status\
line below the name of the instrument. Moving the mouse pointer over\
any of the channel check buttons below, will also highlight the notes belonging\
to that channel. In case the highlighting does not work for that\
channel, it is likely that there is another channel which displayed\
the same pitches.\n\n\
The abc button will generate an abc file and open an editor to this\
file. You can select a time interval by sweeping the mouse\
pointer from left to right over the region of interest while holding\
down the left mouse button. You can also specify the midi channels\
of interest by checking the appropriate check buttons.\n\n\
This representation is still somewhat experimental. The configuration menu,\
allows you to change the way it is displayed. For example in chord mode,\
all the possible notes between the lowest and highest notes in the chord\
are displayed by a vertical column of dots. The reset button restores\
the settings to the default.

"

proc p_highlight {c} {
global mlist
global last_high
global xchannel2program
set last_high $c
.pgram.c itemconfigure c$c -fill white 
set program [lindex $mlist $xchannel2program($c)]
.pgram.stat configure -text "channel $c --> $program"
}

proc p_unhighlight {c} {
global last_high
global progmapper
global groupcolors
global xchannel2program
if {$last_high < 0} return
set p $xchannel2program($last_high)
set g [lindex $progmapper $p]
set kolor [lindex $groupcolors $g]
.pgram.stat configure -text ""
.pgram.c itemconfigure c$c -fill $kolor 
set last_high -1
}


proc pgram_window {} {
global df
global hlp_pgram
global midi
global midichannels
global exec_out
set exec_out "pgram_window\n"
if {![winfo exist .pgram]} {
  toplevel .pgram
  positionWindow .pgram
  frame .pgram.hdr
  pack .pgram.hdr -anchor w
  button .pgram.hdr.cfg -text configure -font $df -command pgram_cfg
  button .pgram.hdr.play -text play -font $df -command pgram_play
  button .pgram.hdr.abc -text abc -font $df -command pgram_abc
  button .pgram.hdr.hlp -text help -font $df -command {show_message_page $hlp_pgram word}
  pack .pgram.hdr.cfg .pgram.hdr.play .pgram.hdr.abc .pgram.hdr.hlp -side left -anchor w
  set pgraph .pgram.c
  canvas $pgraph -width $midi(pgramwidth) -height $midi(pgramheight) -border 3 
  pack $pgraph
  bind_pgram_tags
  frame .pgram.chn
  pack .pgram.chn
  label .pgram.chn.txt -text "channels: " -font $df
  pack .pgram.chn.txt -side left
  label .pgram.stat -text "" -font $df
  pack .pgram.stat
  for {set i 1} {$i < 17} {incr i} {
	  checkbutton .pgram.chn.$i -text $i -font $df -relief ridge -bd 2 -padx 1 -variable midichannels($i)
	  pack .pgram.chn.$i -side left
	  bind .pgram.chn.$i <Enter> "p_highlight $i"
	  bind .pgram.chn.$i  <Leave> "p_unhighlight $i"
          }
  }
compute_pgram
bind $pgraph <ButtonPress-1> {pgram_Button1Press %x %y}
bind $pgraph <ButtonRelease-1> {pgram_Button1Release}
bind $pgraph <Double-Button-1> pgram_ClearMark
update_console_page
}

proc pgram_cfg {} {
global midi
global df
if {![winfo exist .pgramcfg]} {
  set p .pgramcfg
  toplevel $p
  frame $p.mode
  pack $p.mode -anchor w 
  radiobutton $p.mode.c -text "chord mode" -font $df -variable midi(pgrammode) -value chord
  radiobutton $p.mode.p -text "no chord mode" -font $df -variable midi(pgrammode) -value nochord
  pack $p.mode.c $p.mode.p -side left -anchor w
  frame $p.width
  pack $p.width -anchor w
  label $p.width.txt -text "plot width" -font $df
  entry $p.width.ent -textvariable midi(pgramwidth) -font $df
  pack $p.width.txt $p.width.ent -side left -anchor w
  frame $p.height
  pack $p.height
  label $p.height.txt -text "plot height" -font $df
  entry $p.height.ent -textvariable midi(pgramheight) -font $df
  pack $p.height.txt $p.height.ent -side left -anchor w
  frame $p.linewidth
  pack $p.linewidth
  label $p.linewidth.txt -text "line thickness" -font $df
  entry $p.linewidth.ent -textvariable midi(pgramthick) -font $df
  pack $p.linewidth.txt $p.linewidth.ent -side left -anchor w
  frame $p.action
  button $p.action.reset -text "reset" -font $df -command pgram_reset
  button $p.action.update -text "update" -font $df -command pgram_update
  pack $p.action.reset $p.action.update -anchor w -side left
  pack $p.action
  }
}

proc pgram_reset {} {
global midi
set midi(pgrammode) nochord
set midi(pgramwidth) 500
set midi(pgramheight) 350
set midi(pgramthick) 2
destroy .pgram
pgram_window
}

proc pgram_update {} {
destroy .pgram
pgram_window
}




proc bind_pgram_tags {} {
set pgraph .pgram.c
for {set i 0} {$i < 17} {incr i} {
        $pgraph bind c$i <Enter> "p_highlight $i"
        $pgraph bind c$i <Leave> "p_unhighlight $i"
    }
}

#        Support functions

proc pgram_Button1Press {x y} {
    global midi
    global pxlbx pxrbx
    set xc [.pgram.c canvasx $x]
    if {$xc < $pxlbx} {set xc $pxlbx}
    .pgram.c raise mark
    .pgram.c coords mark $xc 21 $xc $midi(pgramheight)
    bind .pgram.c <Motion> { pgram_Button1Motion %x }
}

proc pgram_Button1Motion {x} {
    global midi
    global pxlbx pxrbx
    set xc [.pgram.c canvasx $x]
    if {$xc < $pxlbx} { set xc $pxlbx }
    if {$xc > $pxrbx} { set xc $pxrbx}
    set co [.pgram.c coords mark]
    .pgram.c coords mark [lindex $co 0] 21 $xc $midi(pgramheight)
}

proc pgram_Button1Release {} {
    bind .pgram.c <Motion> {}
    set co [.pgram.c coords mark]
}

proc pgram_ClearMark {} {
    .pgram.c coords mark -1 -1 -1 -1
}



proc reset_pitch_bands {} {
global bminpitch
global bmaxpitch
# reset
for {set i 0} {$i < 32} {incr i} {
  set bminpitch($i) 128
  set bmaxpitch($i) 0
  }
}

proc vbuildpgram {} {
global sorted_pianoresult
global ppqn
global bminpitch
global bmaxpitch
set lastbegin 0
reset_pitch_bands
foreach line $sorted_pianoresult {
     set begin [lindex $line 0]
     set end [lindex $line 1]
     if {[llength $line] == 6} {
       set begin [expr $begin/$ppqn]
       if {$begin > $lastbegin} {output_pitch_bands $lastbegin
	                         set lastbegin $begin}
       set end [expr [lindex $line 1]/$ppqn]
       set t [lindex $line 2]
       set c [lindex $line 3]
       set pitch [lindex $line 4]        
       if {$pitch > $bmaxpitch($c)} {set bmaxpitch($c) $pitch}
       if {$pitch < $bminpitch($c)} {set bminpitch($c) $pitch}
       }
      }
}


proc hbuildpgram {} {
# We draw the notes horizontally, grouping all the
# notes of the same pitch in the same beat location.
# We can have several pitches (chord) occurring in the
# same beat and same channel. Therefore we separate by
# pitch rather than by channel. It is possible that two
# different channels produces the same pitched note, but
# we assume it does not happen too frequently.
global sorted_pianoresult
global ppqn
set lastbegin 0;
global endpitchstrip
reset_endpitchstrip
foreach line $sorted_pianoresult {
     if {[llength $line] == 6} {
       set begin [expr [lindex $line 0]/$ppqn]
       if {$begin > $lastbegin} {output_pstrip $lastbegin
	                         set lastbegin $begin}
       set t [lindex $line 2]
       set c [lindex $line 3]
       if {$c == 10} continue
       set end [expr [lindex $line 1]/$ppqn]
       set pitch [lindex $line 4]        
       set endpitchstrip($pitch) [list $end $c]
       }
      }
}

proc reset_endpitchstrip {} {
global endpitchstrip
for {set i 1} {$i < 128} {incr i} {
  set endpitchstrip($i) 0
  }
}



proc compute_pgram {} {
global midi
global ppqn
global chn2prg
global exec_out
global sorted_pianoresult
global beats_per_pixel
global pxlbx pxrbx
global briefconsole

set pgraph .pgram.c
$pgraph delete all
.pgram.c create rect -1 -1 -1 -1 -tags mark -fill grey30 -stipple gray25
set pgraphwidth $midi(pgramwidth)
set pxrbx [expr $pgraphwidth - 3]
set pxlbx  40
set ytbx 20
set ybbx [expr $midi(pgramheight) + 20]

$pgraph create rectangle $pxlbx $ytbx $pxrbx $ybbx -outline white\
            -width 2 -fill grey5

incr pxlbx 3
incr pxrbx -3

set exec_options "[list $midi(midifilein)] -midigram"
set cmd "exec [list $midi(path_midi2abc)] $exec_options"
catch {eval $cmd} pianoresult
 if {[string first "no such" $pianoresult] >= 0} {abcmidi_no_such_error $midi(path_midi2abc)}
set pianoresult [split $pianoresult \n]
set sorted_pianoresult [lsort -command compare_onset $pianoresult]
set nrec [llength $pianoresult]
set midilength [lindex $pianoresult [expr $nrec -1]]
set nbeats [expr $midilength/$ppqn]
if {$briefconsole} {
  append exec_out compute_pgram:\n$cmd\n\n[string range $pianoresult 0 200]...
  } else {
  append exec_out compute_pgram:\n$cmd\n\n$pianoresult
  }

Graph::alter_transformation $pxlbx $pxrbx $ybbx $ytbx 0.0 $nbeats 0.0 110.0 
set beats_per_pixel [expr $nbeats/double($pxrbx - $pxlbx)]
pgram_vscale

if {$midi(pgrammode) == "chord"} {
  vbuildpgram
  } else {
  hbuildpgram
  }

p_reveal_buttons 
#update_console_page
}

proc pgram_vscale {} {
global df
set pgraph .pgram.c
for {set i 1} {$i < 10} {incr i} {
  set oct C$i
  set p [expr $i*12 + 12]
  set iy [Graph::iypos $p]
  $pgraph create text 20 $iy -text $oct -font $df
  }
}

proc p_reveal_buttons {} {
global activechan
set butlist [lsort -integer [array names activechan]]
for {set i 1} {$i < 17} {incr i} {
   pack forget .pgram.chn.$i 
   }
foreach but $butlist {
   if {$but == 10} continue
   pack .pgram.chn.$but -side left
   }
}

proc output_pitch_bands {beat} {
global bminpitch
global bmaxpitch
global xchannel2program
global progmapper
global groupcolors
global midi
set pgraph .pgram.c
set thickness $midi(pgramthick)
set ix [Graph::ixpos $beat]
set ix2 [expr $ix+2]
for {set i 0} {$i < 16} {incr i} {
  if {$i == 10} continue
  if {$bminpitch($i) < 128} {
	  set iy1 [Graph::iypos $bminpitch($i)]
	  set iy2 [Graph::iypos $bmaxpitch($i)]
          set p $xchannel2program($i)
          set g [lindex $progmapper $p]
          set kolor [lindex $groupcolors $g]
	  set w [expr $iy1 - $iy2]
	  #puts "i = $i p = $p g = $g kolor = $kolor"
	  if {$w < 3} {set iy1 [expr $iy2+2]}
	  if {$w > 10} {set pat {1 6}
	  } elseif {$w > 5} {set pat {1 3}
          } else {set pat {1 1}}
	  #if {$i == 7} {puts "chn7 : $w $ix $iy1 $ix2 $iy2 $kolor $pat"}
          $pgraph create line $ix $iy1  $ix $iy2\
	      -fill $kolor -dash $pat -tag c$i -width $thickness
          }
  }
reset_pitch_bands
}

proc output_pstrip {beat} {
# create rectangle does not work well here because
# they all have outlines which are not optional.
global endpitchstrip
global xchannel2program
global progmapper
global groupcolors
global midi
set pgraph .pgram.c
set thickness $midi(pgramthick)
set ix [Graph::ixpos $beat]
for {set i 1} {$i < 128} {incr i} {
  if {[llength $endpitchstrip($i)] == 2 } {
	  set iy [Graph::iypos $i]
	  set end [lindex $endpitchstrip($i) 0]
	  set c [lindex $endpitchstrip($i) 1]
          set p $xchannel2program($c)
          set g [lindex $progmapper $p]
          set kolor [lindex $groupcolors $g]
	  set ix2 [expr [Graph::ixpos $end] +3]
          $pgraph create line $ix $iy  $ix2 $iy\
	      -fill $kolor -width $thickness -tag c$c
          }
  }
reset_endpitchstrip
}

proc pgram_limits {can} {
# limits of selected region in midistructure
    global beats_per_pixel
    set co [$can coords mark]
    #   is there a marked region of reasonable extent ?
    set extent [expr [lindex $co 2] - [lindex $co 0]]
    if {$extent > 5} {
        set xleft [expr ([lindex $co 0]-42)*$beats_per_pixel]
        set xright [expr ([lindex $co 2]-42)*$beats_per_pixel]
	set xleft [expr floor($xleft)]
	set xright [expr floor($xright)]
        #puts "midistruct_limits: $xleft $xright beats"
	return "$xleft $xright"
    } else {
        #puts "midistruct_limits: none"
        return none}
}

proc pgram_abc {} {
global midi
global midichannels
global exec_out
set exec_out ""
set limits  [pgram_limits .pgram.c]
set options ""
if {[llength $limits] > 1} {
  set fbeat [lindex $limits 0]
  set tbeat [lindex $limits 1]
  append options " -frombeat $fbeat -tobeat $tbeat "
  } 
  set trkchn ""
  for {set i 1} {$i < 17} {incr i} {
     if {$midichannels($i)} {append trkchn "$i,"}
     }
  if {[string length $trkchn] > 0} {
         append options "-chns $trkchn"}
  set cmd "exec [list $midi(path_midicopy)]  $options"
  lappend cmd  $midi(midifilein) tmp.mid
  catch {eval $cmd} miditime
  append exec_out "$cmd\n\$miditime"

  set title [file root [file tail $midi(midifilein)]]
  set options ""
  if {$midi(midirest) > 0} {set options [concat $options "-sr $midi(midirest)"]}
  set cmd "exec [list $midi(path_midi2abc)] tmp.mid $options -noly -title [list $title]" 
  catch {eval $cmd} result
  append exec_out "\n$cmd"
  edit_abc_output $result
}

proc pgram_play {} {
global midi
global midichannels
global exec_out
set exec_out ""
set limits  [pgram_limits .pgram.c]
set options ""
if {[llength $limits] > 1} {
  set fbeat [lindex $limits 0]
  set tbeat [lindex $limits 1]
  append options " -frombeat $fbeat -tobeat $tbeat "
  } 
  set trkchn ""
  for {set i 1} {$i < 17} {incr i} {
     if {$midichannels($i)} {append trkchn "$i,"}
     }
  if {[string length $trkchn] > 0} {
         append options "-chns $trkchn"}
  set cmd "exec [list $midi(path_midicopy)]  $options"
  lappend cmd  $midi(midifilein) tmp.mid
  catch {eval $cmd} miditime
  append exec_out "$cmd\n\$miditime"

  play_midi_file tmp.mid 
}

#   Part 21.0 Key map

proc keymap_help {} {
set hlp_msg "The function shows how the key signature evolves\
across a midi file on a color coded strip.\
Histograms of the pitch classes are computed\
for blocks of n beats where n is specified in the spacing\
entry box. If the weighted entry box is checked, the histogram\
is weighted by the duration of the notes. The key is determined\
by matching the histogram with either the Krumhansl-Kessler (kk)\
or Craig Sapp's simple coefficients (ss), for the different major and\
minor keys. The key with the highest correlation is plotted in\
color coded form. If the mouse pointer enters into one of the\
color coded boxes, the key associated with that box will\
be shown below. If you left click\
the mouse pointer in one of the boxes, the corresponding normalized\
histogram will appear in a separate window. The correlation values\
for the four best keys will be listed on the right column. 

The colors button will display a legend showing the colors\
for the different keys. Clicking the color button again will\
remove this legend.

The key estimator works better with larger blocks, but may miss\
key changes of short duration. You can apply this algorithm to\
specific channels or tracks by selecting them in the main window\
or the midistructure window.

The keystrip matches the key changes in the entire midi file. Long\
midi files will have more blocks (boxes), so they will appear\
thinner in this display.
"
show_message_page $hlp_msg w
return
}
     
set midi(debug) 0 


# Krumhansl-Kessler coefficients - mean 3.709 removed
# major C scale
array set kkMj {
0       2.87
1       -1.25
2       -0.00
3       -1.15
4       0.90
5       0.61
6       -0.96
7       1.71
8       -1.09
9       0.18
10      -1.19
11      -0.60
}

# Krumhansl-Kessler coefficients - mean 3.4825 removed
# minor C scale (3 flats)
array set kkMn {
0       2.62
1       -1.03
2       -0.19
3       1.67
4       -1.11
5       -0.18
6       -1.17
7       1.04
8       0.27
9       -1.02
10      -0.37
11      -0.54
}

# Craig Sapp's simple coefficients (mkeyscape)
# mean 9/12 removed
# Major C scale
array set ssMj {
0       1.25
1       -0.75
2       0.25
3       -0.75
4       0.25
5       0.25
6       -0.75
7       1.25
8       -0.75
9       0.25
10      -0.75
11      0.25
}

# Minor C scale (3 flats)
array set ssMn {
0       1.25
1       -0.75
2       0.25
3       0.25
4       -0.75
5       0.25
6       -0.75
7       1.25
8       0.25
9       -0.75
10      0.25
11      -0.75
}


array set majorColors {
 0       #00FF00
 1       #26FF8C
 2       #3F5FFF
 3       #E41353
 4       #FF0000
 5       #FFFF00
 6       #C0FF00
 7       #5DD3FF
 8       #8132FF
 9       #CD29FF
 10      #FFA000
 11      #FF6E0A
}


proc keystrip_window {source} {
global midi
global df
set spacelist {3 4 6 8 12 16 18 24 32 36 48 64}
 if {![winfo exist .keystrip.c]} {


    set w .keystrip
    toplevel $w
    positionWindow ".keystrip"
#    frame $w.head
#    button $w.head.but -text configure -font $df
#    pack $w.head.but -side left -anchor w
#    pack $w.head -anchor w

    canvas $w.c -width $midi(stripwindow) -height 50\
         -scrollregion { 0 0 500.0 50}\
         -xscrollcommand "$w.xsc set"
    scrollbar $w.xsc -orient horiz -command {.keystrip.c xview}
    pack $w.c
    pack $w.xsc -fill x
    #pack $w
    frame $w.status
    label $w.status.txt -text "" -font $df
    pack $w.status.txt
    pack $w.status
  frame $w.cfg
    frame $w.cfg.spc
    label $w.cfg.spc.spclab -text keySpacing -font $df
    ttk::combobox $w.cfg.spc.spcbox -textvariable midi(keySpacing) -values $spacelist -width 3
    bind $w.cfg.spc.spcbox <<ComboboxSelected>> {keymap keystrip; focus .keystrip}
    pack  $w.cfg.spc -side top -anchor w
    pack $w.cfg.spc.spclab -side left -anchor w
    pack $w.cfg.spc.spcbox -side left -anchor w
    radiobutton $w.cfg.spc.kk -text kk -value kk -variable midi(pitchcoef) -command "keymap $source" -font $df
    radiobutton $w.cfg.spc.ss -text ss -value ss -variable midi(pitchcoef) -command "keymap $source" -font $df
    checkbutton $w.cfg.spc.w -text pitchWeighting -variable midi(pitchWeighting) -command "keymap $source" -font $df
    button $w.cfg.spc.h -text help -command keymap_help -font $df
    button $w.cfg.spc.c -text colors -command keyscape_keyboard -font $df
    pack $w.cfg.spc.kk $w.cfg.spc.ss $w.cfg.spc.w $w.cfg.spc.c $w.cfg.spc.h -side left -anchor w

   pack $w.cfg

    }
}

proc segment_histogram {beatfrom} {
    global pianoresult midi
    global histogram
    global ppqn
    global midi
    set keySpacing $midi(keySpacing)
    for {set i 0} {$i < 12} {incr i} {set histogram($i) 0}
    set beatstart [expr $beatfrom * $ppqn]
    set beatend [expr ($beatfrom + $keySpacing) * $ppqn]
    foreach line $pianoresult {
        if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        if {$begin < $beatstart} continue
        if {$begin > $beatend} continue
        set end [lindex $line 1]
        set t [lindex $line 2]
        set c [lindex $line 3]
        # ignore percussion channel
        if {$c == 10} continue
        set note [expr [lindex $line 4] % 12]
        set vel [lindex $line 5]
        if {$midi(pitchWeighting)} {
          set dur [expr ($end - $begin)/double($ppqn)]
          set histogram($note) [expr $histogram($note)+$dur]
          } else {
          set histogram($note) [expr $histogram($note)+1]
          }
        }


    set total 0;
    for {set i 0} {$i <12} {incr i} {
        set total [expr $total+$histogram($i)]
    }
    if {$total > 1} {
       for {set i 0} {$i <12} {incr i} {
           set histogram($i) [expr double($histogram($i))/$total]
       }
    }
}




proc keymap {source} {
# derived from pianoroll_statistics
    global pianoresult midi
    global histogram
    global ppqn
    global lastbeat
    global total
    global exec_out
    global midi
    global majorColors
    global stripscale
    global sharpflatnotes
    global df
    global cleanData
    global briefconsole

    #puts "keymap $midi(keySpacing)"
    set sharpflatnotes  {C C# D Eb E F F# G G# A Bb B}

    set keySpacing $midi(keySpacing)

    keystrip_window $source
    .keystrip.c delete all

    if {![file exist $midi(path_midi2abc)]} {
       set msg "cannot find $midi(path_midi2abc). Install midi2abc
from the abcMIDI package and set the path to its location."
      tk_messageBox -message $msg
        return
        }
    if {![file exist $midi(midifilein)]} {
       set msg "cannot find $midi(midifilein). Use the file button to
set the path to a midi file."
       tk_messageBox -message $msg
       return
       }
   set exec_out "keymap\n"
   # copy selected tracks/channels
   copyMidiToTmp $source
   set cleanData 0
   set cmd "exec [list $midi(path_midi2abc)] $midi(outfilename) -midigram"
    catch {eval $cmd} pianoresult
    if {$briefconsole} {
      append exec_out "\n\n$cmd\n\n [string range $pianoresult 0 200]..."
      } else {
      append exec_out "\n\n$cmd\n\n $pianoresult"
      }

    set pianoresult [split $pianoresult \n]
    set ppqn [lindex [lindex $pianoresult 0] 3]
    if {$midi(debug)} {puts "ppqn = $ppqn"}
    set nrec [llength $pianoresult]
    #set midilength [lindex $pianoresult [expr $nrec -1]]
    #set lastbeat [expr $midilength/$ppqn]
    set stripscale [expr 500.0/$lastbeat]
    if {$midi(debug)} {puts "midilength = $midilength lastbeat = $lastbeat"}
    set str1 ""
     for {set i 0} {$i <12} {incr i} {
        append str1 [format "%5s" [lindex $sharpflatnotes $i]]
        }
    if {$midi(debug)} {puts $str1}

    for {set beatfrom 0} {$beatfrom < [expr $lastbeat - $keySpacing]} {set beatfrom [expr $beatfrom + $keySpacing]} {
           segment_histogram $beatfrom
           set key [keyMatch]
           set jc [lindex $key 0]
           if {$jc < 0} continue
           set keysig [lindex $sharpflatnotes $jc][lindex $key 1]
    #puts $keysig
           set x0 [expr $stripscale*$beatfrom]
           set x1 [expr $stripscale*$keySpacing + $x0]
           if {[lindex $key 1] == "minor"} {
             .keystrip.c create rect $x0 25 $x1 1 -fill $majorColors($jc) -tag $keysig -stipple gray50
              } else {
             .keystrip.c create rect $x0 25 $x1 1 -fill $majorColors($jc) -tag $keysig
       }
        .keystrip.c bind $keysig <Enter> "keyDescriptor $keysig %W %x %y"
        bind .keystrip.c  <1> "show_histogram %W %x %y"
         }
  update_console_page
  }


array set keysharpflats {
Cmajor "C major"
C#major "Db major 5 flats"
Dmajor "D major 2 sharps"
Ebmajor "Eb major 3 flats"
Emajor "E major 4 sharps"
Fmajor "F major 1 flats"
F#major "F# major 6 sharps or Gb 6 flats"
Gmajor "G major 1 sharp"
G#major "Ab major 4 flats"
Amajor "A major 3 sharps"
Bbmajor "Bb major 2 flats"
Bmajor "B major 5 sharps"
Cminor "C minor 3 flats"
C#minor "C# minor 4 sharps"
Dminor "D minor 1 flat"
Ebminor "Eb minor 6 flats or D# minor 6 sharps"
Eminor "E minor 1 sharp"
Fminor "F minor 4 flats"
F#minor "F# minor 3 sharps"
Gminor "G minor 2 flats"
G#minor "G# minor 5 sharps"
Aminor "A minor"
Bbminor "Bb minor 5 flats"
Bminor "B minor 2 sharps"
}

proc keyDescriptor {keysig w x y} {
  global midi
  global stripscale
  global keysharpflats
  set str [append $keysig $keysharpflats($keysig)]
  set spacing $midi(keySpacing)
  set xv [.keystrip.c xview]
  set xpos  [expr $x + [lindex $xv 0]*1000] 
  set beatfrom [expr $spacing*floor($xpos/$stripscale/$spacing)]
  append str " at beat $beatfrom"
  .keystrip.status.txt configure -text $str
  }
 

proc displayKeyPitchHistogram {} {
global beatfrom
global rmajmin
global sharpflatnotes
global df
segment_histogram $beatfrom
keymapPlotPitchClassHistogram
keyMatch
if {[llength $rmajmin] < 10} return
set matches [lsort -real -decreasing -indices $rmajmin]
set iy 50
set ix 420 
for {set i 0} {$i <4} {incr i} {
  set j [lindex $matches $i]
  set note [lindex $sharpflatnotes [expr $j/2]]
  set minor [expr $j % 2]
  if {$minor} {set mode minor
   } else {set mode major}
  set str "[format %5.3f [lindex $rmajmin $j]] $note$mode"
  .keypitchclass.c create text $ix $iy -text $str -font $df
  incr iy 15
  }
}

proc show_histogram {w x y} {
global stripscale
global midi
#global df
#global rmajmin
#global sharpflatnotes
global beatfrom

set keySpacing $midi(keySpacing)
set xv [.keystrip.c xview]
set xpos  [expr $x + [lindex $xv 0]*1000]
set beatfrom [expr $keySpacing*floor($xpos/$stripscale/$keySpacing)]
displayKeyPitchHistogram 
}

proc keyMatch {} {
# correlates the normalized histogram with the major and
# minor functions for different keys and returns the result
# with the highest correlation.
global ssMj
global ssMn
global kkMj
global kkMn
global histogram
global midi
global rmajmin
set best 0.0
set bestIndex 0
set bestMode ""

set rmajmin [list]
for {set r 0} {$r < 12} {incr r} {
  set c2M 0.0
  set c2m 0.0
  set h2 0.0
  set hM 0.0
  set hm 0.0

  for {set i 0} {$i < 12} {incr i} {
    set k [expr ($i - $r)%12]
    switch $midi(pitchcoef) {
      kk {set coefM($i) $kkMj($k)
          set coefm($i) $kkMn($k)
          }
      ss {set coefM($i) $ssMj($k)
          set coefm($i) $ssMn($k)
         }
      }

      set c2M [expr $c2M + $coefM($i)*$coefM($i)]
      set c2m [expr $c2m + $coefm($i)*$coefm($i)]
      set h2  [expr $h2 + $histogram($i)*$histogram($i)]
      set hm  [expr $hm + $histogram($i)*$coefm($i)]
      set hM  [expr $hM + $histogram($i)*$coefM($i)]
     }
   if {$h2 < 0.0001} {return "-1 0"}
   set rmaj($r) [expr $hM/sqrt($h2*$c2M)]
   set rmin($r) [expr $hm/sqrt($h2*$c2m)]
   lappend rmajmin $rmaj($r)
   lappend rmajmin $rmin($r)
   }

#search for best match
set str3 ""
set str4 ""
for {set r 0} {$r <12} {incr r} {
    append str3 [format %5.1f $rmaj($r)]
    append str4 [format %5.1f $rmin($r)]
    if {$rmaj($r) > $best} {set best $rmaj($r)
                       set bestIndex $r
                       set bestMode major}
    if {$rmin($r) > $best} {set best $rmin($r)
                       set bestIndex $r
                       set bestMode minor}
    }
if {$midi(debug)} {puts $str3}
if {$midi(debug)} {puts $str4}

return "$bestIndex $bestMode [format %7.3f $best]"
  }


proc keymapPlotPitchClassHistogram {} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global histogram
    global df
    global midi
    set notes {C C# D D# E F F# G G# A A# B}
    set maxgraph 0.0
    set xpos [expr $xrbx -40]
    for {set i 0} {$i < 12} {incr i} {
        if {$histogram($i) > $maxgraph} {set maxgraph $histogram($i)}
    }

    set maxgraph [expr $maxgraph + 0.2]
    set pitchc .keypitchclass.c
    if {[winfo exists .keypitchclass] == 0} {
        toplevel .keypitchclass
        positionWindow ".keypitchclass"
        checkbutton .keypitchclass.circle -text "circle of fifths" -variable midi(pitchclassfifths) -font $df -command keymapPlotPitchClassHistogram
        pack .keypitchclass.circle
        pack [canvas $pitchc -width [expr $scanwidth +130] -height $scanheight]\
                -expand yes -fill both
    } else {.keypitchclass.c delete all}

    $pitchc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill grey
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.0 12.0 0.0 $maxgraph
    Graph::draw_y_ticks $pitchc 0.0 $maxgraph 0.1 2 %3.1f

    set iy [expr $ybbx +10]
    set j 0
    foreach note $notes {
        if {$midi(pitchclassfifths)} {
          set i [expr ($j*7) % 12]
          } else {
          set i $j
          }
        set ix [Graph::ixpos [expr $i +0.5]]
        $pitchc create text $ix $iy -text $note -font $df
        set iyb [Graph::iypos $histogram($j)]
        set ix [Graph::ixpos [expr double($i)]]
        set ix2 [Graph::ixpos [expr double($i+1)]]
        $pitchc create rectangle $ix $ybbx $ix2 $iyb -fill blue
        incr j
    }
    $pitchc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2
}

proc keyscape_keyboard {} {
# plots the color scheme for the different keys.
global majorColors
set w .keystrip
if {[winfo exist $w.keyboard]} {
     pack forget $w.keyboard
     destroy $w.keyboard
     return
     }
canvas $w.keyboard -width 350 -height 100
pack $w.keyboard -anchor w
set nat {0 2 4 5 7 9 11}
set shp {1 3 6 8 10}
set shploc {1 2 4 5 6}
$w.keyboard create text 70 8 -text "Major keys"
$w.keyboard create text 220 8 -text "Minor keys"
for  {set i 0} {$i < 7} {incr i} {
   set x1 [expr $i*20]
   set x2 [expr ($i+1)*20]
   $w.keyboard create rect $x1 90 $x2 40 -fill $majorColors([lindex $nat $i])
   $w.keyboard create rect [expr $x1+150] 90 [expr $x2+150] 40 -fill $majorColors([lindex $nat $i]) -stipple gray50
   }
for  {set i 0} {$i < 5} {incr i} {
   set jc [lindex $shp $i]
   set jl [lindex $shploc $i]
   set x1 [expr $jl*20-7]
   set x2 [expr ($jl+1)*20 -14]
   $w.keyboard create rect $x1 70 $x2 20 -fill $majorColors($jc)
   $w.keyboard create rect [expr $x1+150] 70 [expr $x2+150] 20 -fill $majorColors($jc) -stipple gray50 
   }
}


#   Part 25.0 internals
proc dirhome {} {
set textout ""
set filelist [glob *]
append textout "\tmidiexporer_home\n\n"
set filedata {}
foreach filename $filelist {
        file stat $filename filestats
        lappend filedata [list $filename $filestats(mtime)]
         }
set sorted [lsort -index 1 -decreasing $filedata]
foreach item $sorted {
        append textout [lindex $item 0]
        append textout \t\t
        set t [clock format [lindex $item 1]]
        append textout $t
        append textout \n
        }
show_data_page $textout char 1
#puts $filedata
}

proc cleanup {} {
set filelist [glob *]
foreach item $filelist {
  set ext [file extension $item]
  switch $ext {
          .pgm -
          .svg -
          .mid -
          .xhtml { file delete $item}
  }
 }
 dirhome
}


proc show_data_page {text wrapmode clean} {
    global df
    #remove_old_sheet
    set p .data_info
    if [winfo exist $p] {
        $p.t configure -state normal -font $df
        $p.t delete 1.0 end
    } else {
        toplevel $p
        positionWindow ".data_info"
        text $p.t -height 20 -width 80 -wrap $wrapmode -font $df -yscrollcommand {
            .data_info.ysbar set}
        scrollbar $p.ysbar -orient vertical -command {.data_info.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p -expand true -fill both
	button $p.clean -text cleanup -font $df -command cleanup
    }

    if {$clean == 1} {pack $p.clean
    } else {pack forget $p.clean}

    $p.t tag configure grey -background grey80
    set textlist [split $text \n]
    set lkount 1
    foreach textline $textlist {
        set ln 0
        if {$ln} {
            $p.t insert end $textline\n m$lkount
        } else {
            $p.t insert end $textline\n
        }
        incr lkount
    }
    raise $p .
}


set abcmidilist {path_abc2midi 4.84\
            path_midi2abc 3.59\
            path_midicopy 1.38\
	    path_midistats 0.68\
            path_abcm2ps 8.14.6}


proc show_checkversion_summary {} {
    global abcmidilist
    global midi
    global df
    set p .data_info
    if [winfo exist $p] {
        $p.t configure -state normal -font $df
        $p.t delete 1.0 end
    } else {
        toplevel $p
        positionWindow ".data_info"
        text $p.t -height 20 -width 80 -wrap char -font $df -yscrollcommand {
            .data_info.ysbar set}
        scrollbar $p.ysbar -orient vertical -command {.data_info.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p -expand true -fill both
    }

    set msg "full file path                                   expected version      actual version"
    $p.t insert end "$msg\n\n"

    foreach {path ver} $abcmidilist {
        set result [getVersionNumber $midi($path)]
        # add this line for abcm2ps
        set result [lindex [split $result \n] 0]
        #set msg "$midi($path)\t $result"
        set msg [format "%-40s    %-5s     %-20s" $midi($path) $ver $result]
        $p.t insert end "$msg\n"
    }
        $p.t insert end "\n"
}


#   Part 26.0 aftertouch
#process_event load_mflines extract_all_event_clusters
#countDistinctEventClusters showListOfNumberOfClusters
#showEffectWindow minList maxList createTouchPlot
#plotWideData vertical_scale
#touchplot_Button1Press, touchplot_Button1Motion
#touchplot_Button1Release touchplot_ClearMark
#touchplot_limits plot_event_clusters_on_strip
#extract_all_expressions extract_all_volume
#extract_all_pitchbends extract_all_modulations
#findLastNoteOn copy_midi_segment
#pitchRangeFor pianorollFor aftertouch
#getAllControlSettings displayControlSettings



set debug 0

proc process_event {eventName channel beat} {
# A cluster of events is a set of events of the same
# type 'eventName' occurring in a specific channel
# which are all spaced less than 0.5 beats apart.
#
# eventTime is an array which contains the time of the
# last eventName (pitchbend, volume, ...) encountered for
# a specific MIDI channel. It is used to separate clusters
# of eventName events and to record the start of this
# cluster in the global array events.
global eventTime
global eventClusters
global debug
set dash -
if {[info exist eventTime($eventName$dash$channel)]} {
   set lastBeat $eventTime($eventName$dash$channel)
   set interval [expr $beat - $lastBeat]
   #puts "lastBeat = $lastBeat interval = $interval"
   if {$interval > 0.5} {
     if {$debug} {puts "cluster for $event-$channel at $beat"}
     lappend eventClusters [list $eventName $channel $beat]
     }
   set eventTime($eventName$dash$channel) $beat
   } else {
     if {$debug} {puts "cluster for $event-$channel at $beat"}
     lappend eventClusters [list $eventName $channel $beat]
     set eventTime($eventName$dash$channel) $beat
   }
}


proc load_mflines {} {
# Reads a specific midi file, interprets all the messages
# using midi2abc -mftext and returns all the messages
# in the global array mflines.
global mflines
global midi
set cmd "exec [list $midi(path_midi2abc)] [list $midi(midifilein)] -mftext"
catch {eval $cmd} mftextresults
set exec_out $mftextresults
if {[string first "no such" $exec_out] >= 0} {puts "no such file $midi(path_midi2abc)"}
set mftextresults [string map {\" {} \{ {} \} {}} $mftextresults]
set midicommands [split $mftextresults \n]
set mflines [lsort -command compare_onset $midicommands]
}

proc extract_all_event_clusters {} {
global mflines
global eventClusters
global debug
load_mflines
set eventClusters {}
set k 0
foreach line $mflines {
  set gotbeat [scan $line %7f%n beat length] 
  if !$gotbeat continue
  set lline [string range $line $length end]
  set gotkeyword [scan $lline %s%n keyword length]
  set lline [string range $lline $length end]
  #puts "$keyword $length"
  switch $keyword {
        Note {set type note
              scan $lline %d%n channel length
              set  lline [string range $lline $length end]
              scan $lline %s%n onOff length
              set  lline [string range $lline $length end]
              if {$debug} {puts "$beat\t$type $onOff $channel"}
              }
        Pressure {
              set type pressure
              scan $lline %d%n channel length
              set  lline [string range $lline $length end]
              if {$debug} {puts "$beat\t$type $channel"}
              process_event $type $channel $beat
              }
        Pitchbend {set type pitchbend
              scan $lline %d%n channel length
              set  lline [string range $lline $length end]
              scan $lline %d%n bend length
              if {$debug} {puts "$beat\t$type $channel $bend"}
              process_event $type $channel $beat
              }
        Metatext {set type metatext
              set rest $lline
              if {$debug} {puts "$beat\t$type $rest"}
              }
        Meta {set type meta
              set rest $lline 
              if {$debug} {puts "$beat\t$type $rest"}
              }
        Program  {set type program}
        CntlParm {set type cntl
              scan $lline %d%n channel length
              set  lline [string range $lline $length end]
              scan $lline %s%n ctltype length
              set  rest [string range $lline $length end]
              switch $ctltype {
                Expression {
                            scan $rest " = %d" expValue
                            process_event $ctltype $channel $beat
                            }
                ModulationWheel {
                            scan $rest " = %d" modValue
                            process_event $ctltype $channel $beat
                            }
                Volume     {
                            scan $rest " = %d" volValue
                            process_event $ctltype $channel $beat
                           }
                Effects    {
                            scan $rest " = %d" effValue
                            puts "effValue = $effValue"
                            process_event $ctltype $channel $beat
                           }
                Chorus     {
                            scan $rest " = %d" chorValue
                            puts "chorValue = $chorValue"
                            process_event $ctltype $channel $beat
                           }
                Sound      {
                            scan $rest " = %d" soundValue
                            puts "soundValue = $soundValue"
                            process_event $ctltype $channel $beat
                           }
                HoldPedal  {
                            scan $rest " = %d" pedalValue
                            process_event $ctltype $channel $beat
                           }
                }
              if {$debug} {puts "$beat\t$type $channel $ctltype$rest"}
              }
        default {set type other
                 puts "$beat\t***$line"
                }
    }

 incr k
    }
}

proc countDistinctEventClusters {} {
global eventClusters
global chanlist
global typelist
global dEvents
array unset dEvents
set typelist {}
set chanlist {}
foreach e $eventClusters {
  set chan [lindex $e 1]
  set ctype [lindex $e 0]
  set elem $ctype-$chan
  if {[lsearch  $typelist $ctype] < 0} {lappend typelist $ctype} 
  if {[lsearch  $chanlist $chan] < 0} {lappend chanlist $chan} 
  if {[info exist dEvents($elem)]} {
       incr dEvents($elem)
       } else {
       set dEvents($elem) 1
       }
  }
#puts [array get dEvents]
#puts $typelist
set chanlist [lsort -integer $chanlist]
#puts $chanlist
}

proc showListOfNumberOfClusters {} {
global chanlist
global typelist
global dEvents
foreach c $chanlist {
  set line $c
  foreach t $typelist {
    set e $t-$c
    if {[info exist dEvents($e)]} {
      append line " $e = $dEvents($e)"
      }
    }
  }
}



set hlp_effect "Effect\n
Many midi files modify the voicing of the notes using a sequence\
of pitchbends or control messages.\
These messages apply to only a specific channel.\
There are many different control messages. They include ModulationWheel,\
Volume, Expression, etc.\
These messages can be seen using the view/mftext menu button.\n\n\
These messages frequently appear in clusters where a cluster is\
defined as a sequence of messages separated by less than half a beat.\
The number of clusters for a particular message and channel are\
indicated on the exposed buttons. If you click on one of those buttons\
a new window (touchplot) will pop up showing the placement of these\
messages in graphical format.  This is described in a separate help text.
"


set hlp_touchplot "After Touch Graph\n
One of the after touch messages (pitchbend, pressure, control parameter,...)\
is plotted as a function of time (beat number) for a particular channel.\
The plot covers the entire duration of the midi file, but only a small\
region is displayed. The bottom scroll button allows you to shift the\
plot horizontally.\n\n\
The strip above the scroll bar, shows the locations of the after touch\
messages. Shifting the scroll button near the locations will expose the\
the corresponding messages.\n\n\
For reference, the notes are also plotted in piano roll form. Clicking\
the play button will play the notes modified by these messages for the\
exposed region. (You can also designate a selection of notes by\
highlighting an area.). The 'play plain' will play the notes while ignoring\
all of these messages. The 'play all' will play all the channels for\
the exposed (selected) region.\n\n\
Unlike the piano roll view, there is no zoom/unzoom function here.\
The 'effect' window allows you to control the temporal resolution\
of this plot by varying the number of pixels per beat in the top\
menu. Small values spaces the beats closer together and exposes\
a larger time area.
"


proc showEffectWindow {} {
global chanlist
global typelist
global dEvents
global df
if {![winfo exist .effect]} {
   toplevel .effect
   frame .effect.h
   pack  .effect.h -anchor w
   label .effect.h.lab -text "There are no useful control messages in this file"
   button .effect.h.hlp -text help -font $df -command {show_message_page $hlp_effect word}
   set res .effect.h.res.menu
   menubutton .effect.h.res -text "pixels/per beat" -font $df\
      -menu .effect.h.res.menu
   menu  .effect.h.res.menu -tearoff 0
   $res add radiobutton -label 30 -font $df -variable midi(tres) -val 30
   $res add radiobutton -label 40 -font $df -variable midi(tres) -val 40
   $res add radiobutton -label 50 -font $df -variable midi(tres) -val 50
   $res add radiobutton -label 60 -font $df -variable midi(tres) -val 60
   $res add radiobutton -label 70 -font $df -variable midi(tres) -val 70

   pack .effect.h.lab .effect.h.hlp .effect.h.res -anchor w -side left
   }
set ef .effect.f
destroy $ef
frame $ef
pack $ef
label $ef.0 -text channel -font $df -borderwidth 2 
grid $ef.0 -row 0 -sticky w
set k 1
foreach t $typelist {
   label $ef.$k -text $t -font $df -borderwidth 2 -padx 2\
    -width 15 -anchor w
   grid $ef.$k -row $k -column 0
   tooltip::tooltip $ef.$k $t
   incr k
   } 
set j 1
foreach c $chanlist {
   label $ef.$k -text $c -font $df -borderwidth 2 -relief flat
   grid $ef.$k -column $j -row 0
   incr k
   incr j
   }

set n 0
foreach e [array names dEvents] {
  set ev [split $e -]
  set t [lindex $ev 0]
  set c [lindex $ev 1]
  set rowNum [lsearch $typelist $t]
  incr rowNum 
  set colNum [lsearch -exact $chanlist $c]
  incr colNum
  set v $dEvents($e)
  if {$t == "pitchbend"} {
    button $ef.i$n -width 3 -text $v -font $df -command "extract_all_pitchbends $c" -bd 2
    } elseif {$t == "ModulationWheel"} {
    button $ef.i$n -width 3 -text $v -font $df -command "extract_all_modulations $c" -bd 2
    } elseif {$t == "Expression"} {
    button $ef.i$n -width 3 -text $v -font $df -command "extract_all_expressions $c" -bd 2
   } elseif  {$t == "Volume"} {
    button $ef.i$n -width 3 -text $v -font $df -command "extract_all_volume $c" -bd 2
   } elseif  {$t == "HoldPedal"} {
    button $ef.i$n -width 3 -text $v -font $df -command "extract_all_pedals $c" -bd 2
   } elseif  {$t == "pressure"} {
    button $ef.i$n -width 3 -text $v -font $df -command "extract_all_pressures $c" -bd 2
   }

  grid $ef.i$n -column $colNum -row $rowNum
  incr n
  }
#puts "n = $n"
if {$n > 2} {.effect.h.lab configure -text ""}
}



proc minList {data} {
#returns the minimum of the contents of the data list.
set min 100000.0
foreach item $data {
  if {$item < $min} {set min $item}
  }
return $min
}

proc maxList {data} {
#returns the maximum of the contents of the data list.
set max -1000000.0
foreach item $data {
  if {$item > $max} {set max $item}
  }
return $max
}

proc createTouchPlot {plotcanvas WideWidth channel} {
  global df
  global midi
  global hlp_touchplot
  toplevel .touchplot
  wm resizable .touchplot 0 0
  frame .touchplot.1
  frame .touchplot.1a
  frame .touchplot.2
  pack .touchplot.1 .touchplot.1a .touchplot.2 -anchor w
  button .touchplot.1.b -text play -font $df -command "copy_midi_segment $channel 0"
  button .touchplot.1.bp -text "play plain" -font $df -command "copy_midi_segment $channel 1"
  button .touchplot.1.ba -text "play all" -font $df -command "copy_midi_segment $channel 2"
  tooltip::tooltip .touchplot.1.b "Play with all effects"
  tooltip::tooltip .touchplot.1.bp "Play with no effects"
  tooltip::tooltip .touchplot.1.ba "Play all channels with effects"

  label .touchplot.1.speedlabel -text speed -font $df
  scale .touchplot.1.scale -length 100 -from 0.1 -to 2.0\
-orient horizontal -resolution 0.02 -width 10 -variable midi(speed) -font $df
 button .touchplot.1.help -text help -font $df -command {show_message_page $hlp_touchplot word}
  pack .touchplot.1.b .touchplot.1.bp .touchplot.1.ba .touchplot.1.speedlabel .touchplot.1.scale .touchplot.1.help  -side left
  label .touchplot.1a.lab -text "" -font $df
  pack .touchplot.1a.lab
  canvas $plotcanvas -width $midi(tplotWidth) -height 330 -xscrollcommand ".touchplot.scr set" -scrollregion "0 0 $WideWidth 330"
  canvas .touchplot.2.scale -width 50 -height 330 
  pack .touchplot.2.scale $plotcanvas -side left
  canvas .touchplot.strip -width [expr $midi(tplotWidth) + 50] -height 15 -bg seashell3 
  scrollbar .touchplot.scr -orient horiz -width 20 -command {.touchplot.2.c xview }
  pack .touchplot.strip
  pack .touchplot.scr -fill x -expand 1
}


proc plotWideData {xData yData channel color name} {
#plots xData values versus yData values
  global midi
  global df
  global WideWidth
  global touchPlotMaxx
  set plotcanvas .touchplot.2.c
  set hgraph ""
  set miny [minList $yData]
  set maxy [maxList $yData]
  set minx 0.0
  set maxx [expr 1 + floor([maxList $xData)]]
  set touchPlotMaxx $maxx
  set miny [expr $miny -10]
  set maxy [expr $maxy +10]
  set xstep 2.0
  set WideWidth [expr $midi(tres) * $maxx]
  .effect.h.lab configure -text ""
  set leftEdge 0
  set rightEdge $WideWidth
  foreach x $xData y $yData {
      lappend hgraph $x $y
      }
  if {[winfo exists .touchplot] == 0} {
        createTouchPlot $plotcanvas $WideWidth $channel
        positionWindow .touchplot
        } else {
        $plotcanvas delete all
        $plotcanvas configure -scrollregion "0 0 $WideWidth 330"
        .touchplot.1.b configure -command "copy_midi_segment $channel 0"
        .touchplot.1.bp configure -command "copy_midi_segment $channel 1"
        }
   bind .touchplot.2.c <ButtonPress-1> {touchplot_Button1Press %x %y}
   bind .touchplot.2.c <ButtonRelease-1> touchplot_Button1Release
   bind .touchplot.2.c <Double-Button-1> touchplot_ClearMark
   .touchplot.2.c create rect -1 -1 -1 -1 -tags mark -fill gray35 -stipple gray12
   .touchplot.1a.lab  configure -text "$name for channel $channel" \
   -font $df -justify left
   $plotcanvas create rectangle $leftEdge 300 $rightEdge 20 -outline black -width 2 -fill white
   Graph::alter_transformation $leftEdge $rightEdge 300 20 $minx $maxx $miny $maxy
   #Graph::draw_x_ticks $plotcanvas $minx $maxx $xstep 1 0 %3.1f
   Graph::draw_x_grid $plotcanvas $minx $maxx $xstep 1 0 %3.1f

   vertical_scale .touchplot.2.scale $miny $maxy
   pianorollFor $channel $minx $maxx

   Graph::draw_points_from_list $plotcanvas $hgraph $color
   join_points_with_curve $plotcanvas $hgraph
   plot_event_clusters_on_strip $name $channel $minx $maxx
   }

proc join_points_with_curve {can datapoints} {
set lastx 0
set points {}
foreach {x y} $datapoints {
  if {[expr $x - $lastx] > 0.4} {
      if {[llength $points] > 2} {
         Graph::draw_curve_from_list $can $points black
         }
      set points {}
    }
  lappend points $x
  lappend points $y
  set lastx $x
  }
if {[llength $points] > 2} {
      Graph::draw_curve_from_list $can $points black
    }
}



proc plotHoldPedal {xData yData channel color name} {
#plots xData values versus yData values
  global midi
  global df
  global WideWidth
  global touchPlotMaxx
  set plotcanvas .touchplot.2.c
  set hgraph ""
  set miny [minList $yData]
  set maxy [maxList $yData]
  .effect.h.lab configure -text ""
  if {$miny == $maxy} {
    .effect.h.lab configure -text "Can't display pedal data"
    return
    }
  set minx 0.0
  set maxx [expr 1 + floor([maxList $xData)]]
  set touchPlotMaxx $maxx
  set xstep 2.0
  set WideWidth [expr $midi(tres) * $maxx]
 #puts "WideWidth = $WideWidth"
  set leftEdge 0
  set rightEdge $WideWidth
  if {[winfo exists .touchplot] == 0} {
        createTouchPlot $plotcanvas $WideWidth $channel
        positionWindow .touchplot
        } else {
        $plotcanvas delete all
        $plotcanvas configure -scrollregion "0 0 $WideWidth 330"
        .touchplot.1.b configure -command "copy_midi_segment $channel 0"
        .touchplot.1.bp configure -command "copy_midi_segment $channel 1"
        }
   bind .touchplot.2.c <ButtonPress-1> {touchplot_Button1Press %x %y}
   bind .touchplot.2.c <ButtonRelease-1> touchplot_Button1Release
   bind .touchplot.2.c <Double-Button-1> touchplot_ClearMark
   .touchplot.2.c create rect -1 -1 -1 -1 -tags mark -fill gray35 -stipple gray12
   .touchplot.1a.lab configure -text "$name for channel $channel"
   $plotcanvas create rectangle $leftEdge 300 $rightEdge 20 -outline black -width 2 -fill white
   Graph::alter_transformation $leftEdge $rightEdge 300 20 $minx $maxx $miny $maxy
   #Graph::draw_x_ticks $plotcanvas $minx $maxx $xstep 1 0 %3.1f
   Graph::draw_x_grid $plotcanvas $minx $maxx $xstep 1 0 %3.1f

   vertical_scale .touchplot.2.scale $miny $maxy 
   pianorollFor $channel $minx $maxx

  foreach x $xData y $yData {
      if {$y == 127} {set ix1 [Graph::ixpos $x]}
      if {$y == 0  } {set ix2 [Graph::ixpos $x]
                      if {[info exist ix1]} {
                         $plotcanvas create rect $ix1 20 $ix2 300 -fill orange -stipple gray12}
                     }
      }

   plot_event_clusters_on_strip $name $channel $minx $maxx
   }




proc vertical_scale {c miny maxy} {
global df
$c delete all
if {[expr $maxy - $miny] > 140} {
   set step 40
   } else {
   set step 20
   }
set y_scale [expr 250.0 / ($maxy - $miny)]
set y_shift [expr 270.0 + $miny*$y_scale]
set miny [expr round($miny/10)*10]
for {set y $miny} {$y < $maxy} {set y [expr $y + $step]} {
  set iy [expr $y_shift - $y * $y_scale]
  set str [format %4.0f $y]
  $c create line 40 $iy 49 $iy
  $c create text 20 $iy -text $str -font $df
  }
}

proc touchplot_Button1Press {x y} {
    set touchplotHeight 330
    set xc [.touchplot.2.c canvasx $x]
    .touchplot.2.c raise mark
    .touchplot.2.c coords mark $xc 20 $xc $touchplotHeight
    bind .touchplot.2.c <Motion> { touchplot_Button1Motion %x }
}


proc touchplot_Button1Motion {x} {
    set touchplotHeight 300
    set xc [.touchplot.2.c canvasx $x]
    if {$xc < 0} { set xc 0 }
    set co [.touchplot.2.c coords mark]
    .touchplot.2.c coords mark [lindex $co 0] 20 $xc $touchplotHeight
}

proc touchplot_Button1Release {} {
    bind .touchplot.2.c <Motion> {}
    set co [.touchplot.2.c coords mark]
   }

proc touchplot_ClearMark {} {
    .touchplot.2.c coords mark -1 -1 -1 -1
}



proc touchplot_limits {} {
global WideWidth
global touchPlotMaxx
set co [.touchplot.2.c coords mark]
#   is there a marked region of reasonable extent ?
set extent [expr [lindex $co 2] - [lindex $co 0]]
if {$extent > 10} {
        set start [expr [lindex $co 0]/($WideWidth -50.0)]
        set end   [expr [lindex $co 2]/($WideWidth -50.0)]
        set fbeat  [expr $start * $touchPlotMaxx]
        set tbeat  [expr $end   * $touchPlotMaxx]
  } else {
        set xv [.touchplot.2.c xview]
        set fbeat [expr [lindex $xv 0]  * $touchPlotMaxx]
        set tbeat [expr [lindex $xv 1]  * $touchPlotMaxx]
        }
#puts "fbeat = $fbeat tbeat = $tbeat"
return [list $fbeat $tbeat]
}

proc plot_event_clusters_on_strip {name channel minx maxx} {
global eventClusters
global midi
Graph::set_xmapping 0 $midi(tplotWidth) 0.0 $maxx
.touchplot.strip delete all
#puts "name = $name"
foreach event $eventClusters {
   set n [lindex $event 0]
   set c [lindex $event 1]
   set x [lindex $event 2]
   set ix [expr [Graph::ixpos $x] + 23]
   if {$n == $name && $c == $channel} {
     .touchplot.strip create line $ix 0 $ix 15
     }
   }
} 

proc extract_all_expressions {channel} {
# extracts and plots all pitchbend messages
# between beats from and to.
global mflines
global xData yData
load_mflines
set xData {}
set yData {}
set lastbeat 0.0
foreach line $mflines {
    set gotdata [scan $line %6f%s%d%s%n beat key c s length] 
    #puts "$line\ngotdata=$gotdata"
    if {$gotdata != 5} continue
    if {$c !=$channel} continue    
    if {$s != "Expression"} continue
    set lline [string range $line $length end]
    scan $lline %s%d dummy value
    lappend xData $beat   
    lappend yData $value
    set lastbeat $beat
    }
plotWideData $xData $yData $channel brown Expression
}

proc extract_all_volume {channel} {
# extracts and plots all pitchbend messages
# between beats from and to.
global mflines
global xData yData
load_mflines
set xData {}
set yData {}
set lastbeat 0.0
foreach line $mflines {
    set gotdata [scan $line %6f%s%d%s%n beat key c s length]
    #puts "$line\ngotdata=$gotdata"
    if {$gotdata != 5} continue
    if {$c !=$channel} continue
    if {$s != "Volume"} continue
    set lline [string range $line $length end]
    scan $lline %s%d dummy value
    lappend xData $beat
    lappend yData $value
    set lastbeat $beat
    }
plotWideData $xData $yData $channel blue Volume
}


proc extract_all_pitchbends {channel} {
# extracts and plots all pitchbend messages
# between beats from and to.
global mflines
global xData yData
load_mflines
set k 0
set xData {}
set yData {}
set lastbeat 0.0
foreach line $mflines {
    set gotdata [scan $line %6f%s%d%d%n beat key c bend length] 
    #puts "$line\ngotdata=$gotdata"
    if {$gotdata <3} continue
    if {$c !=$channel} continue    
    if {$key != "Pitchbend"} continue
    set bend  [expr $bend - 8192]
    set bend  [expr $bend/40.96]
    #puts "key = $key c = $c bend = $bend"
    #puts "value = $value"
    lappend xData $beat   
    lappend yData $bend
    incr k
    set lastbeat $beat
    }
plotWideData $xData $yData $channel brown pitchbend
}



proc extract_all_modulations {channel} {
# extracts and plots all control modulation messages
global mflines
global xData yData
load_mflines
set k 0
set xData {}
set yData {}
#puts "extract_modulation $channel $from"
foreach line $mflines {
    set gotdata [scan $line %6f%s%d%s%n beat key c s length] 
    if {$gotdata != 5} continue
    #puts "$line\ngotdata=$gotdata"
    if {$c !=$channel} continue    
    if {$s != "ModulationWheel"} continue
    set lline [string range $line $length end]
    scan $lline " = %d" value
    #puts "value = $value"
    lappend xData $beat   
    lappend yData $value
    incr k
    }

plotWideData $xData $yData $channel green ModulationWheel
}

proc extract_all_pedals {channel} {
# extracts and plots all control modulation messages
global mflines
global xData yData
load_mflines
set k 0 
set xData {}
set yData {}
foreach line $mflines {
    #puts $line
    set gotdata [scan $line %6f%s%d%s%n beat key c s length]
    if {$gotdata != 5} continue
    #puts "$line\ngotdata=$gotdata"
    if {$c !=$channel} continue
    if {$s != "HoldPedal"} continue
    set lline [string range $line $length end]
    scan $lline " = %d" value
    #puts "value = $value"
    lappend xData $beat   
    lappend yData $value
    incr k
    }
#puts "Pedal xData = $xData"
#puts "Pedal yData = $yData"
#plotWideData $xData $yData $channel green ModulationWheel
plotHoldPedal $xData $yData $channel green HoldPedal
}

proc extract_all_pressures {channel} {
# extracts and plots all control modulation messages
global mflines
global xData yData
load_mflines
set k 0
set xData {}
set yData {}
foreach line $mflines {
    set gotdata [scan $line %6f%s%d%n beat key c length]
    #puts "$line\ngotdata=$gotdata"
    if {$gotdata != 4} continue
    #puts "$line\ngotdata=$gotdata"
    if {$c !=$channel} continue
    #puts "key = $key"
    if {$key != "Pressure"} continue
    set lline [string range $line $length end]
    set n [scan $lline "%s %d" dummy value]
    incr k
    lappend xData $beat
    lappend yData $value
    }
plotWideData $xData $yData $channel purple pressure
}

 

proc findLastNoteOn {channel fbeat} {
global mflines
set k 0
foreach line $mflines {
    #puts $line
    set gotdata [scan $line %6f%s%s%d beat key dummy c] 
    if {$gotdata < 4} continue
    if {$beat > $fbeat} break
    if {$c != $channel} continue
    if {$key == "Note"} {set notebeat $beat}
    incr k
    }
#puts "notebeat = $notebeat"
return $notebeat
}

proc copy_midi_segment {channel method} {
    global midi
    global exec_out
    set midi(outfilename) tmp.mid
    set limits [touchplot_limits]
    set fbeat [lindex $limits 0]
    set tbeat [lindex $limits 1]
    if {$method != 2} {set cmd "exec [list $midi(path_midicopy)] -chns $channel "
    } else {
    set  cmd "exec [list $midi(path_midicopy)] "
    }
    #set fbeat [findLastNoteOn $channel $fbeat]
    append cmd " -frombeat $fbeat -tobeat $tbeat"
    append cmd " -speed $midi(speed) "
    if {$method == 1} {
      append cmd " -nobends -nopressure -nocntrl "
      }
    append cmd " [list $midi(midifilein)] tmp.mid"
    catch {eval $cmd} midicopyresult
    set exec_out "$cmd\n $midicopyresult\n"

    set cmd "exec [list $midi(path_midiplay)] $midi(midiplay_options) "
    set cmd [concat $cmd [file join [pwd] tmp.mid]]
    set cmd [concat $cmd &]
    puts $cmd
    catch {eval $cmd} midiplayeresult
    return $midiplayeresult
}

proc pitchRangeFor {channel} {
global mflines
set low 128
set high 0
foreach line $mflines {
    set gotdata [scan $line "%6f%s%s%d%d" beat key1 key2 c pitch] 
    if {$gotdata < 5} continue
    if {$c != $channel} continue
    if {$key1 != "Note"} continue
    #puts "$key1 $key2 $c $pitch"
    if {$pitch > $high} {set high $pitch}
    if {$pitch < $low} {set low $pitch}
   }
return "$low $high"
}

proc pianorollFor {channel minx maxx} {
global midi
global pianoxscale
global midilength
global ppqn
global WideWidth
set plotcanvas .touchplot.2.c
set pitchmax [lindex [pitchRangeFor $channel] 1]
set pitchmax [expr $pitchmax +6]
set cmd "exec [list $midi(path_midi2abc)] [list $midi(midifilein)] -midigram"
catch {eval $cmd} pianoresult
set nrec [llength $pianoresult]
set midilength [lindex $pianoresult [expr $nrec -1]]
set pianoresult [split $pianoresult \n]
set header [lindex $pianoresult 0]
set ppqn [lindex  $header 3]
Graph::set_xmapping 0 $WideWidth 0.0 $maxx
foreach line $pianoresult {
  if {[llength $line ] != 6} continue
  set begin [expr [lindex $line 0] / double($ppqn)]
  if {[string is double $begin] != 1} continue
  set end [expr [lindex $line 1] / double($ppqn)]
  set c [lindex $line 3]
  if {$c != $channel} continue
  set pitch [lindex $line 4]
  set ix1 [Graph::ixpos $begin]
  set ix2 [Graph::ixpos $end]
  set iy [expr 20  + ($pitchmax - $pitch)*5]
  #puts "begin = $begin end = $end ix1 = $ix1 iy = $iy"
  if {$iy < 300} {$plotcanvas create line $ix1 $iy $ix2 $iy -width 6 -fill grey}
  }
}


proc aftertouch {} {
extract_all_event_clusters
countDistinctEventClusters
showListOfNumberOfClusters
showEffectWindow
positionWindow .effect
}



proc getAllControlSettings {} {
global mflines
global controlSettings
set notefound {0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0}
set f "%7f CntlParm %d %s = %d" 
set controlSettings {}
load_mflines 
foreach line $mflines {
  set n [scan $line $f beat chan cntrltype value]
  if {$n == 4 && [lindex $notefound $chan] == 0} {
     set cntlsetting [list $cntrltype $chan $value]
     lappend controlSettings $cntlsetting}
  set n [scan $line "%7f Note on %d" beat chan]
  if {$n == 2} {
               set notefound [lreplace $notefound $chan $chan 1]
               }
  }
displayControlSettings
}

set hlp_csettings "Initial Control Change Settings\n\n\
These are the control settings that appear in the MIDI\
file before the first note-on message. These settings\
adjust how the notes are played. For example, the loudness\
of the instrument is controlled by either or both the\
volume and expression variables. Many of the other control\
change parameters presented here are not applicable\
without a specific MIDI synthesizer. They are displayed\
here because they are in the MIDI file. 
"

proc displayControlSettings {} {
global controlSettings
global df
global hlp_csettings
set controlNames {}
set controlChannels {}
foreach setting $controlSettings {
    set name [lindex $setting 0]
    set channel [lindex $setting 1]
    if {[lsearch $controlNames $name] < 0} {
      lappend controlNames $name}
    if {[lsearch $controlChannels $channel] < 0} {
      lappend controlChannels $channel
      }
    }
set cset .csettings.f
if {![winfo exist .csettings]} {
  toplevel .csettings
  positionWindow .csettings
  frame .csettings.h
  button .csettings.h.help -text help -font $df\
    -command {show_message_page $hlp_csettings word}
  pack .csettings.h.help -anchor w
  pack .csettings.h -anchor w
  } else {
  destroy $cset
  }

frame $cset
pack $cset

label $cset.c -text Channel -font $df -anchor w
set rowno 0
grid $cset.c -row $rowno -sticky w
set k 0
set col 1
foreach ch $controlChannels {
  label $cset.$k -text $ch -font $df
  grid $cset.$k -row $rowno -column $col
  set chan2col($ch) $col
  incr k
  incr col
  }
set rowno 1
foreach na $controlNames {
  label $cset.$k -text $na -font $df -anchor w
  set name2row($na) $rowno
  grid $cset.$k -row $rowno -column 0 -sticky w
  incr rowno
  incr k
  }

foreach setting $controlSettings {
    set name [lindex $setting 0]
    set channel [lindex $setting 1]
    set rownum $name2row($name)
    set col $chan2col($channel)
    set value [lindex $setting 2]
    label $cset.$k -text $value -font $df
    grid $cset.$k -row $rownum -column $col
    incr k
    }
}


#   Part 27.0 notebook

proc notebook {} {
#This is an undocumented feature for appending a
#melody.txt file with the name of the file and
#melody instrument. The file save/melody.txt should
#exist.
global midi df
global notedata

set notedata ""
toplevel .notebook
label .notebook.lab -text $midi(midifilein) -font $df
pack .notebook.lab
entry .notebook.ent -textvariable notedata -width 20 -font $df
pack .notebook.ent
button .notebook.app -text append -font $df -command add_note 
pack .notebook.app
focus .notebook.ent
}

proc add_note {} {
global midi
global notedata
set outhandle [open save/melody.txt a]
set front [string length $midi(rootfolder)]
incr front
set filename [string range $midi(midifilein) $front end]
puts $outhandle "$filename\t$notedata"
close $outhandle
destroy .notebook
}

proc count_bar_rhythm_patterns {} {
# The function counts the number of unique rhythm patterns
# in each channel. The code was extracted from full_notedata_analysis
# which is called by pitch analysis/entropy analysis/ rhythm map/ map all.	
# This data is useful for finding the channel carrying the melody.	
global midi
global pianoresult
global midilength
global lasttrack
global midicommands
global ntrks

set cmd "exec [list $midi(path_midi2abc)] [list $midi(midifilein)] -midigram"
catch {eval $cmd} pianoresult
set nrec [llength $pianoresult]
set midilength [lindex $pianoresult [expr $nrec -1]]
set beatsperbar 4
set midicommands [lsort -command compare_onset [split $pianoresult \n]]

if {$midi(midishow_sep) == "track"} {
   set ntrks $lasttrack
   incr ntrks} else {
   set ntrks 17
   }

set result [get_all_note_patterns]
set notepat [lindex $result 0]
set bar_rhythm [lindex $result 1]

set output $midi(midifilein)
for {set c 0} {$c < $ntrks} {incr c} {
  if {[dict exists $bar_rhythm $c,size]} {
    set size  [dict get $bar_rhythm $c,size]
    #puts "bar_rhythm:\n$bar_rhythm"
    set rhythmhistogram [make_string_histogram_for $bar_rhythm $c $size]
    set rhythmsize [llength [dict keys $rhythmhistogram]]
    append output "\n$c $rhythmsize"
    }
  }
show_message_page  $output word
}

#trace add execution compute_pianoroll leave "cmdstr"

restore_root_folder 

