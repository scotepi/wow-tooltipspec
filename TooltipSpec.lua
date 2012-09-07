--[[


]]

-- Start the Addon
TTS = {}
TTS.cache = {}
TTS.events = {}
TTS.frame = CreateFrame("Frame", "GMIFrame")
TTS.inspect = LibStub:GetLibrary("LibInspect")
TTS.nameRole = true;        -- Show the role next to the name
TTS.showSpec = true;        -- Show the spec on the last line
TTS.debug = false;

function TTS:OnInitialize()
    self:Print('Tooltip Spec Loaded...')
    
    -- Add the hooks
    self.inspect:AddHook('TooltipSpec', 'talents', function(...) TTS:InspectReturn(...) end);
    GameTooltip:HookScript("OnTooltipSetUnit", function(...) TTS:ShowTooltip(); end);
    
    -- Register more events
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function() TTS:Inspect('target') end);
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() TTS:ShowTooltip(); end);
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
        guid = UnitGUID('mouseover');
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
    
    local specColor = 'FFFFFF'
    local roleIcon = INLINE_DAMAGER_ICON
    
    if spec.role == 'TANK' then
        specColor = 'FF8A9D'
        roleIcon = INLINE_TANK_ICON
    elseif spec.role == 'HEALER' then
        specColor = 'FFF4B0'
        roleIcon = INLINE_HEALER_ICON
    elseif spec.role == 'DAMAGER' then
        specColor = 'B0D2FF';
    end
    
    local _, fontSize = FCF_GetChatWindowInfo(1);
    
    local textLeft = '|T'..spec.icon..':'..fontSize..'|t';
    local textRight = '|cFF'..specColor..spec.name..'|r';
    textLeft = textLeft..' '..textRight;
    
    if not self:GetNameRole() then
        textLeft = roleIcon..' '..textLeft;
    end
    
    local ttLines = GameTooltip:NumLines();
	local ttUpdated = false;
	
	for i = 1,ttLines do
        -- /run _G["GameTooltipTextLeft1"]:SetText("foo"); GameTooltip:Show();
        -- If the static text matches
		if _G["GameTooltipTextLeft"..i]:GetText() == textLeft then
            
            if self:GetNameRole() then
                _G["GameTooltipTextLeft1"]:SetText(roleIcon..' '.._G["GameTooltipTextLeft1"]:GetText());
            end
            
            if self:GetShowSpec() then
                -- Update the text
                _G["GameTooltipTextLeft"..i]:SetText(textLeft);
                --_G["GameTooltipTextRight"..i]:SetText(textRight);
            end
            
			GameTooltip:Show();
            ttUpdated = true;
        end
    end
    
    if not ttUpdated then
        
        if self:GetNameRole() then
            _G["GameTooltipTextLeft1"]:SetText(roleIcon..' '.._G["GameTooltipTextLeft1"]:GetText());
        end
        
        if self:GetShowSpec() then
            --GameTooltip:AddDoubleLine(textLeft, textRight);
            GameTooltip:AddLine(textLeft);
        end
        
		GameTooltip:Show();
    end
end







--[[ Setters / Getters / Togglers ]]
function TTS:SetDebug(v) self.debug = v end
function TTS:SetNameRole(v) self.nameRole = v end
function TTS:SetShowSpec(v) self.showSpec = v end

function TTS:GetDebug() return self.debug end
function TTS:GetNameRole() return self.nameRole end
function TTS:GetShowSpec() return self.showSpec end

function TTS:ToggleDebug() self:SetDebug(not self:GetDebug()) end
function TTS:ToggleNameRole() self:SetNameRole(not self:GetNameRole()) end
function TTS:ToggleShowSpec() self:SetShowSpec(not self:GetShowSpec()) end





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