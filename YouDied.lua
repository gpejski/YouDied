local YouDied = CreateFrame("Frame", "YouDiedFrame", UIParent)
YouDied:SetAllPoints()
YouDied:SetFrameStrata("DIALOG")
YouDied:Hide()

-- Background texture (Dark banner)
YouDied.bg = YouDied:CreateTexture(nil, "BACKGROUND")
YouDied.bg:SetColorTexture(0, 0, 0, 0.75)

-- Title
YouDied.title = YouDied:CreateFontString(nil, "OVERLAY", "SystemFont_Huge1")
local fontPath = YouDied.title:GetFont() or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
YouDied.title:SetFont(fontPath, 84, "OUTLINE")
YouDied.title:SetPoint("CENTER", YouDied, "CENTER", 0, 150)
YouDied.title:SetText("YOU DIED")
YouDied.title:SetTextColor(0.7, 0.0, 0.0) -- Dark Red
YouDied.title:SetShadowColor(0, 0, 0, 1)
YouDied.title:SetShadowOffset(3, -3)

-- Subtitle
YouDied.subTitle = YouDied:CreateFontString(nil, "OVERLAY", "GameFontNormal")
YouDied.subTitle:SetPoint("TOP", YouDied.title, "BOTTOM", 0, -20)
YouDied.subTitle:SetText("Available life-savers:")

YouDied.rows = {}

local function GetOrCreateRow(index)
    if not YouDied.rows[index] then
        local row = CreateFrame("Frame", nil, YouDied)
        row:SetSize(260, 40)
        if index == 1 then
            row:SetPoint("TOP", YouDied.subTitle, "BOTTOM", 0, -20)
        else
            row:SetPoint("TOP", YouDied.rows[index-1], "BOTTOM", 0, -10)
        end
        
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("LEFT")
        
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        text:SetPoint("LEFT", icon, "RIGHT", 10, 0)
        
        row.icon = icon
        row.text = text
        
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.spellID then
                GameTooltip:SetSpellByID(self.spellID)
            elseif self.itemID then
                GameTooltip:SetItemByID(self.itemID)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        YouDied.rows[index] = row
    end
    return YouDied.rows[index]
end

local function ClearRows()
    for _, row in pairs(YouDied.rows) do
        row:Hide()
    end
end

local paladinSpells = {
    642,   -- Divine Shield
    633,   -- Lay on Hands
    1022,  -- Blessing of Protection
    31850, -- Ardent Defender
    86659, -- Guardian of Ancient Kings
    498,   -- Divine Protection
    403876,-- Divine Protection (Talent variation)
    184662,-- Shield of Vengeance
}

local healingItems = {
    5512,   -- Healthstone
    211878, -- Algari Healing Potion (Rank 1)
    211879, -- Algari Healing Potion (Rank 2)
    211880, -- Algari Healing Potion (Rank 3)
    212239, -- Fleeting Algari Healing Potion
}

local trackedSpells = {
    [642] = 210,   -- Divine Shield
    [633] = 420,   -- Lay on Hands
    [1022] = 300,  -- Blessing of Protection
    [31850] = 120, -- Ardent Defender
    [86659] = 300, -- Guardian of Ancient Kings
    [498] = 60,    -- Divine Protection
    [403876] = 42, -- Divine Protection (Talented cooldown is usually 42s)
    [184662] = 90, -- Shield of Vengeance
}

local function CheckCooldown(spellID)
    -- Bypass all secure API / secret number restrictions by manually tracking cast times
    local cd = trackedSpells[spellID]
    if not cd then return true end
    
    if not YouDiedDB then return true end
    YouDiedDB.lastCastTimes = YouDiedDB.lastCastTimes or {}
    
    local lastCast = YouDiedDB.lastCastTimes[spellID] or 0
    -- Using time() instead of GetTime() ensures tracking survives /reload and client restarts
    if time() - lastCast < cd then
        return false -- It's still on cooldown!
    end
    
    return true
