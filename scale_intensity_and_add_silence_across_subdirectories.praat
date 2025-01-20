############################
#
#  Scales the intensity and add a silence interval to all the files
#  in a specified directory to be equal.
#
############################
# MODIFIED by Xin Xie (xxie13@ur.rochester.edu) to add silence intervals.


form Scale intensity of sound files across subdirectories of a specified directory
    comment Directory containing all subdirectories of interest: 
    comment (NOTE: scaled files will be saved to this directory, overwriting original files; the sound files must be in a subdirectory of the directory specified below)
    text directory E:\stims\scaled_70dB
	comment Directory containing the silence file
	text silence_diretory C:\Users\shawn\Desktop\HLP Lab\praat
    comment Directory for resulting files
    text end_directory /Users/xinxie/Desktop/d_final/training/

    comment Scale to what intensity
    positive intensity 70.0
endform

mySilence = Read from file... 'silence_diretory$'/silence_500ms_44100_mono.wav

# Make a list of all the subdirectories in the specified directory
Create Strings as directory list... subDirList 'directory$'
numSubDirs = Get number of strings

# Loop over subirectories
for d to numSubDirs
    subDir$ = Get string... d

    # Make list of all files in current subdirectory
    Create Strings as file list... wavList 'directory$'/'subDir$'/*.wav
    numSoundFiles = Get number of strings

    # Loop over files in current subdirectory
    for s to numSoundFiles
        # Read in each sound file
        soundFile$ = Get string... s
        Read from file... 'directory$'/'subDir$'/'soundFile$'

        # Get the current intensity
	oldintensity = Get intensity (dB)

        # Scale intensity
        Scale intensity... intensity

        # Make a printout as a sanity check
	printline scaling intensity of 'subDir$'/'soundFile$' from 'oldintensity' to 'intensity'
		
		# Add silence before and after the sound
       	mySound = selected("Sound")
	#	selectObject: mySilence
	#	Copy: "tmp"
	#	plusObject: mySound
	#	plusObject: mySilence
	#	myNewSound = Concatenate
		select mySound
        # Save the scaled file
        # NOTE: THE ORIGINAL FILE WILL BE OVERWRITTEN 
        Write to WAV file... 'directory$'/'subDir$'/'soundFile$'

        select Strings wavList
    endfor
    Remove
    select Strings subDirList
endfor

select all
Remove
printline Done!