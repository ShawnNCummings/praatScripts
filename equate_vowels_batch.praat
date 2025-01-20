#################################################### 
# Praat Script
# equate batch of vowels
#
# Shawn Cummings
# December 2023
##################################
# This script loops through a directory and concatenates (recoverably)
# all sounds with selected prefixes. It then rescales the median pitch
# and/or total duration of the second to that of the first, and then
# outputs the modified individual sounds.
#
# The script will also track and output some relevant data
# to a .csv.
#######################################
#
# This script is endebtted to:
# Matt Winn's script for creating vowel length continua:
# http://www.mattwinn.com/praat/Make_Duration_Continuum.txt
# praat vocal toolkit:
# https://www.praatvocaltoolkit.com
#
##################################
clearinfo

form equate vowels
	comment THIS SCRIPT WILL REMOVE ALL OBJECTS IN YOUR LIST
	comment MAKE SURE NOT TO RUN IT IF YOU HAVE OBJECTS YOU CARE ABOUT!
	comment which aspects of sound would you like to equate?
	boolean duration 1
	boolean pitch 1
	comment Choose the directory containing pairs of sounds to equate: 
	text directory /Users/shawncummings/Documents/GitHub/CNC-CT_Proj/Corpus_stims/18-CriticalWords-Offsets
	comment equated sounds will be saved to a subdirectory. 
	comment What would you like to call this subdirectory?
	text subdirectory Equated_batch
	comment What are the two prefixes you want to equate sounds from?
	comment NOTE: these prefixes must be the same number of characters.
	text prefix1 F1
	text prefix2 F4
	comment Do you want to extract relevant metadata to .csv?
	boolean .csv 1
endform

createDirectory: "'directory$'/'subdirectory$'"

if .csv = 1
	beginPause: "equate vowel lengths: define .csv parameters"
		comment: "A .csv with item, modified vowel, and changes will be"
		comment: "written to the same subdirectory as the files."
		comment: "What would you like to call this .csv?"
		text: ".csv", "Equated_Data"
	endPause: "Continue", 1

	csvName$ = "'directory$'/'subdirectory$'/'.csv$'.csv"

	if fileReadable (csvName$)
		pause There is already a file with that name. It will be deleted.
		deleteFile: csvName$
	endif

	writeFileLine: csvName$, "Prefix", ",Length_Original",
... ",Length_New", ",F0_Original", ",F0_New"
endif

select all
Remove

