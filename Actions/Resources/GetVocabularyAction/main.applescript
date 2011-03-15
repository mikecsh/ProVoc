-- main.applescript
-- ProVoc

--  Created by Simon Bovet on 19.05.06.
--  Copyright 2006 Arizona Software. All rights reserved.

on run {input, parameters}
	
	set theSelectionOnly to |selectionOnly| of parameters
	set theIncludeNames to |includeNames| of parameters
	set theIncludeComments to |includeComments| of parameters
	
	tell application "ProVoc"
		return export only selection theSelectionOnly include names theIncludeNames include comments theIncludeComments
	end tell
	
end run
