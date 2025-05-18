-- PRE-INIT.LUA
-- AUTHOR	: ALTAMURENZA


-- # SETUP #
MainMenu = GetPersistentDataTable('MainMenu')
for Key in pairs(MainMenu) do
	MainMenu[Key] = nil
end


-- # START #

local Language = nil
local Path = GetScriptFilePath()..'/Preferences.ini'
local File = assert(io.open(Path, 'rb'), 'missing preference file: "'..Path..'"')

local Pattern = '([^=]+)=(.*)'
for Line in File:lines() do
	Line = string.gsub(Line, '[\r\n]*$', '')
	if not string.find(Line, '#') and string.find(Line, '=') then
		local Key = string.gsub(Line, Pattern, '%1')
		local Value = string.gsub(Line, Pattern, '%2')
		Value = tonumber(Value)
		
		if Key == 'GameLocalization' and type(Value) == 'number' then
			Language = Value
			break
		end
	end
end

File:close()

if type(Language) ~= 'number' or Language < -1 or Language > 7 then
	error('unknown language')
end
if Language >= 0 and Language <= 7 then
	ptr('0xC18728').uint32 = Language
	ptr('0xC18724').uint32 = Language
end