end

local function IsSpellAvailable(spellID)
    local known = false
    if IsPlayerSpell and IsPlayerSpell(spellID) then
        known = true
    elseif IsSpellKnown and IsSpellKnown(spellID) then
        known = true
    elseif IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellID) then
        known = true
    end
    
    if not known then return false end
    
    return CheckCooldown(spellID)
end

local function IsItemAvailable(itemID)
    if GetItemCount(itemID) == 0 then
        return false
    end
    
    local spellName, spellID = GetItemSpell(itemID)
    if spellID and spellName then
        local cd = 300 -- Potions are 5 mins CD
        if itemID == 5512 then cd = 60 end -- Healthstones are 1 min CD
        
        if YouDiedDB and YouDiedDB.lastCastTimes then
            local lastCast = YouDiedDB.lastCastTimes[spellID]
            
            -- If exact ID wasn't caught, search recent casts for a matching spell name
            if not lastCast then
                for castID, castTime in pairs(YouDiedDB.lastCastTimes) do
                    local castName = nil
                    if C_Spell and C_Spell.GetSpellInfo then
                        local info = C_Spell.GetSpellInfo(castID)
                        if info then castName = info.name end
                    elseif GetSpellInfo then
                        castName = GetSpellInfo(castID)
                    end
                    
                    if castName == spellName then
                        lastCast = castTime
                        YouDiedDB.lastCastTimes[spellID] = castTime -- Cache for next time
                        break
                    end
                end
            end
            
            lastCast = lastCast or 0
            if time() - lastCast < cd then
                return false
            end
        end
    end
    
    return true
end

