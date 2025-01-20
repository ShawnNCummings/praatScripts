# # ## ### ##### ########  #############  ##################### 
# Praat Script
# Make Duration Continuum
#
### creates a duration continuum of all sounds in a directory that you choose
## important! ensure that the sounds all have the same time boundaries!
##	 you set the boundaries once, and then it uses those to act on all the remaining sounds in the directory 
# Matthew Winn
# August 2014
##################################
##################### 
############# 
######## 
#####
###
##
#
#
form Input Enter specifications for Formant settings
    comment shortest duration (ms): 
    real shortdurms 65
    comment longest duration (ms): 
    real longdurms 195
    comment how many steps in the continuum? 
    integer steps 5
    comment enter minimum pitch
    real minpitch 70
    comment enter maximum pitch
    real maxpitch 300
    comment enter duration name prefix
    word durPrefix _dur_

endform

clearinfo
shortdur = shortdurms/1000
longdur = longdurms/1000

call printHeader

call makeContinuum steps shortdur longdur dur_ 1

call enumerateSounds

call identifyLandmarks


for thisSound from 1 to numberOfSelectedSounds
    select sound'thisSound'
	name$ = selected$("Sound")
	call makeDurationContinuum 'name$' start end shortdur longdur steps 'durPrefix$'

endfor

procedure makeDurationContinuum .name$ .start .end .shortdur .longdur .steps .suffix$
	select Sound '.name$'
	.endTime = Get end time
	To Manipulation... 0.01 minpitch maxpitch
	Extract duration tier
	for thisStep from 1 to .steps
		ratio = (dur_'thisStep')/(.end - .start)

		select DurationTier '.name$'
			Remove points between... 0 .endTime
			Add point... (.start-0.0001) 1
			Add point... .start ratio
			Add point... .end ratio
			Add point... (.end+0.0001) 1

		select Manipulation '.name$'
		plus DurationTier '.name$'
		Replace duration tier

		select Manipulation '.name$'
		Get resynthesis (overlap-add)
		Rename... '.name$''.suffix$''thisStep'
	endfor
	
	select Manipulation '.name$'
	plus DurationTier '.name$'
	Remove
endproc



procedure identifyLandmarks
	select sound1
	firstName$ = selected$("Sound")
	Edit
		editor Sound 'firstName$'
		# prompts user to click on vowel beginning and end, create variables with values at points clicked

		 pause Click Get start of segment to be manipulated, click Continue when done
		 Move cursor to nearest zero crossing
		 start = Get cursor

		 pause Click Get end of segment to be manipulated, click Continue when done
		 Move cursor to nearest zero crossing
		 end = Get cursor
	Close
	endeditor
endproc















procedure enumerateSounds
	pause select all sounds to be used for this operation
	numberOfSelectedSounds = numberOfSelected ("Sound")

	for thisSelectedSound to numberOfSelectedSounds
		sound'thisSelectedSound' = selected("Sound",thisSelectedSound)
	endfor
endproc




procedure printHeader
	# creates simple header		
	print Step 'tab$' Duration 'tab$' 'newline$'
endproc


procedure makeContinuum .steps .low .high .prefix$ printvalues
	for thisStep from 1 to .steps

		temp = (('thisStep'-1)*('.high'-'.low')/('.steps'-1))+'.low'

		'.prefix$''thisStep' = temp
		check = '.prefix$''thisStep'
		if printvalues = 1
		print '.prefix$''thisStep''tab$''check:2' 'newline$'
		endif

	endfor
endproc