Create Strings as file list... wavList 'directory$'/*.wav
Sort
numSoundFiles = Get number of strings

# loop through all sounds in directory
for s to numSoundFiles
	select Strings wavList
	
	string$ = Get string: (numSoundFiles - s + 1)
	
	# get all of prefix1 sounds
	if index(string$, prefix1$) != 0
		Read from file... 'directory$'/'string$'
	endif
endfor

select all
minusObject: "Strings wavList"
Concatenate recoverably
selectObject: "Sound chain"
Rename: "chain1"
selectObject: "TextGrid chain"
Rename: "chain1"
select all
minusObject: "Strings wavList", "TextGrid chain1", "Sound chain1"
Remove
 
# loop again for prefix2
for s to numSoundFiles
	select Strings wavList
	
	string$ = Get string: (numSoundFiles - s + 1)
	
	if index(string$, prefix2$) != 0
		Read from file... 'directory$'/'string$'
	endif
endfor

select all
minusObject: "Strings wavList", "TextGrid chain1", "Sound chain1"
Concatenate recoverably
selectObject: "Sound chain"
Rename: "chain2"
selectObject: "TextGrid chain"
Rename: "chain2"
select all
minusObject: "Strings wavList", "TextGrid chain1", "Sound chain1", 
... "TextGrid chain2", "Sound chain2"
Remove

# generate everything we need from each file
selectObject: "Sound chain1"
.dur1 = Get total duration
@minmaxF0
pitch1 = noprogress To Pitch: 0.01, minF0, maxF0
.f0_1 = Get quantile: 0, 0, 0.50, "Hertz"
	
selectObject: "Sound chain2"
.dur2 = Get total duration
@minmaxF0
pitch2 = noprogress To Pitch: 0.01, minF0, maxF0
.f0_2 = Get quantile: 0, 0, 0.50, "Hertz"
selectObject: "Sound chain2"
manip2 = noprogress To Manipulation: 0.01, 75, 600
pitch_tier2 = Extract pitch tier
select 'manip2'
dur_tier2 = Extract duration tier

# a positive value means the prefix1 version is longer
.durDiff = .dur1 - .dur2

# a positive value means the prefix1 version is higher
.pitchDiff = .f0_1 - .f0_2

# First, adjust pitches as/if necessary and desired
if pitch = 1
	if .pitchDiff = 0
		# do nothing
		printline the pitches are already equal.
	else
		.pitchRatio = .f0_1 / .f0_2
		# check that we actually have F0 for both sounds
		if .pitchRatio <> undefined
			select 'pitch_tier2'
			Formula: "self * .pitchRatio"
		else
			printline no reliable pitch, moving on without adjusting...
		endif
	endif
endif

# Second, adjust duration as/if necessary and desired
if duration = 1
	if .durDiff = 0
		# do nothing, just save both unchanged
		printline the durations are already equal.
	else
		.durRatio = .dur1 / .dur2
		select 'dur_tier2'
		Add point: 0, .durRatio
		Add point: .dur2, .durRatio
	endif	
endif

# Regardless of whether anything was modified, rebuild the sound
select 'manip2'
plusObject: 'dur_tier2'
Replace duration tier
select 'manip2'
plusObject: 'pitch_tier2'
Replace pitch tier
select 'manip2'
sound2_new = noprogress Get resynthesis (overlap-add)
		
# Get new values
.dur2_new = Get total duration
@minmaxF0
pitch2_new = noprogress To Pitch: 0.01, minF0, maxF0
.f0_2_new = Get quantile: 0, 0, 0.50, "Hertz"

# Rescale textgrid to match new duration
selectObject: "TextGrid chain2"
Scale times by: .durRatio

# Loop through and save new files
selectObject: "TextGrid chain2"
n_ints = Get number of intervals: 1

for int to n_ints
	selectObject: "TextGrid chain2"
	int_label$ = Get label of interval: 1, int
	plusObject: "Sound chain2"
	Extract intervals where: 1, "no", "is equal to", int_label$
	Save as WAV file: "'directory$'/'subdirectory$'/'int_label$'_Equated.wav"
	Remove
endfor
	
# cleanup
selectObject: "Sound chain2"
plusObject: "Strings wavList", "TextGrid chain1", "Sound chain1", "TextGrid chain2" 
Remove
		
if .csv = 1
	appendFile: csvName$, prefix1$,",",.dur1,",", 
... .dur1,",",.f0_1,",",.f0_1,",", newline$
	appendFile: csvName$, prefix2$,",",.dur2,",", 
... .dur2_new,",",.f0_2,",",.f0_2_new,",", newline$
endif

printline Done! Check 'directory$'\'subdirectory$' for your files!


# minmaxF0, from praat vocal toolkit, here called as a procedure

# This script uses the automatic estimation of min and max f0 proposed by Daniel Hirst
# Hirst, Daniel. (2007). A Praat plugin for Momel and INTSINT with improved algorithms for modelling and coding intonation. Proceedings of the 16th International Congress of Phonetic Sciences.
# https://www.researchgate.net/publication/228640428_A_Praat_plugin_for_Momel_and_INTSINT_with_improved_algorithms_for_modelling_and_coding_intonation
#
# Pitch ceiling raised from q3*1.5 to q3*2.5 to allow for expressive speech, as described at:
# "Hirst, Daniel. (2011). The analysis by synthesis of speech melody: from data to models"
# https://www.researchgate.net/publication/228409777_The_analysis_by_synthesis_of_speech_melody_from_data_to_models

procedure minmaxF0
	selsnd_m = selected("Sound")

	nocheck noprogress To Pitch: 0, 40, 600

	if extractWord$(selected$(), "") = "Pitch"
		voicedframes = Count voiced frames

		if voicedframes > 0
			q1 = Get quantile: 0, 0, 0.25, "Hertz"
			q3 = Get quantile: 0, 0, 0.75, "Hertz"
			minF0 = round(q1 * 0.75)
			maxF0 = round(q3 * 2.5)
		else
			minF0 = 40
			maxF0 = 600
		endif

		Remove
	else
		minF0 = 40
		maxF0 = 600
	endif

	if minF0 < 3 / (object[selsnd_m].nx * object[selsnd_m].dx)
		minF0 = ceiling(3 / (object[selsnd_m].nx * object[selsnd_m].dx))
	endif

	selectObject: selsnd_m
endproc

##### end of script ####


