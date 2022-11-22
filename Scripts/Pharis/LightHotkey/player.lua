--[[
Mod: Light Hotkey - OpenMW Lua
Author: Pharis
--]]

local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')
local interface = require('openmw.interfaces')
local storage = require('openmw.storage')

local Actor = types.Actor
local Armor = types.Armor
local Light = types.Light

local actorInventory = Actor.inventory(self)
local carriedLeft = Actor.EQUIPMENT_SLOT.CarriedLeft
local carriedRight = Actor.EQUIPMENT_SLOT.CarriedRight

local lastShield
local lastWeapon

local modName = "lightHotkey"
local playerSettings = storage.playerSection('SettingsPlayer' .. modName)
local modEnableConfDesc = "Enable Mod"
local showDebugConfDesc = "Show Debug Messages"
local swapLightHotkey = key.symbol.c

----------------------------------------------------------------------
local function setting(key, renderer, argument, name, description, default)
	return {
		key = key,
		renderer = renderer,
		argument = argument,
		name = name,
		description = description,
		default = default,
	}
end

interface.Settings.registerPage {
	key = modName,
	l10n = modName,
	name = "Light Hotkey",
	description = "Equip light with hotkey; automatically re-equip shield when light is unequipped."
}

interface.Settings.registerGroup {
	key = 'SettingsPlayer' .. modName,
	page = modName,
	l10n = modName,
	name = "Player Settings",
	permanentStorage = false,
	settings = {
		setting('modEnableConf', 'checkbox', {}, "test name", modEnableConfDesc, true),
		setting('showDebugConf', 'checkbox', {}, "", showDebugConfDesc, false),
	}
}
----------------------------------------------------------------------

local function debugMessage(msg)
	-- If debug messages disabled do nothing
	if not playerSettings:get('showDebugConf') then return end

	if msg == 'load' then
		ui.printToConsole("[" .. modName .. "] " .. "Loaded.", ui.CONSOLE_COLOR.Default)
		if not lastShield then return end
		ui.printToConsole("[" .. modName .. "] " .. "Loaded saved shield: " .. lastShield, ui.CONSOLE_COLOR.Default)
	elseif msg == 'shieldSave' then
		ui.printToConsole("[" .. modName .. "] " .. "Shield saved.", ui.CONSOLE_COLOR.Default)
	elseif msg == 'equipLight' then
		ui.printToConsole("[" .. modName .. "] " .. "light equipped.", ui.CONSOLE_COLOR.Default)
	elseif msg == 'unequipLight' then
		ui.printToConsole("[" .. modName .. "] " .. "Unequipping Light.", ui.CONSOLE_COLOR.Default)
	end
end

local function unequipLight()
	local equipment = Actor.equipment(self)
	equipment[carriedLeft] = nil
	Actor.setEquipment(self, equipment)
	debugMessage('unequiplight')
end

local function getFirstLight()
	for _, object in ipairs(actorInventory:getAll(Light)) do
			return object
	end
end

local function equip(object, slot)
    local equipment = Actor.equipment(self)
    equipment[Actor.slot] = object
    Actor.setEquipment(self, equipment)
end

local function swap(key)
	-- If incorrect key pressed do nothing
	if key.symbol ~= 'c' then return end

	-- If mod is disabled do nothing
	if not playerSettings:get('modEnableConf') then return end
	
	-- If game is paused do nothing
	if core.isWorldPaused() then return end
	
	local equipment = Actor.equipment(self)
	
	-- Has light equipped
	local carryingLight = equipment[carriedLeft]
	if carryingLight and Light.objectIsInstance(carryingLight) then
		-- Unequip light
		unequipLight()

		-- Equip stored shield if any
		if lastShield then
			equip(carriedLeft, lastShield)
			-- equipment[carriedLeft] = lastShield
			-- Actor.setEquipment(self, equipment)
		end

		return
	end

	-- No light Equipped
	local firstLight = getFirstLight()
	if firstLight then
		lastShield = nil
		
		-- Store currently equipped shield if any
		local equippedShield = Actor.equipment(self, carriedLeft)
		if equippedShield and Armor.objectIsInstance(equippedShield) then
			lastShield = equippedShield
			debugMessage('shieldSave')
		end
		
		-- Equip light
		-- equipment[carriedLeft] = firstLight
		-- Actor.setEquipment(self, equipment)
		equip(carriedLeft, firstLight)
		debugMessage('equipLight')
		ui.showMessage("Equipped light: " .. firstLight.recordId)
		
		return
	end

	ui.showMessage("I'm not carrying any lights.")
end

return {
	engineHandlers = {
		onKeyPress = swap,
		onLoad = function(data)
			lastShield = data
			debugMessage('load')
		end,
		onSave = function()
			if lastShield then
				return lastShield.recordId
			end
		end
	}
}