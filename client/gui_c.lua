------------------------------------
------------------------------------
------------------------------------
---- DONT TOUCH ANY OF THIS IF YOU DON'T KNOW WHAT YOU ARE DOING
---- THESE ARE **NOT** CONFIG VALUES, USE THE CONVARS IF YOU WANT TO CHANGE SOMETHING
----
----
---- If you are a developer and want to change something, consider writing a plugin instead:
---- https://easyadmin.readthedocs.io/en/latest/plugins/
----
------------------------------------
------------------------------------
isAdmin = false
showLicenses = false
RedM = false

settings = {
	button = "none",
	forceShowGUIButtons = false,
}


-- generate "slap" table once
local SlapAmount = {}
for i = 1, 20 do
	table.insert(SlapAmount, i)
end

function handleOrientation(orientation)
	if orientation == "right" then
		return 1300 - menuWidth
	elseif orientation == "middle" then
		return 730
	elseif orientation == "left" then
		return 0
	end
end

playlist = nil

function CheckDutyStatus()
	-- Use the global IsDutySystemEnabled function for consistency
	local isDutySystemEnabled = IsDutySystemEnabled()

	if _menuPool and _menuPool:IsAnyMenuOpen() then
		-- Only check duty status if the duty system is enabled
		if isDutySystemEnabled and LocalPlayer.state["easyadmin-ox:clockedIn"] ~= 'yes' then
			_menuPool:CloseAllMenus()
			lib.notify({
				title = "Menu Disabled",
				description = "EasyAdmin has closed due to clocking out.",
				type = "info"
			})
		end
	end
end

RegisterCommand('easyadmin', function(source, args)
	CreateThread(function()
		if not isAdmin == true then
			TriggerServerEvent("EasyAdmin:amiadmin")
			local waitTime = 0

			repeat
				Wait(10)
				waitTime = waitTime + 1
			until (isAdmin or waitTime == 1000)
			if not isAdmin then
				return
			end
		end

		if not mainMenu or not mainMenu:Visible() then
			if ((RedM and settings.infinity) or not RedM) and isAdmin then
				playerlist = nil
				if DoesPlayerHavePermissionForCategory(-1, "player") then
					TriggerServerEvent("EasyAdmin:GetInfinityPlayerList")
					repeat
						Wait(10)
					until playerlist
				else
					playerlist = {}
				end
			end			if strings and isAdmin then
				-- Use the global IsDutySystemEnabled function for consistency
				local isDutySystemEnabled = IsDutySystemEnabled()
				print("Duty system enabled: " .. tostring(isDutySystemEnabled))
				print("Player clocked in: " .. tostring(LocalPlayer.state["easyadmin-ox:clockedIn"]))

				-- Only verify clock-in status if duty system is enabled
				if not isDutySystemEnabled or LocalPlayer.state["easyadmin-ox:clockedIn"] == 'yes' then
					banLength = {}

					if permissions["player.ban.permanent"] then
						table.insert(banLength, { label = GetLocalisedText("permanent"), time = 10444633200 })
					end

					if permissions["player.ban.temporary"] then
						table.insert(banLength, { label = "6 " .. GetLocalisedText("hours"), time = 21600 })
						table.insert(banLength, { label = "12 " .. GetLocalisedText("hours"), time = 43200 })
						table.insert(banLength, { label = "1 " .. GetLocalisedText("day"), time = 86400 })
						table.insert(banLength, { label = "3 " .. GetLocalisedText("days"), time = 259200 })
						table.insert(banLength, { label = "1 " .. GetLocalisedText("week"), time = 518400 })
						table.insert(banLength, { label = "2 " .. GetLocalisedText("weeks"), time = 1123200 })
						table.insert(banLength, { label = "1 " .. GetLocalisedText("month"), time = 2678400 })
						table.insert(banLength, { label = "1 " .. GetLocalisedText("year"), time = 31536000 })
						table.insert(banLength, { label = GetLocalisedText("customtime"), time = -1 })
					end
					GenerateMenu()

					if (args[1]) then
						local id = tonumber(args[1])
						if (reportMenus[id]) then
							reportMenus[id]:Visible(true)
							return
						elseif playerMenus[args[1]] then
							local menu = playerMenus[args[1]]
							menu.generate(menu.menu)
							menu.menu:Visible(true)
							return
						end
					end
					SendNUIMessage({ action = "speak", text = "EasyAdmin" })
					mainMenu:Visible(true)

					if not _menuPool then
						_menuPool = NativeUI.CreatePool()
					end

					CreateThread(function()
						while _menuPool and _menuPool:IsAnyMenuOpen() do
							CheckDutyStatus()
							Wait(500)
						end
					end)
				else
					lib.notify({
						title = "Error",
						description = "You are not clocked in! Please use /clockin first.",
						type = "error"
					})
					TriggerServerEvent("EasyAdmin:amiadmin")
					return
				end
			end
		else
			mainMenu:Visible(false)
			_menuPool:Remove()
			ExecutePluginsFunction("menuRemoved")
			collectgarbage()
		end
	end)
end, false)


RegisterCommand('ea', function(source, args)
	ExecuteCommand('easyadmin ' .. table.concat(args, " "))
end)

Citizen.CreateThread(function()
	if CompendiumHorseObserved then -- https://www.youtube.com/watch?v=r7qovpFAGrQ
		RedM = true
		settings.button = "PhotoModePc"
	end
	if not RedM then
		RegisterKeyMapping('easyadmin', 'Open EasyAdmin', 'keyboard', "")
	end
	repeat
		Wait(100)
	until NativeUI

	TriggerServerEvent("EasyAdmin:amiadmin")
	TriggerServerEvent("EasyAdmin:requestBanlist")
	TriggerServerEvent("EasyAdmin:requestCachedPlayers")

	if not GetResourceKvpString("ea_menuorientation") then
		SetResourceKvp("ea_menuorientation", "middle")
		SetResourceKvpInt("ea_menuwidth", 0)
		menuWidth = 0
		menuOrientation = handleOrientation("middle")
	else
		menuWidth = GetResourceKvpInt("ea_menuwidth")
		menuOrientation = handleOrientation(GetResourceKvpString("ea_menuorientation"))
	end
	if not GetResourceKvpInt("ea_tts") then
		SetResourceKvpInt("ea_tts", 0)
		SetResourceKvpInt("ea_ttsspeed", 4)
	else
		if GetResourceKvpInt("ea_ttsspeed") == 0 then
			SetResourceKvpInt("ea_ttsspeed", 4)
		end
		if GetResourceKvpInt("ea_tts") == 1 then
			SendNUIMessage({
				action = "toggle_speak",
				enabled = true,
				rate = GetResourceKvpInt("ea_ttsspeed") or 4
			})
		end
	end

	local subtitle = "~b~Admin Menu"
	if settings.updateAvailable then
		subtitle = "~g~UPDATE " .. settings.updateAvailable .. " AVAILABLE!"
	elseif settings.alternativeTitle then
		-- if you remove this code then you're a killjoy, can't we have nice things? just once? it's not like this changes the whole admin menu or how it behaves, its a single subtitle.
		subtitle = settings.alternativeTitle
	end

	while true do
		if _menuPool then
			if not _menuPool:IsAnyMenuOpen() then
				_menuPool:Remove()
				ExecutePluginsFunction("menuRemoved")
				_menuPool = nil
				collectgarbage()
			elseif _menuPool:IsAnyMenuOpen() then
				_menuPool:ProcessMenus()
			end
		end

		if RedM then -- since RedM doesn't have the new key bindings yet, watch for button press actively.
			if (RedM and IsControlJustReleased(0, Controls[settings.button])) then
				ExecuteCommand("easyadmin")
			end
		end

		Citizen.Wait(1)
	end
end)

IsSpectating = false

function DrawPlayerInfo(target)
	drawTarget = target
	drawServerId = GetPlayerServerId(target)
	drawInfo = true
	IsSpectating = true
	DrawPlayerInfoLoop()
end

function StopDrawPlayerInfo()
	drawInfo = false
	drawTarget = 0
	drawServerId = 0
	IsSpectating = false
end

local banlistPage = 1
playerMenus = {}
cachedMenus = {}
reportMenus = {}
local easterChance = math.random(0, 101)
local overrideEgg, currentEgg



-- note: we dont support dui banner and dui logo at the same time yet.
local eastereggs = {
	pipes = {
		duibanner = "http://legacy.furfag.de/eggs/pipes",
		banner = false,
		logo = "dependencies/images/banner-logo.png",
	},
	nom = {
		duilogo = "http://legacy.furfag.de/eggs/nom",
		banner = "dependencies/images/banner-gradient.png",
		logo = false,
	},
	pride = {
		banner = "dependencies/images/banner-gradient.png",
		logo = "dependencies/images/pride.png",
	},
	ukraine = {
		banner = "dependencies/images/banner-gradient.png",
		logo = "dependencies/images/ukraine.png"
	},
	EOA = {
		banner = "dependencies/images/banner-eoa.png",
		logo = "dependencies/images/logo-eoa.png"
	},
	HardAdmin = {
		banner = "dependencies/images/banner-hardadmin.png",
		logo = "dependencies/images/logo-hardadmin.png"
	}
}

