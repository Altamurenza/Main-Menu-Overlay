-- LIBRARY.LUA
-- AUTHOR	: ALTAMURENZA


-- # HEADER #

RequireSystemAccess()
RequireLoaderVersion(10)

local Lib, Err = loadlib(GetPackageFilePath('MainMenu.dll'), 'MainMenu')
if type(Lib) ~= 'function' then
	error(Err)
end
Lib() -- Calling Lib will not return anything, it only registers functions to the _G table.

require('utility/texture')


-- # DISPLAY FUNCTIONS #

IsConfiguring = function()
	if not PreCheckKey('IsAdjust', 'boolean') then
		return 
	end
	return MainMenu.IsAdjust
end
IsNativeOption = function(Option)
	if not PreCheckArg(Option, 'string') then
		return
	end
	return ({
		-- Layer: Main
		[GetLocalization('STORY')] = true,
		[GetLocalization('SETTINGS')] = true,
		[GetLocalization('EXIT')] = true,
		
		-- Layer: Settings
		[GetLocalization('RESOLUTION')] = true,
		[GetLocalization('ANTIALIASING')] = true,
		[GetLocalization('VSYNC')] = true,
		[GetLocalization('SHADOWS')] = true,
	})[Option] or false
end
IsLayerIndexAvailable = function(Layer, Index)
	local Color = GetLayerIndexValue(Layer, Index, 'R')
	return type(Color) == 'number' and Color ~= 100 or nil
end
IsMessageQueuing = function()
	return next(MainMenu.MessageQueue) and type(MainMenu.MessageThread) ~= 'thread'
end
GetLayer = function()
	if not PreCheckKey('Layer', 'string') then
		return
	end
	return MainMenu.Layer
end
GetLayerTable = function(Layer)
	if not PreCheckArg(MainMenu.Table[Layer], 'table', 1, 'invalid layer') then
		return
	end
	return MainMenu.Table[Layer]
end
GetLayerCID = function(Layer)
	if not PreCheckArg(MainMenu.Table[Layer], 'table', 1, 'invalid layer') then
		return
	end
	return MainMenu.Table[Layer].CID
end
GetLayerLID = function(Layer)
	if not PreCheckArg(MainMenu.Table[Layer], 'table', 1, 'invalid layer') then
		return
	end
	return MainMenu.Table[Layer].LID
end
GetLayerSize = function(Layer)
	if not PreCheckArg(MainMenu.Table[Layer], 'table', 1, 'invalid layer') then
		return
	end
	return table.getn(MainMenu.Table[Layer])
end
GetLayerIndexValue = function(Layer, Index, Key)
	if not PreCheckArgs({
		{MainMenu.Table[Layer], 'table', 'invalid layer'},
		{MainMenu.Table[Layer][Index], 'table', 'invalid index'},
	}) then return end
	return MainMenu.Table[Layer][Index][Key]
end
GetFixedWidth = function(Scale, Ratio)
	if not PreCheckArg(Scale, 'number') then
		return
	end
	if type(Ratio) == 'number' then
		return Scale * (Ratio / (MainMenu.AspectRatio / (MainMenu.AspectRatio / 2)))
	end
	return Scale / MainMenu.AspectRatio
end
GetLastAspectRatio = function()
	if not PreCheckKey('AspectRatio', 'number') then
		return
	end
	return MainMenu.AspectRatio
end
GetLastResolution = function()
	if not PreCheckKey('Resolution', 'table') then
		return
	end
	return MainMenu.Resolution[1], MainMenu.Resolution[2]
end
GetQueuedMessage = function(Index)
	if not PreCheckArg(Index, 'number') then
		return
	end
	return MainMenu.MessageQueue[Index][1], MainMenu.MessageQueue[Index][2]
end
SetConfigure = function(Configure)
	if not PreCheckArg(Configure, 'boolean') then
		return
	end
	MainMenu.IsAdjust = Configure
end
SetLayer = function(Layer)
	if not PreCheckArg(Layer, 'string') then
		return
	end
	MainMenu.Layer = Layer