local function GetSpellDetails(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then return info.name, info.iconID end
    elseif GetSpellInfo then
        local name, _, icon = GetSpellInfo(spellID)
        return name, icon
    end
end

local function AddRow(index, name, icon, spellID, itemID)
    local row = GetOrCreateRow(index)
    row.spellID = spellID
    row.itemID = itemID
    row.text:ClearAllPoints()
    if icon then
        row.icon:SetTexture(icon)
        row.icon:Show()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
    else
        row.icon:Hide()
        row.text:SetPoint("LEFT", row, "LEFT", 10, 0)
    end
    row.text:SetText(name)
    row:Show()
end

local dynamicSpellsResolved = false
local function ResolveDynamicSpells()
    if dynamicSpellsResolved then return end
    dynamicSpellsResolved = true
    
    local baseSpellsToTrack = {498, 184662, 204018, 205191}
    for _, baseID in ipairs(baseSpellsToTrack) do
        local localizedName = nil
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(baseID)
            if info then localizedName = info.name end
        elseif GetSpellInfo then
            localizedName = GetSpellInfo(baseID)
        end
        
        if localizedName then
            local spellID = nil
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(localizedName)
                if info then spellID = info.spellID end
            elseif GetSpellInfo then
                local _, _, _, _, _, _, sID = GetSpellInfo(localizedName)
                spellID = sID
            end
            
            local finalID = spellID or baseID
            if not trackedSpells[finalID] then
                table.insert(paladinSpells, finalID)
                trackedSpells[finalID] = 60 -- Default fallback cooldown
            end
        end
    end
end

local function ResolveDynamicItems()
    local bestPotionID = nil
    local bestPotionILvl = -1
    local hasHealthstone = false
    
    for bag = 0, 4 do
        local slots = 0
        if C_Container and C_Container.GetContainerNumSlots then
            slots = C_Container.GetContainerNumSlots(bag)
        elseif GetContainerNumSlots then
            slots = GetContainerNumSlots(bag)
        end
        
        for slot = 1, slots do
            local itemID = nil
            if C_Container and C_Container.GetContainerItemID then
                itemID = C_Container.GetContainerItemID(bag, slot)
            elseif GetContainerItemID then
                itemID = GetContainerItemID(bag, slot)
            end
            
            if itemID then
                if itemID == 5512 then
                    hasHealthstone = true
                else
                    local itemLevel, classID, subclassID = 0, nil, nil
                    if GetItemInfo then
                        local _, _, _, ilvl, _, _, _, _, _, _, _, cID, scID = GetItemInfo(itemID)
                        itemLevel = ilvl or 0
                        classID = cID
                        subclassID = scID
                    end
                    
                    -- Consumable (0) / Potion (1)
                    if classID == 0 and subclassID == 1 then
                        local isHealingPotion = false
                        if C_TooltipInfo and C_TooltipInfo.GetItemByID then
                            local tooltipData = C_TooltipInfo.GetItemByID(itemID)
                            if tooltipData then
                                for _, line in ipairs(tooltipData.lines) do
                                    if line.leftText and string.find(line.leftText, _G.HEALTH or "Health") then
                                        isHealingPotion = true
                                        break
                                    end
                                end
                            end
                        end
                        
                        if isHealingPotion and itemLevel > bestPotionILvl then
                            bestPotionILvl = itemLevel
                            bestPotionID = itemID
                        end
                    end
                end
            end
        end
    end
    
    for k in pairs(healingItems) do
        healingItems[k] = nil
    end
    
    if hasHealthstone then
        table.insert(healingItems, 5512)
    end
    if bestPotionID then
        table.insert(healingItems, bestPotionID)
    end
end

local function PopulateFrame()
    ResolveDynamicSpells()
    ResolveDynamicItems()
    ClearRows()
    local index = 1
    
    local _, class = UnitClass("player")
    if class == "PALADIN" then
        for _, spellID in ipairs(paladinSpells) do
            if IsSpellAvailable(spellID) then
                local name, icon = GetSpellDetails(spellID)
                if name then
                    AddRow(index, name, icon, spellID, nil)
                    index = index + 1
                end
            end
        end
    end
    
    for _, itemID in ipairs(healingItems) do
        if IsItemAvailable(itemID) then
            local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
            if name then
                AddRow(index, name, icon, nil, itemID)
                index = index + 1
            end
        end
    end
    
    if index == 1 then
        -- No abilities were available
        AddRow(index, "You used all your tools. You died honorably.", nil, nil, nil)
        index = index + 1
    end
    
    -- Adjust banner background to fit dynamically around the content
    local lastRow = YouDied.rows[index - 1]
    YouDied.bg:ClearAllPoints()
    YouDied.bg:SetPoint("LEFT")
    YouDied.bg:SetPoint("RIGHT")
    YouDied.bg:SetPoint("TOP", YouDied.title, "TOP", 0, 60)
    YouDied.bg:SetPoint("BOTTOM", lastRow, "BOTTOM", 0, -40)
end

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "YouDiedOptionsPanel")
    panel.name = "You Died"
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("You Died")
    
    local function CreateCheckbox(name, labelText, dbKey, yOffset)
        local cb = CreateFrame("CheckButton", name, panel, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, yOffset)
        
        local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        text:SetText(labelText)
        
        cb:SetChecked(YouDiedDB[dbKey])
        cb:SetScript("OnClick", function(self)
            YouDiedDB[dbKey] = self:GetChecked()
        end)
        return cb
    end
    
    CreateCheckbox("YouDiedOptDungeons", "Show in Dungeons", "showInDungeons", -20)
    CreateCheckbox("YouDiedOptRaids", "Show in Raids", "showInRaids", -50)
    CreateCheckbox("YouDiedOptDelves", "Show in Delves/Scenarios", "showInDelves", -80)
    CreateCheckbox("YouDiedOptWorld", "Show in Open World", "showInOpenWorld", -110)
    CreateCheckbox("YouDiedOptArena", "Show in Arenas", "showInArena", -140)
    CreateCheckbox("YouDiedOptPVP", "Show in Battlegrounds", "showInPVP", -170)
    
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_DEAD")
EventFrame:RegisterEvent("PLAYER_ALIVE")
EventFrame:RegisterEvent("PLAYER_UNGHOST")
EventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