function generateTextures()
	if not RedM and not txd or (overrideEgg ~= currentEgg) then
		if dui then
			DestroyDui(dui)
			dui = nil
		end
		txd = CreateRuntimeTxd("easyadmin")
		CreateRuntimeTextureFromImage(txd, 'badge_dev', 'dependencies/images/pl_badge_dev.png')
		CreateRuntimeTextureFromImage(txd, 'badge_contrib', 'dependencies/images/pl_badge_contr.png')

		if ((overrideEgg == nil) and easterChance == 100) or (overrideEgg or overrideEgg == false) then
			local chance = overrideEgg
			if ((overrideEgg == nil) and easterChance == 100) then
				-- dirty function to select random easter egg
				local tbl = {}
				for k, v in pairs(eastereggs) do
					table.insert(tbl, k)
				end

				chance = tbl[math.random(#tbl)]
			end

			local egg = eastereggs[chance]
			if egg then
				if egg.duibanner then
					dui = CreateDui(egg.duibanner, 512, 128)
					local duihandle = GetDuiHandle(dui)
					CreateRuntimeTextureFromDuiHandle(txd, 'banner-gradient', duihandle)
					Wait(800)
				elseif egg.duilogo then
					dui = CreateDui(egg.duilogo, 512, 128)
					local duihandle = GetDuiHandle(dui)
					CreateRuntimeTextureFromDuiHandle(txd, 'logo', duihandle)
					Wait(800)
				end
				if egg.logo then
					CreateRuntimeTextureFromImage(txd, 'logo', egg.logo)
				end
				if egg.banner then
					CreateRuntimeTextureFromImage(txd, 'banner-gradient', egg.banner)
				end
				currentEgg = chance
			else
				CreateRuntimeTextureFromImage(txd, 'logo', 'dependencies/images/banner-logo.png')
				CreateRuntimeTextureFromImage(txd, 'banner-gradient', 'dependencies/images/banner-gradient.png')
				currentEgg = false
			end
		else
			if settings.alternativeLogo then
				CreateRuntimeTextureFromImage(txd, 'logo', 'dependencies/images/' .. settings.alternativeLogo .. '.png')
			else
				CreateRuntimeTextureFromImage(txd, 'logo', 'dependencies/images/banner-logo.png')
			end
			if settings.alternativeBanner then
				CreateRuntimeTextureFromImage(txd, 'banner-gradient',
					'dependencies/images/' .. settings.alternativeBanner .. '.png')
			else
				CreateRuntimeTextureFromImage(txd, 'banner-gradient', 'dependencies/images/banner-gradient.png')
			end
			currentEgg = nil
		end
	end
end

function ExecutePluginsFunction(funcName, ...)
	for i, plugin in pairs(plugins) do
		if plugin.functions[funcName] then
			PrintDebugMessage("Processing Plugin: " .. plugin.name, 4)
			local ran, errorMsg = pcall(plugin.functions[funcName], ...)
			if not ran then
				PrintDebugMessage("Error in plugin " .. plugin.name .. ": \n" .. errorMsg, 1)
			end
		end
	end
end

function GenerateMenu()
	generateTextures()
	TriggerServerEvent("EasyAdmin:requestCachedPlayers")
	if _menuPool then
		_menuPool:Remove()
		ExecutePluginsFunction("menuRemoved")
		collectgarbage()
	end
	_menuPool = NativeUI.CreatePool()
	collectgarbage()
	if not GetResourceKvpString("ea_menuorientation") then
		SetResourceKvp("ea_menuorientation", "middle")
		SetResourceKvpInt("ea_menuwidth", 0)
		menuWidth = 0
		menuOrientation = handleOrientation("middle")
	else
		menuWidth = GetResourceKvpInt("ea_menuwidth")
		menuOrientation = handleOrientation(GetResourceKvpString("ea_menuorientation"))
	end
	maxRightTextWidth = math.floor((24 + (menuWidth * 0.12)))
	local subtitle = "Admin Menu"
	if settings.updateAvailable then
		subtitle = "~g~UPDATE " .. settings.updateAvailable .. " AVAILABLE!"
	elseif settings.alternativeTitle then
		subtitle = settings.alternativeTitle
	end
	mainMenu = NativeUI.CreateMenu(RedM and "EasyAdmin" or "", subtitle, menuOrientation, 0, "easyadmin",
		"banner-gradient", "logo")
	_menuPool:Add(mainMenu)

	_menuPool:ControlDisablingEnabled(false)
	_menuPool:MouseControlsEnabled(false)


	if DoesPlayerHavePermissionForCategory(-1, "player") then
		playermanagement = _menuPool:AddSubMenu(mainMenu, GetLocalisedText("playermanagement"), "", true, true)
		playermanagement:SetMenuWidthOffset(menuWidth)
	end

	if DoesPlayerHavePermissionForCategory(-1, "server") or permissions["player.ban.view"] then
		servermanagement = _menuPool:AddSubMenu(mainMenu, GetLocalisedText("servermanagement"), "", true, true)
		servermanagement:SetMenuWidthOffset(menuWidth)
	end

	settingsMenu = _menuPool:AddSubMenu(mainMenu, GetLocalisedText("settings"), "", true, true)

	mainMenu:SetMenuWidthOffset(menuWidth)
	settingsMenu:SetMenuWidthOffset(menuWidth)

	-- util stuff
	players = {}
	local localplayers = {}

	if (RedM and settings.infinity) or not RedM then
		local localplayers = playerlist
		local temp = {}
		--table.sort(localplayers)
		for i, thePlayer in pairs(localplayers) do
			table.insert(temp, thePlayer.id)
		end
		table.sort(temp)
		for i, thePlayerId in pairs(temp) do
			for _, thePlayer in pairs(localplayers) do
				if thePlayerId == thePlayer.id then
					players[i] = thePlayer
				end
			end
		end
		temp = nil
	else
		for i = 0, 128 do
			if NetworkIsPlayerActive(i) then
				table.insert(localplayers, GetPlayerServerId(i))
			end
		end
		table.sort(localplayers)
		for i, thePlayer in ipairs(localplayers) do
			table.insert(players, GetPlayerFromServerId(thePlayer))
		end
	end

	ExecutePluginsFunction("mainMenu")

	if DoesPlayerHavePermissionForCategory(-1, "player") then
		local userSearch = NativeUI.CreateItem(GetLocalisedText("searchuser"), GetLocalisedText("searchuserguide"))
		playermanagement:AddItem(userSearch)
		userSearch.Activated = function(ParentMenu, SelectedItem)
			local result = displayKeyboardInput("FMMC_KEY_TIP8", "", 60)

			if result and result ~= "" then
				local found = false
				local foundbyid = playerMenus[result] or false
				local temp = {}
				if foundbyid then
					found = true
					table.insert(temp, { id = foundbyid.id, name = foundbyid.name, menu = foundbyid.menu })
				end
				for k, v in pairs(playerMenus) do
					if string.find(string.lower(v.name), string.lower(result)) then
						found = true
						table.insert(temp, { id = v.id, name = v.name, menu = v.menu })
					end
				end
				for k, v in pairs(cachedMenus) do
					if string.find(string.lower(v.name), string.lower(result)) then
						found = true
						table.insert(temp, { id = v.id, name = v.name, menu = v.menu, cached = true })
					end
				end

				if found and (#temp > 1) then
					local searchsubtitle = "Found " .. tostring(#temp) .. " results!"
					ttsSpeechText(searchsubtitle)
					local resultMenu = NativeUI.CreateMenu("Search Results", searchsubtitle, menuOrientation, 0,
						"easyadmin", "banner-gradient", "logo")
					_menuPool:Add(resultMenu)
					_menuPool:ControlDisablingEnabled(false)
					_menuPool:MouseControlsEnabled(false)

					for i, thePlayer in ipairs(temp) do
						local title = "[" .. thePlayer.id .. "] " .. thePlayer.name, ""
						if thePlayer.cached then
							title = thePlayer.name
						end
						local thisItem = NativeUI.CreateItem(title)
						resultMenu:AddItem(thisItem)
						thisItem.Activated = function(ParentMenu, SelectedItem)
							_menuPool:CloseAllMenus()
							Citizen.Wait(300)
							local thisMenu = thePlayer.menu
							playerMenus[tostring(thePlayer.id)].generate(thisMenu)
							thisMenu:Visible(true)
						end
					end
					_menuPool:CloseAllMenus()
					Citizen.Wait(300)
					resultMenu:Visible(true)
					return
				end
				if found and (#temp == 1) then
					local thisMenu = temp[1].menu
					_menuPool:CloseAllMenus()
					Citizen.Wait(300)
					ttsSpeechText("Found User.")
					playerMenus[tostring(temp[1].id)].generate(thisMenu)
					thisMenu:Visible(true)
					return
				end

				lib.notify({
					title = "Search Results",
					description = "No results found!",
					type = "error"
				})
			end
		end

		playerMenus = {}
		cachedMenus = {}
		reportMenus = {}
		for i, thePlayer in pairs(players) do
			if RedM and not settings.infinity then
				thePlayer = {
					id = GetPlayerServerId(thePlayer),
					name = GetPlayerName(thePlayer)
				}
			end
			local thisPlayerMenu = _menuPool:AddSubMenu(playermanagement, "[" .. thePlayer.id .. "] " .. thePlayer.name,
				"", true)
			if not RedM and thePlayer.developer then
				thisPlayerMenu.ParentItem:SetRightBadge(23)
			elseif not RedM and thePlayer.contributor then
				thisPlayerMenu.ParentItem:SetRightBadge(24)
			end
			playerMenus[tostring(thePlayer.id)] = { menu = thisPlayerMenu, name = thePlayer.name, id = thePlayer.id }

			thisPlayerMenu:SetMenuWidthOffset(menuWidth)

			playerMenus[tostring(thePlayer.id)].generate = function(menu)
				thisPlayer = menu


				if not playerMenus[tostring(thePlayer.id)].generated then
					if permissions["player.kick"] then
						local thisItem = NativeUI.CreateItem(GetLocalisedText("kickplayer"),
							GetLocalisedText("kickreasonguide"))
						thisPlayer:AddItem(thisItem)
						thisItem.Activated = function(ParentMenu, SelectedItem)
							local input = lib.inputDialog('Kick Player', {
								{ type = 'input', label = 'Reason for Kick', description = 'Provide a reason for kicking the player.', required = true, min = 3, max = 128 }
							})

							if input then
								local KickReason = input[1] or GetLocalisedText("noreason")
								TriggerServerEvent("EasyAdmin:kickPlayer", thePlayer.id, KickReason)
								_menuPool:CloseAllMenus()
								Citizen.Wait(800)
								GenerateMenu()
								playermanagement:Visible(true)
							end
						end
					end

					if permissions["player.ban.temporary"] or permissions["player.ban.permanent"] then
						local thisItem = NativeUI.CreateItem(GetLocalisedText("banplayer"), "", true)
						thisPlayer:AddItem(thisItem)

						thisItem.Activated = function(ParentMenu, SelectedItem)
							local input = lib.inputDialog('Ban Details', {
								{ type = 'input',  label = 'Reason for Ban', description = 'Provide a reason for banning the player.',                           required = true, min = 3,   max = 128 },
								{
									type = 'select',
									label = 'Ban Duration',
									description = 'Select the duration of the ban.',
									options = {
										{ label = 'Hour(s)',   value = 'hours' },
										{ label = 'Day(s)',    value = 'days' },
										{ label = 'Week(s)',   value = 'weeks' },
										{ label = 'Month(s)',  value = 'months' },
										{ label = 'Permanent', value = 'permanent' }
									},
									required = true,
									searchable = true,
									clearable = true
								},
								{ type = 'number', label = 'Ban Duration',   description = 'Specify the length of the ban time. If Permanent IGNORE Box Below!', min = 1,         max = 300, step = 10, default = 0, required = true }
							})

							if input then
								local BanReason = input[1] or "No reason provided"

								local BanDuration = input[2] or 'hours'
								print(BanDuration)

								local AmountOfTime = input[3] or 0

								local BanLength = 0
								local BanDurationText = ""

								if BanDuration == 'permanent' then
									BanLength = -1
									BanDurationText = "Permanent"
								elseif AmountOfTime > 0 then
									if BanDuration == 'hours' then
										BanLength = AmountOfTime * 3600
										BanDurationText = AmountOfTime .. " Hour(s)"
									elseif BanDuration == 'days' then
										BanLength = AmountOfTime * 86400
										BanDurationText = AmountOfTime .. " Day(s)"
									elseif BanDuration == 'weeks' then
										BanLength = AmountOfTime * 604800
										BanDurationText = AmountOfTime .. " Week(s)"
									elseif BanDuration == 'months' then
										BanLength = AmountOfTime * 2592000
										BanDurationText = AmountOfTime .. " Month(s)"
									end
								end

								if BanLength > 0 or BanLength == -1 then
									TriggerServerEvent("EasyAdmin:banPlayer", thePlayer.id, BanReason, BanLength,
										thePlayer.name)
									lib.notify({
										title = "Ban Notification",
										description = thePlayer.name ..
										" has been banned for " .. BanReason .. " for " .. BanDurationText .. ".",   -- Removed the BanLength (seconds) from the description
										type = "success"
									})
								else
									lib.notify({
										title = "Error",
										description = "Invalid ban length! Please enter a valid number.",
										type = "error"
									})
								end
							end
						end
					end

					if permissions["player.jail"] then
						local thisItem = NativeUI.CreateItem(GetLocalisedText("jailplayer"), "", true)
						thisPlayer:AddItem(thisItem)

						thisItem.Activated = function(ParentMenu, SelectedItem)
							local input = lib.inputDialog('Jail Details', {
								{ type = 'input',  label = 'Reason for Jail',         description = 'Provide a reason for jailing the player.',        required = true, min = 3,    max = 128 },
								{ type = 'number', label = 'Jail Duration (seconds)', description = 'Specify the length of the jail time in seconds.', min = 1,         max = 1200, default = 30, required = true }
							})

							if input then
								local JailReason = input[1] or "No reason provided"
								local JailLengthSeconds = tonumber(input[2]) or 60

								if JailLengthSeconds >= 1 and JailLengthSeconds <= 1200 then
									TriggerServerEvent("Liam:JailPlayerServer", thePlayer.id, JailLengthSeconds,
										JailReason)
									lib.notify({
										title = 'Player Jailed',
										description = thePlayer.name ..
										' has been jailed for ' .. JailLengthSeconds .. ' seconds.',
										type = 'success'
									})
								else
									lib.notify({
										title = 'Invalid Jail Duration',
										description = 'Please enter a valid number between 1 and 120000 seconds.',
										type = 'error'
									})
								end
							end
						end
					end

					if permissions["player.unjail"] then
						local thisItem = NativeUI.CreateItem(GetLocalisedText("unjailplayer"), "", true)
						thisPlayer:AddItem(thisItem)

						thisItem.Activated = function(ParentMenu, SelectedItem)
							local input = lib.inputDialog('Confirm Unjail', {
								{ type = 'checkbox', label = 'Are you sure you want to unjail ' .. thePlayer.name .. '?', required = true }
							})

							if input and input[1] then
								TriggerServerEvent("Liam:UnjailPlayerServer", thePlayer.id)
								lib.notify({
									title = 'Player Unjailed',
									description = thePlayer.name .. ' has been released from jail.',
									type = 'success'
								})
							else
								lib.notify({
									title = 'Unjail Cancelled',
									description = 'The unjail action was cancelled.',
									type = 'info'
								})
							end
						end
					end

					if permissions["player.mute"] then
						local thisItem = NativeUI.CreateCheckboxItem(GetLocalisedText("mute"), MutedPlayers
							[thePlayer.id], GetLocalisedText("muteguide"))
						thisPlayer:AddItem(thisItem)
						thisItem.CheckboxEvent = function(sender, item, checked_)
							TriggerServerEvent("EasyAdmin:mutePlayer", thePlayer.id)
						end
					end

					if permissions["player.spectate"] then
						local thisItem = NativeUI.CreateItem(GetLocalisedText("spectateplayer"), "")
						thisPlayer:AddItem(thisItem)
						thisItem.Activated = function(ParentMenu, SelectedItem)
							TriggerServerEvent("EasyAdmin:requestSpectate", thePlayer.id)
						end
					end

					if permissions["player.teleport.single"] then
						local sl = { GetLocalisedText("teleporttoplayer"), GetLocalisedText("teleportplayertome"),
							GetLocalisedText("teleportmeback"), GetLocalisedText("teleportplayerback"), GetLocalisedText(
							"teleportintoclosestvehicle") }
						local thisItem = NativeUI.CreateListItem(GetLocalisedText("teleportplayer"), sl, 1, "")
						thisPlayer:AddItem(thisItem)
						thisItem.OnListSelected = function(sender, item, index)
							if item == thisItem then
								i = item:IndexToItem(index)
								local playerPed = PlayerPedId()
								if i == GetLocalisedText("teleporttoplayer") then
									if settings.infinity then
										TriggerServerEvent('EasyAdmin:TeleportAdminToPlayer', thePlayer.id)
									else
										lastLocation = GetEntityCoords(playerPed)
										local x, y, z = table.unpack(GetEntityCoords(
											GetPlayerPed(GetPlayerFromServerId(thePlayer.id)), true))
										local heading = GetEntityHeading(GetPlayerPed(player))
										SetEntityCoords(playerPed, x, y, z, 0, 0, heading, false)
									end
								elseif i == GetLocalisedText("teleportplayertome") then
									local coords = GetEntityCoords(playerPed, true)
									TriggerServerEvent("EasyAdmin:TeleportPlayerToCoords", thePlayer.id, coords)
								elseif i == GetLocalisedText("teleportmeback") and lastLocation then
									local heading = GetEntityHeading(playerPed)
									SetEntityCoords(playerPed, lastLocation, 0, 0, heading, false)
									lastLocation = nil
								elseif i == GetLocalisedText("teleportplayerback") then
									TriggerServerEvent("EasyAdmin:TeleportPlayerBack", thePlayer.id)
								elseif i == GetLocalisedText("teleportintoclosestvehicle") then
									local coords = GetEntityCoords(playerPed, true)
									local vehicles = GetGamePool("CVehicle")
									local closestDistance = -1
									local closestVehicle = -1
									for _, vehicle in pairs(vehicles) do
										local vehcoords = GetEntityCoords(vehicle, true)
										local distance = #(coords - vehcoords)
										if closestDistance == -1 or closestDistance > distance then
											closestDistance = distance
											closestVehicle = vehicle
										end
									end
									if closestVehicle ~= -1 then
										for i = -1, GetVehicleMaxNumberOfPassengers(closestVehicle) do
											if IsVehicleSeatFree(closestVehicle, i) then
												SetPedIntoVehicle(playerPed, closestVehicle, i)
												break
											end
										end
									else
										lib.notify({
											title = "EasyAdmin",
											description = "No Vehicles found nearby.",
											type = "error"
										})
									end
								end
							end
						end
					end


					if permissions["player.slap"] then
						local thisItem = NativeUI.CreateSliderItem(GetLocalisedText("slapplayer"), SlapAmount, 20, false,
							false)
						thisPlayer:AddItem(thisItem)
						thisItem.OnSliderSelected = function(index)
							TriggerServerEvent("EasyAdmin:SlapPlayer", thePlayer.id, index * 10)
						end
					end

					if permissions["player.freeze"] and not RedM then
						local thisItem = NativeUI.CreateCheckboxItem(GetLocalisedText("setplayerfrozen"),
							FrozenPlayers[thePlayer.id])
						thisPlayer:AddItem(thisItem)
						thisItem.CheckboxEvent = function(sender, item, checked_)
							TriggerServerEvent("EasyAdmin:FreezePlayer", thePlayer.id, checked_)
						end
					end

					if permissions["player.screenshot"] then
						local thisItem = NativeUI.CreateItem(GetLocalisedText("takescreenshot"), "")
						thisPlayer:AddItem(thisItem)
						thisItem.Activated = function(ParentMenu, SelectedItem)
							TriggerServerEvent("EasyAdmin:TakeScreenshot", thePlayer.id)
						end
					end

					if permissions["player.warn"] then
						local thisItem = NativeUI.CreateItem(GetLocalisedText("warnplayer"),
							GetLocalisedText("warnreasonguide"))
						thisPlayer:AddItem(thisItem)
						thisItem.Activated = function(ParentMenu, SelectedItem)
							local input = lib.inputDialog('Warn Player', {
								{ type = 'input', label = 'Reason for Warning', description = 'Provide a reason for warning the player.', required = true, min = 3, max = 128 }
							})

							if input then
								local WarnReason = input[1] or GetLocalisedText("noreason")
								TriggerServerEvent("EasyAdmin:warnPlayer", thePlayer.id, WarnReason)
								_menuPool:CloseAllMenus()
								Citizen.Wait(800)
								GenerateMenu()
								playermanagement:Visible(true)
							end
						end
					end

					local items = {
						"Copy Discord ID",
						"Toggle Cuff",
					}
					local thisItem = NativeUI.CreateListItem("Misc Options", items, 1)
					thisPlayer:AddItem(thisItem)
					thisItem.OnListSelected = function(sender, item, index)
						if item == thisItem then
							i = item:IndexToItem(index)
							if i == "Copy Discord ID" then
								if thePlayer.discord then
									copyToClipboard(thePlayer.discord)
								else
									TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("nodiscordpresent"))
								end
							elseif i == "Toggle Cuff" then
								TriggerEvent('SEM_InteractionMenu:Cuff', thePlayer.id) -- Your cuffing event should go here (Default: Sem Interaction Menu)
							end
						end
					end

					if GetConvar("ea_enableActionHistory", "true") == "true" and permissions["player.actionhistory.view"] then
						local actionHistoryMenu = _menuPool:AddSubMenu(thisPlayer, GetLocalisedText("actionhistory"),
							GetLocalisedText("actionhistoryguide"), true)
						actionHistoryMenu:SetMenuWidthOffset(menuWidth)

						local refreshItem = NativeUI.CreateItem(GetLocalisedText("refreshactionhistory"),
							GetLocalisedText("refreshactionhistoryguide"))
						actionHistoryMenu:AddItem(refreshItem)
						refreshItem.Activated = function(ParentMenu, SelectedItem)
							actionHistoryMenu:Clear()
							local loadingItem = NativeUI.CreateItem(GetLocalisedText("actionsloading"),
								GetLocalisedText("actionsloadingguide"))
							actionHistoryMenu:AddItem(loadingItem)
							TriggerServerEvent("EasyAdmin:GetActionHistory", thePlayer.discord)
						end

						local loadingItem = NativeUI.CreateItem(GetLocalisedText("actionsloading"),
							GetLocalisedText("actionsloadingguide"))
						actionHistoryMenu:AddItem(loadingItem)
						TriggerServerEvent("EasyAdmin:GetActionHistory", thePlayer.discord)

						RegisterNetEvent("EasyAdmin:ReceiveActionHistory")
						AddEventHandler("EasyAdmin:ReceiveActionHistory", function(actionHistory)
							actionHistoryMenu:Clear()
							actionHistoryMenu:AddItem(refreshItem)
							if #actionHistory == 0 then
								local noActionsItem = NativeUI.CreateItem(GetLocalisedText("noactions"),
									GetLocalisedText("noactionsguide"))
								actionHistoryMenu:AddItem(noActionsItem)
							end
							for i, action in ipairs(actionHistory) do
								local actionSubmenu = _menuPool:AddSubMenu(actionHistoryMenu,
									"[#" .. action.id .. "] " .. action.action .. " by " .. action.moderator,
									GetLocalisedText("reason") .. ": " .. action.reason or "", true)
								actionSubmenu:SetMenuWidthOffset(menuWidth)
								if action.action == "BAN" and permissions["player.ban.remove"] then
									local actionUnban = NativeUI.CreateItem(GetLocalisedText("unbanplayer"),
										GetLocalisedText("unbanplayerguide"))
									actionUnban.Activated = function(ParentMenu, SelectedItem)
										TriggerServerEvent("EasyAdmin:UnbanPlayer", action.id)
										TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("unbanplayer"))
										TriggerServerEvent("EasyAdmin:GetActionHistory", thePlayer.discord)
										ParentMenu:Visible(false)
										ParentMenu.ParentMenu:Visible(true)
									end
									actionSubmenu:AddItem(actionUnban)
								end
								if permissions["player.actionhistory.delete"] then
									local actionDelete = NativeUI.CreateItem(GetLocalisedText("deleteaction"),
										GetLocalisedText("deleteactionguide"))
									actionDelete.Activated = function(ParentMenu, SelectedItem)
										TriggerServerEvent("EasyAdmin:DeleteAction", action.id)
										lib.notify({
											title = "EasyAdmin",
											description = GetLocalisedText("actiondeleted"),
											type = "success"
										})
										TriggerServerEvent("EasyAdmin:GetActionHistory", thePlayer.discord)
										ParentMenu:Visible(false)
										ParentMenu.ParentMenu:Visible(true)
									end
									actionSubmenu:AddItem(actionDelete)
								end
								local punishedDiscord = NativeUI.CreateItem(GetLocalisedText("getplayerdiscord"),
									GetLocalisedText("getplayerdiscordguide"))
								punishedDiscord.Activated = function(ParentMenu, SelectedItem)
									if action.discord then
										copyToClipboard(action.discord)
									else
										TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("nodiscordpresent"))
									end
								end
								actionSubmenu:AddItem(punishedDiscord)
								local moderatorDiscord = NativeUI.CreateItem(GetLocalisedText("getmoderatordiscord"),
									GetLocalisedText("getmoderatordiscordguide"))
								moderatorDiscord.Activated = function(ParentMenu, SelectedItem)
									if action.moderatorId then
										copyToClipboard(action.moderatorId)
									else
										TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("nodiscordpresent"))
									end
								end
								actionSubmenu:AddItem(moderatorDiscord)
								actionSubmenu:RefreshIndex()
							end
							actionHistoryMenu:RefreshIndex()
						end)
					end

					TriggerEvent("EasyAdmin:BuildPlayerOptions", thePlayer.id)
					for i, plugin in pairs(plugins) do
						if plugin.functions.playerMenu then
							PrintDebugMessage("Processing Plugin: " .. plugin.name, 4)
							local ran, errorMsg = pcall(plugin.functions.playerMenu, thePlayer.id)
							if not ran then
								PrintDebugMessage("Error in plugin " .. plugin.name .. ": \n" .. errorMsg, 1)
							end
						end
					end


					if GetResourceState("es_extended") == "started" and not ESX then
						local thisItem = NativeUI.CreateItem("~y~[ESX]~s~ Options",
							"You can buy the ESX Plugin from https://blumlaut.tebex.io to use this Feature.")
						thisPlayer:AddItem(thisItem)
						thisItem.Activated = function(ParentMenu, SelectedItem)
							copyToClipboard("https://blumlaut.tebex.io/package/4455820")
						end
					end
					if GetResourceState("qb-core") == "started" and not QBCore then
						local thisItem = NativeUI.CreateItem("~b~[QBCore]~s~ Options",
							"You can buy the QBCore Plugin from https://blumlaut.tebex.io to use this Feature.")
						thisPlayer:AddItem(thisItem)
						thisItem.Activated = function(ParentMenu, SelectedItem)
							copyToClipboard("https://blumlaut.tebex.io/package/4842353")
						end
					end

					_menuPool:ControlDisablingEnabled(false)
					_menuPool:MouseControlsEnabled(false)

					thisPlayer:RefreshIndexRecursively()
					playerMenus[tostring(thePlayer.id)].generated = true
				end
			end

			thisPlayerMenu.ParentItem.Activated = function(ParentMenu, SelectedItem)
				thisPlayer = thisPlayerMenu
				playerMenus[tostring(thePlayer.id)].generate(thisPlayer)

				for i, menu in pairs(playerMenus) do
					menu.menu.ParentMenu = playermanagement
				end
			end
		end

		playermanagement.ParentItem.Activated = function(ParentMenu, SelectedItem)
			for i, menu in pairs(playerMenus) do
				menu.menu.ParentMenu = playermanagement
			end
		end

		if permissions["player.reports.view"] then
			reportViewer = _menuPool:AddSubMenu(playermanagement, GetLocalisedText("reportviewer"), "", true)
			local thisMenuWidth = menuWidth
			if menuWidth < 150 then
				thisMenuWidth = 150
			else
				thisMenuWidth = menuWidth
			end
			reportViewer:SetMenuWidthOffset(thisMenuWidth)
			reportViewer.ParentItem:RightLabel(tostring(#reports) .. " " .. GetLocalisedText("open"))

			for i, report in pairs(reports) do
				local reportColour = (report.type == 0 and "~y~" or "~r~")
				if report.claimed then
					reportColour = "~g~"
				end
				local thisMenu = _menuPool:AddSubMenu(reportViewer,
					reportColour ..
					"#" .. report.id .. " " .. string.sub((report.reportedName or report.reporterName), 1, 12) .. "~w~",
					"", true)
				thisMenu:SetMenuWidthOffset(thisMenuWidth)
				thisMenu.ParentItem:RightLabel(formatRightString(report.reason, 32))
				reportMenus[report.id] = thisMenu

				if permissions["player.reports.claim"] then
					local claimText = GetLocalisedText("claimreport")
					local rightLabel = ""
					if report.claimed then
						claimText = GetLocalisedText("claimedby")
						rightLabel = formatRightString(report.claimedName)
					end

					local thisItem = NativeUI.CreateItem(claimText, "")
					thisItem:RightLabel(rightLabel)
					thisMenu:AddItem(thisItem)
					thisItem.Activated = function(ParentMenu, SelectedItem)
						if not report.claimed then
							TriggerServerEvent("EasyAdmin:ClaimReport", i)
						else
							TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("reportalreadyclaimed"))
						end
					end
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("reporter"), GetLocalisedText("entertoopen"))
				thisItem:RightLabel(formatRightString(report.reporterName))
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					_menuPool:CloseAllMenus()
					Citizen.Wait(50)
					GenerateMenu()
					Wait(100)
					if not playerMenus[tostring(report.reporter)] then
						lib.notify({
							title = "EasyAdmin",
							description = "Reporting Player Not Found!",
							type = "error"
						})
						reportViewer:Visible(true)
					else
						local ourMenu = playerMenus[tostring(report.reporter)].menu
						playerMenus[tostring(report.reporter)].generate(ourMenu)
						ourMenu.ParentMenu = reportMenus[report.id]
						ourMenu:Visible(true)
					end
				end

				if report.type == 1 then
					local thisItem = NativeUI.CreateItem(GetLocalisedText("reported"), GetLocalisedText("entertoopen"))
					thisItem:RightLabel(formatRightString(report.reportedName))
					thisMenu:AddItem(thisItem)
					thisItem.Activated = function(ParentMenu, SelectedItem)
						_menuPool:CloseAllMenus()
						Citizen.Wait(50)
						GenerateMenu()
						Wait(100)
						if not playerMenus[tostring(report.reported)] then
							lib.notify({
								title = "EasyAdmin",
								description = "Reported player not found!",
								type = "error"
							})
							reportViewer:Visible(true)
						else
							local ourMenu = playerMenus[tostring(report.reported)].menu
							playerMenus[tostring(report.reported)].generate(ourMenu)
							ourMenu.ParentMenu = reportMenus[report.id]
							ourMenu:Visible(true)
						end
					end
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("reason"), "")
				thisItem:RightLabel(formatRightString(report.reason, 48))
				thisMenu:AddItem(thisItem)

				if permissions["player.reports.process"] then
					local thisItem = NativeUI.CreateItem(GetLocalisedText("closereport"), "")
					thisMenu:AddItem(thisItem)
					thisItem.Activated = function(ParentMenu, SelectedItem)
						TriggerServerEvent("EasyAdmin:RemoveReport", report)
						_menuPool:CloseAllMenus()
						Citizen.Wait(800)
						GenerateMenu()
						reportViewer:Visible(true)
					end


					local thisItem = NativeUI.CreateItem(GetLocalisedText("closesimilarreports"),
						GetLocalisedText("closesimilarreportsguide"))
					thisMenu:AddItem(thisItem)
					thisItem.Activated = function(ParentMenu, SelectedItem)
						TriggerServerEvent("EasyAdmin:RemoveSimilarReports", report)
						_menuPool:CloseAllMenus()
						Citizen.Wait(800)
						GenerateMenu()
						reportViewer:Visible(true)
					end
				end
			end
			local thisItem = NativeUI.CreateItem(GetLocalisedText("refreshreports"),
				GetLocalisedText("refreshreportsguide"))
			reportViewer:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				_menuPool:CloseAllMenus()
				repeat
					Wait(100)
				until reportViewer
				GenerateMenu()
				reportViewer:Visible(true)
			end
		end


		allPlayers = _menuPool:AddSubMenu(playermanagement, GetLocalisedText("allplayers"), "", true)
		allPlayers:SetMenuWidthOffset(menuWidth)
		if permissions["player.teleport.everyone"] then
			-- "all players" function
			local thisItem = NativeUI.CreateItem(GetLocalisedText("teleporttome"), GetLocalisedText("teleporttomeguide"))
			allPlayers:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				local pCoords = GetEntityCoords(PlayerPedId(), true)
				TriggerServerEvent("EasyAdmin:TeleportPlayerToCoords", -1, pCoords)
			end
		end


		cachedListGenerated = false

		CachedList = _menuPool:AddSubMenu(playermanagement, GetLocalisedText("cachedplayers"), "", true)
		CachedList:SetMenuWidthOffset(menuWidth)

		CachedList.ParentItem.Activated = function(ParentMenu, SelectedItem)
			if not cachedListGenerated then
				if permissions["player.ban.temporary"] or permissions["player.ban.permanent"] then
					for i, cachedplayer in pairs(cachedplayers) do
						if cachedplayer.droppedTime and not cachedplayer.immune then
							local thisCachedPlayerMenu = _menuPool:AddSubMenu(CachedList,
								"[" .. cachedplayer.id .. "] " .. cachedplayer.name, "", true)
							cachedMenus[tostring(cachedplayer.id)] = {
								menu = thisCachedPlayerMenu,
								name = cachedplayer
									.name,
								id = cachedplayer.id
							}
							thisCachedPlayerMenu:SetMenuWidthOffset(menuWidth)

							thisCachedPlayerMenu.ParentItem.Activated = function(ParentMenu, SelectedItem)
								thisPlayer = thisCachedPlayerMenu
								if not cachedMenus[tostring(cachedplayer.id)].generated then
									local thisBanMenu = _menuPool:AddSubMenu(thisPlayer, GetLocalisedText("banplayer"),
										"", true)
									thisBanMenu:SetMenuWidthOffset(menuWidth)

									local thisItem = NativeUI.CreateItem(GetLocalisedText("reason"),
										GetLocalisedText("banreasonguide"))
									thisBanMenu:AddItem(thisItem)
									BanReason = GetLocalisedText("noreason")
									thisItem:RightLabel(BanReason)
									thisItem.Activated = function(ParentMenu, SelectedItem)
										local result = displayKeyboardInput("FMMC_KEY_TIP8", "", 128)
										local formattedResult = formatRightString(formatShortcuts(result))

										if result and result ~= "" then
											BanReason = result
											thisItem:RightLabel(formattedResult)
										else
											BanReason = GetLocalisedText("noreason")
										end
									end
									local bt = {}
									for i, a in ipairs(banLength) do
										table.insert(bt, a.label)
									end

									local thisItem = NativeUI.CreateListItem(GetLocalisedText("banlength"), bt, 1,
										GetLocalisedText("banlengthguide"))
									thisBanMenu:AddItem(thisItem)
									local BanTime = 1
									thisItem.OnListChanged = function(sender, item, index)
										BanTime = index
									end

									local thisItem = NativeUI.CreateItem(GetLocalisedText("confirmban"),
										GetLocalisedText("confirmbanguide"))
									thisBanMenu:AddItem(thisItem)
									thisItem.Activated = function(ParentMenu, SelectedItem)
										if BanReason == "" then
											BanReason = GetLocalisedText("noreason")
										end
										TriggerServerEvent("EasyAdmin:offlinebanPlayer", cachedplayer.id, BanReason,
											banLength[BanTime].time, cachedplayer.name)
										BanTime = 1
										BanReason = ""
										_menuPool:CloseAllMenus()
										Citizen.Wait(800)
										GenerateMenu()
										playermanagement:Visible(true)
									end
									TriggerEvent("EasyAdmin:BuildCachedOptions", cachedplayer.id)
									for i, plugin in pairs(plugins) do
										if plugin.functions.cachedMenu then
											PrintDebugMessage("Processing Plugin: " .. plugin.name, 4)
											local ran, errorMsg = pcall(plugin.functions.cachedMenu, cachedplayer.id)
											if not ran then
												PrintDebugMessage(
													"Error in plugin " .. plugin.name .. ": \n" .. errorMsg,
													1)
											end
										end
									end
									thisPlayer:RefreshIndexRecursively()
								end
							end
						end
					end
				end
				cachedListGenerated = true
				CachedList:RefreshIndexRecursively()
			end
		end
	end


	if DoesPlayerHavePermissionForCategory(-1, "server") then
		if permissions["server.announce"] then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("announcement"), GetLocalisedText("announcementguide"))
			servermanagement:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				local input = lib.inputDialog('Make Announcement', {
					{ type = 'input', label = 'Announcement Message', description = 'Enter the announcement message.', required = true, min = 1, max = 200 }
				})

				if input then
					local announcementMessage = input[1]
					if announcementMessage and announcementMessage ~= "" then
						TriggerServerEvent("EasyAdmin:announcement", announcementMessage)
						lib.notify({
							title = "Announcement",
							description = announcementMessage,
							type = "success"
						})
					else
						lib.notify({
							title = "EasyAdmin",
							description = "Announcement Failed",
							type = "error"
						})
					end
				end
			end
		end

		if permissions["server.convars"] then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("setgametype"), GetLocalisedText("setgametypeguide"))
			servermanagement:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				local input = lib.inputDialog('Set Game Type', {
					{ type = 'input', label = 'Game Type', description = 'Enter the new game type', required = true }
				})

				if input then
					local newGameType = input[1]
					if newGameType then
						TriggerServerEvent("EasyAdmin:SetGameType", newGameType)
					else
						TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("invalidgametype"))
					end
				end
			end

			local thisItem = NativeUI.CreateItem(GetLocalisedText("setmapname"), GetLocalisedText("setmapnameguide"))
			servermanagement:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				local input = lib.inputDialog('Set Map Name', {
					{ type = 'input', label = 'Map Name', description = 'Enter the new map name', required = true }
				})

				if input then
					local newMapName = input[1]
					if newMapName then
						TriggerServerEvent("EasyAdmin:SetMapName", newMapName)
					else
						TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("invalidmapname"))
					end
				end
			end
		end

		if permissions["server.resources.start"] then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("startresourcebyname"),
				GetLocalisedText("startresourcebynameguide"))
			servermanagement:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				local input = lib.inputDialog('Start Resource', {
					{ type = 'input', label = 'Resource Name', description = 'Enter the name of the resource to start', required = true }
				})

				if input then
					local resourceName = input[1]
					if resourceName and resourceName ~= "" then
						TriggerServerEvent("EasyAdmin:StartResource", resourceName)
					else
						TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("invalidresourcename"))
					end
				end
			end
		end

		if permissions["server.resources.stop"] then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("stopresourcebyname"),
				GetLocalisedText("stopresourcebynameguide"))
			servermanagement:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				local input = lib.inputDialog('Stop Resource', {
					{ type = 'input', label = 'Resource Name', description = 'Enter the name of the resource to stop', required = true }
				})

				if input then
					local resourceName = input[1]
					if resourceName and resourceName ~= "" then
						if resourceName ~= GetCurrentResourceName() then
							TriggerServerEvent("EasyAdmin:StopResource", resourceName)
						else
							TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("badidea"))
						end
					else
						TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("invalidresourcename"))
					end
				end
			end
		end

		if permissions["server.convars"] then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("setconvar"), GetLocalisedText("setconvarguide"))
			servermanagement:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				local input = lib.inputDialog('Set Convar', {
					{ type = 'input', label = 'Convar Name',  description = 'Enter the name of the convar',   required = true },
					{ type = 'input', label = 'Convar Value', description = 'Enter the value for the convar', required = true }
				})

				if input then
					local convarName = input[1]
					local convarValue = input[2]
					if convarName and convarName ~= "" and convarValue and convarValue ~= "" then
						TriggerServerEvent("EasyAdmin:SetConvar", convarName, convarValue)
					else
						TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("invalidconvar"))
					end
				end
			end
		end
	end

	if permissions["player.ban.view"] then
		unbanPlayer = _menuPool:AddSubMenu(servermanagement, GetLocalisedText("viewbanlist"), "", true)
		local thisMenuWidth = menuWidth
		if menuWidth < 150 then
			thisMenuWidth = 150
		else
			thisMenuWidth = menuWidth
		end
		unbanPlayer:SetMenuWidthOffset(thisMenuWidth)
		local reason = ""
		local identifier = ""

		local function generateBanOverview(banId)
			_menuPool:Remove()
			TriggerEvent("EasyAdmin:MenuRemoved")
			_menuPool = NativeUI.CreatePool()
			collectgarbage()
			if not GetResourceKvpString("ea_menuorientation") then
				SetResourceKvp("ea_menuorientation", "middle")
				SetResourceKvpInt("ea_menuwidth", 0)
				menuWidth = 0
				menuOrientation = handleOrientation("middle")
			else
				menuWidth = GetResourceKvpInt("ea_menuwidth")
				menuOrientation = handleOrientation(GetResourceKvpString("ea_menuorientation"))
			end

			local mainMenu = NativeUI.CreateMenu("", "Ban Infos", menuOrientation, 0, "easyadmin", "banner-gradient",
				"logo")
			_menuPool:Add(mainMenu)

			local thisMenuWidth = menuWidth
			if menuWidth < 150 then
				thisMenuWidth = 150
			else
				thisMenuWidth = menuWidth
			end
			mainMenu:SetMenuWidthOffset(thisMenuWidth)
			_menuPool:ControlDisablingEnabled(false)
			_menuPool:MouseControlsEnabled(false)


			if banlist[banId].banid then
				local thisItem = NativeUI.CreateItem("Ban ID: " .. banlist[banId].banid, "")
				mainMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					copyToClipboard(banlist[banId].banid)
				end
			end

			local thisItem = NativeUI.CreateItem(GetLocalisedText("reason"), banlist[banId].reason)
			mainMenu:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
			end


			if banlist[banId].name then
				local thisItem = NativeUI.CreateItem("Name: " .. banlist[banId].name, "")
				mainMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					if permissions["player.ban.edit"] then
						local result = displayKeyboardInput("", banlist[banId].name, 64)

						if result then
							banlist[banId].name = result
						end
					end
				end
			end


			if banlist[banId].banner then
				local thisItem = NativeUI.CreateItem("Banner: " .. banlist[banId].banner, "")
				mainMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					if permissions["player.ban.edit"] then
						local result = displayKeyboardInput("", banlist[banId].banner, 64)

						if result then
							banlist[banId].banner = result
						end
					end
				end
			end


			if banlist[banId].expireString then
				local thisItem = NativeUI.CreateItem("Expires: " .. banlist[banId].expireString, "")
				mainMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					if permissions["player.ban.edit"] then
						AddTextEntry("EA_ENTERTIME", "Enter Unix Timestamp")
						local result = displayKeyboardInput("EA_ENTERTIME", banlist[banId].expire, 64)

						if result then
							banlist[banId].expire = tonumber(result)
						end
					end
				end
			end


			for _, identifier in pairs(banlist[banId].identifiers) do
				if not (GetConvar("ea_IpPrivacy", "true") == "true" and string.split(identifier, ":")[1] == "ip") then
					local thisItem = NativeUI.CreateItem(
						string.format(GetLocalisedText("identifier"), string.split(identifier, ":")[1]), identifier)
					mainMenu:AddItem(thisItem)
					thisItem.Activated = function(ParentMenu, SelectedItem)
						copyToClipboard(identifier)
					end
				end
			end

			if permissions["player.ban.edit"] then
				local thisItem = NativeUI.CreateItem(GetLocalisedText("savebanchanges"), GetLocalisedText("savebanguide"))
				mainMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					TriggerServerEvent("EasyAdmin:editBan", banlist[banId])
				end
			end

			if permissions["player.ban.remove"] then
				local thisItem = NativeUI.CreateItem(GetLocalisedText("unbanplayer"),
					GetLocalisedText("unbanplayerguide"))
				mainMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					TriggerServerEvent("EasyAdmin:unbanPlayer", banlist[banId].banid)
					TriggerServerEvent("EasyAdmin:requestBanlist")
					_menuPool:CloseAllMenus()
					Citizen.Wait(800)
					GenerateMenu()
					unbanPlayer:Visible(true)
				end
				mainMenu:Visible(true)
			end
		end


		local thisItem = NativeUI.CreateItem(GetLocalisedText("searchbans"), "")
		unbanPlayer:AddItem(thisItem)
		thisItem.Activated = function(ParentMenu, SelectedItem)
			local result = displayKeyboardInput("FMMC_KEY_TIP8", "", 128)

			local foundBan = false
			if result then
				for i, theBanned in ipairs(banlist) do
					if foundBan then
						break
					end
					if tostring(theBanned.banid) == result then
						foundBan = true
						foundBanid = i
						break
					end
				end
				if not foundBan then
					for i, theBanned in ipairs(banlist) do
						if theBanned.name then
							if string.find(string.lower(theBanned.name), string.lower(result)) then
								foundBan = true
								foundBanid = i
								break
							end
						end
						if string.find((string.lower(theBanned.reason) or "No Reason"), string.lower(result)) then
							foundBan = true
							foundBanid = i
							break
						end
						for _, identifier in pairs(theBanned.identifiers) do
							if string.find(identifier, result) then
								foundBan = true
								foundBanid = i
								break
							end
						end
					end
				end
			end
			_menuPool:CloseAllMenus()
			Citizen.Wait(300)
			if foundBan then
				generateBanOverview(foundBanid)
			else
				lib.notify({
					title = "Announcement",
					description = "No Ban with the Search Criteria was found.",
					type = "fail"
				})


				GenerateMenu()
				unbanPlayer:Visible(true)
			end
		end

		for i, theBanned in ipairs(banlist) do
			if i < (banlistPage * 10) + 1 and i > (banlistPage * 10) - 10 then
				if theBanned then
					reason = theBanned.reason or "No Reason"
					local thisItem = NativeUI.CreateItem(string.sub(reason, 1, 50), "")
					unbanPlayer:AddItem(thisItem)
					thisItem.Activated = function(ParentMenu, SelectedItem)
						generateBanOverview(i)
					end
				end
			end
		end


		if #banlist > (banlistPage * 10) then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("lastpage"), "")
			unbanPlayer:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				banlistPage = math.ceil(#banlist / 10)
				_menuPool:CloseAllMenus()
				Citizen.Wait(300)
				GenerateMenu()
				unbanPlayer:Visible(true)
			end
		end

		if banlistPage > 1 then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("firstpage"), "")
			unbanPlayer:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				banlistPage = 1
				_menuPool:CloseAllMenus()
				Citizen.Wait(300)
				GenerateMenu()
				unbanPlayer:Visible(true)
			end
			local thisItem = NativeUI.CreateItem(GetLocalisedText("previouspage"), "")
			unbanPlayer:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				banlistPage = banlistPage - 1
				_menuPool:CloseAllMenus()
				Citizen.Wait(300)
				GenerateMenu()
				unbanPlayer:Visible(true)
			end
		end
		if #banlist > (banlistPage * 10) then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("nextpage"), "")
			unbanPlayer:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				banlistPage = banlistPage + 1
				_menuPool:CloseAllMenus()
				Citizen.Wait(300)
				GenerateMenu()
				unbanPlayer:Visible(true)
			end
		end
	end


	if DoesPlayerHavePermissionForCategory(-1, "server") then
		local sl = {}
		if permissions["server.cleanup.cars"] then
			table.insert(sl, GetLocalisedText('cars'))
		end
		if permissions["server.cleanup.peds"] then
			table.insert(sl, GetLocalisedText('peds'))
		end
		if permissions["server.cleanup.props"] then
			table.insert(sl, GetLocalisedText('props'))
		end

		if #sl > 0 and not RedM then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("cleanarea"), GetLocalisedText("cleanareaguide"))
			servermanagement:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				local input = lib.inputDialog('Clean Area', {
					{
						type = 'select',
						label = 'Type',
						options = {
							{ value = 'cars',  label = GetLocalisedText('cars') },
							{ value = 'peds',  label = GetLocalisedText('peds') },
							{ value = 'props', label = GetLocalisedText('props') }
						},
						default = 'cars'
					},
					{
						type = 'select',
						label = 'Radius',
						options = {
							{ value = 10,       label = '10' },
							{ value = 20,       label = '20' },
							{ value = 50,       label = '50' },
							{ value = 100,      label = '100' },
							{ value = 'global', label = 'Global' } },
						default = 10
					},
					{ type = 'checkbox', label = 'Deep Clean', description = GetLocalisedText("deepcleanguide") }
				})

				if input then
					local cleanType = input[1]
					local cleanRadius = input[2]
					local deepClean = input[3]
					local playerName = GetPlayerName(PlayerId()) -- Get the player's name

					if cleanType and cleanRadius then
						TriggerServerEvent("EasyAdmin:requestCleanup", cleanType, cleanRadius, deepClean)

						-- Send a notification if it's a global cleanup
						if cleanRadius == 'global' then
							local message = string.format("%s has performed a global cleanup of %s.", playerName,
								GetLocalisedText(cleanType))
							TriggerServerEvent("ox_lib:notifyAll", {
								title = "Global Cleanup",
								description = message,
								type = "info"
							})
						end
					else
						TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("invalidcleanup"))
					end
				end
			end
		end


		if permissions["server.permissions.read"] then
			permissionEditor = _menuPool:AddSubMenu(servermanagement, GetLocalisedText("permissioneditor"),
				GetLocalisedText("permissioneditorguide"), true)
			local thisMenuWidth = menuWidth
			if menuWidth < 150 then
				thisMenuWidth = 150
			else
				thisMenuWidth = menuWidth
			end
			permissionEditor:SetMenuWidthOffset(thisMenuWidth)

			editAces = _menuPool:AddSubMenu(permissionEditor, GetLocalisedText("aces"), "", true)
			editAces:SetMenuWidthOffset(thisMenuWidth)


			if permissions["server.permissions.read"] and permissions["server.permissions.write"] then
				local thisMenu = _menuPool:AddSubMenu(editAces, GetLocalisedText("addace"), "", true)
				thisMenu:SetMenuWidthOffset(thisMenuWidth)
				local tempAce = {}
				local thisItem = NativeUI.CreateItem(GetLocalisedText("group"), "")
				thisItem:RightLabel(tempAce[1] or "")
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					AddTextEntry("ENTERGROUP", GetLocalisedText("entergroup"))
					local result = displayKeyboardInput("ENTERGROUP", "group.", 64)

					if result and result ~= "" then
						tempAce[1] = result
						thisItem:RightLabel(formatRightString(result))
						thisMenu.ParentItem.Text._Text = result
					end
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("permission"), "")
				thisItem:RightLabel(formatRightString(tempAce[2]))
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					AddTextEntry("ENTERPERM", GetLocalisedText("enterperm"))
					local result = displayKeyboardInput("ENTERPERM", "", 64)

					if result and result ~= "" then
						tempAce[2] = result
						thisItem:RightLabel(formatRightString(result))
						thisMenu.ParentItem:RightLabel(formatRightString(result))
					end
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("state"), GetLocalisedText("stateguide"))
				thisItem:RightLabel("allow")
				tempAce[3] = "allow"
				thisMenu:AddItem(thisItem)
				thisItem:Enabled(false)


				local thisItem = NativeUI.CreateItem(GetLocalisedText("addace"), GetLocalisedText("addaceguide"))
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					table.insert(add_aces, tempAce)
					_menuPool:CloseAllMenus()
					Citizen.Wait(800)
					GenerateMenu()
					editAces:Visible(true)
					collectgarbage()
				end
			end

			for i, ace in pairs(add_aces) do
				local thisMenu = _menuPool:AddSubMenu(editAces, ace[1] .. " " .. ace[2], "", true)
				thisMenu:SetMenuWidthOffset(thisMenuWidth)
				thisMenu.ParentItem:RightLabel(ace[3])

				local thisItem = NativeUI.CreateItem(GetLocalisedText("group"), "")
				thisItem:RightLabel(formatRightString(ace[1]))
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					AddTextEntry("ENTERGROUP", GetLocalisedText("entergroup"))
					local result = displayKeyboardInput("ENTERGROUP", ace[1], 64)

					if result and result ~= "" then
						add_aces[i][1] = result
						thisItem:RightLabel(formatRightString(result))
						thisMenu.ParentItem.Text._Text = add_aces[i][1] .. " " .. add_aces[i][2]
					end
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("permission"), "")
				thisItem:RightLabel(formatRightString(ace[2]))
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					AddTextEntry("ENTERPERM", GetLocalisedText("enterperm"))
					local result = displayKeyboardInput("ENTERPERM", ace[2], 64)

					if result and result ~= "" then
						add_aces[i][2] = result
						thisItem:RightLabel(formatRightString(result))
						thisMenu.ParentItem.Text._Text = add_aces[i][1] .. " " .. add_aces[i][2]
					end
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("state"), GetLocalisedText("stateguide"))
				thisItem:RightLabel(formatRightString(ace[3]))
				thisMenu:AddItem(thisItem)
				thisItem:Enabled(false)

				if (ace.file) then
					local thisItem = NativeUI.CreateItem(GetLocalisedText("location"), GetLocalisedText("locationguide"))
					thisItem:RightLabel(formatRightString(ace.file))
					thisMenu:AddItem(thisItem)
					thisItem:Enabled(false)
				end


				local thisItem = NativeUI.CreateItem(GetLocalisedText("deletepermission"),
					GetLocalisedText("deletepermissionguide"))
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					thisMenu.ParentItem:Enabled(false)
					thisMenu.ParentItem._Description = GetLocalisedText("itemdeleted")
					add_aces[i] = nil
					thisMenu:GoBack()
				end
			end


			editPrincipals = _menuPool:AddSubMenu(permissionEditor, GetLocalisedText("principals"), "", true)
			editPrincipals:SetMenuWidthOffset(thisMenuWidth)

			if permissions["server.permissions.read"] and permissions["server.permissions.write"] then
				local thisMenu = _menuPool:AddSubMenu(editPrincipals, GetLocalisedText("addprincipal"), "", true)
				thisMenu:SetMenuWidthOffset(thisMenuWidth)
				local tempPrincipal = {}
				local thisItem = NativeUI.CreateItem(GetLocalisedText("principal"), "")
				thisItem:RightLabel(tempPrincipal[1] or "")
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					AddTextEntry("ENTERPRINCIPAL", GetLocalisedText("enterprincipal"))
					local result = displayKeyboardInput("ENTERPRINCIPAL", "identifier.", 64)

					if result and result ~= "" then
						tempPrincipal[1] = result
						thisItem:RightLabel(formatRightString(result))
					end
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("group"), "")
				thisItem:RightLabel(tempPrincipal[2] or "")
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					AddTextEntry("ENTERGROUP", GetLocalisedText("entergroup"))
					local result = displayKeyboardInput("ENTERGROUP", "group.", 64)

					if result and result ~= "" then
						tempPrincipal[2] = result
						thisItem:RightLabel(formatRightString(result))
						thisMenu.ParentItem:RightLabel(formatRightString(result))
					end
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("addprincipal"), GetLocalisedText("addaceguide")) -- the use of addaceguide is intentional.
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					table.insert(add_principals, tempPrincipal)
					_menuPool:CloseAllMenus()
					Citizen.Wait(800)
					GenerateMenu()
					editPrincipals:Visible(true)
					collectgarbage()
				end
			end

			for i, principal in pairs(add_principals) do
				local thisMenu = _menuPool:AddSubMenu(editPrincipals, principal[1], "", true)
				thisMenu:SetMenuWidthOffset(thisMenuWidth)
				thisMenu.ParentItem:RightLabel(principal[2])

				local thisItem = NativeUI.CreateItem(GetLocalisedText("principal"), "")
				thisItem:RightLabel(formatRightString(principal[1]))
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					AddTextEntry("ENTERPRINCIPAL", GetLocalisedText("enterprincipal"))
					local result = displayKeyboardInput("ENTERPRINCIPAL", principal[1], 64)

					if result and result ~= "" then
						add_principals[i][1] = result
						thisItem:RightLabel(formatRightString(result))
						thisMenu.ParentItem.Text._Text = add_principals[i][1]
					end
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("group"), "")
				thisItem:RightLabel(formatRightString(principal[2]))
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					AddTextEntry("ENTERGROUP", GetLocalisedText("entergroup"))
					local result = displayKeyboardInput("ENTERGROUP", principal[2], 64)

					if result and result ~= "" then
						add_principals[i][2] = result
						thisItem:RightLabel(formatRightString(result))
						thisMenu.ParentItem:RightLabel(formatRightString(result))
					end
				end

				if (principal.file) then
					local thisItem = NativeUI.CreateItem(GetLocalisedText("location"), GetLocalisedText("locationguide"))
					thisItem:RightLabel(formatRightString(principal.file))
					thisMenu:AddItem(thisItem)
					thisItem:Enabled(false)
				end

				local thisItem = NativeUI.CreateItem(GetLocalisedText("deleteprincipal"),
					GetLocalisedText("deleteprincipalguide"))
				thisMenu:AddItem(thisItem)
				thisItem.Activated = function(ParentMenu, SelectedItem)
					thisMenu.ParentItem:Enabled(false)
					thisMenu.ParentItem._Description = GetLocalisedText("itemdeleted")
					add_principals[i] = nil
					thisMenu:GoBack()
				end
			end
		end
		if permissions["server.permissions.read"] then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("refreshpermissions"), "")
			permissionEditor:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				add_aces, add_principals = nil, nil
				TriggerServerEvent("EasyAdmin:getServerAces")
				_menuPool:CloseAllMenus()
				repeat
					Wait(500)
				until add_aces
				GenerateMenu()
				permissionEditor:Visible(true)
				collectgarbage()
			end
		end

		if permissions["server.permissions.read"] and permissions["server.permissions.write"] then
			local thisItem = NativeUI.CreateItem(GetLocalisedText("savechanges"), GetLocalisedText("savechangesguide"))
			permissionEditor:AddItem(thisItem)
			thisItem.Activated = function(ParentMenu, SelectedItem)
				TriggerLatentServerEvent("EasyAdmin:setServerAces", 200000, add_aces, add_principals)
				_menuPool:CloseAllMenus()
				Citizen.Wait(800)
				GenerateMenu()
				permissionEditor:Visible(true)
				collectgarbage()
			end
		end


		TriggerEvent("EasyAdmin:BuildServerManagementOptions")
		for i, plugin in pairs(plugins) do
			if plugin.functions.serverMenu then
				PrintDebugMessage("Processing Plugin: " .. plugin.name, 4)
				local ran, errorMsg = pcall(plugin.functions.serverMenu)
				if not ran then
					PrintDebugMessage("Error in plugin " .. plugin.name .. ": \n" .. errorMsg, 1)
				end
			end
		end
	end

	if permissions["player.ban.view"] then
		local sl = { GetLocalisedText("unbanreasons"), GetLocalisedText("unbanlicenses") }
		local thisItem = NativeUI.CreateListItem(GetLocalisedText("banlistshowtype"), sl, 1,
			GetLocalisedText("banlistshowtypeguide"))
		settingsMenu:AddItem(thisItem)
		thisItem.OnListSelected = function(sender, item, index)
			if item == thisItem then
				i = item:IndexToItem(index)
				if i == GetLocalisedText(unbanreasons) then
					showLicenses = false
				else
					showLicenses = true
				end
			end
		end
	end


	if permissions["player.ban.view"] then
		local thisItem = NativeUI.CreateItem(GetLocalisedText("refreshbanlist"), GetLocalisedText("refreshbanlistguide"))
		settingsMenu:AddItem(thisItem)
		thisItem.Activated = function(ParentMenu, SelectedItem)
			banlist = nil
			TriggerServerEvent("EasyAdmin:updateBanlist")
			repeat
				Wait(500)
			until banlist
			GenerateMenu()
			settingsMenu:Visible(true)
			collectgarbage()
		end
	end

	if permissions["player.ban.temporary"] or permissions["player.ban.permanent"] then
		local thisItem = NativeUI.CreateItem(GetLocalisedText("refreshcachedplayers"),
			GetLocalisedText("refreshcachedplayersguide"))
		settingsMenu:AddItem(thisItem)
		thisItem.Activated = function(ParentMenu, SelectedItem)
			cachedplayers = nil
			TriggerServerEvent("EasyAdmin:requestCachedPlayers")
			repeat
				Wait(500)
			until cachedplayers
			GenerateMenu()
			settingsMenu:Visible(true)
			collectgarbage()
		end
	end

	local thisItem = NativeUI.CreateItem(GetLocalisedText("refreshpermissions"),
		GetLocalisedText("refreshpermissionsguide"))
	settingsMenu:AddItem(thisItem)
	thisItem.Activated = function(ParentMenu, SelectedItem)
		TriggerServerEvent("EasyAdmin:amiadmin")
	end

	local orientationIndex = 1
	if GetResourceKvpString("ea_menuorientation") == "middle" then
		orientationIndex = 2
	elseif GetResourceKvpString("ea_menuorientation") == "right" then
		orientationIndex = 3
	end

	local sl = { GetLocalisedText("left"), GetLocalisedText("middle"), GetLocalisedText("right") }
	local thisItem = NativeUI.CreateListItem(GetLocalisedText("menuOrientation"), sl, orientationIndex,
		GetLocalisedText("menuOrientationguide"))
	settingsMenu:AddItem(thisItem)
	thisItem.OnListSelected = function(sender, item, index)
		if item == thisItem then
			i = item:IndexToItem(index)
			if i == GetLocalisedText("left") then
				SetResourceKvp("ea_menuorientation", "left")
			elseif i == GetLocalisedText("middle") then
				SetResourceKvp("ea_menuorientation", "middle")
			else
				SetResourceKvp("ea_menuorientation", "right")
			end
		end
	end

	local sl = {}
	for i = 0, 250, 10 do
		table.insert(sl, i)
	end
	local thisi = 0
	for i, a in ipairs(sl) do
		if menuWidth == a then
			thisi = i
		end
	end
	local thisItem = NativeUI.CreateSliderItem(GetLocalisedText("menuOffset"), sl, thisi,
		GetLocalisedText("menuOffsetguide"), false)
	settingsMenu:AddItem(thisItem)
	thisItem.OnSliderSelected = function(index)
		i = thisItem:IndexToItem(index)
		SetResourceKvpInt("ea_menuwidth", i)
		menuWidth = i
	end
	thisi = nil
	sl = nil


	local thisItem = NativeUI.CreateItem(GetLocalisedText("resetmenuOffset"), "")
	settingsMenu:AddItem(thisItem)
	thisItem.Activated = function(ParentMenu, SelectedItem)
		SetResourceKvpInt("ea_menuwidth", 0)
		menuWidth = 0
	end

	if permissions["anon"] then
		local thisItem = NativeUI.CreateCheckboxItem(GetLocalisedText("anonymous"), anonymous or false,
			GetLocalisedText("anonymousguide"))
		settingsMenu:AddItem(thisItem)
		thisItem.CheckboxEvent = function(sender, item, checked_)
			anonymous = checked_
			TriggerServerEvent("EasyAdmin:SetAnonymous", checked_)
		end
	end


	local thisItem = NativeUI.CreateCheckboxItem(GetLocalisedText("screenreader"),
		GetResourceKvpInt('ea_tts') == 1 and true or false, GetLocalisedText("screenreaderguide"))
	settingsMenu:AddItem(thisItem)
	thisItem.CheckboxEvent = function(sender, item, checked_)
		SendNUIMessage({
			action = "toggle_speak",
			enabled = checked_
		})
		SetResourceKvpInt("ea_tts", checked_ and 1 or 0)
		SendNUIMessage({ action = "speak", text = "Text to Speech" })
	end

	if not RedM then
		local sl = { "none" }
		local currentEggIndex = 1
		for k, v in pairs(eastereggs) do
			table.insert(sl, k)
		end
		for k, v in pairs(sl) do
			if v == overrideEgg or v == currentEgg then
				currentEggIndex = k
			end
		end

		local thisItem = NativeUI.CreateListItem(GetLocalisedText("forceeasteregg"), sl, currentEggIndex, "")
		settingsMenu:AddItem(thisItem)
		thisItem.OnListSelected = function(sender, item, index)
			if item == thisItem then
				i = item:IndexToItem(index)
				if i == "none" then
					overrideEgg = false
				else
					overrideEgg = i
				end
			end
		end
	end


	TriggerEvent("EasyAdmin:BuildSettingsOptions")
	for i, plugin in pairs(plugins) do
		if plugin.functions.settingsMenu then
			PrintDebugMessage("Processing Plugin: " .. plugin.name, 4)
			local ran, errorMsg = pcall(plugin.functions.settingsMenu)
			if not ran then
				PrintDebugMessage("Error in plugin " .. plugin.name .. ": \n" .. errorMsg, 1)
			end
		end
	end
	_menuPool:ControlDisablingEnabled(false)
	_menuPool:MouseControlsEnabled(false)

	_menuPool:RefreshIndex() -- refresh indexes
