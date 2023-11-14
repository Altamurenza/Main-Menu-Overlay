-- LIBRARY.LUA
-- AUTHOR	: ALTAMURENZA


-- # HEADER #

RequireSystemAccess()
RequireLoaderVersion(7)

loadlib(GetPackageFilePath('MainMenu.dll'), 'open_mainmenu')()


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
		[GetLocalization('NEWGAME')] = true,
		[GetLocalization('CONTINUE')] = true,
		[GetLocalization('SETTINGS')] = true,
		[GetLocalization('EXIT')] = true,
	})[Option] or false
end
IsLayerIndexAvailable = function(Layer, Index)
	local Color = GetLayerIndexValue(Layer, Index, 'R')
	return type(Color) == 'number' and Color ~= 100 or nil
end
GetLayer = function()
	if not PreCheckKey('Layer', 'string') then
		return
	end
	return MainMenu.Layer
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
SetLayer = function(Layer)
	if not PreCheckArg(Layer, 'string') then
		return
	end
	MainMenu.Layer = Layer
end
SetConfigure = function(Configure)
	if not PreCheckArg(Configure, 'boolean') then
		return
	end
	MainMenu.IsAdjust = Configure
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
SetPreference = function(Table)
	if not PreCheckArg(Table, 'table') then
		return
	end
	MainMenu.Settings = Table
end
SetLocalization = function(Table)
	if not PreCheckArg(Table, 'table') then
		return
	end
	MainMenu.TextMenu = Table
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
		local Lang = GetPreference('Localization')
		
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
			UseDefaultLanguage = {Type = 'boolean', Default = false},
			Localization = {Type = 'string', Default = 'English'},
			ShowImage = {Type = 'number', Default = 0},
			Font1 = {Type = 'string', Default = 'Georgia'},
			Font2 = {Type = 'string', Default = 'Century'},
			MainMidScale = {Type = 'number', Default = 1.3},
			MainBotScale = {Type = 'number', Default = 1.2},
			LoadTopScale = {Type = 'number', Default = 2.5},
			LoadMidScale = {Type = 'number', Default = 1.3},
			LoadBotScale = {Type = 'number', Default = 1.2},
			SettingTopScale = {Type = 'number', Default = 2.5},
			SettingMidScale = {Type = 'number', Default = 1.3},
			SettingBotScale = {Type = 'number', Default = 1.2},
			MainSpacing = {Type = 'number', Default = 0.02},
			LoadSpacing = {Type = 'number', Default = 0.01},
			SettingSpacing = {Type = 'number', Default = 0.02},
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


-- # KEY FUNCTIONS #

IsJoystickButtonPressed = function(Button, Controller)
	if not PreCheckArgs({{Button, 'number'}, {Controller, 'number'}}) then
		return
	end
	
	local Result = Joystick[Controller].Pressed[Button]
	if type(Result) == 'nil' then
		return false
	end
	return Result
end
IsJoystickButtonBeingPressed = function(Button, Controller)
	if not PreCheckArgs({{Button, 'number'}, {Controller, 'number'}}) then
		return
	end
	
	local Result = Joystick[Controller].BeingPressed[Button]
	if type(Result) == 'nil' then
		return false
	end
	return Result
end
IsJoystickButtonBeingReleased = function(Button, Controller)
	if not PreCheckArgs({{Button, 'number'}, {Controller, 'number'}}) then
		return
	end
	
	local Result = Joystick[Controller].BeingReleased[Button]
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
			if Input[Index] and (Index > 1 and Input[Index] ~= Input[1] or true) then
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
		local InputMap = {
			Left = {Index = 0, Codes = {'DIK_LEFT', 'DIK_A', 2}}, 
			Right = {Index = 1, Codes = {'DIK_RIGHT', 'DIK_D', 3}},
			Up = {Index = 2, Codes = {'DIK_UP', 'DIK_W', 0}}, 
			Down = {Index = 3, Codes = {'DIK_DOWN', 'DIK_S', 1}}, 
			Select = {Index = 7, Codes = {'DIK_RETURN', 12}}, 
			Return = {Index = 8, Codes = {'DIK_SPACE', 13}},
		}
		
		local Result = {}
		Result.Joystick = IsUsingJoystick(0)
		
		for String, Table in pairs(InputMap) do
			local Type, Code = GetInputHardware(Table.Index, 0)
			Type = string.upper(Type)
			
			Result[String] = {Result.Joystick and Code or ((Input[Type] and Input[Type][Code]) and Input[Type][Code] or false), unpack(Table.Codes)}
		end
		return Result
	end
	return
