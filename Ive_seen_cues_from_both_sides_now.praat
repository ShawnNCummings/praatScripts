# Modification of extract_fricative_cues_to_csv
# Which extracts all vowel-related cues from 
# the preceding as well as subsequent segment.
# 
# Name inspiration credit to "Both Sides, Now" (Mitchell, 1968)
#
# ##############################################################################################
# 
# Ive_seen_cues_from_both_sides_now (July 2025, implemented for Praat 6.4.27)
#
# Shawn Cummings (shawn.cummings@uconn.edu)
# 
# Credit goes to zero-crossings-and-spectral-moments 
# (http://stel.ub.edu/labfon/en/praat-scripts; Elvira-Garcia 2014)
# for formatting of sections of this script.
#
#############################################################################################
# DESCRIPTION
# This script runs through all the .wav/.TextGrid combos in a folder and 
# extracts for each interval labelled with selected fricatives:
#	-File name
#	-Fricative label
#	-Labels on either side (phonetic environment)
#	-Any other temporally co-located intervals in other tiers
# 	(e.g. word or other info)
#	
# Additionally, the script will extract the user's choice of the following cues:
#	-Peak Frequency (spectral mode)
#	-Frication Duration
#	-Duration of following vowel
#	-Frication root-mean-square (RMS) Amplitude
#	-Vowel root-mean-square (RMS) Amplitude			
#	-F3 Narrow-band Amplitude (frication)
#	-F3 Narrow-band Amplitude (vowel)
#	-F5 Narrow-band Amplitude (frication)
#	-F5 Narrow-band Amplitude (vowel)
#	-Low Frequency Energy
#	-F0 Frequency
#	-F1 Frequency
#	-F2 Frequency
#	-F3 Frequency
#	-F4 Frequency
#	-F5 Frequency
#	-Spectral Mean	
#	-Spectral Variance
#	-Spectral Skewness
#	-Spectral Kurtosis
#	-Transition Mean	
#	-Transition Variance
#	-Transition Skewness
#	-Transition Kurtosis
#
# These cues are largely derived from Jongman, Wayland, & Wong (2000) 
# and McMurray & Jongman (2011; doi:10.1037/a0022325). 
# However, the exact methods of extraction may differ. 
# The procedure for each cue is described in-line where it occurs.
#
# INSTRUCTIONS
# Prerequisites:
# - A version of Praat 6.4 or more recent
# - A folder with Sounds and TextGrids with the same filenames (e.g., "clip.wav", "clip.TextGrid")
#	-The textgrids must have fricative intervals marked in tier 1
# 	-Any number of additional labels can be included in tiers 2+
#
# Steps for Running:
# 	1) Open the script with Praat (Praat, Open Praat Script...). In the upper menu select Run and Run again. 
#	2) Fill the form, click OK, fill the second form, click Run, and choose the folder where your files will go.
#	3) When the script finishes a screen will appear telling you where you can check the .csv file.
#
####################################	FORM	##################################################################

form extract_fricative_cues_to_csv
	comment Write the name of the .csv file where data will be stored
	comment The file will be created in the same folder where .wav files are.
	sentence csvName fricative_cues_extracted_by_praat
	comment Which fricative label(s) would you like to extract/analyse?
	comment (separate each label by spaces)
	sentence fricativeLabels SS S s SH sh ʃ
endform

folder$ = chooseDirectory$ ("Where are your Sounds and TextGrids?")
csvName$ = folder$ + "/" + csvName$	
csvNameExtension$= csvName$+ ".csv"

# Environment clean-up if necessary
select all
numberOfSelectedObjects = numberOfSelected ()
if numberOfSelectedObjects <> 0
	pause You have objects in the list. Do you want me to remove them?
	Remove
endif

if fileReadable (csvNameExtension$)
	pause There is already a file with that name. It will be deleted.
	deleteFile: csvNameExtension$
endif

