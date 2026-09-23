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

YouDied.potionWarning = YouDied:CreateFontString(nil, "OVERLAY", "GameFontNormal")
YouDied.potionWarning:SetPoint("TOP", YouDied.subTitle, "BOTTOM", 0, -5)
YouDied.potionWarning:SetTextColor(1, 0.5, 0) -- Orange warning
YouDied.potionWarning:Hide()
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

local classSpells = {
    WARRIOR = { 871, 118038, 184364, 23920, 190456, 97462 },
    PALADIN = { 642, 633, 1022, 204018, 31850, 86659, 498, 184662, 205191 },
    HUNTER = { 186265, 264735, 109304, 119574 },
    ROGUE = { 31224, 5277, 1966, 185311 },
    PRIEST = { 47585, 19236, 33206, 62618, 47788, 197268 },
    DEATHKNIGHT = { 48792, 48707, 51052, 55233, 48743, 219809, 194679 },
    SHAMAN = { 108271, 198103, 108280, 98008, 108281 },
    MAGE = { 45438, 108978, 55342, 235450, 235313, 11426, 110959 },
    WARLOCK = { 104773, 108416, 6789 },
    MONK = { 115203, 122470, 122278, 122783, 115176, 116849 },
    DRUID = { 61336, 22812, 102342, 108238, 22842, 740 },
    DEMONHUNTER = { 198589, 212800, 204021, 203720, 196718 },
    EVOKER = { 363916, 374227, 357170, 363534 }
}

local healingItems = {}

local trackedSpells = {
    -- WARRIOR
    [871] = 300, [118038] = 180, [184364] = 120, [23920] = 25, [190456] = 12, [97462] = 180,
    -- PALADIN
    [642] = 210, [633] = 420, [1022] = 300, [204018] = 180, [31850] = 120, [86659] = 300, [498] = 60, [184662] = 90, [205191] = 60,
    -- HUNTER
    [186265] = 180, [264735] = 180, [109304] = 120, [119574] = 120,
    -- ROGUE
    [31224] = 120, [5277] = 120, [1966] = 15, [185311] = 30,
    -- PRIEST
    [47585] = 120, [19236] = 90, [33206] = 180, [62618] = 180, [47788] = 180, [197268] = 60,
    -- DEATH KNIGHT
    [48792] = 180, [48707] = 60, [51052] = 120, [55233] = 90, [48743] = 120, [219809] = 60, [194679] = 25,
    -- SHAMAN
    [108271] = 90, [198103] = 300, [108280] = 180, [98008] = 180, [108281] = 120,
    -- MAGE
    [45438] = 240, [108978] = 60, [55342] = 120, [235450] = 60, [235313] = 60, [11426] = 60, [110959] = 120,
    -- WARLOCK
    [104773] = 180, [108416] = 60, [6789] = 45,
    -- MONK
    [115203] = 180, [122470] = 90, [122278] = 120, [122783] = 90, [115176] = 300, [116849] = 120,
    -- DRUID
    [61336] = 180, [22812] = 60, [102342] = 90, [108238] = 90, [22842] = 36, [740] = 180,
    -- DEMON HUNTER
    [198589] = 60, [212800] = 180, [204021] = 60, [203720] = 20, [196718] = 180,
    -- EVOKER
    [363916] = 90, [374227] = 120, [357170] = 60, [363534] = 180,
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
    ResolveDynamicItems()
    ClearRows()
    local index = 1
    
    local hasPotion = false
    for _, itemID in ipairs(healingItems) do
        if itemID ~= 5512 then
            hasPotion = true
            break
        end
    end
    
    if not hasPotion then
        YouDied.potionWarning:SetText("(You have no Healing Potions! Stock up!)")
        YouDied.potionWarning:Show()
    else
        YouDied.potionWarning:Hide()
    end
    
    local _, class = UnitClass("player")
    local mySpells = classSpells[class] or {}
    for _, spellID in ipairs(mySpells) do
        if IsSpellAvailable(spellID) then
            local name, icon = GetSpellDetails(spellID)
            if name then
                AddRow(index, name, icon, spellID, nil)
                index = index + 1
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
    
    if YouDied.rows[1] then
        YouDied.rows[1]:ClearAllPoints()
        if not hasPotion then
            YouDied.rows[1]:SetPoint("TOP", YouDied.potionWarning, "BOTTOM", 0, -20)
        else
            YouDied.rows[1]:SetPoint("TOP", YouDied.subTitle, "BOTTOM", 0, -20)
        end
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
        YouDiedOptionsCategoryID = category.ID
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
SlashCmdList["YOUDIED"] = function(msg)
    local command = msg and msg:lower() or ""
    
    if command == "options" or command == "config" or command == "settings" then
        if Settings and Settings.OpenToCategory and YouDiedOptionsCategoryID then
            Settings.OpenToCategory(YouDiedOptionsCategoryID)
        else
            InterfaceOptionsFrame_OpenToCategory("You Died")
            InterfaceOptionsFrame_OpenToCategory("You Died") -- Bypass old UI bug
        end
    else
        if YouDied:IsShown() then
            YouDied:Hide()
        else
            PopulateFrame()
            YouDied:Show()
        end
    end
end
