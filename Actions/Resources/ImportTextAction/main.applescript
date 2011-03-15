-- main.applescript
-- ProVoc

--  Created by Simon Bovet on 19.05.06.
--  Copyright 2006 Arizona Software. All rights reserved.

on run {input, parameters}
	
	set theNewDocument to |newDocument| of parameters
	tell application "ProVoc"
		import text input new document theNewDocument
	end tell
	
	return input
	
end run
