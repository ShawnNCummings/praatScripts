
dir_fricatives$ = "L:\Projects\LGPL\Stimulus_components\74-CriticalWords-Fricatives-continua"
dir_onsets$ = "L:\Projects\LGPL\Stimulus_components\17-CriticalWords-Onsets"
dir_offsets$ = "L:\Projects\LGPL\Stimulus_components\18-CriticalWords-Offsets"
dir_output$ = "L:\Projects\LGPL\Stimulus_components\75-CriticalWords-assembled-continua"

#onset_formant$  = "SS"
#offset_formant$ = "SS"

num_steps = 11
save = 1

Create Strings as file list: "wordList", "'dir_fricatives$'\*Offset_1.wav"
num_words = Get number of strings
for word_index from 1 to num_words
    selectObject: "Strings wordList"
    extended_name$ = Get string: word_index
    name$ = extended_name$ - "_Offset_1.wav"

    # check to make sure this hasn't already been done
    first_saved$ = "'dir_output$'/'name$'_step_1.wav"
    already_run = fileReadable(first_saved$)

    if already_run != 1

        # read from onset
        Read from file: "'dir_onsets$'\'name$'_Onset.wav"
        for step from 1 to num_steps
            Read from file: "'dir_fricatives$'\'name$'_Offset_'step'.wav"
        endfor
        Read from file: "'dir_offsets$'\'name$'_Offset.wav"

        # concatenate step by step
        for step from 1 to num_steps
            selectObject: "Sound 'name$'_Onset"
            plusObject: "Sound 'name$'_Offset_'step'"
            plusObject: "Sound 'name$'_Offset"
            Concatenate with overlap: 0.003
            Rename: "'name$'_step_'step"
            if save == 1
                Save as WAV file: "'dir_output$'\'name$'_step_'step'.wav"
            endif
            plusObject: "Sound 'name$'_Offset_'step'"
            Remove
        endfor

        # clean up the onset & offsets
            selectObject: "Sound 'name$'_Onset"
            plusObject: "Sound 'name$'_Offset"
            Remove
    # end condition on if this sound were not already run
    endif
endfor


