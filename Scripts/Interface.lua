-- INTERFACE.LUA
-- AUTHOR	: ALTAMURENZA


-- # CONTROL #

ButtonManagement = function()
	if not IsConsoleActive() and not GetSaveLoad() then
		local Layer = GetLayer()
		
		if GetKeyPress('Up') then
			SetLayerCID(Layer, nil, false)
			if Layer == 'Main' then
				local IsLNative = IsNativeOption(GetLayerIndexValue(Layer, GetLayerLID(Layer), 'Text'))
				local IsCNative = IsNativeOption(GetLayerIndexValue(Layer, GetLayerCID(Layer), 'Text'))
				if (not IsLNative and IsCNative) or (not IsLNative and not IsCNative) then
					RunCFunction('0x5D3E60', 'NavUp')
					DisableController()
				else
					SetKeyPress(0)
				end
			elseif Layer == 'Story' or Layer == 'Load'then
				RunCFunction('0x5D3E60', 'NavUp')
				DisableController()
			elseif Layer == 'Settings' and not IsConfiguring() then
				SetKeyPress(1) -- 1 is prev in the Settings menu
			else
				DisableController()
			end
		elseif GetKeyPress('Down') then
			SetLayerCID(Layer, nil, true)
			if Layer == 'Main' then
				if not IsNativeOption(GetLayerIndexValue(Layer, GetLayerCID(Layer), 'Text')) then
					RunCFunction('0x5D3E60', 'NavDwn')
					DisableController()
				else
					SetKeyPress(1)
				end
			elseif Layer == 'Story' or Layer == 'Load' then
				RunCFunction('0x5D3E60', 'NavDwn')
				DisableController()
			elseif Layer == 'Settings' and not IsConfiguring() then
				SetKeyPress(0) -- 0 is next in the Settings menu
			else
				DisableController()
			end
		elseif GetKeyPress('Left') then
			if Layer == 'Settings' and IsConfiguring() then
				SetSettingOption(GetLayerCID(Layer), nil, false)
				SetKeyPress(0)
			else
				DisableController()
			end
		elseif GetKeyPress('Right') then
			if Layer == 'Settings' and IsConfiguring() then
				SetSettingOption(GetLayerCID(Layer), nil, true)
				SetKeyPress(1)
			else
				DisableController()
			end
		elseif GetKeyPress('Return') then
			if Layer == 'Story' then
				SetLayer('Main')
				RunCFunction('0x5D3E60', 'ButtonDwn')
				DisableController()
			elseif Layer == 'Settings' and IsConfiguring() then
				local CID = GetLayerCID(Layer)
				SetSettingOption(CID, GetSettingOption(CID))
				SetConfigure(false)
				SetKeyPress(8)
			elseif Layer == 'Load' or (Layer == 'Settings' and not IsConfiguring()) then
				SetLayerCID(Layer, Layer == 'Load' and GetLayerCID(Layer) or 1)
				SetLayer(Layer == 'Load' and 'Story' or 'Main')
				local Function = Layer == 'Load' and DisableController or SetKeyPress
				Function(8)
			else
				DisableController()
			end
		elseif GetKeyPress('Select') then
			if Layer == 'Main' then
				local Title = GetLayerIndexValue(Layer, GetLayerCID(Layer), 'Text')
				if Title == GetLocalization('STORY') or Title == GetLocalization('SETTINGS') or Title == GetLocalization('EXIT') then
					local Function = Title == GetLocalization('EXIT') and QuitGame or SetLayer
					Function(Title == GetLocalization('STORY') and 'Story' or 'Settings')
					RunCFunction('0x5D3E60', 'ButtonUp')
					Function = Title == GetLocalization('STORY') and DisableController or SetKeyPress
					Function(7)
				else
					DisableController()
				end
			elseif Layer == 'Story' then
				local Title = GetLayerIndexValue(Layer, GetLayerCID(Layer), 'Text')
				if Title == GetLocalization('CONTINUE') then
					if IsSaveDataAvailable(IsFileTableAvaiable() and GetSaveLastID() or -1) then
						SetSaveLoad(true)
					end
					if not GetSaveLoad() and IsSaveDataAvailable(GetLastSavedGame()) and SetProxyFiles(true, GetLastSavedGame()) then
						SetSaveLoad(GetLastSavedGame())
					end
					if not GetSaveLoad() then
						for Index = 1, 6 do
							if IsSaveDataAvailable(Index) and SetProxyFiles(true, GetLayerCID(Layer)) then
								SetSaveLoad(Index)
								break
							end
						end
					end
					if not GetSaveLoad() then
						PrintWarning("FORCE BOOT! unable to load any savedata")
						SetSaveLoad(true)
					end
					RunCFunction('0x5D3E60', 'ButtonUp')
					DisableController()
				elseif Title == GetLocalization('NEWGAME')then
					SetForceReset(true)
					SetSaveLoad(true)
					RunCFunction('0x5D3E60', 'ButtonUp')
					DisableController()
				elseif Title == GetLocalization('LOAD') then
					SetLayer('Load')
					RunCFunction('0x5D3E60', 'ButtonUp')
					DisableController()
				else
					DisableController()
				end
			elseif Layer == 'Load' then
				if IsSaveDataAvailable(GetLayerCID(Layer)) then
					if SetProxyFiles(true, GetLayerCID(Layer)) then
						SetSaveLoad(GetLayerCID(Layer))
					else
						PrintWarning('unable to load savedata: "BullyFile'..GetLayerCID(Layer)..'"')
					end
				end
				RunCFunction('0x5D3E60', 'ButtonUp')
				DisableController()
			elseif Layer == 'Settings' then
				if IsConfiguring() then
					local CID = GetLayerCID(Layer)
					SetSettingOption(CID, Select(2, GetSettingOption(CID)))
					RunCFunction('0x5D3E60', 'ButtonUp')
				end
				SetConfigure(not IsConfiguring())
				SetKeyPress(7)
			else
				DisableController()
			end
		else
			DisableController()
		end
	end
	
	-- load the game
	if GetSaveLoad() then
		StartGame(IsForceReset())
	end
	
	-- prevent the game to detect any input while typing on the console
	if IsConsoleActive() then
		DisableController()
	end
