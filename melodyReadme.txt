Here is a random selection of midi files from the Clean Lakh Dataset
which I analyzed. My object was to identify the channel number
(from 1 to 16) which carries the main tune. This is usually sung
by the vocalist. Following the tab in each line, there are two
numbers. The first number is the channel number containing the
melody. The second number is the General Midi program number
starting from 0 (Acoustic Piano).

In some cases, I was unable to identify a melody in any of the
channels. I used the code -1 -1 to denote this situation.
In a few cases, the melody shifts around several instruments
and midi channels. In other cases, two channels may carry the
melody line. Only one of the channels is indicated.

For some midi files, the channel carrying the melody is barely
audible. You may need to use a mixer to attenuate the other
channels which drown out melody.

In addition, I found more than 2000 midi files in which the
melody track (channel) was labeled with a metatext command MELODY,
or Melody, or melody..  These files were added.

