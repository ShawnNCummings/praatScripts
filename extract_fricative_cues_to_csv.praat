# ISSUE: the script at present assumes that every fricative is followed by a vowel.
# If this is not the case, many measurements may be off. 
#
#
# ##############################################################################################
# 
# extract_fricative_cues_to_csv (April 2025, implemented for Praat 6.4.27)
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
	sentence fricativeLabels S s SH sh ʃ
endform

beginPause: "Select the cue(s) to extract:"
	comment: "Select the cue(s) to extract:"
		boolean: "peak_frequency", 1
		boolean: "fricative_duration", 1
		boolean: "vowel_duration", 1
		boolean: "frication_RMS_amplitude", 1	
		boolean: "vowel_RMS_amplitude", 1			
		boolean: "f3_narrowband_amplitude_fricative", 1
		boolean: "f3_narrowband_amplitude_vowel", 1
		boolean: "f5_narrowband_amplitude_fricative", 1
		boolean: "f5_narrowband_amplitude_vowel", 1
		boolean: "low_frequency_energy", 1
		boolean: "formant_frequencies", 1
		boolean: "spectral_moments", 1
		boolean: "transition_moments", 1
endPause: "Continue", 1

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

# Cues
if peak_frequency = 1
	headermaxpf$ = "cue_raw_maxpf,"
else
	headermaxpf$ = ""
endif
if fricative_duration = 1
	headerdur_f$ = "cue_raw_dur_f,"
else
	headerdur_f$ = ""
endif
if vowel_duration = 1
	headerdur_v$ = "cue_raw_dur_v,"
else
	headerdur_v$ = ""
endif
if frication_RMS_amplitude = 1
	headerrms_f$ = "cue_raw_rms_f,"
else
	headerrms_f$ = ""
endif
if vowel_RMS_amplitude = 1
	headerrms_v$ = "cue_raw_rms_v,"
else
	headerrms_v$ = ""
endif
if f3_narrowband_amplitude_fricative = 1
	headerF3ampF$ = "cue_raw_F3ampF,"
else
	headerF3ampF$ = ""
endif
if f3_narrowband_amplitude_vowel = 1
	headerF3ampV$ = "cue_raw_F3ampV,"
else
	headerF3ampV$ = ""
endif
if f5_narrowband_amplitude_fricative = 1
	headerF5ampF$ = "cue_raw_F5ampF,"
else
	headerF5ampF$ = ""
endif
if f5_narrowband_amplitude_vowel = 1
	headerF5ampV$ = "cue_raw_F5ampV,"
else
	headerF5ampV$ = ""
endif
if low_frequency_energy = 1
	headerlowF$ = "cue_raw_lowF,"
else
	headerlowF$ = ""
endif
if formant_frequencies = 1
	headerFormantFrequencies$ = "cue_raw_F0,cue_raw_F1,cue_raw_F2,cue_raw_F3,cue_raw_F4,cue_raw_F5,"
else
	headerFormantFrequencies$ = ""
endif
if spectral_moments = 1
	headerSpectralMoments$ = "cue_raw_M1,cue_raw_M2,cue_raw_M3,cue_raw_M4,"
else
	headerSpectralMoments$ = ""
endif
if transition_moments = 1
	headerTransitionMoments$ = "cue_raw_M1trans,cue_raw_M2trans,
				... cue_raw_M3trans,cue_raw_M4trans,"
else
	headerTransitionMoments$ = ""
endif