end
SetLayerCID = function(Layer, Value, Adjust)
	if not PreCheckArg(MainMenu.Table[Layer], 'table', 1, 'invalid layer') then
		return
	end
	
	if type(Value) == 'number' then
		MainMenu.Table[Layer].LID = MainMenu.Table[Layer].CID
		MainMenu.Table[Layer].CID = Value
		return
	end
	if type(Adjust) == 'boolean' then
		if Layer == 'Load' and IsSaveDataTableEmpty() then -- avoid to freeze the game since there's no available save
			return
		end
		MainMenu.Table[Layer].LID = MainMenu.Table[Layer].CID
		local Size = GetLayerSize(Layer)
		
		if Adjust then
			MainMenu.Table[Layer].CID = MainMenu.Table[Layer].CID + 1 > Size and 1 or MainMenu.Table[Layer].CID + 1
			while not IsLayerIndexAvailable(Layer, MainMenu.Table[Layer].CID) do
				MainMenu.Table[Layer].CID = MainMenu.Table[Layer].CID + 1 > Size and 1 or MainMenu.Table[Layer].CID + 1
			end
		else
			MainMenu.Table[Layer].CID = MainMenu.Table[Layer].CID - 1 < 1 and Size or MainMenu.Table[Layer].CID - 1
			while not IsLayerIndexAvailable(Layer, MainMenu.Table[Layer].CID) do
				MainMenu.Table[Layer].CID = MainMenu.Table[Layer].CID - 1 < 1 and Size or MainMenu.Table[Layer].CID - 1
			end
		end
	end
end
SetLayerIndexColor = function(Layer, Index, Red, Green, Blue)
	if not PreCheckArgs({
		{MainMenu.Table[Layer], 'table', 'invalid layer'},
		{MainMenu.Table[Layer][Index], 'table', 'invalid index'},
	}) then return end
	
	if type(Red) == 'number' then
		MainMenu.Table[Layer][Index].R = Red
	end
	if type(Green) == 'number' then
		MainMenu.Table[Layer][Index].G = Green
	end
	if type(Blue) == 'number' then
		MainMenu.Table[Layer][Index].B = Blue
	end
end
SetLayerIndexTitle = function(Layer, Index, Title)
	if not PreCheckArgs({
		{MainMenu.Table[Layer], 'table', 'invalid layer'},
		{MainMenu.Table[Layer][Index], 'table', 'invalid index'},
	}) then return end
	MainMenu.Table[Layer][Index].Text = Title
end
SetLastAspectRatio = function(AspectRatio)
	if not PreCheckArg(AspectRatio, 'number') then
		return
	end
	MainMenu.AspectRatio = AspectRatio
end
SetLastResolution = function(Width, Height)
	if not PreCheckArgs({{Width, 'number'}, {Height, 'number'}}) then 
		return
	end
	MainMenu.Resolution = {Width, Height}
end
SetQueuedMessage = function(Message, Second)
	if not PreCheckArgs({{Message, 'string'}, {Second, 'number'}}) then 
		return
	end
	table.insert(MainMenu.MessageQueue, {Message, Second})
end
ShowQueuedMessage = function(Func, TUD, TAR, Message, Second)
	if not PreCheckArgs({
		{Func, 'function'}, {TUD, 'table'}, {TAR, 'table'},
		{Message, 'string'}, {Second, 'number'}
	}) then return end
	MainMenu.MessageThread = CreateDrawingThread(Func, TUD, TAR, Message, Second)
end

-- # INPUT FUNCTIONS #

GetScriptPath = function()
	return GetScriptFilePath()..(gDerpyScriptLoader < 8 and GetScriptCollection() or '')
end
GetKeyValue = function(File)
	if not PreCheckHandler(File) then
		return
	end
	
	local Result = {}
	for Line in File:lines() do
		Line = string.gsub(Line, '[\r\n]*$', '')
		if not string.find(Line, '#') and string.find(Line, '=') then
			local Value = string.gsub(Line, '([^=]+)=(.*)', '%2')
			local Check = tonumber(Value) or ({['true'] = true, ['false'] = false})[Value]
			Value = type(Check) == 'nil' and Value or Check
			Result[string.gsub(Line, '([^=]+)=(.*)', '%1')] = Value
		end
	end
	return Result
