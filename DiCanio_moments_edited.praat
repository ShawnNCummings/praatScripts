### 
#
# Edited by Shawn Cummings (July 2025) to include some convienience features.
# These include:
# - choosing a directory (rather than writing it out)
# - allowing multiple fricatives 
# - correct indentations
# - writing word tier into file along with fricative
# - deleting objects such that larger files can be run without exceeding
# praat's 10,000 object limit



#Praat script which produces the first four spectral moments from fricative spectra. The DFTs are
#averaged using time-averaging (Shadle 2012). The fricative signals should not be upsampled, so if
#the signal is sampled at under 44.1 kHz, please adjust the Resampling rate to match that of the
#original recording. Within time-averaging, a number of DFTs are taken from across the duration of
#the fricative. These DFTs are averaged for each token and then the moments are calculated. The
#analyzed duration of the fricative is always equivalent to the center 80% of the total duration,
#cutting off the transitions.

#Note that the duration of these DFTs (window size) multiplied by the number of DFTs (window number)
#should equal a value no greater than 1.6 times the duration of the sound file to be analyzed.
#In other words, if you set the window size to 15 ms and the window number to 6, the sum of all
#window durations is equal to 90 ms. This number of windows works fine for a total fricative duration
#down to 56 ms, but no lower. The reason for this is that the windows should overlap only up to 50%
#over the duration of the fricative. If they overlap more than this, certain parts of the duration
#(in the center) get more heavily weighted than others. The value of 1.6 derives from the fact that
#the analyzed duration is only 80% of the duration of the total. Thus, the sum of the windows may
#only be twice of this 80% value, or 160% of the total duration.

#Copyright 2013, Christian DiCanio, Haskins Laboratories & SUNY Buffalo. Please cite this script
#if it is used in a publication or presentation. Special thanks to Christine Shadle for suggestions
#and troubleshooting.

#Version 2.0 revised 2017 to fix an issue with intensity averaging. Thanks to Ting Huang at
#Taiwan Tsing Hua University for pointing this error out to me.

#Version 3.0 revised in 2021 to fix some minor issues with sampling rate.

#Version 4.0 revised in 2021 with extensive help by Wei Rong Chen and Christine
#Shadle at Haskins Labs. The newest version applies an improved function
#in calculating the amplitude of frequency bins and does not utilize Praat's built-in
#functions for spectral moments, but calculates them using methods discussed in
#Forrest, K., Weismer, G., Milenkovic, P. & Dougall, R. N. (1988) Statistical analysis of word-initial
#voiceless obstruents: preliminary data, Journal of the Acoustical Society of America, 84(1), 115â€“123.

form Time averaging for fricatives (be polite - please cite!)
   sentence Interval_label SS S s SH sh ʃ
   sentence Log_file logfile
   positive Labeled_tier_number 1
   positive word_tier_number 2
   positive Resampling_rate 44100
   positive Window_number 6
   positive Window_size 0.015
   positive High_pass_cutoff 300
endform

directory_name$ = chooseDirectory$ ("Where are your Sounds and TextGrids?")

Create Strings from tokens: "interval_labels", interval_label$, " "
numFricatives = Get number of strings