end


-- # VISUAL #

CreateMenuComponent = function(TUD, TAR)
	TUD.Background = CreateTexture('Graphics/Base/Background.png')
	TAR.Background = GetTextureDisplayAspectRatio(TUD.Background)
	TUD.Ebox = CreateTexture('Graphics/Base/Ebox.png')
	TAR.Ebox = GetTextureDisplayAspectRatio(TUD.Ebox)
	TUD.Logo = CreateTexture('Graphics/Base/Logo.png')
	TAR.Logo = GetTextureDisplayAspectRatio(TUD.Logo)
	TUD.Prev = CreateTexture('Graphics/Base/Prev.png')
	TAR.Prev = GetTextureDisplayAspectRatio(TUD.Prev)
	TUD.Next = CreateTexture('Graphics/Base/Next.png')
	TAR.Next = GetTextureDisplayAspectRatio(TUD.Next)
	
	local Option = GetPreference('ShowImage')
	if Option >= 0 and Option <= 6 then
		if Option == 0 then
			math.randomseed(GetSystemTimer())
			Option = math.random(1, 6)
		end
		
		TUD.Image = CreateTexture('Graphics/Base/Image0'..Option..'.png')
		TAR.Image = GetTextureDisplayAspectRatio(TUD.Image)
	end
end
UpdateMenuTable = function()
	SetSaveDataTable(IsFileTableAvaiable() and GetSaveDataOutlines() or {})
	SetLastSavedGame(GetLastSavedGame(true))
	for Index = 1, 6 do
		SetLayerIndexTitle('Load', Index, GetSaveName(Index))
		SetLayerIndexColor('Load', Index, unpack(IsSaveDataAvailable(Index) and {255, 255, 255} or {100, 100, 100}))
	end
	
	local Settings = GetDisplaySettings()
	if Settings then
		for Index = 1, table.getn(Settings) do
			SetSettingOption(Index, Settings[Index])
		end
	end
end
UpdateMenuComponent = function(TUD, TAR, Layout)
	for Key in pairs(TAR) do
		TAR[Key] = GetTextureDisplayAspectRatio(TUD[Key])
	end
	
	SetLastAspectRatio(GetDisplayAspectRatio())
	SetLastResolution(GetDisplayResolution())
	
	-- clear cache
	for Key in pairs(Layout) do
		Layout[Key] = nil
	end
end
UpdateMenuInput = function(TUD, TAR)
	-- detect keyboard or joystick
	SetNavigationInput(GetNavigationInput())
	if GetNavigationInput('Joystick') then
		CreateSystemThread(JoystickListener, 0)
	end
	
	-- create button texture
	TUD.Select, TAR.Select = CreateInputTexture('Select')
	TUD.Return, TAR.Return = CreateInputTexture('Return')
end