end
GetLocalization = function(Key)
	if type(Key) == 'string' and PreCheckKey('TextMenu', 'table') then
		return MainMenu.TextMenu[Key] or MainMenu.TextMenu['UNKNOWN']
	end
	
	if type(Key) == 'nil' then
		local Lang = GetPreference('MenuLocalization')
		
		local Path = GetScriptPath()..'/Translations/'..Lang..'.txt'
		local File = io.open(Path, 'rb')
		if File then
			local Table = GetKeyValue(File)
			File:close()
			return Table
		end
		
		PrintWarning('missing localization file: "'..Path..'"')
		
		Path = GetScriptPath()..'/Translations/English.txt'
		File = assert(io.open(Path, 'rb'), 'missing localization file: "'..Path..'"')
		local Table = GetKeyValue(File)
		File:close()
		return Table
	end
	return
end
GetPreference = function(Key)
	if type(Key) == 'string' and PreCheckKey('Settings', 'table') then
		return MainMenu.Settings[Key]
	end
	
	if type(Key) == 'nil' then
		local Test = {
			GameLocalization = {Type = 'number', Default = -1},
			MenuLocalization = {Type = 'string', Default = 'English'},
			ShowImage = {Type = 'number', Default = 0},
			Font1 = {Type = 'string', Default = 'Georgia'},
			Font2 = {Type = 'string', Default = 'Century'},
			MenuTopScale = {Type = 'number', Default = 2.5},
			MenuMidScale = {Type = 'number', Default = 1.2},
			MenuBotScale = {Type = 'number', Default = 1.1},
			MenuSpacing = {Type = 'number', Default = 0.02},
		}
		
		local Path = GetScriptPath()..'/Preferences.ini'
		local File = io.open(Path, 'rb')
		if File then
			local Table = GetKeyValue(File)
			File:close()
			
			for Key, Value in pairs(Test) do
				if type(Table[Key]) == 'nil' or type(Table[Key]) ~= Value.Type then
					Table[Key] = Value.Default
				end
			end
			return Table
		end
		
		PrintWarning('missing preference file: "'..Path..'"')
		
		local Subs = {}
		for Key, Value in pairs(Test) do
			Subs[Key] = Value.Default
		end
		return Subs
	end
	return
end
SetPreference = function(Language)
	local Path = GetScriptPath()..'/Preferences.ini'
	local File = io.open(Path, 'wb')
	if not File then
		PrintWarning('could not write a file: "'..Path..'"')
	end
	
	local Preference = [[
[Localization]
# 
# Introduced in: 1.0
# Updated in: 3.0
# 
# Set the 'GameLocalization' parameter to one of the following numerical values 
# to change the game language:
# 
#    -1 = Default (based on the system registry)
#     0 = English (US)
#     1 = French
#     2 = German
#     3 = Italian
#     4 = Spanish
#     5 = English (UK)
#     6 = Russian
#     7 = Japanese
# 
# To customize main menu localization, set 'MenuLocalization' to the name of a 
# localization folder in the '../MainMenu/Translations' folder.
# 
GameLocalization=%d
MenuLocalization=%s

[Image]
# 
# Introduced in: 1.0
# Updated in: 2.0
# 
# Set the 'ShowImage' parameter to change the title screen image.
# The image must be located in the "../Graphics/Base/" folder.
# 
#    -1 = No image
#     0 = Random image
#     1-6 = Fixed image (select a specific image by number)
# 
ShowImage=%d

[FontType]
# 
# Introduced in: 1.0
# Updated in: -
# 
# Set 'Font1' and 'Font2' to any installed font available on the user's system.
#     'Font1' is primarily used across various UI components.
#     'Font2' is exclusively used for options in the Settings menu.
# 
Font1=%s
Font2=%s

[Layout]
# 
# Introduced in: 1.0
# Updated in: 2.3
# 
# Adjust the following values if the menu scale appears too small to read.
# 
LayoutTopScale=%.2f
LayoutMidScale=%.2f
LayoutBotScale=%.2f
LayoutSpacing=%.2f
	]]
	File:write(string.format(
		Preference,
		Language,
		GetPreference('MenuLocalization'),
		GetPreference('ShowImage'),
		GetPreference('Font1'),
		GetPreference('Font2'),
		GetPreference('LayoutTopScale'),
		GetPreference('LayoutMidScale'),
		GetPreference('LayoutBotScale'),
		GetPreference('LayoutSpacing')
	))
	File:close()
	
	MainMenu.Settings['GameLocalization'] = Language