Create Strings as file list... list 'directory_name$'/*.wav
num = Get number of strings
for ifile to num
	select Strings list
	fileName$ = Get string... ifile
	Read from file... 'directory_name$'/'fileName$'
	soundID1$ = selected$("Sound")
	Resample... resampling_rate 50
	soundID2 = selected("Sound")
	Read from file... 'directory_name$'/'soundID1$'.TextGrid
	textGridID = selected("TextGrid")
	num_labels = Get number of intervals... labeled_tier_number

	fileappend 'directory_name$''log_file$'.txt label'tab$'word'tab$'
	fileappend 'directory_name$''log_file$'.txt start'tab$'duration'tab$'intensity'tab$'cog'tab$'sdev'tab$'skew'tab$'kurt'tab$'
	fileappend 'directory_name$''log_file$'.txt 'newline$'

#For each duration in a sound file, extract its duration and then apply a low stop filter
#from 0 to the high pass cutoff frequency set as a variable. Estimate the margin of offset
#then for placing the windows evenly across this duration.

	for i to num_labels
		select 'textGridID'
		label$ = Get label of interval... labeled_tier_number i
		for fricative to numFricatives
			select Strings interval_labels
			currentFricative$ = Get string: fricative
			if label$ = currentFricative$
				fileappend 'directory_name$''log_file$'.txt 'fileName$''tab$'
				select 'textGridID'
	      		intvl_start = Get starting point... labeled_tier_number i
				word_int_n = Get interval at time... word_tier_number intvl_start
				word$ = Get label of interval... word_tier_number word_int_n
				fileappend 'directory_name$''log_file$'.txt 'word$''tab$'
				intvl_end = Get end point... labeled_tier_number i
				durval = intvl_end - intvl_start
				threshold = 0.1*(intvl_end-intvl_start)
				domain_start = (intvl_start + threshold)
				domain_end = (intvl_end - threshold)
				select 'soundID2'
				Extract part... domain_start domain_end Rectangular 1 no
				intID = selected("Sound")
				select 'intID'
				Filter (stop Hann band)... 0 high_pass_cutoff 1
				intID2 = selected("Sound")
				d1 = Get total duration
				d2 = ((d1-window_size)*window_number)/(window_number-1)
				margin = (window_size - (d2/window_number))/2
				end_d2 = (domain_end-margin)
				start_d2 = (domain_start+margin)

#Estimating the size of each window, which varies with the window number and with the size of the margin.
#The margin is the offset between the edge of the overall duration and the estimated start of the window.
#If the overall duration is shorter than the sum duration of all windows, the windows will overlap and
#the margin will be positive. So, this means that the windows at the edge of the overall duration
#are pushed inward so that they do not begin earlier or later than the overall duration. If the overall
#duration is longer than the sum duration of all windows, then the margin will be negative. This means
#that the windows are pushed outward so that they are spaced evenly across the overall duration. Tables
#are created to store the average values of each spectrum, the real values, and the imaginary values.

				chunk_length = d2/window_number
				window_end = (chunk_length)+margin
				window_start = window_end-window_size
				bins = round(((resampling_rate/2)*window_size)+1)
				bin_size = (resampling_rate/2)/(bins - 1)
				Create TableOfReal... freqs 1 bins
				freqs = selected("TableOfReal")
			  	Create TableOfReal... avs 1 bins
				averages = selected("TableOfReal")
				Create TableOfReal... mag window_number bins
				magnitudes = selected("TableOfReal")
				Create TableOfReal... reals window_number bins
				real_table = selected("TableOfReal")
				Create TableOfReal... imags window_number bins
				imag_table = selected("TableOfReal")
				offset = 0.0001

#For each slice, extract the duration and get the intensity value.
#Then, convert each slice to a spectrum. For each sampling interval of the spectrum,
#extract the real and imaginary values and place them in the appropriate tables.

				Create Table with column names: "table", window_number, "int.val"
				int_table = selected("Table")

				for j to window_number
					window_end = (chunk_length*j)+margin
					window_start = window_end-(window_size + offset)
					select 'intID2'
					Extract part... window_start window_end Hanning 1 yes
					chunk_part = selected("Sound")

					intensity = Get intensity (dB)
					select 'int_table'
					Set numeric value: j, "int.val", intensity
					select 'chunk_part'

					To Spectrum... no
					spect = selected("Spectrum")

					for k to bins
						select 'spect'
						freq = Get frequency from bin number: k
						select 'freqs'
						Set value... 1 k freq
		  				select 'spect'
						real = Get real value in bin... k
						real2 = real^2
						select 'real_table'
						Set value... j k real2
						select 'spect'
						imaginary = Get imaginary value in bin... k
						imaginary2 = imaginary^2
						select 'imag_table'
						Set value... j k imaginary2
              			select 'magnitudes'
              			Set value... j k real2+imaginary2
					endfor
					Create Table with column names: "table", window_number, "dsmfc"
					Set numeric value: 1, "dsmfc", 92879
				endfor

				select 'int_table'
				Extract rows where column (text): "int.val", "is not equal to", "--undefined--"
				int.rev.table = selected("Table")
				int = Get mean: "int.val"


#Getting average values from the real and imaginary numbers in the combined matrix of spectral values.
#Then, placing them into the averaged matrix.

				for q to bins
          			select 'magnitudes'
					mag_ave = Get column mean (index)... q
					select 'averages'
					Set value... 1 q mag_ave
				endfor

#Now, converting the averaged matrix to a spectrum to get the moments. Annoyingly, Praat does
#not allow any simple function to change the sampling interval or xmax in a matrix. So, instead,
#you have to extract the first two moments and then multiply each by the sampling interval size.

        			start_bin = ceiling(high_pass_cutoff/bin_size)
				select 'averages'
     		   	Extract column ranges... 'start_bin':'bins'
   		    	 	new_aves = selected("TableOfReal")
 		       	select 'freqs'
		        Extract column ranges... 'start_bin':'bins'
		        new_freqs = selected("TableOfReal")
 		       	select 'new_aves'
				To Matrix
        			ave_mat = selected("Matrix")
        			sum_mat = Get sum

        #We need to divide the matrix values starting from a value above your cut-off frequency by the sum of the matrix values.
        			for x to (bins-start_bin+1)
          			select 'ave_mat'
          			val_x = Get value in cell: 1, x
					Set value: 1, x, val_x/sum_mat
        			endfor

		 #function for center of gravity.
		        cog = 0
		        for b to (bins-start_bin+1)
		          select 'new_freqs'
		          f = Get value: 1, b
    			      select 'ave_mat'
     		      p = Get value in cell: 1, b
         		  cog = cog+(f*p)
        			endfor

		 #For the calculation of spectral moments, we start with the function l and then add to it for each moment.
       		 	l2 = 0
        			l3 = 0
        			l4 = 0
        			for c to (bins-start_bin+1)
          			select 'new_freqs'
          			f = Get value: 1, c
          			select 'ave_mat'
          			p = Get value in cell: 1, c
          			l2 = l2+((f-cog)^2) * p
          			l3 = l3+((f-cog)^3) * p
          			l4 = l4+((f-cog)^4) * p
        			endfor

		#After calculating the functions above, the summed values are modified slightly following Forrest et al. 1988.
				sdev = sqrt(l2)
      			skew = l3/(l2^(3/2))
      			kurt = (l4/(l2^2))-3

				fileappend 'directory_name$''log_file$'.txt 'intvl_start''tab$''durval''tab$''int''tab$''cog''tab$''sdev''tab$''skew''tab$''kurt''newline$'
				printline done with 'word$' from 'fileName$'
				
				# cleanup
				select all
				minus Strings list
				minus Strings interval_labels
				minus 'soundID2'
				minus 'textGridID'
				Remove
			else
				#do nothing
	   		endif
		endfor
	endfor
endfor
printline 'Done!'
select all
Remove