HalveText = function(Text, Width, Max)
	if Width <= Max then
		return Text
	end
	
	local Point = 0
	for _ = 1, math.ceil(Select(2, string.gsub(Text, '%s', '')) / 2 + 0.5) do
		Point = string.find(Text, '%s', Point + 1)
	end
	return string.sub(Text, 1, Point - 1)..'\n'..string.sub(Text, Point + 1, string.len(Text))
end
DrawButton = function(L_Texture, R_Texture, L_Description, R_Description, Middle)
	local X = Middle and 0.5 or GetFixedWidth(0.1)
	local Y = 0.9
	local Format = '~xy+scale+font+white~ '
	local Scale = GetPreference('LayoutBotScale')
	local Font = GetPreference('Font1')
	
	-- left button
	local L_Text = {Format..GetLocalization(L_Description), X, Y, Scale, Font, 0, 3}
	local Width, Height = MeasureTextInline(unpack(L_Text))
	local L_Size = Height * GetTextureDisplayAspectRatio(L_Texture)
	L_Text[2] = X + (Middle and (
		type(R_Texture) == 'userdata' and -(0.04 + GetFixedWidth(Width)) or GetFixedWidth(L_Size)
	) or L_Size)
	
	DrawTexture(L_Texture, Middle and L_Text[2] - L_Size or X, Y, L_Size, Height)
	DrawTextInline(unpack(L_Text))
	
	-- right button
	if type(R_Texture) == 'userdata' then
		local R_Text = {Format..GetLocalization(R_Description), X, Y, Scale, Font, 0, 3}
		local R_Size = Height * GetTextureDisplayAspectRatio(R_Texture)
		R_Text[2] = Middle and X + 0.04 + GetFixedWidth(R_Size) or L_Text[2] + 0.08 + R_Size
		
		DrawTexture(R_Texture, Middle and R_Text[2] - R_Size or L_Text[2] + 0.08, Y, R_Size, Height)
		DrawTextInline(unpack(R_Text))
	end
end
DrawMain = function(TUD, TAR, Layout, Layer)
	if GetPreference('ShowImage') >= 0 and GetLastAspectRatio() >= 1.4 and TUD.Image then
		DrawTexture2(TUD.Image, 1.02 - GetFixedWidth(1, TAR.Image), 0.52, 1 * TAR.Image, 1, 0, 0, 0, 0, 100)
		DrawTexture2(TUD.Image, 1.00 - GetFixedWidth(1, TAR.Image), 0.50, 1 * TAR.Image, 1, 0)
	end
	DrawTexture(TUD.Logo, GetFixedWidth(0.1), 0.1, 0.2 * TAR.Logo, 0.2)
	if Layer == 'Main' then
		DrawButton(TUD.Select, nil, 'SELECT', nil, false)
	else
		DrawButton(TUD.Return, TUD.Select, 'RETURN', 'SELECT', false)
	end
	
	if not Layout[Layer] then
		Layout[Layer] = {}
	end
	for Index, Table in ipairs(GetLayerTable(Layer)) do
		if not Layout[Layer][Index] then
			Layout[Layer][Index] = {}
			Layout[Layer][Index].Text = {'~xy+scale+font+rgb~  '..Table.Text, GetFixedWidth(0.1), 0.5, GetPreference('LayoutMidScale'), GetPreference('Font1'), Table.R, Table.G, Table.B, 0, 3}
			
			local Height = Select(2, MeasureTextInline(unpack(Layout[Layer][Index].Text))) * 1.1
			Layout[Layer][Index].PadHeight = Height + 0.01
			
			local Space = Layout[Layer][Index].PadHeight + GetPreference('LayoutSpacing')
			local Ceiling = (1 - Space * GetLayerSize(Layer)) / 2
			local Current = Space * Index - Space / 2
			Layout[Layer][Index].Text[3] = Ceiling + Current
			Layout[Layer][Index].Y = Ceiling + Current + Height / 2
		end
		
		local PadWidth = 0.2 * TAR.Logo
		if Index == GetLayerCID(Layer) then
			DrawTexture2(TUD.Ebox, GetFixedWidth(0.1) + PadWidth / 2, Layout[Layer][Index].Y, PadWidth, Layout[Layer][Index].PadHeight, 0, 250, 173, 24, 220)
		else
			DrawTexture2(TUD.Ebox, GetFixedWidth(0.1) + PadWidth / 2, Layout[Layer][Index].Y, PadWidth, Layout[Layer][Index].PadHeight, 0, 25, 25, 25, 50)
		end
		
		DrawTextInline(unpack(Layout[Layer][Index].Text))
	end