end
SetLocalization = function(Table)
	if not PreCheckArg(Table, 'table') then
		return
	end
	MainMenu.TextMenu = Table
end


-- # KEY FUNCTIONS #

IsJoystickButtonPressed = function(Button, Controller)
	if not PreCheckArgs({{Button, 'number'}, {Controller, 'number'}}) then
		return
	end
	
	local Result = GetJoystickValue(Controller, Button, 'Pressed')
	if type(Result) == 'nil' then
		return false
	end
	return Result
end
IsJoystickButtonBeingPressed = function(Button, Controller)
	if not PreCheckArgs({{Button, 'number'}, {Controller, 'number'}}) then
		return
	end
	
	local Result = GetJoystickValue(Controller, Button, 'BeingPressed')
	if type(Result) == 'nil' then
		return false
	end
	return Result
end
IsJoystickButtonBeingReleased = function(Button, Controller)
	if not PreCheckArgs({{Button, 'number'}, {Controller, 'number'}}) then
		return
	end
	
	local Result = GetJoystickValue(Controller, Button, 'BeingReleased')
	if type(Result) == 'nil' then
		return false
	end
	return Result
end
GetKeyPress = function(Key)
	if not PreCheckArg(Key, 'string') or not PreCheckKey('KeyTimer', 'number') then
		return
	end
	
	if GetSystemTimer() > MainMenu.KeyTimer and GetNavigationInput(Key) then
		local Input = GetNavigationInput(Key)
		for Index = 1, table.getn(Input) do
			if Input[Index] then
				--[[
					possibly bugs from DSL:
					1. IsKeyBeingPressed(Key, 0) is behaving like IsKeyPressed, but IsKeyBeingPressed(Key) is functioning as expected
					2. IsKeyBeingReleased(Key, 0) doesn't work
				]]
				
				if type(Input[Index]) == 'string' and IsKeyBeingPressed(Input[Index]) then
					return true
				end
				if type(Input[Index]) == 'number' and IsJoystickButtonBeingPressed(Input[Index], 0) then
					return true
				end
			end
		end
	end
	return false
end
GetNavigationInput = function(Key)
	if type(Key) == 'string' and PreCheckKey('Input', 'table') then
		return MainMenu.Input[Key]
	end
	
	if type(Key) == 'nil' then
		return {
			-- joystick or keyboard
			Joystick = IsUsingJoystick(0),
			
			-- input map
			Left = {'DIK_LEFT', 'DIK_A', 2}, 
			Right = {'DIK_RIGHT', 'DIK_D', 3},
			Up = {'DIK_UP', 'DIK_W', 0}, 
			Down = {'DIK_DOWN', 'DIK_S', 1}, 
			Select = {'DIK_RETURN', 12}, 
			Return = {'DIK_SPACE', 13},
		}
	end
	return
end
GetJoystickValue = function(Controller, Button, Key)
	if not PreCheckArgs({
		{Controller, 'number'}, {Button, 'number'}, 
		{Joystick[Controller][Key], 'table', 'invalid key'}
	}) then return end
	
	return Joystick[Controller][Key][Button]
end
SetKeyPress = function(Key)
	if not PreCheckArg(Key, 'number') then
		return
	end
	
	-- prevent the "slipping button" issue by setting the other buttons to 0
	for Index = 0, 24 do
		SetStickValue(Index == Key and Key or Index, 0, Index == Key and 1 or 0)
		if GetNavigationInput('Joystick') then
			SetStickValue(Index == Key and Key or Index, 1, Index == Key and 1 or 0)
		end
	end
	MainMenu.KeyTimer = GetSystemTimer() + 150
end
SetKeyPressOnce = function(Key, Wait1, Wait2)
	if not PreCheckArg(Key, 'number') then
		return
	end
	
	local Sleep = function(Ms)
		local Timer = GetSystemTimer()
		while Timer + Ms > GetSystemTimer() do
			Wait(0)
		end
	end
	
	local IsPressed = false
	local Event = RegisterLocalEventHandler('ControllerUpdating', function(ID)
		if ID == 0 and not IsPressed then
			SetButtonPressed(Key, 0, true)
			IsPressed = true
		end
	end)
	Sleep(150)
	RemoveEventHandler(Event)
	Sleep(150)
