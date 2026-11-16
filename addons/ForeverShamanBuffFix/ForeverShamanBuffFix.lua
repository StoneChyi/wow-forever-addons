local _, class = UnitClass("player")
local ui = EllesmereUI
if class ~= "SHAMAN" or not ui or not ui.IS_FOREVER then return end

local cdm = ui._ModuleNS and ui._ModuleNS.EllesmereUICooldownManager
if not cdm or type(cdm.GetBarSpellData) ~= "function"
    or type(cdm.UpdateCustomBuffAuraTracking) ~= "function" then return end

local buffBarKey = "buffs"
local auraIDs = { 1238931, 16257 } -- Improved Stormstrike, Flurry
local listener = CreateFrame("Frame")
local queued, restoring

local function ContainsSpell(spells, spellID)
    for _, id in ipairs(spells or {}) do
        if id == spellID then return true end
    end
    return false
end

local function IsAuraTracked(data, spellID)
    return data and data.customSpellIDs and data.customSpellIDs[spellID]
        and (data.spellDurations and data.spellDurations[spellID] or 0) <= 0
        and ContainsSpell(data.assignedSpells, spellID)
end

local function RestoreBuffs()
    queued = false
    if InCombatLockdown() then
        listener:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    listener:UnregisterEvent("PLAYER_REGEN_ENABLED")

    local bars = cdm.barDataByKey
    local mainBar = bars and bars[buffBarKey]
    if not (mainBar and mainBar.enabled and cdm.cdmBarFrames and cdm.cdmBarFrames[buffBarKey]) then return end

    local data = cdm.GetBarSpellData(buffBarKey)
    if not data then return end

    -- Respect exact custom auras already placed on another enabled CDM buff bar.
    local trackedElsewhere = {}
    for key, bar in pairs(bars) do
        if key ~= buffBarKey and bar.enabled and not bar.isGhostBar
            and (bar.barType == "buffs" or bar.barType == "custom_buff") then
            local other = cdm.GetBarSpellData(key)
            for _, spellID in ipairs(auraIDs) do
                if IsAuraTracked(other, spellID) then trackedElsewhere[spellID] = true end
            end
        end
    end

    local changed = false
    for _, spellID in ipairs(auraIDs) do
        if not trackedElsewhere[spellID] and not IsAuraTracked(data, spellID) then
            data.assignedSpells = data.assignedSpells or {}
            data.customSpellIDs = data.customSpellIDs or {}

            -- The normal picker deduplicates by name on Forever. The passive talent and
            -- the actual aura share a name, so add only the exact aura ID here.
            if not ContainsSpell(data.assignedSpells, spellID) then
                data.assignedSpells[#data.assignedSpells + 1] = spellID
            end
            data.customSpellIDs[spellID] = true
            if data.spellDurations then data.spellDurations[spellID] = nil end
            changed = true
        end
    end

    if changed then
        restoring = true
        cdm._spellOrderDirty = true
        if cdm.RebuildSpellRouteMap then cdm.RebuildSpellRouteMap() end
        cdm.UpdateCustomBuffAuraTracking()
        restoring = false
        if cdm.QueueReanchor then cdm.QueueReanchor() end
    end
end

local function QueueRestore()
    if queued or restoring then return end
    queued = true
    C_Timer.After(0, RestoreBuffs)
end

-- Run after CDM has finished reconciling its current profile. Never poll aura state.
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:SetScript("OnEvent", QueueRestore)
hooksecurefunc(cdm, "UpdateCustomBuffAuraTracking", QueueRestore)
QueueRestore()