end
DrawLoad = function(TUD, TAR, Layout, Layer)
	DrawTextInline('~xy+scale+font+white~'..GetLocalization('LOAD'), 0.5, 0.075, GetPreference('LayoutTopScale'), GetPreference('Font1'), 0, 1)
	DrawButton(TUD.Return, TUD.Select, 'RETURN', 'SELECT', true)
	
	if not Layout[Layer] then
		Layout[Layer] = {}
	end
	for Index, Table in ipairs(GetLayerTable(Layer)) do
		if not Layout[Layer][Index] then
			local Format = '~xy+scale+font+rgb~'
			local Scale = GetPreference('LayoutMidScale')
			local Font = GetPreference('Font1')
			
			Layout[Layer][Index] = {}
			Layout[Layer][Index].L_Text = {Format..Table.Text[1], 0.5 - GetFixedWidth(0.50), 0.5, Scale, Font, Table.R, Table.G, Table.B, 0, 3}
			
			local Width, Height = MeasureTextInline(unpack(Layout[Layer][Index].L_Text))
			Height = Height * 2.2
			Layout[Layer][Index].PadHeight = Height + 0.01
			
			local Space = Layout[Layer][Index].PadHeight + GetPreference('LayoutSpacing')
			local Ceiling = (1 - Space * GetLayerSize(Layer)) / 2
			local Current = Space * Index - Space / 2
			Layout[Layer][Index].Y = Ceiling + Current + Height / 2
			Layout[Layer][Index].L_Text[1] = HalveText(Layout[Layer][Index].L_Text[1], Width, 0.27)
			Layout[Layer][Index].L_Text[3] = Ceiling + Current + (Width > 0.27 and 0 or Height / 4)
			
			Layout[Layer][Index].M_Text = {Format..Table.Text[2], 0.5 + GetFixedWidth(0.02), 0.5, Scale, Font, Table.R, Table.G, Table.B, 0, 3}
			Width = MeasureTextInline(unpack(Layout[Layer][Index].M_Text))
			Layout[Layer][Index].M_Text[1] = HalveText(Layout[Layer][Index].M_Text[1], Width, 0.20)
			Layout[Layer][Index].M_Text[3] = Ceiling + Current + (Width > 0.20 and 0 or Height / 4)
			
			Layout[Layer][Index].R_Text = {Format..Table.Text[3], 0.5 + GetFixedWidth(0.50), Ceiling + Current + Height / 4, Scale, Font, Table.R, Table.G, Table.B, 0, 5}
		end
		
		local PadWidth = GetFixedWidth(2.25, TAR.Ebox)
		if Index == MainMenu.Table[MainMenu.Layer].CID then
			DrawTexture2(TUD.Ebox, 0.5, Layout[Layer][Index].Y, PadWidth, Layout[Layer][Index].PadHeight, 0, 250, 173, 24, 220)
		else
			DrawTexture2(TUD.Ebox, 0.5, Layout[Layer][Index].Y, PadWidth, Layout[Layer][Index].PadHeight, 0, 25, 25, 25, 50)
		end
		
		DrawTextInline(unpack(Layout[Layer][Index].L_Text))
		DrawTextInline(unpack(Layout[Layer][Index].M_Text))
		DrawTextInline(unpack(Layout[Layer][Index].R_Text))
	end