end
SetKeyPress = function(Key)
	if not PreCheckArg(Key, 'number') then
		return
	end
	
	-- prevent the "slipping button" issue by setting the other buttons to 0
	for Index = 0, 24 do
		SetStickValue(Index == Key and Key or Index, 0, Index == Key and 1 or 0) -- this doesn't work for joystick ??
		if GetNavigationInput('Joystick') then
			-- it just works by pressing the keyboard input (controller index 1 instead of 0)
			SetStickValue(Index == Key and Key or Index, 1, Index == Key and 1 or 0)
		end
	end
	MainMenu.KeyTimer = GetSystemTimer() + 150
end
SetNavigationInput = function(Table)
	if not PreCheckArg(Table, 'table') then
		return
	end
	MainMenu.Input = Table
end
DisableController = function()
	if GetNavigationInput('Joystick') then
		ZeroController(1)
	end
	ZeroController(0)
end
JoystickListener = function()
	while true do
		Wait(0)
		
		for Controller = 0, 3 do
			for Button = 0, 15 do
				if Joystick[Controller].BeingPressed[Button] then
					Joystick[Controller].BeingPressed[Button] = false
				end
				if Joystick[Controller].BeingReleased[Button] then
					Joystick[Controller].BeingReleased[Button] = false
				end
				
				if IsGamepadButtonPressed(Button, Controller) then
					if not Joystick[Controller].Pressed[Button] then
						Joystick[Controller].BeingPressed[Button] = true
						Joystick[Controller].Pressed[Button] = true
					end
				else
					if Joystick[Controller].Pressed[Button] then
						Joystick[Controller].BeingReleased[Button] = true
						Joystick[Controller].Pressed[Button] = false
					end
				end
			end
		end
	end
end


-- # SAVEDATA FUNCTIONS #

IsSaveDataAvailable = function(Index)
	if not PreCheckArg(Index, 'number') then
		return
	end
	local Result = Select(2, pcall(IsSaveFileAvailable, 'BullyFile'..Index))
	if type(Result) == 'string' then
		PrintWarning(Result)
	end
	
	return type(Result) == 'boolean' and Result or false
end
IsSaveDataTableEmpty = function()
	if type(MainMenu.SaveData) == 'table' and next(MainMenu.SaveData) then
		return false
	end
	return true
end
IsFileTableAvaiable = function()
	local Result = Select(2, pcall(IsSaveFileAvailable, 'FileTableBully'))
	if type(Result) == 'string' then
		PrintWarning(Result)
	end
	
	return type(Result) == 'boolean' and Result or false
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
		return {GetLocalization('NA'), '', ''}
	end
	local Table = GetSaveDataTable(Order)
	if type(Table) ~= 'table' then
		return {GetLocalization('UNKNOWN'), GetLocalization('UNKNOWN'), '0%'}
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
		end
		MainMenu.Table['Main'].LID = 1
		MainMenu.Table['Main'].CID = 1
		MainMenu.ForceEntry = false
		MainMenu.ForceCount = 0
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


-- # SETTING FUNCTIONS #

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
	local Settings, Message = GetRawDisplaySettings()
	if type(Message) == 'string' then
		PrintWarning(Message)
		return
	end
	for Index, Value in ipairs(Settings) do
		if Value == -1 then
			PrintWarning("non-DWORD value: 'Settings > "..GetLayerIndexValue('Settings', Index > 1 and Index - 1 or Index, 'Text').."'")
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
SetSettingOption = function(Index, Option)
	if not PreCheckArgs({
		{MainMenu.Table['Settings'][Index], 'table', 'invalid index'},
		{Option, 'number'},
	}) then return end
	MainMenu.Table['Settings'][Index].BackOpt = Option
	MainMenu.Table['Settings'][Index].CurrOpt = Option
end
SetSettingTable = function(Index, Table)
	if not PreCheckArgs({
		{MainMenu.Table['Settings'][Index], 'table', 'invalid index'},
		{Table, 'table'},
	}) then return end
	MainMenu.Table['Settings'][Index].List = Table
end


-- # MISCELLANEOUS FUNCTIONS #

