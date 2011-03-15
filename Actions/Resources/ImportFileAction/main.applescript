-- main.applescript
-- ProVoc

--  Created by Simon Bovet on 19.05.06.
--  Copyright 2006 Arizona Software. All rights reserved.

on run {input, parameters}
	
	set theFiles to {}
	repeat with i in input
		copy (POSIX path of i) to end of theFiles
	end repeat
	
	if theFiles is not {} then
		set theNewDocument to |newDocument| of parameters
		tell application "ProVoc"
			import theFiles new document theNewDocument
		end tell
	end if
	
	return input
	
end run
