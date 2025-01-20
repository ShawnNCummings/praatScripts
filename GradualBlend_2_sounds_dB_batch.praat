#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
# Script to "blend" two endpoint sounds
# in the LTAS domain
# version 6
#
# works for aperiodic/fricative sounds 
# but don't try to use it on periodic sounds like vowels
# because it will produce an abomination.
#
# Matthew Winn
# November 2022
##################################
# Modified to batch blend all sounds in a given directory
# Shawn Cummings & Rachel Theodore
# December 2022
##################### 
# INSTRUCTIONS/INFO
#
# All pairs of sounds must be in the same directory. They can have any prefix as a name,
# but each pair must be identical except for 2-letter codings for the sounds of interest
# (here, SS and SH). These codings must be last 2 characters in the filename before the
# .wav extension.
#
# THIS SCRIPT CAN ONLY EXECUTE FOR 48 PAIRS OF STIMULI OR FEWER AT A TIME!
# If you want it to work on > 48 pairs of stimuli, need to put the for loop into a procedure.
#
# All blended sounds will be saved to the same directory as the original pairs.
# Blends will be named a concatenation of both parent filenames, plus a number
# corresponding to blend step.
# 
############# 
######## 
#####
###
##
#
#
clearinfo

form gradually blend two sounds
	comment Choose the directory containing pairs of sounds to blend: 
	text directory C:\Users\shawn\Desktop\script_test
endform

Create Strings as file list... wavList 'directory$'/*.wav
numSoundFiles = Get number of strings

# loop through every filename in the directory
for s to numSoundFiles
	select Strings wavList
	Sort
	string$ = Get string... s
	# remove .wav (4 chars) + the fricative suffix (2 chars)
	stringID$ = left$ (string$, length(string$) - 6)
	
	# for each encountered prefix, generate both versions 
	string1$ = stringID$ + "SH.wav"
	string2$ = stringID$ + "SS.wav"

	# clunky code to format everything 
	sound1 = Read from file... 'directory$'/'string1$'
	select sound1
	sound1$ = selected$("Sound",1)

	sound2 = Read from file... 'directory$'/'string2$'
	select sound2
	sound2$ = selected$("Sound",1)

# CONSTANTS and USER DEFINED PARAMS
	select Sound 'sound1$'
	duration = Get total duration
	ltas_bandwidth = 100
	intensity = 0 ; leave at zero to leave the original sound unaltered)

# This number can be adjusted if more or fewer gradiations between sounds are desired.
# It's set to 11, which will make 0/100 to 100/0 blends in 10% steps.
	num_steps = 11

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
# Generate the amplitude envelope that will be imposed on the output sounds
#
# Get the envelopes of the sounds
	call fast_envelope 'sound1$'
	call fast_envelope 'sound2$'

# Average the envelopes together
# (hoping they are the same duration)
	select Sound 'sound1$'_ENV
	Copy... modulator
	Formula... self[col]*0.5 + Sound_'sound2$'_ENV[col]*0.5

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#

# Create noise to be modified by the LTAS
# (you could change this to be a tone complex or something)
	Create Sound from formula... noise 1 0 'duration' 44100  randomGauss(0,0.1)
	# Discrete Fourier transform
	To Spectrum... no
	select Sound noise
	Remove

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#

# Create LTAS for each of the two endpoint sounds 
	select Sound 'sound1$'
	original_intensity = Get intensity (dB)
	if intensity > 0 
		Scale intensity... intensity
	endif
	To Ltas: ltas_bandwidth
	select Sound 'sound1$'
	Scale intensity... original_intensity
	

	select Sound 'sound2$'
	original_intensity = Get intensity (dB)
	if intensity > 0 
		Scale intensity... intensity
	endif
	To Ltas: ltas_bandwidth
	select Sound 'sound2$'
	Scale intensity... original_intensity
	

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
# Generate the continuum of LTAS obejcts
# by graduated averaging of dB values in each bin[col]
	for n from 1 to num_steps
		mix_1 = (n-1)/(num_steps-1)
		mix_2 = 1 - mix_1
		selectObject: "Ltas 'sound1$'"
		Copy: "step_'n'"
		
		# mix the sounds
		Formula: "self[col]*mix_1 + Ltas_'sound2$'[col]*mix_2"
	endfor

# Generate the sound continuum based on the LTAS
	for n from 1 to num_steps
		# zero pad single digit step numbers
		if length(string$(n)) = 1
			printstep$ = "0" + string$(n)
		else
			printstep$ = string$(n)
		endif	

		select Spectrum noise
		Copy... temp
		Formula... self * 10 ^ (Ltas_step_'n'(x)/20)
		To Sound
		
		# modulate amplitude envelope
		Formula... self[col] * Sound_modulator[col]
		print Step 'printstep$' of 'sound1$'-'sound2$' generated 'newline$'
		Write to WAV file... 'directory$'/'sound1$'-'sound2$'-'printstep$'.wav
			
		select Spectrum temp
		Remove
	endfor
endfor
print Done!
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
# PROCEDURES
procedure fast_envelope .name$
#>> a way to obtain the envelope
#>> that is faster than a Hilbert transform
#>> since it uses native optimized Praat functions 
#>> rather than loops

   # make the amplitude envelope
	select Sound '.name$'
	.samplerate = Get sampling frequency
	.duration = Get total duration
	
	To Intensity: 800, 0, "yes"
	selectObject: "Intensity '.name$'"
	Down to IntensityTier
	To AmplitudeTier
	Down to TableOfReal
	To Matrix
	Transpose
	To Sound (slice): 2
	Rename... temp
	Scale times to: 0, .duration
	Resample: .samplerate, 5
	Rename: "'.name$'_ENV"

   #cleanup
	select Intensity '.name$'
	plus IntensityTier '.name$'
	plus AmplitudeTier '.name$'
	plus TableOfReal '.name$'
	plus Matrix '.name$'
	plus Matrix '.name$'_transposed
	plus Sound temp
	Remove
endproc