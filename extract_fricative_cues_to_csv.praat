###########################################################################################
# THINGS TO COMPLETE:
#	-Annotate following vowel for all stims (to get dur_V)
# 	-Fix Surrounding Phonetic Environment to better account for Arpabet (and include in instructions)
#	-find a way to identify preceding and following sounds
#
# BUGS/ISSUES (Currently Known):
# 	-the MaxPF value for about 2% of tokens appears as 0, for unknown reasons
#	-the current method of searching for formants (which first checks up to 5500 Hz, then 
#	 up to 6700 if it doesn't find at least 5 formants) still leaves the occasional undefined 
#	 for f5, and may have unintended effects on f1-3.
#	-the shifted% applies indiscriminately to all tokens in a set, including incidental secondary
#	 (non-target) fricatives that are not actually shifted
#
# ##############################################################################################
# 
# extract_fricative_cues_to_csv (September 2021, implemented for Praat 6.1.16)
#
# Script based loosely on zero-crossings-and-spectral-moments
# by Elvira-Garcia 2014 (http://stel.ub.edu/labfon/en/praat-scripts)
# that gets a subset of informative cues for fricative contrasts
#
# Shawn Cummings (shawn.cummings@uconn.edu)
#
#############################################################################################
# 
# DESCRIPTION
# This script runs through all the .wav/.TextGrid combos in a folder and 
# gets for each interval labelled with a selected fricative:
#	File Name
#	Word Label
#	Fricative Label	
#	
# Additionally, the script will extract the user's choice of the following general cues:
#	Fricative Voicing (categorical)
#	Fricative Place of Articulation
#	Fricative Sibilance (categorical)
#	Surrounding Phonetic Environment (precedent and subsequent sound categories)
#
# Finally, the script will extract the user's choice of the following cues
# described in Jongman, Weyland, & Wong (2000) and McMurray & Jongman (2011):
# Note: Cues with an * require accurate boundary markings for the vowel after each
# target fricative (and that each fricative is followed by a vowel or vowel-like sound)
#	Peak Frequency
#	Frication Duration
#	*Vowel Duration
#	Frication root-mean-square (RMS) Amplitude
#	*Vowel root-mean-square (RMS) Amplitude			
#	F3 Narrow-band Amplitude (frication)
#	*F3 Narrow-band Amplitude (vowel)
#	F5 Narrow-band Amplitude (frication)
#	*F5 Narrow-band Amplitude (vowel)
#	Low Frequency Energy
#	F0 Frequency (pitch)
#	F1 Frequency
#	F2 Frequency
#	F3 Frequency
#	F4 Frequency
#	F5 Frequency
#	Spectral Mean	
#	Spectral Variance
#	Spectral Skewness
#	Spectral Kurtosis
#	Transition Mean	
#	Transition Variance
#	Transition Skewness
#	Transition Kurtosis
# More information about these cues and their extraction criteria can be found in 
# McMurray & Jongman (2011); doi:10.1037/a0022325
#
# INSTRUCTIONS
# Prerequisites:
# - A folder with Sounds and TextGrids with the same filenames (e.g., "clip.wav", "clip.TextGrid")
#	-Files must be named in the following manner: "first-half_second-half" (ex. Kraljic-Samuel-2008_50)
#		first half: Study name, with hyphens (not underscores) between all words (author names, years, etc.)
#			ex. "Drouin-et-al-2016-and-2018", "Liu-Jaeger-exp3a", etc.
#		second half (3 options): a) the percent of shift applied to all phones in the file
#						ex. 0 for natural speech, 50 for maximally ambiguous blend
#					 b) A string including the word "test", if the file is a test continuum
#						ex. "test-asi-ashi" (use hyphens, not underscores)
#					 c) "x-bias", where x (lowercase) represents the altered phone. A %shift value
#					    of 0 will be applied to instances of that phone, and 50 to all others.
#						ex. "s-bias"
#	-The textgrids must have fricative intervals marked in tier 1 and word intervals marked in tier 2
#	-Additional information in a third tier (optional) is concatenated with the word label in the export .csv
#	-For certain cues (i.e. Vowel-based JWW cues or phonetic environment information) it may also be
# 	 necesary to have the sounds around each fricative marked in tier 1
#- A version of Praat 6.1 or more recent (In earlier versions of Praat, the "tabulate" command 
#  displays an info window instead of creating a Table object; the script requires Table objects)
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
	comment Select the fricative(s) to extract/analyse:
		boolean s 1
		boolean sh 1
		boolean f 0
		boolean th 0
		boolean z 0
		boolean zh 0
		boolean v 0
		boolean dh 0
	comment Include continuum blend tokens, ex. "?SSH"? (this will extract any interval starting with a "?")
		boolean continuum 1
	comment Include articulatory information about the fricatives?
		boolean articulation 1
	comment Include the phonetic environment around the fricatives? 
	comment Note: this requires the TextGrids to be annotated with said environment
		boolean environment 1