end
SetNavigationInput = function(Table)
	if not PreCheckArg(Table, 'table') then
		return
	end
	MainMenu.Input = Table
end
SetJoystickValue = function(Controller, Button, Pressed, BeingPressed, BeingReleased)
	if not PreCheckArgs({{Controller, 'number'}, {Button, 'number'}}) then
		return
	end
	
	if type(Pressed) ~= 'nil' then
		Joystick[Controller].Pressed[Button] = Pressed
	end
	if type(BeingPressed) ~= 'nil' then
		Joystick[Controller].BeingPressed[Button] = BeingPressed
	end
	if type(BeingReleased) ~= 'nil' then
		Joystick[Controller].BeingReleased[Button] = BeingReleased
	end
end
DisableController = function()
	if GetNavigationInput('Joystick') then
		ZeroController(1)
	end
	ZeroController(0)
end
JoystickListener = function(Controller)
	while not RunCFunction('0x5D53E0') do
		Wait(0)
		
		for Button = 0, 15 do
			if GetJoystickValue(Controller, Button, 'BeingPressed') then
				SetJoystickValue(Controller, Button, nil, false, nil)
			end
			if GetJoystickValue(Controller, Button, 'BeingReleased') then
				SetJoystickValue(Controller, Button, nil, nil, false)
			end
			
			local IsPressed = IsGamepadButtonPressed(Button, Controller)
			if IsPressed and not GetJoystickValue(Controller, Button, 'Pressed') then
				SetJoystickValue(Controller, Button, true, true, nil)
			elseif not IsPressed and GetJoystickValue(Controller, Button, 'Pressed') then
				SetJoystickValue(Controller, Button, false, nil, true)
			end
		end
	end
end


-- # SAVEDATA FUNCTIONS #

IsSaveDataAvailable = function(Index)
	if not PreCheckArg(Index, 'number') then
		return
	end
	return IsSaveFileAvailable('BullyFile'..Index)
end
IsSaveDataTableEmpty = function()
	if type(MainMenu.SaveData) == 'table' and next(MainMenu.SaveData) then
		return false
	end
	return true
end
IsSavingGame = function()
	-- require system thread or drawing thread
	return IsGamePaused() and PedMePlaying(gPlayer, 'AnimSave')
end
IsFileTableAvaiable = function()
	return IsSaveFileAvailable('FileTableBully')
end
IsForceReset = function()
	if not PreCheckKey('ForceReset', 'boolean') then
		return
	end
	return MainMenu.ForceReset
end
GetLastSavedGame = function(Get)
	if type(Get) == 'nil' and PreCheckKey('LastSave', 'number') then
		return MainMenu.LastSave
	end
	
	if type(Get) == 'boolean' and Get then
		local LastSave = IsFileTableAvaiable() and GetSaveLastID() or -1
		if LastSave > 0 and IsSaveDataAvailable(LastSave) then
			return LastSave
		end
		
		local LastDate = {-1, 0}
		for Index = 1, 6 do
			local NextDate = GetTimestamp(Index)
			if NextDate then
				if LastDate[2] > 0 then
					if NextDate > LastDate[2] then
						LastSave = Index
						LastDate = {Index, NextDate}
					else
						LastSave = LastDate[1]
					end
				else
					LastSave = Index
					LastDate = {Index, NextDate}
				end
			end
		end
		return LastSave
	end
	return
end
GetTimestamp = function(Index)
	if not PreCheckArg(Index, 'number') then
		return
	end
	
	local Table = GetSaveDataTable(Index)
	if type(Table) ~= 'table' then
		return nil
	end
	
	return os.time({
		year = 2000 + Table.SaveYear, month = Table.SaveMonth, day = Table.SaveDay,
		hour = Table.SaveHour, min = Table.SaveMinute, sec = Table.SaveSecond
	})
