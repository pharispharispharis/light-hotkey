--[[

Mod: Light Hotkey - OpenMW Lua
Author: Pharis

--]]

local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local storage = require('openmw.storage')
local ui = require('openmw.ui')

-- Mod info
local modInfo = require('Scripts.Pharis.LightHotkey.modInfo')
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- General settings description(s)
local modEnableConfDesc = "To mod or not to mod."
local logDebugConfDesc = "Press F10 to see logged messages in-game."
local modHotkeyConfDesc = "Choose which key equips a light; picking \'alt\' isn't recommended as preferred light is set with \'alt > hotkey\'."

-- Other variables
local playerSettings = storage.playerSection('SettingsPlayer' .. modName)

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

local function initSettings()
	I.Settings.registerRenderer('inputKeySelection', function(value, set)
		local name = "No Key Set"
		if value then
			if value == input.KEY.Escape then
				name = input.getKeyName(playerSettings:get('modHotkeyConf'))
			else
				name = input.getKeyName(value)
			end
		end
		return {
			template = I.MWUI.templates.box,
			content = ui.content {
				{
					template = I.MWUI.templates.padding,
					content = ui.content {
						{
							template = I.MWUI.templates.textEditLine,
							props = {
								text = name,
							},
							events = {
								keyPress = async:callback(function(e)
									if e.code == input.KEY.Escape then return end
									set(e.code)
								end),
							},
						},
					},
				},
			},
		}
end)

	I.Settings.registerPage {
		key = modName,
		l10n = modName,
		name = "Light Hotkey",
		description = "By Pharis\n\nEquip light with hotkey; automatically re-equip shield when light is unequipped."
	}

	I.Settings.registerGroup {
		key = 'SettingsPlayer' .. modName,
		page = modName,
		l10n = modName,
		name = "General Settings",
		permanentStorage = false,
		settings = {
			setting('modEnableConf', 'checkbox', {}, "Enable Mod", modEnableConfDesc, true),
			setting('showDebugConf', 'checkbox', {}, "Log Debug Messages", logDebugConfDesc, false),
			setting('modHotkeyConf', 'inputKeySelection', {}, "Light Hotkey", modHotkeyConfDesc, input.KEY.C),
		}
	}

	print("[" .. modName .. "] Initialized v" .. modVersion)
end

return {
	engineHandlers = {
		onActive = initSettings,
	}
}