# Index objects
Create Strings as file list... list 'folder$'/*.wav
numberOfFiles = Get number of strings

Create Strings from tokens: "fricativeLabels", fricativeLabels$, " "
numFricatives = Get number of strings


########################	 HEADER	##################################
# Create a header that only includes the information selected for extraction in the form
headerInfo$ = "file,sound_preceeding,sound_following"

# Figure out how many tiers are in the textgrids and what their labels are
select Strings list
fileName$ = Get string: 1
base$ = fileName$ - ".wav"
# Read the TextGrid in
Read from file... 'folder$'/'base$'.TextGrid
.tiersCheck = Get number of tiers
headerTiers$ = ""
for tier to .tiersCheck
	newTier$ = Get tier name: tier
	headerTiers$ = headerTiers$ + "," + newTier$ + "," + newTier$ + "_dur" 
endfor
headerTiers$ = headerTiers$ + ","

headerCues$ = "preceding_F0,following_F0,
... preceding_F1,following_F1,preceding_F2,following_F2,preceding_F3,
... following_F3,preceding_F4,following_F4,preceding_F5,following_F5,
... maxpf,dur_f,preceding_dur_v,following_dur_v,rms_f,
... preceding_rms_v,following_rms_v,preceding_F3ampF,following_F3ampF,
... preceding_F3ampV,following_F3ampV,preceding_F5ampF,following_F5ampF,
... preceding_F5ampV,following_F5ampV,lowF,M1,M2,M3,M4, preceding_M1trans,
... preceding_M2trans,preceding_M3trans,preceding_M4trans,
... following_M1trans,following_M2trans,following_M3trans,following_M4trans"

#Write the Header
writeFileLine: csvNameExtension$, headerInfo$, headerTiers$, headerCues$

######################	FILE LOOP	######################
# Here, we're running a three-layer for-loop.
# Layer 1: Loop through each of the files in the selected directory
# Layer 2: Loop through each interval in each file
# Layer 3: Loop through specified fricative labels, look for matches,
# and extract cues if necessary. 

for ifile to numberOfFiles
	select Strings list
	fileName$ = Get string: ifile
	base$ = fileName$ - ".wav"

	# Read the Sound in
	Read from file... 'folder$'/'base$'.wav
	Open long sound file: folder$ + "/"+ base$ + ".wav"
	# Read the TextGrid in
	Read from file... 'folder$'/'base$'.TextGrid

	######################	INTERVAL LOOP	######################
	# Get the number of intervals
	select TextGrid 'base$'
	numberOfIntervals = Get number of intervals: 1
	for n to numberOfIntervals
		select TextGrid 'base$'
		intervalLabel$ = Get label of interval: 1, n
		######################	FRICATIVE LOOP	######################
		for fricative to numFricatives
			select Strings fricativeLabels
			currentFricative$ = Get string: fricative
			if intervalLabel$ = currentFricative$
				@fric_analysis
			endif
		endfor
	endfor

############# ANALYSIS ############# 

procedure fric_analysis
	# File Name
	appendFile: csvNameExtension$,"'base$',"

	# Surrounding phonetic environment
	select TextGrid 'base$'
	if n = 1
		precedingLabel$ = "N/A"
	else
		precedingLabel$ = Get label of interval: 1, n-1
		# truncate any additional commas
		if index(precedingLabel$, ",") != 0
			precedingLabel$ = left$ (precedingLabel$, index(precedingLabel$, ",") - 1)
		endif
	endif
	if precedingLabel$ = ""
		appendFile: csvNameExtension$, "N/A,"
	else
		appendFile: csvNameExtension$, "'precedingLabel$',"
	endif

	select TextGrid 'base$'
	if n = numberOfIntervals
		followingLabel$ = "N/A"
	else
		followingLabel$ = Get label of interval: 1, n+1
				# truncate any additional commas
		if index(followingLabel$, ",") != 0
			followingLabel$ = left$ (followingLabel$, index(followingLabel$, ",") - 1)
		endif
	endif
	if followingLabel$ = ""
		appendFile: csvNameExtension$, "N/A,"
	else
		appendFile: csvNameExtension$, "'followingLabel$',"
	endif

	# Tier labels
	select TextGrid 'base$'
	.tiersCheck = Get number of tiers
	for tier to .tiersCheck
		.intervalStart = Get start point: 1, n
		.intervalNumber = Get interval at time: tier, .intervalStart
		newTierLabel$ = Get label of interval: tier, .intervalNumber
		.newintervalStart = Get start point: tier, .intervalNumber
		.newintervalEnd = Get end point: tier, .intervalNumber
		.newintervalDur = .newintervalEnd - .newintervalStart
		appendFile: csvNameExtension$, "'newTierLabel$','.newintervalDur',"
	endfor

	# Get a number of useful information for all cues
	# Starting and ending intervals
	.intervalStart = Get start point: 1, n			
	.intervalEnd = Get end point: 1, n
	.intervalDur = .intervalEnd - .intervalStart

	if n != 1
		.vowelStart_preceding = Get start point: 1, n-1
		.vowelDur_preceding = .intervalStart - .vowelStart_preceding
	else
		# should really be undefined, but that doesn't play nice with 
		# the multiplier later in the script.
		.vowelDur_preceding = 0
	endif

	if n != numberOfIntervals
		.vowelEnd_following = Get end point: 1, n+1
		.vowelDur_following = .vowelEnd_following - .intervalEnd
	else
		.vowelDur_following = 0
	endif

	# fricative: a Sound object of the entire fricative
	select LongSound 'base$'
	Extract part: .intervalStart, .intervalEnd, "yes"
	Rename: "fricative"

	# window0: a 40 ms region centered on the fricative onset
	select LongSound 'base$'
	.w0Start = .intervalStart - 0.020	
	.w0End = .intervalStart + 0.020
	Extract part... .w0Start .w0End Hamming 1 no
	Rename: "window0"

	# window1: the first 40 ms of the fricative
	select LongSound 'base$'
	.w1End = .intervalStart + 0.040
	Extract part... .intervalStart .w1End Hamming 1 no
	Rename: "window1"

	# window2: a 40 ms region centered on the fricative midpoint
	select LongSound 'base$'
	.intervalMid = .intervalStart + (.intervalDur/2)
	.w2Start = .intervalMid - 0.020
	.w2End = .intervalMid + 0.020
	Extract part... .w2Start .w2End Hamming 1 no
	Rename: "window2"

	# window3: the last 40 ms of the fricative
	select LongSound 'base$'
	.w3Start = .intervalEnd - 0.040
	Extract part... .w2Start .intervalEnd Hamming 1 no
	Rename: "window3"

	# window4: a 40 ms region centered on the fricative offset
	select LongSound 'base$'
	.w4Start = .intervalEnd - 0.020	
	.w4End = .intervalEnd + 0.020
	Extract part... .w4Start .w4End Hamming 1 no
	Rename: "window4"

	# formantWindow1: a 23.3 ms region centered on the fricative midpoint
	select LongSound 'base$'
	.fW1Start = .intervalMid - 0.01165
	.fW1End = .intervalMid + 0.01165
	Extract part... .fW1Start .fW1End Hamming 1 no
	Rename: "formantWindow1"

	# formantWindow2: the first 23.3 ms of the vowel after the fricative
	select LongSound 'base$'
	.fW2End = .intervalEnd + 0.0233
	Extract part... .intervalEnd .fW2End Rectangular 1 no
	Rename: "formantWindow2"
	
	# formantWindow3: the first 46.6 ms of the vowel after the fricative
	select LongSound 'base$'
	.fW3End = .intervalEnd + 0.0466
	Extract part... .intervalEnd .fW3End Rectangular 1 no
	Rename: "formantWindow3"

	# formantWindow4: the last 23.3 ms of the vowel before the fricative
	select LongSound 'base$'
	.fW4Start = .intervalStart - 0.0233
	if .fW4Start > 0
		Extract part... .fW4Start .intervalStart Rectangular 1 no
		Rename: "formantWindow4"
	endif
	
	# formantWindow5: the last 46.6 ms of the vowel before the fricative
	select LongSound 'base$'
	.fW5Start = .intervalStart - 0.0466
	if .fW5Start > 0
		Extract part... .fW5Start .intervalStart Rectangular 1 no
		Rename: "formantWindow5"
	endif

	# Formants
	select Sound formantWindow3
	.fW3Dur = Get total duration
	if .fW3Dur < 0.046
		.f0_following = undefined
		.f1_following = undefined
		.f2_following = undefined
		.f3_following = undefined
		.f4_following = undefined
		.f5_following = undefined
	else
		To Pitch: 0.0, 75.0, 600.0
		.f0_following = Get mean: 0.0, 0.0, "hertz"
		select Sound formantWindow2
		#formant ceiling set to 5500, praat default for adult females
		To Formant (burg): 0.0, 5.0, 5500.0, 0.025, 50.0
		.numberOfFormants = Get maximum number of formants
		#occasionally, praat cannot find higher (4th and 5th) formants
		#in these cases, we try a higher ceiling of 6700, as the highest F5 values
		#in McMurray & Jongman 2011 were in the 6600's
		if .numberOfFormants < 5
			select Sound formantWindow2
			To Formant (burg): 0.0, 5.0, 6700, 0.025, 50.0
		endif
		.f1_following = Get mean: 1, 0.0, 0.0, "hertz"
		.f2_following = Get mean: 2, 0.0, 0.0, "hertz"
		.f3_following = Get mean: 3, 0.0, 0.0, "hertz"
		.f4_following = Get mean: 4, 0.0, 0.0, "hertz"
		.f5_following = Get mean: 5, 0.0, 0.0, "hertz"
	endif

	if .fW5Start > 0
		select Sound formantWindow5
		.fW5Dur = Get total duration
		if .fW5Dur < 0.046
			.f0_preceding = undefined
			.f1_preceding = undefined
			.f2_preceding = undefined
			.f3_preceding = undefined
			.f4_preceding = undefined
			.f5_preceding = undefined
		else
			To Pitch: 0.0, 75.0, 600.0
			.f0_preceding = Get mean: 0.0, 0.0, "hertz"
			select Sound formantWindow4
			#formant ceiling set to 5500, praat default for adult females
			To Formant (burg): 0.0, 5.0, 5500.0, 0.025, 50.0
			.numberOfFormants = Get maximum number of formants
			#occasionally, praat cannot find higher (4th and 5th) formants
			#in these cases, we try a higher ceiling of 6700, as the highest F5 values
			#in McMurray & Jongman 2011 were in the 6600's
			if .numberOfFormants < 5
				select Sound formantWindow4
				To Formant (burg): 0.0, 5.0, 6700, 0.025, 50.0
			endif
			.f1_preceding = Get mean: 1, 0.0, 0.0, "hertz"
			.f2_preceding = Get mean: 2, 0.0, 0.0, "hertz"
			.f3_preceding = Get mean: 3, 0.0, 0.0, "hertz"
			.f4_preceding = Get mean: 4, 0.0, 0.0, "hertz"
			.f5_preceding = Get mean: 5, 0.0, 0.0, "hertz"
		endif
	else
		.f0_preceding = undefined
		.f1_preceding = undefined
		.f2_preceding = undefined
		.f3_preceding = undefined
		.f4_preceding = undefined
		.f5_preceding = undefined
	endif

	appendFile: csvNameExtension$, .f0_preceding,",",.f0_following,",",
... .f1_preceding,",",.f1_following,",",.f2_preceding,",",.f2_following,",",
... .f3_preceding,",",.f3_following,",", .f4_preceding,",",.f4_following,
... ",",.f5_preceding,",",.f5_following,","

	# Peak Frequency
	select Sound window2
	To Spectrum: 1
	Tabulate: 0, 1, 0, 0, 0, 1
	.max = Get maximum: "pow(dB/Hz)"
	.max$ = string$ (.max)
	.row = Search column: "pow(dB/Hz)", .max$
	.maxpf = Get value: .row, "freq(Hz)"
	appendFile: csvNameExtension$, .maxpf,","

	# Fricative Duration
	appendFile: csvNameExtension$, .intervalDur*1000,","
	
	# Vowel Duration
	appendFile: csvNameExtension$, .vowelDur_preceding*1000,",",
... .vowelDur_following*1000,","

	# Frication RMS Amplitude
	select Sound fricative
	.rms_f = Get root-mean-square: 0.0, 0.0
	appendFile: csvNameExtension$, .rms_f,","

	# Vowel RMS Amplitude
	select Sound formantWindow3
	.rms_v_following = Get root-mean-square: 0.0, 0.0
	if .fW5Start > 0
		select Sound formantWindow5
		.rms_v_preceding = Get root-mean-square: 0.0, 0.0
	else
		.rms_v_preceding = undefined
	endif
	appendFile: csvNameExtension$, .rms_v_preceding,",",.rms_v_following,","

	# Create spectra for F3 and F5 Narrow Band Amplitudes (fricative and vowel)
	select Sound formantWindow1
	To Spectrum: 1
	Rename: "nbaSpectrumFricative"
	select Sound formantWindow2
	To Spectrum: 1
	Rename: "nbaSpectrumVowelFollowing"

	if .fW4Start > 0
		select Sound formantWindow4
		To Spectrum: 1
		Rename: "nbaSpectrumVowelPreceding"
	endif

	# F3 Narrow Band Amplitude (fricative)
	select Spectrum nbaSpectrumFricative
	if .f3_preceding = undefined
		.f3ampF_preceding = undefined
	else
		.f3ampF_preceding = Get sound pressure level of nearest maximum: .f3_preceding
	endif
	if .f3_following = undefined
		.f3ampF_following = undefined
	else
		.f3ampF_following = Get sound pressure level of nearest maximum: .f3_following
	endif
	appendFile: csvNameExtension$, .f3ampF_preceding,",",.f3ampF_following,","

	# F3 Narrow Band Amplitude (vowel)
	if .fW4Start > 0
		select Spectrum nbaSpectrumVowelPreceding
		if .f3_preceding = undefined
			.f3ampV_preceding = undefined
		else
			.f3ampV_preceding = Get sound pressure level of nearest maximum: .f3_preceding
		endif
	else
		.f3ampV_preceding = undefined
	endif
	select Spectrum nbaSpectrumVowelFollowing
	if .f3_following = undefined
		.f3ampV_following = undefined
	else
		.f3ampV_following = Get sound pressure level of nearest maximum: .f3_following
	endif
	.f3ampV_preceding = undefined
	appendFile: csvNameExtension$, .f3ampV_preceding,",",.f3ampV_following,","	
		

	# F5 Narrow Band Amplitude (fricative)
	select Spectrum nbaSpectrumFricative
	if .f5_preceding = undefined
		.f5ampF_preceding = undefined
	else
		.f5ampF_preceding = Get sound pressure level of nearest maximum: .f5_preceding
	endif
	if .f5_following = undefined
		.f5ampF_following = undefined
	else
		.f5ampF_following = Get sound pressure level of nearest maximum: .f5_following
	endif
	appendFile: csvNameExtension$, .f5ampF_preceding,",",.f5ampF_following,","

	# F5 Narrow Band Amplitude (vowel)
	if .fW5Start > 0
		select Spectrum nbaSpectrumVowelPreceding
		if .f5_preceding = undefined
			.f5ampV_preceding = undefined
		else
			.f5ampV_preceding = Get sound pressure level of nearest maximum: .f5_preceding
		endif
	else
		.f5ampV_preceding = undefined
	endif

	select Spectrum nbaSpectrumVowelFollowing
	if .f5_following = undefined
		.f5ampV_following = undefined
	else
		.f5ampV_following = Get sound pressure level of nearest maximum: .f5_following
	endif
	appendFile: csvNameExtension$, .f5ampV_preceding,",",.f5ampV_following,","
		
	# Low-Frequency Energy
	select Sound fricative
	To Spectrum: 1
	Tabulate: 0, 1, 0, 0, 0, 1
	Extract rows where column (number): "freq(Hz)", "less than", 500
	.lowF = Get mean: "pow(dB/Hz)"
	appendFile: csvNameExtension$, .lowF,","

	# Spectral Moments, Transition Moments, and JWW00 Moments
# These defaults are probably subideal. Another quality script that
# may provide better results for the same cues:
# -Time averaging for fricatives (Dicanio 2013)
# 		https://www.acsu.buffalo.edu/~cdicanio/scripts.html
	select Sound window1
	To Spectrum: 1
	.center_gravity1 = Get centre of gravity: 2
	.standard_dev1 = Get standard deviation: 2
	.skewness1 = Get skewness: 2
	.kurtosis1 = Get kurtosis: 2

	select Sound window2
	To Spectrum: 1
	.center_gravity2 = Get centre of gravity: 2
	.standard_dev2 = Get standard deviation: 2
	.skewness2 = Get skewness: 2
	.kurtosis2 = Get kurtosis: 2
	
	select Sound window3
	To Spectrum: 1
	.center_gravity3 = Get centre of gravity: 2
	.standard_dev3 = Get standard deviation: 2
	.skewness3 = Get skewness: 2
	.kurtosis3 = Get kurtosis: 2

	select Sound window4
	To Spectrum: 1
	.tcenter_gravity = Get centre of gravity: 2
	.tstandard_dev = Get standard deviation: 2
	.tskewness = Get skewness: 2
	.tkurtosis = Get kurtosis: 2

	# preceding vowel also
	select Sound window0
	To Spectrum: 1
	.pcenter_gravity = Get centre of gravity: 2
	.pstandard_dev = Get standard deviation: 2
	.pskewness = Get skewness: 2
	.pkurtosis = Get kurtosis: 2

	# Spectral Moments
	.center_gravity = (.center_gravity1 + .center_gravity2 + .center_gravity3)/3
	.standard_dev = (.standard_dev1 + .standard_dev2 + .standard_dev3)/3
	.skewness = (.skewness1 + .skewness2 + .skewness3)/3
	.kurtosis = (.kurtosis1 + .kurtosis2 + .kurtosis3)/3
	appendFile: csvNameExtension$, .center_gravity,",",.standard_dev,",",.skewness,",",.kurtosis,","

	# Transition Moments	
	appendFile: csvNameExtension$, .tcenter_gravity,",",.tstandard_dev,
... ",",.tskewness,",",.tkurtosis,",", .pcenter_gravity,",",.pstandard_dev,
... ",",.pskewness,",",.pkurtosis,","
	
	appendFile: csvNameExtension$, newline$
	printline 'base$': Extracted cues from 'intervalLabel$'
	select all
	minus Strings list
	minus Strings fricativeLabels
	minus Sound 'base$'
	minus LongSound 'base$'
	minus TextGrid 'base$'
	Remove
endproc

############# FINAL CLEANING AND INFO ############# 
endfor
selectObject: "Strings list", "Strings fricativeLabels", "Sound 'base$'", "LongSound 'base$'", "TextGrid 'base$'"
Remove

echo The .csv file has been created. 
printline You can find it here: 'folder$'.