endform

beginPause: "MJ11: Select the cue(s) to extract:"
	comment: "Select the cue(s) from McMurray & Jongman 2011 to extract:"
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
		boolean: "f0_frequency", 1
		boolean: "f1_frequency", 1
		boolean: "f2_frequency", 1
		boolean: "f3_frequency", 1
		boolean: "f4_frequency", 1
		boolean: "f5_frequency", 1
		boolean: "spectral_moments", 1
		boolean: "transition_moments", 1
endPause: "Continue", 1

if spectral_moments = 1
	beginPause: "JWW00: Select the cue(s) to extract:"
		comment: "You selected to extract spectral moments, using the criteria laid out in McMurray & Jongman 2011"
		comment: "This cue was extracted differently for Jongman, Wayland, & Wong 2000"
		comment: "Would you like to also extract spectral moments using the JWW 2000 criteria?"
			boolean: "jww00_spectral_moments", 1
endPause: "Run", 1

folder$ = chooseDirectory$ ("Where are your Sounds and TextGrids?")
csvName$ = folder$ + "/" + csvName$	
csvNameExtension$= csvName$+ ".csv"

#beginPause: "Talker Gender"
#	comment: "Praat looks for Formant values at ___. For female talkers, this is often insufficient"
#	comment: "If you would like to alter Praat's standards to search a higher range for these cues, indicate here:"
#		boolean: Strings list, 1
#endPause: "Run", 1

# Check Talker Gender
#for ifile to numberOfFiles
#	select Strings list
#	fileName$ = Get string: ifile
#	base$ = fileName$ - ".wav"
#		beginPause: "Talker Gender"
#			comment: "Is the talker in 'base$' Female?"
#				choice: "Talker Gender", 1
#					option: "male"
#					option: "female"
#		endPause: "Run", 1
#endfor

##########################	PREDEFINED FUNCTIONS	##########################################################

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

########################	HEADER	##################################
# Create a header that only includes the information selected for extraction in the form
headerInfo$ = "file,study,word,fricative,shift_percent,"

if articulation = 1
	headerArticulatoryCues$ = "fricative_voicing,fricative_place,fricative_sibilance,"
else
	headerArticulatoryCues$ = ""
endif
if environment = 1
	headerPhoneticEnvironment$ = "sound_preceeding,sound_following,"
else
	headerPhoneticEnvironment$ = ""
endif

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
if f0_frequency = 1
	headerF0$ = "cue_raw_F0,"
else
	headerF0$ = ""
endif
if f1_frequency = 1
	headerF1$ = "cue_raw_F1,"
else
	headerF1$ = ""
endif
if f2_frequency = 1
	headerF2$ = "cue_raw_F2,"
else
	headerF2$ = ""
endif
if f3_frequency = 1
	headerF3$ = "cue_raw_F3,"
else
	headerF3$ = ""
endif
if f4_frequency = 1
	headerF4$ = "cue_raw_F4,"
else
	headerF4$ = ""
endif
if f5_frequency = 1
	headerF5$ = "cue_raw_F5,"
else
	headerF5$ = ""
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
if jww00_spectral_moments = 1
	headerJWW00SpectralMoments$ = "cue_raw_W1M1,cue_raw_W1M2,cue_raw_W1M3,cue_raw_W1M4,