#Write the Header
writeFileLine: csvNameExtension$, headerInfo$, headerTiers$, headerFormantFrequencies$,
... headermaxpf$, headerdur_f$, headerdur_v$, headerrms_f$, headerrms_v$, headerF3ampF$,
... headerF3ampV$, headerF5ampF$, headerF5ampV$, headerlowF$, 
... headerSpectralMoments$, headerTransitionMoments$

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
	preceedingLabel$ = Get label of interval: 1, n-1
	if preceedingLabel$ = ""
		appendFile: csvNameExtension$, "N/A,"
	else
		appendFile: csvNameExtension$, "'preceedingLabel$',"
	endif
	select TextGrid 'base$'
	followingLabel$ = Get label of interval: 1, n+1
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
			.vowelEnd = Get end point: 1, n+1		
			.intervalDur = .intervalEnd - .intervalStart
			.vowelDur = .vowelEnd - .intervalEnd

		# fricative: a Sound object of the entire fricative
		select LongSound 'base$'
		Extract part: .intervalStart, .intervalEnd, "yes"
		Rename: "fricative"

		# Hamming windows (for specific usages see McMurray & Jongman 2011)
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

	# Formants
	if formant_frequencies = 1
		select Sound formantWindow3
		To Pitch: 0.0, 75.0, 600.0
		.f0 = Get mean: 0.0, 0.0, "hertz"
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
		.f1 = Get mean: 1, 0.0, 0.0, "hertz"
		.f2 = Get mean: 2, 0.0, 0.0, "hertz"
		.f3 = Get mean: 3, 0.0, 0.0, "hertz"
		.f4 = Get mean: 4, 0.0, 0.0, "hertz"
		.f5 = Get mean: 5, 0.0, 0.0, "hertz"
		appendFile: csvNameExtension$, .f0,",",.f1,",",.f2,",",.f3,",",.f4,",",.f5,","
	endif

	# Peak Frequency
	select Sound window2
	To Spectrum: 1
	Tabulate: 0, 1, 0, 0, 0, 1
	.max = Get maximum: "pow(dB/Hz)"
	.max$ = string$ (.max)
	.row = Search column: "pow(dB/Hz)", .max$
	.maxpf = Get value: .row, "freq(Hz)"
	if peak_frequency = 1
		appendFile: csvNameExtension$, .maxpf,","
	endif

	# Fricative Duration
	if fricative_duration = 1
		appendFile: csvNameExtension$, .intervalDur*1000,","
	endif
	
	# Vowel Duration
	if vowel_duration = 1
		appendFile: csvNameExtension$, .vowelDur*1000,","
	endif
	
	# Frication RMS Amplitude
	if frication_RMS_amplitude = 1
		select Sound fricative
		.rms_f = Get root-mean-square: 0.0, 0.0
		appendFile: csvNameExtension$, .rms_f,","
	endif
	
	# Vowel RMS Amplitude
	if vowel_RMS_amplitude = 1
		select Sound formantWindow3
		.rms_v = Get root-mean-square: 0.0, 0.0
		appendFile: csvNameExtension$, .rms_v,","
	endif

	# Create spectra for F3 and F5 Narrow Band Amplitudes (fricative and vowel)
	select Sound formantWindow1
	To Spectrum: 1
	Rename: "nbaSpectrumFricative"
	select Sound formantWindow2
	To Spectrum: 1
	Rename: "nbaSpectrumVowel"
	
	# F3 Narrow Band Amplitude (fricative)
	if f3_narrowband_amplitude_fricative = 1
		select Spectrum nbaSpectrumFricative
		.f3ampF = Get sound pressure level of nearest maximum: .f3
		appendFile: csvNameExtension$, .f3ampF,","
	endif

	# F3 Narrow Band Amplitude (vowel)
	if f3_narrowband_amplitude_vowel = 1
		select Spectrum nbaSpectrumVowel
		.f3ampV = Get sound pressure level of nearest maximum: .f3
		appendFile: csvNameExtension$, .f3ampV,","
	endif

	# F5 Narrow Band Amplitude (fricative)
	if f5_narrowband_amplitude_fricative = 1
		select Spectrum nbaSpectrumFricative
		.f5ampF = Get sound pressure level of nearest maximum: .f5
		appendFile: csvNameExtension$, .f5ampF,","
	endif

	# F5 Narrow Band Amplitude (vowel)
	if f5_narrowband_amplitude_vowel = 1
		select Spectrum nbaSpectrumVowel
		.f5ampV = Get sound pressure level of nearest maximum: .f5
		appendFile: csvNameExtension$, .f5ampV,","
	endif
		
	# Low-Frequency Energy
	if low_frequency_energy = 1
		select Sound fricative
		To Spectrum: 1
		Tabulate: 0, 1, 0, 0, 0, 1
		Extract rows where column (number): "freq(Hz)", "less than", 500
		.lowF = Get mean: "pow(dB/Hz)"
		appendFile: csvNameExtension$, .lowF,","
	endif

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

	# Spectral Moments
	if spectral_moments = 1
		.center_gravity = (.center_gravity1 + .center_gravity2 + .center_gravity3)/3
		.standard_dev = (.standard_dev1 + .standard_dev2 + .standard_dev3)/3
		.skewness = (.skewness1 + .skewness2 + .skewness3)/3
		.kurtosis = (.kurtosis1 + .kurtosis2 + .kurtosis3)/3
		appendFile: csvNameExtension$, .center_gravity,",",.standard_dev,",",.skewness,",",.kurtosis,","
	endif

	# Transition Moments
	if transition_moments = 1	
		appendFile: csvNameExtension$, .tcenter_gravity,",",.tstandard_dev,",",.tskewness,",",.tkurtosis,","
	endif
	
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