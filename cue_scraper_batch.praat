#################################################### 
# Praat Script
# scrape cues from batches
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

form F0_F3_Batch
	comment WARNING! THIS SCRIPT REMOVES ALL OBJECTS FROM PRAAT OBJECT WINDOW
	comment Write the name of the .csv file where data will be stored
	comment The file will be created in the same folder where .wav files are.
	sentence csvName F0_F3_Batch

	comment Write the names of all prefixes you wish to batch together.
	comment separate these by spaces
	sentence prefix F1 F2 F3 F4 F5 F6 F7 F8 M1 M2 M3 M4 M5 M6 M7 M8
endform

appendInfoLine: "Please select the directory containing your Sounds"
appendInfoLine: "to ensure the script runs properly, the filenames should have no spaces"
folder$ = chooseDirectory$ ("Where are your Sounds and TextGrids?")
csvName$ = folder$ + "/" + csvName$	
csvNameExtension$= csvName$+ ".csv"

# Check whether there is already a .csv with the selected name, and notify
if fileReadable (csvNameExtension$)
	pause There is already a file with that name. It will be deleted.
	deleteFile: csvNameExtension$
endif

# Create .csv header
writeFileLine: csvNameExtension$, "Prefix", ",", "F0", ",", "F3"


select all
Remove

Create Strings from tokens: "Prefices", prefix$, " "
numPrefices = Get number of strings

Create Strings as file list... list 'folder$'/*.wav
numberOfFiles = Get number of strings

# loop through each prefix
for prefix to numPrefices
	select Strings Prefices

	prefix$ = Get string: prefix

	for ifile to numberOfFiles
		select Strings list
		fileName$ = Get string: ifile
		base$ = fileName$ - ".wav"

		# Read the Sound in
		if index(fileName$, prefix$) != 0
			Read from file... 'folder$'/'fileName$'
		endif
	endfor

	select all
	minusObject: "Strings Prefices", "Strings list"
	Concatenate

	# Get F0:
	@minmaxF0
	noprogress To Pitch: 0.01, minF0, maxF0
	.median_f0 = Get quantile: 0, 0, 0.50, "Hertz"

	# Get formant:
	selectObject: "Sound chain"
	# Set maximum value to look for formant.
	# This can be changed by user if desired.
	if left$(prefix$, 1) = "F"
		.maxFormant = 5500
	endif
	if left$(prefix$, 1) = "M"
		.maxFormant = 5000	
	endif
	noprogress To Formant (robust): 0.005, 5, .maxFormant, 0.025, 50, 1.5, 5, 0.000001
	.median_f3 = Get quantile: 3, 0, 0, "hertz", 0.5

	appendFile: csvNameExtension$, prefix$, ",", .median_f0, ",", .median_f3, newline$

	# clean up
	select all
	minusObject: "Strings Prefices", "Strings list"
	Remove
endfor

selectObject: "Strings Prefices"
Remove

printline Done! Your measurements can be found at 'csvName$'.csv


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