end
GetSaveName = function(Order)
	if not PreCheckArg(Order, 'number') then
		return
	end
	
	if not IsSaveDataAvailable(Order) then
		return {GetLocalization('NA'), '-', '-'}
	end
	local Table = GetSaveDataTable(Order)
	if type(Table) ~= 'table' then
		return {GetLocalization('UNREGISTERED'), '-', '-'}
	end
	return {
		(Table.LastChapter + 1 >= 6 and GetLocalization('SUMMER') or GetLocalization('CHAPTER')..' '..(Table.LastChapter + 1))..' : '..GetLocalization('AREA_'..Table.LastArea),
		GetLocalization('MISSION_'..Table.LastMission),
		string.format('%.2f', Table.GameCompletion)..'%',
	}
end
GetSaveLoad = function()
	return MainMenu.LoadSave
end
GetSaveDataTable = function(Index)
	if not PreCheckArg(Index, 'number') or not PreCheckKey('SaveData', 'table') then
		return
	end
	return MainMenu.SaveData[Index]
end
SetSaveLoad = function(Order)
	if type(Order) == 'nil' then
		if type(GetSaveLoad()) == 'number' then
			SetProxyFiles(false)
			print('revert')
		end
		MainMenu.Table['Main'].LID = 1
		MainMenu.Table['Main'].CID = 1
		MainMenu.ForceEntry = 0
		SetLayer('Main')
		collectgarbage()
	end
	MainMenu.LoadSave = Order
end
SetLastSavedGame = function(Order)
	MainMenu.Table['Load'].CID = Order
	MainMenu.LastSave = Order
end
SetSaveDataTable = function(Table)
	if not PreCheckArg(Table, 'table') then
		return
	end
	MainMenu.SaveData = Table
end
SetForceReset = function(Reset)
	if not PreCheckArg(Reset, 'boolean') then
		return
	end
	
	MainMenu.ForceReset = Reset
	if not Reset then
		RunCFunction('0x5D53A0')
	end
end
UpdateSaveData = function()
	if not IsSavingGame() then
		return
	end
	
	local Date = GetSaveDataDate('FileTableBully')
	local EncodedPNG = CapturePNG()
	repeat
		Wait(0)
	until not IsSavingGame()
	
	if Date ~= GetSaveDataDate('FileTableBully') and type(EncodedPNG) == 'string' and IsFileTableAvaiable() then
		local Slot = GetSaveLastID()
		local File = io.open(GetScriptPath()..'/Graphics/Load/BullyFile'..Slot..'.png', 'wb')
		File:write(EncodedPNG)
		File:close()
	end
end


-- # SETTING FUNCTIONS #

GetLanguageOption = function()
	return GetPreference('GameLocalization') == -1 and 1 or RunCFunction('0x5D5C10') + 2
end
GetSettingOption = function(Index)
	if not PreCheckArg(MainMenu.Table['Settings'][Index], 'table', 1, 'invalid index') then
		return
	end
	return MainMenu.Table['Settings'][Index].BackOpt, MainMenu.Table['Settings'][Index].CurrOpt
end
GetSettingTable = function(Index)
	if not PreCheckArg(MainMenu.Table['Settings'][Index], 'table', 1, 'invalid index') then
		return
	end
	return MainMenu.Table['Settings'][Index].List
end
GetDisplaySettings = function()
	local Settings, Message = GetDisplayValues()
	if type(Message) == 'string' then
		PrintWarning(Message)
		return
	end
	for Index, Value in ipairs(Settings) do
		if Value == -1 then
			PrintWarning("unable to get raw value for 'Settings > "..GetLayerIndexValue('Settings', Index > 1 and Index - 1 or Index, 'Text').."'")
			return
		end
	end
	SetSettingTable(1, GetDisplayModes() or {Settings[1]..'x'..Settings[2]})
	
	local Output = {}
	for Index, Resolution in ipairs(GetSettingTable(1)) do
		if Resolution == Settings[1]..'x'..Settings[2] then
			table.insert(Output, Index)
			break
		end
	end
	table.insert(Output, ({[1] = 1, [2] = 2, [4] = 3, [8] = 4})[Settings[3]])
	table.insert(Output, Settings[4] + 1)
	table.insert(Output, Settings[5] + 1)
	return Output
