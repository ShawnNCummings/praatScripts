#################################################### 
# Praat Script
# equate vowel lengths
#
# Shawn Cummings
# December 2023
##################################
# This script loops through a directory and for each pair of sound files,
# which must be isolated vowels and have identical names except for 
# divergent prefixes, speeds the longer vowel to the duration of the shorter.
#
# Both the length-shifted files and their counterparts
# (which are unchanged) will be written to a user-defined subdirectory.
#
# The script can also track which sound is edited and output relevant data
# to a .csv.
#######################################
#
# This script relies on and borrows heavily from Matt Winn's
# script for creating vowel length continua. This can be found at:
# http://www.mattwinn.com/praat/Make_Duration_Continuum.txt
#
##################################
clearinfo

form equate vowel lengths
	comment Choose the directory containing pairs of sounds to equate: 
	text directory /Users/shawncummings/Documents/GitHub/CNC-CT_Proj/Corpus_stims/18-CriticalWords-Offsets
	comment Length-equated sounds will be saved to a subdirectory. 
	comment What would you like to call this subdirectory?
	text subdirectory Length_Equated
	comment What are the two prefixes you want to equate lengths from?
	comment NOTE: these prefixes must be the same number of characters.
	text prefix1 F1
	text prefix2 F4
	comment Do you want to extract relevant metadata to .csv?
	boolean .csv 1
endform

createDirectory: "'directory$'/'subdirectory$'"

if .csv = 1
	beginPause: "equate vowel lengths: define .csv parameters"
		comment: "A .csv with item, modified vowel, and length change will be"
		comment: "written to the same subdirectory as the length-shifted files."
		comment: "What would you like to call this .csv?"
		text: ".csv", "Length_Equated_Data"
	endPause: "Continue", 1

	csvName$ = "'directory$'/'subdirectory$'/'.csv$'.csv"

	if fileReadable (csvName$)
		pause There is already a file with that name. It will be deleted.
		deleteFile: csvName$
	endif

	writeFileLine: csvName$, "Item", ",Sound_Changed", ",Extent_Changed"
endif

Create Strings as file list... wavList 'directory$'/*.wav
Sort
numSoundFiles = Get number of strings

# loop through all sounds in directory
for s to numSoundFiles
	select Strings wavList
	
	# move from the bottom of the list up, such that the script doesn't
	# catch duplicates of itself.
	# NOTE 12-12-23 unclear if this is actually necessary. 
	string$ = Get string: (numSoundFiles - s + 1)
	if index(string$, prefix1$) != 0
		# remove .wav (4 chars) suffix
		stringID$ = left$ (string$, length(string$) - 4)
		# remove prefix
		stringID$ = right$ (stringID$, length(stringID$) - length(prefix1$))

		# generate filenames for file pair to be equated
		string1$ = prefix1$ + stringID$ + ".wav"
		string2$ = prefix2$ + stringID$ + ".wav"

		sound1 = Read from file... 'directory$'/'string1$'
		.dur1 = Get total duration
	
		sound2 = Read from file... 'directory$'/'string2$'
		.dur2 = Get total duration

		# a positive value means the prefix1 version is longer
		.durDiff = .dur1 - .dur2
		
		if .durDiff = 0
			# do nothing, just save both unchanged
			printline 'sound1' and 'sound2' are already the same length!
			select 'sound1'
			Save as WAV file: "'directory$'/'subdirectory$'/'prefix1$''stringID$'_Duration.wav"
			Remove
			select 'sound2'
			Save as WAV file: "'directory$'/'subdirectory$'/'prefix2$''stringID$'_Duration.wav"
			Remove

		# Currently, script will always set length of prefix2 sound to length of prefix1.
		# This could be changed such that each moves to the average?
		else
			# save sound1 unchanged
			select 'sound1'
			Save as WAV file: "'directory$'/'subdirectory$'/'prefix1$''stringID$'_Duration.wav"
			Remove
			.durRatio = .dur1 / .dur2
			select 'sound2'
			To Manipulation: 0.01, 70, 300
			Rename: "Manipulation"
			Extract duration tier
			Add point: 0, .durRatio
			Add point: .dur2, .durRatio
			plusObject: "Manipulation Manipulation"
			Replace duration tier
			selectObject: "Manipulation Manipulation"
			noprogress Get resynthesis (overlap-add)
			Save as WAV file: "'directory$'/'subdirectory$'/'prefix2$''stringID$'_Duration.wav"
			printline saved 'directory$'/'subdirectory$'/'prefix2$''stringID$'_Duration.wav!
			
			# cleanup
			select 'sound2'
			plusObject: "Manipulation Manipulation", "sound Manipulation", "DurationTier Manipulation"
			remove
			
		endif	
		
	#	elsif .durDiff > 0
	#		# mark sound1 as the one to trim
	#		select 'sound1'
	#		Rename: "toSpeed"
	#		toSave$ = string1$
	#		.durSpeed = .dur2
	#		# save sound2 unchanged
	#		select 'sound2'
	#		Save as WAV file: "'directory$'/'subdirectory$'/'prefix2$''stringID$'_Duration.wav"
	#		Remove
	#
	#	elsif .durDiff < 0
	#		# mark sound2 as the one to trim
	#		select 'sound2'
	#		Rename: "toSpeed"
	#		toSave$ = string2$
	#		.durSpeed = .dur1
	#		# save sound1 unchanged
	#		select 'sound1'
	#		Save as WAV file: "'directory$'/'subdirectory$'/'prefix1$''stringID$'_Duration.wav"
	#		Remove
	#	endif
	#
	#	if .durDiff != 0
	#		selectObject: "Sound toSpeed"
	#		Scale times to: 0, .durSpeed
	#		Save as WAV file: "'directory$'/'subdirectory$'/'toSave$'_Duration.wav"
	#	endif
	#
	#	selectObject: "Sound toSpeed"
	#	Remove

		if .csv = 1
			appendFile: csvName$, stringID$,",",prefix2$,",",.durDiff,  newline$
		endif
	endif

endfor

select Strings wavList
Remove

printline Done! Check 'directory$'\'subdirectory$' for your files!

##### end of script ####