CreateInputTexture = function(Key)
	if not PreCheckArg(Key, 'string') then
		return
	end
	
	local Button = GetNavigationInput(Key)[1]
	if not Button then
		local Secondary = {
			Up = GetNavigationInput('Joystick') and Input['BUTTON'][0] or 'DIK_UP',
			Down = GetNavigationInput('Joystick') and Input['BUTTON'][1] or 'DIK_DOWN',
			Left = GetNavigationInput('Joystick') and Input['BUTTON'][2] or 'DIK_LEFT',
			Right = GetNavigationInput('Joystick') and Input['BUTTON'][3] or 'DIK_RIGHT',
			Select = GetNavigationInput('Joystick') and Input['BUTTON'][12] or 'DIK_RETURN',
			Return = GetNavigationInput('Joystick') and Input['BUTTON'][13] or 'DIK_SPACE',
		}
		if not Secondary[Key] then
			PrintWarning("invalid key '"..Key.."' to '"..GetFunctionName(1).."'")
			return
		end
		
		Button = Secondary[Key]
	end
	if type(Button) == 'number' and GetNavigationInput('Joystick') then
		Button = Input['BUTTON'][Button]
	end
	
	local Texture = Select(2, pcall(CreateTexture, 'Graphics/Button/'..Button..'.png'))
	if type(Texture) == 'userdata' then
		return Texture, GetTextureDisplayAspectRatio(Texture)
	end
	
	Texture = CreateTexture('Graphics/Button/DIK_PLAIN.png')
	return Texture, GetTextureDisplayAspectRatio(Texture)
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
SoundEffect2D = function(Sound)
	if not PreCheckArg(Sound, 'string') or string.len(Sound) == 0 then
		return
	end
	RunCFunction('0x5D3E60', Sound)
end


-- # LOCAL #

Input = {
	['KEYBOARD'] = {
		[1] = 'DIK_ESCAPE',
		[2] = 'DIK_1',
		[3] = 'DIK_2',
		[4] = 'DIK_3',
		[5] = 'DIK_4',
		[6] = 'DIK_5',
		[7] = 'DIK_6',
		[8] = 'DIK_7',
		[9] = 'DIK_8',
		[10] = 'DIK_9',
		[11] = 'DIK_0',
		[12] = 'DIK_MINUS',
		[13] = 'DIK_EQUALS',
		[14] = 'DIK_BACK',
		[15] = 'DIK_TAB',
		[16] = 'DIK_Q',
		[17] = 'DIK_W',
		[18] = 'DIK_E',
		[19] = 'DIK_R',
		[20] = 'DIK_T',
		[21] = 'DIK_Y',
		[22] = 'DIK_U',
		[23] = 'DIK_I',
		[24] = 'DIK_O',
		[25] = 'DIK_P',
		[26] = 'DIK_LBRACKET',
		[27] = 'DIK_RBRACKET',
		[28] = 'DIK_RETURN',
		[29] = 'DIK_LCONTROL',
		[30] = 'DIK_A',
		[31] = 'DIK_S',
		[32] = 'DIK_D',
		[33] = 'DIK_F',
		[34] = 'DIK_G',
		[35] = 'DIK_H',
		[36] = 'DIK_J',
		[37] = 'DIK_K',
		[38] = 'DIK_L',
		[39] = 'DIK_SEMICOLON',
		[40] = 'DIK_APOSTROPHE',
		[41] = 'DIK_GRAVE',
		[42] = 'DIK_LSHIFT',
		[43] = 'DIK_BACKSLASH',
		[44] = 'DIK_Z',
		[45] = 'DIK_X',
		[46] = 'DIK_C',
		[47] = 'DIK_V',
		[48] = 'DIK_B',
		[49] = 'DIK_N',
		[50] = 'DIK_M',
		[51] = 'DIK_COMMA',
		[52] = 'DIK_PERIOD',
		[53] = 'DIK_SLASH',
		[54] = 'DIK_RSHIFT',
		[55] = 'DIK_MULTIPLY',
		[56] = 'DIK_LMENU',
		[57] = 'DIK_SPACE',
		[58] = 'DIK_CAPITAL',
		[59] = 'DIK_F1',
		[60] = 'DIK_F2',
		[61] = 'DIK_F3',
		[62] = 'DIK_F4',
		[63] = 'DIK_F5',
		[64] = 'DIK_F6',
		[65] = 'DIK_F7',
		[66] = 'DIK_F8',
		[67] = 'DIK_F9',
		[68] = 'DIK_F10',
		[69] = 'DIK_NUMLOCK',
		[71] = 'DIK_NUMPAD7',
		[72] = 'DIK_NUMPAD8',
		[73] = 'DIK_NUMPAD9',
		[74] = 'DIK_SUBTRACT',
		[75] = 'DIK_NUMPAD4',
		[76] = 'DIK_NUMPAD5',
		[77] = 'DIK_NUMPAD6',
		[78] = 'DIK_ADD',
		[79] = 'DIK_NUMPAD1',
		[80] = 'DIK_NUMPAD2',
		[81] = 'DIK_NUMPAD3',
		[82] = 'DIK_NUMPAD0',
		[83] = 'DIK_DECIMAL',
		[87] = 'DIK_F11',
		[88] = 'DIK_F12',
		[141] = 'DIK_NUMPADEQUALS',
		[156] = 'DIK_NUMPADENTER',
		[157] = 'DIK_RCONTROL',
		[181] = 'DIK_DIVIDE',
		[184] = 'DIK_RMENU',
		[197] = 'DIK_PAUSE',
		[199] = 'DIK_HOME',
		[200] = 'DIK_UP',
		[201] = 'DIK_PRIOR',
		[203] = 'DIK_LEFT',
		[205] = 'DIK_RIGHT',
		[207] = 'DIK_END',
		[208] = 'DIK_DOWN',
		[209] = 'DIK_NEXT',
		[210] = 'DIK_INSERT',
		[211] = 'DIK_DELETE',
	},
	['BUTTON'] = {
		[0] = 'JOY_ARROW_UP',
		[1] = 'JOY_ARROW_DOWN',
		[2] = 'JOY_ARROW_LEFT',
		[3] = 'JOY_ARROW_RIGHT',
		[4] = 'JOY_BACK',
		[5] = 'JOY_START',
		[6] = 'JOY_L3',
		[7] = 'JOY_R3',
		[8] = 'JOY_L1',
		[9] = 'JOY_R1',
		[10] = 'JOY_L2',
		[11] = 'JOY_R2',
		[12] = 'JOY_CROSS',
		[13] = 'JOY_CIRCLE',
		[14] = 'JOY_SQUARE',
		[15] = 'JOY_TRIANGLE',
	},
}

