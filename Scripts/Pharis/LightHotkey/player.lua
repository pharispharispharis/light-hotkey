--[[

Mod: Light Hotkey
Author: Pharis

--]]

local aux_util = require("openmw_aux.util")
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
local Item = types.Item
local Light = types.Light
local Weapon = types.Weapon

local SLOT_CARRIED_LEFT = Actor.EQUIPMENT_SLOT.CarriedLeft
local SLOT_CARRIED_RIGHT = Actor.EQUIPMENT_SLOT.CarriedRight

local lastShield
local preferredLight

local WEAPON_TYPES_TWO_HANDED = {
	[Weapon.TYPE.LongBladeTwoHand] = true,
	[Weapon.TYPE.BluntTwoClose] = true,
	[Weapon.TYPE.BluntTwoWide] = true,
	[Weapon.TYPE.SpearTwoWide] = true,
	[Weapon.TYPE.AxeTwoHand] = true,
	[Weapon.TYPE.MarksmanBow] = true,
	[Weapon.TYPE.MarksmanCrossbow] = true,
}

local function message(msg, _)
	if (userInterfaceSettings:get("showMessages")) then ui.showMessage(msg) end
end

local function isTwoHanded(weapon)
	return (weapon)
		and (Weapon.objectIsInstance(weapon))
		and (WEAPON_TYPES_TWO_HANDED[Weapon.record(weapon).type])
end

local function getLight()
	local lights = Actor.inventory(self):getAll(Light);
	if (#lights == 0) then return nil; end;
	lights, _ = aux_util.mapFilterSort(
		lights,
		function (light)
			if (not Light.record(light).isCarriable) then return nil; end;
			local condition = Item.itemData(light).condition;
			if (condition == 0) then return nil; end;
			return (condition > 0) and condition or 2147483647;
		end
	);
	return lights[(gameplaySettings:get("lightUseOrder") == "ascending") and 1 or #lights];
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
	local carriedLeft = equipment[SLOT_CARRIED_LEFT]
	if (carriedLeft) and (Light.objectIsInstance(carriedLeft)) then
		-- Set/clear preferred light if alt is held when hotkey is pressed
		if (key.withAlt) then
			preferredLight = (preferredLight ~= carriedLeft) and carriedLeft or nil
			message((preferredLight) and "Set preferred light." or "Cleared preferred light.")
			return
		end

		-- Either un-equip light or switch to last shield
		equip(SLOT_CARRIED_LEFT, (lastShield and lastShield.count > 0) and lastShield or nil)
		return
	end

	-- If no light Equipped
	local firstLight = getLight()
	if (firstLight) then
		-- Store currently equipped shield if any
		lastShield = (carriedLeft and Armor.objectIsInstance(carriedLeft)) and carriedLeft or nil

		-- Equip light
		equip(SLOT_CARRIED_LEFT, (preferredLight and preferredLight.count > 0) and preferredLight or firstLight)

		if (gameplaySettings:get("lowerTwoHandedWeapon")) then
			local carriedRight = equipment[SLOT_CARRIED_RIGHT]
			if (isTwoHanded(carriedRight)) then Actor.setStance(self, Actor.STANCE.Nothing) end
		end
	else
		message("I'm not carrying any lights.")
	end
end

-- Temporary hack because saved objects can't be used after load for some reason
local function findObjectStringMatch(objectString)
	for _, object in ipairs(Actor.inventory(self):getAll()) do
		if (tostring(object) == objectString) then return object end
	end
end

local function onSave()
	return {
		lastShield = tostring(lastShield),
		preferredLight = tostring(preferredLight)
	}
end

local function onLoad(data)
	if (not data) then return end
	lastShield = findObjectStringMatch(data.lastShield)
	preferredLight = findObjectStringMatch(data.preferredLight)
end

return {
	engineHandlers = {
		onKeyPress = onKeyPress,
		onSave = onSave,
		onLoad = onLoad,
	}
}
