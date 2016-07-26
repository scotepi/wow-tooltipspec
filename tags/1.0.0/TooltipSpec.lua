--[[


]]

-- Start the Addon
TTS = {}
TTS.cache = {}
TTS.events = {}
TTS.frame = CreateFrame("Frame", "TTSFrame")
TTS.inspect = LibStub:GetLibrary("LibInspect")

function TTS:OnInitialize()
    self:Print('Tooltip Spec Loaded...')
    
    -- Add the hooks
    self.inspect:AddHook('TooltipSpec', 'talents', function(...) TTS:InspectReturn(...) end);
    GameTooltip:HookScript("OnTooltipSetUnit", function(...) TTS:ShowTooltip(); end);
    
    -- Register more events
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function() TTS:Inspect('target') end);
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() TTS:ShowTooltip(); end);
	
	-- SlashHandler
	SLASH_TOOLTIPSPEC1 = '/tts';
	SLASH_TOOLTIPSPEC2 = '/ttspec';
	SLASH_TOOLTIPSPEC3 = '/tooltipspec';
	function SlashCmdList.TOOLTIPSPEC(msg, editbox)
		TTS:SlashHandler(msg, editbox);
	end
	
	-- Initalize Settings
	if not TTS_Settings then
		self:ResetSettings();
	end
end

function TTS:ResetSettings()
	TTS_Settings = {
		nameRole = true,
		nameSpec = true,
		showSpec = false,
		debug = false,
		settingVer = 1,
	};
end

function TTS:Inspect(target)
    if not CanInspect(target) then return false end
    
    local guid = UnitGUID(target)
    
    if not self.cache[guid] then
        local classDisplayName, class, classID = UnitClass(target)
        local name, realm = UnitName(target)
        
        self.cache[guid] = {
            name = name,
            realm = realm,
            class = class,
            className = classDisplayName,
            classID = classID,
        }
    end
    
    self.cache[guid].target = target;
    
    self:Debug('Requesting Talents for', target, UnitName(target), guid);
    self.inspect:RequestTalents(target);
end

function TTS:InspectReturn(guid, data, age)
    if data.talents and type(data.talents) == 'table' and self.cache[guid] then
        self.cache[guid].talents = data.talents;
        self:ShowTooltip();
    end
end

function TTS:TooltipHook()
	local name, unit = GameTooltip:GetUnit();
	local guid = false;
	
	if unit then
		guid = UnitGUID(unit);
	elseif name then
		guid = self:NameToGUID(name);
	end
	
	if tonumber(guid) and tonumber(guid) > 0 then
		self:ShowTooltip(guid);
    end
end

function TTS:NameToGUID(name, realm)
	if not name then return false end
	
	-- Try and get the realm from the name-realm
	if not realm then
		name, realm = strsplit('-', name, 2);
	end
	
	-- If no realm then set it to current realm
	if not realm or realm == '' then
		realm = GetRealmName();
	end
	
	if name then
		name = strlower(name);
		local likely = false;
        
		for guid,info in pairs(self.cache) do
			if strlower(info.name) == name and info.realm == realm then
				return guid;
            elseif strlower(info.name) == name then
                likely = guid;
            end
		end
        
        if likely then
            return likely;
        end
	end
	
	return false;
end

function TTS:ShowTooltip(guid)
    if not guid then
        guid = UnitGUID('mouseover')
    end
    
    -- print(guid);
    
    -- error out
    if not guid then return false end
    if not self.cache[guid] then return false end
    if not self.cache[guid].talents then return false end
    
    -- /dump TTS.cache[UnitGUID('target')]
    -- /dump TTS.inspect.cache[UnitGUID('target')].data.talents
    local spec = self.cache[guid].talents
    
    -- print(spec.name)
    
    local specColor = 'B0D2FF'
    local roleIcon = INLINE_DAMAGER_ICON
    
    if spec.role == 'TANK' then
        specColor = 'FF8A9D'
        roleIcon = INLINE_TANK_ICON
    elseif spec.role == 'HEALER' then
        specColor = 'FFF4B0'
        roleIcon = INLINE_HEALER_ICON
    end
    
    local _, fontSize = FCF_GetChatWindowInfo(1);
    
    if not spec.icon then return false end
    
    local specIcon = '|T'..spec.icon..':'..fontSize..'|t'
    local specName = '|cFF'..specColor..spec.name..'|r'
    
    local textLeft = specIcon..' '..specName
    local textRight = false -- Nothing Yet
    
    -- Put the role on the added line if its not in the name
    if not self:GetNameRole() then
        textLeft = roleIcon..' '..textLeft
    end
    
    local ttLines = GameTooltip:NumLines()
	local ttUpdated = false;
	
	for i = 1,ttLines do
        
        -- If the static text matches
		if _G["GameTooltipTextLeft"..i]:GetText() == textLeft then
            
            self:TooltipAppendName(roleIcon, spec.icon)
            
            -- Update the text
            if self:GetShowSpec() then
                _G["GameTooltipTextLeft"..i]:SetText(textLeft)
                GameTooltip:Show()
            end
            
            ttUpdated = true
        end
    end
    
    if not ttUpdated then
        self:TooltipAppendName(roleIcon, spec.icon)
        
        if self:GetShowSpec() then
            GameTooltip:AddLine(textLeft)
            GameTooltip:Show()
        end
    end