Joystick = {
	[0] = {Pressed = {}, BeingPressed = {}, BeingReleased = {}},
	[1] = {Pressed = {}, BeingPressed = {}, BeingReleased = {}},
	[2] = {Pressed = {}, BeingPressed = {}, BeingReleased = {}},
	[3] = {Pressed = {}, BeingPressed = {}, BeingReleased = {}},
}

MainMenu = GetPersistentDataTable()

if not next(MainMenu) then
	MainMenu.Settings = GetPreference()
	MainMenu.SaveData = IsFileTableAvaiable() and GetSaveDataOutlines() or {}
	MainMenu.LastSave = GetLastSavedGame(true)
	MainMenu.LoadSave = nil
	MainMenu.KeyTimer = GetSystemTimer()
	MainMenu.IsAdjust = false
	MainMenu.TextMenu = GetLocalization()
	
	MainMenu.ForceEntry = false
	MainMenu.ForceCount = 0
	
	MainMenu.AspectRatio = GetDisplayAspectRatio()
	MainMenu.Resolution = {GetDisplayResolution()}
	
	MainMenu.Input = {}
	MainMenu.Layer = 'Main'
	MainMenu.Table = {
		['Main'] = {
			LID = 1,
			CID = 1,
			{Text = GetLocalization('CONTINUE'), R = 255, G = 255, B = 255},
			{Text = GetLocalization('LOAD'), R = 255, G = 255, B = 255},
			{Text = GetLocalization('SETTINGS'), R = 255, G = 255, B = 255},
			{Text = GetLocalization('EXIT'), R = 255, G = 255, B = 255},
		},
		['Load'] = {
			CID = MainMenu.LastSave == -1 and 1 or MainMenu.LastSave,
			{Text = GetSaveName(1), R = 255, G = 255, B = 255},
			{Text = GetSaveName(2), R = 255, G = 255, B = 255},
			{Text = GetSaveName(3), R = 255, G = 255, B = 255},
			{Text = GetSaveName(4), R = 255, G = 255, B = 255},
			{Text = GetSaveName(5), R = 255, G = 255, B = 255},
			{Text = GetSaveName(6), R = 255, G = 255, B = 255},
		},
		['Settings'] = {
			CID = 1,
			{Text = GetLocalization('RESOLUTION'), BackOpt = 1, CurrOpt = 1, List = {}},
			{Text = GetLocalization('ANTIALIASING'), BackOpt = 1, CurrOpt = 1, List = {'1x MSAA', '2x MSAA', '4x MSAA', '8x MSAA'}},
			{Text = GetLocalization('VSYNC'), BackOpt = 1, CurrOpt = 1, List = {GetLocalization('OFF'), GetLocalization('ON')}},
			{Text = GetLocalization('SHADOWS'), BackOpt = 1, CurrOpt = 1, List = {GetLocalization('OFF'), GetLocalization('LOW'), GetLocalization('MEDIUM'), GetLocalization('HIGH')}},
		},
	}
end
