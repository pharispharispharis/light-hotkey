--[[

Mod: Light Hotkey - OpenMW Lua
Author: Pharis

--]]

local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')

-- Mod info
local modInfo = require('Scripts.Pharis.LightHotkey.modInfo')
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Settings
local playerSettings = storage.playerSection('SettingsPlayer' .. modName)

-- Other Variables
local Player = types.Player
local Armor = types.Armor
local Light = types.Light

local playerInventory = Player.inventory(self)
local carriedLeft = Player.EQUIPMENT_SLOT.CarriedLeft
local lastShield
local preferredLight

local function debugMessage(msg)
	if not playerSettings:get('showDebug') then return end

	print("[" .. modName .. "]", string.format(msg, _))
end

local function getFirstLight()
	for _, object in ipairs(playerInventory:getAll(Light)) do
		return object
	end
end

local function equip(slot, object)
    local playerEquipment = Player.equipment(self)
    playerEquipment[slot] = object
    Player.setEquipment(self, playerEquipment)
end

local function lightSwap(key)
	if key.code ~= playerSettings:get('lightHotkey') then return end

	if not playerSettings:get('modEnable') then return end

	if core.isWorldPaused() then return end

	local playerEquipment = Player.equipment(self)

	-- If any light equipped
	local equippedLight = playerEquipment[carriedLeft]
	if equippedLight and Light.objectIsInstance(equippedLight) then
		-- Set/clear preferred light if alt is held when hotkey is pressed
		if key.withAlt then
			if preferredLight == equippedLight.recordId then
				preferredLight = nil
				ui.showMessage("Cleared preferred light.")
				return
			end

			preferredLight = equippedLight.recordId
			ui.showMessage("Set preferred light.")
			return
		end

		-- Unequip light
		equip(carriedLeft, nil)

		-- Equip stored shield if any
		if lastShield and playerInventory:countOf(lastShield) >= 1 then
			equip(carriedLeft, lastShield)
		end

		return
	end

	-- If no light Equipped
	local firstLight = getFirstLight()
	if firstLight then
		firstLight = firstLight.recordId
		lastShield = nil

		-- Store currently equipped shield if any
		local equippedShield = playerEquipment[carriedLeft]
		if equippedShield and Armor.objectIsInstance(equippedShield) then
			lastShield = equippedShield.recordId
			debugMessage("Shield saved: " .. lastShield)
		end

		-- Equip light
		if preferredLight and playerInventory:countOf(preferredLight) >= 1 then
			equip(carriedLeft, preferredLight)
			debugMessage("Preferred light equipped")
		else
			equip(carriedLeft, firstLight)
			debugMessage("No preferred light found, equipping first light")
		end

		return
	end

	ui.showMessage("I'm not carrying any lights.")
end

local function onSave()
	return {
		lastShield = lastShield,
		preferredLight = preferredLight
	}
end

local function onLoad()
	-- data can potentially be nil, throws error
	if not data then return end

	lastShield = data.lastShield
	preferredLight = data.preferredLight
	debugMessage("Loaded saved shield: " .. lastShield)
	debugMessage("Loaded preferred light: " .. preferredLight)
end

return {
	engineHandlers = {
		onKeyPress = lightSwap,
		onLoad = onLoad,
		onSave = onSave,
	}
}
