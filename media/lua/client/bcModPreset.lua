require 'OptionScreen/ModSelector'
require 'bcutils'

BCModPreset = {};
BCModPreset.savefile = "mod_presets.txt";
BCModPreset.OSMScreate = ModSelector.create;

function BCModPreset.inputModal(_centered, _width, _height, _posX, _posY, _onclick, target, param1, param2) -- {{{
	-- based on luautils.okModal
	local posX = _posX or 0;
	local posY = _posY or 0;
	local width = _width or 230;
	local height = _height or 120;
	local centered = _centered;
	local txt = _text;
	local core = getCore();

	-- center the modal if necessary
	if centered then
		posX = core:getScreenWidth() * 0.5 - width * 0.5;
		posY = core:getScreenHeight() * 0.5 - height * 0.5;
	end

	-- ISModalDialog:new(x, y, width, height, text, yesno, target, onclick, player, param1, param2)
	local modal = ISTextBox:new(posX, posY, width, height, getText("UI_characreation_BuildSavePrompt"), "", target, _onclick, param1, param2);
	modal:initialise();
	modal:setAlwaysOnTop(true)
	modal:setCapture(true)
	modal:addToUIManager();
	modal.yes:setTitle(getText("UI_btn_save"))

	return modal;
end
-- }}}
function BCModPreset.readSaveFile() -- {{{
	local retVal = {};

	local saveFile = getFileReader(BCModPreset.savefile, true);
	local line = saveFile:readLine();
	while line ~= nil do
		local s = luautils.split(line, ":");
		retVal[s[1]] = s[2];
		line = saveFile:readLine();
	end
	saveFile:close();

	return retVal;
end
-- }}}
function BCModPreset.writeSaveFile(options) -- {{{
	local saved_presets = getFileWriter(BCModPreset.savefile, true, false); -- overwrite
	for key,val in pairs(options) do
		saved_presets:write(key..":"..val.."\n");
	end
	saved_presets:close();
end
-- }}}
function BCModPreset.loadPreset(self, box) -- {{{
	local mods = getActivatedMods();
	for i=mods:size()-1,0,-1 do
		toggleModActive(getModInfoByID(mods:get(i)), false);
	end

	local preset = box.options[box.selected];
	if preset == nil then return end;

	local saved_presets = BCModPreset.readSaveFile();
	local build = saved_presets[preset];

	if build == nil then return end;

	local failed_mods = "";
	local count_fail = 0;
	local active_mods = luautils.split(build, ";");
	for i=1,#active_mods do
		local modInfo = getModInfoByID(active_mods[i]);
		if not modInfo then
			count_fail = count_fail + 1;
			failed_mods = failed_mods .. active_mods[i] .. ", "
		else
			toggleModActive(getModInfoByID(active_mods[i]), true);
		end
	end
	saveModsFile();

	if count_fail > 0 then
		luautils.okModal("Mods failed to load: "..count_fail.."\n\n"..failed_mods, true);
	end
end
-- }}}
ModSelector.create = function(self) -- {{{
	BCModPreset.OSMScreate(self);
	local pb = self.playButton;

	self.savedPresets = ISComboBox:new(pb:getRight()+16, pb:getY(), 250, pb:getHeight(), self, BCModPreset.loadPreset);
	self.savedPresets:setAnchorTop(false);
	self.savedPresets:setAnchorBottom(true);
	self.savedPresets.openUpwards = true;
	self:addChild(self.savedPresets)

	self.savedPresets:addOption(getText("UI_characreation_SelectToLoad"))
	local saved_presets = BCModPreset.readSaveFile();
	for key,val in pairs(saved_presets) do
		self.savedPresets:addOption(key)
	end

	self.saveBuildButton = ISButton:new(self.savedPresets:getRight() + 10, pb:getY(), 50, 25, "Save this preset", self, self.saveBuildStep1);
	self.saveBuildButton:initialise();
	self.saveBuildButton:instantiate();
	self.saveBuildButton:setAnchorLeft(true);
	self.saveBuildButton:setAnchorRight(false);
	self.saveBuildButton:setAnchorTop(false);
	self.saveBuildButton:setAnchorBottom(true);
	self.saveBuildButton.borderColor = { r = 1, g = 1, b = 1, a = 0.1 };
	self:addChild(self.saveBuildButton);
end
-- }}}
function ModSelector:saveBuildValidate(text) -- {{{
	return text ~= "" and not text:contains("/") and not text:contains("\\") and
		not text:contains(":") and not text:contains(";") and not text:contains('"')
end
-- }}}
function ModSelector.inputModal(_centered, _width, _height, _posX, _posY, _onclick, target, param1, param2) -- {{{
	-- based on luautils.okModal
	local posX = _posX or 0;
	local posY = _posY or 0;
	local width = _width or 230;
	local height = _height or 120;
	local centered = _centered;
	local txt = _text;
	local core = getCore();
  
	-- center the modal if necessary
	if centered then
		posX = core:getScreenWidth() * 0.5 - width * 0.5;
		posY = core:getScreenHeight() * 0.5 - height * 0.5;
	end
  
	-- ISModalDialog:new(x, y, width, height, text, yesno, target, onclick, player, param1, param2)
	local modal = ISTextBox:new(posX, posY, width, height, "Save this mod selection", "", target, _onclick, param1, param2);
	modal:initialise();
	modal:setAlwaysOnTop(true)
	modal:setCapture(true)
	modal:addToUIManager();
	modal.yes:setTitle(getText("UI_btn_save"))

	return modal;
end
-- }}}
function ModSelector:saveBuildStep1() -- {{{
	self.inputModal = BCModPreset.inputModal(true, nil, nil, nil, nil, self.saveBuildStep2, self);
	self.inputModal.backgroundColor.a = 0.9
	self.inputModal:setValidateFunction(self, self.saveBuildValidate)
end
-- }}}
function ModSelector:saveBuildStep2(button, joypadData, param2) -- {{{
	if joypadData then
		joypadData.focus = self.presetPanel
		updateJoypadFocus(joypadData)
	end

	if button.internal == "CANCEL" then
		return
	end

	local builds = BCModPreset.readSaveFile();

	savestring = "";
	local mods = getActivatedMods();
	for i=0,mods:size()-1 do
		savestring = savestring..mods:get(i)..";"
	end

	local savename = button.parent.entry:getText()
	if savename == '' then return end
	builds[savename] = savestring;

	local options = {};
	options[getText("UI_characreation_SelectToLoad")] = 1;
	BCModPreset.writeSaveFile(builds);
	for key,val in pairs(builds) do
		options[key] = 1;
	end

	self.savedPresets.options = {};
	local i = 1;
	for key,val in pairs(options) do
		table.insert(self.savedPresets.options, key);
		if key == savename then
			self.savedPresets.selected = i;
		end
		i = i + 1;
	end
end
-- }}}