end
DrawSettings = function(TUD, TAR, Layout, Layer)
	DrawTextInline('~xy+scale+font+white~'..GetLocalization('SETTINGS'), 0.5, 0.075, GetPreference('LayoutTopScale'), GetPreference('Font1'), 0, 1)
	if IsConfiguring() then
		DrawButton(TUD.Return, TUD.Select, 'CANCEL', 'CONFIRM', true)
	else
		DrawButton(TUD.Return, TUD.Select, 'RETURN', 'SELECT', true)
	end
	
	if not Layout[Layer] then
		Layout[Layer] = {}
	end
	for Index, Table in ipairs(GetLayerTable(Layer)) do
		if not Layout[Layer][Index] then
			Layout[Layer][Index] = {}
		end
		
		local RGBA = (IsConfiguring() and Index ~= GetLayerCID(Layer)) and {100, 100, 100, 255} or {255, 255, 255, 255}
		local HasOptionChanged = type(Layout[Layer][Index].Current) == 'nil' or Layout[Layer][Index].Current ~= Table.CurrOpt
		local SelectOrDeselect = type(Layout[Layer][Index].Configuring) == 'nil' or Layout[Layer][Index].Configuring ~= IsConfiguring()
		
		if HasOptionChanged or SelectOrDeselect then
			local Format = '~xy+scale+font+rgb+a~'
			local Scale = GetPreference('LayoutMidScale')
			Layout[Layer][Index].Option = {Format..Table.List[Table.CurrOpt], 0.5, 0.5, Scale, GetPreference('Font2'), RGBA[1], RGBA[2], RGBA[3], RGBA[4], 0, 1}
			
			local Height = Select(2, MeasureTextInline(unpack(Layout[Layer][Index].Option))) * 1.1
			Layout[Layer][Index].PadHeight = Height + 0.01
			Layout[Layer][Index].X1 = 0.5 + GetFixedWidth(Layout[Layer][Index].PadHeight)
			Layout[Layer][Index].X2 = 0.5 + GetFixedWidth(0.5 - Layout[Layer][Index].PadHeight)
			Layout[Layer][Index].Option[2] = (Layout[Layer][Index].X1 + Layout[Layer][Index].X2) / 2
			
			local Space = Layout[Layer][Index].PadHeight + GetPreference('LayoutSpacing')
			local Ceiling = (1 - Space * GetLayerSize(Layer)) / 2
			local Current = Space * Index - Space / 2
			Layout[Layer][Index].Option[3] = Ceiling + Current
			Layout[Layer][Index].Y = Ceiling + Current + Height / 2
			
			local LeftCorner = 0.5 - GetFixedWidth(0.5 - (Layout[Layer][Index].PadHeight / 2))
			Layout[Layer][Index].Label = {Format..Table.Text, LeftCorner, Ceiling + Current, Scale, GetPreference('Font1'), RGBA[1], RGBA[2], RGBA[3], RGBA[4], 0, 3}
			Layout[Layer][Index].Current = Table.CurrOpt
			Layout[Layer][Index].Configuring = IsConfiguring()
		end
		
		local PadWidth = GetFixedWidth(2.25, TAR.Ebox)
		if Index == GetLayerCID(Layer) then
			DrawTexture2(TUD.Ebox, 0.5, Layout[Layer][Index].Y, PadWidth, Layout[Layer][Index].PadHeight, 0, 250, 173, 24, 220)
		else
			DrawTexture2(TUD.Ebox, 0.5, Layout[Layer][Index].Y, PadWidth, Layout[Layer][Index].PadHeight, 0, 25, 25, 25, 50)
		end
		
		-- We don't need width for TUD.Prev and TUD.Next, they're 1:1 textures
		DrawTexture2(TUD.Prev, Layout[Layer][Index].X1, Layout[Layer][Index].Y, Layout[Layer][Index].PadHeight * TAR.Prev, Layout[Layer][Index].PadHeight, 0, unpack(RGBA))
		DrawTexture2(TUD.Next, Layout[Layer][Index].X2, Layout[Layer][Index].Y, Layout[Layer][Index].PadHeight * TAR.Next, Layout[Layer][Index].PadHeight, 0, unpack(RGBA))
		DrawTextInline(unpack(Layout[Layer][Index].Option))
		DrawTextInline(unpack(Layout[Layer][Index].Label))
	end
end

ScreenManagement = function()
	local TUD = {} -- texture userdata
	local TAR = {} -- texture aspect ratio
	local Layout = {}
	
	CreateMenuComponent(TUD, TAR)
	UpdateMenuTable()
	UpdateMenuInput(TUD, TAR)
	
	local LayerInput = RegisterLocalEventHandler('ControllersUpdated', ButtonManagement)
	local LayerFunction = {
		['Main'] = DrawMain, ['Story'] = DrawMain,
		['Load'] = DrawLoad, ['Settings'] = DrawSettings,
	}
	while true do
		if type(shared) == 'table' and HasStoryModeBeenSelected() then
			break
		end
		if IsKeyBeingPressed('T') then
			CaptureScreen('_MMO.png')
		end
		-- update TAR and Layout when the resolution has changed
		if table.concat({GetLastResolution()}) ~= table.concat({GetDisplayResolution()}) then
			UpdateMenuComponent(TUD, TAR, Layout)
		end
		
		-- ui
		DrawTexture2(TUD.Background, 0.5, 0.5, 1 * TAR.Background, 1, 0)
		LayerFunction[GetLayer()](TUD, TAR, Layout, GetLayer())
		
		Wait(0)
	end
	
	if type(shared) == 'table' then
		RemoveEventHandler(LayerInput)
	end
end