end
SetSettingOption = function(Index, Value, Adjust)
	if not PreCheckArg(MainMenu.Table['Settings'][Index], 'table', 1, 'invalid index') then
		return
	end
	
	if type(Value) == 'number' then
		MainMenu.Table['Settings'][Index].BackOpt = Value
		MainMenu.Table['Settings'][Index].CurrOpt = Value
		return
	end
	if type(Adjust) == 'boolean' then
		local Current = MainMenu.Table['Settings'][Index].CurrOpt
		if Adjust then
			MainMenu.Table['Settings'][Index].CurrOpt = Current + 1 > table.getn(GetSettingTable(Index)) and 1 or Current + 1
		else
			MainMenu.Table['Settings'][Index].CurrOpt = Current - 1 < 1 and table.getn(GetSettingTable(Index)) or Current - 1
		end
	end
end
SetSettingTable = function(Index, Table)
	if not PreCheckArgs({
		{MainMenu.Table['Settings'][Index], 'table', 'invalid index'},
		{Table, 'table'},
	}) then return end
	MainMenu.Table['Settings'][Index].List = Table
end


-- # MISCELLANEOUS FUNCTIONS #

StartGame = function(Reset)
	if not PreCheckArg(Reset, 'boolean') then
		return
	end
	
	if MainMenu.ForceEntry < (Reset and 10 or 1) then
		(math.mod(MainMenu.ForceEntry, 2) == 0 and SetStickValue or DisableController)(7, 0, 1)
		MainMenu.ForceEntry = MainMenu.ForceEntry + 1
	end
end
GetFunctionName = function(Level)
	if type(Level) == 'number' then
		return debug.getinfo(Level, 'n').name or '??'
	end
	Level = 0
	while debug.getinfo(Level, 'n').name do
		Level = Level + 1
	end
	return debug.getinfo(Level - 1, 'n').name
end
PreCheckArg = function(Value, Expected, Index, Message)
	if type(Value) ~= Expected then
		PrintWarning("bad argument #"..(Index or 1).." to '"..GetFunctionName().."' ("..(
			type(Message) == "string" and Message or "expected "..Expected..", got "..type(Value)
		)..")")
		return false
	end
	return true
end
PreCheckArgs = function(Table)
	for Index, Arg in ipairs(Table) do
		if not PreCheckArg(Arg[1], Arg[2], Index, Arg[3]) then
			return false
		end
	end
	return true
end
PreCheckKey = function(Key, Expected, Message)
	if type(MainMenu[Key]) ~= Expected then
		PrintWarning("invalid type '"..Key.."' to '"..GetFunctionName().."' ("..(
			type(Message) == "string" and Message or "expected "..Expected..", got "..type(MainMenu[Key])
		)..")")
		return false
	end
	return true
end
PreCheckKeys = function(Table)
	for Index, Arg in ipairs(Table) do
		if not PreCheckKey(Arg[1], Arg[2], Arg[3]) then
			return false
		end
	end
	return true
end
PreCheckHandler = function(File, Index, Message)
	if io.type(File) ~= 'file' then
		PrintWarning("invalid handler #"..(Index or 1).." to '"..GetFunctionName().."'")
		return false
	end
	return true
end
Select = function(...)
	if type(arg[1]) ~= 'number' and arg[1] ~= '#' then
		PrintOutput("bad argument #1 to 'Select' (expected index, got "..tostring(arg[1])..")")
		return
	end
	
	if type(arg[1]) == 'number' and arg[1] + 1 <= table.getn(arg) then
		local result = {}
		for id = arg[1] + 1, table.getn(arg) do
			result[table.getn(result) + 1] = arg[id]
		end
		return unpack(result)
	end
	if arg[1] == '#' then
		return table.getn(arg) - 1
	end
	
	return
end


-- # LOCAL #

Joystick = {
	[0] = {Pressed = {}, BeingPressed = {}, BeingReleased = {}},
	[1] = {Pressed = {}, BeingPressed = {}, BeingReleased = {}},
	[2] = {Pressed = {}, BeingPressed = {}, BeingReleased = {}},
	[3] = {Pressed = {}, BeingPressed = {}, BeingReleased = {}},
}


MainMenu = GetPersistentDataTable('MainMenu')

