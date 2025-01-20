# # ## ### ##### ########  #############  ##################### 
# Praat Script
# check fricative annotations
#
# Shawn Cummings
# October 2022
##################################
# This script takes a TextGrid and Sound pair and returns:
# -for each tier, the number of non-empty intervals (for our purposes, should always be 80)
# -for each tier, any intervals whose text don't match that of tier 1 (our 'Item' layer) at the same timepoint
# -any boundaries not snapped to zero crossings.
#
# Additionally, the script will automatically move non-empty interval boundaries to the nearest zero crossing.
#######################################
clearinfo

.moved = 0

pause select TextGrid and matching Sound to check

textGrid$ = selected$("TextGrid",1)
sound$ = selected$("Sound",1)

select TextGrid 'textGrid$'
.tiers = Get number of tiers

for i to .tiers
	select TextGrid 'textGrid$'
	Extract one tier... i
	currentTier$ = selected$("TextGrid",1)
	Down to Table: 0,17,1,0
	currentTable$ = selected$("Table",1)
	.rows = Get number of rows
	printline There are '.rows' total non-blank intervals in tier 'i'.	
	for t to .rows
		select Table 'currentTable$'
		.tMin = Get value: t, "tmin"

		select Sound 'sound$'
		.tMinCrossing = Get nearest zero crossing: 1, .tMin

		select TextGrid 'textGrid$'
		.tierInterval = Get interval at time: i, .tMin
		tierLabel$ = Get label of interval: i, .tierInterval

		# we give .itemInterval a 5ms buffer, which avoids a bug if the item tier moves forward to a zero 
		# crossing. This is a problem if any of our intervals (particularly offsets) are <5ms long, but 
		# in this data that's never the case.
		.tItemMin = 0.005 + .tMin
		.itemInterval = Get interval at time: 1, .tItemMin
		itemLabel$ = Get label of interval: 1, .itemInterval

		if .tMin = 0
		elsif .tMinCrossing != .tMin
			Set interval text: i, .tierInterval, ""
			Remove boundary at time: i, .tMin
			Insert boundary: i, .tMinCrossing
			Set interval text: i, .tierInterval, tierLabel$
			.diff = abs(.tMinCrossing - .tMin)
			if .diff > .001
				printline Boundary in tier 'i' moved '.diff', from '.tMin' to '.tMinCrossing'
			else
			.moved = .moved + 1
			endif
		endif

		if tierLabel$ != itemLabel$
			printline tier 'i' label at '.tMin' ('tierLabel$') doesn't match item label ('itemLabel$')
		endif
	endfor
	selectObject: "Table 'currentTable$'", "TextGrid 'currentTier$'"
	Remove
endfor



printline '.moved' additional boundaries moved less than 1ms to zero crossings.
printline Check completed!
