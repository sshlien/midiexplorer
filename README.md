### Introduction

Midiexplorer is a tool for exploring and analyzing a large collection of MIDI
files. In particular, it was developed for managing the **Clean MIDI subset**
that can be downloaded from <https://colinraffel.com/projects/lmd/>. This
collection contains approximately 17,000 MIDI files organized by artist. If
you download this collection, then you should also get the folder
**lakh_playlist** which links the various music genres to this collection.

Midiexplorer contains various visualization tools. It can extract the
characteristics of these files and store them in a database. This database can
be used to search for files having certain attributes.

The latest documentation is found on <https://midiexplorer.sourceforge.io/>.

### Requirements

With one exception (see below), you will require tcl/tk 8.5 or higher and some
other executables installed on your system. On Linux, you start midiexplorer
by typing

    
    
    wish midiexplorer.tcl
    

On Windows you would double click on the midiexplorer.tcl icon.

Midiexplorer depends on many external applications. If you are running runabc,
then you probably have these externals.

It requires a midi player (either commercial or freeware). Several players are
suggested in the documentation.

Midiexplorer requires the executables midicopy, midi2abc, abc2midi which are
part of the abcmidi project. The latest source code to these externals as well
as midiexplorer.tcl can be found on <https://ifdo.ca/~seymour/runabc/top.html>
The source code can also be found on
<https://sourceforge.net/projects/abcmidi/> or
<https://github.com/sshlien/abcmidi> but they are not updated frequently.

You also require an internet browser in order to use some of the features.

Binaries for various operating systems can be found on
<http://abcplus.sourceforge.net/>

If you running on a Windows operating system (Windows 10, 8.1, 8,0, 7, or XP),
then you can install midiexplorer from
<https://sourceforge.net/projects/midiexplorer/>. The windows_binary folder
contains win32 executables that allow you to avoid installing Tcl/Tk. You will
still need an external midi player.

