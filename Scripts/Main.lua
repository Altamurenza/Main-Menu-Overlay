-- MAIN.LUA
-- AUTHOR	: ALTAMURENZA


-- # SETUP #

local CallScript = function(Path)
	local Result, Script = pcall(OpenFile, Path, 'r')
	
	if type(Script) ~= 'userdata' then
		Path = string.gsub(Path, '.$', 'r')
		Result, Script = pcall(OpenFile, Path, 'r')
		
		if type(Script) ~= 'userdata' then
			error("no such file in directory: '"..string.gsub(Path, "^.+/(.-)%.%a+$", "%1").."'")
		end
	end
	
	CloseFile(Script)
	LoadScript(Path)
end

CallScript('Scripts/Library.lua')
CallScript('Scripts/Interface.lua')
CallScript = nil


-- # START #

CreateDrawingThread(function()
	while true do
		if GetSaveLoad() then
			SetSaveLoad(nil)
		end
		
		if type(shared) == 'table' and not HasStoryModeBeenSelected() then
			ScreenManagement()
		end
		Wait(0)
	end
end)