end

function DrawPlayerInfoLoop()
	CreateThread(function()
		while drawInfo do
			Wait(0)

			local text = {}
			-- cheat checks
			local targetPed = GetPlayerPed(drawTarget)
			if (not RedM) then
				local targetGod = GetPlayerInvincible(drawTarget)
				if targetGod then
					table.insert(text, GetLocalisedText("godmodedetected"))
				else
					table.insert(text, GetLocalisedText("godmodenotdetected"))
				end
				if not CanPedRagdoll(targetPed) and not IsPedInAnyVehicle(targetPed, false) and (GetPedParachuteState(targetPed) == -1 or GetPedParachuteState(targetPed) == 0) and not IsPedInParachuteFreeFall(targetPed) then
					table.insert(text, GetLocalisedText("antiragdoll"))
				end
				-- health info
				table.insert(text,
					GetLocalisedText("health") .. ": " .. GetEntityHealth(targetPed) ..
					"/" .. GetEntityMaxHealth(targetPed))

				table.insert(text, GetLocalisedText("armor") .. ": " .. GetPedArmour(targetPed))

				-- misc info
				table.insert(text, GetLocalisedText("wantedlevel") .. ": " .. GetPlayerWantedLevel(drawTarget))
				table.insert(text, GetLocalisedText("exitspectator"))

				for i, theText in pairs(text) do
					SetTextFont(0)
					SetTextProportional(1)
					SetTextScale(0.0, 0.30)
					SetTextDropshadow(0, 0, 0, 0, 255)
					SetTextEdge(1, 0, 0, 0, 255)
					SetTextDropShadow()
					SetTextOutline()
					SetTextEntry("STRING")
					AddTextComponentString(theText)
					EndTextCommandDisplayText(0.3, 0.7 + (i / 30))
				end
			elseif (RedM) then
				local targetGod = GetPlayerInvincible(drawTarget)
				if targetGod then
					table.insert(text, GetLocalisedText("godmodedetected"))
				else
					table.insert(text, GetLocalisedText("godmodenotdetected"))
				end

				table.insert(text,
					GetLocalisedText("health") .. ": " .. GetEntityHealth(targetPed) ..
					"/" .. GetEntityMaxHealth(targetPed))
				table.insert(text, GetLocalisedText("exitspectator"))

				for i, theText in pairs(text) do
					Citizen.InvokeNative(0xADA9255D, 0)
					SetTextScale(0.0, 0.30)
					SetTextDropshadow(0, 0, 0, 0, 255)

					local str = CreateVarString(10, "LITERAL_STRING", Text)
					DisplayText(theText, 0.3, 0.7 + (i / 30))
				end
			end

			if (not RedM and IsControlJustPressed(0, 103) or (RedM and IsControlJustReleased(0, Controls["Enter"]))) then
				local targetPed = PlayerPedId()
				local targetPlayer = -1
				local targetx, targety, targetz = table.unpack(GetEntityCoords(targetPed, false))
				spectatePlayer(targetPed, targetPlayer, GetPlayerName(targetPlayer))
				TriggerEvent('EasyAdmin:FreezePlayer', false)
				--SetEntityCoords(PlayerPedId(), oldCoords.x, oldCoords.y, oldCoords.z, 0, 0, 0, false)
				if not RedM then
					TriggerEvent('EasyAdmin:FreezePlayer', false)
				end

				StopDrawPlayerInfo()
				TriggerEvent("ox_lib:notify", {
					title = "Spectating Stopped", -- You can change the title
					description = GetLocalisedText("stoppedSpectating"),
					type = "info"  -- Adjust the type as needed, e.g., "success", "error", "info"
				})

				TriggerServerEvent("EasyAdmin:resetBucket", MyBucket)
			end
		end
	end)

	CreateThread(function()
		while drawInfo do
			Wait(5000)

			local targetPed = GetPlayerPed(drawTarget)
			if not DoesEntityExist(targetPed) and drawServerId ~= 0 then
				-- player no longer exists, lets contact the server to see if they changed bucket?
				TriggerServerEvent("EasyAdmin:requestBucket", drawServerId)
			end
		end
	end)
end
