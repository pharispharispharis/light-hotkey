--[[

Mod: Light Hotkey
Author: Pharis

--]]

local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")

local modInfo = require("Scripts.Pharis.LightHotkey.modInfo")

local playerSettings = storage.playerSection("SettingsPlayer" .. modInfo.name)
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")
local controlsSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Controls")
local gameplaySettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Gameplay")

local Actor = types.Actor
local Armor = types.Armor
local Light = types.Light
local Weapon = types.Weapon

local playerInventory = Actor.inventory(self)
local carriedLeft = Actor.EQUIPMENT_SLOT.CarriedLeft
local carriedRight = Actor.EQUIPMENT_SLOT.CarriedRight

local lastShield
local preferredLight

local weaponTypesTwoHanded = {
	[Weapon.TYPE.LongBladeTwoHand] = true,
	[Weapon.TYPE.BluntTwoClose] = true,
	[Weapon.TYPE.BluntTwoWide] = true,
	[Weapon.TYPE.SpearTwoWide] = true,
	[Weapon.TYPE.AxeTwoHand] = true,
	[Weapon.TYPE.MarksmanBow] = true,
	[Weapon.TYPE.MarksmanCrossbow] = true,
}

local function message(msg, _)
	if (not userInterfaceSettings:get("showMessages")) then return end
	ui.showMessage(string.format(msg, _))
end

local function isTwoHanded(weapon)
	return (weapon)
		and (Weapon.objectIsInstance(weapon))
		and (weaponTypesTwoHanded[Weapon.record(weapon).type])
end

local function getFirstLight()
	for _, light in ipairs(playerInventory:getAll(Light)) do
		if (Light.record(light).isCarriable) then return light end
	end
end

local function equip(slot, object)
    local equipment = Actor.equipment(self)
    equipment[slot] = object
    Actor.setEquipment(self, equipment)
end

local function onKeyPress(key)
	if (not playerSettings:get("modEnable"))
		or (key.code ~= controlsSettings:get("lightHotkey"))
		or (core.isWorldPaused()) then return end

	local equipment = Actor.equipment(self)

	-- If any light equipped
	local equippedLight = equipment[carriedLeft]
	if (equippedLight) and (Light.objectIsInstance(equippedLight)) then
		-- Set/clear preferred light if alt is held when hotkey is pressed
		if (key.withAlt) then
			if (preferredLight == equippedLight.recordId) then
				preferredLight = nil
				message("Cleared preferred light.")
				return
			end

			preferredLight = equippedLight.recordId
			message("Set preferred light.")
			return
		end

		-- Unequip light
		equip(carriedLeft, nil)

		-- Equip stored shield if any
		if (lastShield) and (playerInventory:countOf(lastShield) >= 1) then
			equip(carriedLeft, lastShield)
		end

		return
	end

	-- If no light Equipped
	local firstLight = getFirstLight()
	if (firstLight) then
		firstLight = firstLight.recordId
		lastShield = nil

		-- Store currently equipped shield if any
		local equippedShield = equipment[carriedLeft]
		if (equippedShield) and (Armor.objectIsInstance(equippedShield)) then
			lastShield = equippedShield.recordId
		end

		-- Equip light
		if (preferredLight) and (playerInventory:countOf(preferredLight) >= 1) then
			equip(carriedLeft, preferredLight)
		else
			equip(carriedLeft, firstLight)
		end

		if (gameplaySettings:get("lowerTwoHandedWeapon")) then
			local equippedWeapon = equipment[carriedRight]
			if (isTwoHanded(equippedWeapon)) then
				Actor.setStance(self, Actor.STANCE.Nothing)
			end
		end

		return
	end

	message("I'm not carrying any lights.")
end

local function onSave()
	return {
		lastShield = lastShield,
		preferredLight = preferredLight
	}
end

local function onLoad(data)
	if (not data) then return end
	lastShield = data.lastShield
	preferredLight = data.preferredLight
end

return {
	engineHandlers = {
		onKeyPress = onKeyPress,
		onSave = onSave,
		onLoad = onLoad,
	}
}