local spellNameToIDs = {}
local namesBuilt = false
local function BuildTrackedSpellNames()
    if namesBuilt then return end
    namesBuilt = true
    for id, _ in pairs(trackedSpells) do
        local name = nil
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(id)
            if info then name = info.name end
        elseif GetSpellInfo then
            name = GetSpellInfo(id)
        end
        if name then
            spellNameToIDs[name] = spellNameToIDs[name] or {}
            table.insert(spellNameToIDs[name], id)
        end
    end
end

EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "YouDied" then
            if not YouDiedDB then YouDiedDB = {} end
            if YouDiedDB.showInDungeons == nil then YouDiedDB.showInDungeons = true end
            if YouDiedDB.showInRaids == nil then YouDiedDB.showInRaids = true end
            if YouDiedDB.showInDelves == nil then YouDiedDB.showInDelves = true end
            if YouDiedDB.showInOpenWorld == nil then YouDiedDB.showInOpenWorld = true end
            if YouDiedDB.showInArena == nil then YouDiedDB.showInArena = true end
            if YouDiedDB.showInPVP == nil then YouDiedDB.showInPVP = true end
            
            YouDiedDB.lastCastTimes = YouDiedDB.lastCastTimes or {}
            -- Garbage collect old cast times (older than 10 minutes) so the DB doesn't grow infinitely
            local now = time()
            for k, v in pairs(YouDiedDB.lastCastTimes) do
                if now - v > 600 then
                    YouDiedDB.lastCastTimes[k] = nil
                end
            end
            CreateOptionsPanel()
        end
    elseif event == "PLAYER_DEAD" then
        local _, instanceType = GetInstanceInfo()
        local shouldShow = false
        
        if instanceType == "party" and YouDiedDB.showInDungeons then
            shouldShow = true
        elseif instanceType == "raid" and YouDiedDB.showInRaids then
            shouldShow = true
        elseif instanceType == "scenario" and YouDiedDB.showInDelves then
            shouldShow = true
        elseif instanceType == "arena" and YouDiedDB.showInArena then
            shouldShow = true
        elseif instanceType == "pvp" and YouDiedDB.showInPVP then
            shouldShow = true
        elseif instanceType == "none" and YouDiedDB.showInOpenWorld then
            shouldShow = true
        end
        
        if shouldShow then
            PopulateFrame()
            YouDied:Show()
        end
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        YouDied:Hide()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, castGUID, spellID = ...
        if unit == "player" then
            if not YouDiedDB then YouDiedDB = {} end
            YouDiedDB.lastCastTimes = YouDiedDB.lastCastTimes or {}
            
            -- Save the exact spellID cast (essential for tracking item spells like Potions)
            YouDiedDB.lastCastTimes[spellID] = time()
            
            BuildTrackedSpellNames()
            
            local castName = nil
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(spellID)
                if info then castName = info.name end
            elseif GetSpellInfo then
                castName = GetSpellInfo(spellID)
            end
            
            if castName and spellNameToIDs[castName] then
                if not YouDiedDB then YouDiedDB = {} end
                YouDiedDB.lastCastTimes = YouDiedDB.lastCastTimes or {}
                
                for _, id in ipairs(spellNameToIDs[castName]) do
                    YouDiedDB.lastCastTimes[id] = time()
                end
            end
        end
    end
end)

-- Allow closing by clicking on the frame just in case
YouDied:EnableMouse(true)
YouDied:SetScript("OnMouseDown", function(self)
    self:Hide()
end)

SLASH_YOUDIED1 = "/youdied"
SlashCmdList["YOUDIED"] = function()
    if YouDied:IsShown() then
        YouDied:Hide()
    else
        PopulateFrame()
        YouDied:Show()
    end
end
