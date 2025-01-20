# Praat script Insert silence
# author Daniel Hirst daniel.hirst@...>
# Modified by Zhenghan Qi
# 
# Modified by Danielle Daidone 2/20/18 to add silence at the beginning of each sound file in a folder
# Files are saved to the directory specified by the user with their original names
#
# Modified by Shawn Cummings 10/29/23 to actually add silence at the beginning, rather than end.
# Note: if the 'prefix' argument is left blank, original files may be overwritten!
################################################################################################

form Insert silence
comment Specify duration of silence (in milliseconds) to be added to the beginning of sound files
positive duration_of_silence 200
comment Specify directory of sound files (don't forget final slash)
sentence inputDir  /Users/shawncummings/Desktop/script_test/
comment Specify directory where you want to save the finished files (don't forget final slash)
sentence saveDir /Users/shawncummings/Desktop/script_test/
comment Give an optional prefix for all filenames: 
sentence prefix silence_
endform

duration_of_silence = duration_of_silence/1000

Create Strings as file list... list 'inputDir$'*.wav
numberOfFiles = Get number of strings

for ifile to numberOfFiles
   select Strings list

   #open sound file	
   fileName$ = Get string... ifile
   Read from file... 'inputDir$''fileName$'
   mySound = selected("Sound")

   #get sampling frequency of sound and create silence based on that
   sampling_frequency = Get sampling frequency
   nb_channels = Get number of channels
   mySilence = Create Sound from formula... silence nb_channels 0 duration_of_silence sampling_frequency 0

   #concatenate sound file and silence
   select mySound
   Copy: "mySoundTwo"

   select Sound silence
   plusObject: "Sound mySoundTwo"
   myNewSound = Concatenate

   # save concatenated sound to save directory
   select myNewSound
   Write to WAV file... 'saveDir$''prefix$''fileName$'
   appendInfoLine: "File 'prefix$''fileName$' saved!"
   select all
   minus Strings list
   Remove
endfor

select all
Remove

appendInfoLine: "Files successfully created!"