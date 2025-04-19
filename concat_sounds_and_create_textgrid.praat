 
#
#
# ##############################################################################################
# 
# concat_sounds_and_create_textgrid (April 2025, implemented for Praat 6.4.27)
#
# Shawn Cummings (shawn.cummings@uconn.edu)
#
#############################################################################################
# DESCRIPTION
# This script runs through all the .wavs in a directory, includes their filenames as .TextGrid
# labels, and concatenates them with matching sounds in a different directory. 
#
# INSTRUCTIONS
# This script not really designed for broad applicability... if you're seeing this for some reason
# and actually have a use-case contact Shawn for instructions.
#
####################################	FORM	##################################################################


dir_offsets$ = "/Users/shawncummings/Desktop/LoL_dissertation/praat_acoustics/18-CriticalWords-Offsets"
dir_fricatives$ = "/Users/shawncummings/Desktop/LoL_dissertation/praat_acoustics/25-CriticalWords-LinearBlends"
dir_new$ = "/Users/shawncummings/Desktop/LoL_dissertation/praat_acoustics/exposure_offsetconcats"

Create Strings as file list: "wordList", "'dir_fricatives$'/*asi*.wav"

num_words = Get number of strings
for word_index from 1 to num_words
    selectObject: "Strings wordList"
    name$ = Get string: word_index

	where = index (name$, "_SH")
	word$ = left$ (name$, where)

	nameIndex$ = name$ - ".wav"


	Read from file: "'dir_fricatives$'/'name$'"

	Read from file: "'dir_offsets$'/'word$'SS_Offset.wav"

	selectObject: "Sound 'nameIndex$'", "Sound 'word$'SS_Offset"
	Concatenate recoverably
	selectObject: "TextGrid chain"
	Set interval text: 1, 1, "fric"
	Save as text file: "'dir_new$'/'nameIndex$'.TextGrid"

	selectObject: "Sound chain"
	Save as WAV file: "'dir_new$'/'nameIndex$'.wav"

	# clean up
    selectObject: "Sound chain", "TextGrid chain"
	Remove
endfor

printline done!
