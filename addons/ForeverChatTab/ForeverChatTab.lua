local nativeChatTypes = {
    WHISPER = true,
    BN_WHISPER = true,
    SMART_WHISPER = true,
    COMMUNITIES_CHANNEL = true,
    VOICE_TEXT = true,
}

local function IsEnabled()
    return type(ForeverChatTabDB) ~= "table" or ForeverChatTabDB.enabled ~= false
end

local function IsCommunityChannel(id)
    local _, _, _, isCommunity = GetChannelName(id)
    return isCommunity
end

local function GetNumberedChannels()
    local ids, seen = {}, {}
    local channels = { GetChannelList() }
    for index = 1, #channels, 3 do
        local id, disabled = channels[index], channels[index + 2]
        if id > 0 and not disabled and not seen[id] and not IsCommunityChannel(id)
            and (not C_ChatInfo.IsChannelRegional(id) or C_ChatInfo.IsRegionalServiceAvailable()) then
            seen[id] = true
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    return ids
end

local function GetCycle()
    local cycle = { "SAY" }
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        cycle[#cycle + 1] = "INSTANCE_CHAT"
    elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
        cycle[#cycle + 1] = "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        cycle[#cycle + 1] = "PARTY"
    end
    if IsInGuild() then
        cycle[#cycle + 1] = "GUILD"
    end
    for _, id in ipairs(GetNumberedChannels()) do
        cycle[#cycle + 1] = id
    end
    return cycle
end

local function NextChannel(cycle, current, reverse)
    local step = reverse and -1 or 1
    for index, channel in ipairs(cycle) do
        if channel == current then
            return cycle[(index - 1 + step) % #cycle + 1]
        end
    end
    return cycle[reverse and #cycle or 1]
end

local function IsReadable(value)
    return not canaccessvalue or canaccessvalue(value)
end

local function OnChatTab(editBox)
    if not IsEnabled() or C_ChatInfo.InChatMessagingLockdown() then return end

    local chatType, text = editBox:GetChatType(), editBox:GetText()
    if not IsReadable(chatType) or not IsReadable(text) or not IsReadable(editBox:GetTellTarget()) then return end
    if not chatType or nativeChatTypes[chatType] or text:match("^%s*/") then return end

    local current = chatType
    if chatType == "CHANNEL" then
        current = editBox:GetChannelTarget()
        if not IsReadable(current) or (current > 0 and IsCommunityChannel(current)) then return end
    end

    local nextChannel = NextChannel(GetCycle(), current, IsShiftKeyDown())
    if nextChannel == current then return end

    local numbered = type(nextChannel) == "number"
    local oldTarget = numbered and editBox:GetAttribute("channelTarget")
    if numbered and not IsReadable(oldTarget) then return end
    local ok = pcall(function()
        if numbered then editBox:SetChannelTarget(nextChannel) end
        editBox:SetChatType(numbered and "CHANNEL" or nextChannel)
        editBox:UpdateHeader()
    end)
    if not ok then
        pcall(function()
            if numbered then editBox:SetChannelTarget(oldTarget) end
            editBox:SetChatType(chatType)
            editBox:UpdateHeader()
        end)
    end
end

-- The chat frame calls this extension point after handling autocomplete.
hooksecurefunc("ChatEdit_CustomTabPressed", OnChatTab)

SLASH_FOREVERCHATTAB1 = "/fct"
SlashCmdList.FOREVERCHATTAB = function(input)
    local command = input:match("^%s*(.-)%s*$"):lower()
    if command == "on" or command == "off" then
        ForeverChatTabDB = { enabled = command == "on" }
    end
    local state = IsEnabled() and "已开启" or "已关闭"
    DEFAULT_CHAT_FRAME:AddMessage("ForeverChatTab 「Tab 切换发言频道」" .. state .. "（/fct on 或 /fct off）")
end
