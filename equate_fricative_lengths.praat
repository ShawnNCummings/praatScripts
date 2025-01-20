# # ## ### ##### ########  #############  ##################### 
# Praat Script
# equate fricative lengths
#
# Shawn Cummings & Rachel Theodore
# October 2022
##################################
# This script loops through a directory and for each pair of sound files,
# which must have identical names excepting different suffixes of "SS" and "SH",
# trims from the center of the longer file such that its length matches that of
# the shorter.
#
# Both the length-shifted files and their counterparts
# (which are unchanged) will be written to a user-defined subdirectory.
#
# The script can also track which sound is edited and output relevant data
# to a .csv.
#######################################
clearinfo

form equate fricative lengths
	comment Choose the directory containing pairs of sounds to equate: 
	text directory E:\Stims for NSF Grant\fric_test
	comment Length-equated sounds will be saved to a subdirectory. 
	comment What would you like to call this subdirectory?
	text subdirectory Length_Equated
	comment Do you want to extract relevant metadata to .csv?
	boolean .csv 0
endform

if .csv = 1
	beginPause: "equate fricative lengths: define .csv parameters"
		comment: "A .csv with item, modified fricative, and length change will be"
		comment: "written to the same subdirectory as the length-shifted files."
		comment: "What would you like to call this .csv?"
		text: ".csv", "Length_Equated_Data"
	endPause: "Continue", 1

	csvName$ = "'directory$'/'subdirectory$'/'.csv$'.csv"

	if fileReadable (csvName$)
		pause There is already a file with that name. It will be deleted.
		deleteFile: csvName$
	endif

	writeFileLine: csvName$, "Item", ",Fricative_Trimmed", ",Extent_Trimmed"
endif

Create Strings as file list... wavList 'directory$'/*.wav
Sort
numSoundFiles = Get number of strings

# loop through all sounds in directory
for s to numSoundFiles
	select Strings wavList
	
	string$ = Get string: (numSoundFiles - s + 1)
	if index(string$, "SH") != 0
		# remove .wav (4 chars) + the fricative suffix (2 chars)
		stringID$ = left$ (string$, length(string$) - 6)
	
		# for each encountered prefix, generate both versions 
		string1$ = stringID$ + "SS.wav"
		string2$ = stringID$ + "SH.wav"

		sound1 = Read from file... 'directory$'/'string1$'
		.dur1 = Get total duration
	
		sound2 = Read from file... 'directory$'/'string2$'
		.dur2 = Get total duration

		.durDiff = .dur1 - .dur2
		# SS - SH, such that a positive value means SS is longer
		
		if .durDiff = 0
		printline 'sound1' and 'sound2' are already the same length!
		# do nothing
		elsif .durDiff > 0
			fric$ = "SS"
			select 'sound1'
			Rename: "toTrim"
			.durTrim = .dur1
			select 'sound2'
			Save as WAV file: "'directory$'/'subdirectory$'/'stringID$'SH-Duration.wav"
			Remove
			

		elsif .durDiff < 0
			fric$ = "SH"
			select 'sound2'
			Rename: "toTrim"
			.durTrim = .dur2
			.durDiff = abs(.durDiff)
			select 'sound1'
			Save as WAV file: "'directory$'/'subdirectory$'/'stringID$'SS-Duration.wav"
			Remove
		endif

		if .durDiff != 0
			selectObject: "Sound toTrim"

			.start = (.durTrim / 2) - (.durDiff / 2)
			.startZero = Get nearest zero crossing: 1, .start

			.end = (.durTrim / 2) + (.durDiff / 2)
			.endZero = Get nearest zero crossing: 1, .end
		
			half1 = Extract part: 0.0, .startZero, "rectangular", 1, "no"
			Rename: "half1"
			
			selectObject: "Sound toTrim"
			half2 = Extract part: .endZero, .durTrim, "rectangular", 1, "no"
			Rename: "half2"

			selectObject: "Sound half1", "Sound half2"
			Concatenate
			Rename: "trimmed"
		
			Save as WAV file: "'directory$'/'subdirectory$'/'stringID$''fric$'-Duration.wav"

			
		endif

		selectObject: "Sound toTrim", "Sound trimmed", "Sound half1", "Sound half2" 
		Remove
		if .csv = 1
			appendFile: csvName$, stringID$,",",fric$,",",.durDiff,  newline$
		endif
	endif

endfor

select Strings wavList
Remove

printline Done! Check 'directory$'\'subdirectory$' for your files!

##### end of script ####