end

function TTS:TooltipAppendName(roleIcon, specIcon)
    local currentText = _G["GameTooltipTextLeft1"]:GetText()
    if not currentText then return false end
    
    local appendText = ''
    
    -- Add the role
    if self:GetNameRole() then
        appendText = appendText..roleIcon..' '
    end
    
    -- Add the spec
    if self:GetNameSpec() then
        local fontName, fontHeight, fontFlags = _G["GameTooltipTextLeft1"]:GetFont()
        appendText = appendText..'|T'..specIcon..':'..fontHeight..'|t '
    end
    
    -- Check that its not alredy there
    local length = string.len(appendText);
    if string.sub(currentText, 0, length) == appendText then return true end
    
    -- Add the icon
    _G["GameTooltipTextLeft1"]:SetText(appendText..currentText)
    GameTooltip:Show()
end





--[[ Setters / Getters / Togglers ]]
function TTS:SetDebug(v) TTS_Settings.debug = v end
function TTS:SetNameRole(v) TTS_Settings.nameRole = v end
function TTS:SetNameSpec(v) TTS_Settings.nameSpec = v end
function TTS:SetShowSpec(v) TTS_Settings.showSpec = v end

function TTS:GetDebug() return TTS_Settings.debug end
function TTS:GetNameRole() return TTS_Settings.nameRole end
function TTS:GetNameSpec() return TTS_Settings.nameSpec end
function TTS:GetShowSpec() return TTS_Settings.showSpec end

function TTS:ToggleDebug() self:SetDebug(not self:GetDebug()) end
function TTS:ToggleNameRole() self:SetNameRole(not self:GetNameRole()) end
function TTS:ToggleNameSpec() self:SetNameRole(not self:GetNameSpec()) end
function TTS:ToggleShowSpec() self:SetShowSpec(not self:GetShowSpec()) end


--[[ Handle the slash command ]]
function TTS:SlashHandler(msg, editbox)
	local cmd, rest = msg:match("^(%S*)%s*(.-)$");
	
	if cmd == "role" then
		self:ToggleNameRole();
		self:Print("Setting role next to the player name,", self:GetNameRole());
	elseif cmd == "spec" then
		self:ToggleNameSpec();
		self:Print("Setting spec next to the player name,", self:GetNameSpec());
	elseif cmd == "name" then
		self:ToggleShowSpec();
		self:Print("Showing the spec on the tooltip,", self:GetShowSpec());
	elseif cmd == "reset" then
		self:Print("Resetting all settings");
		self:ResetSettings();
	else
		self:Print('Syntax: /tts (role|spec|name|reset)');
		self:Print('/tts role, Show the role next to the name,', self:GetNameRole());
		self:Print('/tts spec, Show the spec next to the name,', self:GetNameSpec());
		self:Print('/tts name, Show the spec on the last line,', self:GetShowSpec());
		self:Print('/tts reset, Reset settings to default');
	end
	self:Debug(cmd, rest);
	
end

--[[ Ace3 Link functions ]]
function TTS:RegisterEvent(event, callback)
    self.events[event] = callback
    self.frame:RegisterEvent(event)
end

function TTS:OnEvent(event, ...)
    if type(self.events[event]) == 'function' then
        self.events[event](...);
    else
        self:Debug('No Callback for', event, ...)
    end
end

function TTS:Print(...) print('|cFF3079EDTTS:|r ', ...); end
function TTS:Debug(...) if self:GetDebug() then print('|cFFFF0000TTS Debug:|r ', ...); end end

-- Special Functions
local function OnEvent(self, ...) TTS:OnEvent(...) end

-- Register handlers
TTS.frame:SetScript("OnEvent", OnEvent);
TTS:RegisterEvent("PLAYER_LOGIN", function() TTS:OnInitialize(); end);