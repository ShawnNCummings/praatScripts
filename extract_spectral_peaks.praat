# # ## ### ##### ########  #############  ##################### 
# Praat Script
# Extract Spectral Peaks
#
# Shawn Cummings
# October 2022
##################### 
# INSTRUCTIONS/INFO
#
# All sounds must be in the same directory.
#
# A .csv will be created in this directory, and will overwrite
# any previously existing .csv of the same name ("extract_spectral_peaks.csv")
############# 
######## 
#####
###
##
#
#
clearinfo

form extract spectral peaks
	comment Choose the directory containing sounds to analyse: 
	text directory C:\Users\shawn\Desktop\script_test
endform

### Create .csv to store data
csv$ = directory$ + "/extract_spectral_peaks.csv" 

# Header
writeFileLine: csv$, "File, Peak_1_Freq, Peak_1_Amp, Peak_2_Freq, 
... Peak_2_Amp, Peak_3_Freq, Peak_3_Amp,"  
###


Create Strings as file list... wavList 'directory$'/*.wav
numSoundFiles = Get number of strings

# loop through every filename in the directory
for s to numSoundFiles
	Erase all
	select Strings wavList
	Sort
	string$ = Get string... s
	# Remove .wav
	stringID$ = left$ (string$, length(string$) - 4)

	Read from file... 'directory$'/'string$'

	select Sound 'stringID$'
	To Spectrum... Fast
	Copy: "First_peak"
	Copy: "Second_peak"
	Copy: "Third_peak"

	# Drawing
	select Spectrum 'stringID$'
	Cepstral smoothing: 300
	Draw: 1500, 8500, -5, 45, 1

	select Spectrum First_peak
	Filter (pass Hann band): 1500, 3500, 1
	# ~2500
	LPC smoothing: 1, 1
	To SpectrumTier (peaks)
	Draw: 1500, 8500, -5, 45, 0, "speckles"
	Down to Table
	.peak1freq = Get value: 1, "freq(Hz)"
	.peak1amp = Get value: 1, "pow(dB/Hz)"

	select Spectrum Second_peak
	Filter (pass Hann band): 4000, 6000, 1
	# ~5000
	LPC smoothing: 1, 1
	To SpectrumTier (peaks)
	Draw: 1500, 8500, -5, 45, 0, "speckles"
	Down to Table
	.peak2freq = Get value: 1, "freq(Hz)"
	.peak2amp = Get value: 1, "pow(dB/Hz)"

	select Spectrum Third_peak
	Filter (pass Hann band): 6500, 8500, 1
	# ~7500
	LPC smoothing: 1, 1
	To SpectrumTier (peaks)
	Draw: 1500, 8500, -5, 45, 0, "speckles"
	Down to Table
	.peak3freq = Get value: 1, "freq(Hz)"
	.peak3amp = Get value: 1, "pow(dB/Hz)"

	Save as 300-dpi PNG file... 'directory$'/'stringID$'.png

	# Cleanup
	selectObject: "Spectrum First_peak", "SpectrumTier First_peak", "Table First_peak",
	... "Spectrum Second_peak", "SpectrumTier Second_peak", "Table Second_peak",
	... "Spectrum Third_peak", "SpectrumTier Third_peak", "Table Third_peak"
	Remove
	#selectObject: "Spectrum First_peak", "Spectrum Second_peak", "Spectrum Third_peak"
	#Remove 

	
	


# append .csv
appendFile: csv$, stringID$, ",", .peak1freq, ",", .peak1amp, ",",
... .peak2freq, ",", .peak2amp, ",", .peak3freq, ",", .peak3amp, ","
appendFile: csv$, newline$
	
endfor

	
