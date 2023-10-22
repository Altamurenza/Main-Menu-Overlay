-- INTERFACE.LUA
-- AUTHOR	: ALTAMURENZA


-- # CONTROL #

ButtonManagement = function()
	if not IsConsoleActive() and not GetSaveLoad() then
		if GetLayer() == 'Main' then
			if GetKeyPress('Select') then
				local Title = GetLayerIndexValue('Main', MainMenu.Table[MainMenu.Layer].CID, 'Text')
				if Title == GetLocalization('NEWGAME')then
					SetSaveLoad(true)
					DisableController()
				elseif Title == GetLocalization('CONTINUE') then
					if IsSaveDataExist(GetSaveLastID()) then
						SetSaveLoad(true)
					end
					if not GetSaveLoad() and IsSaveDataExist(GetLastSavedGame()) and SetProxyFiles(true, GetLastSavedGame()) then
						SetSaveLoad(GetLastSavedGame())
					end
					if not GetSaveLoad() then
						for Index = 1, 6 do
							if IsSaveDataExist(Index) and SetProxyFiles(true, MainMenu.Table[MainMenu.Layer].CID) then
								SetSaveLoad(Index)
								break
							end
						end
					end
					if not GetSaveLoad() then
						PrintOutput('starting a new game..')
						SetSaveLoad(true)
					end
					DisableController()
				elseif Title == GetLocalization('LOAD') then
					SetLayer('Load')
					DisableController()
				elseif Title == GetLocalization('SETTINGS') then
					SetLayer('Settings')
					SetKeyPress(7)
				elseif Title == GetLocalization('EXIT') then
					QuitGame()
				else
					DisableController()
				end
			elseif GetKeyPress('Up') then
				MainMenu.Table[MainMenu.Layer].LID = MainMenu.Table[MainMenu.Layer].CID
				MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID - 1 < 1 and table.getn(MainMenu.Table[MainMenu.Layer]) or MainMenu.Table[MainMenu.Layer].CID - 1
				while not IsLayerIndexAvailable(MainMenu.Layer, MainMenu.Table[MainMenu.Layer].CID) do
					MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID - 1 < 1 and table.getn(MainMenu.Table[MainMenu.Layer]) or MainMenu.Table[MainMenu.Layer].CID - 1
				end
				if not IsNativeOption(GetLayerIndexValue('Main', MainMenu.Table[MainMenu.Layer].LID, 'Text')) and IsNativeOption(GetLayerIndexValue('Main', MainMenu.Table[MainMenu.Layer].CID, 'Text')) then
					SoundEffect2D('NavDwn')
					DisableController()
				else
					SetKeyPress(0)
				end
			elseif GetKeyPress('Down') then
				MainMenu.Table[MainMenu.Layer].LID = MainMenu.Table[MainMenu.Layer].CID
				MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID + 1 > table.getn(MainMenu.Table[MainMenu.Layer]) and 1 or MainMenu.Table[MainMenu.Layer].CID + 1
				while not IsLayerIndexAvailable(MainMenu.Layer, MainMenu.Table[MainMenu.Layer].CID) do
					MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID + 1 > table.getn(MainMenu.Table[MainMenu.Layer]) and 1 or MainMenu.Table[MainMenu.Layer].CID + 1
				end
				if IsNativeOption(GetLayerIndexValue('Main', MainMenu.Table[MainMenu.Layer].CID, 'Text')) then
					SetKeyPress(1)
				else
					SoundEffect2D('NavDwn')
					DisableController()
				end
			else
				DisableController()
			end
		elseif GetLayer() == 'Load' then
			if GetKeyPress('Select') then
				if IsSaveDataExist(MainMenu.Table[MainMenu.Layer].CID) then
					if SetProxyFiles(true, MainMenu.Table[MainMenu.Layer].CID) then
						SetSaveLoad(MainMenu.Table[MainMenu.Layer].CID)
					else
						PrintOutput('failed to load file: "BullyFile'..MainMenu.Table[MainMenu.Layer].CID..'"')
					end
				end
				SoundEffect2D('ButtonUp')
				DisableController()
			elseif GetKeyPress('Return') then
				SetLayer('Main')
				SoundEffect2D('ButtonDown')
				DisableController()
			elseif GetKeyPress('Up') then
				MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID - 1 < 1 and table.getn(MainMenu.Table[MainMenu.Layer]) or MainMenu.Table[MainMenu.Layer].CID - 1
				while not IsLayerIndexAvailable(MainMenu.Layer, MainMenu.Table[MainMenu.Layer].CID) do
					MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID - 1 < 1 and table.getn(MainMenu.Table[MainMenu.Layer]) or MainMenu.Table[MainMenu.Layer].CID - 1
				end
				SoundEffect2D('NavUp')
				DisableController()
			elseif GetKeyPress('Down') then
				MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID + 1 > table.getn(MainMenu.Table[MainMenu.Layer]) and 1 or MainMenu.Table[MainMenu.Layer].CID + 1
				while not IsLayerIndexAvailable(MainMenu.Layer, MainMenu.Table[MainMenu.Layer].CID) do
					MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID + 1 > table.getn(MainMenu.Table[MainMenu.Layer]) and 1 or MainMenu.Table[MainMenu.Layer].CID + 1
				end
				SoundEffect2D('NavDwn')
				DisableController()
			else
				DisableController()
			end
		elseif GetLayer() == 'Settings' then
			if IsConfiguring() then
				if GetKeyPress('Select') then
					MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].BackOpt = MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].CurrOpt
					SetConfigure(false)
					SetKeyPress(7)
				elseif GetKeyPress('Return') then
					MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].CurrOpt = MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].BackOpt
					SetConfigure(false)
					SetKeyPress(8)
				elseif GetKeyPress('Left') then
					MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].CurrOpt = MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].CurrOpt - 1 < 1 and table.getn(MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].List) or MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].CurrOpt - 1
					SetKeyPress(0)
				elseif GetKeyPress('Right') then
					MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].CurrOpt = MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].CurrOpt + 1 > table.getn(MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].List) and 1 or MainMenu.Table[MainMenu.Layer][MainMenu.Table[MainMenu.Layer].CID].CurrOpt + 1
					SetKeyPress(1)
				else
					DisableController()
				end
			else
				if GetKeyPress('Select') then
					SetConfigure(true)
					SetKeyPress(7)
				elseif GetKeyPress('Return') then
					MainMenu.Table[MainMenu.Layer].CID = 1
					SetLayer('Main')
					SetKeyPress(8)
				elseif GetKeyPress('Up') then
					MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID - 1 < 1 and table.getn(MainMenu.Table[MainMenu.Layer]) or MainMenu.Table[MainMenu.Layer].CID - 1
					SetKeyPress(1) -- this isn't a typo, it was reversed by the game itself (1 = previous)
				elseif GetKeyPress('Down') then
					MainMenu.Table[MainMenu.Layer].CID = MainMenu.Table[MainMenu.Layer].CID + 1 > table.getn(MainMenu.Table[MainMenu.Layer]) and 1 or MainMenu.Table[MainMenu.Layer].CID + 1
					SetKeyPress(0) -- this isn't a typo, it was reversed by the game itself (0 = next)
				else
					DisableController()
				end
			end
		else
			DisableController()
		end
	end
	
	-- force start the game in a hacky way
	if GetSaveLoad() then
		if MainMenu.ForceCount < 10 then
			MainMenu.ForceEntry = not MainMenu.ForceEntry
			MainMenu.ForceCount = MainMenu.ForceCount + 1
			if MainMenu.ForceEntry then
				SetStickValue(7, 0, 1)
			else
				DisableController()
			end
		end
	end
	
	-- prevent the game to detect any input while typing on the console
	if IsConsoleActive() then
		DisableController()
	end