-- A NOTE ABOUT PERSISTENT DATA:
--[[
	Future me might wonder why I wrote type(shared) ~= 'table' below. Here's why:
	
	DSL 10 introduced a new PersistentDataTable mechanism, saving data to a file called savedata.bin.
	Previously, the function stored nothing, so every time we started the game, it reset to its default state.
	
	However, the issue arises when the game unexpectedly stops (e.g., crash or ALT + F4). In such cases, the
	latest persistent data is used, causing the sub-menu to reflect the last selected state. This disrupts
	the ButtonManagement event (see Interface.lua).
	
	In order to replicate the behavior of the old GetPersistentDataTable, the table must be in its default state
	during init. While there are many ways to detect the init phase, checking type(shared) ~= 'table' is the simplest.
	The shared table is only declared once the game boots.
	
	Deleting the data WILL NOT resolve the issue because both Init.lua and Main.lua rely on this script for communication.
]]
if not next(MainMenu) or type(shared) ~= 'table' then
	MainMenu.Settings = GetPreference()
	MainMenu.SaveData = IsFileTableAvaiable() and GetSaveDataOutlines() or {}
	MainMenu.LastSave = GetLastSavedGame(true)
	MainMenu.LoadSave = nil
	MainMenu.KeyTimer = GetSystemTimer()
	MainMenu.IsAdjust = false
	MainMenu.TextMenu = GetLocalization()
	
	MainMenu.MessageThread = nil
	MainMenu.MessageQueue = {}
	
	MainMenu.ForceReset = false
	MainMenu.ForceEntry = 0
	
	MainMenu.AspectRatio = GetDisplayAspectRatio()
	MainMenu.Resolution = {GetDisplayResolution()}
	
	MainMenu.Input = {}
	MainMenu.Layer = 'Main'
	MainMenu.Table = {
		['Main'] = {
			LID = 1,
			CID = 1,
			{Text = GetLocalization('STORY'), R = 255, G = 255, B = 255},
			{Text = GetLocalization('SETTINGS'), R = 255, G = 255, B = 255},
			{Text = GetLocalization('EXIT'), R = 255, G = 255, B = 255},
		},
		['Story'] = {
			LID = 1,
			CID = GetLastSavedGame() == -1 and 2 or 1,
			{Text = GetLocalization('CONTINUE'), R = 255, G = 255, B = 255},
			{Text = GetLocalization('NEWGAME'), R = 255, G = 255, B = 255},
			{Text = GetLocalization('LOAD'), R = 255, G = 255, B = 255},
		},
		['Load'] = {
			LID = 1,
			CID = GetLastSavedGame() == -1 and 1 or MainMenu.LastSave,
			{Text = GetSaveName(1), R = 255, G = 255, B = 255},
			{Text = GetSaveName(2), R = 255, G = 255, B = 255},
			{Text = GetSaveName(3), R = 255, G = 255, B = 255},
			{Text = GetSaveName(4), R = 255, G = 255, B = 255},
			{Text = GetSaveName(5), R = 255, G = 255, B = 255},
			{Text = GetSaveName(6), R = 255, G = 255, B = 255},
		},
		['Settings'] = {
			LID = 1,
			CID = 1,
			{Text = GetLocalization('RESOLUTION'), BackOpt = 1, CurrOpt = 1, List = {}, R = 255, G = 255, B = 255},
			{Text = GetLocalization('ANTIALIASING'), BackOpt = 1, CurrOpt = 1, List = {'1x MSAA', '2x MSAA', '4x MSAA', '8x MSAA'}, R = 255, G = 255, B = 255},
			{Text = GetLocalization('VSYNC'), BackOpt = 1, CurrOpt = 1, List = {GetLocalization('OFF'), GetLocalization('ON')}, R = 255, G = 255, B = 255},
			{Text = GetLocalization('SHADOWS'), BackOpt = 1, CurrOpt = 1, List = {GetLocalization('OFF'), GetLocalization('LOW'), GetLocalization('MEDIUM'), GetLocalization('HIGH')}, R = 255, G = 255, B = 255},
			{Text = GetLocalization('LANGUAGE'), BackOpt = GetLanguageOption(), CurrOpt = GetLanguageOption(), List = {GetLocalization('DEFAULT'), GetLocalization('AMERICAN'), GetLocalization('FRENCH'), GetLocalization('GERMAN'), GetLocalization('ITALIAN'), GetLocalization('SPANISH'), GetLocalization('BRITISH'), GetLocalization('RUSSIAN'), GetLocalization('JAPANESE')}, R = 255, G = 255, B = 255},
		},
	}
end