... cue_raw_W2M1,cue_raw_W2M2,cue_raw_W2M3,cue_raw_W2M4,
... cue_raw_W3M1,cue_raw_W3M2,cue_raw_W3M3,cue_raw_W3M4,
... cue_raw_W4M1,cue_raw_W4M2,cue_raw_W4M3,cue_raw_W4M4"
else
	headerJWW00SpectralMoments$ = ""
endif

#Write the Header
writeFileLine: csvNameExtension$, headerInfo$, headerArticulatoryCues$, headerPhoneticEnvironment$,
... headermaxpf$, headerdur_f$, headerdur_v$, headerrms_f$, headerrms_v$, headerF3ampF$, headerF3ampV$,
... headerF5ampF$, headerF5ampV$, headerlowF$, headerF0$, headerF1$, headerF2$, headerF3$, headerF4$,
... headerF5$, headerSpectralMoments$, headerTransitionMoments$, headerJWW00SpectralMoments$


########################################
# Start the loop
Create Strings as file list... list 'folder$'/*.wav
numberOfFiles = Get number of strings

for ifile to numberOfFiles
	######################	ACTIONS FOR ALL INTERVALS	#############################
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
		# Get word label
		.intervalStart = Get start time of interval: 1, n
		.wordInterval = Get interval at time: 2, .intervalStart
		wordLabel$ = Get label of interval: 2, .wordInterval
		if index(wordLabel$, "_") <> 0
			underscore = index(wordLabel$, "_")
			wordLabel$ = left$(wordLabel$, underscore - 1)
		endif
		# If there is a tier giving addition information (i.e. continuum steps for a?sshi tokens)
		# it is appended to the word label
		.tiers = Get number of tiers
		if .tiers > 2
			.manipulationInterval = Get interval at time: 3, .intervalStart
			manipulationLabel$ = Get label of interval: 3, .manipulationInterval
			wordLabel$ = wordLabel$ + " (" + manipulationLabel$ + ")"
		endif

		# Select intervals to extract
		# Provide articulation info for extracted fricatives
		if s = 1
			if intervalLabel$ = "s" or intervalLabel$ = "S"
				voicing$ = "voiceless"
				place$ = "alveolar"
				sibilance$ = "sibilant"
				@fric_analysis
			endif
		endif
		if sh = 1
			if intervalLabel$ = "sh" or intervalLabel$ = "SH"
				voicing$ = "voiceless"
				place$ = "post-alveolar"
				sibilance$ = "sibilant"
				@fric_analysis
			endif
		endif
		if f = 1
			if intervalLabel$ = "f" or intervalLabel$ = "F"
				voicing$ = "voiceless"
				place$ = "labiodental"
				sibilance$ = "non-sibilant"
				@fric_analysis
			endif
		endif
		if th = 1
			if intervalLabel$ = "th" or intervalLabel$ = "TH"
				voicing$ = "voiceless"
				place$ = "interdental"
				sibilance$ = "non-sibilant"
				@fric_analysis
			endif
		endif
		if z = 1
			if intervalLabel$ = "z" or intervalLabel$ = "Z"
				voicing$ = "voiced"
				place$ = "alveolar"
				sibilance$ = "sibilant"
				@fric_analysis
			endif
		endif
		if zh = 1
			if intervalLabel$ = "zh" or intervalLabel$ = "ZH"
				voicing$ = "voiced"
				place$ = "post-alveolar"
				sibilance$ = "sibilant"
				@fric_analysis
			endif
		endif
		if v = 1
			if intervalLabel$ = "v" or intervalLabel$ = "V"
				voicing$ = "voiced"
				place$ = "labiodental"
				sibilance$ = "non-sibilant"
				@fric_analysis
			endif
		endif
		if dh = 1
			if intervalLabel$ = "dh" or intervalLabel$ = "DH"
				voicing$ = "voiced"
				place$ = "interdental"
				sibilance$ = "non-sibilant"
				@fric_analysis
			endif
		endif
		
		# Account for continuum steps, if selected
		# Note: articulatory info will not be provided for these tokens
		if continuum = 1
			intervalLabelStart$ = left$: intervalLabel$, 1
			if intervalLabelStart$ = "?"
				voicing$ = ""
				place$ = ""
				sibilance$ = ""
				@fric_analysis
			endif
		endif
	endfor

############# ANALYSIS ############# 

procedure fric_analysis
	# File Name, Study Name, Fricative, Word Label, and Shift Percentage
	length = length(base$)
	underscore = index(base$, "_")
	studyName$ = left$(base$, underscore - 1)

	if index(base$, "test") <> 0
		shiftPercent$ = manipulationLabel$
	elif index(base$, "bias") <> 0
		shiftedPhone$ = right$(base$, length - underscore)
		length2 = length(shiftedPhone$)
		shiftedPhone$ = left$(shiftedPhone$, length2 - 5)
		if shiftedPhone$ = intervalLabel$
			shiftPercent$ = "50"
		else
			shiftPercent$ = "0"
		endif
	else
		shiftPercent$ = right$(base$, length - underscore)
	endif
	appendFile: csvNameExtension$,"'base$','studyName$','wordLabel$','intervalLabel$','shiftPercent$',"

	# Articulatory Info
	if articulation = 1
		appendFile: csvNameExtension$, "'voicing$','place$','sibilance$',"
	endif

	# Surrounding Phonetic Environment
	if environment = 1
		preceedingLabel$ = Get label of interval: 1, n-1
		if preceedingLabel$ = ""
			appendFile: csvNameExtension$, "N/A,"
		else
			appendFile: csvNameExtension$, "'preceedingLabel$',"
		endif
		followingLabel$ = Get label of interval: 1, n+1
		if followingLabel$ = ""
			appendFile: csvNameExtension$, "N/A,"
		else
			appendFile: csvNameExtension$, "'followingLabel$',"
		endif
	endif

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
			Extract part: .intervalStart, .w1End, "yes"
			Rename: "window1"

			# window2: a 40 ms region centered on the fricative midpoint
			select LongSound 'base$'
			.intervalMid = .intervalStart + (.intervalDur/2)
			.w2Start = .intervalMid - 0.020
			.w2End = .intervalMid + 0.020
			Extract part: .w2Start, .w2End, "yes"
			Rename: "window2"

			# window3: the last 40 ms of the fricative
			select LongSound 'base$'
			.w3Start = .intervalEnd - 0.040
			Extract part: .w2Start, .intervalEnd, "yes"
			Rename: "window3"
	
			# window4: a 40 ms region centered on the fricative offset
			select LongSound 'base$'
			.w4Start = .intervalEnd - 0.020	
			.w4End = .intervalEnd + 0.020
			Extract part: .w4Start, .w4End, "yes"
			Rename: "window4"
		
			# formantWindow1: a 23.3 ms region centered on the fricative midpoint
			select LongSound 'base$'
			.fW1Start = .intervalMid - 0.01165
			.fW1End = .intervalMid + 0.01165
			Extract part: .fW1Start, .fW1End, "yes"
			Rename: "formantWindow1"

			# formantWindow2: the first 23.3 ms of the vowel after the fricative
			select LongSound 'base$'
			.fW2End = .intervalEnd + 0.0233
			Extract part: .intervalEnd, .fW2End, "yes"
			Rename: "formantWindow2"
			
			# formantWindow3: the first 46.6 ms of the vowel after the fricative
			select LongSound 'base$'
			.fW3End = .intervalEnd + 0.0466
			Extract part: .intervalEnd, .fW3End, "yes"
			Rename: "formantWindow3"

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

	# Formants
		select Sound formantWindow2
		#formant ceiling set to 5500, praat default for adult females
		To Formant (burg): 0.0, 5.0, 5500.0, 0.025, 50.0
		.numberOfFormants = Get maximum number of formants
		#occasionally, praat cannot find higher (4th and 5th) formants
		#in these cases, we try a higher ceiling of 6700, as the highest F5 values
		#in McMurray & Jongman 2011 were in the 6600's
		if .numberOfFormants < 5
			printline "'.maxpf'"
			select Sound formantWindow2
			To Formant (burg): 0.0, 5.0, 6700, 0.025, 50.0
		endif
		.f1 = Get mean: 1, 0.0, 0.0, "hertz"
		.f2 = Get mean: 2, 0.0, 0.0, "hertz"
		.f3 = Get mean: 3, 0.0, 0.0, "hertz"
		.f3$ = string$ (.f3)
		.f4 = Get mean: 4, 0.0, 0.0, "hertz"
		.f5 = Get mean: 5, 0.0, 0.0, "hertz"
		.f5$ = string$ (.f5)

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

	# Create Table for F3 and F5 Narrow Band Amplitudes (fricative and vowel)
	select Sound formantWindow1
	To Spectrum: 1
	Tabulate: 0, 1, 0, 0, 0, 1
	Rename: "nbaTableFricative"
	select Sound formantWindow2
	To Spectrum: 1
	Tabulate: 0, 1, 0, 0, 0, 1
	Rename: "nbaTableVowel"
	# Most of the time, the exact frequencies of f3 and f5 wont be featured in the table. 
	# To get the closest frequency, we add a dummy row with the formant frequency and 
	# use the nearest adjacent row as our amplitude estimate.
	
	# F3 Narrow Band Amplitude (fricative)
	if f3_narrowband_amplitude_fricative = 1
		select Table nbaTableFricative
		.f3Row = Search column: "freq(Hz)", .f3$
		if .f3Row = 0
			Insert row: 1
			Set numeric value: 1, "freq(Hz)", .f3
			Sort rows: "freq(Hz)"
			.f3Row = Search column: "freq(Hz)", .f3$
			.f3AboveRow = Get value: .f3Row - 1, "freq(Hz)"
			.f3DiffAboveRow = .f3 - .f3AboveRow
			.f3BelowRow = Get value: .f3Row + 1, "freq(Hz)"
			.f3DiffBelowRow = .f3BelowRow - .f3
			if .f3DiffAboveRow <= .f3DiffBelowRow
				.f3ampF = Get value: .f3Row - 1, "pow(dB/Hz)"
			else
				.f3ampF = Get value: .f3Row + 1, "pow(dB/Hz)"
			endif
		else
			.f3ampF = Get value: .f3Row, "pow(dB/Hz)"
		endif
		appendFile: csvNameExtension$, .f3ampF,","
	endif

	# F3 Narrow Band Amplitude (vowel)
	# This still needs to be done... it's fairly similar to extracting F3ampF
	if f3_narrowband_amplitude_vowel = 1
		select Table nbaTableVowel
		.f3Row = Search column: "freq(Hz)", .f3$
		if .f3Row = 0
			Insert row: 1
			Set numeric value: 1, "freq(Hz)", .f3
			Sort rows: "freq(Hz)"
			.f3Row = Search column: "freq(Hz)", .f3$
			.f3AboveRow = Get value: .f3Row - 1, "freq(Hz)"
			.f3DiffAboveRow = .f3 - .f3AboveRow
			.f3BelowRow = Get value: .f3Row + 1, "freq(Hz)"
			.f3DiffBelowRow = .f3BelowRow - .f3
			if .f3DiffAboveRow <= .f3DiffBelowRow
				.f3ampV = Get value: .f3Row - 1, "pow(dB/Hz)"
			else
				.f3ampV = Get value: .f3Row + 1, "pow(dB/Hz)"
			endif
		else
			.f3ampV = Get value: .f3Row, "pow(dB/Hz)"
		endif
		appendFile: csvNameExtension$, .f3ampV,","
	endif

	# F5 Narrow Band Amplitude (fricative)
	if f5_narrowband_amplitude_fricative = 1
		select Table nbaTableFricative
		# Only check f5 narrow band amplitude if f5 is defined
		.f5Row = Search column: "freq(Hz)", .f5$
		if .f5 = undefined
			.f5ampF = undefined
		elif .f5Row = 0
			Insert row: 1
			Set numeric value: 1, "freq(Hz)", .f5
			Sort rows: "freq(Hz)"
			.f5Row = Search column: "freq(Hz)", .f5$
			.f5AboveRow = Get value: .f5Row - 1, "freq(Hz)"
			.f5DiffAboveRow = .f5 - .f5AboveRow
			.f5BelowRow = Get value: .f5Row + 1, "freq(Hz)"
			.f5DiffBelowRow = .f5BelowRow - .f5
			if .f5DiffAboveRow <= .f5DiffBelowRow
				.f5ampF = Get value: .f5Row - 1, "pow(dB/Hz)"
			else
				.f5ampF = Get value: .f5Row + 1, "pow(dB/Hz)"
			endif
		else
			.f5ampF = Get value: .f5Row, "pow(dB/Hz)"
		endif
		appendFile: csvNameExtension$, .f5ampF,","
	endif
	
	# F5 Narrow Band Amplitude (vowel)
	# Still needs to be done
	if f5_narrowband_amplitude_vowel = 1
		select Table nbaTableVowel
		# Only check f5 narrow band amplitude if f5 is defined
		.f5Row = Search column: "freq(Hz)", .f5$
		if .f5 = undefined
			.f5ampV = undefined
		elif .f5Row = 0
			Insert row: 1
			Set numeric value: 1, "freq(Hz)", .f5
			Sort rows: "freq(Hz)"
			.f5Row = Search column: "freq(Hz)", .f5$
			.f5AboveRow = Get value: .f5Row - 1, "freq(Hz)"
			.f5DiffAboveRow = .f5 - .f5AboveRow
			.f5BelowRow = Get value: .f5Row + 1, "freq(Hz)"
			.f5DiffBelowRow = .f5BelowRow - .f5
			if .f5DiffAboveRow <= .f5DiffBelowRow
				.f5ampV = Get value: .f5Row - 1, "pow(dB/Hz)"
			else
				.f5ampV = Get value: .f5Row + 1, "pow(dB/Hz)"
			endif
		else
			.f5ampV = Get value: .f5Row, "pow(dB/Hz)"
		endif
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
	
	# Formants
	if f0_frequency = 1
		select Sound formantWindow3
		To Pitch: 0.0, 75.0, 600.0
		.f0 = Get mean: 0.0, 0.0, "hertz"
		appendFile: csvNameExtension$, .f0,","
	endif
	if f1_frequency = 1
		appendFile: csvNameExtension$, .f1,","
	endif
	if f2_frequency = 1
		appendFile: csvNameExtension$, .f2,","
	endif
	if f3_frequency = 1
		appendFile: csvNameExtension$, .f3,","
	endif
	if f4_frequency = 1
		appendFile: csvNameExtension$, .f4,","
	endif
	if f5_frequency = 1
		appendFile: csvNameExtension$, .f5,","
	endif

	# Spectral Moments, Transition Moments, and JWW00 Moments
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
		.center_gravity = (.center_gravity1 + .center_gravity2)/2
		.standard_dev = (.standard_dev1 + .standard_dev2)/2
		.skewness = (.skewness1 + .skewness2)/2
		.kurtosis = (.kurtosis1 + .kurtosis2)/2
		appendFile: csvNameExtension$, .center_gravity,",",.standard_dev,",",.skewness,",",.kurtosis,","
	endif

	# Transition Moments
	if transition_moments = 1	
		appendFile: csvNameExtension$, .tcenter_gravity,",",.tstandard_dev,",",.tskewness,",",.tkurtosis,","
	endif
	
	# JWW00 Moments
	if jww00_spectral_moments = 1
		appendFile: csvNameExtension$, .center_gravity1,",",.standard_dev1,",",.skewness1,",",.kurtosis1,",",
		... .center_gravity2,",",.standard_dev2,",",.skewness2,",",.kurtosis2,",",
		... .center_gravity3,",",.standard_dev3,",",.skewness3,",",.kurtosis3,",",
		... .tcenter_gravity,",",.tstandard_dev,",",.tskewness,",",.tkurtosis,","



	appendFile: csvNameExtension$, newline$
	printline 'base$': Extracted cues from 'intervalLabel$' in 'wordLabel$'
	select all
	minus Strings list
	minus Sound 'base$'
	minus LongSound 'base$'
	minus TextGrid 'base$'
	Remove
endproc

############# FINAL CLEANING AND INFO ############# 
endfor
selectObject: "Strings list", "Sound 'base$'", "LongSound 'base$'", "TextGrid 'base$'"
Remove

echo The .csv file has been created. 
printline You can find it here: 'folder$'.