end


-- # VISUAL #

ScreenManagement = function()
	if GetLastSavedGame(type(shared) == 'table') == -1 or not IsFileTableExist() or IsSaveDataTableEmpty() then
		SetLayerIndexTitle('Main', 1, GetLocalization('NEWGAME')) -- FTB doesn't exist and there is no save data
		SetLayerIndexColor('Main', 2, 100, 100, 100) -- disable "Load" to prevent the game from freezing
	else
		-- check the real files, so user can even load the unregistered save data
		SetSaveDataTable(IsFileTableExist() and GetSaveDataOutlines() or {})
		SetLastSavedGame(GetLastSavedGame(true))
		local Found = false
		for Index = 1, 6 do
			SetLayerIndexTitle('Load', Index, GetSaveName(Index))
			if not IsSaveDataExist(Index) then
				SetLayerIndexColor('Load', Index, 100, 100, 100)
			else
				SetLayerIndexColor('Load', Index, 255, 255, 255)
				if not Found then
					Found = true
				end
			end
		end
		if Found then
			SetLayerIndexTitle('Main', 1, GetLocalization('CONTINUE'))
			SetLayerIndexColor('Main', 2, 255, 255, 255)
		else
			SetLayerIndexTitle('Main', 1, GetLocalization('NEWGAME')) -- FTB does exist, but there is no save data yet
			SetLayerIndexColor('Main', 2, 100, 100, 100) -- disable "Load" to avoid undefined behavior
		end
	end
	local Settings = GetDisplaySettings()
	if Settings then
		for Index = 1, table.getn(Settings) do
			SetSettingOption(Index, Settings[Index])
		end
	end
	
	-- input: keyboard or joystick
	SetNavigationInput(GetNavigationInput())
	local Listener = nil
	if GetNavigationInput('Joystick') then
		Listener = CreateSystemThread(JoystickListener)
	end
	
	local T = {} -- texture userdata
	local R = {} -- texture aspect ratio
	
	-- create basic UI texture
	T.Background = CreateTexture('Graphics/Base/Background.png')
	R.Background = GetTextureDisplayAspectRatio(T.Background)
	T.Ebox = CreateTexture('Graphics/Base/Ebox.png')
	R.Ebox = GetTextureDisplayAspectRatio(T.Ebox)
	T.Logo = CreateTexture('Graphics/Base/Logo.png')
	R.Logo = GetTextureDisplayAspectRatio(T.Logo)
	T.Prev = CreateTexture('Graphics/Base/Prev.png')
	R.Prev = GetTextureDisplayAspectRatio(T.Prev)
	T.Next = CreateTexture('Graphics/Base/Next.png')
	R.Next = GetTextureDisplayAspectRatio(T.Next)
	
	-- create button texture
	T.Return, R.Return = CreateInputTexture('Select')
	T.Space, R.Space = CreateInputTexture('Return')
	
	-- create image from the relative path or real path
	if GetPreference('ShowImage') >= 0 then
		local Option = GetPreference('ShowImage')
		if Option >= 0 and Option <= 6 then
			if Option == 0 then
				math.randomseed(GetSystemTimer())
			end
			T.Image = CreateTexture('Graphics/Image/Image0'..(Option == 0 and math.random(1, 6) or Option)..'.png')
			R.Image = GetTextureDisplayAspectRatio(T.Image)
		end
	end
	
	-- create protocol for controls
	local Control = RegisterLocalEventHandler('ControllersUpdated', ButtonManagement)
	
	-- cache
	local Layout = {}
	local Button = {}
	
	while true do
		if type(shared) == 'table' and HasStoryModeBeenSelected() then
			break
		end
		
		-- adjust aspect ratio
		if table.concat({GetLastResolution()}) ~= table.concat({GetDisplayResolution()}) then
			for Key in pairs(R) do
				R[Key] = GetTextureDisplayAspectRatio(T[Key])
			end
			
			SetLastAspectRatio(GetDisplayAspectRatio())
			SetLastResolution(GetDisplayResolution())
			
			-- clear cache
			for Key in pairs(Layout) do
				Layout[Key] = nil
			end
			for Key in pairs(Button) do
				Button[Key] = nil
			end
		end
		
		-- 75% of the text is cached, it may look confusing, but it is the best option for a long-term use
		DrawTexture2(T.Background, 0.5, 0.5, 1 * R.Background, 1, 0)
		if GetLayer() == 'Main' then
			if GetPreference('ShowImage') >= 0 and GetLastAspectRatio() >= 1.4 and T.Image then
				DrawTexture2(T.Image, 1.02 - GetFixedWidth(1, R.Image), 0.52, 1 * R.Image, 1, 0, 0, 0, 0, 100)
				DrawTexture2(T.Image, 1.00 - GetFixedWidth(1, R.Image), 0.50, 1 * R.Image, 1, 0)
			end
			DrawTexture(T.Logo, GetFixedWidth(0.1), 0.1, 0.2 * R.Logo, 0.2)
			
			if not Button['Main'] then
				Button['Main'] = {}
				Button['Main'].X = GetFixedWidth(0.1)
				Button['Main'].Y = 0.9
				Button['Main'].Text = {'~xy+scale+font+white~ '..GetLocalization('SELECT'), Button['Main'].X, Button['Main'].Y, GetPreference('MainBotScale'), GetPreference('Font1'), 0, 3}
				Button['Main'].Width, Button['Main'].Height = MeasureTextInline(unpack(Button['Main'].Text))
				Button['Main'].Text[2] = Button['Main'].X + (Button['Main'].Height * R.Return)
			end
			DrawTexture(T.Return, Button['Main'].X, Button['Main'].Y, Button['Main'].Height * R.Return, Button['Main'].Height)
			DrawTextInline(unpack(Button['Main'].Text))
			
			for Index, Table in ipairs(MainMenu.Table['Main']) do
				if not Layout['Main'] then
					Layout['Main'] = {}
				end
				if not Layout['Main'][Index] then
					Layout['Main'][Index] = {}
					Layout['Main'][Index].Text = {'~xy+scale+font+rgb~  '..Table.Text, GetFixedWidth(0.1), 0.5, GetPreference('MainMidScale'), GetPreference('Font1'), Table.R, Table.G, Table.B, 0, 3}
					Layout['Main'][Index].Width, Layout['Main'][Index].Height = MeasureTextInline(unpack(Layout['Main'][Index].Text))
					Layout['Main'][Index].Size = Layout['Main'][Index].Height * 1.1
					Layout['Main'][Index].TopY = ((1 - (Layout['Main'][Index].Size + GetPreference('MainSpacing')) * table.getn(MainMenu.Table['Main'])) / 2) + ((Layout['Main'][Index].Size + GetPreference('MainSpacing')) * Index) - ((Layout['Main'][Index].Size + GetPreference('MainSpacing')) / 2)
					Layout['Main'][Index].MidY = Layout['Main'][Index].TopY + (Layout['Main'][Index].Height / 2)
					Layout['Main'][Index].Text[3] = Layout['Main'][Index].TopY
				end
				
				if Index == MainMenu.Table[MainMenu.Layer].CID then
					DrawTexture2(T.Ebox, GetFixedWidth(0.1) + ((0.2 * R.Logo) / 2), Layout['Main'][Index].MidY, 0.2 * R.Logo, Layout['Main'][Index].Size + 0.010, 0, 250, 173, 24, 220)
				else
					DrawTexture2(T.Ebox, GetFixedWidth(0.1) + ((0.2 * R.Logo) / 2), Layout['Main'][Index].MidY, 0.2 * R.Logo, Layout['Main'][Index].Size + 0.010, 0, 25, 25, 25, 50)
				end
				DrawTextInline(unpack(Layout['Main'][Index].Text))
			end
		elseif GetLayer() == 'Load' then
			DrawTextInline('~xy+scale+font+white~'..GetLocalization('LOAD'), 0.5, 0.075, GetPreference('LoadTopScale'), GetPreference('Font1'), 0, 1)
			
			if not Button['Load'] then
				Button['Load'] = {}
				Button['Load'].X = 0.5
				Button['Load'].Y = 0.9
				Button['Load'].L_Text = {'~xy+scale+font+white~ '..GetLocalization('RETURN'), Button['Load'].X, Button['Load'].Y, GetPreference('LoadBotScale'), GetPreference('Font1'), 0, 3}
				Button['Load'].R_Text = {'~xy+scale+font+white~ '..GetLocalization('SELECT'), Button['Load'].X, Button['Load'].Y, GetPreference('LoadBotScale'), GetPreference('Font1'), 0, 3}
				Button['Load'].Width, Button['Load'].Height = MeasureTextInline(unpack(Button['Load'].L_Text))
				Button['Load'].L_Text[2] = (Button['Load'].X - 0.04) - GetFixedWidth(Button['Load'].Width)
				Button['Load'].R_Text[2] = (Button['Load'].X + 0.04) + GetFixedWidth(Button['Load'].Height * R.Return)
			end
			DrawTexture(T.Space, Button['Load'].L_Text[2] - (Button['Load'].Height * R.Space), Button['Load'].Y, Button['Load'].Height * R.Space, Button['Load'].Height)
			DrawTextInline(unpack(Button['Load'].L_Text))
			DrawTexture(T.Return, Button['Load'].R_Text[2] - (Button['Load'].Height * R.Return), Button['Load'].Y, Button['Load'].Height * R.Return, Button['Load'].Height)
			DrawTextInline(unpack(Button['Load'].R_Text))
			
			for Index, Table in ipairs(MainMenu.Table['Load']) do
				if not Layout['Load'] then
					Layout['Load'] = {}
				end
				if not Layout['Load'][Index] then
					Layout['Load'][Index] = {}
					Layout['Load'][Index].L_Text = {'~xy+scale+font+rgb~'..Table.Text[1], 0.5 - GetFixedWidth(0.50), 0.5, GetPreference('LoadMidScale'), GetPreference('Font1'), Table.R, Table.G, Table.B, 0, 3}
					Layout['Load'][Index].M_Text = {'~xy+scale+font+rgb~'..Table.Text[2], 0.5 + GetFixedWidth(0.02), 0.5, GetPreference('LoadMidScale'), GetPreference('Font1'), Table.R, Table.G, Table.B, 0, 3}
					Layout['Load'][Index].R_Text = {'~xy+scale+font+rgb~'..Table.Text[3], 0.5 + GetFixedWidth(0.50), 0.5, GetPreference('LoadMidScale'), GetPreference('Font1'), Table.R, Table.G, Table.B, 0, 5}
					Layout['Load'][Index].L_Width, Layout['Load'][Index].L_Height = MeasureTextInline(unpack(Layout['Load'][Index].L_Text))
					Layout['Load'][Index].M_Width, Layout['Load'][Index].M_Height = MeasureTextInline(unpack(Layout['Load'][Index].M_Text))
					Layout['Load'][Index].Size = Layout['Load'][Index].L_Height * 2.2
					Layout['Load'][Index].TopY = ((1 - (Layout['Load'][Index].Size + GetPreference('LoadSpacing')) * table.getn(MainMenu.Table['Load'])) / 2) + ((Layout['Load'][Index].Size + GetPreference('LoadSpacing')) * Index) - ((Layout['Load'][Index].Size + GetPreference('LoadSpacing')) / 2)
					Layout['Load'][Index].MidY = Layout['Load'][Index].TopY + (Layout['Load'][Index].L_Height / 2)
					Layout['Load'][Index].L_Text[3] = Layout['Load'][Index].TopY
					Layout['Load'][Index].M_Text[3] = Layout['Load'][Index].TopY
					Layout['Load'][Index].R_Text[3] = Layout['Load'][Index].TopY
					
					if Layout['Load'][Index].L_Width > 0.27 and string.find(Layout['Load'][Index].L_Text[1], '%s') then
						local Old = Layout['Load'][Index].L_Text[1]
						Layout['Load'][Index].L_Text[1] = string.gsub(Old, '([^%s]*)%s([^%s]*)$', '%1\n%2')
						if MeasureTextInline(unpack(Layout['Load'][Index].L_Text)) > 0.27 then
							Layout['Load'][Index].L_Text[1] = string.gsub(Old, ':%s', ':\n')
						end
						Layout['Load'][Index].L_Text[3] = Layout['Load'][Index].TopY - (Layout['Load'][Index].L_Height / 2)
					end
					if Layout['Load'][Index].M_Width > 0.20 and string.find(Layout['Load'][Index].M_Text[1], '%s') then
						local Old = Layout['Load'][Index].M_Text[1]
						Layout['Load'][Index].M_Text[1] = string.gsub(Old, '([^%s]*)%s([^%s]*)$', '%1\n%2')
						if MeasureTextInline(unpack(Layout['Load'][Index].M_Text)) > 0.20 then
							local Point = 0
							for _ = 1, math.ceil(Select(2, string.gsub(Old, '%s', '')) / 2 + 0.5) do
								Point = string.find(Old, '%s', Point + 1)
							end
							Layout['Load'][Index].M_Text[1] = string.sub(Old, 1, Point - 1)..'\n'..string.sub(Old, Point + 1, string.len(Old))
						end
						Layout['Load'][Index].M_Text[3] = Layout['Load'][Index].TopY - (Layout['Load'][Index].M_Height / 2)
					end
				end
				
				if Index == MainMenu.Table[MainMenu.Layer].CID then
					DrawTexture2(T.Ebox, 0.5, Layout['Load'][Index].MidY, GetFixedWidth(2.25, R.Ebox), Layout['Load'][Index].Size, 0, 250, 173, 24, 220)
				else
					DrawTexture2(T.Ebox, 0.5, Layout['Load'][Index].MidY, GetFixedWidth(2.25, R.Ebox), Layout['Load'][Index].Size, 0, 25, 25, 25, 50)
				end
				DrawTextInline(unpack(Layout['Load'][Index].L_Text))
				DrawTextInline(unpack(Layout['Load'][Index].M_Text))
				DrawTextInline(unpack(Layout['Load'][Index].R_Text))
			end
		elseif GetLayer() == 'Settings' then
			DrawTextInline('~xy+scale+font+white~'..GetLocalization('SETTINGS'), 0.5, 0.075, GetPreference('SettingTopScale'), GetPreference('Font1'), 0, 1)
			
			if not Button['Settings'] then
				Button['Settings'] = {}
				Button['Settings'].X = 0.5
				Button['Settings'].Y = 0.9
				Button['Settings'].L_Text = {'', Button['Settings'].X, Button['Settings'].Y, GetPreference('SettingBotScale'), GetPreference('Font1'), 0, 3}
				Button['Settings'].R_Text = {'', Button['Settings'].X, Button['Settings'].Y, GetPreference('SettingBotScale'), GetPreference('Font1'), 0, 3}
			end
			if type(Button['Settings'].Configure) == 'nil' or Button['Settings'].Configure ~= IsConfiguring() then
				Button['Settings'].L_Text[1] = '~xy+scale+font+white~ '..GetLocalization(IsConfiguring() and 'CANCEL' or 'RETURN')
				Button['Settings'].R_Text[1] = '~xy+scale+font+white~ '..GetLocalization(IsConfiguring() and 'CONFIRM' or 'SELECT')
				Button['Settings'].Width, Button['Settings'].Height = MeasureTextInline(unpack(Button['Settings'].L_Text))
				Button['Settings'].L_Text[2] = (Button['Settings'].X - 0.04) - GetFixedWidth(Button['Settings'].Width)
				Button['Settings'].R_Text[2] = (Button['Settings'].X + 0.04) + GetFixedWidth(Button['Settings'].Height * R.Return)
				Button['Settings'].Configure = IsConfiguring()
			end
			DrawTexture(T.Space, Button['Settings'].L_Text[2] - (Button['Settings'].Height * R.Space), Button['Settings'].Y, Button['Settings'].Height * R.Space, Button['Settings'].Height)
			DrawTextInline(unpack(Button['Settings'].L_Text))
			DrawTexture(T.Return, Button['Settings'].R_Text[2] - (Button['Settings'].Height * R.Return), Button['Settings'].Y, Button['Settings'].Height * R.Return, Button['Settings'].Height)
			DrawTextInline(unpack(Button['Settings'].R_Text))
			
			for Index, Table in ipairs(MainMenu.Table['Settings']) do
				if not Layout['Settings'] then
					Layout['Settings'] = {}
				end
				if not Layout['Settings'][Index] then
					Layout['Settings'][Index] = {}
				end
				if not Layout['Settings'][Index].Option or Layout['Settings'][Index].Option ~= Table.CurrOpt then
					Layout['Settings'][Index].Text = {'~xy+scale+font+rgb~'..Table.List[Table.CurrOpt], 0.5, 0.5, GetPreference('SettingMidScale'), GetPreference('Font2'), 255, 255, 255, 0, 1}
					Layout['Settings'][Index].Width, Layout['Settings'][Index].Height = MeasureTextInline(unpack(Layout['Settings'][Index].Text))
					Layout['Settings'][Index].Size = Layout['Settings'][Index].Height * 1.1
					Layout['Settings'][Index].X1 = 0.5 + GetFixedWidth(Layout['Settings'][Index].Size)
					Layout['Settings'][Index].X2 = 0.5 + GetFixedWidth(0.5 - Layout['Settings'][Index].Size)
					Layout['Settings'][Index].TopY = ((1 - (Layout['Settings'][Index].Size + GetPreference('SettingSpacing')) * table.getn(MainMenu.Table['Settings'])) / 2) + ((Layout['Settings'][Index].Size + GetPreference('SettingSpacing')) * Index) - ((Layout['Settings'][Index].Size + GetPreference('SettingSpacing')) / 2)
					Layout['Settings'][Index].MidY = Layout['Settings'][Index].TopY + (Layout['Settings'][Index].Height / 2)
					Layout['Settings'][Index].Text[2] = (Layout['Settings'][Index].X1 + Layout['Settings'][Index].X2) / 2
					Layout['Settings'][Index].Text[3] = Layout['Settings'][Index].TopY
					Layout['Settings'][Index].RGB = {255, 255, 255}
					Layout['Settings'][Index].Option = Table.CurrOpt
				end
				if IsConfiguring() then
					if (Layout['Settings'][MainMenu.Table[MainMenu.Layer].CID - 1] and Layout['Settings'][MainMenu.Table[MainMenu.Layer].CID - 1].RGB[1] == 255) or (Layout['Settings'][MainMenu.Table[MainMenu.Layer].CID + 1] and Layout['Settings'][MainMenu.Table[MainMenu.Layer].CID + 1].RGB[1] == 255) then
						for Option = 1, table.getn(MainMenu.Table['Settings']) do
							if Option ~= MainMenu.Table[MainMenu.Layer].CID then
								Layout['Settings'][Option].RGB = {100, 100, 100}
								Layout['Settings'][Option].Text[6] = Layout['Settings'][Option].RGB[1]
								Layout['Settings'][Option].Text[7] = Layout['Settings'][Option].RGB[2]
								Layout['Settings'][Option].Text[8] = Layout['Settings'][Option].RGB[3]
							end
						end
					end
				else
					if (Layout['Settings'][MainMenu.Table[MainMenu.Layer].CID - 1] and Layout['Settings'][MainMenu.Table[MainMenu.Layer].CID - 1].RGB[1] == 100) or (Layout['Settings'][MainMenu.Table[MainMenu.Layer].CID + 1] and Layout['Settings'][MainMenu.Table[MainMenu.Layer].CID + 1].RGB[1] == 100) then
						for Option = 1, table.getn(MainMenu.Table['Settings']) do
							if Option ~= MainMenu.Table[MainMenu.Layer].CID then
								Layout['Settings'][Option].RGB = {255, 255, 255}
								Layout['Settings'][Option].Text[6] = Layout['Settings'][Option].RGB[1]
								Layout['Settings'][Option].Text[7] = Layout['Settings'][Option].RGB[2]
								Layout['Settings'][Option].Text[8] = Layout['Settings'][Option].RGB[3]
							end
						end
					end
				end
				
				if Index == MainMenu.Table[MainMenu.Layer].CID then
					DrawTexture2(T.Ebox, 0.5, Layout['Settings'][Index].MidY, GetFixedWidth(2.25, R.Ebox), Layout['Settings'][Index].Size + 0.010, 0, 250, 173, 24, 220)
				else
					DrawTexture2(T.Ebox, 0.5, Layout['Settings'][Index].MidY, GetFixedWidth(2.25, R.Ebox), Layout['Settings'][Index].Size + 0.010, 0, 25, 25, 25, 50)
				end
				DrawTexture2(T.Prev, Layout['Settings'][Index].X1, Layout['Settings'][Index].MidY, Layout['Settings'][Index].Size * R.Prev, Layout['Settings'][Index].Size, 0, Layout['Settings'][Index].RGB[1], Layout['Settings'][Index].RGB[2], Layout['Settings'][Index].RGB[3], 255)
				DrawTexture2(T.Next, Layout['Settings'][Index].X2, Layout['Settings'][Index].MidY, Layout['Settings'][Index].Size * R.Next, Layout['Settings'][Index].Size, 0, Layout['Settings'][Index].RGB[1], Layout['Settings'][Index].RGB[2], Layout['Settings'][Index].RGB[3], 255)
				DrawTextInline('~xy+scale+font+rgb~'..Table.Text, 0.5 - GetFixedWidth(0.5 - (Layout['Settings'][Index].Size / 2)), Layout['Settings'][Index].TopY, GetPreference('SettingMidScale'), GetPreference('Font1'), Layout['Settings'][Index].RGB[1], Layout['Settings'][Index].RGB[2], Layout['Settings'][Index].RGB[3], 0, 3)
				DrawTextInline(unpack(Layout['Settings'][Index].Text))
			end
		end
		
		Wait(0)
	end
	
	if type(shared) == 'table' then
		RemoveEventHandler(Control)
		
		if type(Listener) == 'thread' then
			TerminateThread(Listener)
		end
	end
end
